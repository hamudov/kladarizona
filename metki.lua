script_name("Treasure Map Manager")
script_author("hamudov")

require "lib.moonloader"
local sampev = require "samp.events"
local encoding = require "encoding"
encoding.default = 'CP1251'
local u8 = encoding.UTF8

-- Переменные
local treasureMarkers = {}
local iconId = 41
local renderDist = 0
local saveDir = getWorkingDirectory() .. "\\config"
local savePath = saveDir .. "\\treasure_markers.json"

-- Переменные для интерфейса
local showWindow = false
local windowMode = "main" -- main, add, manual_coords, list, delete
local inputText = ""
local inputFieldIndex = 1
local manualX, manualY, manualZ = 0, 0, 0
local selectedMarkerId = nil

function getMyPlayerId()
    local result, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
    return result and id or nil
end

function createMapBlip(x, y, z)
    return addSpriteBlipForCoord(x, y, z, iconId)
end

function getDistance(x1, y1, z1, x2, y2, z2)
    return math.sqrt((x1 - x2)^2 + (y1 - y2)^2 + (z1 - z2)^2)
end

function isMarkerNearby(x, y, z, radius)
    for _, mark in ipairs(treasureMarkers) do
        if getDistance(x, y, z, mark.x, mark.y, mark.z) <= radius then
            return true
        end
    end
    return false
end

function updateBlipsVisibility()
    local px, py, pz = getCharCoordinates(PLAYER_PED)
    for _, mark in ipairs(treasureMarkers) do
        local dist = getDistance(px, py, pz, mark.x, mark.y, mark.z)
        
        if renderDist == 0 or dist <= renderDist then
            if not mark.blip then
                mark.blip = createMapBlip(mark.x, mark.y, mark.z)
            end
        else
            if mark.blip then
                removeBlip(mark.blip)
                mark.blip = nil
            end
        end
    end
end

function refreshAllBlips()
    for _, mark in ipairs(treasureMarkers) do
        if mark.blip then 
            removeBlip(mark.blip) 
            mark.blip = nil
        end
    end
    updateBlipsVisibility()
end

function saveMarkers()
    if not doesDirectoryExist(saveDir) then createDirectory(saveDir) end
    local file = io.open(savePath, "w")
    if file then
        local tempSave = {}
        for _, m in ipairs(treasureMarkers) do
            table.insert(tempSave, {
                name = m.name or "Клад",
                x = m.x, 
                y = m.y, 
                z = m.z,
                time = m.time or os.date("%H:%M:%S")
            })
        end
        local saveData = { 
            current_icon = iconId, 
            render_distance = renderDist,
            map_markers = tempSave 
        }
        file:write(encodeJson(saveData))
        file:close()
        sampAddChatMessage(("{00FF00}[Клад] {FFFFFF}Маркеры сохранены!"), -1)
    end
end

function loadMarkers()
    local file = io.open(savePath, "r")
    if file then
        local content = file:read("*a")
        file:close()
        local decoded = decodeJson(content)
        if decoded then 
            treasureMarkers = decoded.map_markers or {}
            iconId = decoded.current_icon or 41
            renderDist = decoded.render_distance or 0
        end
    end
end

function addTreasureMarker(name, x, y, z)
    if not name then name = "Клад #" .. (#treasureMarkers + 1) end
    
    table.insert(treasureMarkers, {
        name = name,
        x = x, 
        y = y, 
        z = z,
        time = os.date("%H:%M:%S"),
        blip = nil
    })
    saveMarkers()
    updateBlipsVisibility()
    sampAddChatMessage(("{00FF00}[Клад] {FFFFFF}Маркер '" .. name .. "' добавлен!"), -1)
end

function deleteTreasureMarker(index)
    if treasureMarkers[index] then
        if treasureMarkers[index].blip then
            removeBlip(treasureMarkers[index].blip)
        end
        local markerName = treasureMarkers[index].name
        table.remove(treasureMarkers, index)
        saveMarkers()
        sampAddChatMessage(("{00FF00}[Клад] {FFFFFF}Маркер '" .. markerName .. "' удален!"), -1)
    end
end

function toggleWindow()
    showWindow = not showWindow
    windowMode = "main"
    inputText = ""
    if showWindow then
        sampAddChatMessage(("{00FF00}[Клад] {FFFFFF}Окно управления открыто!"), -1)
    end
end

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end

    loadMarkers()
    refreshAllBlips()

    lua_thread.create(function()
        while true do
            wait(1000) 
            if renderDist > 0 and not isGamePaused() then
                updateBlipsVisibility()
            end
        end
    end)

    -- Команда для открытия окна
    sampRegisterChatCommand("klua", function()
        toggleWindow()
    end)

    -- Команда быстрого добавления маркера
    sampRegisterChatCommand("kadd", function(arg)
        local name = arg ~= "" and arg or "Клад #" .. (#treasureMarkers + 1)
        local x, y, z = getCharCoordinates(PLAYER_PED)
        
        if isMarkerNearby(x, y, z, 10.0) then
            sampAddChatMessage(("{FFFF00}[Клад] {FFFFFF}Слишком близко к уже существующему маркеру!"), -1)
            return
        end
        
        addTreasureMarker(name, x, y, z)
    end)

    -- Команда для удаления ближайшего маркера
    sampRegisterChatCommand("kdel", function()
        if #treasureMarkers == 0 then
            sampAddChatMessage(("{FF0000}[Клад] {FFFFFF}Нет маркеров!"), -1)
            return
        end
        
        local px, py, pz = getCharCoordinates(PLAYER_PED)
        local closestIdx = nil
        local minDist = 999999.0
        
        for i, mark in ipairs(treasureMarkers) do
            local dist = getDistance(px, py, pz, mark.x, mark.y, mark.z)
            if dist < minDist then
                minDist = dist
                closestIdx = i
            end
        end
        
        if closestIdx then
            deleteTreasureMarker(closestIdx)
        end
    end)

    -- Команда для установки дистанции отрисовки
    sampRegisterChatCommand("kdist", function(arg)
        local dist = tonumber(arg)
        if dist and dist >= 0 then
            renderDist = dist
            saveMarkers()
            refreshAllBlips()
            if dist == 0 then
                sampAddChatMessage(("{00FF00}[Клад] {FFFFFF}Отрисовка: все маркеры видны."), -1)
            else
                sampAddChatMessage(("{00FF00}[Клад] {FFFFFF}Отрисовка: только в радиусе " .. dist .. "м."), -1)
            end
        else
            sampAddChatMessage(("{FF0000}[Клад] {FFFFFF}Использование: /kdist [расстояние]"), -1)
        end
    end)

    -- Команда для изменения иконки
    sampRegisterChatCommand("kicon", function(arg)
        local id = tonumber(arg)
        if id then
            iconId = id
            saveMarkers()
            refreshAllBlips()
            sampAddChatMessage(("{00FF00}[Клад] {FFFFFF}Иконка изменена на: " .. id), -1)
        else
            sampAddChatMessage(("{FF0000}[Клад] {FFFFFF}Использование: /kicon [ID]"), -1)
        end
    end)

    -- Команда для помощи
    sampRegisterChatCommand("khelp", function()
        sampAddChatMessage(("{00FF00}[Клад] {FFFFFF}--- СПРАВКА ---"), -1)
        sampAddChatMessage(("{FFFF00}/klua {FFFFFF}--- Открыть окно управления"), -1)
        sampAddChatMessage(("{FFFF00}/kadd [название] {FFFFFF}--- Добавить маркер"), -1)
        sampAddChatMessage(("{FFFF00}/kdel {FFFFFF}--- Удалить ближайший маркер"), -1)
        sampAddChatMessage(("{FFFF00}/kdist [м] {FFFFFF}--- Расстояние отрисовки"), -1)
        sampAddChatMessage(("{FFFF00}/kicon [ID] {FFFFFF}--- Изменить иконку"), -1)
    end)

    wait(-1)
end

function sampev.onServerMessage(color, text)
    local cleanText = text:gsub("{%x%x%x%x%x%x}", "")
    local myId = getMyPlayerId()
    if not myId then return end
    
    local myName = sampGetPlayerNickname(myId)
    local pattern = ("Вы начали копать") 

    if cleanText:find(pattern) then
        lua_thread.create(function()
            wait(500)
            if getActiveInterior() ~= 0 then return end

            local x, y, z = getCharCoordinates(PLAYER_PED)
            if x ~= 0 or y ~= 0 then
                if not isMarkerNearby(x, y, z, 10.0) then
                    addTreasureMarker("Найденный клад", x, y, z)
                end
            end
        end)
    end
end
