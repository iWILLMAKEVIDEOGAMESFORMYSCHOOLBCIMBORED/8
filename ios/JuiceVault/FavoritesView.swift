import SwiftUI

struct FavoritesView: View {
    @ObservedObject private var player = PlayerModel.shared

    private var favs: [Song] {
        player.favorites.values.sorted { $0.title < $1.title }
    }

    var body: some View {
        NavigationStack {
            Group {
                if favs.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Theme.gold)
                            .frame(width: 76, height: 76)
                            .background(Circle().fill(Theme.raised))
                        Text("No favorites yet")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Theme.primaryText)
                        Text("Tap the heart in the player to\nkeep your favorite tracks here.")
                            .font(.footnote)
                            .foregroundStyle(Theme.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            Text("\(favs.count) SAVED")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(2)
                                .foregroundStyle(Theme.tertiaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                                .padding(.bottom, 6)
                            ForEach(favs) { song in
                                Button {
                                    if player.currentSong?.id == song.id && player.isPlaying {
                                        player.togglePlay()
                                    } else {
                                        player.play(song, in: favs)
                                    }
                                    Vibe.tap()
                                } label: {
                                    SongRow(
                                        song: song,
                                        isFavorite: true,
                                        isCurrent: player.currentSong?.id == song.id
                                    )
                                }
                                .buttonStyle(RowPress())
                                Divider()
                                    .overlay(Theme.hairline)
                                    .padding(.leading, 76)
                            }
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
            .background(Theme.bg)
            .navigationTitle("Favorites")
        }
    }
}