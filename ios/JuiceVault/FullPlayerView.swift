import SwiftUI
import UIKit

struct FullPlayerView: View {
    @ObservedObject private var player = PlayerModel.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var isDownloading = false
    @State private var showPlaylists = false
    @State private var isDragging = false
    @State private var dragValue: Double?

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            if let url = player.currentSong?.coverURL {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .scaledToFill()
                            .blur(radius: 60)
                            .opacity(0.28)
                    }
                }
                .ignoresSafeArea()
            }

            VStack(spacing: 0) {
                HStack {
                    Capsule()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 42, height: 4)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Theme.primaryText)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(Color.black.opacity(0.35)))
                    }
                }
                .padding(.top, 12)
                .padding(.horizontal, 26)

                Spacer(minLength: 8)

                Group {
                    if let url = player.currentSong?.coverURL {
                        ArtworkView(url: url, size: 210, radius: 18)
                    } else {
                        ArtworkView(url: nil, size: 210, radius: 18)
                    }
                }
                .shadow(color: .black.opacity(0.45), radius: 28, y: 12)

                Spacer(minLength: 18)

                VStack(spacing: 6) {
                    Text(player.currentSong?.title ?? "")
                        .font(.system(size: 19, weight: .medium))
                        .foregroundStyle(Theme.primaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    Text(player.currentSong?.artist ?? "")
                        .font(.system(size: 13.5))
                        .foregroundStyle(Theme.secondaryText)
                        .lineLimit(1)
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 22)

                slider
                    .padding(.horizontal, 26)

                controls
                    .padding(.top, 16)

                actions
                    .padding(.top, 20)
                    .padding(.horizontal, 26)

                Spacer(minLength: 0)
            }
            .padding(.bottom, 24)
        }
        .id(player.currentSong?.id ?? "none")
        .animation(.easeInOut(duration: 0.2), value: player.currentSong?.id)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: shareItems)
        }
        .sheet(isPresented: $showPlaylists) {
            if let song = player.currentSong {
                AddToPlaylistSheet(song: song)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    // MARK: Seek

    private var slider: some View {
        VStack(spacing: 5) {
            Slider(
                value: Binding(
                    get: { isDragging ? (dragValue ?? player.currentTime) : player.currentTime },
                    set: { dragValue = $0 }
                ),
                in: 0...max(player.duration, 1),
                onEditingChanged: { editing in
                    if editing {
                        isDragging = true
                        dragValue = player.currentTime
                    } else {
                        isDragging = false
                        if let v = dragValue { player.seek(to: v) }
                        dragValue = nil
                    }
                }
            )
            .tint(Theme.accent)
            HStack {
                Text(player.formattedTime(player.currentTime))
                    .font(.system(size: 11, weight: .regular))
                Spacer()
                Text(player.formattedTime(player.duration))
                    .font(.system(size: 11, weight: .regular))
            }
            .foregroundStyle(Theme.secondaryText)
        }
    }

    // MARK: Transport

    private var controls: some View {
        HStack(spacing: 46) {
            Button {
                player.previous()
                Vibe.tap()
            } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Theme.primaryText.opacity(0.9))
                    .frame(width: 40, height: 40)
            }
            Button {
                player.togglePlay()
                Vibe.tap()
            } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 27, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 70, height: 70)
                    .background(
                        Circle()
                            .fill(Theme.accent)
                            .shadow(color: Theme.accent.opacity(0.35), radius: 16, y: 7)
                    )
            }
            Button {
                player.next()
                Vibe.tap()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Theme.primaryText.opacity(0.9))
                    .frame(width: 40, height: 40)
            }
        }
    }

    // MARK: Actions

    private var actions: some View {
        HStack(spacing: 0) {
            actionButton(
                icon: player.currentSong.map { player.isFavorite($0) } == true ? "heart.fill" : "heart",
                label: player.currentSong.map { player.isFavorite($0) } == true ? "Liked" : "Like",
                color: player.currentSong.map { player.isFavorite($0) } == true ? Theme.gold : Theme.secondaryText
            ) {
                if let song = player.currentSong {
                    player.toggleFavorite(song)
                    Vibe.tap()
                }
            }
            actionButton(icon: "text.badge.plus", label: "Playlist", color: Theme.secondaryText) {
                showPlaylists = true
                Vibe.tap()
            }
            actionButton(icon: "arrow.down.circle", label: "Save", color: Theme.secondaryText) {
                download()
            }
            actionButton(icon: "square.and.arrow.up", label: "Share", color: Theme.secondaryText) {
                shareLink()
            }
        }
    }

    private func actionButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .regular))
                Text(label)
                    .font(.system(size: 10.5))
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isDownloading && label == "Save")
    }

    // MARK: Helpers

    private func shareLink() {
        guard let song = player.currentSong else { return }
        shareItems = [
            "\(song.title) — \(song.artist)",
            song.downloadURL.absoluteString
        ]
        showShareSheet = true
    }

    private func download() {
        guard let song = player.currentSong else { return }
        isDownloading = true
        Task {
            defer { Task { @MainActor in isDownloading = false } }
            do {
                let (tempURL, _) = try await URLSession.shared.download(from: song.downloadURL)
                let safeName = song.title
                    .replacingOccurrences(of: "/", with: "-")
                    .replacingOccurrences(of: ":", with: "-")
                let dest = FileManager.default.temporaryDirectory.appendingPathComponent("\(safeName).mp3")
                try? FileManager.default.removeItem(at: dest)
                try FileManager.default.moveItem(at: tempURL, to: dest)
                shareItems = [dest]
                showShareSheet = true
            } catch {
                isDownloading = false
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}