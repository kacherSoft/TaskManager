import Foundation

// MARK: - Custom Field Types

public enum CustomFieldValueType: String, CaseIterable, Identifiable, Sendable, Codable {
    case text
    case number
    case currency
    case date
    case toggle

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .text: return "Text"
        case .number: return "Number"
        case .currency: return "Currency"
        case .date: return "Date"
        case .toggle: return "Toggle"
        }
    }
}

// MARK: - Custom Field Definition

public struct CustomFieldDefinition: Identifiable, Sendable, Codable {
    public let id: UUID
    public let name: String
    public let valueType: CustomFieldValueType
    public let isActive: Bool
    public let sortOrder: Int

    public init(
        id: UUID = UUID(),
        name: String,
        valueType: CustomFieldValueType,
        isActive: Bool = true,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.valueType = valueType
        self.isActive = isActive
        self.sortOrder = sortOrder
    }
}

// MARK: - Custom Field Entry

public struct CustomFieldEntry: Identifiable, Sendable {
    public let definitionId: UUID
    public let name: String
    public let valueType: CustomFieldValueType
    public let stringValue: String?
    public let numberValue: Double?
    public let decimalValue: Decimal?
    public let dateValue: Date?
    public let boolValue: Bool?

    public var id: UUID { definitionId }

    public var displayValue: String {
        switch valueType {
        case .text:
            return stringValue ?? ""
        case .number:
            if let number = numberValue {
                return number.truncatingRemainder(dividingBy: 1) == 0
                    ? String(format: "%.0f", number)
                    : String(number)
            }
            return ""
        case .currency:
            if let decimal = decimalValue {
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                return formatter.string(from: decimal as NSDecimalNumber) ?? ""
            }
            return ""
        case .date:
            if let date = dateValue {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return formatter.string(from: date)
            }
            return ""
        case .toggle:
            if let value = boolValue {
                return value ? "Yes" : "No"
            }
            return ""
        }
    }

    public init(
        definitionId: UUID,
        name: String,
        valueType: CustomFieldValueType,
        stringValue: String? = nil,
        numberValue: Double? = nil,
        decimalValue: Decimal? = nil,
        dateValue: Date? = nil,
        boolValue: Bool? = nil
    ) {
        self.definitionId = definitionId
        self.name = name
        self.valueType = valueType
        self.stringValue = stringValue
        self.numberValue = numberValue
        self.decimalValue = decimalValue
        self.dateValue = dateValue
        self.boolValue = boolValue
    }
}

// MARK: - Custom Field Edit Value (used for form bindings)
public enum CustomFieldEditValue: Sendable {
    case text(String)
    case number(Double?)
    case currency(Decimal?)
    case date(Date?)
    case toggle(Bool)

    public static func empty(for type: CustomFieldValueType) -> CustomFieldEditValue {
        switch type {
        case .text: return .text("")
        case .number: return .number(nil)
        case .currency: return .currency(nil)
        case .date: return .date(nil)
        case .toggle: return .toggle(false)
        }
    }

    public static func from(entry: CustomFieldEntry) -> CustomFieldEditValue {
        switch entry.valueType {
        case .text: return .text(entry.stringValue ?? "")
        case .number: return .number(entry.numberValue)
        case .currency: return .currency(entry.decimalValue)
        case .date: return .date(entry.dateValue)
        case .toggle: return .toggle(entry.boolValue ?? false)
        }
    }
}

// MARK: - Custom Field Entry Extensions
extension CustomFieldEntry {
    public func toEditValue() -> CustomFieldEditValue {
        CustomFieldEditValue.from(entry: self)
    }
}
