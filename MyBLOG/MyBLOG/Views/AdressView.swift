//
//  Address.swift
//  MyBLOG
//
//  Created by 櫻井絵理香 on 2024/08/21.
//

import SwiftUI

struct AdressView: View {
    var body: some View {
        ZStack {
            Image("backImage")
            VStack(alignment: .center) {
                CustomBox(title: "EMAIL", content: "example@email.com", systemImage: "envelope.fill", mainColor: .white)
                CustomBox(title: "ADDRESS", content: "123 Main St, City", systemImage: "house.fill", mainColor: .white)
            }
        }
    }
}

#Preview {
    AdressView()
}
