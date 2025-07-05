//
//  ContentView.swift
//  MMYPhotoKitSimpleDemo
//
//  Created by alimysoyang on 7/5/25.
//

import SwiftUI

struct ContentView: View {
    @State private var manager: AppManager = .init()
    
    init() {
        if let fileURL = Bundle.main.url(forResource: "40KUMT", withExtension: "jpg"),
           let data = try? Data(contentsOf: fileURL) {
            manager.sourceImage = UIImage(data: data)
        }
    }
    
    var body: some View {
        VStack(spacing: 10) {
            if let sourceImage = manager.sourceImage {
                Image(uiImage: sourceImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 260)
            }
            
            Button("Remove background") {
                manager.photoProcess(.red)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            if let destinationImage = manager.destinationImage {
                Image(uiImage: destinationImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 260)
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
