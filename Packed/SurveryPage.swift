//
//  SurveryPage.swift
//  Packed
//
//  Created by Scholar on 7/29/25.
//

import SwiftUI

struct SurveryPage: View {
    @State private var selectedType = "Tropical Vacation"
    @State private var selectedGender = "I prefer not to say"
    @State private var selectedWeather = "Sunny"
    @State private var selectedLength = 1
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Create New List")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.195, green: 0.648, blue: 0.859))
                    .padding(.top, 75.0)
                    .padding(.bottom, 35.0)
                
                Spacer()
                // Type of Vacation button
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
                    ZStack {
                        Rectangle()
                            .foregroundColor(Color("buttonGray"))
                            .frame(width: 350, height: 50) // Set constant size here
                            .cornerRadius(10)
                        
                        Label(
                            title: {Text(selectedType)
                                    .foregroundColor(Color(red: 0.561, green: 0.561, blue: 0.561))
                                .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)},
                            icon: {Image("arrow")
                                    .resizable()
                                    .frame(width: 37, height: 30)
                            }
                        )
                    }
                    .padding(.top, 8.0)
                }
                .padding(.bottom)
                // Type of Vacation button
                Text("WEATHER")
                    .foregroundColor(Color(red: 0.561, green: 0.557, blue: 0.557))
                Menu {
                    Button(action: { selectedWeather = "Sunny" }) {
                        Text("Sunny")
                    }
                    Button(action: { selectedWeather = "Rainy" }) {
                        Text("Rainy")
                    }
                    Button(action: { selectedWeather = "Cloudy" }) {
                        Text("Cloudy")
                    }
                    Button(action: { selectedWeather = "Foggy" }) {
                        Text("Foggy")
                    }
                    Button(action: { selectedWeather = "Windy" }) {
                        Text("Windy")
                    }
                    Button(action: { selectedWeather = "Snowy" }) {
                        Text("Snowy")
                    }
                } label: {
                    ZStack {
                        Rectangle()
                            .foregroundColor(Color("buttonGray"))
                            .frame(width: 350, height: 50) // Set constant size here
                            .cornerRadius(10)
                        
                        Label(
                            title: {Text(selectedWeather)
                                    .foregroundColor(Color(red: 0.561, green: 0.561, blue: 0.561))
                                .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)},
                            icon: {Image("arrow")
                                    .resizable()
                                    .frame(width: 37, height: 30)
                            }
                        )
                    }
                    .padding(.top, 8.0)
                }
                .padding(.bottom)
                
                // Type of Vacation button
                Text("LENGTH OF VACATION")
                    .foregroundColor(Color(red: 0.561, green: 0.557, blue: 0.557))
                Menu {
                    Button(action: { selectedLength = 1 }) {
                        Text("1 Day")
                    }
                    Button(action: { selectedLength = 2 }) {
                        Text("2 Days")
                    }
                    Button(action: { selectedLength = 3 }) {
                        Text("3 Days")
                    }
                    Button(action: { selectedLength = 4 }) {
                        Text("4 Days")
                    }
                    Button(action: { selectedLength = 5 }) {
                        Text("5 Days")
                    }
                    Button(action: { selectedLength = 6 }) {
                        Text("6 Days")
                    }
                    Button(action: { selectedLength = 7 }) {
                        Text("7 Days")
                    }
                    Button(action: { selectedLength = 8 }) {
                        Text("8+ Days")
                    }
                } label: {
                    ZStack {
                        Rectangle()
                            .foregroundColor(Color("buttonGray"))
                            .frame(width: 350, height: 50) // Set constant size here
                            .cornerRadius(10)
                        
                        Label(
                            title: {Text("\(selectedLength) Day(s)")
                                    .foregroundColor(Color(red: 0.561, green: 0.561, blue: 0.561))
                                .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)},
                            icon: {Image("arrow")
                                    .resizable()
                                    .frame(width: 37, height: 30)
                            }
                        )
                    }
                    .padding(.top, 8.0)

                }
                .padding(.bottom)
                
                // Type of Vacation button
                Text("GENDER")
                    .foregroundColor(Color(red: 0.561, green: 0.557, blue: 0.557))
                Menu {
                    Button(action: { selectedGender = "I prefer not to say" }) {
                        Text("I prefer not to say")
                    }
                    Button(action: { selectedGender = "Male" }) {
                        Text("Male")
                    }
                    Button(action: { selectedGender = "Female" }) {
                        Text("Female")
                    }
                } label: {
                    ZStack {
                        Rectangle()
                            .foregroundColor(Color("buttonGray"))
                            .frame(width: 350, height: 50) // Set constant size here
                            .cornerRadius(10)
                        
                        Label(
                            title: {Text(selectedGender)
                                    .foregroundColor(Color(red: 0.561, green: 0.561, blue: 0.561))
                                .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)},
                            icon: {Image("arrow")
                                    .resizable()
                                    .frame(width: 37, height: 30)
                            }
                        )

                    }
                    .padding(.bottom)
                }
                
                Spacer()
                NavigationLink(destination: ListPage(
                    selectedType: selectedType,
                    selectedGender: selectedGender,
                    selectedWeather: selectedWeather,
                    selectedLength: selectedLength
                )) {
                    ZStack {
                        Rectangle()
                            .foregroundColor(Color("lightBlue"))
                            .frame(width: 350, height: 50)
                            .cornerRadius(10)
                        Text("Create")
                            .font(.title2)
                            .foregroundColor(Color.white)
                    }
                }
                Spacer()
            }
        }
    }
}

#Preview {
    SurveryPage()
}
