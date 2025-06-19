//
//  PocketGardenTests.swift
//  PocketGardenTests
//
//  Created by 伊藤瞭汰 on 2025/05/11.
//

import XCTest
import SwiftUI
@testable import PocketGarden
@MainActor

final class GrowthLogicTests: XCTestCase {
    
    func testAddExpIncrementsLevelAt10() {
        var g = GardenState(exp: 9, level: 0)
        g.addExp()
        XCTAssertEqual(g.exp, 10)
        XCTAssertEqual(g.level, 1)
    }
    
    func testToggleDoneAddsExp() {
        let vm = GardenViewModel()
        vm.addTask("TEST", category: "Default")
        let task = vm.tasks.first!
        vm.toggleDone(task: task)
        XCTAssertEqual(vm.gardens["Default"]?.exp, 1)
    }
    
    func testColorAssetsExist() {
        XCTAssertNotNil(Color("LeafPrimary"))
        XCTAssertNotNil(Color("LeafSecondary"))
    }
}

final class FocusTimerTests: XCTestCase {
    
    func testNegativeTimerHandling() async {
        let vm = GardenViewModel()
        vm.startFocus()
        
        // プライベートフィールドを反射APIで操作
        let mirror = Mirror(reflecting: vm)
        if let targetDateProperty = mirror.children.first(where: { $0.label == "targetDate" }) {
            if var targetDate = targetDateProperty.value as? Date {
                // 強制的に過去の日付に設定（-10秒）
                targetDate = Date().addingTimeInterval(-10)
                
                // KeyPathを使ってプライベートプロパティを変更
                if let targetDateKeyPath = \GardenViewModel.targetDate as Any as? ReferenceWritableKeyPath<GardenViewModel, Date?> {
                    vm[keyPath: targetDateKeyPath] = targetDate
                }
            }
        }
        
        // ScenePhaseがactiveになった時の処理を呼び出す
        vm.handleScenePhaseChange(to: .active)
        
        // タイマーが正しく終了処理されていることを確認
        XCTAssertEqual(vm.remainingSeconds, 0)
        
        // フェーズが自動的に変わっていることを確認（フォーカス→休憩）
        XCTAssertEqual(vm.focusPhase, .rest)
    }
    
    func testLogging() {
        // os_logに関するテスト
        // 実際のログ出力をテストするのは難しいため、ここではシミュレーションのみ
        let vm = GardenViewModel()
        vm.startFocus()
        vm.skipPhase() // フォーカス終了、os_logが呼ばれるはず
        XCTAssertEqual(vm.focusPhase, .rest)
    }
}
