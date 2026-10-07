//
//  ListPage.swift
//  Packed
//
//  Created by Scholar on 7/29/25.
//

import SwiftUI

struct ListPage: View {
    var selectedType: String
    var selectedGender: String
    var selectedWeather: String
    var selectedLength: Int
    var destination: String = ""
    var travelDate: Date = Date()
    @ObservedObject var savedLists: SavedLists
    @EnvironmentObject var userData: UserData
    @State private var showLoginPrompt = false
    @State private var saveErrorMessage: String?
    @State private var isSaving = false
    @State private var vacationName: String = ""
    @State private var newItem: String = ""
    @State private var items: [PackingItem] = []
    // Historical weather average for the destination + travel date, when available.
    @State private var historicalWeather: HistoricalWeatherSummary?
    @State private var isLoadingWeather: Bool = false
    // Whether the current list came from the Claude-powered generator.
    @State private var isGeneratingList: Bool = false
    @State private var usedAIGeneration: Bool = false
    @State private var aiNotice: String?
    
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                TextField("Vacation Name", text: $vacationName)
                    .padding([.top, .leading, .bottom])
                    .font(.largeTitle)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .accessibilityLabel("Trip name")
                    .onChange(of: vacationName) { _, newValue in
                        if newValue.count > 60 {
                            vacationName = String(newValue.prefix(60))
                        }
                    }

                if isLoadingWeather {
                    Text("Checking weather for \(destination)...")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.bottom, 8)
                } else if let historicalWeather {
                    Text(historicalWeather.summaryText)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.bottom, 8)
                }

                if isGeneratingList {
                    Text("Generating your smart packing list...")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.bottom, 8)
                } else if usedAIGeneration {
                    Text("✨ AI-personalized packing list")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.bottom, 8)
                } else if let aiNotice {
                    Text(aiNotice)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                } else if !items.isEmpty && !userData.isLoggedIn {
                    Text("Basic list. Log in to get an AI-personalized one next time.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
                Divider()
                
                PackingItemsListView(items: $items)
                
                AddItemBar(text: $newItem) { name in
                    items.append(PackingItem(name: name, category: "Added by You"))
                }

                // Save and Go Home buttons
                VStack(spacing: 0) {
                    Button(action: {
                        guard userData.isLoggedIn else {
                            showLoginPrompt = true
                            return
                        }
                        let listItems = items.map { SavedPackingItem($0) }
                        isSaving = true
                        Task {
                            guard let token = try? await userData.validAccessToken(), let uid = userData.currentUserId else {
                                isSaving = false
                                showLoginPrompt = true
                                return
                            }
                            let didSave = await savedLists.saveList(
                                title: vacationName.isEmpty ? "Untitled" : vacationName,
                                items: listItems,
                                type: selectedType,
                                duration: selectedLength,
                                member: selectedGender,
                                travelDate: travelDate,
                                userId: uid,
                                accessToken: token
                            )
                            isSaving = false
                            if didSave {
                                dismiss() // Dismiss the view and go back to the home screen
                            } else {
                                saveErrorMessage = savedLists.errorMessage ?? "Couldn't save your list. Check your connection and try again."
                            }
                        }
                    }) {
                        Text(isSaving ? "Saving..." : "Save List")
                            .font(.headline)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity)
                            .background(Color("lightBlue"))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    .disabled(isSaving)
                    .padding(.top, 10)
                }
                .padding(.bottom, 20)
            }
            .padding(.top)
            .padding(.bottom, 60)

            BottomNavBar(current: .home)
        }
            .background(Color("appBackground").ignoresSafeArea())
            .alert("Log in required", isPresented: $showLoginPrompt) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Log in to save your packing list.")
            }
            .alert("Couldn't save list", isPresented: Binding(
                get: { saveErrorMessage != nil },
                set: { if !$0 { saveErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveErrorMessage ?? "")
            }
            .task {
                guard items.isEmpty else { return }
                let trimmedDestination = destination.trimmingCharacters(in: .whitespacesAndNewlines)

                if !trimmedDestination.isEmpty {
                    isLoadingWeather = true
                    do {
                        historicalWeather = try await WeatherService.fetchWeatherContext(
                            destination: trimmedDestination,
                            date: travelDate
                        )
                    } catch {
                        // Fall back silently to the manually selected weather
                        // (e.g. offline, unknown destination, or API hiccup).
                        historicalWeather = nil
                    }
                    isLoadingWeather = false
                }

                // Snapshot anything the user manually added via "Add" while
                // the weather/AI fetch above was in flight, so the result
                // below doesn't silently wipe it out.
                let userAddedWhileGenerating = items

                isGeneratingList = true
                // Logged-in users get AI lists through Packed's backend;
                // a personal API key (Profile settings) still works too.
                var accessToken: String?
                if userData.isLoggedIn {
                    accessToken = try? await userData.validAccessToken()
                }
                do {
                    let generated = try await ClaudePackingListService.generatePackingList(
                        destination: trimmedDestination,
                        tripType: selectedType,
                        gender: selectedGender,
                        travelDate: travelDate,
                        lengthDays: selectedLength,
                        weather: historicalWeather,
                        accessToken: accessToken
                    )
                    items = generated + userAddedWhileGenerating
                    usedAIGeneration = true
                } catch {
                    // Not logged in / no key, offline, or an API error -
                    // fall back to the rule-based generator.
                    Log.ai.notice("AI list unavailable, using rule-based list: \(error.localizedDescription, privacy: .public)")
                    if case .limitReached(let message)? = error as? ClaudePackingListError {
                        aiNotice = "\(message) Here's a basic list instead."
                    }
                    let generated = ListItems.generatePackingList(
                        type: selectedType,
                        gender: selectedGender,
                        weather: selectedWeather,
                        length: selectedLength,
                        historicalWeather: historicalWeather
                    )
                    items = generated + userAddedWhileGenerating
                    usedAIGeneration = false
                }
                isGeneratingList = false

                // Pre-fill the vacation name based on selections, unless the
                // user already typed their own while generation was running.
                if vacationName.isEmpty {
                    vacationName = "\(selectedType) - \(selectedLength) Day(s)"
                }
            }
    }
}

#Preview {
    ListPage(
        selectedType: "Tropical Vacation",
        selectedGender: "Female",
        selectedWeather: "Sunny",
        selectedLength: 3,
        savedLists: SavedLists()
    )
    .environmentObject(UserData())
    .environmentObject(AppNavigator())
}
