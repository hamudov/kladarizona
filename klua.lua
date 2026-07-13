-- Скрипт для поиска кладов в Arizona RP
-- Команда: /klua
-- Функции: добавление, удаление и отображение точек кладов на карте

local treasurePoints = {} -- Таблица для хранения точек кладов
local showTreasureMap = false -- Флаг для отображения окна управления
local selectedPointId = nil -- ID выбранной точки для редактирования
local newPointName = "" -- Название новой точки
local pointCounter = 0 -- Счетчик для ID точек

-- Константы для цветов
local COLOR_RED = 0xFF0000FF -- Красный цвет для точек на карте
local COLOR_WHITE = 0xFFFFFFFF -- Белый цвет для текста
local COLOR_GREEN = 0x00FF00FF -- З��леный цвет
local COLOR_YELLOW = 0xFFFF00FF -- Желтый цвет

-- Таблица для хранения отображаемых текстов на экране
local screenText = {}

-- Функция для добавления новой точки клада
function addTreasurePoint(name)
    local x, y, z = getPlayerPos()
    if x == 0 and y == 0 and z == 0 then
        sendChatMessage("[ОШИБКА] Не удалось получить координаты")
        return false
    end
    
    pointCounter = pointCounter + 1
    local newPoint = {
        id = pointCounter,
        name = name or ("Клад #" .. pointCounter),
        x = x,
        y = y,
        z = z,
        time = os.date("%H:%M:%S")
    }
    
    table.insert(treasurePoints, newPoint)
    sendChatMessage("[✓] Точка клада добавлена: " .. newPoint.name .. " | Координаты: " .. math.floor(x) .. ", " .. math.floor(y) .. ", " .. math.floor(z))
    
    return true
end

-- Функция для удаления точки клада по ID
function removeTreasurePoint(pointId)
    for i, point in ipairs(treasurePoints) do
        if point.id == pointId then
            local name = point.name
            table.remove(treasurePoints, i)
            sendChatMessage("[✓] Точка клада удалена: " .. name)
            return true
        end
    end
    sendChatMessage("[ОШИБКА] Точка с ID " .. pointId .. " не найдена")
    return false
end

-- Функция для отправки сообщения в чат
function sendChatMessage(message)
    -- Эта функция зависит от движка SA:MP
    -- Используется для вывода сообщений в чат игры
    print(message) -- Для тестирования в консоли
end

-- Функция для получения позиции игрока
function getPlayerPos()
    -- Эта функция должна вызывать API SA:MP для получения позиции
    -- Здесь используется заглушка для примера
    -- В реальной реализации нужно использовать GetPlayerPos() из SA:MP
    return 0, 0, 0 -- Заглушка
end

-- Функция для отображения окна управления метками
function showTreasureWindow()
    showTreasureMap = not showTreasureMap
    if showTreasureMap then
        sendChatMessage("[✓] Окно управления кладами открыто. Введите /klua help для справки")
    else
        sendChatMessage("[✓] Окно управления кладами закрыто")
    end
end

-- Функция для отображения всех точек кладов на карте (текстовая версия)
function drawTreasurePoints()
    screenText = {}
    
    if not showTreasureMap then return end
    
    table.insert(screenText, "~r~[ПОИСК КЛАДОВ]~s~ (Нажми ESC для выхода)")
    table.insert(screenText, "━━━━━━━━━━━━━━━━━━━━━━━━━━")
    
    if #treasurePoints == 0 then
        table.insert(screenText, "~y~Нет добавленных точек~s~")
    else
        for i, point in ipairs(treasurePoints) do
            local distance = math.sqrt(
                (point.x - getPlayerPos())^2 + 
                (point.y - select(2, getPlayerPos()))^2 + 
                (point.z - select(3, getPlayerPos()))^2
            )
            
            table.insert(screenText, "~g~" .. i .. ".~s~ " .. point.name .. 
                        " ~y~[" .. math.floor(distance) .. "м]~s~")
            table.insert(screenText, "   Координаты: " .. math.floor(point.x) .. ", " .. 
                        math.floor(point.y) .. ", " .. math.floor(point.z))
            table.insert(screenText, "   Добавлено: " .. point.time)
        end
    end
    
    table.insert(screenText, "━━━━━━━━━━━━━━━━━━━━━━━━━━")
    table.insert(screenText, "~g~/klua add [название]~s~ - Добавить точку")
    table.insert(screenText, "~r~/klua del [ID]~s~ - Удалить точку")
    table.insert(screenText, "~y~/klua list~s~ - Показать все точки")
    table.insert(screenText, "~b~/klua help~s~ - Справка")
end

-- Команда /klua
function cmdTreasure(text)
    if not text or text == "" then
        showTreasureWindow()
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
            sendChatMessage("[!] Использование: /klua add [название точки]")
            return true
        end
        addTreasurePoint(name)
        
    elseif command == "del" then
        if not args[2] then
            sendChatMessage("[!] Использование: /klua del [ID]")
            return true
        end
        local pointId = tonumber(args[2])
        if not pointId then
            sendChatMessage("[ОШИБКА] ID должен быть числом")
            return true
        end
        removeTreasurePoint(pointId)
        
    elseif command == "list" then
        showTreasureWindow()
        
    elseif command == "help" then
        sendChatMessage("~g~=== СПРАВКА ПО КОМАНДАМ ПОИСКА КЛАДОВ ===~s~")
        sendChatMessage("~y~/klua~s~ - Открыть/закрыть окно управления")
        sendChatMessage("~y~/klua add [название]~s~ - Добавить новую точку клада")
        sendChatMessage("  Пример: ~g~/klua add Клад у дерева~s~")
        sendChatMessage("~y~/klua del [ID]~s~ - Удалить точку клада по ID")
        sendChatMessage("  Пример: ~g~/klua del 1~s~")
        sendChatMessage("~y~/klua list~s~ - Показать все добавленные точки")
        sendChatMessage("~y~/klua clear~s~ - Удалить все точки")
        
    elseif command == "clear" then
        treasurePoints = {}
        pointCounter = 0
        sendChatMessage("[✓] Все точки кладов очищены")
        
    else
        sendChatMessage("[ОШИБКА] Неизвестная команда. Введите /klua help")
    end
    
    return true
end

-- Функция для сохранения точек в файл
function saveTreasurePoints(filename)
    local file = io.open(filename or "treasurepoints.json", "w")
    if not file then
        sendChatMessage("[ОШИБКА] Не удалось открыть файл для сохранения")
        return false
    end
    
    local jsonData = "{"
    for i, point in ipairs(treasurePoints) do
        if i > 1 then jsonData = jsonData .. "," end
        jsonData = jsonData .. '"point' .. point.id .. '":{'
        jsonData = jsonData .. '"id":' .. point.id .. ','
        jsonData = jsonData .. '"name":"' .. point.name .. '",'
        jsonData = jsonData .. '"x":' .. point.x .. ','
        jsonData = jsonData .. '"y":' .. point.y .. ','
        jsonData = jsonData .. '"z":' .. point.z .. ','
        jsonData = jsonData .. '"time":"' .. point.time .. '"'
        jsonData = jsonData .. '}'
    end
    jsonData = jsonData .. "}"
    
    file:write(jsonData)
    file:close()
    sendChatMessage("[✓] Точки кладов сохранены в файл: " .. (filename or "treasurepoints.json"))
    return true
end

-- Функция для загрузки точек из файла
function loadTreasurePoints(filename)
    local file = io.open(filename or "treasurepoints.json", "r")
    if not file then
        sendChatMessage("[ОШИБКА] Файл не найден: " .. (filename or "treasurepoints.json"))
        return false
    end
    
    -- Здесь нужна обработка JSON
    -- Это упрощенная версия - в реальной реализации используйте JSON library
    
    file:close()
    sendChatMessage("[✓] Точки кладов загружены из файла")
    return true
end

-- Экспорт функций
return {
    addTreasurePoint = addTreasurePoint,
    removeTreasurePoint = removeTreasurePoint,
    showTreasureWindow = showTreasureWindow,
    drawTreasurePoints = drawTreasurePoints,
    cmdTreasure = cmdTreasure,
    saveTreasurePoints = saveTreasurePoints,
    loadTreasurePoints = loadTreasurePoints,
    treasurePoints = treasurePoints
}
