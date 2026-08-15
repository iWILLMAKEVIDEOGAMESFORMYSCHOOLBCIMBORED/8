import SwiftUI

enum VaultTab: String, CaseIterable, Identifiable {
    case home = "home"
    case search = "search"
    case profile = "profile"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .home: return "house"
        case .search: return "magnifyingglass"
        case .profile: return "person.crop.circle"
        }
    }

    var selectedIcon: String {
        icon + ".fill"
    }

    var label: String {
        switch self {
        case .home: return "Home"
        case .search: return "Search"
        case .profile: return "Profile"
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
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
                        selection = tab
                    }
                    Vibe.tap()
                } label: {
                    VStack(spacing: 5) {
                        ZStack {
                            if selection == tab {
                                Capsule()
                                    .fill(Theme.accent.opacity(0.15))
                                    .frame(width: 46, height: 26)
                                    .matchedGeometryEffect(id: "activePill", in: pill)
                            }
                            Image(systemName: selection == tab ? tab.selectedIcon : tab.icon)
                                .font(.system(size: 19, weight: .medium))
                                .foregroundStyle(selection == tab ? Theme.accent : Theme.tertiaryText)
                                .frame(width: 46, height: 26)
                        }
                        Text(tab.label)
                            .font(.system(size: 10.5, weight: selection == tab ? .semibold : .regular))
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
                .shadow(color: .black.opacity(0.35), radius: 18, y: 6)
        )
        .padding(.horizontal, 14)
        .padding(.bottom, 6)
    }
}