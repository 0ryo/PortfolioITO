//
//  PocketGardenApp.swift
//  PocketGarden
//
//  Created by 伊藤瞭汰 on 2025/05/11.
//

import SwiftUI

@main
struct PocketGardenApp: App {
    // アプリ全体で共有する ViewModel を生成
    @StateObject private var gardenVM = GardenViewModel()
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            HomeView()                       // エントリ画面
                .environmentObject(gardenVM) // 下層 View へ DI
                .onAppear { gardenVM.load() } // 起動時に永続データ読込
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
                    gardenVM.save()          // 終了直前に保存
                }
                .onChange(of: scenePhase) { newPhase in
                    // ScenePhaseの変更をViewModelに通知
                    gardenVM.handleScenePhaseChange(to: newPhase)
                    
                    // アプリ終了時にも保存
                    if newPhase == .background {
                        gardenVM.save()
                    }
                }
        }
    }
}
