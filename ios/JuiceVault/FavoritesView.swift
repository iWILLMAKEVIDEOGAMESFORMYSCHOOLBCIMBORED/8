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
                    VStack(spacing: 12) {
                        Image(systemName: "heart").font(.system(size: 44))
                            .foregroundStyle(Color(red: 0.5, green: 0.85, blue: 0.45))
                        Text("No favorites yet").font(.headline).foregroundStyle(.white)
                        Text("Tap the heart in the player to save songs here.")
                            .font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(favs) { song in
                                Button {
                                    player.play(song, in: favs)
                                } label: {
                                    SongRowView(song: song, isFavorite: true)
                                }
                                .buttonStyle(.plain)
                                Divider().background(Color.white.opacity(0.06))
                            }
                        }
                        .padding(.bottom, 90)
                    }
                }
            }
            .background(Color(red: 0.06, green: 0.05, blue: 0.09))
            .navigationTitle("Favorites")
        }
    }
}
