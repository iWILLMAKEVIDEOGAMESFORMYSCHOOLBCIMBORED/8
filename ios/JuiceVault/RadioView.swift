import SwiftUI

struct RadioView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var radio = RadioModel.shared
    @State private var shake = false
    @State private var bigWaves = false

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            backgroundLayer
                .ignoresSafeArea()

            LinearGradient(
                colors: [.clear, Theme.bg.opacity(0.92)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Theme.primaryText)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(Color.black.opacity(0.4)))
                    }
                    Spacer()
                    HStack(spacing: 6) {
                        Circle()
                            .fill(radio.isPlaying ? Theme.danger : Theme.accent)
                            .frame(width: 7, height: 7)
                        Text("LIVE")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(1.5)
                            .foregroundStyle(radio.isPlaying ? Theme.danger : Theme.accent)
                        Text("999 Radio")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.primaryText)
                    }
                    Spacer()
                    Color.clear.frame(width: 34, height: 34)
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)

                Spacer(minLength: 10)

                VStack(spacing: 18) {
                    ArtworkView(url: radio.nowPlaying?.song.coverURL, size: 240, radius: 22)
                        .shadow(color: .black.opacity(0.5), radius: 30, y: 14)

                    VStack(spacing: 7) {
                        Text(radio.nowPlaying?.title ?? "999 Radio")
                            .font(.system(size: 21, weight: .medium))
                            .foregroundStyle(Theme.primaryText)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                        Text(radio.nowPlaying?.artist ?? "Tune in — the vault never sleeps")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.secondaryText)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 24)
                }

                Spacer(minLength: 14)

                bigWaveform
                    .frame(height: 46)
                    .padding(.bottom, 18)

                Button {
                    radio.toggle()
                    Vibe.tap()
                } label: {
                    Image(systemName: radio.isPlaying ? "stop.fill" : "play.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 70, height: 70)
                        .background(
                            Circle()
                                .fill(radio.isPlaying ? Theme.danger : Theme.accent)
                                .shadow(color: Theme.accent.opacity(0.4), radius: 16, y: 8)
                        )
                }

                Text(radio.isPlaying ? "Feel the beat" : "Tap to go live")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.tertiaryText)
                    .padding(.top, 14)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 26)
            .padding(.bottom, 22)
        }
        .onAppear {
            shake = true
            if radio.isPlaying { radio.attachBeat() }
        }
        .onChange(of: radio.isPlaying) { playing in
            if playing { radio.attachBeat() } else { radio.detachBeat() }
        }
        .onDisappear {
            radio.detachBeat()
        }
    }

    private var backgroundLayer: some View {
        GeometryReader { geo in
            ZStack {
                if let url = radio.nowPlaying?.song.coverURL {
                    AsyncImage(url: url) { phase in
                        if case .success(let image) = phase {
                            image
                                .resizable()
                                .scaledToFill()
                                .blur(radius: 40)
                        } else {
                            Theme.deep
                        }
                    }
                } else {
                    Theme.deep
                }
            }
            .frame(width: geo.size.width * 1.25, height: geo.size.height * 1.25)
            .offset(x: shake ? 10 : -10, y: shake ? -6 : 6)
            .animation(
                .easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                value: shake
            )
            .opacity(0.55)
        }
    }

    private var bigWaveform: some View {
        HStack(alignment: .center, spacing: 5) {
            ForEach(0..<7, id: \.self) { i in
                Capsule()
                    .fill(radio.isPlaying ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(Theme.tertiaryText))
                    .frame(width: 6, height: waveHeight(i))
                    .animation(
                        radio.isPlaying
                            ? .easeInOut(duration: 0.55).repeatForever(autoreverses: true).delay(Double(i) * 0.08)
                            : .linear(duration: 0.1),
                        value: bigWaves
                    )
            }
        }
        .onAppear { bigWaves = true }
        .onChange(of: radio.isPlaying) { playing in
            guard playing else { return }
            bigWaves = false
            Task {
                try? await Task.sleep(nanoseconds: 50_000_000)
                bigWaves = true
            }
        }
    }

    private func waveHeight(_ i: Int) -> CGFloat {
        let heights: [CGFloat] = [18, 34, 24, 42, 28, 38, 20]
        return radio.isPlaying ? (bigWaves ? heights[i] : heights[i] * 0.35) : 8
    }
}