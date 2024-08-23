//
//  SelfIntroduction.swift
//  MyBLOG
//
//  Created by 櫻井絵理香 on 2024/08/21.
//

import SwiftUI

struct SelfIntroductionView: View {
    let name: String = "櫻井 絵理香"
    let occupation: String = "iOS Developper"
    let hobbies: [String] = ["Reading", "Hiking", "Coding"]
    let skills: [String] = ["SwiftUI", "UIKit","Firebase","Figma"]

    var body: some View {
        ZStack {
            Image("backImage")
            ScrollView {
                VStack(alignment: .center, spacing: 20) {
                    Text("Self introduction")
                    // Face Icon
                    Image("me")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.blue, lineWidth: 4)
                        )
                        .shadow(radius: 7)

                    // Name
                    Text(name)
                        .font(.title)
                        .fontWeight(.bold)

                    //Occupation
                    Text("\(occupation)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack {
                        // skills
                        VStack(alignment: .leading) {
                            Text("Skills:")
                                .font(.headline)
                            ForEach(skills, id: \.self) { skill in
                                Text("• \(skill)")
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)


                        // Hobbies
                        VStack(alignment: .leading) {
                            Text("Hobbies:")
                                .font(.headline)
                            ForEach(hobbies, id: \.self) { hobby in
                                Text("• \(hobby)")
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }

                    // Additional information can be added here
                    //Occupation
                    Text("About Career https://www.wantedly.com/id/erika_sakurai_korogi")
                        .font(.subheadline)
                        .foregroundColor(.secondary)


                    Spacer()
                }
                .padding()
            }
        }
        .navigationTitle("Self Introduction")
        .padding()
    }
}

struct SelfIntroductionView_Previews: PreviewProvider {
    static var previews: some View {
        SelfIntroductionView()
    }
}
