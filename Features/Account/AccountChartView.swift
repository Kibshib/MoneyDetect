import SwiftUI
import Charts


struct AccountChartView: View {

    @ObservedObject var vm: AccountViewModel
    @State private var hover: BalancePoint?

    var body: some View {
        let today = Calendar.current.startOfDay(for: Date())
        let left = today
        let right = Calendar.current.date(byAdding: .day, value: -29, to: today)!
        let center = Calendar.current.date(byAdding: .day, value: -14, to: today)!
        let xLabels = [right, center, left]
        VStack(alignment: .leading, spacing: 12) {


            Picker("Mode", selection: $vm.chartMode) {
                ForEach(ChartMode.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .onChange(of: vm.chartMode) { _ in hover = nil }

            if !vm.isEditing {
                withAnimation(.easeInOut) {
                    Chart {
                        ForEach(points) { point in
                            BarMark(
                                x: .value("Date", point.date),
                                y: .value("Balance", abs(point.total.asDouble))
                            )
                            .foregroundStyle(barColor(for: point))
                            .cornerRadius(6)
                        }
                    }
                    .chartYAxis(.hidden)
                    .chartXAxis(.hidden)
                    .frame(height: 200)
                    .id(vm.chartMode.rawValue + points.map { $0.id.uuidString }.joined())
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                    .padding(.top , 32)
                    .overlay(alignment: .top) { tooltip }
                    .chartOverlay { proxy in
                        GeometryReader { geo in
                            Rectangle().fill(Color.clear).contentShape(Rectangle())
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            let location = value.location
                                            if let date: Date = proxy.value(atX: location.x) {
                                                if let match = points.min(by: { abs($0.date.timeIntervalSince1970 - date.timeIntervalSince1970) < abs($1.date.timeIntervalSince1970 - date.timeIntervalSince1970) }) {
                                                    hover = match
                                                }
                                            }
                                        }
                                        .onEnded { _ in hover = nil }
                                )
                        }
                    }
                }
            }
            if vm.chartMode == .months {
                let months = points.map { $0.date }
                let leftMonth = months.first
                let rightMonth = months.last
                let centerMonth = months.count > 2 ? months[months.count / 2] : nil
                HStack {
                    if let left = leftMonth {
                        Text(label(for: left))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 16)
                    }
                    if let center = centerMonth {
                        Text(label(for: center))
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    if let right = rightMonth {
                        Text(label(for: right))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.trailing, 16)
                    }
                }
                .font(.caption)
                .padding(.top, -24)
            } else {
                HStack {
                    Text(label(for: right))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 16)
                    Text(label(for: center))
                        .frame(maxWidth: .infinity, alignment: .center)
                    Text(label(for: left))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, 16)
                }
                .font(.caption)
                .padding(.top, -24)
            }
        }
    }

    private func barColor(for point: BalancePoint) -> Color {
        point.total.asDouble >= 0 ? .green : .orange
    }


    private var tooltip: some View {
        Group {
            if let hover {
                Text(label(for: hover.date) + ": " +
                        NumberFormatter.localizedString(from: hover.total as NSDecimalNumber, number: .currency))
                    .font(.caption)
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemBackground))
                            .shadow(radius: 4)
                    )
            }
        }
        .opacity(hover == nil ? 0 : 1)
        .animation(.easeInOut, value: hover)
        .padding(.top, 8)
    }


    private var points: [BalancePoint] {
        vm.chartMode == .days ? vm.dailyPoints : vm.monthlyPoints
    }


    private func label(for date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ru_RU")
        df.dateFormat = vm.chartMode == .days ? "dd.MM" : "LLLL yyyy"
        return df.string(from: date)
    }
}

private extension Decimal {
    var asDouble: Double { (self as NSDecimalNumber).doubleValue }
}
