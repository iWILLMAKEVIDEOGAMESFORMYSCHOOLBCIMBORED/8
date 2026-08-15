import SwiftUI

struct HomeView: View {
    @ObservedObject private var radio = RadioModel.shared
    @ObservedObject private var player = PlayerModel.shared
    @State private var stats: StatsResponse?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    hero
                    if let stats {
                        statsBlock(stats)
                        topSection(stats)
                    } else if let errorMessage {
                        errorBlock
                    } else {
                        SkeletonRow(titleWidth: 180)
                        SkeletonRow(titleWidth: 140)
                        SkeletonRow(titleWidth: 160)
                        SkeletonRow(titleWidth: 120)
                    }
                    radioCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 28)
            }
            .background(Theme.bg)
            .refreshable { await load() }
            .task { await load() }
        }
    }

    // MARK: Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("999")
                .font(Theme.display(46, .black))
                .foregroundStyle(Theme.primaryText)
            Text("V A U L T")
                .font(.system(size: 13, weight: .bold))
                .tracking(6)
                .foregroundStyle(Theme.violet)
            Text("Every era. Every leak. All 999s.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.secondaryText)
        }
    }

    // MARK: Overview

    private func statsBlock(_ stats: StatsResponse) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            stat("\(stats.total_songs)", "UNRELEASED")
            stat(compactDuration(stats.total_duration), "PLAYTIME")
            stat(stats.total_size, "ARCHIVE")
        }
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(Theme.display(19, .black))
                .foregroundStyle(Theme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(Theme.tertiaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func compactDuration(_ raw: String) -> String {
        let words = raw.split(separator: " ").map { String($0).replacingOccurrences(of: ",", with: "") }
        var parts: [String] = []
        var i = 0
        while i + 1 < words.count {
            let unit = words[i + 1].lowercased()
            let suffix: String
            if unit.hasPrefix("day") { suffix = "D" }
            else if unit.hasPrefix("hour") { suffix = "H" }
            else if unit.hasPrefix("minute") { suffix = "M" }
            else if unit.hasPrefix("second") { suffix = "S" }
            else { suffix = "" }
            if !suffix.isEmpty {
                parts.append("\(words[i])\(suffix)")
            }
            i += 2
        }
        return parts.isEmpty ? raw : parts.joined(separator: " · ")
    }

    // MARK: Most played

    private func topSection(_ stats: StatsResponse) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: "Most Played")
            ForEach(Array(stats.top_songs.prefix(10).enumerated()), id: \.element.id) { index, top in
                Button {
                    playOrToggle(top.song, in: stats.top_songs.map(\.song))
                } label: {
                    rankRow(rank: index + 1, song: top.song)
                }
                .buttonStyle(RowPress())
            }
        }
    }

    private func rankRow(rank: Int, song: Song) -> some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(Theme.display(15, .black))
                .foregroundStyle(rank == 1 ? Theme.gold : Theme.tertiaryText)
                .frame(width: 26, alignment: .leading)
            ArtworkView(url: song.coverURL, size: 44, radius: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(player.currentSong?.id == song.id ? Theme.accent : Theme.primaryText)
                    .lineLimit(1)
                Text("\(song.artist)  ·  \(song.play_count ?? 0) plays")
                    .font(.system(size: 12.5))
                    .foregroundStyle(Theme.secondaryText)
                    .lineLimit(1)
            }
            Spacer()
            if player.currentSong?.id == song.id {
                EqualizerBars(playing: player.isPlaying)
            }
        }
        .padding(.vertical, 5)
    }

    // MARK: Radio

    private var radioCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 7) {
                Circle()
                    .fill(radio.isPlaying ? Theme.danger : Theme.accent)
                    .frame(width: 8, height: 8)
                Text("LIVE")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(2)
                    .foregroundStyle(radio.isPlaying ? Theme.danger : Theme.primaryText)
                Spacer()
                if radio.isLoading {
                    ProgressView().tint(Theme.accent).scaleEffect(0.75)
                }
            }
            if let now = radio.nowPlaying {
                HStack(spacing: 14) {
                    ArtworkView(url: now.song.coverURL, size: 96, radius: 14)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(now.title)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Theme.primaryText)
                            .lineLimit(2)
                        Text(now.artist)
                            .font(.system(size: 13.5))
                            .foregroundStyle(Theme.secondaryText)
                            .lineLimit(1)
                    }
                    Spacer()
                    EqualizerBars(playing: radio.isPlaying)
                }
            } else {
                Text("Tune in to the vault, 24/7.")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.secondaryText)
            }
            Button {
                radio.toggle()
                Vibe.tap()
            } label: {
                Text(radio.isPlaying ? "STOP" : "LISTEN LIVE")
                    .font(.system(size: 12.5, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(radio.isPlaying ? Color.white : Theme.bg)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        radio.isPlaying ? AnyShapeStyle(Theme.danger) : AnyShapeStyle(Color.white),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.surface)
        )
    }

    // MARK: States

    private var errorBlock: some View {
        VStack(spacing: 10) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 26))
                .foregroundStyle(Theme.tertiaryText)
            Text(errorMessage ?? "")
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
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    // MARK: Helpers

    private func playOrToggle(_ song: Song, in list: [Song]) {
        if player.currentSong?.id == song.id && player.isPlaying {
            player.togglePlay()
        } else {
            player.play(song, in: list)
        }
        Vibe.tap()
    }

    private func load() async {
        do {
            stats = try await APIClient.stats()
            errorMessage = nil
        } catch {
            errorMessage = "Could not reach the vault. Check your connection and pull to retry."
        }
    }
}