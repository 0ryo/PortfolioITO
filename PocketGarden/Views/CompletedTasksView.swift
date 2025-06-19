//
//  CompletedTasksView.swift
//  PocketGarden
//
//  Created by 伊藤瞭汰 on 2025/05/14.
//

import SwiftUI

struct CompletedTasksView: View {
    @EnvironmentObject private var vm: GardenViewModel
    @State private var showingDatePicker = false
    @State private var selectedDate = Date()
    
    var body: some View {
        List {
            Section {
                HStack {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.blue)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Button {
                        showingDatePicker.toggle()
                    } label: {
                        Text(dateFormatter.string(from: selectedDate))
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.blue)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 8)
            }
            
            if completedTasks.isEmpty {
                Section {
                    Text("この日に達成したタスクはありません 😌")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            } else {
                Section("達成したタスク") {
                    ForEach(completedTasks) { task in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            
                            VStack(alignment: .leading) {
                                Text(task.title)
                                
                                Text("カテゴリ: \(task.category)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(timeFormatter.string(from: task.createdAt))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .id(selectedDate)
        .navigationTitle("達成したタスク")
        .sheet(isPresented: $showingDatePicker) {
            VStack {
                HStack {
                    Button("キャンセル") {
                        showingDatePicker = false
                    }
                    
                    Spacer()
                    
                    Button("完了") {
                        showingDatePicker = false
                    }
                    .fontWeight(.bold)
                }
                .padding()
                
                DatePicker("日付を選択", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                
                Spacer()
            }
        }
    }
    
    private var completedTasks: [Task] {
        let calendar = Calendar.current
        return vm.tasks.filter { task in
            task.isDone && calendar.isDate(task.createdAt, inSameDayAs: selectedDate)
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }
} 