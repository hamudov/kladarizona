script_name("Klad Aurora")
script_author("hamudov")

require "lib.moonloader"
local sampev = require "samp.events"
local encoding = require "encoding"
encoding.default = 'CP1251'
local u8 = encoding.UTF8

local imgui = require 'imgui'
local sw, sh = getScreenResolution()

local treasureMarkers = {}
local iconId = 41
local renderDist = 0
local saveDir = getWorkingDirectory() .. "\\config"
local savePath = saveDir .. "\\treasure_markers.json"

local showWindow = false
local windowX, windowY = sw / 2 - 300, sh / 2 - 250
local inputName = imgui.ImBuffer(256)
local inputX = imgui.ImBuffer(256)
local inputY = imgui.ImBuffer(256)
local inputZ = imgui.ImBuffer(256)
local selectedMarker = 0
local windowMode = 1

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

function drawWindow()
    if not showWindow then return end
    
    imgui.SetNextWindowSize(imgui.ImVec2(650, 500), imgui.Cond_FirstUseEver)
    
    if imgui.Begin("Klad Manager", showWindow) then
        imgui.Text("Markers: " .. #treasureMarkers)
        imgui.Separator()
        
        if imgui.BeginTabBar("##tabs", imgui.ImGuiTabBarFlags_None) then
            
            if imgui.BeginTabItem("Add") then
                imgui.Text("Add New Marker")
                imgui.InputText("##markerName", inputName, 256)
                
                local px, py, pz = getCharCoordinates(PLAYER_PED)
                imgui.Text(string.format("Current Position: X: %.1f Y: %.1f Z: %.1f", px, py, pz))
                
                if imgui.Button("Add From Current Position", imgui.ImVec2(200, 30)) then
                    addTreasureMarker(inputName.v, px, py, pz)
                    inputName.v = ""
                end
                
                imgui.Separator()
                imgui.Text("Or Add By Coordinates:")
                
                imgui.InputText("X##X", inputX, 256)
                imgui.InputText("Y##Y", inputY, 256)
                imgui.InputText("Z##Z", inputZ, 256)
                
                if imgui.Button("Add By Coordinates", imgui.ImVec2(200, 30)) then
                    local x = tonumber(inputX.v) or 0
                    local y = tonumber(inputY.v) or 0
                    local z = tonumber(inputZ.v) or 0
                    addTreasureMarker(inputName.v, x, y, z)
                    inputName.v = ""
                    inputX.v = ""
                    inputY.v = ""
                    inputZ.v = ""
                end
                
                imgui.EndTabItem()
            end
            
            if imgui.BeginTabItem("List") then
                imgui.Text("All Markers:")
                imgui.Separator()
                
                local px, py, pz = getCharCoordinates(PLAYER_PED)
                
                if imgui.BeginChild("##markersList", imgui.ImVec2(600, 350)) then
                    for i, mark in ipairs(treasureMarkers) do
                        local dist = getDistance(px, py, pz, mark.x, mark.y, mark.z)
                        imgui.Text(string.format("[%d] %s (%.1f m)", i, mark.name, dist))
                        imgui.Text(string.format("    X: %.1f Y: %.1f Z: %.1f", mark.x, mark.y, mark.z))
                        
                        if imgui.Button("Delete##" .. i, imgui.ImVec2(100, 20)) then
                            deleteTreasureMarker(i)
                        end
                        imgui.Separator()
                    end
                    imgui.EndChild()
                end
                
                imgui.EndTabItem()
            end
            
            if imgui.BeginTabItem("Settings") then
                imgui.Text("Settings:")
                imgui.Separator()
                
                local distValue = imgui.ImInt(renderDist)
                if imgui.SliderInt("Render Distance", distValue, 0, 500) then
                    renderDist = distValue.v
                    saveMarkers()
                    refreshAllBlips()
                end
                
                local iconValue = imgui.ImInt(iconId)
                if imgui.SliderInt("Icon ID", iconValue, 1, 100) then
                    iconId = iconValue.v
                    saveMarkers()
                    refreshAllBlips()
                end
                
                if imgui.Button("Clear All Markers", imgui.ImVec2(200, 30)) then
                    for _, mark in ipairs(treasureMarkers) do
                        if mark.blip then
                            removeBlip(mark.blip)
                        end
                    end
                    treasureMarkers = {}
                    saveMarkers()
                end
                
                if imgui.Button("Save", imgui.ImVec2(200, 30)) then
                    saveMarkers()
                end
                
                imgui.EndTabItem()
            end
            
            imgui.EndTabBar()
        end
        
        imgui.End()
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
            return
        end
        
        addTreasureMarker(name, x, y, z)
    end)

    sampRegisterChatCommand("kdel", function()
        if #treasureMarkers == 0 then
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
