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
    @State private var searchTask: Task<Void, Never>?

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
            .background(Theme.bg)
            .navigationTitle("The Vault")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search \(allSongs.count) songs")
            .task {
                if allSongs.isEmpty { await loadAll() }
            }
            .refreshable { await loadAll() }
            .onChange(of: searchText) { _ in
                searchTask?.cancel()
                searchTask = Task {
                    try? await Task.sleep(nanoseconds: 350_000_000)
                    guard !Task.isCancelled else { return }
                    await runSearch(searchText)
                }
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
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                selectedCategory == cat.id
                                    ? AnyShapeStyle(Theme.accent)
                                    : AnyShapeStyle(Theme.raised),
                                in: Capsule()
                            )
                            .foregroundStyle(selectedCategory == cat.id ? .white : Theme.secondaryText)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    @ViewBuilder
    private var content: some View {
        if isSearching {
            songList(searchResults)
        } else if isLoading {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(0..<8, id: \.self) { _ in
                        SkeletonRow()
                    }
                }
            }
            .scrollDisabled(true)
        } else if let errorMessage {
            VStack(spacing: 10) {
                Image(systemName: "tray")
                    .font(.system(size: 26))
                    .foregroundStyle(Theme.tertiaryText)
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
                Button("Retry") {
                    Task { await loadAll() }
                }
                .font(.system(size: 13, weight: .semibold))
                .buttonStyle(.bordered)
                .tint(Theme.accent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if filtered.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "music.note")
                    .font(.system(size: 24))
                    .foregroundStyle(Theme.tertiaryText)
                Text("Nothing here — try another category.")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            songList(filtered)
        }
    }

    private func songList(_ songs: [Song]) -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                Text("\(songs.count) TRACKS")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(Theme.tertiaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 6)
                ForEach(songs) { song in
                    Button {
                        playOrToggle(song, in: songs)
                    } label: {
                        SongRow(
                            song: song,
                            isFavorite: player.isFavorite(song),
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

    private func playOrToggle(_ song: Song, in list: [Song]) {
        if player.currentSong?.id == song.id && player.isPlaying {
            player.togglePlay()
        } else {
            player.play(song, in: list)
        }
        Vibe.tap()
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