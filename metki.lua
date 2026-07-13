script_name("Klad Aurora")
script_author("hamudov")

require "lib.moonloader"
local sampev = require "samp.events"
local encoding = require "encoding"
encoding.default = 'CP1251'
local u8 = encoding.UTF8

local treasureMarkers = {}
local iconId = 41
local renderDist = 0
local saveDir = getWorkingDirectory() .. "\\config"
local savePath = saveDir .. "\\treasure_markers.json"

local showWindow = false
local windowTab = 1
local inputName = ""
local inputX = ""
local inputY = ""
local inputZ = ""
local selectedMarker = 0

local screenWidth, screenHeight = getScreenResolution()
local windowWidth = 700
local windowHeight = 500
local windowX = (screenWidth - windowWidth) / 2
local windowY = (screenHeight - windowHeight) / 2

local colors = {
    bg = 0x1A1A1AFF,
    border = 0xFF6600FF,
    text = 0xFFFFFFFF,
    header = 0xFF6600FF,
    button = 0xFF6600FF,
    buttonHover = 0xFF8800FF,
    success = 0x00FF00FF,
    error = 0xFF0000FF,
    warning = 0xFFFF00FF
}

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
                name = m.name or "Klad",
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
    if not name or name == "" then name = "Klad #" .. (#treasureMarkers + 1) end
    
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
end

function deleteTreasureMarker(index)
    if treasureMarkers[index] then
        if treasureMarkers[index].blip then
            removeBlip(treasureMarkers[index].blip)
        end
        table.remove(treasureMarkers, index)
        saveMarkers()
        refreshAllBlips()
    end
end

function drawBox(x, y, w, h, color)
    renderDrawBox(x, y, w, h, 2, color, color)
end

function drawText(text, x, y, color, scale)
    renderFonts(x, y, x + 200, y + 20, color, text, 0, scale or 1, 1)
end

function drawWindow()
    if not showWindow then return end
    
    -- Background
    drawBox(windowX, windowY, windowWidth, windowHeight, colors.bg)
    
    -- Border
    renderDrawLine(windowX, windowY, windowX + windowWidth, windowY, 2, colors.border)
    renderDrawLine(windowX, windowY, windowX, windowY + windowHeight, 2, colors.border)
    renderDrawLine(windowX + windowWidth, windowY, windowX + windowWidth, windowY + windowHeight, 2, colors.border)
    renderDrawLine(windowX, windowY + windowHeight, windowX + windowWidth, windowY + windowHeight, 2, colors.border)
    
    -- Header
    drawBox(windowX, windowY, windowWidth, 40, colors.header)
    renderFonts(windowX + 10, windowY + 10, windowX + windowWidth - 10, windowY + 30, colors.text, "KLAD MANAGER [" .. #treasureMarkers .. " markers]", 0, 1.2, 1)
    
    -- Close button
    if renderGetCursorPos then
        local mx, my = getCursorPos()
        local closeX, closeY = windowX + windowWidth - 30, windowY + 10
        if mx >= closeX and mx <= closeX + 20 and my >= closeY and my <= closeY + 20 then
            drawBox(closeX, closeY, 20, 20, colors.error)
        else
            drawBox(closeX, closeY, 20, 20, colors.button)
        end
        renderFonts(closeX + 5, closeY + 5, closeX + 25, closeY + 25, colors.text, "X", 0, 1, 1)
    end
    
    -- Tabs
    local tabY = windowY + 50
    local tabWidth = windowWidth / 3
    
    for i = 1, 3 do
        local tabX = windowX + (i - 1) * tabWidth
        local tabColor = (windowTab == i) and colors.header or colors.button
        drawBox(tabX, tabY, tabWidth, 35, tabColor)
        
        local tabNames = {"ADD", "LIST", "SETTINGS"}
        renderFonts(tabX + 10, tabY + 8, tabX + tabWidth - 10, tabY + 27, colors.text, tabNames[i], 0, 1, 1)
    end
    
    -- Content area
    local contentY = tabY + 40
    local contentHeight = windowHeight - (contentY - windowY) - 10
    
    if windowTab == 1 then
        drawAddTab(contentY, contentHeight)
    elseif windowTab == 2 then
        drawListTab(contentY, contentHeight)
    elseif windowTab == 3 then
        drawSettingsTab(contentY, contentHeight)
    end
end

function drawAddTab(startY, height)
    local y = startY + 10
    
    -- Name input
    renderFonts(windowX + 10, y, windowX + 100, y + 20, colors.text, "Name:", 0, 1, 1)
    drawBox(windowX + 100, y - 5, windowWidth - 120, 25, colors.bg)
    renderFonts(windowX + 105, y, windowX + windowWidth - 20, y + 20, colors.text, inputName, 0, 1, 1)
    
    y = y + 40
    
    -- Current position
    local px, py, pz = getCharCoordinates(PLAYER_PED)
    renderFonts(windowX + 10, y, windowX + windowWidth - 10, y + 20, colors.success, 
        string.format("Current: X:%.1f Y:%.1f Z:%.1f", px, py, pz), 0, 1, 1)
    
    y = y + 30
    
    -- Add from current button
    drawBox(windowX + 10, y, 200, 30, colors.button)
    renderFonts(windowX + 20, y + 5, windowX + 200, y + 25, colors.text, "Add From Current", 0, 0.9, 1)
    
    y = y + 40
    
    -- Manual coordinates
    renderFonts(windowX + 10, y, windowX + 200, y + 20, colors.text, "Or enter coordinates:", 0, 1, 1)
    
    y = y + 25
    renderFonts(windowX + 10, y, windowX + 50, y + 20, colors.text, "X:", 0, 1, 1)
    drawBox(windowX + 50, y - 5, 100, 25, colors.bg)
    renderFonts(windowX + 55, y, windowX + 145, y + 20, colors.text, inputX, 0, 1, 1)
    
    renderFonts(windowX + 160, y, windowX + 200, y + 20, colors.text, "Y:", 0, 1, 1)
    drawBox(windowX + 200, y - 5, 100, 25, colors.bg)
    renderFonts(windowX + 205, y, windowX + 295, y + 20, colors.text, inputY, 0, 1, 1)
    
    renderFonts(windowX + 310, y, windowX + 350, y + 20, colors.text, "Z:", 0, 1, 1)
    drawBox(windowX + 350, y - 5, 100, 25, colors.bg)
    renderFonts(windowX + 355, y, windowX + 445, y + 20, colors.text, inputZ, 0, 1, 1)
    
    y = y + 30
    
    -- Add by coordinates button
    drawBox(windowX + 10, y, 200, 30, colors.button)
    renderFonts(windowX + 20, y + 5, windowX + 200, y + 25, colors.text, "Add By Coordinates", 0, 0.9, 1)
end

function drawListTab(startY, height)
    local y = startY + 10
    local px, py, pz = getCharCoordinates(PLAYER_PED)
    
    if #treasureMarkers == 0 then
        renderFonts(windowX + 10, y, windowX + windowWidth - 10, y + 20, colors.warning, "No markers!", 0, 1, 1)
        return
    end
    
    for i, mark in ipairs(treasureMarkers) do
        if y > startY + height - 40 then break end
        
        local dist = getDistance(px, py, pz, mark.x, mark.y, mark.z)
        renderFonts(windowX + 10, y, windowX + windowWidth - 10, y + 20, colors.success, 
            string.format("[%d] %s (%.1f m)", i, mark.name, dist), 0, 1, 1)
        
        renderFonts(windowX + 20, y + 20, windowX + windowWidth - 10, y + 35, colors.text, 
            string.format("X:%.1f Y:%.1f Z:%.1f", mark.x, mark.y, mark.z), 0, 0.8, 1)
        
        -- Delete button
        drawBox(windowX + windowWidth - 100, y + 15, 90, 25, colors.error)
        renderFonts(windowX + windowWidth - 95, y + 20, windowX + windowWidth - 15, y + 35, colors.text, "Delete", 0, 0.9, 1)
        
        y = y + 50
    end
end

function drawSettingsTab(startY, height)
    local y = startY + 10
    
    -- Render distance
    renderFonts(windowX + 10, y, windowX + 200, y + 20, colors.text, "Render Distance (0 = all):", 0, 1, 1)
    drawBox(windowX + 250, y - 5, 100, 25, colors.bg)
    renderFonts(windowX + 255, y, windowX + 345, y + 20, colors.text, tostring(renderDist), 0, 1, 1)
    
    y = y + 40
    
    -- Icon ID
    renderFonts(windowX + 10, y, windowX + 200, y + 20, colors.text, "Icon ID:", 0, 1, 1)
    drawBox(windowX + 250, y - 5, 100, 25, colors.bg)
    renderFonts(windowX + 255, y, windowX + 345, y + 20, colors.text, tostring(iconId), 0, 1, 1)
    
    y = y + 40
    
    -- Save button
    drawBox(windowX + 10, y, 150, 30, colors.success)
    renderFonts(windowX + 20, y + 5, windowX + 150, y + 25, colors.text, "Save", 0, 1, 1)
    
    -- Clear button
    drawBox(windowX + 170, y, 150, 30, colors.error)
    renderFonts(windowX + 180, y + 5, windowX + 310, y + 25, colors.text, "Clear All", 0, 1, 1)
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

    lua_thread.create(function()
        while true do
            wait(0)
            drawWindow()
        end
    end)

    sampRegisterChatCommand("klua", function()
        showWindow = not showWindow
    end)

    sampRegisterChatCommand("kadd", function(arg)
        local name = arg ~= "" and arg or "Klad #" .. (#treasureMarkers + 1)
        local x, y, z = getCharCoordinates(PLAYER_PED)
        
        if isMarkerNearby(x, y, z, 10.0) then
            sampAddChatMessage("{FFFF00}[Klad] {FFFFFF}Too close to existing marker!", -1)
            return
        end
        
        addTreasureMarker(name, x, y, z)
        sampAddChatMessage("{00FF00}[Klad] {FFFFFF}Marker added!", -1)
    end)

    sampRegisterChatCommand("kdel", function()
        if #treasureMarkers == 0 then
            sampAddChatMessage("{FF0000}[Klad] {FFFFFF}No markers!", -1)
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
            sampAddChatMessage("{00FF00}[Klad] {FFFFFF}Marker deleted!", -1)
        end
    end)

    wait(-1)
end

function sampev.onServerMessage(color, text)
    local myId = getMyPlayerId()
    if not myId then return end
    
    if text:find("begin dig") or text:find("started dig") or text:find("kopay") then
        lua_thread.create(function()
            wait(500)
            if getActiveInterior() ~= 0 then return end

            local x, y, z = getCharCoordinates(PLAYER_PED)
            if x ~= 0 or y ~= 0 then
                if not isMarkerNearby(x, y, z, 10.0) then
                    addTreasureMarker("Found Treasure", x, y, z)
                end
            end
        end)
    end
end
