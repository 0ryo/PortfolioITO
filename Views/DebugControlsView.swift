import SwiftUI

// MARK: - Debug Controls (Development Only)
struct DebugControlsView: View {
    @EnvironmentObject private var vm: GardenViewModel
    
    var body: some View {
        // デバッグボタンを削除し、空のViewに変更
        EmptyView()
    }
}

// MARK: - Debug Button Style
extension View {
    #if DEBUG
    func debugButtonStyle(_ color: Color) -> some View {
        self
            .font(.caption)
            .foregroundColor(color)
            .padding(8)
            .background(color.opacity(0.1), in: .capsule)
            .buttonStyle(.plain)
    }
    #endif
} 