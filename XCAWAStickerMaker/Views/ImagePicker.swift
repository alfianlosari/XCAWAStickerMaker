//
//  ImagePicker.swift
//  XCAWAStickerMaker
//
//  Created by Alfian Losari on 14/10/23.
//

import CoreImage.CIImage
import SwiftUI
import PhotosUI
import UIKit

struct ImagePicker<Label>: View where Label: View {
    
    @State private var imageSelection: PhotosPickerItem? = nil
    
    var label: () -> Label
    let onSelectedImage: (CIImage) -> ()
    
    var body: some View {
        PhotosPicker(selection: $imageSelection, matching: .images) {
            label()
        }
        .onChange(of: imageSelection) { _, newSelection in
            self.loadInputImage(fromPhotosPickerItem: newSelection)
        }
    }
    
    private func loadInputImage(fromPhotosPickerItem item: PhotosPickerItem?) {
        guard let item else { return }
        item.loadTransferable(type: Data.self) { result in
            switch result {
            case .failure(let error):
                print("Failed to load: \(error)")
                return
                
            case .success(let _data):
                guard let data = _data else {
                    print("Failed to load image data")
                    return
                }
                
                guard var image = CIImage(data: data) else {
                    print("Failed to create image from selected photo")
                    return
                }
                
                if let orientation = image.properties["Orientation"] as? Int32, orientation != 1 {
                    image = image.oriented(forExifOrientation: orientation)
                }
                
                DispatchQueue.main.async {
                    onSelectedImage(image)
                }
            }
        }
    }
}

#Preview {
    ImagePicker {
        Text("Select Photo")
    } onSelectedImage: { image in
        
    }
}
