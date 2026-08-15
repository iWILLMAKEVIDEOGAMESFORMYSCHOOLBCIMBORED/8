import SwiftUI

struct HomeView: View {
    @ObservedObject private var radio = RadioModel.shared
    @State private var stats: StatsResponse?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    if let stats {
                        statsRow(stats)
                        topSongsSection(stats)
                    } else if let errorMessage {
                        Text(errorMessage).foregroundStyle(.red).font(.footnote)
                    } else {
                        ProgressView().frame(maxWidth: .infinity).padding(.top, 40)
                    }
                    radioCard
                }
                .padding(16)
            }
            .background(Color(red: 0.06, green: 0.05, blue: 0.09))
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("JUICE WRLD").font(.title.bold())
                    .foregroundStyle(.white)
                Text("THE VAULT 999").font(.caption).tracking(4)
                    .foregroundStyle(Color(red: 0.5, green: 0.85, blue: 0.45))
            }
            Spacer()
            Image(systemName: "bolt.fill").font(.title2)
                .foregroundStyle(.yellow)
                .padding(10)
                .background(Color(red: 0.14, green: 0.12, blue: 0.22), in: Circle())
        }
    }

    private func statsRow(_ stats: StatsResponse) -> some View {
        HStack(spacing: 10) {
            statCard("SONGS", "\(stats.total_songs)")
            statCard("PLAYTIME", stats.total_duration)
            statCard("ARCHIVE", stats.total_size)
        }
    }

    private func statCard(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(.system(size: 15, weight: .bold))
                .lineLimit(2).minimumScaleFactor(0.6)
                .foregroundStyle(.white)
            Text(label).font(.system(size: 9, weight: .semibold)).tracking(1)
                .foregroundStyle(Color(red: 0.5, green: 0.85, blue: 0.45))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(red: 0.11, green: 0.09, blue: 0.17), in: RoundedRectangle(cornerRadius: 14))
    }

    private func topSongsSection(_ stats: StatsResponse) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("MOST PLAYED")
            ForEach(Array(stats.top_songs.prefix(10).enumerated()), id: \.element.id) { index, top in
                Button {
                    PlayerModel.shared.play(top.song, in: stats.top_songs.map(\.song))
                } label: {
                    songRow(rank: index + 1, song: top.song)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func songRow(rank: Int, song: Song) -> some View {
        HStack(spacing: 12) {
            Text("\(rank)").font(.system(size: 13, weight: .bold)).foregroundStyle(.secondary).frame(width: 22)
            coverArt(song)
            VStack(alignment: .leading, spacing: 2) {
                Text(song.title).font(.system(size: 14, weight: .semibold)).lineLimit(1).foregroundStyle(.white)
                Text("\(song.artist) • \(song.play_count ?? 0) plays").font(.system(size: 12)).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "play.fill").font(.system(size: 13)).foregroundStyle(Color(red: 0.5, green: 0.85, blue: 0.45))
        }
        .padding(.vertical, 6)
    }

    private func coverArt(_ song: Song) -> some View {
        AsyncImage(url: song.coverURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            default:
                ZStack {
                    Color(red: 0.16, green: 0.13, blue: 0.26)
                    Text("999").font(.system(size: 14, weight: .black))
                        .foregroundStyle(Color(red: 0.5, green: 0.85, blue: 0.45))
                }
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var radioCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .foregroundStyle(radio.isPlaying ? .red : Color(red: 0.5, green: 0.85, blue: 0.45))
                sectionTitle("999 RADIO — LIVE")
                Spacer()
                if radio.isLoading {
                    ProgressView().scaleEffect(0.7)
                }
            }
            if let now = radio.nowPlaying {
                HStack(spacing: 12) {
                    AsyncImage(url: now.song.coverURL) { phase in
                        if case .success(let image) = phase {
                            image.resizable().scaledToFill()
                        } else {
                            Color(red: 0.16, green: 0.13, blue: 0.26)
                        }
                    }
                    .frame(width: 52, height: 52).clipShape(RoundedRectangle(cornerRadius: 10))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(now.title).font(.system(size: 15, weight: .semibold)).foregroundStyle(.white).lineLimit(1)
                        Text(now.artist).font(.system(size: 12)).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            } else {
                Text("Streaming the vault 24/7").font(.system(size: 13)).foregroundStyle(.secondary)
            }
            Button {
                radio.toggle()
            } label: {
                HStack {
                    Image(systemName: radio.isPlaying ? "stop.fill" : "play.fill")
                    Text(radio.isPlaying ? "STOP RADIO" : "LISTEN LIVE")
                        .font(.system(size: 12, weight: .bold)).tracking(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    radio.isPlaying ? Color.red.opacity(0.85) : Color(red: 0.16, green: 0.4, blue: 0.2),
                    in: RoundedRectangle(cornerRadius: 12)
                )
                .foregroundStyle(.white)
            }
        }
        .padding(14)
        .background(Color(red: 0.11, green: 0.09, blue: 0.17), in: RoundedRectangle(cornerRadius: 14))
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text).font(.system(size: 11, weight: .bold)).tracking(2)
            .foregroundStyle(Color(red: 0.5, green: 0.85, blue: 0.45))
    }

    private func load() async {
        do {
            stats = try await APIClient.stats()
            errorMessage = nil
        } catch {
            errorMessage = "Could not reach the vault. Check your connection."
        }
    }
}
