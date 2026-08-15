import SwiftUI
import UIKit

// MARK: - Design system (calm)

enum Theme {
    static let bg = Color(red: 0.050, green: 0.047, blue: 0.075)
    static let surface = Color(red: 0.085, green: 0.078, blue: 0.120)
    static let raised = Color(red: 0.120, green: 0.110, blue: 0.160)
    static let deep = Color(red: 0.150, green: 0.130, blue: 0.225)
    static let accent = Color(red: 0.70, green: 0.63, blue: 0.95)
    static let gold = Color(red: 0.93, green: 0.80, blue: 0.55)
    static let danger = Color(red: 0.85, green: 0.48, blue: 0.50)
    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.58)
    static let tertiaryText = Color.white.opacity(0.34)
    static let hairline = Color.white.opacity(0.06)

    static func display(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

// MARK: - Artwork

enum ArtworkCache {
    static let memory = NSCache<NSURL, UIImage>()
}

actor ArtworkLoader {
    static let shared = ArtworkLoader()
    private var running = 0
    private var waiters: [CheckedContinuation<Void, Never>] = []
    private let maxConcurrent = 6

    func acquire() async {
        if running < maxConcurrent {
            running += 1
            return
        }
        await withCheckedContinuation { waiters.append($0) }
        running += 1
    }

    func release() {
        running -= 1
        if !waiters.isEmpty {
            let next = waiters.removeFirst()
            next.resume()
        }
    }
}

struct ArtworkView: View {
    let url: URL?
    var size: CGFloat = 48
    var radius: CGFloat = 12
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            placeholder
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .task(id: url) {
            await load()
        }
    }

    private func load() async {
        guard let url else {
            image = nil
            return
        }
        if let hit = ArtworkCache.memory.object(forKey: url as NSURL) {
            image = hit
            return
        }
        await ArtworkLoader.shared.acquire()
        defer { Task { await ArtworkLoader.shared.release() } }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard !Task.isCancelled, let img = UIImage(data: data) else { return }
            ArtworkCache.memory.setObject(img, forKey: url as NSURL)
            image = img
        } catch {}
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.16, green: 0.14, blue: 0.24), Color(red: 0.08, green: 0.07, blue: 0.13)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            if size >= 120 {
                Text("999")
                    .font(Theme.display(size * 0.24, .bold))
                    .foregroundStyle(Color.white.opacity(0.70))
            }
        }
    }
}

// MARK: - Now-playing indicator

struct EqualizerBars: View {
    let playing: Bool
    @State private var phase = false

    private let heights: [CGFloat] = [12, 6, 9]

    var body: some View {
        HStack(alignment: .center, spacing: 2.5) {
            ForEach(0..<3, id: \.self) { i in
                Capsule()
                    .fill(playing ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(Color.white.opacity(0.35)))
                    .frame(width: 3.5, height: barHeight(i))
                    .animation(
                        playing
                            ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(Double(i) * 0.13)
                            : .linear(duration: 0.15),
                        value: phase
                    )
            }
        }
        .frame(height: 16)
        .onAppear { if playing { phase = true } }
        .onChange(of: playing) { newValue in
            if newValue {
                phase = false
                Task {
                    try? await Task.sleep(nanoseconds: 60_000_000)
                    phase = true
                }
            }
        }
    }

    private func barHeight(_ i: Int) -> CGFloat {
        playing ? (phase ? heights[i] : heights[i] * 0.35) : 4
    }
}

// MARK: - List row

struct SongRow: View {
    let song: Song
    let isFavorite: Bool
    let isCurrent: Bool
    @ObservedObject private var player = PlayerModel.shared

    var body: some View {
        HStack(spacing: 12) {
            ArtworkView(url: song.coverURL, size: 46, radius: 10)
            VStack(alignment: .leading, spacing: 3) {
                Text(song.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(isCurrent ? Theme.accent : Theme.primaryText)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 12.5))
                    .foregroundStyle(Theme.secondaryText)
                    .lineLimit(1)
            }
            Spacer()
            if isCurrent {
                EqualizerBars(playing: player.isPlaying)
            } else if isFavorite {
                Image(systemName: "heart.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.gold)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }

    private var subtitle: String {
        if let length = song.length {
            return "\(song.artist)  ·  \(length)"
        }
        return song.artist
    }
}

// MARK: - Loading placeholders

struct SkeletonRow: View {
    var titleWidth: CGFloat = 150
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Theme.raised)
                .frame(width: 46, height: 46)
            VStack(alignment: .leading, spacing: 7) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Theme.raised)
                    .frame(width: titleWidth, height: 12)
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Theme.raised)
                    .frame(width: 86, height: 10)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .opacity(pulse ? 0.45 : 1)
        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)
        .onAppear { pulse = true }
    }
}

// MARK: - Press feedback

struct RowPress: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.5 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Haptics

enum Vibe {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func pulse() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}