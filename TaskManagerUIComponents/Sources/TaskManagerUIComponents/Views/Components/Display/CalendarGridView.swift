import SwiftUI

// MARK: - Calendar Date Info
public struct CalendarDateInfo: Sendable {
    public let hasCreatedTask: Bool
    public let hasDeadline: Bool
    
    public init(hasCreatedTask: Bool, hasDeadline: Bool) {
        self.hasCreatedTask = hasCreatedTask
        self.hasDeadline = hasDeadline
    }
}

// MARK: - Calendar Grid View
public struct CalendarGridView: View {
    @Binding var selectedDate: Date?
    let dateInfo: [Date: CalendarDateInfo]
    
    @State private var displayedMonth: Date = Date()
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
    
    public init(selectedDate: Binding<Date?>, dateInfo: [Date: CalendarDateInfo] = [:]) {
        self._selectedDate = selectedDate
        self.dateInfo = dateInfo
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            // Month navigation header
            HStack {
                Text(monthYearString)
                    .font(.system(size: 13, weight: .semibold))
                
                Spacer()
                
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                
                Button(action: { displayedMonth = Date() }) {
                    Circle()
                        .fill(.secondary)
                        .frame(width: 6, height: 6)
                }
                .buttonStyle(.plain)
                .help("Today")
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
            
            // Day of week headers
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Day cells
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 2) {
                ForEach(daysInMonth, id: \.self) { date in
                    if let date = date {
                        DayCellView(
                            date: date,
                            isSelected: isSelected(date),
                            isToday: calendar.isDateInToday(date),
                            isCurrentMonth: isCurrentMonth(date),
                            info: infoFor(date)
                        )
                        .onTapGesture {
                            if isSelected(date) {
                                selectedDate = nil
                            } else {
                                selectedDate = date
                            }
                        }
                    } else {
                        Color.clear
                            .frame(height: 28)
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }
    
    private func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: displayedMonth) {
            displayedMonth = newDate
        }
    }
    
    private func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: displayedMonth) {
            displayedMonth = newDate
        }
    }
    
    private func isSelected(_ date: Date) -> Bool {
        guard let selected = selectedDate else { return false }
        return calendar.isDate(date, inSameDayAs: selected)
    }
    
    private func isCurrentMonth(_ date: Date) -> Bool {
        calendar.component(.month, from: date) == calendar.component(.month, from: displayedMonth)
    }
    
    private func infoFor(_ date: Date) -> CalendarDateInfo? {
        // Match by day - strip time components
        let startOfDay = calendar.startOfDay(for: date)
        return dateInfo[startOfDay]
    }
    
    private var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth) else { return [] }
        
        let firstDay = monthInterval.start
        // weekday: 1=Sun, 2=Mon, ... 7=Sat. We want Monday-first, so shift.
        let weekday = calendar.component(.weekday, from: firstDay)
        // Convert to Monday=0 index
        let mondayIndex = (weekday + 5) % 7
        
        var days: [Date?] = []
        
        // Leading empty cells (days from previous month)
        // Actually, let's show previous month days as dimmed
        if mondayIndex > 0 {
            for i in stride(from: mondayIndex, through: 1, by: -1) {
                if let prevDate = calendar.date(byAdding: .day, value: -i, to: firstDay) {
                    days.append(prevDate)
                }
            }
        }
        
        // Days of current month
        let daysInMonth = calendar.range(of: .day, in: .month, for: displayedMonth)!
        for day in daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        
        // Trailing days to fill the last week
        let remainder = days.count % 7
        if remainder > 0 {
            let lastDay = monthInterval.end
            for i in 0..<(7 - remainder) {
                if let nextDate = calendar.date(byAdding: .day, value: i, to: lastDay) {
                    days.append(nextDate)
                }
            }
        }
        
        return days
    }
}

// MARK: - Day Cell
private struct DayCellView: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isCurrentMonth: Bool
    let info: CalendarDateInfo?
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 1) {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 11, weight: isToday ? .bold : .regular))
                .foregroundStyle(foregroundColor)
                .frame(width: 24, height: 20)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isSelected ? Color.accentColor : Color.clear)
                )
            
            // Dot indicators
            HStack(spacing: 2) {
                if let info {
                    if info.hasCreatedTask {
                        Circle()
                            .fill(.green)
                            .frame(width: 4, height: 4)
                    }
                    if info.hasDeadline {
                        Circle()
                            .fill(.red)
                            .frame(width: 4, height: 4)
                    }
                }
            }
            .frame(height: 4)
        }
        .frame(height: 28)
        .contentShape(Rectangle())
    }
    
    private var foregroundColor: Color {
        if isSelected {
            return .white
        }
        if !isCurrentMonth {
            return .secondary.opacity(0.4)
        }
        if isToday {
            return .accentColor
        }
        return .primary
    }
}
