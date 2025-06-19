import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var vm: GardenViewModel
    @State private var showAdd = false
    @State private var goFocus = false
    @State private var completingTasks: Set<UUID> = []
    @State private var expandingTasks: Set<UUID> = []
    @State private var showCompletionEffect = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Experience Gauge
                ExpGaugeView(
                    currentExp: vm.gardens[vm.currentCategory]?.exp ?? 0,
                    currentLevel: vm.gardens[vm.currentCategory]?.level ?? 0,
                    maxExp: ((vm.gardens[vm.currentCategory]?.level ?? 0) + 1) * 10
                )
                .frame(width: 200, height: 200)
                .padding(.bottom, 10)
                
                // Task List with Completion Effects
                ZStack {
                    TaskListView(
                        completingTasks: $completingTasks,
                        expandingTasks: $expandingTasks,
                        showCompletionEffect: $showCompletionEffect
                    )
                    
                    // Completion Effect Overlay
                    if showCompletionEffect {
                        TaskCompletionEffectView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .allowsHitTesting(false)
                    }
                }
                
                // Action Buttons
                ActionButtonsView(goFocus: $goFocus)
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
                ToolbarItem(placement: .bottomBar) {
                    CompleteAllTasksButton()
                }
            }
            .sheet(isPresented: $showAdd) { AddTaskSheet() }
            .navigationDestination(isPresented: $goFocus) { FocusView() }
        }
    }
}

// MARK: - Add Task Sheet
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
                    
                    DateSelectionRow(
                        title: "開始日時",
                        date: startDate,
                        formatter: dateTimeFormatter
                    ) {
                        showStartDatePicker = true
                    }
                    
                    DateSelectionRow(
                        title: "終了日時",
                        date: endDate,
                        formatter: dateTimeFormatter
                    ) {
                        showEndDatePicker = true
                    }
                    
                    DateSelectionRow(
                        title: "締切日",
                        date: deadline,
                        formatter: dateFormatter
                    ) {
                        showDeadlinePicker = true
                    }
                }
            }
            .navigationTitle("新規タスク")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル", action: dismiss.callAsFunction)
                }
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
                    }
                    .disabled(title.isEmpty)
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
    
    // MARK: - Computed Properties
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

// MARK: - Date Selection Row
struct DateSelectionRow: View {
    let title: String
    let date: Date
    let formatter: DateFormatter
    let action: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(formatter.string(from: date))
                .foregroundColor(.blue)
                .onTapGesture(perform: action)
        }
    }
}

// MARK: - Date Picker Sheet
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
