//
//  AppTypography.swift
//  course work
//
//  Created by Apple on 14.12.2025.
//

import SwiftUI

/// Типографика приложения
extension Font {
    static func appTitle() -> Font {
        .system(size: 32, weight: .bold, design: .rounded)
    }
    
    static func appHeadline() -> Font {
        .system(size: 20, weight: .semibold, design: .rounded)
    }
    
    static func appBody() -> Font {
        .system(size: 16, weight: .regular, design: .rounded)
    }
    
    static func appCaption() -> Font {
        .system(size: 14, weight: .medium, design: .rounded)
    }
    
    static func appLargeNumber() -> Font {
        .system(size: 48, weight: .bold, design: .rounded)
    }
    
    static func appGiantNumber() -> Font {
        .system(size: 72, weight: .bold, design: .rounded)
    }
}

