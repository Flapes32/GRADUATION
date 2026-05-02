# Инструкция по добавлению HealthKit

Разрешения для HealthKit уже добавлены в Build Settings. Теперь нужно добавить capability HealthKit в Xcode.

## Шаг 1: Добавление HealthKit Capability в Xcode

1. Откройте проект `course work.xcodeproj` в Xcode
2. В навигаторе проекта (левая панель) выберите проект "course work" (самый верхний элемент)
3. Выберите target "course work" (под TARGETS)
4. Перейдите на вкладку **"Signing & Capabilities"**
5. Нажмите кнопку **"+ Capability"** (в левом верхнем углу списка capabilities)
6. В появившемся списке найдите и выберите **"HealthKit"**
7. HealthKit capability будет добавлена автоматически

## Шаг 2: Проверка разрешений

Разрешения уже добавлены в Build Settings:
- ✅ `NSHealthShareUsageDescription` - для чтения данных из HealthKit
- ✅ `NSHealthUpdateUsageDescription` - для записи данных в HealthKit  
- ✅ `NSMotionUsageDescription` - для доступа к датчикам движения

## Готово!

После добавления capability HealthKit ваше приложение сможет:
- Читать данные о сердечном ритме
- Читать данные о сне
- Записывать данные о тренировках
- Использовать датчики движения для анализа

## Примечание

HealthKit работает только на реальных устройствах (iPhone/Apple Watch), а не в симуляторе. Для тестирования используйте физическое устройство.

