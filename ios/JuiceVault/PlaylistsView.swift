import SwiftUI

// MARK: - Profile

struct ProfileView: View {
    @ObservedObject private var player = PlayerModel.shared
    @State private var showNewPlaylist = false
    @State private var newName = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    header
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                Section {
                    HStack {
                        Text("Playlists")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Theme.primaryText)
                        Spacer()
                        Button {
                            showNewPlaylist = true
                            Vibe.tap()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 21))
                                .foregroundStyle(Theme.accent)
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                    ForEach(player.playlists) { playlist in
                        NavigationLink {
                            PlaylistDetailView(playlistID: playlist.id)
                        } label: {
                            playlistRow(playlist)
                        }
                        .listRowBackground(Theme.surface)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            if playlist.id != PlayerModel.songsPlaylistID {
                                Button(role: .destructive) {
                                    withAnimation {
                                        player.deletePlaylist(playlist.id)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle("Profile")
            .alert("New playlist", isPresented: $showNewPlaylist) {
                TextField("Name", text: $newName)
                Button("Create") {
                    player.createPlaylist(named: newName)
                    newName = ""
                    Vibe.success()
                }
                Button("Cancel", role: .cancel) {
                    newName = ""
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Text("JW")
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 62, height: 62)
                .background(Circle().fill(Theme.accent))
            VStack(alignment: .leading, spacing: 4) {
                Text("999 Vault")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(Theme.primaryText)
                Text("\(player.likedCount()) liked songs")
                    .font(.system(size: 12.5))
                    .foregroundStyle(Theme.secondaryText)
            }
            Spacer()
        }
        .padding(.vertical, 14)
    }

    private func playlistRow(_ playlist: Playlist) -> some View {
        HStack(spacing: 12) {
            Image(systemName: playlist.id == PlayerModel.songsPlaylistID ? "heart.fill" : "music.note")
                .font(.system(size: 17))
                .foregroundStyle(playlist.id == PlayerModel.songsPlaylistID ? Theme.gold : Theme.accent)
                .frame(width: 50, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Theme.deep)
                )
            VStack(alignment: .leading, spacing: 3) {
                Text(playlist.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.primaryText)
                Text("\(playlist.songIDs.count) \(playlist.songIDs.count == 1 ? "song" : "songs")")
                    .font(.system(size: 12.5))
                    .foregroundStyle(Theme.secondaryText)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.tertiaryText)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Playlist detail

struct PlaylistDetailView: View {
    let playlistID: String
    @ObservedObject private var player = PlayerModel.shared
    @State private var showPicker = false

    private var playlist: Playlist? {
        player.playlists.first { $0.id == playlistID }
    }

    private var songs: [Song] {
        guard let playlist else { return [] }
        return player.songs(in: playlist)
    }

    var body: some View {
        List {
            Section {
                header
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                HStack(spacing: 10) {
                    Button {
                        guard !songs.isEmpty else { return }
                        player.play(songs[0], in: songs)
                        Vibe.tap()
                    } label: {
                        Label("Play", systemImage: "play.fill")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 9)
                            .background(Capsule().fill(Theme.accent))
                    }
                    Button {
                        showPicker = true
                        Vibe.tap()
                    } label: {
                        Label("Add songs", systemImage: "plus")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.primaryText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background(Capsule().fill(Theme.raised))
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            Section {
                ForEach(songs) { song in
                    Button {
                        if player.currentSong?.id == song.id && player.isPlaying {
                            player.togglePlay()
                        } else {
                            player.play(song, in: songs)
                        }
                        Vibe.tap()
                    } label: {
                        SongRow(
                            song: song,
                            isFavorite: player.isFavorite(song),
                            isCurrent: player.currentSong?.id == song.id
                        )
                    }
                    .buttonStyle(RowPress())
                    .listRowBackground(Theme.bg)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            player.removeSong(song.id, from: playlistID)
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
                }
            } header: {
                if songs.isEmpty {
                    Text("No songs yet — hit Add songs to fill it up.")
                        .font(.system(size: 12.5))
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            .listRowSeparatorTint(Theme.hairline)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
        .navigationTitle(playlist?.name ?? "Playlist")
        .sheet(isPresented: $showPicker) {
            SongPickerSheet(playlistID: playlistID)
                .presentationDetents([.large])
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: playlist?.id == PlayerModel.songsPlaylistID ? "heart.fill" : "music.note")
                .font(.system(size: 22))
                .foregroundStyle(playlist?.id == PlayerModel.songsPlaylistID ? Theme.gold : Theme.accent)
                .frame(width: 64, height: 64)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Theme.deep)
                )
            VStack(alignment: .leading, spacing: 4) {
                Text(playlist?.name ?? "Playlist")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(Theme.primaryText)
                Text("\(songs.count) \(songs.count == 1 ? "song" : "songs")")
                    .font(.system(size: 12.5))
                    .foregroundStyle(Theme.secondaryText)
            }
            Spacer()
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Add current song to a playlist

struct AddToPlaylistSheet: View {
    let song: Song
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var player = PlayerModel.shared
    @State private var showNewField = false
    @State private var newName = ""

    var body: some View {
        NavigationStack {
            List {
                Button {
                    showNewField = true
                } label: {
                    Label("New Playlist", systemImage: "plus.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.accent)
                }
                .listRowBackground(Theme.surface)

                if showNewField {
                    HStack(spacing: 8) {
                        TextField("Playlist name", text: $newName)
                            .font(.system(size: 14))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Theme.raised)
                            )
                        Button("Create") {
                            player.createPlaylist(named: newName)
                            let created = player.playlists.last
                            if let created {
                                player.addSongs([song.id], to: created.id)
                            }
                            newName = ""
                            showNewField = false
                            Vibe.success()
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.accent)
                        .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .listRowBackground(Theme.surface)
                }

                ForEach(player.playlists) { playlist in
                    Button {
                        player.toggleSong(song, in: playlist.id)
                        Vibe.tap()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: playlist.id == PlayerModel.songsPlaylistID ? "heart.fill" : "music.note")
                                .font(.system(size: 15))
                                .foregroundStyle(playlist.id == PlayerModel.songsPlaylistID ? Theme.gold : Theme.accent)
                                .frame(width: 34, height: 34)
                                .background(
                                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                                        .fill(Theme.deep)
                                )
                            Text(playlist.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Theme.primaryText)
                            Spacer()
                            if player.isInPlaylist(song, playlistID: playlist.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 17))
                                    .foregroundStyle(Theme.accent)
                            }
                        }
                    }
                    .listRowBackground(Theme.surface)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle("Add to playlist")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.accent)
                }
            }
        }
    }
}

// MARK: - Pick songs to add into a playlist

struct SongPickerSheet: View {
    let playlistID: String
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var player = PlayerModel.shared
    @State private var songs: [Song] = []
    @State private var selected: Set<String> = []
    @State private var searchText = ""

    private var filtered: [Song] {
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return songs }
        return songs.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed) ||
            $0.artist.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered) { song in
                    Button {
                        if selected.contains(song.id) {
                            selected.remove(song.id)
                        } else {
                            selected.insert(song.id)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            ArtworkView(url: song.coverURL, size: 42, radius: 8)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(song.title)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Theme.primaryText)
                                    .lineLimit(1)
                                Text(song.artist)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.secondaryText)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Image(systemName: selected.contains(song.id) ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 19))
                                .foregroundStyle(selected.contains(song.id) ? Theme.accent : Theme.tertiaryText)
                        }
                    }
                    .buttonStyle(RowPress())
                    .listRowBackground(Theme.bg)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle("Add songs")
            .searchable(text: $searchText, prompt: "Search the vault")
            .safeAreaInset(edge: .bottom) {
                if !selected.isEmpty {
                    Button {
                        player.addSongs(Array(selected), to: playlistID)
                        selected = []
                        dismiss()
                        Vibe.success()
                    } label: {
                        Text("Add \(selected.count) \(selected.count == 1 ? "song" : "songs")")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Theme.accent)
                            )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    .background(Theme.bg)
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.accent)
                }
            }
            .task {
                songs = await PlayerModel.ensureCatalog()
            }
        }
    }
}