import SwiftUI

struct LoveNoteView: View {
    @StateObject private var viewModel: LoveNoteViewModel
    let onExit: () -> Void

    @State private var selectedTab = 0

    init(cloudKitService: any CloudKitServiceProtocol, onExit: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: LoveNoteViewModel(cloudKitService: cloudKitService))
        self.onExit = onExit
    }

    var body: some View {
        VStack(spacing: 18) {
            CozyHeader(title: "Love Notes", tint: .pekisBerry, onHome: onExit)

            Picker("View", selection: $selectedTab) {
                Text("Write").tag(0)
                Text("Received").tag(1)
            }
            .pickerStyle(.segmented)
            .tint(.pekisBerry)
            .padding(.horizontal)

            if selectedTab == 0 {
                writeNoteSection
            } else {
                receivedNotesSection
            }

            Spacer()
        }
        .onAppear {
            Task { await viewModel.fetchNotes() }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }

    private var writeNoteSection: some View {
        VStack(spacing: 18) {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.note)
                    .scrollContentBackground(.hidden)
                    .frame(height: 260)
                    .padding(12)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(.pekisInk)
                    .cozyCard(accent: .pekisBerry)

                if viewModel.note.isEmpty {
                    Text("Write something sweet…")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(.pekisInkSoft)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 20)
                        .allowsHitTesting(false)
                }
            }

            HStack(spacing: 12) {
                Button {
                    viewModel.copyNote()
                } label: {
                    Label(
                        viewModel.hasCopied ? "Copied!" : "Copy",
                        systemImage: viewModel.hasCopied ? "checkmark" : "doc.on.doc"
                    )
                }
                .buttonStyle(CapsuleButtonStyle(background: .pekisSurfaceSoft, foreground: .pekisInk))
                .disabled(viewModel.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button {
                    Task { await viewModel.sendNote() }
                } label: {
                    if viewModel.isSending {
                        ProgressView().tint(.white)
                    } else {
                        Label("Send", systemImage: "paperplane.fill")
                    }
                }
                .buttonStyle(SquishyButtonStyle(tint: .pekisBerry))
                .disabled(
                    viewModel.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || viewModel.isSending
                )
            }
        }
    }

    private var receivedNotesSection: some View {
        Group {
            if viewModel.receivedNotes.isEmpty {
                VStack(spacing: 16) {
                    PekiMascot(mood: .hopeful, tint: .pekisBerry, size: 90)
                    Text("No notes yet")
                        .font(PekisFont.headline())
                        .foregroundStyle(.pekisInk)
                    Text("Send a note to your partner!")
                        .font(PekisFont.body())
                        .foregroundStyle(.pekisInkSoft)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(viewModel.receivedNotes) { note in
                            NoteCard(
                                note: note,
                                isFromMe: note.isFromCurrentUser(currentUserID: viewModel.currentUserID ?? "")
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }
}

// MARK: - Note Card

private struct NoteCard: View {
    let note: LoveNote
    let isFromMe: Bool

    var body: some View {
        VStack(alignment: isFromMe ? .trailing : .leading, spacing: 6) {
            HStack {
                if isFromMe { Spacer() }
                Text(note.content)
                    .font(PekisFont.body())
                    .foregroundStyle(isFromMe ? .white : .pekisInk)
                    .padding(14)
                    .background(
                        isFromMe ? Color.pekisBerry : Color.pekisSurface,
                        in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.pekisHairline, lineWidth: isFromMe ? 0 : 1)
                    )
                    .shadow(color: (isFromMe ? Color.pekisBerry : Color.pekisInk).opacity(0.12), radius: 8, y: 4)
                if !isFromMe { Spacer() }
            }

            Text(note.formattedDate)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.pekisInkSoft)
                .padding(.horizontal, 8)
        }
    }
}

#if DEBUG
#Preview {
    ZStack {
        CozyBackground()
        LoveNoteView(cloudKitService: MockCloudKitService(), onExit: {}).padding()
    }
}
#endif
