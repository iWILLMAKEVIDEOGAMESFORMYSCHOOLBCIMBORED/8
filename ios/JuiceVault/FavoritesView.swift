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
                    VStack(spacing: 14) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 42))
                            .foregroundStyle(LinearGradient.vaultGlow)
                            .shadow(color: Color.vaultGold.opacity(0.35), radius: 14)
                        Text("No favorites yet")
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                        Text("Tap the heart in the player\nto keep your favorite tracks here.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            Text("\(favs.count) SAVED")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(2)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.top, 6)
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
                                .buttonStyle(.plain)
                                Divider()
                                    .overlay(Color.white.opacity(0.05))
                                    .padding(.leading, 76)
                            }
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
            .background(Color.vaultBg)
            .navigationTitle("Favorites")
        }
    }
}