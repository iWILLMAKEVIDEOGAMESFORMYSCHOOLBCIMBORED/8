import SwiftUI

struct Shelf: Identifiable {
    let id: String
    let title: String
    let icon: String
    let colors: [Color]
    let songs: [Song]
}

struct HomeView: View {
    @ObservedObject private var radio = RadioModel.shared
    @ObservedObject private var player = PlayerModel.shared
    @State private var stats: StatsResponse?
    @State private var shelves: [Shelf] = []
    @State private var isLoaded = false
    @State private var failed = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    miniHeader
                    if isLoaded {
                        if let stats {
                            shelfSection(mostPlayedShelf(stats))
                        }
                        ForEach(shelves) { shelf in
                            shelfSection(shelf)
                        }
                        if shelves.isEmpty && stats == nil {
                            emptyBlock
                        }
                        radioBanner
                    } else if failed {
                        errorBlock
                    } else {
                        ShelfSkeleton()
                        ShelfSkeleton()
                        ShelfSkeleton()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 30)
            }
            .background(Theme.bg)
            .refreshable { await load() }
            .task { await load() }
        }
    }

    // MARK: Header

    private var miniHeader: some View {
        HStack {
            Text("999")
                .font(Theme.display(16, .black))
                .foregroundStyle(.white)
                .padding(.horizontal, 15)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(colors: [Theme.accent, Theme.violet], startPoint: .leading, endPoint: .trailing),
                    in: Capsule()
                )
                .shadow(color: Theme.accent.opacity(0.45), radius: 12, y: 4)
            Spacer()
            Image(systemName: "waveform")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.tertiaryText)
        }
        .padding(.top, 6)
    }

    // MARK: Shelves

    private func mostPlayedShelf(_ stats: StatsResponse) -> Shelf {
        Shelf(
            id: "top",
            title: "Most Played",
            icon: "flame.fill",
            colors: [Theme.gold, Theme.accent],
            songs: Array(stats.top_songs.prefix(15).map(\.song))
        )
    }

    private func shelfSection(_ shelf: Shelf) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 8) {
                Image(systemName: shelf.icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.leading, 12)
                Text(shelf.title.uppercased())
                    .font(.system(size: 13, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(.white)
                    .padding(.trailing, 13)
                    .padding(.vertical, 1)
            }
            .padding(.vertical, 7)
            .background(
                LinearGradient(colors: shelf.colors, startPoint: .topLeading, endPoint: .bottomTrailing),
                in: Capsule()
            )
            .shadow(color: shelf.colors[0].opacity(0.35), radius: 10, y: 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(Array(shelf.songs.enumerated()), id: \.element.id) { index, song in
                        Button {
                            playOrToggle(song, in: shelf.songs)
                        } label: {
                            ShelfCard(song: song, rank: shelf.id == "top" ? index + 1 : nil)
                        }
                        .buttonStyle(RowPress())
                    }
                }
                .padding(.bottom, 2)
            }
        }
    }

    // MARK: Radio banner

    private var radioBanner: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 7) {
                Circle()
                    .fill(radio.isPlaying ? Theme.danger : Color.white)
                    .frame(width: 8, height: 8)
                Text("LIVE")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(2)
                    .foregroundStyle(.white)
                Spacer()
                Text("24/7 vault radio")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.75))
            }
            HStack(spacing: 14) {
                ArtworkView(url: radio.nowPlaying?.song.coverURL, size: 88, radius: 12)
                VStack(alignment: .leading, spacing: 4) {
                    Text(radio.nowPlaying?.title ?? "999 RADIO")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Text(radio.nowPlaying?.artist ?? "Tune in — the vault never sleeps")
                        .font(.system(size: 13.5))
                        .foregroundStyle(Color.white.opacity(0.85))
                        .lineLimit(1)
                }
                Spacer()
                Button {
                    radio.toggle()
                    Vibe.tap()
                } label: {
                    Image(systemName: radio.isPlaying ? "stop.fill" : "play.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(radio.isPlaying ? Theme.danger : Theme.accent)
                        .frame(width: 58, height: 58)
                        .background(Circle().fill(.white))
                        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
                }
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Theme.accent, Theme.violet, Color(red: 0.24, green: 0.12, blue: 0.44)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .shadow(color: Theme.accent.opacity(0.35), radius: 22, y: 10)
    }

    // MARK: States

    private var errorBlock: some View {
        VStack(spacing: 10) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 26))
                .foregroundStyle(Theme.tertiaryText)
            Text("Could not reach the vault. Check your connection and pull to retry.")
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
            Button("Try again") {
                Task { await load() }
            }
            .font(.system(size: 13, weight: .semibold))
            .buttonStyle(.bordered)
            .tint(Theme.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
    }

    private var emptyBlock: some View {
        Text("Nothing here yet — pull to refresh.")
            .font(.footnote)
            .foregroundStyle(Theme.secondaryText)
            .frame(maxWidth: .infinity)
            .padding(.top, 20)
    }

    // MARK: Data

    private func load() async {
        async let statsTask = APIClient.stats()
        let songs = await PlayerModel.ensureCatalog()
        do {
            let s = try await statsTask
            stats = s
            buildShelves(songs)
            isLoaded = true
            failed = false
        } catch {
            stats = nil
            failed = true
            isLoaded = false
        }
        Task { await radio.refresh() }
    }

    private func buildShelves(_ songs: [Song]) {
        let defs: [(String, String, String, [Color])] = [
            ("main", "Unreleased", "sparkles", [Theme.violet, Theme.accent]),
            ("released", "Released", "checkmark.seal.fill", [Theme.accent, Color(red: 1.0, green: 0.5, blue: 0.3)]),
            ("instrumental", "Instrumentals", "waveform", [Color(red: 0.2, green: 0.72, blue: 1.0), Color(red: 0.1, green: 0.6, blue: 0.8)]),
            ("stem", "Stems", "slider.horizontal.3", [Color(red: 0.37, green: 0.9, blue: 0.55), Color(red: 0.1, green: 0.72, blue: 0.6)]),
            ("cut", "Cuts", "scissors", [Color(red: 0.3, green: 0.5, blue: 1.0), Theme.violet]),
            ("remaster", "Remasters", "star.fill", [Theme.gold, Color(red: 1.0, green: 0.55, blue: 0.3)])
        ]
        shelves = defs.compactMap { def in
            let found = songs.filter { $0.category == def.0 }
            guard !found.isEmpty else { return nil }
            return Shelf(id: def.0, title: def.1, icon: def.2, colors: def.3, songs: Array(found.prefix(12)))
        }
    }

    private func playOrToggle(_ song: Song, in list: [Song]) {
        if player.currentSong?.id == song.id && player.isPlaying {
            player.togglePlay()
        } else {
            player.play(song, in: list)
        }
        Vibe.tap()
    }
}

// MARK: - Shelf pieces

struct ShelfCard: View {
    let song: Song
    var rank: Int? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ArtworkView(url: song.coverURL, size: 140, radius: 14)
                .overlay(alignment: .topLeading) {
                    if let rank {
                        Text("\(rank)")
                            .font(Theme.display(12, .black))
                            .foregroundStyle(rank == 1 ? .black : .white)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(rank == 1 ? Theme.gold : Color.black.opacity(0.55)))
                            .padding(6)
                    }
                }
            Text(song.title)
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundStyle(Theme.primaryText)
                .lineLimit(2)
                .frame(height: 36, alignment: .top)
            Text(song.artist)
                .font(.system(size: 12))
                .foregroundStyle(Theme.secondaryText)
                .lineLimit(1)
        }
        .frame(width: 140, alignment: .leading)
        .contentShape(Rectangle())
    }
}

struct ShelfSkeleton: View {
    @State private var pulse = false

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Theme.raised)
                    .frame(width: 14, height: 14)
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Theme.raised)
                    .frame(width: 110, height: 13)
            }
            .padding(.vertical, 3)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(0..<3, id: \.self) { _ in
                        VStack(alignment: .leading, spacing: 8) {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Theme.raised)
                                .frame(width: 140, height: 140)
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(Theme.raised)
                                .frame(width: 100, height: 12)
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(Theme.raised)
                                .frame(width: 66, height: 10)
                        }
                    }
                }
            }
        }
        .opacity(pulse ? 0.45 : 1)
        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)
        .onAppear { pulse = true }
    }
}