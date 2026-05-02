//
//  AppColors.swift
//  course work
//
//  Created by Apple on 14.12.2025.
//

import SwiftUI

/// Цветовая схема приложения - стиль boxing-app2
extension Color {
    // Основные цвета
    static let appPrimary = Color.yellow
    static let appSecondary = Color.orange
    static let appAccent = Color.blue
    
    // Фоны
    static let appBackground = Color.black
    static let cardBackground = Color(.systemGray6).opacity(0.2)
    static let cardBackgroundLight = Color(.systemGray6).opacity(0.3)
    
    // Градиенты
    static let gradientPrimary = LinearGradient(
        colors: [Color.yellow, Color.orange],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let gradientSecondary = LinearGradient(
        colors: [Color.blue.opacity(0.7), Color.blue],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let gradientHeart = LinearGradient(
        colors: [Color.red.opacity(0.8), Color.pink.opacity(0.6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let gradientSuccess = LinearGradient(
        colors: [Color.green.opacity(0.8), Color.green.opacity(0.6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let gradientWarning = LinearGradient(
        colors: [Color.yellow.opacity(0.8), Color.orange.opacity(0.6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

/// Стиль карточек в стиле boxing-app2
struct BoxingCardStyle: ViewModifier {
    var cornerRadius: CGFloat = 15
    var padding: CGFloat = 15
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.cardBackground)
            )
    }
}

extension View {
    func boxingCard(cornerRadius: CGFloat = 15, padding: CGFloat = 15) -> some View {
        modifier(BoxingCardStyle(cornerRadius: cornerRadius, padding: padding))
    }
}

/// Фоновый стиль
struct BoxingBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.appBackground.ignoresSafeArea())
    }
}

extension View {
    func boxingBackground() -> some View {
        modifier(BoxingBackground())
    }
}
