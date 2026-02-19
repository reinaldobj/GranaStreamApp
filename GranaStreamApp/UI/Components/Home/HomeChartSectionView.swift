import SwiftUI
import Charts

struct HomeChartSectionView: View {
    let points: [DashboardChartPointResponseDto]
    let bucket: DashboardChartBucket
    let emptyText: String
    @State private var selectedIndex: Int?

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: DS.Spacing.item) {
                AppSectionHeader(text: L10n.Home.chartTitle)

                if points.isEmpty {
                    Text(emptyText)
                        .font(DS.Typography.caption)
                        .foregroundColor(DS.Colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, DS.Spacing.sm)
                } else {
                    Chart(points.indices, id: \.self) { index in
                        let point = points[index]

                        AreaMark(
                            x: .value("Período", index),
                            y: .value("Saldo", point.runningBalance)
                        )
                        .foregroundStyle(DS.Colors.primary.opacity(0.2))

                        LineMark(
                            x: .value("Período", index),
                            y: .value("Saldo", point.runningBalance)
                        )
                        .foregroundStyle(DS.Colors.primary)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        .interpolationMethod(.catmullRom)

                        if let selectedIndex, selectedIndex == index {
                            RuleMark(x: .value("Selecionado", selectedIndex))
                                .foregroundStyle(DS.Colors.textSecondary.opacity(0.35))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))

                            PointMark(
                                x: .value("Período", index),
                                y: .value("Saldo", point.runningBalance)
                            )
                            .foregroundStyle(DS.Colors.primary)
                            .symbolSize(64)
                        }
                    }
                    .frame(height: 190)
                    .chartXScale(domain: chartXDomain)
                    .chartXScale(range: .plotDimension(startPadding: 0, endPadding: 0))
                    .chartOverlay { proxy in
                        GeometryReader { geometry in
                            ZStack(alignment: .topLeading) {
                                Rectangle()
                                    .fill(.clear)
                                    .contentShape(Rectangle())
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { value in
                                                updateSelection(at: value.location, proxy: proxy, geometry: geometry)
                                            }
                                            .onEnded { _ in
                                                selectedIndex = nil
                                            }
                                    )

                                if let selectedIndex, points.indices.contains(selectedIndex) {
                                    tooltipView(for: points[selectedIndex], index: selectedIndex)
                                        .position(
                                            x: tooltipPositionX(for: selectedIndex, proxy: proxy, geometry: geometry),
                                            y: 12
                                        )
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(DS.Colors.border)
                            AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(DS.Colors.border)
                            AxisValueLabel {
                                if let index = value.as(Int.self), points.indices.contains(index) {
                                    if index % axisStep == 0 || index == points.count - 1 {
                                        Text(axisLabel(for: points[index], index: index))
                                            .font(.system(size: 10))
                                    }
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                }
            }
        }
    }

    private var axisStep: Int {
        switch bucket {
        case .week, .month, .year:
            return 1
        case .hour, .day:
            return max(1, points.count / 4)
        }
    }

    private var chartXDomain: ClosedRange<Int> {
        let upperBound = max(1, points.count - 1)
        return 0...upperBound
    }

    private func updateSelection(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        let plotFrame = geometry[proxy.plotAreaFrame]
        let xPosition = location.x - plotFrame.origin.x

        guard xPosition >= 0, xPosition <= proxy.plotAreaSize.width else {
            selectedIndex = nil
            return
        }

        if let value = proxy.value(atX: xPosition, as: Int.self) {
            let index = max(0, min(points.count - 1, value))
            selectedIndex = index
            return
        }

        selectedIndex = nil
    }

    private func tooltipView(for point: DashboardChartPointResponseDto, index: Int) -> some View {
        VStack(alignment: .center, spacing: 2) {
            Text(axisLabel(for: point, index: index))
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(DS.Colors.textSecondary)
            Text(CurrencyFormatter.string(from: point.runningBalance))
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(DS.Colors.textPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(DS.Colors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(DS.Colors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func tooltipPositionX(for index: Int, proxy: ChartProxy, geometry: GeometryProxy) -> CGFloat {
        let plotFrame = geometry[proxy.plotAreaFrame]
        let plotOriginX = plotFrame.origin.x
        let plotWidth = proxy.plotAreaSize.width
        let xInPlot = proxy.position(forX: index) ?? 0
        let rawX = plotOriginX + xInPlot

        // Keep tooltip inside the chart card bounds near edges.
        let tooltipHalfWidth: CGFloat = 62
        let minX = plotOriginX + tooltipHalfWidth
        let maxX = plotOriginX + plotWidth - tooltipHalfWidth

        return min(max(rawX, minX), maxX)
    }

    private func axisLabel(for point: DashboardChartPointResponseDto, index: Int) -> String {
        let rawLabel = (point.label ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        switch bucket {
        case .hour:
            if !rawLabel.isEmpty { return rawLabel }
            return "\(index)h"
        case .week:
            return weeklyLabel(from: rawLabel, index: index)
        case .month:
            return monthLabel(from: rawLabel, index: index)
        case .year:
            return yearLabel(from: rawLabel, index: index)
        case .day:
            if !rawLabel.isEmpty { return rawLabel }
            return "\(index + 1)"
        }
    }

    private func weeklyLabel(from rawLabel: String, index: Int) -> String {
        if let date = parseDate(rawLabel) {
            return dayMonthShortLabel(from: date)
        }
        if let matched = rawLabel.range(of: #"\b\d{2}/\d{2}\b"#, options: .regularExpression) {
            return normalizedDayMonth(String(rawLabel[matched]))
        }
        if rawLabel.contains("/") {
            let parts = rawLabel.split(separator: "/")
            if parts.count >= 2 {
                return normalizedDayMonth("\(parts[0])/\(parts[1])")
            }
        }
        if !rawLabel.isEmpty {
            return rawLabel
        }
        return "\(index + 1)-\(shortMonthNames[(index % shortMonthNames.count)])"
    }

    private func monthLabel(from rawLabel: String, index: Int) -> String {
        if let date = parseDate(rawLabel) {
            return dayMonthShortLabel(from: date)
        }
        if let monthNumber = Int(rawLabel), (1...12).contains(monthNumber) {
            return "01-\(shortMonthNames[monthNumber - 1])"
        }
        if !rawLabel.isEmpty {
            if let matched = rawLabel.range(of: #"\b\d{2}/\d{2}\b"#, options: .regularExpression) {
                return normalizedDayMonth(String(rawLabel[matched]))
            }
            let normalized = rawLabel.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            if let monthIndex = monthNamesNormalized.firstIndex(of: normalized) {
                return "01-\(shortMonthNames[monthIndex])"
            }
            return rawLabel
        }
        return "\(index + 1)-\(shortMonthNames[(index % shortMonthNames.count)])"
    }

    private func yearLabel(from rawLabel: String, index: Int) -> String {
        if let date = parseDate(rawLabel) {
            return monthYearShortLabel(from: date)
        }
        if let matched = rawLabel.range(of: #"\b\d{2}/\d{4}\b"#, options: .regularExpression) {
            return normalizedMonthYear(String(rawLabel[matched]))
        }
        if let matched = rawLabel.range(of: #"\b\d{4}-\d{2}\b"#, options: .regularExpression) {
            return normalizedMonthYear(String(rawLabel[matched]))
        }
        if !rawLabel.isEmpty {
            return rawLabel
        }
        let current = Date()
        let fallbackDate = calendar.date(byAdding: .month, value: index, to: current) ?? current
        return monthYearShortLabel(from: fallbackDate)
    }

    private func parseDate(_ value: String) -> Date? {
        guard !value.isEmpty else { return nil }
        if let date = isoDateTimeFormatter.date(from: value) {
            return date
        }
        if let date = isoDateTimeNoFractionFormatter.date(from: value) {
            return date
        }
        for formatter in fallbackFormatters {
            if let date = formatter.date(from: value) {
                return date
            }
        }
        return nil
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "pt_BR")
        return calendar
    }

    private var monthNames: [String] {
        [
            "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
            "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"
        ]
    }

    private var shortMonthNames: [String] {
        [
            "jan", "fev", "mar", "abr", "mai", "jun",
            "jul", "ago", "set", "out", "nov", "dez"
        ]
    }

    private var monthNamesNormalized: [String] {
        monthNames.map { $0.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current) }
    }

    private var isoDateTimeFormatter: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }

    private var isoDateTimeNoFractionFormatter: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }

    private var fallbackFormatters: [DateFormatter] {
        let formats = ["yyyy-MM-dd", "dd/MM/yyyy", "dd/MM"]
        return formats.map { format in
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "pt_BR")
            formatter.calendar = calendar
            formatter.dateFormat = format
            return formatter
        }
    }

    private var dayMonthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.calendar = calendar
        formatter.dateFormat = "dd/MM"
        return formatter
    }

    private func dayMonthShortLabel(from date: Date) -> String {
        let components = calendar.dateComponents([.day, .month], from: date)
        let day = max(1, components.day ?? 1)
        let month = max(1, min(12, components.month ?? 1))
        return String(format: "%02d-%@", day, shortMonthNames[month - 1])
    }

    private func normalizedDayMonth(_ rawValue: String) -> String {
        let parts = rawValue.split(separator: "/")
        guard parts.count >= 2 else { return rawValue }
        let day = Int(parts[0]) ?? 1
        let month = Int(parts[1]) ?? 1
        let safeMonth = max(1, min(12, month))
        return String(format: "%02d-%@", day, shortMonthNames[safeMonth - 1])
    }

    private var yearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.calendar = calendar
        formatter.dateFormat = "yyyy"
        return formatter
    }

    private func monthYearShortLabel(from date: Date) -> String {
        let components = calendar.dateComponents([.month, .year], from: date)
        let month = max(1, min(12, components.month ?? 1))
        let year = components.year ?? calendar.component(.year, from: date)
        return "\(shortMonthNames[month - 1])/\(year)"
    }

    private func normalizedMonthYear(_ rawValue: String) -> String {
        if rawValue.contains("-") {
            let parts = rawValue.split(separator: "-")
            if parts.count >= 2 {
                let year = Int(parts[0]) ?? calendar.component(.year, from: Date())
                let month = max(1, min(12, Int(parts[1]) ?? 1))
                return "\(shortMonthNames[month - 1])/\(year)"
            }
        } else if rawValue.contains("/") {
            let parts = rawValue.split(separator: "/")
            if parts.count >= 2 {
                let month = max(1, min(12, Int(parts[0]) ?? 1))
                let year = Int(parts[1]) ?? calendar.component(.year, from: Date())
                return "\(shortMonthNames[month - 1])/\(year)"
            }
        }
        return rawValue
    }
}

#Preview {
    HomeChartSectionView(
        points: [
            DashboardChartPointResponseDto(label: "01", runningBalance: 180),
            DashboardChartPointResponseDto(label: "02", runningBalance: 600),
            DashboardChartPointResponseDto(label: "03", runningBalance: 750),
            DashboardChartPointResponseDto(label: "04", runningBalance: 1130)
        ],
        bucket: .day,
        emptyText: L10n.Home.chartEmpty
    )
    .padding()
}
