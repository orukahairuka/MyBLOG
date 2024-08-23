//
//  CustomTextBox.swift
//  MyBLOG
//
//  Created by 櫻井絵理香 on 2024/08/22.
//

import SwiftUI

struct CustomBox: View {
    let title: String
    let content: String
    let systemImage: String
    var mainColor: Color

    init(title: String, content: String, systemImage: String, mainColor: Color = .blue) {
        self.title = title
        self.content = content
        self.systemImage = systemImage
        self.mainColor = mainColor
    }

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: systemImage)
                .foregroundColor(.gray)
                .font(.system(size: 30))
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.black)

                Text(content)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
            }
        }
        .padding()
        .frame(width: 310, height: 100)
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.white, mainColor.opacity(0.5)]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
        )
        .cornerRadius(25)
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(mainColor.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 5, y: 5)
        .shadow(color: mainColor.opacity(0.4), radius: 5, x: 2, y: 2)
    }
}
