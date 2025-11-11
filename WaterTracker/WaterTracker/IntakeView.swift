import SwiftUI
import SwiftData

// 親から @Binding で waterAmount を受け取る
struct IntakeView: View {
    @Environment(\.modelContext) private var context
    @Binding var waterAmount: Double

    var onLogged: (Int) -> Void = { _ in }

    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Image(systemName: "spigot")
                        .resizable()
                        .frame(width: 94, height: 75)
                        .scaledToFill()
                        .padding(.leading, 80)
                    Spacer()
                }

                ZStack(alignment: .bottom) {
                    Rectangle()
                        .frame(width: 140, height: 240)
                        .foregroundStyle(.black)
                        .clipShape(.rect(
                            topLeadingRadius: 5, bottomLeadingRadius: 10, bottomTrailingRadius: 10, topTrailingRadius: 5
                        ))

                    Rectangle()
                        .frame(width: 120, height: 240)
                        .foregroundStyle(.white)
                        .padding(.bottom, 10)
                        .clipShape(.rect(
                            topLeadingRadius: 0, bottomLeadingRadius: 10, bottomTrailingRadius: 10, topTrailingRadius: 0
                        ))
                    Rectangle()
                        .frame(width: 120, height: 60)
                        .foregroundStyle(.tint)
                        .padding(.bottom, 10)
                        .clipShape(.rect(
                            topLeadingRadius: 0, bottomLeadingRadius: 10, bottomTrailingRadius: 10, topTrailingRadius: 0
                        ))
                }
                .padding(30)

                Text(String(waterAmount))
                    .fontWeight(.semibold)
                Divider()
                    .frame(width: 200)
                ZStack {
                    Slider(value: $waterAmount, in: 0...100, step: 25)
                        .padding(.horizontal, 75)
                        .overlay(alignment: .bottomLeading) {
                            GeometryReader { geo in
                                let w = geo.size.width
                                ZStack(alignment: .topLeading) {
                                    ForEach(IntakeView.Tick.allCases, id: \.self) { tick in
                                        tick.view.offset(x: w * tick.position, y: 12)
                                    }
                                }
                            }
                        }
                }
                Button(action: {
                    let log = WaterLog(date: .now, amountML: Int(waterAmount))
                    context.insert(log)
                    do {
                        try context.save()
                        onLogged(Int(waterAmount))
                    } catch {
                        print("Save error: \(error)")
                    }
                }, label: {
                    ZStack {
                        Rectangle()
                            .frame(width: 140, height: 60)
                            .clipShape(.rect(
                                topLeadingRadius: 15, bottomLeadingRadius: 15, bottomTrailingRadius: 15, topTrailingRadius: 15
                            ))
                            .overlay() {
                                HStack(spacing: 20) {
                                    Image(systemName: "drop.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 30)
                                        .foregroundStyle(.white)
                                    Text("Log")
                                        .foregroundStyle(.white)
                                        .font(.system(size: 35))
                                }
                            }
                    }
                })
                .padding(.top, 12)
            }
        }
    }
}

extension IntakeView {
    enum Tick: CaseIterable {
        case quarter
        case half
        case threeQuarter

        var position: CGFloat {
            switch self {
            case .quarter: return 0.36
            case .half: return 0.50
            case .threeQuarter: return 0.64
            }
        }

        var view: some View {
            Rectangle()
                .frame(width: 2, height: 8)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
    }
}

#Preview {
    IntakeView(waterAmount: .constant(25.0)) { amount in
        print("Logged: \\ (amount) ml")
    }
}
