//
//  PekisSceneDelegate.swift
//  Pekis
//
//  SwiftUI apps backed by WindowGroup use UIWindowScene internally. iOS routes
//  CloudKit share-link taps to UIWindowSceneDelegate.windowScene(_:userDidAcceptCloudKitShareWith:)
//  rather than UIApplicationDelegate.application(_:userDidAcceptCloudKitShareWith:).
//  This delegate captures that call and forwards it to AppDelegate.handleCloudKitShare(_:).
//
//  AppDelegate registers this class via application(_:configurationForConnecting:options:).
//

import CloudKit
import OSLog
import UIKit

final class PekisSceneDelegate: UIResponder, UIWindowSceneDelegate {
    // Cold launch from a share link delivers metadata in connectionOptions, not via
    // windowScene(_:userDidAcceptCloudKitShareWith:). Handle both paths.
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let metadata = connectionOptions.cloudKitShareMetadata else { return }
        PekisLogger.app.debug("PekisSceneDelegate: scene willConnectTo cloudKitShareMetadata, shareURL=\(metadata.share.url?.absoluteString ?? "nil", privacy: .public)")
        forwardShare(metadata)
    }

    func windowScene(
        _ windowScene: UIWindowScene,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
    ) {
        PekisLogger.app.debug("PekisSceneDelegate: windowScene userDidAcceptCloudKitShareWith fired, shareURL=\(cloudKitShareMetadata.share.url?.absoluteString ?? "nil", privacy: .public)")
        forwardShare(cloudKitShareMetadata)
    }

    private func forwardShare(_ metadata: CKShare.Metadata) {
        guard let appDelegate = AppDelegate.shared else {
            PekisLogger.app.error("PekisSceneDelegate: AppDelegate.shared is nil")
            return
        }
        appDelegate.handleCloudKitShare(metadata)
    }
}
