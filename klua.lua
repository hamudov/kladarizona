-- Скрипт для поиска кладов в Arizona RP с графическим интерфейсом
-- Команда: /klua
-- Функции: добавление, удаление и отображение точек кладов на карте

local treasurePoints = {} -- Таблица для хранения точек кладов
local showTreasureWindow = false -- Флаг для отображения окна управления
local windowMode = "main" -- Режимы: main, add, manual_coords, edit, map
local selectedPointId = nil -- ID выбранной точки для редактирования
local newPointName = "" -- Название новой точки
local manualX, manualY, manualZ = 0, 0, 0 -- Координаты для ручного добавления
local pointCounter = 0 -- Счетчик для ID точек
local mapClickCount = 0 -- Счетчик кликов для добавления точки на карте
local mapClickX, mapClickY = 0, 0 -- Координаты первого клика
local isAddingMapPoint = false -- Флаг добавления точки через карту

-- Константы для цветов
local COLOR_RED = 0xFF0000FF
local COLOR_WHITE = 0xFFFFFFFF
local COLOR_GREEN = 0x00FF00FF
local COLOR_YELLOW = 0xFFFF00FF
local COLOR_BLUE = 0x0000FFFF
local COLOR_GRAY = 0x808080FF

-- Размеры окна
local WINDOW_WIDTH = 600
local WINDOW_HEIGHT = 500
local SCREEN_WIDTH = 1920
local SCREEN_HEIGHT = 1080
local WINDOW_X = (SCREEN_WIDTH - WINDOW_WIDTH) / 2
local WINDOW_Y = (SCREEN_HEIGHT - WINDOW_HEIGHT) / 2

-- Функция для добавления новой точки клада
function addTreasurePoint(name, x, y, z)
    if not x or not y or not z then
        x, y, z = getPlayerCoordinates()
        if x == 0 and y == 0 and z == 0 then
            showMessage("[ОШИБКА] Не удалось получить координаты")
            return false
        end
    end
    
    pointCounter = pointCounter + 1
    local newPoint = {
        id = pointCounter,
        name = name or ("Клад #" .. pointCounter),
        x = x,
        y = y,
        z = z,
        time = os.date("%H:%M:%S"),
        date = os.date("%d.%m.%Y")
    }
    
    table.insert(treasurePoints, newPoint)
    showMessage("[✓] Точка добавлена: " .. newPoint.name)
    showMessage("Координаты: X:" .. math.floor(x) .. " Y:" .. math.floor(y) .. " Z:" .. math.floor(z))
    
    -- Отмечаем точку на карте
    markPointOnMap(newPoint)
    
    return true
end

-- Функция для отмечания точки на карте
function markPointOnMap(point)
    -- Эта функция будет использовать SA:MP функции для отмечания на карте
    -- Здесь используется заглушка
    showMessage("[★] Точка отмечена на карте: " .. point.name .. " (" .. math.floor(point.x) .. ", " .. math.floor(point.y) .. ")")
end

-- Функция для удаления точки клада по ID
function removeTreasurePoint(pointId)
    for i, point in ipairs(treasurePoints) do
        if point.id == pointId then
            local name = point.name
            table.remove(treasurePoints, i)
            showMessage("[✓] Точка удалена: " .. name)
            return true
        end
    end
    showMessage("[ОШИБКА] Точка не найдена")
    return false
end

-- Функция для получения координат игрока
function getPlayerCoordinates()
    -- Заглушка - в реальной реализации используйте API SA:MP
    -- GetPlayerPos(playerid, &Float:x, &Float:y, &Float:z)
    return 100, 200, 5 -- Пример координат
end

-- Функция для вывода сообщения
function showMessage(message)
    print(message)
end

-- Функция для рисования основного окна
function drawMainWindow()
    -- Фон окна
    drawRectangle(WINDOW_X, WINDOW_Y, WINDOW_WIDTH, WINDOW_HEIGHT, 0x1A1A1AFF)
    -- Рамка
    drawRectangleBorder(WINDOW_X, WINDOW_Y, WINDOW_WIDTH, WINDOW_HEIGHT, 2, COLOR_RED)
    
    -- Заголовок
    local titleY = WINDOW_Y + 15
    drawText(WINDOW_X + 20, titleY, "🗺️ УПРАВЛЕНИЕ КЛАДАМИ", COLOR_RED, 1.5)
    
    -- Линия разделитель
    drawLine(WINDOW_X + 20, titleY + 30, WINDOW_X + WINDOW_WIDTH - 20, titleY + 30, COLOR_GRAY)
    
    -- Информация
    local infoY = titleY + 50
    drawText(WINDOW_X + 20, infoY, "Всего точек: " .. #treasurePoints, COLOR_GREEN, 1.0)
    
    -- Список точек
    local listY = infoY + 30
    local maxVisible = 10
    
    if #treasurePoints == 0 then
        drawText(WINDOW_X + 20, listY, "Нет добавленных точек", COLOR_YELLOW, 1.0)
    else
        for i = 1, math.min(#treasurePoints, maxVisible) do
            local point = treasurePoints[i]
            local x, y, z = getPlayerCoordinates()
            local distance = math.sqrt((point.x - x)^2 + (point.y - y)^2 + (point.z - z)^2)
            
            local pointText = i .. ". " .. point.name .. " [" .. math.floor(distance) .. "м]"
            drawText(WINDOW_X + 20, listY + (i-1) * 25, pointText, COLOR_WHITE, 0.9)
        end
    end
    
    -- Кнопки (нарисованы как текст с указаниями)
    local buttonY = WINDOW_Y + WINDOW_HEIGHT - 80
    drawText(WINDOW_X + 20, buttonY, "[ 1 ] Добавить точку", COLOR_GREEN, 1.0)
    drawText(WINDOW_X + 20, buttonY + 25, "[ 2 ] Добавить по координатам", COLOR_YELLOW, 1.0)
    drawText(WINDOW_X + 20, buttonY + 50, "[ 3 ] Удалить точку", COLOR_RED, 1.0)
    drawText(WINDOW_X + WINDOW_WIDTH / 2 + 20, buttonY, "[ 4 ] На карте", COLOR_BLUE, 1.0)
    drawText(WINDOW_X + WINDOW_WIDTH / 2 + 20, buttonY + 25, "[ 5 ] Сохранить", COLOR_GREEN, 1.0)
    drawText(WINDOW_X + WINDOW_WIDTH / 2 + 20, buttonY + 50, "[ ESC ] Закрыть", COLOR_GRAY, 1.0)
end

-- Функция для рисования окна добавления точки (текущая позиция)
function drawAddPointWindow()
    drawRectangle(WINDOW_X, WINDOW_Y, WINDOW_WIDTH, WINDOW_HEIGHT, 0x1A1A1AFF)
    drawRectangleBorder(WINDOW_X, WINDOW_Y, WINDOW_WIDTH, WINDOW_HEIGHT, 2, COLOR_GREEN)
    
    local titleY = WINDOW_Y + 15
    drawText(WINDOW_X + 20, titleY, "➕ ДОБАВИТЬ НОВУЮ ТОЧКУ", COLOR_GREEN, 1.5)
    
    drawLine(WINDOW_X + 20, titleY + 30, WINDOW_X + WINDOW_WIDTH - 20, titleY + 30, COLOR_GRAY)
    
    local x, y, z = getPlayerCoordinates()
    local infoY = titleY + 50
    
    drawText(WINDOW_X + 20, infoY, "Текущие координаты:", COLOR_YELLOW, 1.0)
    drawText(WINDOW_X + 40, infoY + 25, "X: " .. math.floor(x), COLOR_WHITE, 0.9)
    drawText(WINDOW_X + 40, infoY + 45, "Y: " .. math.floor(y), COLOR_WHITE, 0.9)
    drawText(WINDOW_X + 40, infoY + 65, "Z: " .. math.floor(z), COLOR_WHITE, 0.9)
    
    drawText(WINDOW_X + 20, infoY + 100, "Введите название точки:", COLOR_YELLOW, 1.0)
    drawText(WINDOW_X + 40, infoY + 125, "_" .. newPointName .. "_", COLOR_WHITE, 0.9)
    
    local buttonY = WINDOW_Y + WINDOW_HEIGHT - 80
    drawText(WINDOW_X + 20, buttonY, "[ ENTER ] Добавить", COLOR_GREEN, 1.0)
    drawText(WINDOW_X + 20, buttonY + 30, "[ ESC ] Отмена", COLOR_RED, 1.0)
end

-- Функция для рисования окна добавления по координатам
function drawManualCoordsWindow()
    drawRectangle(WINDOW_X, WINDOW_Y, WINDOW_WIDTH, WINDOW_HEIGHT, 0x1A1A1AFF)
    drawRectangleBorder(WINDOW_X, WINDOW_Y, WINDOW_WIDTH, WINDOW_HEIGHT, 2, COLOR_YELLOW)
    
    local titleY = WINDOW_Y + 15
    drawText(WINDOW_X + 20, titleY, "📍 ДОБАВИТЬ ПО КООРДИНАТАМ", COLOR_YELLOW, 1.5)
    
    drawLine(WINDOW_X + 20, titleY + 30, WINDOW_X + WINDOW_WIDTH - 20, titleY + 30, COLOR_GRAY)
    
    local infoY = titleY + 50
    
    drawText(WINDOW_X + 20, infoY, "Введите координаты вручную:", COLOR_YELLOW, 1.0)
    drawText(WINDOW_X + 40, infoY + 30, "X: " .. manualX, COLOR_WHITE, 0.9)
    drawText(WINDOW_X + 40, infoY + 55, "Y: " .. manualY, COLOR_WHITE, 0.9)
    drawText(WINDOW_X + 40, infoY + 80, "Z: " .. manualZ, COLOR_WHITE, 0.9)
    
    drawText(WINDOW_X + 20, infoY + 120, "Название точки:", COLOR_YELLOW, 1.0)
    drawText(WINDOW_X + 40, infoY + 145, "_" .. newPointName .. "_", COLOR_WHITE, 0.9)
    
    local buttonY = WINDOW_Y + WINDOW_HEIGHT - 100
    drawText(WINDOW_X + 20, buttonY, "Нажимайте цифры для редактирования координат", COLOR_GRAY, 0.8)
    drawText(WINDOW_X + 20, buttonY + 25, "[ TAB ] - переключение поля | [ ENTER ] Добавить | [ ESC ] Отмена", COLOR_GRAY, 0.8)
end

-- Функция для рисования режима выбора на карте
function drawMapSelectionWindow()
    drawRectangle(WINDOW_X, WINDOW_Y, WINDOW_WIDTH, WINDOW_HEIGHT, 0x1A1A1AFF)
    drawRectangleBorder(WINDOW_X, WINDOW_Y, WINDOW_WIDTH, WINDOW_HEIGHT, 2, COLOR_BLUE)
    
    local titleY = WINDOW_Y + 15
    drawText(WINDOW_X + 20, titleY, "🎯 ВЫБРАТЬ НА КАРТЕ", COLOR_BLUE, 1.5)
    
    drawLine(WINDOW_X + 20, titleY + 30, WINDOW_X + WINDOW_WIDTH - 20, titleY + 30, COLOR_GRAY)
    
    local infoY = titleY + 50
    
    if mapClickCount == 0 then
        drawText(WINDOW_X + 20, infoY, "Нажмите ЛКМ на карту для выбора точки", COLOR_YELLOW, 1.0)
        drawText(WINDOW_X + 20, infoY + 30, "(Это первый клик)", COLOR_YELLOW, 1.0)
    elseif mapClickCount == 1 then
        drawText(WINDOW_X + 20, infoY, "Первый клик выполнен!", COLOR_GREEN, 1.0)
        drawText(WINDOW_X + 20, infoY + 30, "Координаты: " .. math.floor(mapClickX) .. ", " .. math.floor(mapClickY), COLOR_GREEN, 1.0)
        drawText(WINDOW_X + 20, infoY + 60, "Нажмите ЛКМ второй раз для подтверждения", COLOR_YELLOW, 1.0)
    end
    
    drawText(WINDOW_X + 20, infoY + 100, "Введите название точки:", COLOR_YELLOW, 1.0)
    drawText(WINDOW_X + 40, infoY + 125, "_" .. newPointName .. "_", COLOR_WHITE, 0.9)
    
    local buttonY = WINDOW_Y + WINDOW_HEIGHT - 80
    drawText(WINDOW_X + 20, buttonY, "[ ENTER ] Добавить", COLOR_GREEN, 1.0)
    drawText(WINDOW_X + 20, buttonY + 30, "[ ESC ] Отмена", COLOR_RED, 1.0)
end

-- Функция для рисования списка всех точек
function drawListWindow()
    drawRectangle(WINDOW_X, WINDOW_Y, WINDOW_WIDTH, WINDOW_HEIGHT, 0x1A1A1AFF)
    drawRectangleBorder(WINDOW_X, WINDOW_Y, WINDOW_WIDTH, WINDOW_HEIGHT, 2, COLOR_BLUE)
    
    local titleY = WINDOW_Y + 15
    drawText(WINDOW_X + 20, titleY, "📋 ВСЕ ТОЧКИ КЛАДОВ", COLOR_BLUE, 1.5)
    
    drawLine(WINDOW_X + 20, titleY + 30, WINDOW_X + WINDOW_WIDTH - 20, titleY + 30, COLOR_GRAY)
    
    local listY = titleY + 50
    local maxVisible = 15
    
    if #treasurePoints == 0 then
        drawText(WINDOW_X + 20, listY, "Нет добавленных точек", COLOR_YELLOW, 1.0)
    else
        for i = 1, math.min(#treasurePoints, maxVisible) do
            local point = treasurePoints[i]
            local x, y, z = getPlayerCoordinates()
            local distance = math.sqrt((point.x - x)^2 + (point.y - y)^2 + (point.z - z)^2)
            
            local color = (selectedPointId == point.id) and COLOR_GREEN or COLOR_WHITE
            local pointText = string.format("[%d] %s (%.1f м)", point.id, point.name, distance)
            drawText(WINDOW_X + 20, listY + (i-1) * 25, pointText, color, 0.9)
            drawText(WINDOW_X + 400, listY + (i-1) * 25, "X:" .. math.floor(point.x) .. " Y:" .. math.floor(point.y), COLOR_GRAY, 0.8)
        end
    end
    
    local buttonY = WINDOW_Y + WINDOW_HEIGHT - 50
    drawText(WINDOW_X + 20, buttonY, "[ ← ] Назад", COLOR_YELLOW, 1.0)
end

-- Заглушки для функций рисования (нужны для реальной реализации с SA:MP)
function drawRectangle(x, y, w, h, color)
    -- Используется для рисования прямоугольников
end

function drawRectangleBorder(x, y, w, h, thickness, color)
    -- Используется для рисования рамок
end

function drawText(x, y, text, color, scale)
    -- Используется для вывода текста на экран
    -- print("[" .. x .. "," .. y .. "] " .. text)
end

function drawLine(x1, y1, x2, y2, color)
    -- Используется для рисования линий
end

-- Функция для обновления окна
function updateWindow()
    if not showTreasureWindow then return end
    
    if windowMode == "main" then
        drawMainWindow()
    elseif windowMode == "add" then
        drawAddPointWindow()
    elseif windowMode == "manual_coords" then
        drawManualCoordsWindow()
    elseif windowMode == "map" then
        drawMapSelectionWindow()
    elseif windowMode == "list" then
        drawListWindow()
    end
end

-- Функция для открытия/закрытия окна
function toggleTreasureWindow()
    showTreasureWindow = not showTreasureWindow
    windowMode = "main"
    newPointName = ""
    mapClickCount = 0
    manualX, manualY, manualZ = 0, 0, 0
    
    if showTreasureWindow then
        showMessage("[✓] Окно управления кладами открыто")
    else
        showMessage("[✓] Окно управления кладами закрыто")
    end
end

-- Команда /klua
function cmdTreasure(text)
    if not text or text == "" then
        toggleTreasureWindow()
        return true
    end
    
    local args = {}
    for arg in string.gmatch(text, "[^ ]+") do
        table.insert(args, arg)
    end
    
    local command = args[1]:lower()
    
    if command == "add" then
        local name = string.sub(text, 5)
        if name == "" then
            name = "Клад #" .. (pointCounter + 1)
        end
        addTreasurePoint(name)
        
    elseif command == "del" then
        if not args[2] then
            showMessage("[!] Использование: /klua del [ID]")
            return true
        end
        local pointId = tonumber(args[2])
        if not pointId then
            showMessage("[ОШИБКА] ID должен быть числом")
            return true
        end
        removeTreasurePoint(pointId)
        
    elseif command == "list" then
        toggleTreasureWindow()
        windowMode = "list"
        
    elseif command == "coords" then
        local x, y, z = getPlayerCoordinates()
        showMessage("Ваши координаты: X:" .. math.floor(x) .. " Y:" .. math.floor(y) .. " Z:" .. math.floor(z))
        
    elseif command == "clear" then
        treasurePoints = {}
        pointCounter = 0
        showMessage("[✓] Все точки кладов очищены")
        
    elseif command == "help" then
        showMessage("~g~=== СПРАВКА ПО КОМАНДАМ ПОИСКА КЛАДОВ ===~s~")
        showMessage("~y~/klua~s~ - Открыть главное окно управления")
        showMessage("~y~/klua add [название]~s~ - Добавить точку из текущей позиции")
        showMessage("~y~/klua del [ID]~s~ - Удалить точку по ID")
        showMessage("~y~/klua list~s~ - Показать список всех точек")
        showMessage("~y~/klua coords~s~ - Показать текущие координаты")
        showMessage("~y~/klua clear~s~ - Удалить все точки")
    else
        showMessage("[ОШИБКА] Неизвестная команда. Введите /klua help")
    end
    
    return true
end

-- Экспорт функций
return {
    addTreasurePoint = addTreasurePoint,
    removeTreasurePoint = removeTreasurePoint,
    toggleTreasureWindow = toggleTreasureWindow,
    updateWindow = updateWindow,
    cmdTreasure = cmdTreasure,
    getPlayerCoordinates = getPlayerCoordinates,
    treasurePoints = treasurePoints,
    showTreasureWindow = function() return showTreasureWindow end,
    getWindowMode = function() return windowMode end
}
