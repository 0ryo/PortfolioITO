import SwiftUI
import Combine

@MainActor
final class GardenViewModel: ObservableObject {
    // MARK: - Published States
    @Published private(set) var tasks: [Task] = []
    @Published private(set) var gardens: [String: GardenState] = ["Default": .init(exp: 0, level: 0)]
    @Published var currentCategory: String = "Default"
    @Published private(set) var lastLevelUp: Date?
    
    // MARK: - Private Properties
    private let persistenceKey = "PocketGarden.store"
    
    // MARK: - Initialization
    init() {
        // 初期化処理のみ
    }
    
    // MARK: - TASK CRUD
    func addTask(_ title: String, category: String) {
        tasks.append(.init(title: title, category: category))
        save()
    }
    
    func addTask(_ task: Task) {
        tasks.append(task)
        save()
    }
    
    func toggleDone(task: Task) {
        guard let idx = tasks.firstIndex(of: task) else { return }
        tasks[idx].isDone.toggle()
        if tasks[idx].isDone { completeTask(category: task.category) }
        save()
    }
    
    func delete(task: Task) {
        tasks.removeAll { $0.id == task.id }
        save()
    }
    
    func completeTask(category: String) {
        ensureGardenExists(for: category)
        
        let oldLevel = gardens[category]!.level
        gardens[category]!.addExp()
        
        if gardens[category]!.level > oldLevel {
            lastLevelUp = Date()
        }
    }
    
    private func ensureGardenExists(for category: String) {
        if gardens[category] == nil {
            gardens[category] = .init(exp: 0, level: 0)
        }
    }
    
    
    // ScenePhaseが変更されたときに呼び出される
    func handleScenePhaseChange(to phase: ScenePhase) {
        // アプリがバックグラウンドに移行した際にも保存
        if phase == .background {
            save()
        }
    }
    
    // MARK: - Persistence (UserDefaults+JSON)
    func save() {
        let bundle = BundleData(tasks: tasks, gardens: gardens)
        guard let data = try? JSONEncoder().encode(bundle) else { return }
        UserDefaults.standard.set(data, forKey: persistenceKey)
    }
    
    func load() {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey),
              let bundle = try? JSONDecoder().decode(BundleData.self, from: data) else { 
            return 
        }
        
        tasks = bundle.tasks
        gardens = bundle.gardens
    }
    
    private struct BundleData: Codable {
        let tasks: [Task]
        let gardens: [String: GardenState]
    }
    
    // MARK: - Statistics (Heat-map)
    struct HeatEntry: Identifiable { let id = UUID(); let date: Date; let minutes: Int }
    
    func aggregatedStudyMinutes() -> [HeatEntry] {
        let calendar = Calendar.current
        // セッション=25min のみカウント
        var dict: [Date: Int] = [:]
        for task in tasks where task.isDone {
            let day = calendar.startOfDay(for: task.createdAt)
            dict[day, default: 0] += 25
        }
        return dict.map { HeatEntry(date: $0.key, minutes: $0.value) }
    }
    
    // MARK: - Development/Debug Methods
    #if DEBUG
    func resetExpAndLevel(category: String) {
        gardens[category] = .init(exp: 0, level: 0)
        save()
    }
    
    func addExpForTest(category: String, amount: Int = 1) {
        ensureGardenExists(for: category)
        
        let oldLevel = gardens[category]!.level
        gardens[category]!.addExp(amount)
        
        if gardens[category]!.level > oldLevel {
            lastLevelUp = Date()
        }
        save()
    }
    #endif
}
