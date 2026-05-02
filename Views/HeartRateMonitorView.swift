//
//  HeartRateMonitorView.swift
//  course work
//
//  Created by Apple on 14.12.2025.
//

import SwiftUI
import Charts

/// Экран мониторинга ЧСС и целевых зон
struct HeartRateMonitorView: View {
    @StateObject private var healthKitManager = HealthKitManager.shared
    @State private var targetZones: [HeartRateZone] = [
        HeartRateZone(min: 120, max: 160, name: "Аэробная", color: .aerobic),
        HeartRateZone(min: 160, max: 180, name: "Анаэробная", color: .anaerobic)
    ]
    @State private var showSettings = false
    @State private var heartRateHistory: [HeartRateData] = []
    
    // Демонстрационные данные для наглядности
    @State private var demoCurrentHeartRate: Double = 145.0
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Подготавливаем данные для отображения
                        let displayHeartRate = healthKitManager.currentHeartRate ?? demoCurrentHeartRate
                        let displayHistory = heartRateHistory.isEmpty ? generateDemoHistory() : heartRateHistory
                        
                        // Текущий ЧСС (используем демо-данные если нет реальных)
                        CurrentHeartRateCard(heartRate: displayHeartRate)
                        
                        // Статистика ЧСС
                        HeartRateStatsCard(heartRateHistory: displayHistory, currentHR: displayHeartRate)
                        
                        // Кардио-зоны с визуализацией
                        CardioZonesCard(currentHeartRate: displayHeartRate)
                        
                        // Целевые зоны
                        TargetZonesCard(zones: targetZones, currentHeartRate: displayHeartRate)
                        
                        // Анализ времени в зонах
                        TimeInZonesCard(heartRateHistory: displayHistory)
                        
                        // Оценка VO2max
                        VO2MaxEstimateCard(heartRateHistory: displayHistory)
                        
                        // График ЧСС
                        HeartRateChart(heartRateData: displayHistory)
                        
                        // Рекомендации
                        HeartRateRecommendationsCard(currentHR: displayHeartRate, history: displayHistory)
                        
                        // История
                        HeartRateHistoryView(history: displayHistory)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Мониторинг ЧСС")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.appPrimary)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                HeartRateSettingsView(zones: $targetZones)
            }
            .onAppear {
                loadHeartRateHistory()
                // Инициализируем демо-данные
                initializeDemoData()
            }
            .onChange(of: healthKitManager.currentHeartRate) { newValue in
                if let hr = newValue {
                    checkZoneAlerts(heartRate: hr)
                } else {
                    // Обновляем демо-ЧСС для наглядности
                    updateDemoHeartRate()
                }
            }
        }
    }
    
    /// Инициализация демонстрационных данных
    private func initializeDemoData() {
        demoCurrentHeartRate = Double.random(in: 120...170)
        
        // Обновляем демо-ЧСС каждые 3 секунды для наглядности
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            updateDemoHeartRate()
        }
    }
    
    /// Обновление демонстрационного ЧСС
    private func updateDemoHeartRate() {
        // Плавно меняем ЧСС в диапазоне 120-180 для демонстрации
        let change = Double.random(in: -5...5)
        demoCurrentHeartRate = max(100, min(190, demoCurrentHeartRate + change))
    }
    
    /// Генерация демонстрационной истории ЧСС за последние 24 часа
    private func generateDemoHistory() -> [HeartRateData] {
        var history: [HeartRateData] = []
        let calendar = Calendar.current
        let now = Date()
        
        // Генерируем данные каждые 30 минут за последние 24 часа
        var currentHR = 75.0 // Начальный ЧСС в покое
        
        for hour in stride(from: 24, through: 0, by: -0.5) {
            guard let timestamp = calendar.date(byAdding: .minute, value: -Int(hour * 60), to: now) else { continue }
            
            // Имитируем суточные колебания ЧСС
            let hourOfDay = calendar.component(.hour, from: timestamp)
            
            // Ночью ЧСС низкий (60-75)
            if hourOfDay >= 22 || hourOfDay < 6 {
                currentHR = Double.random(in: 60...75)
            }
            // Утром ЧСС растет (70-85)
            else if hourOfDay >= 6 && hourOfDay < 10 {
                currentHR = Double.random(in: 70...85)
            }
            // Днем возможны тренировки (80-180)
            else if hourOfDay >= 10 && hourOfDay < 20 {
                // Иногда добавляем пики тренировок
                if Int.random(in: 0...100) < 15 { // 15% шанс на тренировку
                    currentHR = Double.random(in: 140...180)
                } else {
                    currentHR = Double.random(in: 75...95)
                }
            }
            // Вечером ЧСС снижается (70-90)
            else {
                currentHR = Double.random(in: 70...90)
            }
            
            history.append(HeartRateData(
                value: currentHR,
                timestamp: timestamp,
                workoutSessionId: nil
            ))
        }
        
        return history
    }
    
    private func loadHeartRateHistory() {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .hour, value: -24, to: endDate) ?? endDate
        
        healthKitManager.fetchHeartRateHistory(startDate: startDate, endDate: endDate) { data in
            heartRateHistory = data
        }
    }
    
    private func checkZoneAlerts(heartRate: Double) {
        // Проверяем, находится ли ЧСС в целевых зонах
        let inZone = targetZones.contains { $0.contains(heartRate) }
        
        if !inZone {
            // Можно добавить уведомление
            print("ЧСС вне целевой зоны: \(Int(heartRate))")
        }
    }
}

/// Карточка текущего ЧСС
struct CurrentHeartRateCard: View {
    let heartRate: Double?
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Text("Текущий пульс")
                    .font(.appHeadline())
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Image(systemName: "heart.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.gradientHeart)
            }
            
            if let hr = heartRate {
                VStack(spacing: 8) {
                    Text("\(Int(hr))")
                        .font(.appGiantNumber())
                        .foregroundStyle(Color.gradientHeart)
                    
                    Text("уд/мин")
                        .font(.appHeadline())
                        .foregroundColor(.white.opacity(0.6))
                }
            } else {
                VStack(spacing: 8) {
                    Text("--")
                        .font(.appGiantNumber())
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("Ожидание данных")
                        .font(.appBody())
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .boxingCard()
    }
}

/// Карточка целевых зон
struct TargetZonesCard: View {
    let zones: [HeartRateZone]
    let currentHeartRate: Double?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Целевые зоны")
                .font(.appHeadline())
                .foregroundColor(.white.opacity(0.8))
            
            VStack(spacing: 12) {
                ForEach(zones, id: \.name) { zone in
                    ZoneRow(zone: zone, currentHeartRate: currentHeartRate)
                }
            }
        }
        .boxingCard()
    }
}

struct ZoneRow: View {
    let zone: HeartRateZone
    let currentHeartRate: Double?
    
    var isInZone: Bool {
        guard let hr = currentHeartRate else { return false }
        return zone.contains(hr)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(isInZone ? Color.green.opacity(0.3) : Color.white.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Circle()
                    .fill(isInZone ? Color.green : Color.white.opacity(0.3))
                    .frame(width: 12, height: 12)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(zone.name)
                    .font(.appBody())
                    .foregroundColor(.white)
                
                Text("\(Int(zone.min))-\(Int(zone.max)) уд/мин")
                    .font(.appCaption())
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            if isInZone {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 24))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isInZone ? Color.green.opacity(0.1) : Color.cardBackgroundLight.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isInZone ? Color.green.opacity(0.5) : Color.clear, lineWidth: 2)
                )
        )
    }
}

/// График ЧСС
struct HeartRateChart: View {
    let heartRateData: [HeartRateData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("График ЧСС (24 часа)")
                .font(.appHeadline())
                .foregroundColor(.white.opacity(0.8))
            
            Chart {
                ForEach(heartRateData.prefix(100)) { data in
                    LineMark(
                        x: .value("Время", data.timestamp, unit: .hour),
                        y: .value("ЧСС", data.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.red.opacity(0.8), Color.pink.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                }
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
                        .foregroundStyle(.white.opacity(0.2))
                    AxisValueLabel()
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
                        .foregroundStyle(.white.opacity(0.2))
                    AxisValueLabel()
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
        .boxingCard()
    }
}

/// История ЧСС
struct HeartRateHistoryView: View {
    let history: [HeartRateData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("История")
                .font(.appHeadline())
                .foregroundColor(.white.opacity(0.8))
            
            if history.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "heart.slash")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.3))
                    Text("Нет данных")
                        .font(.appBody())
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 12) {
                    ForEach(history.suffix(10).reversed(), id: \.id) { data in
                        HStack(spacing: 16) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.red.opacity(0.6))
                            
                            Text(formatTime(data.timestamp))
                                .font(.appBody())
                                .foregroundColor(.white.opacity(0.8))
                            
                            Spacer()
                            
                            Text("\(Int(data.value))")
                                .font(.appHeadline())
                                .foregroundColor(.white)
                            
                            Text("уд/мин")
                                .font(.appCaption())
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.cardBackgroundLight.opacity(0.5))
                        )
                    }
                }
            }
        }
        .boxingCard()
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

/// Настройки целевых зон
struct HeartRateSettingsView: View {
    @Binding var zones: [HeartRateZone]
    @Environment(\.dismiss) var dismiss
    
    @State private var editingZone: HeartRateZone?
    @State private var newZoneMin: String = ""
    @State private var newZoneMax: String = ""
    @State private var newZoneName: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Целевые зоны ЧСС") {
                    ForEach(zones, id: \.name) { zone in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(zone.name)
                                    .font(.headline)
                                Text("\(Int(zone.min))-\(Int(zone.max)) уд/мин")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Изменить") {
                                editingZone = zone
                                newZoneMin = "\(Int(zone.min))"
                                newZoneMax = "\(Int(zone.max))"
                                newZoneName = zone.name
                            }
                        }
                    }
                    .onDelete { indexSet in
                        zones.remove(atOffsets: indexSet)
                    }
                }
                
                Section("Добавить зону") {
                    TextField("Название", text: $newZoneName)
                    TextField("Мин. ЧСС", text: $newZoneMin)
                        .keyboardType(.numberPad)
                    TextField("Макс. ЧСС", text: $newZoneMax)
                        .keyboardType(.numberPad)
                    
                    Button("Добавить") {
                        if let min = Double(newZoneMin),
                           let max = Double(newZoneMax),
                           !newZoneName.isEmpty {
                            let zone = HeartRateZone(
                                min: min,
                                max: max,
                                name: newZoneName,
                                color: .aerobic
                            )
                            zones.append(zone)
                            newZoneName = ""
                            newZoneMin = ""
                            newZoneMax = ""
                        }
                    }
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// Карточка статистики ЧСС
struct HeartRateStatsCard: View {
    let heartRateHistory: [HeartRateData]
    let currentHR: Double
    
    var avgHeartRate: Double {
        guard !heartRateHistory.isEmpty else { return currentHR }
        return heartRateHistory.map { $0.value }.reduce(0, +) / Double(heartRateHistory.count)
    }
    
    var maxHeartRate: Double {
        guard !heartRateHistory.isEmpty else { return currentHR }
        return heartRateHistory.map { $0.value }.max() ?? currentHR
    }
    
    var minHeartRate: Double {
        guard !heartRateHistory.isEmpty else { return currentHR }
        return heartRateHistory.map { $0.value }.min() ?? currentHR
    }
    
    var restingHeartRate: Double {
        // Пульс в покое - минимальное значение за последние 24 часа
        return minHeartRate
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Статистика")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                HRStatBox(
                    title: "Средний",
                    value: "\(Int(avgHeartRate))",
                    icon: "heart.circle.fill",
                    color: .blue
                )
                
                HRStatBox(
                    title: "Максимальный",
                    value: "\(Int(maxHeartRate))",
                    icon: "arrow.up.circle.fill",
                    color: .red
                )
                
                HRStatBox(
                    title: "Минимальный",
                    value: "\(Int(minHeartRate))",
                    icon: "arrow.down.circle.fill",
                    color: .green
                )
                
                HRStatBox(
                    title: "В покое",
                    value: "\(Int(restingHeartRate))",
                    icon: "bed.double.fill",
                    color: .purple
                )
            }
        }
        .padding()
        .boxingCard()
    }
}

struct HRStatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.cardBackgroundLight)
        .cornerRadius(12)
    }
}

/// Карточка кардио-зон с визуализацией
struct CardioZonesCard: View {
    let currentHeartRate: Double
    
    // Стандартные кардио-зоны (от 50% до 100% от максимального ЧСС)
    var cardioZones: [(name: String, min: Double, max: Double, color: Color, description: String)] {
        let maxHR = 200.0 // Предполагаемый максимальный ЧСС
        return [
            ("Восстановление", maxHR * 0.5, maxHR * 0.6, .blue, "50-60%"),
            ("Жиросжигание", maxHR * 0.6, maxHR * 0.7, .green, "60-70%"),
            ("Аэробная", maxHR * 0.7, maxHR * 0.8, .yellow, "70-80%"),
            ("Анаэробная", maxHR * 0.8, maxHR * 0.9, .orange, "80-90%"),
            ("Максимальная", maxHR * 0.9, maxHR, .red, "90-100%")
        ]
    }
    
    var currentZone: (name: String, min: Double, max: Double, color: Color, description: String)? {
        cardioZones.first { currentHeartRate >= $0.min && currentHeartRate <= $0.max }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Кардио-зоны")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            // Визуализация зон
            VStack(spacing: 8) {
                ForEach(cardioZones.indices, id: \.self) { index in
                    let zone = cardioZones[index]
                    let isActive = currentZone?.name == zone.name
                    
                    HStack(spacing: 12) {
                        // Индикатор зоны
                        RoundedRectangle(cornerRadius: 4)
                            .fill(zone.color)
                            .frame(width: 6, height: 40)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(zone.name)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                if isActive {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(zone.color)
                                }
                            }
                            
                            Text("\(Int(zone.min))-\(Int(zone.max)) уд/мин (\(zone.description))")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isActive ? zone.color.opacity(0.2) : Color.cardBackgroundLight.opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isActive ? zone.color.opacity(0.5) : Color.clear, lineWidth: 2)
                            )
                    )
                }
            }
        }
        .padding()
        .boxingCard()
    }
}

/// Карточка анализа времени в зонах
struct TimeInZonesCard: View {
    let heartRateHistory: [HeartRateData]
    
    var timeInZones: [(zone: String, time: Double, percentage: Double)] {
        let maxHR = 200.0
        var zones: [String: Double] = [
            "Восстановление": 0,
            "Жиросжигание": 0,
            "Аэробная": 0,
            "Анаэробная": 0,
            "Максимальная": 0
        ]
        
        // Считаем время в каждой зоне (каждая точка данных = 5 секунд)
        for data in heartRateHistory {
            let hr = data.value
            if hr >= maxHR * 0.9 {
                zones["Максимальная"]! += 5
            } else if hr >= maxHR * 0.8 {
                zones["Анаэробная"]! += 5
            } else if hr >= maxHR * 0.7 {
                zones["Аэробная"]! += 5
            } else if hr >= maxHR * 0.6 {
                zones["Жиросжигание"]! += 5
            } else {
                zones["Восстановление"]! += 5
            }
        }
        
        let total = zones.values.reduce(0, +)
        
        return zones.map { (zone: $0.key, time: $0.value, percentage: total > 0 ? ($0.value / total) * 100 : 0) }
            .sorted { $0.percentage > $1.percentage }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Время в зонах")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(timeInZones, id: \.zone) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(item.zone)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Spacer()
                            
                            Text(String(format: "%.0f%%", item.percentage))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 8)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(getZoneColor(item.zone))
                                    .frame(width: geometry.size.width * CGFloat(item.percentage / 100), height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                }
            }
        }
        .padding()
        .boxingCard()
    }
    
    private func getZoneColor(_ zone: String) -> Color {
        switch zone {
        case "Восстановление": return .blue
        case "Жиросжигание": return .green
        case "Аэробная": return .yellow
        case "Анаэробная": return .orange
        case "Максимальная": return .red
        default: return .gray
        }
    }
}

/// Карточка оценки VO2max
struct VO2MaxEstimateCard: View {
    let heartRateHistory: [HeartRateData]
    
    var vo2MaxEstimate: Double {
        guard !heartRateHistory.isEmpty else { return 45.0 }
        
        // Упрощенная оценка VO2max на основе максимального ЧСС и пульса в покое
        let maxHR = heartRateHistory.map { $0.value }.max() ?? 200
        let restingHR = heartRateHistory.map { $0.value }.min() ?? 60
        
        // Формула: VO2max ≈ 15.3 × (макс ЧСС / пульс в покое)
        let estimate = 15.3 * (maxHR / restingHR)
        return min(70, max(30, estimate)) // Ограничиваем разумными значениями
    }
    
    var fitnessLevel: String {
        let vo2 = vo2MaxEstimate
        if vo2 >= 55 { return "Отличный" }
        if vo2 >= 45 { return "Хороший" }
        if vo2 >= 35 { return "Средний" }
        return "Низкий"
    }
    
    var fitnessColor: Color {
        let vo2 = vo2MaxEstimate
        if vo2 >= 55 { return .green }
        if vo2 >= 45 { return .yellow }
        if vo2 >= 35 { return .orange }
        return .red
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Оценка VO₂max")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "lungs.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.cyan)
            }
            
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(String(format: "%.1f", vo2MaxEstimate))")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.cyan)
                    
                    Text("мл/кг/мин")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text(fitnessLevel)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(fitnessColor)
                    
                    Text("уровень")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Text("Оценка максимального потребления кислорода на основе данных ЧСС")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.white.opacity(0.5))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .boxingCard()
    }
}

/// Карточка рекомендаций на основе ЧСС
struct HeartRateRecommendationsCard: View {
    let currentHR: Double
    let history: [HeartRateData]
    
    var recommendations: [String] {
        var tips: [String] = []
        
        let avgHR = history.isEmpty ? currentHR : history.map { $0.value }.reduce(0, +) / Double(history.count)
        let restingHR = history.isEmpty ? 60.0 : history.map { $0.value }.min() ?? 60
        
        // Рекомендации на основе текущего ЧСС
        if currentHR > 180 {
            tips.append("⚠️ Очень высокий пульс! Рекомендуется снизить интенсивность или сделать перерыв")
        } else if currentHR > 160 {
            tips.append("Высокая интенсивность. Отличная работа для развития выносливости")
        } else if currentHR < 100 {
            tips.append("Низкий пульс. Можно увеличить интенсивность для более эффективной тренировки")
        }
        
        // Рекомендации на основе среднего ЧСС
        if avgHR > 150 {
            tips.append("Средний пульс за период высокий. Убедитесь в достаточном восстановлении")
        }
        
        // Рекомендации на основе пульса в покое
        if restingHR > 75 {
            tips.append("Пульс в покое выше нормы. Возможно, требуется больше отдыха")
        } else if restingHR < 60 {
            tips.append("✅ Отличный пульс в покое! Это указывает на хорошую физическую форму")
        }
        
        // Общие рекомендации
        if tips.isEmpty {
            tips.append("Продолжайте поддерживать регулярные тренировки")
            tips.append("Следите за восстановлением между тренировками")
        }
        
        return tips
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Рекомендации")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(recommendations, id: \.self) { tip in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.yellow)
                            .padding(.top, 2)
                        
                        Text(tip)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .background(Color.cardBackgroundLight.opacity(0.5))
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .boxingCard()
    }
}

#Preview {
    HeartRateMonitorView()
}

