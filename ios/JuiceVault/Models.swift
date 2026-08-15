import Foundation

struct Song: Identifiable, Codable, Hashable {
    let id: String
    let file_name: String
    let title: String
    let artist: String
    let album: String?
    let year: Int?
    let duration: Int?
    let length: String?
    let bitrate: Int?
    let cover: String?
    let play_count: Int?
    let category: String?
    let relevance: Int?
    let file_size: String?
    let file_size_bytes: Int64?
    let archive_added_at: String?
    let is_session_edit: Bool?
    let alt_names: [String]?

    enum CodingKeys: String, CodingKey {
        case id, file_name, title, artist, album, year, duration, length, bitrate
        case cover, play_count, category, relevance, file_size, file_size_bytes
        case archive_added_at, is_session_edit, alt_names
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(String.self, forKey: .id)) ?? ""
        file_name = (try? c.decode(String.self, forKey: .file_name)) ?? ""
        title = (try? c.decode(String.self, forKey: .title)) ?? ""
        artist = (try? c.decode(String.self, forKey: .artist)) ?? ""
        album = try? c.decode(String.self, forKey: .album)
        year = try? c.decode(Int.self, forKey: .year)
        duration = try? c.decode(Int.self, forKey: .duration)
        length = try? c.decode(String.self, forKey: .length)
        bitrate = try? c.decode(Int.self, forKey: .bitrate)
        cover = try? c.decode(String.self, forKey: .cover)
        play_count = try? c.decode(Int.self, forKey: .play_count)
        category = try? c.decode(String.self, forKey: .category)
        relevance = try? c.decode(Int.self, forKey: .relevance)
        file_size = try? c.decode(String.self, forKey: .file_size)
        file_size_bytes = try? c.decode(Int64.self, forKey: .file_size_bytes)
        archive_added_at = try? c.decode(String.self, forKey: .archive_added_at)
        is_session_edit = try? c.decode(Bool.self, forKey: .is_session_edit)
        alt_names = try? c.decode([String].self, forKey: .alt_names)
    }

    init(id: String, file_name: String, title: String, artist: String, album: String? = nil,
         year: Int? = nil, duration: Int? = nil, length: String? = nil, bitrate: Int? = nil,
         cover: String? = nil, play_count: Int? = nil, category: String? = nil, relevance: Int? = nil,
         file_size: String? = nil, file_size_bytes: Int64? = nil, archive_added_at: String? = nil,
         is_session_edit: Bool? = nil, alt_names: [String]? = nil) {
        self.id = id
        self.file_name = file_name
        self.title = title
        self.artist = artist
        self.album = album
        self.year = year
        self.duration = duration
        self.length = length
        self.bitrate = bitrate
        self.cover = cover
        self.play_count = play_count
        self.category = category
        self.relevance = relevance
        self.file_size = file_size
        self.file_size_bytes = file_size_bytes
        self.archive_added_at = archive_added_at
        self.is_session_edit = is_session_edit
        self.alt_names = alt_names
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(file_name, forKey: .file_name)
        try c.encode(title, forKey: .title)
        try c.encode(artist, forKey: .artist)
        try c.encodeIfPresent(album, forKey: .album)
        try c.encodeIfPresent(year, forKey: .year)
        try c.encodeIfPresent(duration, forKey: .duration)
        try c.encodeIfPresent(length, forKey: .length)
        try c.encodeIfPresent(bitrate, forKey: .bitrate)
        try c.encodeIfPresent(cover, forKey: .cover)
        try c.encodeIfPresent(play_count, forKey: .play_count)
        try c.encodeIfPresent(category, forKey: .category)
        try c.encodeIfPresent(relevance, forKey: .relevance)
        try c.encodeIfPresent(file_size, forKey: .file_size)
        try c.encodeIfPresent(file_size_bytes, forKey: .file_size_bytes)
        try c.encodeIfPresent(archive_added_at, forKey: .archive_added_at)
        try c.encodeIfPresent(is_session_edit, forKey: .is_session_edit)
        try c.encodeIfPresent(alt_names, forKey: .alt_names)
    }

    var coverURL: URL? {
        guard let cover else { return nil }
        return URL(string: APIClient.baseURL + cover)
    }

    var streamURL: URL {
        URL(string: APIClient.baseURL + "/music/stream/\(id)")!
    }

    var downloadURL: URL {
        URL(string: APIClient.baseURL + "/music/download/\(id)")!
    }
}

struct SongListResponse: Decodable {
    let total: Int?
    let songs: [Song]
}

struct SearchResponse: Decodable {
    let query: String?
    let count: Int?
    let results: [Song]
}

struct TopSong: Decodable, Identifiable, Hashable {
    let rank: Int
    let id: String
    let title: String
    let artist: String
    let length: String?
    let cover: String?
    let play_count: Int

    var song: Song {
        Song(id: id, file_name: title + ".mp3", title: title, artist: artist,
             length: length, cover: cover, play_count: play_count)
    }
}

struct StatsResponse: Decodable {
    let total_songs: Int
    let total_duration: String
    let total_size: String
    let top_songs: [TopSong]
}

struct RadioCurrent: Decodable, Identifiable {
    let id: String
    let title: String
    let artist: String
    let duration: Int?
    let length: String?
    let cover: String?
    let play_count: Int?
    let elapsed: Double?
    let remaining: Double?

    var song: Song {
        Song(id: id, file_name: title + ".mp3", title: title, artist: artist,
             length: length, cover: cover, play_count: play_count)
    }
}

struct RadioNowPlaying: Decodable {
    let success: Bool
    let data: RadioData?
}

struct RadioData: Decodable {
    let current: RadioCurrent?
    let next: RadioCurrent?
}
