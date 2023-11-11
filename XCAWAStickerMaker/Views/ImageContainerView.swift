//
//  ImageContainerView.swift
//  XCAWAStickerMaker
//
//  Created by Alfian Losari on 14/10/23.
//

import SwiftUI

let width: CGFloat = 108
let spacing: CGFloat = 20

struct ImageContainerView: View {
    
    var badgeText: String?
    var sticker: Sticker
    var showOriginalImage: Bool = false

    var image: Image? {
        showOriginalImage ? sticker.inputImage : sticker.outputImage
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if (image == nil && !sticker.isGeneratingImage && sticker.errorText == nil) {
                Image(systemName: "photo.badge.plus")
                    .imageScale(.large)
                    .foregroundStyle(Color.accentColor)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            if let image {
                image
                    .resizable()
                    .scaledToFit()
                    .clipped()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            if let badgeText {
                Text(badgeText)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(4)
                    .background {
                        Circle().foregroundStyle(Color.accentColor)
                    }
                    .padding([.leading, .top], 8)
            }
            
            if sticker.isGeneratingImage {
                ProgressView("🤖✨")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(16)
            }
            
            if let errorText = sticker.errorText {
                Text(errorText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(3)
            }
            
        }
        .frame(width: width, height: width)
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 3, dash: [8]))
        }
    }
}

#Preview {
    VStack {
        ImageContainerView(sticker: .init())
        ImageContainerView(badgeText: "12", sticker: .init())
    }
}
