//
//  PekisApp.swift
//  Pekis
//
//  Created by Martin Olivares on 23-11-25.
//

import CloudKit
import OSLog
import SwiftUI
import UIKit

// MARK: - App Delegate (remote notification processing for CloudKit)

final class AppDelegate: NSObject, UIApplicationDelegate {
    // Static reference because UIApplication.shared.delegate returns a SwiftUI
    // wrapper when using @UIApplicationDelegateAdaptor — direct cast fails.
    static weak var shared: AppDelegate?

    override init() {
        super.init()
        AppDelegate.shared = self
    }

    var cloudKitService: CloudKitService? {
        didSet {
            // A share tapped on a cold launch can arrive before RootView wires up
            // the service. Replay it once the service is available.
            if let metadata = pendingShareMetadata {
                pendingShareMetadata = nil
                accept(metadata)
            }
        }
    }

    private var pendingShareMetadata: CKShare.Metadata?
    private var activeShareRecordName: String?

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

    // Invoked by the system when the user taps a CloudKit share link. Requires
    // `CKSharingSupported = YES` in Info.plist. iCloud share URLs are delivered
    // here, not via SwiftUI's `onOpenURL`, which only sees the app's own schemes
    // and universal links.
    func application(
        _ application: UIApplication,
        userDidAcceptCloudKitShareWith metadata: CKShare.Metadata
    ) {
        PekisLogger.app.debug("AppDelegate: userDidAcceptCloudKitShareWith fired, shareURL=\(metadata.share.url?.absoluteString ?? "nil", privacy: .public)")
        handleCloudKitShare(metadata)
    }

    // Called by SceneDelegate for apps using UIWindowScene (SwiftUI WindowGroup).
    func handleCloudKitShare(_ metadata: CKShare.Metadata) {
        let recordName = metadata.share.recordID.recordName
        if activeShareRecordName == recordName {
            PekisLogger.app.debug("handleCloudKitShare: already processing share \(recordName, privacy: .public), skipping duplicate")
            return
        }

        PekisLogger.app.debug("handleCloudKitShare: cloudKitService ready=\(self.cloudKitService != nil, privacy: .public)")
        guard cloudKitService != nil else {
            PekisLogger.app.debug("handleCloudKitShare: service not ready, buffering metadata")
            pendingShareMetadata = metadata
            return
        }
        accept(metadata)
    }

    private func accept(_ metadata: CKShare.Metadata) {
        activeShareRecordName = metadata.share.recordID.recordName
        PekisLogger.app.debug("accept: dispatching acceptShare on CloudKitService")
        Task { @MainActor in
            cloudKitService?.pendingShareMetadata = metadata
            do {
                try await cloudKitService?.acceptShare(metadata)
                PekisLogger.app.debug("accept: acceptShare completed successfully")
            } catch {
                let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                PekisLogger.app.error("accept: Failed to accept share: \(message, privacy: .public)")
                cloudKitService?.errorMessage = message
            }
            activeShareRecordName = nil
        }
    }

    // Registers SceneDelegate as the UIWindowSceneDelegate so that
    // windowScene(_:userDidAcceptCloudKitShareWith:) is called on scene-based apps.
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        if let metadata = options.cloudKitShareMetadata {
            PekisLogger.app.debug("AppDelegate: configurationForConnecting cloudKitShareMetadata, shareURL=\(metadata.share.url?.absoluteString ?? "nil", privacy: .public)")
            handleCloudKitShare(metadata)
        }

        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = PekisSceneDelegate.self
        return config
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
                    // The PEKIS_SKIP_CLOUDKIT env flag offers the same escape hatch for
                    // unsigned UI-preview builds on the simulator (never set in shipping).
                    let isTestBundle = Bundle.allBundles.contains { $0.bundlePath.hasSuffix(".xctest") }
                    let skipCloudKit = ProcessInfo.processInfo.environment["PEKIS_SKIP_CLOUDKIT"] == "1"
                    guard !isTestBundle, !skipCloudKit else {
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
        }
    }
}

// MARK: - Root View (Handles Onboarding vs Main App)

struct RootView: View {
    @EnvironmentObject var cloudKitService: CloudKitService
    @State private var showShareError = false
    @State private var shareErrorMessage = ""

    var body: some View {
        Group {
            if !cloudKitService.hasLoadedInitialState && cloudKitService.couple == nil {
                LoadingView()
            } else if cloudKitService.couple == nil || cloudKitService.needsPartnerName {
                CoupleOnboardingView()
            } else {
                HomeView(cloudKitService: cloudKitService)
            }
        }
        .animation(.easeInOut, value: cloudKitService.isPaired)
        .onChange(of: cloudKitService.errorMessage) { _, message in
            guard let message, !message.isEmpty else { return }
            shareErrorMessage = message
            showShareError = true
            cloudKitService.errorMessage = nil
        }
        .alert("Couldn't Join", isPresented: $showShareError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(shareErrorMessage)
        }
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        ZStack {
            CozyBackground()

            VStack(spacing: 24) {
                PekiMascot(mood: .sleepy, tint: .pekisLightPurple, size: 130)

                Text("Waking up…")
                    .font(PekisFont.headline())
                    .foregroundStyle(.pekisInk)

                ProgressView()
                    .tint(.pekisPurple)
            }
        }
    }
}
