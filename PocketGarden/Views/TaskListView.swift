import SwiftUI

// MARK: - Task List Component
struct TaskListView: View {
    @EnvironmentObject private var vm: GardenViewModel
    @Binding var completingTasks: Set<UUID>
    @Binding var expandingTasks: Set<UUID>
    @Binding var showCompletionEffect: Bool
    
    var body: some View {
        List {
            ForEach(uncompletedTasks) { task in
                TaskRowView(
                    task: task,
                    completingTasks: $completingTasks,
                    expandingTasks: $expandingTasks,
                    showCompletionEffect: $showCompletionEffect,
                    onToggle: { vm.toggleDone(task: task) }
                )
            }
            .onDelete(perform: deleteTask)
        }
        .swipeActions(edge: .trailing) {
            Button("削除", systemImage: "trash") {
                deleteFirstTask()
            }
            .tint(.red)
        }
        .swipeActions(edge: .leading) {
            Button("達成", systemImage: "checkmark") {
                completeFirstTask()
            }
            .tint(.green)
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: vm.tasks)
    }
    
    // MARK: - Computed Properties
    private var uncompletedTasks: [Task] {
        vm.tasks.filter { $0.category == vm.currentCategory && !$0.isDone }
    }
    
    // MARK: - Methods
    private func deleteTask(at offsets: IndexSet) {
        offsets.forEach { index in
            let task = uncompletedTasks[index]
            vm.delete(task: task)
        }
    }
    
    private func deleteFirstTask() {
        if let task = uncompletedTasks.first {
            vm.delete(task: task)
        }
    }
    
    private func completeFirstTask() {
        if let task = uncompletedTasks.first {
            vm.toggleDone(task: task)
        }
    }
}

// MARK: - Task Row Component
struct TaskRowView: View {
    let task: Task
    @Binding var completingTasks: Set<UUID>
    @Binding var expandingTasks: Set<UUID>
    @Binding var showCompletionEffect: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                .onTapGesture {
                    handleTaskCompletion()
                }
            Text(task.title)
        }
        .opacity(completingTasks.contains(task.id) ? 0.0 : 1.0)
        .scaleEffect(taskScale)
        .transition(.asymmetric(insertion: .slide, removal: .move(edge: .trailing)))
    }
    
    // MARK: - Computed Properties
    private var taskScale: CGFloat {
        if expandingTasks.contains(task.id) {
            return 1.1
        } else if completingTasks.contains(task.id) {
            return 0.0
        } else {
            return 1.0
        }
    }
    
    // MARK: - Task Completion Animation
    private func handleTaskCompletion() {
        showCompletionEffect = true
        
        // ステップ1: 拡大アニメーション
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            expandingTasks.insert(task.id)
        }
        
        // ステップ2: 縮小＆フェードアウト
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                expandingTasks.remove(task.id)
                completingTasks.insert(task.id)
            }
        }
        
        // ステップ3: 実際の完了処理
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            onToggle()
            completingTasks.remove(task.id)
        }
        
        // エフェクト非表示
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showCompletionEffect = false
        }
    }
} 