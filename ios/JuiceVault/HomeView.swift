import SwiftUI

struct Shelf: Identifiable {
    let id: String
    let title: String
    let icon: String
    let songs: [Song]
}

struct HomeView: View {
    @ObservedObject private var radio = RadioModel.shared
    @ObservedObject private var player = PlayerModel.shared
    @State private var stats: StatsResponse?
    @State private var shelves: [Shelf] = []
    @State private var isLoaded = false
    @State private var failed = false
    @State private var showRadio = false

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
                        radioCard
                    } else if failed {
                        errorBlock
                    } else {
                        ShelfSkeleton()
                        ShelfSkeleton()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
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
                .font(Theme.display(15, .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Capsule().fill(Theme.accent))
            Spacer()
            Image(systemName: "waveform")
                .font(.system(size: 15))
                .foregroundStyle(Theme.tertiaryText)
        }
        .padding(.top, 4)
    }

    // MARK: Shelves

    private func mostPlayedShelf(_ stats: StatsResponse) -> Shelf {
        Shelf(
            id: "top",
            title: "Most Played",
            icon: "flame",
            songs: Array(stats.top_songs.prefix(15).map(\.song))
        )
    }

    private func shelfSection(_ shelf: Shelf) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 8) {
                Image(systemName: shelf.icon)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.accent)
                Text(shelf.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.primaryText)
                Spacer()
                Text("\(shelf.songs.count)")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.tertiaryText)
            }

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

    // MARK: Radio card

    private var radioCard: some View {
        Button {
            showRadio = true
            Vibe.tap()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Theme.deep)
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.system(size: 24))
                        .foregroundStyle(Theme.accent)
                }
                .frame(width: 56, height: 56)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(radio.isPlaying ? Theme.danger : Theme.accent)
                            .frame(width: 7, height: 7)
                        Text("LIVE")
                            .font(.system(size: 10.5, weight: .semibold))
                            .tracking(1.5)
                            .foregroundStyle(radio.isPlaying ? Theme.danger : Theme.accent)
                        Text("999 Radio")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.primaryText)
                            .padding(.leading, 4)
                    }
                    Text(radio.nowPlaying?.title ?? "Now playing — the vault, 24/7")
                        .font(.system(size: 12.5))
                        .foregroundStyle(Theme.secondaryText)
                        .lineLimit(1)
                }
                Spacer()
                if radio.isPlaying {
                    EqualizerBars(playing: true)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.tertiaryText)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.surface)
            )
        }
        .buttonStyle(RowPress())
        .fullScreenCover(isPresented: $showRadio) {
            RadioView()
        }
    }

    // MARK: States

    private var errorBlock: some View {
        VStack(spacing: 10) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 24))
                .foregroundStyle(Theme.tertiaryText)
            Text("Could not reach the vault. Check your connection and pull to retry.")
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
            Button("Try again") {
                Task { await load() }
            }
            .font(.system(size: 13, weight: .medium))
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
        failed = false
        Task {
            if let s = try? await APIClient.stats() {
                stats = s
                isLoaded = true
            } else if shelves.isEmpty {
                failed = true
                isLoaded = false
            }
        }
        let songs = await PlayerModel.ensureCatalog()
        buildShelves(songs)
        if stats != nil { isLoaded = true }
        Task { await radio.refresh() }
    }

    private func buildShelves(_ songs: [Song]) {
        let defs: [(String, String, String)] = [
            ("main", "Unreleased", "sparkles"),
            ("released", "Released", "checkmark.seal"),
            ("instrumental", "Instrumentals", "waveform"),
            ("stem", "Stems", "slider.horizontal.3"),
            ("cut", "Cuts", "scissors"),
            ("remaster", "Remasters", "star")
        ]
        shelves = defs.compactMap { def in
            let found = songs.filter { $0.category == def.0 }
            guard !found.isEmpty else { return nil }
            return Shelf(id: def.0, title: def.1, icon: def.2, songs: Array(found.prefix(12)))
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
                            .font(Theme.display(12, .bold))
                            .foregroundStyle(rank == 1 ? Color.black : Color.white)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(rank == 1 ? Theme.gold : Color.black.opacity(0.55)))
                            .padding(6)
                    }
                }
            Text(song.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.primaryText)
                .lineLimit(2)
                .frame(height: 36, alignment: .top)
            Text(song.artist)
                .font(.system(size: 11.5))
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
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(Theme.raised)
                .frame(width: 110, height: 14)
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
        .opacity(pulse ? 0.45 : 1)
        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)
        .onAppear { pulse = true }
    }
}