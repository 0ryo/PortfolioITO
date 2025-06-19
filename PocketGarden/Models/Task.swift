import Foundation

// MARK: - Task Entity
struct Task: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var category: String
    var isDone: Bool
    var createdAt: Date
    var endDate: Date?
    var deadline: Date?
    
    init(id: UUID = .init(),
         title: String,
         category: String = "Default",
         isDone: Bool = false,
         createdAt: Date = .now,
         endDate: Date? = nil,
         deadline: Date? = nil) {
        self.id = id
        self.title = title
        self.category = category
        self.isDone = isDone
        self.createdAt = createdAt
        self.endDate = endDate
        self.deadline = deadline
    }
}

// MARK: - Garden State
struct GardenState: Codable {
    var exp: Int        // 累計経験値
    var level: Int      // floor(exp / 10)
    
    mutating func addExp(_ delta: Int = 1) {
        exp += delta
        level = exp / 10
    }
}
