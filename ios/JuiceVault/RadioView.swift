import SwiftUI

struct RadioView: View {
    @ObservedObject private var radio = RadioModel.shared
    @State private var shake = false
    @State private var thump = false
    @State private var bigWaves = false

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            backgroundLayer
                .ignoresSafeArea()

            LinearGradient(
                colors: [.clear, Theme.bg.opacity(0.93)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                liveHeader

                Spacer(minLength: 10)

                VStack(spacing: 18) {
                    ZStack {
                        ArtworkView(url: radio.nowPlaying?.song.coverURL, size: 240, radius: 22)
                            .shadow(color: .black.opacity(0.5), radius: 30, y: 14)
                    }
                    .scaleEffect(thump ? 1.045 : 1.0)
                    .animation(.easeOut(duration: 0.12), value: thump)

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
            thump = false
        }
        .onChange(of: radio.beatPhase) { _ in
            withAnimation(.easeOut(duration: 0.12)) {
                thump.toggle()
            }
        }
    }

    private var liveHeader: some View {
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
        .padding(.top, 18)
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
                                .blur(radius: 46)
                        } else {
                            fallbackBackdrop
                        }
                    }
                } else {
                    fallbackBackdrop
                }
            }
            .frame(width: geo.size.width * 1.3, height: geo.size.height * 1.3)
            .offset(x: shake ? 14 : -14, y: shake ? -8 : 8)
            .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: shake)
            .scaleEffect(thump ? 1.05 : 0.965)
            .animation(.easeOut(duration: 0.12), value: thump)
            .opacity(0.62)
        }
    }

    private var fallbackBackdrop: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.deep, Theme.bg],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [Theme.accent.opacity(0.30), .clear],
                center: .top, startRadius: 10, endRadius: 480
            )
            Text("999")
                .font(Theme.display(240, .bold))
                .foregroundStyle(Color.white.opacity(0.05))
                .rotationEffect(.degrees(-14))
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