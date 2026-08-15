import SwiftUI
import UIKit

struct FullPlayerView: View {
    @ObservedObject private var player = PlayerModel.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var shareURL: URL?
    @State private var isDownloading = false
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
                            .opacity(0.35)
                    }
                }
                .ignoresSafeArea()
            }
            LinearGradient(
                colors: [.clear, Theme.bg.opacity(0.95)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

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
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Theme.primaryText)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(Color.black.opacity(0.35)))
                    }
                }
                .padding(.top, 12)

                Spacer(minLength: 12)

                Group {
                    if let url = player.currentSong?.coverURL {
                        ArtworkView(url: url, size: 300, radius: 24)
                    } else {
                        ArtworkView(url: nil, size: 300, radius: 24)
                    }
                }
                .shadow(color: .black.opacity(0.45), radius: 36, y: 16)

                Spacer(minLength: 32)

                VStack(spacing: 8) {
                    Text(player.currentSong?.title ?? "")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Theme.primaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    HStack(spacing: 8) {
                        if player.isPlaying {
                            EqualizerBars(playing: true)
                        }
                        Text(player.currentSong?.artist ?? "")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.secondaryText)
                            .lineLimit(1)
                            .padding(.leading, player.isPlaying ? 2 : 0)
                    }
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 24)

                slider
                    .padding(.horizontal, 26)

                controls
                    .padding(.top, 14)

                actionRow
                    .padding(.top, 22)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 26)
            .padding(.bottom, 24)
        }
        .id(player.currentSong?.id ?? "none")
        .animation(.easeInOut(duration: 0.22), value: player.currentSong?.id)
        .sheet(isPresented: $showShareSheet) {
            if let shareURL {
                ShareSheet(items: [shareURL])
            }
        }
    }

    private var slider: some View {
        VStack(spacing: 4) {
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
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                Text(player.formattedTime(player.duration))
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(Theme.secondaryText)
        }
    }

    private var controls: some View {
        HStack(spacing: 46) {
            Button {
                player.previous()
                Vibe.tap()
            } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(Theme.primaryText.opacity(0.9))
                    .frame(width: 40, height: 40)
            }
            Button {
                player.togglePlay()
                Vibe.tap()
            } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 29, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(width: 74, height: 74)
                    .background(
                        Circle()
                            .fill(Theme.accent)
                            .shadow(color: Theme.accent.opacity(0.35), radius: 18, y: 8)
                    )
            }
            Button {
                player.next()
                Vibe.tap()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(Theme.primaryText.opacity(0.9))
                    .frame(width: 40, height: 40)
            }
        }
    }

    private var actionRow: some View {
        HStack(spacing: 12) {
            Button {
                if let song = player.currentSong {
                    player.toggleFavorite(song)
                    Vibe.tap()
                }
            } label: {
                Image(systemName: player.currentSong.map { player.isFavorite($0) } == true ? "heart.fill" : "heart")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.gold)
                    .frame(width: 52, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .fill(Theme.raised)
                    )
            }

            Button {
                download()
            } label: {
                HStack(spacing: 8) {
                    if isDownloading {
                        ProgressView().tint(.white).scaleEffect(0.8)
                    } else {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Text(isDownloading ? "Saving…" : "Save song")
                        .font(.system(size: 13, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(Theme.raised)
                )
                .foregroundStyle(Theme.primaryText)
            }
            .disabled(isDownloading)
        }
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
                shareURL = dest
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