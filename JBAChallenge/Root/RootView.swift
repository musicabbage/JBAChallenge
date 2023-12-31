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
                        importButtonTapped()
                    }
                    .padding()
                }
            }
        }, detail: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .padding(22)
                    .foregroundStyle(.white)
                    .background(Color.red)
                    .clipShape(.rect(cornerRadius: 8))
            } else if viewModel.items.isEmpty {
                Button("Import File") {
                    importButtonTapped()
                }
                .buttonStyle(.borderedProminent)
            } else {
                ScrollView {
                    LazyVStack {
                        Text(viewModel.header)
                            .font(.title)
                        Spacer(minLength: 32)
                        if !viewModel.items.isEmpty {
                            ItemCell(columns: ["Xref", "Yref", "Date", "Value"], isHeader: true)
                        }
                        
                        ForEach(0..<viewModel.items.count, id: \.self) { index in
                            let item = viewModel.items[index]
                            ItemCell(columns: ["\(item.xref)",
                                               "\(item.yref)",
                                               item.date ?? "",
                                               "\(item.value)"])
                            .onAppear {
                                guard index >= viewModel.items.count - 1 else { return }
                                viewModel.fetchNextPage()
                            }
                        }
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
                loading = LoadingModel(message: "saving")
                await viewModel.readFile(url: fileUrl)
                loading = nil
            }
        }
    }
}

private extension RootView {
    func importButtonTapped() {
        add = true
        fileUrl = nil
    }
}

#Preview {
    RootView(viewModel: MockRootViewModel())
}
