import SwiftUI

enum VaultTab: String, CaseIterable, Identifiable {
    case home = "home"
    case vault = "vault"
    case favorites = "favorites"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .home: return "house"
        case .vault: return "music.note.list"
        case .favorites: return "heart"
        }
    }

    var selectedIcon: String {
        icon + (icon.contains("list") ? "" : ".fill")
    }

    var label: String {
        switch self {
        case .home: return "Home"
        case .vault: return "Vault"
        case .favorites: return "Favorites"
        }
    }
}

struct CustomTabBar: View {
    @Binding var selection: VaultTab
    @Namespace private var pill

    var body: some View {
        HStack(spacing: 0) {
            ForEach(VaultTab.allCases) { tab in
                Button {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                        selection = tab
                    }
                    Vibe.tap()
                } label: {
                    VStack(spacing: 5) {
                        ZStack {
                            if selection == tab {
                                Capsule()
                                    .fill(Theme.accent.opacity(0.16))
                                    .frame(width: 48, height: 27)
                                    .matchedGeometryEffect(id: "activePill", in: pill)
                            }
                            Image(systemName: selection == tab ? tab.selectedIcon : tab.icon)
                                .font(.system(size: 19, weight: .semibold))
                                .foregroundStyle(selection == tab ? Theme.accent : Theme.tertiaryText)
                                .frame(width: 48, height: 27)
                        }
                        Text(tab.label)
                            .font(.system(size: 10.5, weight: selection == tab ? .bold : .medium))
                            .foregroundStyle(selection == tab ? Theme.primaryText : Theme.tertiaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.5), radius: 20, y: 8)
        )
        .padding(.horizontal, 14)
        .padding(.bottom, 6)
    }
}