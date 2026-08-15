import SwiftUI

struct PlayerBarView: View {
    @ObservedObject private var player = PlayerModel.shared
    @Binding var showFullPlayer: Bool

    var body: some View {
        if let song = player.currentSong {
            HStack(spacing: 12) {
                ArtworkView(url: song.coverURL, size: 40, radius: 8)
                VStack(alignment: .leading, spacing: 2) {
                    Text(song.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.primaryText)
                        .lineLimit(1)
                    Text(song.artist)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.secondaryText)
                        .lineLimit(1)
                }
                Spacer()
                if player.isPlaying {
                    EqualizerBars(playing: true)
                        .padding(.trailing, 2)
                }
                Button {
                    player.togglePlay()
                    Vibe.tap()
                } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(Theme.accent))
                }
                Button {
                    player.next()
                    Vibe.tap()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.primaryText.opacity(0.85))
                        .frame(width: 30, height: 30)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .overlay(alignment: .top) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                            .frame(height: 2)
                        Capsule()
                            .fill(Theme.accent)
                            .frame(width: geo.size.width * barProgress, height: 2)
                    }
                }
                .frame(height: 2)
                .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                showFullPlayer = true
                Vibe.tap()
            }
        }
    }

    private var barProgress: CGFloat {
        guard player.duration > 0 else { return 0 }
        return CGFloat(min(player.currentTime / player.duration, 1))
    }
}