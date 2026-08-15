import SwiftUI
import UIKit

extension Color {
    static let vaultBg = Color(red: 0.035, green: 0.025, blue: 0.075)
    static let vaultAccent = Color(red: 0.72, green: 0.52, blue: 1.0)
    static let vaultGold = Color(red: 0.99, green: 0.82, blue: 0.45)
    static let vaultSub = Color.white.opacity(0.55)
    static let vaultCard = Color.white.opacity(0.07)
    static let vaultStroke = Color.white.opacity(0.10)
}

extension LinearGradient {
    static let vaultGradient = LinearGradient(
        colors: [Color(red: 0.66, green: 0.45, blue: 1.0), Color(red: 0.42, green: 0.22, blue: 0.85)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let vaultGlow = LinearGradient(
        colors: [Color.vaultGold, Color(red: 0.86, green: 0.55, blue: 1.0)],
        startPoint: .leading, endPoint: .trailing
    )
}

struct ArtworkView: View {
    let url: URL?
    var size: CGFloat = 44
    var corner: CGFloat = 10

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            default:
                ZStack {
                    LinearGradient(
                        colors: [Color(red: 0.40, green: 0.26, blue: 0.72), Color(red: 0.13, green: 0.09, blue: 0.30)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    Text("999")
                        .font(.system(size: size * 0.30, weight: .black))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
    }
}

struct EqualizerBars: View {
    let playing: Bool
    @State private var phase = false

    private let heights: [CGFloat] = [13, 6.5, 10, 7.5]

    var body: some View {
        HStack(alignment: .center, spacing: 2.5) {
            ForEach(0..<4, id: \.self) { i in
                Capsule()
                    .fill(playing ? AnyShapeStyle(Color.vaultAccent) : AnyShapeStyle(Color.white.opacity(0.35)))
                    .frame(width: 3.5, height: barHeight(i))
                    .animation(
                        playing
                            ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(Double(i) * 0.12)
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

struct SongRow: View {
    let song: Song
    let isFavorite: Bool
    let isCurrent: Bool
    @ObservedObject private var player = PlayerModel.shared

    var body: some View {
        HStack(spacing: 12) {
            ArtworkView(url: song.coverURL, size: 48, corner: 12)
            VStack(alignment: .leading, spacing: 3) {
                Text(song.title)
                    .font(.system(size: 15, weight: isCurrent ? .bold : .semibold))
                    .foregroundStyle(isCurrent ? Color.vaultAccent : .white)
                    .lineLimit(1)
                HStack(spacing: 5) {
                    Text(song.artist).font(.system(size: 12.5)).foregroundStyle(.secondary)
                    if let length = song.length {
                        Text("•").foregroundStyle(.secondary.opacity(0.5))
                        Text(length).font(.system(size: 12.5)).foregroundStyle(.secondary)
                    }
                }
                .lineLimit(1)
            }
            Spacer()
            if isCurrent {
                EqualizerBars(playing: player.isPlaying)
            } else if isFavorite {
                Image(systemName: "heart.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.vaultGold)
            }
            Image(systemName: "play.fill")
                .font(.system(size: 13))
                .foregroundStyle(Color.white.opacity(0.7))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 7)
    }
}

enum Vibe {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}