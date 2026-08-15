import SwiftUI

struct PlayerBarView: View {
    @ObservedObject private var player = PlayerModel.shared
    @Binding var showFullPlayer: Bool

    var body: some View {
        if let song = player.currentSong {
            HStack(spacing: 12) {
                ArtworkView(url: song.coverURL, size: 44, corner: 10)
                VStack(alignment: .leading, spacing: 3) {
                    Text(song.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(song.artist)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
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
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(LinearGradient.vaultGradient))
                }
                Button {
                    player.next()
                    Vibe.tap()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.85))
                        .frame(width: 30, height: 30)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.12))
                    )
            )
            .overlay(alignment: .bottom) {
                GeometryReader { geo in
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        Capsule()
                            .fill(LinearGradient.vaultGradient)
                            .frame(width: geo.size.width * barProgress, height: 2.5)
                    }
                }
                .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                showFullPlayer = true
                Vibe.tap()
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 6)
        }
    }

    private var barProgress: CGFloat {
        guard player.duration > 0 else { return 0 }
        return CGFloat(min(player.currentTime / player.duration, 1))
    }
}