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
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color(red: 0.195, green: 0.648, blue: 0.859))
            Text("TYPE OF VACATION")
                .foregroundColor(Color(red: 0.561, green: 0.557, blue: 0.557))
        }
    }
}

#Preview {
    SurveryPage()
}
