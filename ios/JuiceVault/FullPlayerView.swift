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
            Color.vaultBg.ignoresSafeArea()

            if let url = player.currentSong?.coverURL {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .scaledToFill()
                            .blur(radius: 70)
                            .opacity(0.4)
                    }
                }
                .ignoresSafeArea()
            }
            LinearGradient(
                colors: [.clear, Color.vaultBg.opacity(0.9)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
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
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(
                                Circle()
                                    .fill(Color.vaultCard)
                                    .overlay(Circle().strokeBorder(Color.vaultStroke))
                            )
                    }
                }
                .padding(.top, 8)

                Spacer(minLength: 0)

                bigArt

                songInfo

                slider

                controls

                actionRow

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 26)
            .padding(.bottom, 20)
        }
        .sheet(isPresented: $showShareSheet) {
            if let shareURL {
                ShareSheet(items: [shareURL])
            }
        }
    }

    private var bigArt: some View {
        Group {
            if let url = player.currentSong?.coverURL {
                ArtworkView(url: url, size: 300, corner: 28)
            } else {
                ArtworkView(url: nil, size: 300, corner: 28)
            }
        }
        .shadow(color: Color.vaultAccent.opacity(0.35), radius: 34, y: 14)
    }

    private var songInfo: some View {
        VStack(spacing: 6) {
            Text(player.currentSong?.title ?? "")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            HStack(spacing: 8) {
                if player.isPlaying {
                    EqualizerBars(playing: true)
                }
                Text(player.currentSong?.artist ?? "")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.vaultAccent)
                    .lineLimit(1)
            }
            if let album = player.currentSong?.album {
                Text(album)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
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
            .tint(Color.vaultAccent)
            HStack {
                Text(player.formattedTime(player.currentTime))
                    .font(.system(size: 11, weight: .medium))
                Spacer()
                Text(player.formattedTime(player.duration))
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(.secondary)
        }
    }

    private var controls: some View {
        HStack(spacing: 44) {
            Button {
                player.previous()
                Vibe.tap()
            } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 27))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 44, height: 44)
            }
            Button {
                player.togglePlay()
                Vibe.tap()
            } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 76, height: 76)
                    .background(
                        Circle()
                            .fill(LinearGradient.vaultGradient)
                            .shadow(color: Color.vaultAccent.opacity(0.5), radius: 20, y: 8)
                    )
            }
            Button {
                player.next()
                Vibe.tap()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 27))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.top, 6)
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
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(Color.vaultGold)
                    .frame(width: 52, height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.vaultCard)
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.vaultStroke))
                    )
            }

            Button {
                download()
            } label: {
                HStack(spacing: 8) {
                    if isDownloading {
                        ProgressView().tint(.white).scaleEffect(0.85)
                    } else {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Text(isDownloading ? "Saving…" : "Save song")
                        .font(.system(size: 13, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.vaultCard)
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.vaultStroke))
                )
                .foregroundStyle(.white)
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