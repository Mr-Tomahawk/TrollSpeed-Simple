//
//  TSSettingsIndex.swift
//  SimpleTS
//

import Foundation

enum TSSettingsIndex: Int, CaseIterable {
    case placeholder = 0

    var key: String {
        switch self {
        case .placeholder:
            return "placeholder_setting"
        }
    }

    var title: String {
        switch self {
        case .placeholder:
            return "Placeholder"
        }
    }

    func subtitle(highlighted: Bool, restartRequired: Bool) -> String {
        switch self {
        case .placeholder:
            return highlighted ? "ON" : "OFF"
        }
    }
}