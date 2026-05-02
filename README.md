# 🥊 Boxing Tracker

Мобильное приложение для мониторинга физиологического состояния боксёра в процессе тренировки. Дипломная работа БГУ, 2025.

## Структура проекта

```
GRADUATION/
├── Models/
│   └── Models.swift                  # Все модели данных
├── Managers/
│   ├── HealthKitManager.swift        # Работа с HealthKit (iOS)
│   ├── WatchSessionManager.swift     # WatchConnectivity (iOS → Watch)
│   └── WorkoutManager.swift          # Менеджер тренировок + LactatePredictor
├── CoreData/
│   ├── CDEntities.swift              # NSManagedObject классы
│   ├── WorkoutRepository.swift       # CRUD операции
│   └── BoxingTracker.xcdatamodel/   # Схема CoreData
├── Views/
│   ├── MainView.swift                # Главный экран / дашборд
│   ├── WorkoutView.swift             # Экран тренировки
│   └── AllViews.swift                # ЧСС, Статистика, Сон, Достижения
├── Watch App/
│   ├── Managers/
│   │   ├── WatchConnectivityManager.swift  # WatchConnectivity (Watch → iPhone)
│   │   └── WatchHealthKitManager.swift     # HealthKit на часах
│   └── Views/
│       └── WatchViews.swift          # Все экраны watchOS
├── ContentView.swift                 # TabView навигация
└── course_workApp.swift              # @main точка входа
```

## Установка в Xcode

### 1. Скопируй файлы

Скопируй все файлы из этой папки в свой Xcode-проект, сохраняя структуру папок.

### 2. Добавь Watch App target

1. File → New → Target → watchOS → App
2. Назови **"Boxing Tracker Watch App"**
3. Перенеси файлы из `Watch App/` в новый target

### 3. CoreData модель

1. File → New → File → Data Model → назови `BoxingTracker`
2. Скопируй содержимое `BoxingTracker.xcdatamodel/contents` в созданную модель
3. **ИЛИ** просто скопируй папку `BoxingTracker.xcdatamodel` в проект

### 4. Capabilities (для каждого target)

**iOS target:**
- HealthKit
- WatchConnectivity (автоматически при добавлении Watch target)

**watchOS target:**
- HealthKit

### 5. Info.plist ключи (iOS)

```xml
NSHealthShareUsageDescription  → "Доступ к данным здоровья для мониторинга тренировок"
NSHealthUpdateUsageDescription → "Запись тренировок и данных ЧСС в HealthKit"
NSMotionUsageDescription       → "Данные движения для прогнозирования лактата"
```

### 6. App Groups

Для обмена данными между iOS и watchOS:
1. В Signing & Capabilities обоих targets добавь **App Groups**
2. Создай группу: `group.com.yourname.boxingtracker`

## Что реализовано

| Функция | Статус |
|---|---|
| Мониторинг ЧСС в реальном времени | ✅ |
| Прогнозирование лактата | ✅ |
| HRV (вариабельность ритма) | ✅ |
| Расход калорий | ✅ |
| Анализ сна (HealthKit) | ✅ |
| CoreData — история тренировок | ✅ |
| WatchConnectivity — двусторонняя синхронизация | ✅ |
| watchOS приложение | ✅ |
| Достижения | ✅ |
| Статистика по периодам | ✅ |

## Технологии

- **Swift 5.9** — язык программирования
- **SwiftUI** — декларативный UI (iOS + watchOS)
- **HealthKit** — физиологические данные
- **WatchConnectivity** — синхронизация iPhone ↔ Apple Watch
- **CoreData** — локальное хранение истории
- **CoreMotion** — данные акселерометра для лактата
- **Charts** — графики ЧСС и сна
- **MVVM** — архитектурный паттерн
