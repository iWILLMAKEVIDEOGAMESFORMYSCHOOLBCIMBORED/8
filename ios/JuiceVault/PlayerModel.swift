import Foundation
import AVFoundation

@MainActor
final class PlayerModel: ObservableObject {
    static let shared = PlayerModel()

    @Published var queue: [Song] = []
    @Published var currentIndex: Int = 0
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0

    let player = AVPlayer()
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private let favoritesKey = "vault.favorites"

    @Published var favorites: [String: Song] = [:] {
        didSet { persistFavorites() }
    }

    private init() {
        setupTimeObserver()
        loadFavorites()
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

    func isFavorite(_ song: Song) -> Bool {
        favorites[song.id] != nil
    }

    func toggleFavorite(_ song: Song) {
        if favorites[song.id] != nil {
            favorites.removeValue(forKey: song.id)
        } else {
            favorites[song.id] = song
        }
    }

    private func loadFavorites() {
        guard let data = UserDefaults.standard.data(forKey: favoritesKey),
              let decoded = try? JSONDecoder().decode([String: Song].self, from: data) else { return }
        favorites = decoded
    }

    private func persistFavorites() {
        if let data = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(data, forKey: favoritesKey)
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

    let player = AVPlayer()

    private init() {}

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
        } else {
            PlayerModel.shared.stop()
            let url = URL(string: APIClient.baseURL + "/radio/stream")!
            player.replaceCurrentItem(with: AVPlayerItem(url: url))
            player.play()
            isPlaying = true
            Task { await refresh() }
        }
    }

    func stop() {
        player.pause()
        isPlaying = false
    }
}
