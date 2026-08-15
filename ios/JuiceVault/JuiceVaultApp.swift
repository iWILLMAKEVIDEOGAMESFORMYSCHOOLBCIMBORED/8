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
                .tint(Color(red: 0.5, green: 0.85, blue: 0.45))

                if player.currentSong != nil {
                    PlayerBarView(showFullPlayer: $showFullPlayer)
                }
            }
            .background(Color(red: 0.06, green: 0.05, blue: 0.09))
            .preferredColorScheme(.dark)
            .sheet(isPresented: $showFullPlayer) {
                FullPlayerView()
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