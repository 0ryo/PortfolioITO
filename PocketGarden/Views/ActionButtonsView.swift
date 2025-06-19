import SwiftUI

// MARK: - Action Buttons Component
struct ActionButtonsView: View {
    @EnvironmentObject private var vm: GardenViewModel
    @Binding var goFocus: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Focus Start Button
            Button {
                goFocus = true
            } label: {
                Label("Start Focus", systemImage: "timer")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.green.opacity(0.2), in: .capsule)
            }
            .buttonStyle(.plain)
            
            // Completed Tasks Navigation
            NavigationLink {
                CompletedTasksView()
            } label: {
                Label("達成したタスク", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.blue.opacity(0.2), in: .capsule)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
    }
}

// MARK: - Complete All Tasks Button
struct CompleteAllTasksButton: View {
    @EnvironmentObject private var vm: GardenViewModel
    
    var body: some View {
        Button {
            let tasks = vm.tasks.filter { $0.category == vm.currentCategory && !$0.isDone }
            for task in tasks {
                vm.toggleDone(task: task)
            }
        } label: {
            Label("全てのタスクを達成", systemImage: "checkmark.circle.fill")
                .font(.caption)
        }
        .disabled(vm.tasks.filter { $0.category == vm.currentCategory && !$0.isDone }.isEmpty)
    }
} 