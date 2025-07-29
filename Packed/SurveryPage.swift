//
//  SurveryPage.swift
//  Packed
//
//  Created by Scholar on 7/29/25.
//

import SwiftUI

struct SurveryPage: View {
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
                Button(action: { }, label: { Text("Tropical Vacation")
                })
                Button(action: { }, label: { Text("Mountain Vacation")
                })
                Button(action: { }, label: { Text("Ski Trip")
                })
                Button(action: { }, label: { Text("City Vacation")
                })
                Button(action: { }, label: { Text("Business Trip")
                })
            } label: {
                Label(
                    title: {Text("Tropical Vacation")
                        .foregroundColor(Color(red: 0.561, green: 0.561, blue: 0.561))},
                    icon: {Image("arrow")
                        }
                )
            }
            Spacer()
        }
    }
}

#Preview {
    SurveryPage()
}
