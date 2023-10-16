//
//  FilePickerView.swift
//  JBAChallenge
//
//  Created by cabbage on 2023/10/13.
//

import Foundation
import SwiftUI

struct FilePickerView: UIViewControllerRepresentable {
    
    @Binding private var fileUrl: URL?
    
    init(fileUrl: Binding<URL?>) {
        self._fileUrl = fileUrl
    }
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let controller = UIDocumentPickerViewController(forOpeningContentTypes: [])
        controller.shouldShowFileExtensions = true
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(fileUrl: $fileUrl)
    }
}

extension FilePickerView {
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        
        @Binding private var fileUrl: URL?
        
        init(fileUrl: Binding<URL?>) {
            self._fileUrl = fileUrl
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            fileUrl = url
        }
    }
}
