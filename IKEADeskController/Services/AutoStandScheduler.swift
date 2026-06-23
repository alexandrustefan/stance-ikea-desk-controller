import Foundation

enum AutoStandScheduler {
    static func isActiveWeekday(
        _ date: Date,
        config: AutoStandConfig,
        calendar: Calendar = .current
    ) -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        return config.activeWeekdays.contains(weekday)
    }

    static func isWithinActiveHours(
        _ date: Date,
        config: AutoStandConfig,
        calendar: Calendar = .current
    ) -> Bool {
        isTimeWithinRange(
            date,
            start: config.activeHourStart,
            end: config.activeHourEnd,
            calendar: calendar
        )
    }

    static func isWithinQuietHours(
        _ date: Date,
        config: AutoStandConfig,
        calendar: Calendar = .current
    ) -> Bool {
        isTimeWithinRange(
            date,
            start: config.quietHoursStart,
            end: config.quietHoursEnd,
            calendar: calendar
        )
    }

    static func matchingScheduleEntry(
        _ date: Date,
        config: AutoStandConfig,
        calendar: Calendar = .current
    ) -> ScheduleEntry? {
        guard config.scheduleMode == .custom else { return nil }
        return config.customSchedule.first { entry in
            isTimeWithinRange(
                date,
                start: entry.startTime,
                end: entry.endTime,
                calendar: calendar
            )
        }
    }

    static func shouldRunAutoStand(
        _ date: Date,
        config: AutoStandConfig,
        calendar: Calendar = .current
    ) -> Bool {
        guard config.enabled else { return false }
        guard isActiveWeekday(date, config: config, calendar: calendar) else { return false }
        guard isWithinActiveHours(date, config: config, calendar: calendar) else { return false }
        guard !isWithinQuietHours(date, config: config, calendar: calendar) else { return false }
        return true
    }

    private static func isTimeWithinRange(
        _ date: Date,
        start: DateComponents,
        end: DateComponents,
        calendar: Calendar
    ) -> Bool {
        guard let startMinutes = minutesSinceMidnight(start, calendar: calendar),
              let endMinutes = minutesSinceMidnight(end, calendar: calendar) else {
            return false
        }

        let currentMinutes = minutesSinceMidnight(for: date, calendar: calendar)

        if startMinutes <= endMinutes {
            return currentMinutes >= startMinutes && currentMinutes < endMinutes
        }

        return currentMinutes >= startMinutes || currentMinutes < endMinutes
    }

    private static func minutesSinceMidnight(
        _ components: DateComponents,
        calendar: Calendar
    ) -> Int? {
        guard let hour = components.hour, let minute = components.minute else { return nil }
        return hour * 60 + minute
    }

    private static func minutesSinceMidnight(for date: Date, calendar: Calendar) -> Int {
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        return hour * 60 + minute
    }
}
