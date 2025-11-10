//
//  DateExtension.swift
//  Libs
//
//  Created by Hari on 03/11/25.
//

import Foundation

public extension Date {
    
    
    enum Period {
        case after
        case before
    }
    
    func date(_ period: Period, offset: TimeUnit) -> Date {
        
        let timeInterval = offset.timeInterval
        
        return switch period {
        case .after: self.addingTimeInterval(timeInterval)
        case .before: self.addingTimeInterval(-timeInterval)
        }
    }
    
    enum TimeUnit {
        
        case seconds(Double)
        
        case minutes(Double)
        
        case hours(Double)
        
        case days(Double)
        
        case weeks(Double)
        
        var timeInterval: TimeInterval {
            switch self {
            case .seconds(let value):
                
                return value
            case .minutes(let value):
                
                return value * 60
            case .hours(let value):
                
                return value * 3600
            case .days(let value):
                
                return value * 86400
            case .weeks(let value):
                
                return value * 604800
            }
        }
    }
    
    enum LogicalOperator {
        case greaterThan
        case lessThan
        case equalTo
    }
    
    /// Check if the time interval since now satisfies the logical condition
    /// - Parameters:
    ///   - logicalOperator: The comparison operator (greaterThan, lessThan, equalTo)
    ///   - timeUnit: The time unit to compare against
    ///   - tolerance: Tolerance for equalTo comparison (default: 1 second)
    /// - Returns: Boolean result of the comparison
    func isTimeConditionMet(_ logicalOperator: LogicalOperator, timeUnit: TimeUnit, tolerance: TimeInterval = 1.0) -> Bool {
        
        let actualInterval = abs(self.timeIntervalSinceNow)
        let targetInterval = timeUnit.timeInterval
        
        switch logicalOperator {
        case .greaterThan:
            return actualInterval > targetInterval
            
        case .lessThan:
            return actualInterval < targetInterval
            
        case .equalTo:
            return abs(actualInterval - targetInterval) <= tolerance
        }
    }
    
    func timeInMillisAsInt64(
        timeIntervalFrom: TimeIntervalFrom = .timeIntervalSince1970
    ) -> Int64 {
        
        return Int64(self.timeIntervalSince1970 * 1000)
    }
    
    func timeInMillisAsDouble(
        timeIntervalFrom: TimeIntervalFrom = .timeIntervalSince1970
    ) -> Double {
        
        return self.timeIntervalSince1970 * 1000
    }
    
    enum TimeIntervalFrom {
        
        case timeIntervalSince1970
        case timeIntervalSinceNow
        case timeIntervalSinceReferenceDate
        case timeIntervalSinceDate(Date)
    }
    
    enum DateFormat {
        
        case ddMMYYYY(seperator: Character = "/")
        case yyyyMMdd(seperator: Character = "/")
        case ddMMyyyy(seperator: Character = "/")
        case MMddyyyy(seperator: Character = "/")
        case YYYYMMdd(seperator: Character = "/")
        case MMddYYYY(seperator: Character = "/")

        case ddMMYYYYHHmm(dateSeperator: Character = "/", dateTimeSeperator: Character = " ", timeSeperator: Character = ":")
        case yyyyMMddHHmm(dateSeperator: Character = "/", dateTimeSeperator: Character = " ", timeSeperator: Character = ":")
        case ddMMyyyyHHmm(dateSeperator: Character = "/", dateTimeSeperator: Character = " ", timeSeperator: Character = ":")
        case MMddyyyyHHmm(dateSeperator: Character = "/", dateTimeSeperator: Character = " ", timeSeperator: Character = ":")
        case YYYYMMddHHmm(dateSeperator: Character = "/", dateTimeSeperator: Character = " ", timeSeperator: Character = ":")
        case MMddYYYYHHmm(dateSeperator: Character = "/", dateTimeSeperator: Character = " ", timeSeperator: Character = ":")

        // Time-only (24-hour)
        case HHmm_24hr(seperator: Character = ":")
        case HHmmss_24hr(seperator: Character = ":")

        // Time-only (12-hour) with AM/PM
        case hhmmAMPM_12hr(seperator: Character = ":")
        case hhmmssAMPM_12hr(seperator: Character = ":")
        
        case custom(String)

        var format: String {
            switch self {
            case .ddMMYYYY(let sep):         return "dd\(sep)MM\(sep)YYYY"
            case .yyyyMMdd(let sep):         return "yyyy\(sep)MM\(sep)dd"
            case .ddMMyyyy(let sep):         return "dd\(sep)MM\(sep)yyyy"
            case .MMddyyyy(let sep):         return "MM\(sep)dd\(sep)yyyy"
            case .YYYYMMdd(let sep):         return "YYYY\(sep)MM\(sep)dd"
            case .MMddYYYY(let sep):         return "MM\(sep)dd\(sep)YYYY"

            case .ddMMYYYYHHmm(let d, let dt, let t):
                return "dd\(d)MM\(d)YYYY\(dt)HH\(t)mm"
            case .yyyyMMddHHmm(let d, let dt, let t):
                return "yyyy\(d)MM\(d)dd\(dt)HH\(t)mm"
            case .ddMMyyyyHHmm(let d, let dt, let t):
                return "dd\(d)MM\(d)yyyy\(dt)HH\(t)mm"
            case .MMddyyyyHHmm(let d, let dt, let t):
                return "MM\(d)dd\(d)yyyy\(dt)HH\(t)mm"
            case .YYYYMMddHHmm(let d, let dt, let t):
                return "YYYY\(d)MM\(d)dd\(dt)HH\(t)mm"
            case .MMddYYYYHHmm(let d, let dt, let t):
                return "MM\(d)dd\(d)YYYY\(dt)HH\(t)mm"

            // Time-only (24-hour)
            case .HHmm_24hr(let sep):             return "HH\(sep)mm"
            case .HHmmss_24hr(let sep):           return "HH\(sep)mm\(sep)ss"

            // 12-hour formats with AM/PM
            case .hhmmAMPM_12hr(let sep):         return "hh\(sep)mm a"
            case .hhmmssAMPM_12hr(let sep):       return "hh\(sep)mm\(sep)ss a"
                
            case let .custom(format): return format
            }
        }
    }
    
    func stringDate(format: DateFormat, timeZone: TimeZone = .current) -> String {
        
        let formatter = DateFormatter()
        formatter.dateFormat = format.format
        formatter.timeZone = timeZone
        
        return formatter.string(from: self)
    }
}
