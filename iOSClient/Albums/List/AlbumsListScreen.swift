//
//  AlbumsRootView.swift
//  Nextcloud
//
//  Created by A200118228 on 07/07/25.
//  Copyright © 2025 Marino Faggiana. All rights reserved.
//

import SwiftUI
import SVGKit

struct AlbumsListScreen: View {
    
    @State private var isPresentingNewAlbum = false
    @State private var newAlbumName: String = ""
    
    @StateObject private var viewModel: AlbumsListViewModel
    
    init(viewModel: AlbumsListViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        
        NavigationView {
            
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading albums...")
                } else if let error = viewModel.errorMessage {
                    Text("Error: \(error)")
                } else if viewModel.albums.isEmpty {
                    VStack(spacing: 20) {
                        
                        SVGImageView(
                            url: AssetExtractor.createLocalUrl(forImageNamed: "octopus.svg")!,
                            size: CGSize(width: 200, height: 200)
                        )
                        .frame(width: 200, height: 200)
                        Text("No albums yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                } else {
                    List(viewModel.albums, id: \.name) { album in
                        Text(album.name)
                    }
                }
            }
            .navigationTitle("Albums")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isPresentingNewAlbum = true
                    }) {
                        Text("New")
                    }
                }
            }
            .sheet(isPresented: $isPresentingNewAlbum) {
                NewAlbumPopupView(
                    isPresented: $isPresentingNewAlbum,
                    albumName: $newAlbumName,
                    onCreate: {
                        print("Creating album: \(newAlbumName)")
                        // TODO: Call your API / ViewModel here
                        newAlbumName = ""
                    }
                )
            }
        }
        .onAppear {
            viewModel.loadAlbums()
        }
    }
}

class AssetExtractor {
    
    static func createLocalUrl(forImageNamed name: String) -> URL? {
        
        let fileManager = FileManager.default
        let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let url = cacheDirectory.appendingPathComponent(name)
        let path = url.path
        
        guard fileManager.fileExists(atPath: path) else {
            guard
                let image = UIImage(named: name),
                let data = image.pngData()
            else { return nil }
            
            fileManager.createFile(atPath: path, contents: data, attributes: nil)
            return url
        }
        
        return url
    }
}

struct NewAlbumPopupView: View {
    
    @Binding var isPresented: Bool
    @Binding var albumName: String
    
    var onCreate: () -> Void
    
    var body: some View {
        
        NavigationView {
            
            VStack(alignment: .leading, spacing: 20) {
                
                Text("Create New Album")
                    .font(.title2)
                    .bold()
                
                Text("Enter a name for your new photo album.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                TextField("Album name", text: $albumName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.top)
                
                Spacer()
                
                HStack {
                    Button("Cancel") {
                        isPresented = false
                        albumName = ""
                    }
                    .foregroundColor(.red)
                    
                    Spacer()
                    
                    Button("Create") {
                        onCreate()
                        isPresented = false
                    }
                    .disabled(albumName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
}

struct SVGImageView: UIViewRepresentable {
    
    var url:URL
    var size:CGSize
    
    func updateUIView(_ uiView: SVGKFastImageView, context: Context) {
        uiView.contentMode = .scaleAspectFit
        uiView.image.size = size
    }
    
    func makeUIView(context: Context) -> SVGKFastImageView {
        let svgImage = SVGKImage(contentsOf: url)
        return SVGKFastImageView(svgkImage: svgImage ?? SVGKImage())
    }
}

#Preview {
    SVGImageView(
        url: AssetExtractor.createLocalUrl(forImageNamed: "octopus.svg")!,
        size: CGSize(width: 100, height: 100)
    )
    .frame(width: 100, height: 100)
}

//#Preview {
//    AlbumsRootView(viewModel: .init(account: "1234"))
//}
