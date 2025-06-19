//
//  ContentView.swift
//  PocketGarden
//
//  Created by 伊藤瞭汰 on 2025/05/11.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var vm: GardenViewModel
    @State private var showAdd = false
    @State private var goFocus = false
    @State private var completingTasks: Set<UUID> = []  // 完了中のタスクID管理
    @State private var expandingTasks: Set<UUID> = []  // 拡大中のタスクID管理
    @State private var showCompletionEffect = false  // 完了エフェクト表示制御
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                ExpGaugeView(
                    currentExp: vm.gardens[vm.currentCategory]?.exp ?? 0,
                    currentLevel: vm.gardens[vm.currentCategory]?.level ?? 0,
                    maxExp: ((vm.gardens[vm.currentCategory]?.level ?? 0) + 1) * 10
                )
                .frame(width: 200, height: 200)
                .padding(.vertical, 20)
                
                // 一時的なテストボタン（デバッグ用）
                HStack(spacing: 12) {
                    Button {
                        vm.resetExpAndLevel(category: vm.currentCategory)
                    } label: {
                        Text("EXP リセット")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(8)
                            .background(Color.red.opacity(0.1), in: .capsule)
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        // EXP増加アニメーションのテスト用
                        vm.addExpForTest(category: vm.currentCategory, amount: 1)
                    } label: {
                        Text("+1 EXP テスト")
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(8)
                            .background(Color.green.opacity(0.1), in: .capsule)
                    }
                    .buttonStyle(.plain)
                }
                
                ZStack {
                    List {
                        ForEach(vm.tasks.filter { $0.category == vm.currentCategory && !$0.isDone }) { task in
                            HStack {
                                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                                                                    .onTapGesture { 
                                    // 完了エフェクトを表示
                                    showCompletionEffect = true
                                    
                                    // ステップ1: 少し大きくなるアニメーション
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        expandingTasks.insert(task.id)
                                    }
                                    
                                    // ステップ2: 0.2秒後に縮小＆フェードアウト
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            expandingTasks.remove(task.id)
                                            completingTasks.insert(task.id)
                                        }
                                    }
                                    
                                    // ステップ3: 0.6秒後に実際の完了処理
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                        vm.toggleDone(task: task)
                                        completingTasks.remove(task.id)
                                    }
                                    
                                    // 1秒後にエフェクトを非表示
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                        showCompletionEffect = false
                                    }
                                }
                                Text(task.title)
                            }
                            .opacity(completingTasks.contains(task.id) ? 0.0 : 1.0)  // フェードアウト効果
                            .scaleEffect(
                                expandingTasks.contains(task.id) ? 1.1 :  // 拡大フェーズ
                                completingTasks.contains(task.id) ? 0.0 : 1.0  // 縮小フェーズ
                            )
                        }
                    .onDelete { index in
                        index.map { 
                            let task = vm.tasks[$0]
                            if !task.isDone {
                                vm.toggleDone(task: task)
                            }
                        }
                    }
                    .deleteDisabled(true)
                    .swipeActions(edge: .trailing) {
                        Button {
                            // 削除機能は残しておく
                            if let index = vm.tasks.firstIndex(where: { $0.category == vm.currentCategory }) {
                                vm.delete(task: vm.tasks[index])
                            }
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            if let index = vm.tasks.firstIndex(where: { $0.category == vm.currentCategory }) {
                                vm.toggleDone(task: vm.tasks[index])
                            }
                        } label: {
                            Label("達成", systemImage: "checkmark")
                        }
                        .tint(.green)
                    }
                    .transition(.asymmetric(insertion: .slide, removal: .move(edge: .trailing)))  // 挿入・削除のトランジション
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: vm.tasks)  // リスト変更のアニメーション
                
                // 完了エフェクトオーバーレイ
                if showCompletionEffect {
                    TaskCompletionEffectView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .allowsHitTesting(false)
                }
            }
                .toolbar {
                    ToolbarItem(placement: .bottomBar) {
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
                
                Button {
                    vm.startFocus()
                    goFocus = true
                } label: {
                    Label("Start Focus", systemImage: "timer")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.green.opacity(0.2), in: .capsule)
                }
                .padding(.horizontal)
                .buttonStyle(.plain)
                
                NavigationLink {
                    CompletedTasksView()
                } label: {
                    Label("達成したタスク", systemImage: "checkmark.seal.fill")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.blue.opacity(0.2), in: .capsule)
                }
                .padding(.horizontal)
                .buttonStyle(.plain)
            }
            .navigationTitle("Pocket Garden")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink("Stats") { StatisticsView() }
                }
            }
            .sheet(isPresented: $showAdd) { AddTaskSheet() }
            .navigationDestination(isPresented: $goFocus) { FocusView() }
        }
    }
}

// --- Quick Add Sheet ---
struct AddTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vm: GardenViewModel
    @State private var title = ""
    @State private var selectedCategory = "Default"
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600) // 1時間後
    @State private var deadline = Date().addingTimeInterval(86400) // 1日後
    @State private var showStartDatePicker = false
    @State private var showEndDatePicker = false
    @State private var showDeadlinePicker = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("タスク詳細")) {
                    TextField("タスク名", text: $title)
                    
                    Picker("カテゴリ", selection: $selectedCategory) {
                        ForEach(Array(vm.gardens.keys), id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    
                    HStack {
                        Text("開始日時")
                        Spacer()
                        Text(dateTimeFormatter.string(from: startDate))
                            .foregroundColor(.blue)
                            .onTapGesture {
                                showStartDatePicker = true
                            }
                    }
                    
                    HStack {
                        Text("終了日時")
                        Spacer()
                        Text(dateTimeFormatter.string(from: endDate))
                            .foregroundColor(.blue)
                            .onTapGesture {
                                showEndDatePicker = true
                            }
                    }
                    
                    HStack {
                        Text("締切日")
                        Spacer()
                        Text(dateFormatter.string(from: deadline))
                            .foregroundColor(.blue)
                            .onTapGesture {
                                showDeadlinePicker = true
                            }
                    }
                }
            }
            .navigationTitle("新規タスク")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル", action: dismiss.callAsFunction) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        let task = Task(
                            title: title,
                            category: selectedCategory,
                            isDone: false,
                            createdAt: startDate,
                            endDate: endDate,
                            deadline: deadline
                        )
                        vm.addTask(task)
                        dismiss()
                    }.disabled(title.isEmpty)
                }
            }
            .sheet(isPresented: $showStartDatePicker) {
                DatePickerSheet(
                    date: $startDate,
                    isPresented: $showStartDatePicker,
                    title: "開始日時を選択"
                )
            }
            .sheet(isPresented: $showEndDatePicker) {
                DatePickerSheet(
                    date: $endDate,
                    isPresented: $showEndDatePicker,
                    title: "終了日時を選択"
                )
            }
            .sheet(isPresented: $showDeadlinePicker) {
                DatePickerSheet(
                    date: $deadline,
                    isPresented: $showDeadlinePicker,
                    title: "締切日を選択",
                    displayComponents: .date
                )
            }
        }
    }
    
    private var dateTimeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }
}

struct DatePickerSheet: View {
    @Binding var date: Date
    @Binding var isPresented: Bool
    let title: String
    var displayComponents: DatePickerComponents = [.date, .hourAndMinute]
    
    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    title,
                    selection: $date,
                    displayedComponents: displayComponents
                )
                .datePickerStyle(.graphical)
                .padding()
                
                Spacer()
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") {
                        isPresented = false
                    }
                }
            }
        }
    }
}
