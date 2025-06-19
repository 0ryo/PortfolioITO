//
//  TaskCompletionEffectView.swift
//  PocketGarden
//
//  Created by AI Assistant
//

import SwiftUI

struct TaskCompletionEffectView: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0
    @State private var rotation: Double = 0
    
    var body: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 30))
            .foregroundColor(.green)
            .scaleEffect(scale)
            .opacity(opacity)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    scale = 1.2
                    opacity = 1.0
                }
                withAnimation(.linear(duration: 0.5)) {
                    rotation = 360
                }
                withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                    scale = 0.8
                    opacity = 0.0
                }
            }
    }
} 