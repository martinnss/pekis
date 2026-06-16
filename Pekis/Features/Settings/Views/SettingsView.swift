import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var cloudKitService: CloudKitService
    @Environment(\.dismiss) private var dismiss

    @State private var showDisconnectConfirm = false
    @State private var isDisconnecting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                CozyBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        PekiMascot(mood: .happy, tint: .pekisPurple, size: 96)
                            .padding(.top, 12)

                        VStack(alignment: .leading, spacing: 14) {
                            Text("Danger Zone")
                                .font(PekisFont.caption())
                                .foregroundStyle(.pekisInkSoft)
                                .textCase(.uppercase)

                            Button(role: .destructive) {
                                HapticManager.impact(style: .medium)
                                showDisconnectConfirm = true
                            } label: {
                                HStack(spacing: 12) {
                                    CozyIconBadge(systemName: "heart.slash.fill", tint: .pekisCoral, size: 44)
                                    Text("Break Connection")
                                        .font(PekisFont.headline())
                                        .foregroundStyle(.pekisCoral)
                                    Spacer()
                                    if isDisconnecting {
                                        ProgressView().tint(.pekisCoral)
                                    }
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity)
                                .cozyCard(accent: .pekisCoral)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .disabled(isDisconnecting)

                            Text("Permanently disconnects you from your partner and erases all shared data for both of you. You'll both start over from scratch. This can't be undone.")
                                .font(PekisFont.caption())
                                .foregroundStyle(.pekisInkSoft)
                        }
                        .padding(.horizontal, 4)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.pekisCream, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .tint(.pekisPurple)
                }
            }
            .alert("Break Connection?", isPresented: $showDisconnectConfirm) {
                Button("Break Connection", role: .destructive) { disconnect() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("All shared data will be erased for both you and your partner, and you'll start over. This can't be undone.")
            }
            .alert(
                "Couldn't Disconnect",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func disconnect() {
        isDisconnecting = true
        Task {
            do {
                try await cloudKitService.disconnectCouple()
                HapticManager.notification(type: .success)
                dismiss()
            } catch {
                HapticManager.notification(type: .error)
                errorMessage = error.localizedDescription
            }
            isDisconnecting = false
        }
    }
}
