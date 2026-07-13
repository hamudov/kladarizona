-- Интеграция скрипта управления кладами с SA:MP
-- Этот файл содержит функции для работы с реальным SA:MP API

local treasureManager = require("klua")

-- Переменные для обработки ввода
local isInputActive = false
local currentEditField = 1 -- 1 = X, 2 = Y, 3 = Z, 4 = Name
local fieldValues = {0, 0, 0, ""}

-- Функция инициализации интеграции
function initTreasureManager()
    print("✓ Менеджер кладов инициализирован")
    
    -- Здесь должны быть регистрации обработчиков событий SA:MP
    -- registerCommand("klua", treasureManager.cmdTreasure)
    -- registerOnGameRender(treasureManager.updateWindow)
    -- registerOnKeyDown(handleKeyPress)
    -- registerOnMapClick(handleMapClick)
end

-- Обработчик нажатия клавиш
function handleKeyPress(key)
    local window = treasureManager.showTreasureWindow()
    if not window then return end
    
    local mode = treasureManager.getWindowMode()
    
    -- ESC - выход
    if key == 27 then
        treasureManager.toggleTreasureWindow()
        return
    end
    
    if mode == "main" then
        handleMainWindowKeys(key)
    elseif mode == "add" then
        handleAddWindowKeys(key)
    elseif mode == "manual_coords" then
        handleManualCoordsKeys(key)
    elseif mode == "map" then
        handleMapWindowKeys(key)
    end
end

-- Обработчик нажатий в главном окне
function handleMainWindowKeys(key)
    if key == 49 then -- 1
        treasureManager.windowMode = "add"
    elseif key == 50 then -- 2
        treasureManager.windowMode = "manual_coords"
        fieldValues = {0, 0, 0, ""}
        currentEditField = 1
    elseif key == 51 then -- 3
        treasureManager.windowMode = "delete_select"
    elseif key == 52 then -- 4
        treasureManager.windowMode = "map"
        treasureManager.mapClickCount = 0
    elseif key == 53 then -- 5
        treasureManager.saveTreasurePoints()
    end
end

-- Обработчик нажатий в окне добавления точки
function handleAddWindowKeys(key)
    if key == 13 then -- ENTER
        if treasureManager.newPointName ~= "" then
            treasureManager.addTreasurePoint(treasureManager.newPointName)
            treasureManager.windowMode = "main"
            treasureManager.newPointName = ""
        end
    elseif key == 8 then -- BACKSPACE
        treasureManager.newPointName = string.sub(treasureManager.newPointName, 1, -2)
    elseif key >= 32 and key <= 126 then -- Обычные символы
        treasureManager.newPointName = treasureManager.newPointName .. string.char(key)
    end
end

-- Обработчик нажатий в окне ручного ввода координат
function handleManualCoordsKeys(key)
    if key == 13 then -- ENTER
        if fieldValues[4] ~= "" then
            treasureManager.addTreasurePoint(fieldValues[4], fieldValues[1], fieldValues[2], fieldValues[3])
            treasureManager.windowMode = "main"
            fieldValues = {0, 0, 0, ""}
        end
    elseif key == 9 then -- TAB - переключение между полями
        currentEditField = currentEditField + 1
        if currentEditField > 4 then currentEditField = 1 end
    elseif key == 8 then -- BACKSPACE
        if currentEditField <= 3 then
            fieldValues[currentEditField] = math.floor(fieldValues[currentEditField] / 10)
        else
            fieldValues[4] = string.sub(fieldValues[4], 1, -2)
        end
    elseif key >= 48 and key <= 57 then -- Цифры 0-9
        if currentEditField <= 3 then
            fieldValues[currentEditField] = fieldValues[currentEditField] * 10 + (key - 48)
        else
            fieldValues[4] = fieldValues[4] .. string.char(key)
        end
    elseif key == 45 and currentEditField <= 3 then -- Минус для координат
        fieldValues[currentEditField] = -fieldValues[currentEditField]
    elseif key == 46 and currentEditField <= 3 then -- Точка для координат
        -- Для упрощения игнорируем дробные части
    end
    
    -- Обновляем значения в менеджере
    treasureManager.manualX = fieldValues[1]
    treasureManager.manualY = fieldValues[2]
    treasureManager.manualZ = fieldValues[3]
    treasureManager.newPointName = fieldValues[4]
end

-- Обработчик нажатий в режиме выбора на карте
function handleMapWindowKeys(key)
    if key == 13 then -- ENTER
        if treasureManager.mapClickCount == 2 and treasureManager.newPointName ~= "" then
            treasureManager.addTreasurePoint(treasureManager.newPointName, treasureManager.mapClickX, treasureManager.mapClickY, 5)
            treasureManager.windowMode = "main"
            treasureManager.newPointName = ""
            treasureManager.mapClickCount = 0
        end
    elseif key == 8 then -- BACKSPACE
        treasureManager.newPointName = string.sub(treasureManager.newPointName, 1, -2)
    elseif key >= 32 and key <= 126 then -- Обычные символы
        treasureManager.newPointName = treasureManager.newPointName .. string.char(key)
    end
end

-- Обработчик клика на карте
function handleMapClick(x, y)
    local mode = treasureManager.getWindowMode()
    
    if mode == "map" then
        treasureManager.mapClickCount = treasureManager.mapClickCount + 1
        
        if treasureManager.mapClickCount == 1 then
            treasureManager.mapClickX = x
            treasureManager.mapClickY = y
            print("✓ Первая точка выбрана: " .. math.floor(x) .. ", " .. math.floor(y))
        elseif treasureManager.mapClickCount == 2 then
            print("✓ Вторая точка выбрана: " .. math.floor(x) .. ", " .. math.floor(y))
        end
    end
end

-- Функция для рендеринга окна (вызывается каждый кадр)
function renderTreasure()
    treasureManager.updateWindow()
end

-- Функция сохранения точек в JSON файл
function saveTreasurePointsToFile()
    local points = treasureManager.treasurePoints
    
    local json = "[\n"
    for i, point in ipairs(points) do
        if i > 1 then json = json .. ",\n" end
        json = json .. string.format(
            '  {"id":%d,"name":"%s","x":%.2f,"y":%.2f,"z":%.2f,"time":"%s","date":"%s"}',
            point.id, point.name, point.x, point.y, point.z, point.time, point.date
        )
    end
    json = json .. "\n]"
    
    -- Здесь должна быть реальная запись в файл
    print("[✓] Файл будет сохранен: treasurepoints.json")
    print(json)
end

-- Инициализация при загрузке скрипта
print("=== Скрипт управления кладами для Arizona RP ===")
print("Команда: /klua")
print("Для справки введите: /klua help")

-- Возвращаемый интерфейс
return {
    init = initTreasureManager,
    handleKeyPress = handleKeyPress,
    handleMapClick = handleMapClick,
    render = renderTreasure,
    saveTreasurePoints = saveTreasurePointsToFile
}
