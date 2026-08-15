import SwiftUI

struct HomeView: View {
    @ObservedObject private var radio = RadioModel.shared
    @ObservedObject private var player = PlayerModel.shared
    @State private var stats: StatsResponse?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    hero
                    if let stats {
                        statsRow(stats)
                        topSongs(stats)
                    } else if let errorMessage {
                        errorState
                    } else {
                        ProgressView()
                            .tint(Color.vaultAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    }
                    radioCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background(Color.vaultBg)
            .refreshable { await load() }
            .task { await load() }
        }
    }

    private var hero: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("999 VAULT")
                    .font(.system(size: 15, weight: .heavy))
                    .tracking(4)
                    .foregroundStyle(LinearGradient.vaultGradient)
                Text("JUICE WRLD")
                    .font(.system(size: 30, weight: .black))
                    .foregroundStyle(.white)
                Text("Every era. Every leak. All 999s.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "bolt.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.vaultGold)
                .frame(width: 46, height: 46)
                .background(
                    Circle()
                        .fill(Color.vaultCard)
                        .overlay(Circle().strokeBorder(Color.vaultStroke))
                )
        }
        .padding(.top, 6)
    }

    private var errorState: some View {
        VStack(spacing: 10) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 32))
                .foregroundStyle(Color.vaultGold)
            Text(errorMessage ?? "")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Try again") {
                Task { await load() }
            }
            .font(.system(size: 13, weight: .semibold))
            .buttonStyle(.bordered)
            .tint(Color.vaultAccent)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 30)
    }

    private func statsRow(_ stats: StatsResponse) -> some View {
        HStack(spacing: 10) {
            statCard("SONGS", "\(stats.total_songs)")
            statCard("PLAYTIME", stats.total_duration)
            statCard("ARCHIVE", stats.total_size)
        }
    }

    private func statCard(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(LinearGradient.vaultGlow)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.vaultCard)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.vaultStroke))
        )
    }

    private func topSongs(_ stats: StatsResponse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(LinearGradient.vaultGlow)
                sectionTitle("MOST PLAYED")
            }
            ForEach(Array(stats.top_songs.prefix(10).enumerated()), id: \.element.id) { index, top in
                Button {
                    if player.currentSong?.id == top.song.id && player.isPlaying {
                        player.togglePlay()
                    } else {
                        player.play(top.song, in: stats.top_songs.map(\.song))
                    }
                    Vibe.tap()
                } label: {
                    rankRow(rank: index + 1, song: top.song)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func rankRow(rank: Int, song: Song) -> some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(rank == 1 ? Color.vaultGold : Color.white.opacity(0.45))
                .frame(width: 24)
            ArtworkView(url: song.coverURL, size: 44, corner: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(player.currentSong?.id == song.id ? Color.vaultAccent : .white)
                    .lineLimit(1)
                Text("\(song.artist) • \(song.play_count ?? 0) plays")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            if player.currentSong?.id == song.id {
                EqualizerBars(playing: player.isPlaying)
            } else {
                Image(systemName: "play.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.7))
            }
        }
        .padding(.vertical, 5)
    }

    private var radioCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                liveDot
                sectionTitle("999 RADIO — LIVE")
                Spacer()
                if radio.isLoading {
                    ProgressView().tint(Color.vaultAccent).scaleEffect(0.8)
                }
            }
            if let now = radio.nowPlaying {
                HStack(spacing: 12) {
                    ArtworkView(url: now.song.coverURL, size: 52, corner: 12)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(now.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Text(now.artist)
                            .font(.system(size: 12.5))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    EqualizerBars(playing: radio.isPlaying)
                }
            } else {
                Text("Streaming the vault, nonstop.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            Button {
                radio.toggle()
                Vibe.tap()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: radio.isPlaying ? "stop.fill" : "play.fill")
                        .font(.system(size: 12, weight: .bold))
                    Text(radio.isPlaying ? "STOP RADIO" : "LISTEN LIVE")
                        .font(.system(size: 12, weight: .heavy))
                        .tracking(1.5)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    radio.isPlaying
                        ? AnyShapeStyle(Color.red.opacity(0.85))
                        : AnyShapeStyle(LinearGradient.vaultGradient),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .foregroundStyle(.white)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.vaultCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(radio.isPlaying ? Color.red.opacity(0.6) : Color.vaultStroke)
                )
        )
    }

    @State private var livePulse = false

    private var liveDot: some View {
        Circle()
            .fill(radio.isPlaying ? Color.red : Color.vaultGold)
            .frame(width: 8, height: 8)
            .scaleEffect(livePulse ? 1.4 : 0.8)
            .opacity(livePulse ? 0.4 : 1)
            .animation(
                radio.isPlaying
                    ? .easeInOut(duration: 0.9).repeatForever(autoreverses: true)
                    : .default,
                value: livePulse
            )
            .onAppear { livePulse = true }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .heavy))
            .tracking(2)
            .foregroundStyle(Color.vaultAccent)
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