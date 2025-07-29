//
//  PastLists.swift
//  Packed
//
//  Created by Scholar on 7/29/25.
//

import SwiftUI

struct PastLists: View {
    
    var body: some View {
        VStack {
            Text("Past Lists")
                .padding([.top, .leading, .bottom])
                .font(.largeTitle)
                .multilineTextAlignment(.center)
            
            Divider()
            
            Spacer()
            
            Button(action: {
                // Add navigation or action here
            }) {
                Text("Go Home")
                    .font(.headline)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color("lightBlue"))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .padding()
    }
}

#Preview {
    PastLists()
}
