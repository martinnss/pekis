//
//  PekisApp.swift
//  Pekis
//
//  Created by Martin Olivares on 23-11-25.
//

import CloudKit
import SwiftUI
import UIKit

// MARK: - App Delegate (remote notification processing for CloudKit)

final class AppDelegate: NSObject, UIApplicationDelegate {
    var cloudKitService: CloudKitService?

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        Task { @MainActor in
            await cloudKitService?.handleNotification(userInfo: userInfo)
            completionHandler(.newData)
        }
    }
}

@main
struct PekisApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var cloudKitService = CloudKitService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(cloudKitService)
                .onAppear {
                    appDelegate.cloudKitService = cloudKitService
                    NotificationManager.shared.requestAuthorization()
                    // Skip CloudKit in test environments — entitlements are absent
                    // when built with CODE_SIGNING_ALLOWED=NO, causing CKContainer to crash.
                    guard !Bundle.allBundles.contains(where: { $0.bundlePath.hasSuffix(".xctest") }) else {
                        return
                    }
                    Task {
                        await cloudKitService.setup()
                        try? await cloudKitService.subscribeToChanges()
                        NotificationManager.shared.scheduleNotifications(
                            reunionDate: cloudKitService.couple?.reunionDate
                        )
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
        let container = CKContainer(identifier: "iCloud.molivares.pekisgame")

        Task { @MainActor in
            do {
                let metadata = try await withCheckedThrowingContinuation { continuation in
                    container.fetchShareMetadata(with: url) { metadata, error in
                        if let metadata {
                            continuation.resume(returning: metadata)
                        } else {
                            continuation.resume(throwing: error ?? CloudKitError.shareNotFound)
                        }
                    }
                }
                cloudKitService.pendingShareMetadata = metadata
                try await cloudKitService.acceptShare(metadata)
            } catch {
                print("Failed to handle share URL: \(error.localizedDescription)")
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
                LoadingView()
            } else if cloudKitService.couple == nil || cloudKitService.needsPartnerName {
                CoupleOnboardingView()
            } else {
                HomeView(cloudKitService: cloudKitService)
            }
        }
        .animation(.easeInOut, value: cloudKitService.isPaired)
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
