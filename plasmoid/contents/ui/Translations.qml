import QtQuick

QtObject {
    property string currentLanguage: "system"
    readonly property string language: currentLanguage === "system"
        ? (Qt.locale().name.startsWith("uk") ? "uk" : "en")
        : currentLanguage

    readonly property var uk: ({
        "Battery": "Заряд",
        "Polling rate": "Частота",
        "Connection": "Зв'язок",
        "Updated": "Оновлено",
        "Hz": "Гц",
        "mV": "мВ",
        "mouse": "мишка",
        "receiver": "ресивер",
        "cable": "кабель",
        "not connected": "не підключено",
        "mouse is not linked": "мишка не на зв'язку",
        "no access to the mouse": "немає доступу до мишки",
        "Grant access": "Надати доступ",
        "— (move the mouse)": "— (поводь мишкою)",
        "Language:": "Мова:",
        "System": "Системна",
        "Indicator:": "Індикатор:",
        "Ring": "Кільце",
        "Vertical bar": "Вертикальна смужка",
        "Horizontal bar": "Горизонтальна батарейка",
        "Text": "Текст",
        "Show percentage": "Показувати відсотки",
        "Icon:": "Іконка:",
        "Choose…": "Вибрати…"
    })

    function tr(text) {
        return language === "uk" && uk[text] ? uk[text] : text
    }
}
