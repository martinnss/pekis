//
//  PekisApp.swift
//  Pekis
//
//  Created by Martin Olivares on 23-11-25.
//

import CloudKit
import SwiftUI

@main
struct PekisApp: App {
    @StateObject private var cloudKitService = CloudKitService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(cloudKitService)
                .onAppear {
                    NotificationManager.shared.requestAuthorization()
                    Task {
                        await cloudKitService.setup()
                        try? await cloudKitService.subscribeToChanges()
                    }
                }
                .onOpenURL { url in
                    // Handle incoming CloudKit share URLs
                    handleIncomingURL(url)
                }
        }
    }

    private func handleIncomingURL(_ url: URL) {
        // CloudKit share URLs use the cloudkit scheme
        let container = CKContainer(identifier: "iCloud.molivares.PekisGame")

        container.fetchShareMetadata(with: url) { metadata, error in
            guard let metadata = metadata, error == nil else {
                print("Failed to fetch share metadata: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            Task { @MainActor in
                cloudKitService.pendingShareMetadata = metadata
                do {
                    try await cloudKitService.acceptShare(metadata)
                } catch {
                    print("Failed to accept share: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Root View (Handles Onboarding vs Main App)

struct RootView: View {
    @EnvironmentObject var cloudKitService: CloudKitService

    var body: some View {
        Group {
            if cloudKitService.isLoading && cloudKitService.couple == nil {
                // Loading state
                LoadingView()
            } else if cloudKitService.couple == nil {
                // No couple yet - show onboarding
                CoupleOnboardingView()
            } else {
                // Paired - show main app
                HomeView()
            }
        }
        .animation(.easeInOut, value: cloudKitService.couple != nil)
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.pekisBackground.ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text("Connecting to iCloud...")
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }
}
