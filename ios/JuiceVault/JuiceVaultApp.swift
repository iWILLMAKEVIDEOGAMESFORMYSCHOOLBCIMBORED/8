import SwiftUI
import AVFoundation

@main
struct JuiceVaultApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject private var player = PlayerModel.shared
    @State private var showFullPlayer = false

    init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    var body: some Scene {
        WindowGroup {
            VStack(spacing: 0) {
                TabView {
                    HomeView()
                        .tabItem { Label("Home", systemImage: "house.fill") }
                    LibraryView()
                        .tabItem { Label("Vault", systemImage: "music.note.list") }
                    FavoritesView()
                        .tabItem { Label("Favorites", systemImage: "heart.fill") }
                }
                .tint(Theme.accent)
                .toolbarBackground(Theme.bg, for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)

                if player.currentSong != nil {
                    PlayerBarView(showFullPlayer: $showFullPlayer)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .background(Theme.bg)
            .preferredColorScheme(.dark)
            .animation(.spring(response: 0.38, dampingFraction: 0.86), value: player.currentSong != nil)
            .sheet(isPresented: $showFullPlayer) {
                FullPlayerView()
                    .presentationDragIndicator(.hidden)
            }
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        application.beginReceivingRemoteControlEvents()
        return true
    }
}