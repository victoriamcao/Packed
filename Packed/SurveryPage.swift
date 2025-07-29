//
//  SurveryPage.swift
//  Packed
//
//  Created by Scholar on 7/29/25.
//

import SwiftUI

struct SurveryPage: View {
    @State private var selectedType = "Tropical Vacation"
    
    var body: some View {
        VStack {
            Text("Create New List")
                .font(.largeTitle)
                .fontWeight(.semibold)
                .foregroundColor(Color(red: 0.195, green: 0.648, blue: 0.859))
                .padding(.vertical, 100.0)
            Text("TYPE OF VACATION")
                .foregroundColor(Color(red: 0.561, green: 0.557, blue: 0.557))
            Menu {
                Button(action: { selectedType = "Tropical Vacation" }) {
                    Text("Tropical Vacation")
                }
                Button(action: { selectedType = "Mountain Vacation" }) {
                    Text("Mountain Vacation")
                }
                Button(action: { selectedType = "Ski Trip" }) {
                    Text("Ski Trip")
                }
                Button(action: { selectedType = "City Vacation" }) {
                    Text("City Vacation")
                }
                Button(action: { selectedType = "Business Trip" }) {
                    Text("Business Trip")
                }
            } label: {
                Label(
                    title: {Text(selectedType)
                            .foregroundColor(Color(red: 0.561, green: 0.561, blue: 0.561))
                        .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)},
                    icon: {Image("arrow")
                            .resizable()
                            .frame(width: 25, height: 25)
                        }
                )
                .background(Rectangle()
                    .foregroundColor(Color("buttonGray")))
                .cornerRadius(15)
                .padding()
            }
            Spacer()
        }
    }
}

#Preview {
    SurveryPage()
}
