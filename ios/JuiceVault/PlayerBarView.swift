import SwiftUI

struct PlayerBarView: View {
    @ObservedObject private var player = PlayerModel.shared
    @Binding var showFullPlayer: Bool

    var body: some View {
        if let song = player.currentSong {
            HStack(spacing: 12) {
                AsyncImage(url: song.coverURL) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFill()
                    } else {
                        Color(red: 0.16, green: 0.13, blue: 0.26)
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(song.title).font(.system(size: 13, weight: .semibold))
                        .lineLimit(1).foregroundStyle(.white)
                    Text(song.artist).font(.system(size: 11))
                        .lineLimit(1).foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    player.togglePlay()
                } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                }

                Button {
                    player.next()
                } label: {
                    Image(systemName: "forward.fill").font(.system(size: 16))
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(
                Color(red: 0.11, green: 0.09, blue: 0.17)
                    .overlay(alignment: .bottom) {
                        GeometryReader { geo in
                            VStack(spacing: 0) {
                                Spacer(minLength: 0)
                                Rectangle()
                                    .fill(Color(red: 0.5, green: 0.85, blue: 0.45))
                                    .frame(width: geo.size.width * barProgress, height: 2)
                            }
                        }
                        .allowsHitTesting(false)
                    }
            )
            .contentShape(Rectangle())
            .onTapGesture { showFullPlayer = true }
        }
    }

    private var barProgress: CGFloat {
        guard player.duration > 0 else { return 0 }
        return CGFloat(min(player.currentTime / player.duration, 1))
    }
}
