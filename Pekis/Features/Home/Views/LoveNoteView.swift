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
        VStack(spacing: 20) {
            header

            // Tab selector
            Picker("View", selection: $selectedTab) {
                Text("Write").tag(0)
                Text("Received").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            if selectedTab == 0 {
                writeNoteSection
            } else {
                receivedNotesSection
            }

            Spacer()
        }
        .onAppear {
            Task {
                await viewModel.fetchNotes()
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }

    private var writeNoteSection: some View {
        VStack(spacing: 20) {
            TextEditor(text: $viewModel.note)
                .frame(height: 280)
                .padding()
                .background(.white.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(.pink.opacity(0.3), lineWidth: 1)
                )
                .font(.title3)
                .foregroundStyle(.gray)

            HStack(spacing: 12) {
                Button(action: viewModel.copyNote) {
                    Label(
                        viewModel.hasCopied ? "Copied!" : "Copy",
                        systemImage: viewModel.hasCopied ? "checkmark" : "doc.on.doc"
                    )
                }
                .buttonStyle(CapsuleButtonStyle(background: .white.opacity(0.2), foreground: .white))
                .disabled(viewModel.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button {
                    Task {
                        await viewModel.sendNote()
                    }
                } label: {
                    if viewModel.isSending {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Label("Send to Partner", systemImage: "paperplane.fill")
                    }
                }
                .buttonStyle(CapsuleButtonStyle(background: .pink, foreground: .white))
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
                    Image(systemName: "heart.text.square")
                        .font(.system(size: 60))
                        .foregroundStyle(.white.opacity(0.3))
                    Text("No notes yet")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.6))
                    Text("Send a note to your partner!")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
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

    private var header: some View {
        HStack {
            Button(action: onExit) {
                Image(systemName: "house.fill")
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(.white.opacity(0.2))
                    .clipShape(Circle())
            }
            Spacer()
            Text("Love Notes")
                .font(.title2.bold())
                .foregroundStyle(.white)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
    }
}

// MARK: - Note Card

private struct NoteCard: View {
    let note: LoveNote
    let isFromMe: Bool

    var body: some View {
        VStack(alignment: isFromMe ? .trailing : .leading, spacing: 8) {
            HStack {
                if isFromMe { Spacer() }
                Text(note.content)
                    .font(.body)
                    .foregroundStyle(isFromMe ? .white : .primary)
                    .padding()
                    .background(isFromMe ? Color.pink : Color.white.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                if !isFromMe { Spacer() }
            }

            Text(note.formattedDate)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
                .padding(.horizontal, 8)
        }
    }
}

#Preview {
    LoveNoteView(cloudKitService: MockCloudKitService(), onExit: {})
}
