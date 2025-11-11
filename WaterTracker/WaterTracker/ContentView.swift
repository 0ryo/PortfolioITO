import SwiftUI

struct ContentView: View {
    @State private var selectedwtMode = wtMode.intake
    @State private var waterAmount = 25.0
    @State private var showOverlay = false
    @State private var overlayMessage = ""

    var body: some View {
        ZStack { 
            VStack(alignment: .center) {
                Picker("", selection: $selectedwtMode) {
                    ForEach(wtMode.allCases) { wtMode in
                        Text(wtMode.rawValue).tag(wtMode)
                    }
                }
                .colorMultiply(.white)
                .pickerStyle(.segmented)
                .padding()

                // セグメント
                ZStack {
                    switch selectedwtMode {
                    case .intake:
                        IntakeView(
                            waterAmount: $waterAmount,
                            onLogged: { amount in
                                overlayMessage = "\(amount) ml"
                                showOverlay = true
                            }
                        )
                    case .records:
                        RecordsView()
                    }
                }
                .frame(width: 375, height: 670)
                .clipped()
                .contentTransition(.opacity)
            }
            .frame(alignment: .top)

            // オーバーレイ
            if showOverlay {
                WaterOverlayView(isPresented: $showOverlay, message: overlayMessage)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea(.all)
                    .zIndex(1)
            }
        }
    }
}

extension ContentView {
    enum wtMode: String, CaseIterable, Identifiable {
        case intake = "Log Intake"
        case records = "Records"
        
        var id: String { rawValue }
    }
}

#Preview {
    ContentView()
}
