import SwiftUI
import AVFoundation

@main
struct JuiceVaultApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject private var player = PlayerModel.shared
    @State private var tab: VaultTab = .home
    @State private var showFullPlayer = false

    init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    var body: some Scene {
        WindowGroup {
            VStack(spacing: 0) {
                ZStack {
                    Theme.bg.ignoresSafeArea()
                    switch tab {
                    case .home:
                        HomeView()
                    case .vault:
                        LibraryView()
                    case .favorites:
                        FavoritesView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if player.currentSong != nil {
                    PlayerBarView(showFullPlayer: $showFullPlayer)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .background(Theme.bg)
            .preferredColorScheme(.dark)
            .animation(.spring(response: 0.38, dampingFraction: 0.86), value: player.currentSong != nil)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                CustomTabBar(selection: $tab)
            }
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