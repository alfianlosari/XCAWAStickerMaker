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
    var image: Image?
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if image == nil {
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
        ImageContainerView()
        ImageContainerView(badgeText: "12", image: nil)
    }
}
