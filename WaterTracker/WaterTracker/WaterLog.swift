import Foundation
import SwiftData

@Model
final class WaterLog {
    var date: Date
    var amountML: Int
    
    init(date: Date, amountML: Int) {
        self.date = date
        self.amountML = amountML
    }
}
