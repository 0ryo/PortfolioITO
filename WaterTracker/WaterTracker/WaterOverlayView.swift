import SwiftUI


struct WaveShape: Shape {
    var phase: CGFloat     // 波の位相
    var amplitude: CGFloat // 波の振幅
    var base: CGFloat      // 波の高さ

    var animatableData: CGFloat {
        get { base }
        set { base = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let width = rect.width
        let height = rect.height

        let startY = base + sin(phase) * amplitude
        p.move(to: CGPoint(x: 0, y: startY))

        let step: CGFloat = max(1, width / 220)
        let freq: CGFloat = 1.6
        for x in stride(from: 0, through: width, by: step) {
            let normalizedX = x / width
            let y = base + sin((.pi * 2 * freq * normalizedX) + phase) * amplitude
            p.addLine(to: CGPoint(x: x, y: y))
        }

        p.addLine(to: CGPoint(x: width, y: height))
        p.addLine(to: CGPoint(x: 0, y: height))
        p.closeSubpath()
        return p
    }
}

struct WaterOverlayView: View {
    @Binding var isPresented: Bool
    var message: String

    @State private var progress: CGFloat = 0
    @State private var phase: CGFloat = 0
    @State private var running = false
    @State private var showText = false

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let amplitude = max(8, h * 0.03)
            let baseY = h * (1 - progress)

            ZStack {
                Color.clear

                // 波
                WaveShape(phase: phase + .pi, amplitude: amplitude * 0.8, base: baseY + 4)
                    .fill(
                        LinearGradient(gradient: Gradient(colors: [
                            Color.blue,
                            Color.cyan
                        ]), startPoint: .top, endPoint: .bottom)
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea(.all)

                VStack {
                    Text("Recorded")
                        .font(.system(size: 24, weight: .semibold))
                        .multilineTextAlignment(.center)

                    Text(message)
                        .font(.system(size: 40, weight: .bold))
                        .multilineTextAlignment(.center)
                        .padding(40)

                    Button(action: close) {
                        Text("Back")
                            .font(.system(size: 24, weight: .semibold))
                            .padding(.vertical, 12)
                            .padding(.horizontal, 28)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(.white)
                            )
                    }
                    .accessibilityIdentifier("nextButton")
                }
                // フェードインのタイミング
                .opacity(showText ? 1 : 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(.all)
            .onAppear(perform: open)
            .onReceive(Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()) { _ in
                guard running else { return }
                phase += 0.08
            }
        }
        .ignoresSafeArea(.all)
    }

    private func open() {
        running = true
        withAnimation(.easeInOut(duration: 2.0)) {
            progress = 0.9 // 波の高さ
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.8)) {
                showText = true
            }
        }
    }

    private func close() {
        showText = false
        withAnimation(.easeInOut(duration: 1.0)) {
            progress = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            running = false
            isPresented = false
        }
    }
}

#Preview {
    StatefulPreviewWrapper(false) { binding in
        WaterOverlayView(isPresented: binding, message: "テスト表示")
    }
}

struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State var value: Value
    let content: (Binding<Value>) -> Content
    init(_ value: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: value)
        self.content = content
    }
    var body: some View {
        content($value)
    }
}
