import Foundation
import AVFoundation

struct Playlist: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var songIDs: [String]
}

@MainActor
final class PlayerModel: ObservableObject {
    static let shared = PlayerModel()
    static let songsPlaylistID = "songs"

    static var catalog: [Song]?
    private static let catalogURL = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("vault_catalog.json")

    static func ensureCatalog() async -> [Song] {
        if let catalog { return catalog }
        if let data = try? Data(contentsOf: catalogURL),
           let songs = try? JSONDecoder().decode([Song].self, from: data),
           !songs.isEmpty {
            catalog = songs
            Task { await refreshCatalog() }
            return songs
        }
        return await fetchAndCacheCatalog()
    }

    private static func fetchAndCacheCatalog() async -> [Song] {
        guard let songs = try? await APIClient.fetchSongs("/music/list") else {
            return catalog ?? []
        }
        catalog = songs
        saveCatalog(songs)
        return songs
    }

    private static func refreshCatalog() async {
        guard let songs = try? await APIClient.fetchSongs("/music/list") else { return }
        catalog = songs
        saveCatalog(songs)
    }

    private static func saveCatalog(_ songs: [Song]) {
        do {
            try FileManager.default.createDirectory(
                at: catalogURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try JSONEncoder().encode(songs).write(to: catalogURL, options: .atomic)
        } catch {}
    }

    @Published var queue: [Song] = []
    @Published var currentIndex: Int = 0
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0

    let player = AVPlayer()
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private let playlistsKey = "vault.playlists"
    private let legacyFavoritesKey = "vault.favorites"

    @Published var playlists: [Playlist] = [] {
        didSet { persistPlaylists() }
    }

    private init() {
        setupTimeObserver()
        loadPlaylists()
    }

    var currentSong: Song? {
        guard !queue.isEmpty, queue.indices.contains(currentIndex) else { return nil }
        return queue[currentIndex]
    }

    func play(_ song: Song, in list: [Song]) {
        RadioModel.shared.stop()
        queue = list
        currentIndex = list.firstIndex(of: song) ?? 0
        loadCurrent()
    }

    func loadCurrent() {
        guard let song = currentSong else { return }
        let item = AVPlayerItem(url: song.streamURL)
        player.replaceCurrentItem(with: item)
        player.play()
        isPlaying = true
        currentTime = 0
        duration = Double(song.duration ?? 0)
        setupEndObserver()
    }

    func togglePlay() {
        guard currentSong != nil else { return }
        if player.rate > 0 {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }

    func next() {
        guard !queue.isEmpty else { return }
        currentIndex = (currentIndex + 1) % queue.count
        loadCurrent()
    }

    func previous() {
        guard !queue.isEmpty else { return }
        if currentTime > 4 {
            seek(to: 0)
        } else {
            currentIndex = (currentIndex - 1 + queue.count) % queue.count
            loadCurrent()
        }
    }

    func seek(to seconds: Double) {
        let target = max(0, min(seconds, max(duration, 1)))
        let time = CMTime(seconds: target, preferredTimescale: 600)
        player.seek(to: time)
        currentTime = target
    }

    func stop() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        isPlaying = false
        queue = []
        currentIndex = 0
        currentTime = 0
        duration = 0
    }

    private func setupTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor in
                guard let self else { return }
                self.currentTime = time.seconds
                let d = self.player.currentItem?.duration.seconds ?? 0
                if d.isFinite, d > 0 {
                    self.duration = d
                } else if let song = self.currentSong, let secs = song.duration, secs > 0 {
                    self.duration = Double(secs)
                }
            }
        }
    }

    private func setupEndObserver() {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.next()
            }
        }
    }

    // MARK: Favorites (backed by the "Songs" playlist)

    func isFavorite(_ song: Song) -> Bool {
        isInPlaylist(song, playlistID: Self.songsPlaylistID)
    }

    func toggleFavorite(_ song: Song) {
        toggleSong(song, in: Self.songsPlaylistID)
        if isFavorite(song) { Vibe.success() }
    }

    func likedCount() -> Int {
        guard let p = playlists.first(where: { $0.id == Self.songsPlaylistID }) else { return 0 }
        return p.songIDs.count
    }

    // MARK: Playlists

    func isInPlaylist(_ song: Song, playlistID: String) -> Bool {
        playlists.first(where: { $0.id == playlistID })?.songIDs.contains(song.id) == true
    }

    func toggleSong(_ song: Song, in playlistID: String) {
        guard let index = playlists.firstIndex(where: { $0.id == playlistID }) else { return }
        if playlists[index].songIDs.contains(song.id) {
            playlists[index].songIDs.removeAll { $0 == song.id }
        } else {
            playlists[index].songIDs.append(song.id)
        }
    }

    func addSongs(_ ids: [String], to playlistID: String) {
        guard let index = playlists.firstIndex(where: { $0.id == playlistID }) else { return }
        for id in ids where !playlists[index].songIDs.contains(id) {
            playlists[index].songIDs.append(id)
        }
    }

    func removeSong(_ id: String, from playlistID: String) {
        guard let index = playlists.firstIndex(where: { $0.id == playlistID }) else { return }
        playlists[index].songIDs.removeAll { $0 == id }
    }

    func createPlaylist(named name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        playlists.append(Playlist(id: UUID().uuidString, name: trimmed, songIDs: []))
    }

    func deletePlaylist(_ id: String) {
        guard id != Self.songsPlaylistID else { return }
        playlists.removeAll { $0.id == id }
    }

    func songs(in playlist: Playlist) -> [Song] {
        let catalog = Self.catalog ?? []
        let byID = Dictionary(uniqueKeysWithValues: catalog.map { ($0.id, $0) })
        return playlist.songIDs.compactMap { byID[$0] }
    }

    private func loadPlaylists() {
        if let data = UserDefaults.standard.data(forKey: playlistsKey),
           let decoded = try? JSONDecoder().decode([Playlist].self, from: data) {
            playlists = decoded
        } else {
            playlists = []
        }
        if !playlists.contains(where: { $0.id == Self.songsPlaylistID }) {
            var seeded: [String] = []
            if let data = UserDefaults.standard.data(forKey: legacyFavoritesKey),
               let legacy = try? JSONDecoder().decode([String: Song].self, from: data) {
                seeded = Array(legacy.keys)
                UserDefaults.standard.removeObject(forKey: legacyFavoritesKey)
            }
            playlists.insert(Playlist(id: Self.songsPlaylistID, name: "Songs", songIDs: seeded), at: 0)
        }
        persistPlaylists()
    }

    private func persistPlaylists() {
        if let data = try? JSONEncoder().encode(playlists) {
            UserDefaults.standard.set(data, forKey: playlistsKey)
        }
    }

    func formattedTime(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds > 0 else { return "0:00" }
        let total = Int(seconds)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

@MainActor
final class RadioModel: ObservableObject {
    static let shared = RadioModel()

    @Published var isPlaying = false
    @Published var nowPlaying: RadioCurrent?
    @Published var isLoading = false
    /// Flips on every beat so views can sync thump animations.
    @Published var beatPhase = false

    let player = AVPlayer()
    private var beatTimer: Timer?
    private var beatCount = 0
    private let bpm: Double = 92
    private let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private let soft = UIImpactFeedbackGenerator(style: .light)

    private init() {}

    func attachBeat() {
        detachBeat()
        beatCount = 0
        beatPhase = false
        heavy.prepare()
        soft.prepare()
        beatTimer = Timer.scheduledTimer(withTimeInterval: 60.0 / bpm, repeats: true) { [weak self] _ in
            self?.fireBeat()
        }
    }

    private func fireBeat() {
        beatCount += 1
        let beat = ((beatCount - 1) % 4) + 1
        if beat == 1 {
            heavy.impactOccurred(intensity: 1.0)
        } else {
            soft.impactOccurred(intensity: beat == 3 ? 0.7 : 0.45)
        }
        beatPhase.toggle()
    }

    func detachBeat() {
        beatTimer?.invalidate()
        beatTimer = nil
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            nowPlaying = try await APIClient.radioNowPlaying()
        } catch {
            nowPlaying = nil
        }
    }

    func toggle() {
        if isPlaying {
            player.pause()
            isPlaying = false
            detachBeat()
        } else {
            PlayerModel.shared.stop()
            let url = URL(string: APIClient.baseURL + "/radio/stream")!
            player.replaceCurrentItem(with: AVPlayerItem(url: url))
            player.play()
            isPlaying = true
            attachBeat()
            Task { await refresh() }
        }
    }

    func stop() {
        player.pause()
        isPlaying = false
        detachBeat()
    }
}
