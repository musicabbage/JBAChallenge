//
//  RootView.swift
//  JBAChallenge
//
//  Created by cabbage on 2023/10/12.
//

import SwiftUI

struct RootView<ViewModel: RootViewModelProtocol>: View {
    
    @State private var loading: LoadingModel?
    @State private var add: Bool = false
    @State private var fileUrl: URL?
    @ObservedObject private var viewModel: ViewModel
    
    init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        NavigationSplitView(sidebar: {
            NavigationView {
                VStack {
                    List(viewModel.files) { file in
                        Button(action: {
                            guard let fileName = file.name else { return }
                            viewModel.fetchGrids(file: fileName)
                        }) {
                            Text(file.name ?? "")
                        }
                    }
                    Button("Import") {
                        add = true
                        fileUrl = nil
                    }
                    .padding()
                }
            }
        }, detail: {
            ScrollView {
                LazyVStack {
                    Text(viewModel.header)
                        .font(.title)
                    Spacer()
                    ForEach(viewModel.items) { item in
                        ItemCell(item: item)
                    }
                }
            }
        })
        .loadingView($loading)
        .sheet(isPresented: $add, content: {
            FilePickerView(fileUrl: $fileUrl)
        })
        .onChange(of: fileUrl) { oldValue, newValue in
            guard let fileUrl else { return }
            Task {
                loading = LoadingModel()
                await viewModel.readFile(url: fileUrl)
                loading = nil
            }
        }
    }
}

private extension RootView {
}

#Preview {
    RootView(viewModel: MockRootViewModel())
}
