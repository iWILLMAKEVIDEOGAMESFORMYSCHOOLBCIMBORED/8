import SwiftUI

private struct VaultCategory: Identifiable {
    let id: String
    let label: String
}

struct LibraryView: View {
    @ObservedObject private var player = PlayerModel.shared
    @State private var allSongs: [Song] = []
    @State private var filtered: [Song] = []
    @State private var searchText = ""
    @State private var searchResults: [Song] = []
    @State private var isSearching = false
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedCategory = "main"

    private let categories: [VaultCategory] = [
        VaultCategory(id: "main", label: "Unreleased"),
        VaultCategory(id: "all", label: "All"),
        VaultCategory(id: "released", label: "Released"),
        VaultCategory(id: "instrumental", label: "Instrumentals"),
        VaultCategory(id: "remaster", label: "Remasters"),
        VaultCategory(id: "stem", label: "Stems"),
        VaultCategory(id: "cut", label: "Cuts")
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                categoryChips
                content
            }
            .background(Color(red: 0.06, green: 0.05, blue: 0.09))
            .navigationTitle("The Vault")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search \(allSongs.count) songs")
            .task {
                if allSongs.isEmpty { await loadAll() }
            }
            .refreshable { await loadAll() }
            .onChange(of: searchText) { newValue in
                Task { await runSearch(newValue) }
            }
            .onChange(of: selectedCategory) { _ in
                applyFilter()
            }
        }
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.id) { cat in
                    Button {
                        selectedCategory = cat.id
                    } label: {
                        Text(cat.label)
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(
                                selectedCategory == cat.id
                                    ? Color(red: 0.5, green: 0.85, blue: 0.45)
                                    : Color(red: 0.14, green: 0.12, blue: 0.22),
                                in: Capsule()
                            )
                            .foregroundStyle(selectedCategory == cat.id ? .black : .white)
                    }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private var content: some View {
        if isSearching {
            songList(searchResults)
        } else if isLoading {
            VStack(spacing: 10) {
                ProgressView()
                Text("Loading the vault…").font(.footnote).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage {
            VStack(spacing: 10) {
                Text("⚠️").font(.largeTitle)
                Text(errorMessage).font(.footnote).foregroundStyle(.red)
                Button("Retry") { Task { await loadAll() } }
                    .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if filtered.isEmpty {
            Text("Nothing here — try another category.")
                .font(.footnote).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            songList(filtered)
        }
    }

    private func songList(_ songs: [Song]) -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(songs) { song in
                    Button {
                        player.play(song, in: songs)
                    } label: {
                        SongRowView(song: song, isFavorite: player.isFavorite(song))
                    }
                    .buttonStyle(.plain)
                    Divider().background(Color.white.opacity(0.06))
                }
            }
            .padding(.bottom, 90)
        }
    }

    private func applyFilter() {
        if selectedCategory == "all" {
            filtered = allSongs
        } else if selectedCategory == "main" {
            filtered = allSongs.filter { $0.category == "main" }
        } else {
            filtered = allSongs.filter { $0.category == selectedCategory }
        }
    }

    private func loadAll() async {
        isLoading = true
        errorMessage = nil
        do {
            allSongs = try await APIClient.fetchSongs("/music/list")
            applyFilter()
        } catch {
            errorMessage = "Could not load the vault."
        }
        isLoading = false
    }

    private func runSearch(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            isSearching = false
            searchResults = []
            return
        }
        isSearching = true
        do {
            searchResults = try await APIClient.search(trimmed)
        } catch {
            searchResults = []
        }
    }
}

struct SongRowView: View {
    let song: Song
    let isFavorite: Bool

    var body: some View {
        HStack(spacing: 12) {
            cover
            VStack(alignment: .leading, spacing: 2) {
                Text(song.title).font(.system(size: 14, weight: .semibold))
                    .lineLimit(1).foregroundStyle(.white)
                HStack(spacing: 6) {
                    Text(song.artist).font(.system(size: 12)).foregroundStyle(.secondary)
                    if let length = song.length {
                        Text("•").foregroundStyle(.secondary.opacity(0.5))
                        Text(length).font(.system(size: 12)).foregroundStyle(.secondary)
                    }
                }
                .lineLimit(1)
            }
            Spacer()
            if isFavorite {
                Image(systemName: "heart.fill").font(.system(size: 11))
                    .foregroundStyle(Color(red: 0.5, green: 0.85, blue: 0.45))
            }
            Image(systemName: "play.fill").font(.system(size: 12))
                .foregroundStyle(Color(red: 0.5, green: 0.85, blue: 0.45))
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
    }

    private var cover: some View {
        AsyncImage(url: song.coverURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            case .failure:
                ZStack {
                    Color(red: 0.16, green: 0.13, blue: 0.26)
                    Text("999").font(.system(size: 12, weight: .black))
                        .foregroundStyle(Color(red: 0.5, green: 0.85, blue: 0.45))
                }
            default:
                Color(red: 0.16, green: 0.13, blue: 0.26)
            }
        }
        .frame(width: 46, height: 46)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
