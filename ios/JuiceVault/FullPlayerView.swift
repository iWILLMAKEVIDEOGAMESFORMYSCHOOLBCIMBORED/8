import SwiftUI
import UIKit

struct FullPlayerView: View {
    @ObservedObject private var player = PlayerModel.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var shareURL: URL?
    @State private var isDownloading = false

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.down").font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white).padding(8)
                }
            }

            Spacer()

            bigArt

            VStack(spacing: 8) {
                Text(player.currentSong?.title ?? "")
                    .font(.title2.bold()).foregroundStyle(.white).lineLimit(2).multilineTextAlignment(.center)
                Text(player.currentSong?.artist ?? "")
                    .font(.subheadline).foregroundStyle(Color(red: 0.5, green: 0.85, blue: 0.45))
                if let album = player.currentSong?.album {
                    Text(album).font(.footnote).foregroundStyle(.secondary)
                }
            }

            slider

            controls

            Spacer()

            Button {
                if let song = player.currentSong { player.toggleFavorite(song) }
            } label: {
                Image(systemName: player.currentSong.map { player.isFavorite($0) } == true ? "heart.fill" : "heart")
                    .font(.system(size: 26))
                    .foregroundStyle(Color(red: 0.5, green: 0.85, blue: 0.45))
            }

            Button {
                download()
            } label: {
                HStack(spacing: 8) {
                    if isDownloading {
                        ProgressView()
                    } else {
                        Image(systemName: "square.and.arrow.down")
                    }
                    Text(isDownloading ? "Saving…" : "Save song")
                        .font(.system(size: 13, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(red: 0.16, green: 0.13, blue: 0.26), in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.white)
            }
            .disabled(isDownloading)
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 28)
        .background(Color(red: 0.06, green: 0.05, blue: 0.09))
        .sheet(isPresented: $showShareSheet) {
            if let shareURL {
                ShareSheet(items: [shareURL])
            }
        }
    }

    private var bigArt: some View {
        AsyncImage(url: player.currentSong?.coverURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            default:
                ZStack {
                    LinearGradient(colors: [Color(red: 0.2, green: 0.15, blue: 0.35), Color(red: 0.08, green: 0.1, blue: 0.15)], startPoint: .top, endPoint: .bottom)
                    Text("999").font(.system(size: 72, weight: .black))
                        .foregroundStyle(Color(red: 0.5, green: 0.85, blue: 0.45))
                }
            }
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.6), radius: 18, y: 8)
    }

    private var slider: some View {
        VStack(spacing: 6) {
            Slider(
                value: Binding(
                    get: { player.currentTime },
                    set: { player.seek(to: $0) }
                ),
                in: 0...max(player.duration, 1)
            )
            .tint(Color(red: 0.5, green: 0.85, blue: 0.45))
            HStack {
                Text(player.formattedTime(player.currentTime)).font(.system(size: 11, weight: .medium))
                Spacer()
                Text(player.formattedTime(player.duration)).font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(.secondary)
        }
    }

    private var controls: some View {
        HStack(spacing: 48) {
            Button { player.previous() } label: {
                Image(systemName: "backward.fill").font(.system(size: 28)).foregroundStyle(.white)
            }
            Button { player.togglePlay() } label: {
                Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 68)).foregroundStyle(Color(red: 0.5, green: 0.85, blue: 0.45))
            }
            Button { player.next() } label: {
                Image(systemName: "forward.fill").font(.system(size: 28)).foregroundStyle(.white)
            }
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