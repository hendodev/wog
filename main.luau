print("Game GUI script loaded (WindUI - Fixed ESP + Box ESP with Beams + Rejoin)")

-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local player = game.Players.LocalPlayer
local TeleportService = game:GetService("TeleportService")

-- Function to find object recursively
local function findObjectByName(parent, name)
    if not parent then return nil end
    for _, child in ipairs(parent:GetChildren()) do
        if child.Name == name then
            return child
        end
        local found = findObjectByName(child, name)
        if found then return found end
    end
    return nil
end

-- Create Window
local Window = WindUI:CreateWindow({
    Title = "Leon's WOG - Call +4407957179190 or +4401484541111 ",
    Folder = "GameGUI",
    OpenButton = {
        Enabled = true,
        Draggable = true,
        Title = "Open Game GUI",
    },
})

-- Tabs
local MainTab = Window:Tab({ Title = "Main" })
local ESPTab = Window:Tab({ Title = "ESP" })
local HitboxTab = Window:Tab({ Title = "Hitbox" })

-- Visible top-level Config tab (placed after Hitbox)
local ConfigTab = Window:Tab({ Title = "Config", Icon = "solar:folder-with-files-bold" })
-- Input tab for logs and inputs
local InputTab = Window:Tab({ Title = "Input" })

local ConfigManager = nil
pcall(function() ConfigManager = Window.ConfigManager end)

local ConfigName = "default"

local function refreshConfigList(dropdown)
    if not dropdown then return end
    if ConfigManager and ConfigManager.AllConfigs then
        pcall(function() dropdown:Refresh(ConfigManager:AllConfigs()) end)
    end
end

local ConfigSection = ConfigTab:Section({ Title = "Config Manager" })

local ConfigNameInput = ConfigSection:Input({
    Title = "Config Name",
    Value = ConfigName,
    Callback = function(v) ConfigName = v end,
})

local AllConfigsDropdown = ConfigSection:Dropdown({
    Title = "All Configs",
    Values = (ConfigManager and pcall(function() return ConfigManager:AllConfigs() end) and ConfigManager:AllConfigs()) or {},
    Value = nil,
    Callback = function(v)
        ConfigName = v
        ConfigNameInput:Set(v)
    end
})

ConfigSection:Space()

ConfigSection:Button({
    Title = "Save Config",
    Callback = function()
        if not ConfigManager then
            WindUI:Notify({ Title = "Config", Content = "ConfigManager unavailable" })
            return
        end
        local ok, cfg = pcall(function() return ConfigManager:Config(ConfigName) end)
        if ok and cfg then
            pcall(function()
                cfg:Set("HitboxEnabled", hitboxEnabled)
                cfg:Set("FuselageMultiplier", fuselageMultiplier)
                cfg:Set("WingsMultiplier", wingsMultiplier)
                cfg:Set("FilledESP", filledEspEnabled)
                cfg:Set("BoxESP", boxEspEnabled)
                cfg:Set("LobbyESP", lobbyEspEnabled)
                cfg:Set("SelfBox", selfBoxEnabled)
                cfg:Set("SelfOutline", selfOutlineEnabled)
                cfg:Set("FilledEnemyColor", filledEnemyColor)
                cfg:Set("FilledFriendlyColor", filledFriendlyColor)
                cfg:Set("BoxEnemyColor", boxEnemyColor)
                cfg:Set("BoxFriendlyColor", boxFriendlyColor)
                cfg:Set("SnaplineEnemyColor", snaplineEnemyColor)
                cfg:Set("SnaplineFriendlyColor", snaplineFriendlyColor)
                cfg:Set("SnaplineThickness", snaplineThickness)
                cfg:Save()
            end)
            WindUI:Notify({ Title = "Config", Content = "Saved: " .. tostring(ConfigName) })
            refreshConfigList(AllConfigsDropdown)
        else
            WindUI:Notify({ Title = "Config", Content = "Failed to create config" })
        end
    end
})

ConfigSection:Button({
    Title = "Load Config",
    Callback = function()
        if not ConfigManager then
            WindUI:Notify({ Title = "Config", Content = "ConfigManager unavailable" })
            return
        end
        local ok, cfg = pcall(function() return ConfigManager:CreateConfig(ConfigName) end)
        if ok and cfg then
            local ok2 = pcall(function() cfg:Load() end)
            if ok2 then
                WindUI:Notify({ Title = "Config", Content = "Loaded: " .. tostring(ConfigName) })
                -- try to reapply a few known flags
                pcall(function()
                    hitboxEnabled = cfg:Get("HitboxEnabled") or hitboxEnabled
                    fuselageMultiplier = cfg:Get("FuselageMultiplier") or fuselageMultiplier
                    wingsMultiplier = cfg:Get("WingsMultiplier") or wingsMultiplier
                    filledEspEnabled = cfg:Get("FilledESP") or filledEspEnabled
                    boxEspEnabled = cfg:Get("BoxESP") or boxEspEnabled
                    lobbyEspEnabled = cfg:Get("LobbyESP") or lobbyEspEnabled
                    selfBoxEnabled = cfg:Get("SelfBox") or selfBoxEnabled
                    selfOutlineEnabled = cfg:Get("SelfOutline") or selfOutlineEnabled
                    filledEnemyColor = cfg:Get("FilledEnemyColor") or filledEnemyColor
                    filledFriendlyColor = cfg:Get("FilledFriendlyColor") or filledFriendlyColor
                    boxEnemyColor = cfg:Get("BoxEnemyColor") or boxEnemyColor
                    boxFriendlyColor = cfg:Get("BoxFriendlyColor") or boxFriendlyColor
                    snaplineEnemyColor = cfg:Get("SnaplineEnemyColor") or snaplineEnemyColor
                    snaplineFriendlyColor = cfg:Get("SnaplineFriendlyColor") or snaplineFriendlyColor
                    snaplineThickness = cfg:Get("SnaplineThickness") or snaplineThickness
                end)
                -- reapply visuals
                resetAllHitboxes(); clearFilledESP(); clearBoxESP(); clearLobbyESP(); clearSelfBox(); clearSelfOutline()
                if hitboxEnabled then applyHitboxes() end
                if filledEspEnabled then applyFilledESP() end
                if boxEspEnabled then applyBoxESP() end
                if lobbyEspEnabled then applyLobbyESP() end
                if snaplineEnabled then applySnaplines() end
                if selfBoxEnabled then applySelfBox() end
                if selfOutlineEnabled then applySelfOutline() end
            else
                WindUI:Notify({ Title = "Config", Content = "Failed to load config" })
            end
        end
    end
})

ConfigSection:Button({
    Title = "Delete Config",
    Callback = function()
        if ConfigManager and ConfigManager.Delete then
            pcall(function() ConfigManager:Delete(ConfigName) end)
            refreshConfigList(AllConfigsDropdown)
            WindUI:Notify({ Title = "Config", Content = "Deleted: " .. tostring(ConfigName) })
        else
            WindUI:Notify({ Title = "Config", Content = "Delete not supported" })
        end
    end
})


-- Variables
local fuselageMultiplier = 100
local wingsMultiplier = 100

local hitboxEnabled = false
local hitboxTeamCheck = true

local filledEspEnabled = false
local boxEspEnabled = false
local lobbyEspEnabled = false

local filledHighlights = {}
local boxBeamContainers = {}

local originalSizes = {}

-- ESP Team Check variables
local filledEspTeamCheck = true
local boxEspTeamCheck = true

-- Lobby ESP variables
local previewPlaneHighlight = nil
local previewPlaneBoxFolder = nil

-- Camera FOV control
local fovEnabled = false
local fovValue = 70

-- Snapline (tracer) variables
local snaplineEnabled = false
local snaplineTeamCheck = true
local snaplineContainers = {}
local snaplineThickness = 0.03

-- Self ESP variables
local selfBoxEnabled = false
local selfBoxModel = nil
local selfBoxFolder = nil
local selfOutlineEnabled = false
local selfOutlineHighlight = nil

-- Debugging helpers
local debugESP = false
local loggedBoxCreation = {}

-- ESP color settings (user configurable via UI flags)
local filledEnemyColor = Color3.fromRGB(255, 0, 0)
local filledFriendlyColor = Color3.fromRGB(0, 0, 255)
local boxEnemyColor = Color3.fromRGB(255, 0, 0)
local boxFriendlyColor = Color3.fromRGB(0, 0, 255)
local snaplineEnemyColor = Color3.fromRGB(255, 0, 0)
local snaplineFriendlyColor = Color3.fromRGB(0, 0, 255)
local lobbyBoxColor = Color3.fromRGB(255, 255, 255)
local selfBoxColor = Color3.fromRGB(255, 255, 255)

local rainbowAllEnabled = false
local rainbowTask = nil
local savedUserColors = {}

-- Friends tracking & logs
local friendsSet = {} -- keyed by player name
local friendHighlights = {} -- keyed by player name -> Highlight instance
local friendsLogs = {}
local FriendsLogsInput = nil

-- Cobra Spin state
local cobraSpinEnabled = false
local CobraToggleControl = nil



-- Player folder & Camera
local camera = workspace.CurrentCamera or workspace:FindFirstChild("Camera")
local playerFolder = camera and camera:FindFirstChild("plane_viewmodels")

-- Helper: gather models from both `plane_viewmodels` and camera's `plane_model` (dedupe)
local function getAllPlayerModels()
    local result = {}
    local seen = {}

    if playerFolder then
        for _, child in ipairs(playerFolder:GetChildren()) do
            if child and child:IsA("Model") and not seen[child] then
                table.insert(result, child)
                seen[child] = true
            end
        end
    end

    if camera then
        local pm = camera:FindFirstChild("plane_model")
        if pm then
            for _, child in ipairs(pm:GetChildren()) do
                if child and child:IsA("Model") and not seen[child] then
                    table.insert(result, child)
                    seen[child] = true
                end
            end
        end
    end

    return result
end

-- Helper: return only other players' models (from camera's `plane_viewmodels`).
-- This excludes the local player's `plane_model` so self-only features remain separate.
local function getOtherPlayerModels()
    local result = {}
    if playerFolder then
        for _, child in ipairs(playerFolder:GetChildren()) do
            if child and child:IsA("Model") then
                table.insert(result, child)
            end
        end
    end
    return result
end

-- Teams
local teams = nil
local playerTeamName = nil
pcall(function()
    teams = game:GetService("ReplicatedStorage").GameLogic.teams
end)

local function checkPlayerTeam()
    if not teams then return end
    playerTeamName = nil
    for _, teamName in ipairs({"Blue", "Red"}) do
        if teams[teamName] and teams[teamName]:FindFirstChild(player.Name) then
            playerTeamName = teamName
            break
        end
    end
end
checkPlayerTeam()

-- Function to get model oriented bounding box
local function getModelOrientedBounds(model)
    if not model then return nil, nil, nil end

    -- Choose a reference part: prefer PrimaryPart, otherwise pick the largest BasePart by volume
    local referencePart = model.PrimaryPart
    if not referencePart then
        local bestPart = nil
        local bestVol = 0
        for _, part in ipairs(model:GetDescendants()) do
            if part:IsA("BasePart") then
                local vol = math.abs(part.Size.X * part.Size.Y * part.Size.Z)
                if vol > bestVol then
                    bestVol = vol
                    bestPart = part
                end
            end
        end
        referencePart = bestPart
    end

    if not referencePart then return nil, nil, nil end

    if debugESP and not referencePart then
        warn("getModelOrientedBounds: no reference part for model:", model and model:GetFullName())
    end

    local minX, minY, minZ = math.huge, math.huge, math.huge
    local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge

    -- Calculate bounding box in reference part's local space
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            local localCF = referencePart.CFrame:Inverse() * part.CFrame
            local size = part.Size
            for _, dx in ipairs({-1, 1}) do
                for _, dy in ipairs({-1, 1}) do
                    for _, dz in ipairs({-1, 1}) do
                        local corner = localCF * CFrame.new(dx * size.X / 2, dy * size.Y / 2, dz * size.Z / 2)
                        local pos = corner.Position
                        minX = math.min(minX, pos.X)
                        minY = math.min(minY, pos.Y)
                        minZ = math.min(minZ, pos.Z)
                        maxX = math.max(maxX, pos.X)
                        maxY = math.max(maxY, pos.Y)
                        maxZ = math.max(maxZ, pos.Z)
                    end
                end
            end
        end
    end

    if minX == math.huge then return nil, nil, nil end

    local localCenter = Vector3.new((minX + maxX) / 2, (minY + maxY) / 2, (minZ + maxZ) / 2)
    local localSize = Vector3.new(maxX - minX, maxY - minY, maxZ - minZ)

    return referencePart.CFrame, localCenter, localSize
end

-- Store original size if not already stored
local function storeOriginalIfNeeded(part)
    if part and part:IsA("BasePart") and not originalSizes[part] then
        originalSizes[part] = part.Size
    end
end

-- HITBOX FUNCTIONS
local function resetAllHitboxes()
    for part, orig in pairs(originalSizes) do
        if part and part.Parent then
            part.Size = orig
        end
    end
end

local function applyHitboxes()
    if not hitboxEnabled then return end

    for _, child in ipairs(getOtherPlayerModels()) do
        if child and child:IsA("Model") then
            -- Skip friends from hitbox modifications
            if friendsSet[child.Name] then
                continue
            end
            local isEnemy = not (playerTeamName and teams and teams[playerTeamName] and teams[playerTeamName]:FindFirstChild(child.Name))

            if hitboxTeamCheck and not isEnemy then continue end

            local fuselage = child:FindFirstChild("Fuselage", true)
            if fuselage then
                storeOriginalIfNeeded(fuselage)
                fuselage.Size = originalSizes[fuselage] * (fuselageMultiplier / 100)
            end

            local leftWing = child:FindFirstChild("LeftWing", true)
            if leftWing then
                storeOriginalIfNeeded(leftWing)
                leftWing.Size = originalSizes[leftWing] * (wingsMultiplier / 100)
            end

            local rightWing = child:FindFirstChild("RightWing", true)
            if rightWing then
                storeOriginalIfNeeded(rightWing)
                rightWing.Size = originalSizes[rightWing] * (wingsMultiplier / 100)
            end
        end
    end
end

-- FILLED ESP FUNCTIONS
local function clearFilledESP()
    for _, hl in ipairs(filledHighlights) do
        if hl then hl:Destroy() end
    end
    filledHighlights = {}
end

local function applyFilledESP()
    clearFilledESP()

    for _, child in ipairs(getOtherPlayerModels()) do
        if child and child:IsA("Model") then
            local isEnemy = not (playerTeamName and teams and teams[playerTeamName] and teams[playerTeamName]:FindFirstChild(child.Name))
            local shouldShow = filledEspTeamCheck and isEnemy or not filledEspTeamCheck
            if shouldShow then
                local hl = Instance.new("Highlight")
                hl.Adornee = child
                if friendsSet[child.Name] then
                    hl.FillColor = Color3.fromRGB(0, 170, 255) -- friends: bright blue
                else
                    hl.FillColor = isEnemy and filledEnemyColor or filledFriendlyColor
                end
                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                hl.FillTransparency = 0.5
                hl.OutlineTransparency = 0
                hl.Enabled = true
                hl.Parent = child
                table.insert(filledHighlights, hl)
                if friendsSet[child.Name] then
                    friendHighlights[child.Name] = hl
                end
            end
        end
    end
end

-- BOX ESP FUNCTIONS
local function createBoxAroundModel(model)
    if not model then
        warn("Box ESP: Model is nil")
        return nil
    end
    local folder = Instance.new("Folder")
    folder.Name = "BoxESP"
    folder.Parent = workspace

    local edges = {
        {1,2}, {2,3}, {3,4}, {4,1},
        {5,6}, {6,7}, {7,8}, {8,5},
        {1,5}, {2,6}, {3,7}, {4,8},
    }

    -- Determine team status for coloring
    local isEnemy = not (playerTeamName and teams and teams[playerTeamName] and teams[playerTeamName]:FindFirstChild(model.Name))
    local edgeColor = isEnemy and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 0, 255)

    -- Create 8 invisible corner parts with attachments so beams anchor to real Parts
    local cornerParts = {}
    for i = 1, 8 do
        local p = Instance.new("Part")
        p.Name = "Corner" .. i
        p.Size = Vector3.new(0.2, 0.2, 0.2)
        p.Transparency = 1
        p.CanCollide = false
        p.Anchored = true
        p.CastShadow = false
        p.Parent = folder

        local att = Instance.new("Attachment")
        att.Name = "Att" .. i
        att.Parent = p

        cornerParts[i] = p
    end

    -- Create solid Neon connector parts for each edge for reliable visibility
    local edgeParts = {}
    for _, edge in ipairs(edges) do
        local epart = Instance.new("Part")
        epart.Name = "Edge_" .. edge[1] .. "_" .. edge[2]
        epart.Anchored = true
        epart.CanCollide = false
        epart.Transparency = 0
        epart.Material = Enum.Material.Neon
        epart.Size = Vector3.new(0.03, 0.03, 0.03) -- slimmer lines
        epart.Parent = folder

        -- store edge endpoints as attributes
        epart:SetAttribute("Edge1", edge[1])
        epart:SetAttribute("Edge2", edge[2])

        epart:SetAttribute("IsVertical", (edge[1] == 1 and edge[2] == 5) or (edge[1] == 2 and edge[2] == 6) or (edge[1] == 3 and edge[2] == 7) or (edge[1] == 4 and edge[2] == 8))

        -- color
        epart.Color = edgeColor

        edgeParts[#edgeParts + 1] = epart
    end

    if debugESP then
        pcall(function()
            print("createBoxAroundModel -> created box for:", model and model:GetFullName())
        end)
    end

    return folder
end

local function updateBoxPositions()
    for model, folder in pairs(boxBeamContainers) do
        if model and model.Parent and folder and folder.Parent then
            -- Get oriented bounds (follows plane rotation)
            local modelCF, localCenter, localSize = getModelOrientedBounds(model)
            
            if not modelCF then
                if debugESP then
                    pcall(function()
                        warn("Box ESP update failed for model:", model:GetFullName())
                    end)
                else
                    warn("Box ESP update failed for model:", model.Name)
                end
                continue
            end
            
            -- Add spacing
            localSize = localSize * 1.2
            
            -- Create corners in local space
            local localCorners = {
                CFrame.new(localCenter + Vector3.new(-localSize.X/2, -localSize.Y/2, -localSize.Z/2)),
                CFrame.new(localCenter + Vector3.new( localSize.X/2, -localSize.Y/2, -localSize.Z/2)),
                CFrame.new(localCenter + Vector3.new( localSize.X/2,  localSize.Y/2, -localSize.Z/2)),
                CFrame.new(localCenter + Vector3.new(-localSize.X/2,  localSize.Y/2, -localSize.Z/2)),
                CFrame.new(localCenter + Vector3.new(-localSize.X/2, -localSize.Y/2,  localSize.Z/2)),
                CFrame.new(localCenter + Vector3.new( localSize.X/2, -localSize.Y/2,  localSize.Z/2)),
                CFrame.new(localCenter + Vector3.new( localSize.X/2,  localSize.Y/2,  localSize.Z/2)),
                CFrame.new(localCenter + Vector3.new(-localSize.X/2,  localSize.Y/2,  localSize.Z/2)),
            }
            
            -- Transform to world space and move corner parts
            local worldCorners = {}
            for i, localCF in ipairs(localCorners) do
                worldCorners[i] = modelCF * localCF
            end

            -- Move corner Parts if present under folder
            for i = 1, 8 do
                local cornerPart = folder:FindFirstChild("Corner" .. i)
                if cornerPart and cornerPart:IsA("BasePart") then
                    cornerPart.CFrame = worldCorners[i]
                else
                    -- Fallback: move attachment directly if no corner part
                    for _, att in ipairs(folder:GetChildren()) do
                        if att:IsA("Attachment") and att.Name == ("Att" .. i) then
                            att.WorldCFrame = worldCorners[i]
                        end
                    end
                end
            end

            -- Update edge parts positions/sizes
            for _, epart in ipairs(folder:GetChildren()) do
                if epart:IsA("BasePart") and epart.Name:match("^Edge_%d+_%d+") then
                    local e1 = epart:GetAttribute("Edge1")
                    local e2 = epart:GetAttribute("Edge2")
                    local isVertical = epart:GetAttribute("IsVertical")
                    if e1 and e2 and worldCorners[e1] and worldCorners[e2] then
                        local p1 = worldCorners[e1].Position
                        local p2 = worldCorners[e2].Position
                        local mid = (p1 + p2) / 2
                        local dir = p2 - p1
                        local len = dir.Magnitude
                        if len > 0 then
                            -- thickness: slimmer lines
                            local thickness = isVertical and 0.06 or 0.03
                            -- Use Z axis for length so CFrame.new(mid, p2) aligns correctly
                            epart.Size = Vector3.new(thickness, thickness, len)
                            epart.CFrame = CFrame.new(mid, p2)
                        end
                    end
                end
            end
        else
            -- Clean up invalid entries
            if folder then folder:Destroy() end
            boxBeamContainers[model] = nil
        end
    end
end

local function clearBoxESP()
    for model, folder in pairs(boxBeamContainers) do
        if folder then folder:Destroy() end
    end
    boxBeamContainers = {}
end

local function applyBoxESP()
    clearBoxESP()

    for _, child in ipairs(getOtherPlayerModels()) do
        if child and child:IsA("Model") then
            local isEnemy = not (playerTeamName and teams and teams[playerTeamName] and teams[playerTeamName]:FindFirstChild(child.Name))
            local shouldShow = boxEspTeamCheck and isEnemy or not boxEspTeamCheck
            if shouldShow then
                local container = createBoxAroundModel(child)
                if container then
                    -- apply chosen colors to edges (friends get dedicated blue color)
                    local colorToUse = friendsSet[child.Name] and Color3.fromRGB(0, 170, 255) or ((isEnemy and boxEnemyColor) or boxFriendlyColor)
                    for _, epart in ipairs(container:GetChildren()) do
                        if epart:IsA("BasePart") and epart.Name:match("^Edge_%d+_%d+") then
                            epart.Color = colorToUse
                        end
                    end
                    boxBeamContainers[child] = container
                    if debugESP and not loggedBoxCreation[child] then
                        pcall(function()
                            print("applyBoxESP -> added box for:", child and child:GetFullName())
                        end)
                        loggedBoxCreation[child] = true
                    end
                end
            end
        end
    end
end

-- LOBBY ESP FUNCTIONS
local function getModelBounds(model)
    -- Get the actual bounding box of all parts in the model
    local minX, minY, minZ = math.huge, math.huge, math.huge
    local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
    
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            local cf = part.CFrame
            local size = part.Size
            
            -- Get all 8 corners of this part
            local corners = {
                cf * CFrame.new(-size.X/2, -size.Y/2, -size.Z/2),
                cf * CFrame.new( size.X/2, -size.Y/2, -size.Z/2),
                cf * CFrame.new( size.X/2,  size.Y/2, -size.Z/2),
                cf * CFrame.new(-size.X/2,  size.Y/2, -size.Z/2),
                cf * CFrame.new(-size.X/2, -size.Y/2,  size.Z/2),
                cf * CFrame.new( size.X/2, -size.Y/2,  size.Z/2),
                cf * CFrame.new( size.X/2,  size.Y/2,  size.Z/2),
                cf * CFrame.new(-size.X/2,  size.Y/2,  size.Z/2),
            }
            
            for _, corner in ipairs(corners) do
                local pos = corner.Position
                minX = math.min(minX, pos.X)
                minY = math.min(minY, pos.Y)
                minZ = math.min(minZ, pos.Z)
                maxX = math.max(maxX, pos.X)
                maxY = math.max(maxY, pos.Y)
                maxZ = math.max(maxZ, pos.Z)
            end
        end
    end
    
    local center = Vector3.new((minX + maxX)/2, (minY + maxY)/2, (minZ + maxZ)/2)
    local size = Vector3.new(maxX - minX, maxY - minY, maxZ - minZ)
    
    return center, size
end

local function createGlowingBoxAroundModel(model)
    if not model then 
        warn("Lobby Box: Model is nil")
        return nil
    end

    local folder = Instance.new("Folder")
    folder.Name = "GlowingBoxESP"
    folder.Parent = workspace

    local edges = {
        {1,2}, {2,3}, {3,4}, {4,1},
        {5,6}, {6,7}, {7,8}, {8,5},
        {1,5}, {2,6}, {3,7}, {4,8},
    }

    -- Create 8 invisible corner parts with attachments for lobby box too
    local cornerParts = {}
    for i = 1, 8 do
        local p = Instance.new("Part")
        p.Name = "Corner" .. i
        p.Size = Vector3.new(0.2, 0.2, 0.2)
        p.Transparency = 1
        p.CanCollide = false
        p.Anchored = true
        p.CastShadow = false
        p.Parent = folder

        local att = Instance.new("Attachment")
        att.Name = "Att" .. i
        att.Parent = p

        cornerParts[i] = p
    end
    -- Create Neon edge parts for lobby box
    for _, edge in ipairs(edges) do
        local epart = Instance.new("Part")
        epart.Name = "Edge_" .. edge[1] .. "_" .. edge[2]
        epart.Anchored = true
        epart.CanCollide = false
        epart.Transparency = 0
        epart.Material = Enum.Material.Neon
        epart.Size = Vector3.new(0.03, 0.03, 0.03) -- slimmer lobby lines
        epart.Parent = folder

        epart:SetAttribute("Edge1", edge[1])
        epart:SetAttribute("Edge2", edge[2])
        epart:SetAttribute("IsVertical", (edge[1] == 1 and edge[2] == 5) or (edge[1] == 2 and edge[2] == 6) or (edge[1] == 3 and edge[2] == 7) or (edge[1] == 4 and edge[2] == 8))
        epart.Color = lobbyBoxColor
    end

    print("Created", #edges, "beams for lobby box")
    return folder
end

local function updateLobbyBoxPositions()
    if not previewPlaneBoxFolder then return end
    
    local previewPlane = workspace:FindFirstChild("preview_plane")
    if not previewPlane then return end
    
    local planeModel = nil
    for _, child in ipairs(previewPlane:GetChildren()) do
        if child:IsA("Model") then
            planeModel = child
            break
        end
    end
    
    if not planeModel then return end
    
    -- Get oriented bounds (follows plane rotation)
    local modelCF, localCenter, localSize = getModelOrientedBounds(planeModel)
    
    if not modelCF then 
        warn("Lobby ESP update failed")
        return 
    end
    
    -- Add spacing
    localSize = localSize * 1.3  -- Slightly bigger for visibility
    
    -- Create corners in local space, then transform to world space
    local localCorners = {
        CFrame.new(localCenter + Vector3.new(-localSize.X/2, -localSize.Y/2, -localSize.Z/2)),
        CFrame.new(localCenter + Vector3.new( localSize.X/2, -localSize.Y/2, -localSize.Z/2)),
        CFrame.new(localCenter + Vector3.new( localSize.X/2,  localSize.Y/2, -localSize.Z/2)),
        CFrame.new(localCenter + Vector3.new(-localSize.X/2,  localSize.Y/2, -localSize.Z/2)),
        CFrame.new(localCenter + Vector3.new(-localSize.X/2, -localSize.Y/2,  localSize.Z/2)),
        CFrame.new(localCenter + Vector3.new( localSize.X/2, -localSize.Y/2,  localSize.Z/2)),
        CFrame.new(localCenter + Vector3.new( localSize.X/2,  localSize.Y/2,  localSize.Z/2)),
        CFrame.new(localCenter + Vector3.new(-localSize.X/2,  localSize.Y/2,  localSize.Z/2)),
    }
    
    -- Transform to world space
    local worldCorners = {}
    for i, localCF in ipairs(localCorners) do
        worldCorners[i] = modelCF * localCF
    end

    -- Move corner parts if present under previewPlaneBoxFolder
    for i = 1, 8 do
        local cornerPart = previewPlaneBoxFolder:FindFirstChild("Corner" .. i)
        if cornerPart and cornerPart:IsA("BasePart") then
            cornerPart.CFrame = worldCorners[i]
        else
            for _, att in ipairs(previewPlaneBoxFolder:GetChildren()) do
                if att:IsA("Attachment") and att.Name == ("Att" .. i) then
                    att.WorldCFrame = worldCorners[i]
                end
            end
        end
    end

    -- Update Neon edge parts positions/sizes for lobby
    for _, epart in ipairs(previewPlaneBoxFolder:GetChildren()) do
        if epart:IsA("BasePart") and epart.Name:match("^Edge_%d+_%d+") then
            local e1 = epart:GetAttribute("Edge1")
            local e2 = epart:GetAttribute("Edge2")
            if e1 and e2 and worldCorners[e1] and worldCorners[e2] then
                local p1 = worldCorners[e1].Position
                local p2 = worldCorners[e2].Position
                local mid = (p1 + p2) / 2
                local dir = p2 - p1
                local len = dir.Magnitude
                if len > 0 then
                    epart.Size = Vector3.new(epart.Size.X, epart.Size.Y, len)
                    epart.CFrame = CFrame.new(mid, p2)
                end
            end
        end
    end
    -- Ensure lobby edge parts remain white neon (no rainbow animation)
    for _, epart in ipairs(previewPlaneBoxFolder:GetChildren()) do
        if epart:IsA("BasePart") and epart.Name:match("^Edge_%d+_%d+") then
            epart.Color = Color3.fromRGB(255, 255, 255)
        end
    end
end

local function clearLobbyESP()
    if previewPlaneHighlight then
        previewPlaneHighlight:Destroy()
        previewPlaneHighlight = nil
    end
    
    if previewPlaneBoxFolder then
        previewPlaneBoxFolder:Destroy()
        previewPlaneBoxFolder = nil
    end
end

local function applyLobbyESP()
    clearLobbyESP()
    
    local previewPlane = workspace:FindFirstChild("preview_plane")
    if not previewPlane then return end
    
    local planeModel = nil
    for _, child in ipairs(previewPlane:GetChildren()) do
        if child:IsA("Model") then
            planeModel = child
            break
        end
    end
    
    if not planeModel then return end
    
    previewPlaneHighlight = Instance.new("Highlight")
    previewPlaneHighlight.Adornee = planeModel
    -- Outline-only highlight: no fill, white outline
    previewPlaneHighlight.FillTransparency = 1
    previewPlaneHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    previewPlaneHighlight.OutlineTransparency = 0
    previewPlaneHighlight.Enabled = true
    previewPlaneHighlight.Parent = planeModel
    
    previewPlaneBoxFolder = createGlowingBoxAroundModel(planeModel)
end

-- SNAPLINE (TRACERS) FUNCTIONS
local function getLocalFuselage()
    local cam = workspace.CurrentCamera or workspace:FindFirstChild("Camera")
    if not cam then return nil, nil end
    local pm = cam:FindFirstChild("plane_model")

    -- Prefer any model inside plane_model that contains a Fuselage
    if pm then
        for _, candidate in ipairs(pm:GetChildren()) do
            if candidate and candidate:IsA("Model") then
                local fus = candidate:FindFirstChild("Fuselage", true)
                if fus and fus:IsA("BasePart") then
                    return fus, candidate
                end
            end
        end
    end

    -- Fallback: look in playerFolder for player's model with a Fuselage
    if playerFolder then
        for _, candidate in ipairs(playerFolder:GetChildren()) do
            if candidate and candidate:IsA("Model") and candidate.Name == player.Name then
                local fus2 = candidate:FindFirstChild("Fuselage", true)
                if fus2 and fus2:IsA("BasePart") then
                    return fus2, candidate
                end
            end
        end
        -- Final fallback: any model under playerFolder that has a Fuselage
        for _, candidate in ipairs(playerFolder:GetChildren()) do
            if candidate and candidate:IsA("Model") then
                local fus2 = candidate:FindFirstChild("Fuselage", true)
                if fus2 and fus2:IsA("BasePart") then
                    return fus2, candidate
                end
            end
        end
    end

    return nil, nil
end

local function clearSnaplines()
    for model, folder in pairs(snaplineContainers) do
        if folder then
            -- destroy attachments referenced inside folder (ObjectValues)
            for _, v in ipairs(folder:GetChildren()) do
                if v:IsA("ObjectValue") and v.Value and v.Value:IsA("Attachment") then
                    pcall(function() v.Value:Destroy() end)
                end
            end
            folder:Destroy()
        end
        snaplineContainers[model] = nil
    end
    snaplineContainers = {}
    -- Extra cleanup: ensure no lingering Snap_Beam, Snap_Att* attachments or folders
    for _, inst in ipairs(workspace:GetDescendants()) do
        if inst:IsA("Beam") and inst.Name == "Snap_Beam" then
            pcall(function() inst:Destroy() end)
        elseif inst:IsA("Attachment") and tostring(inst.Name):match("^Snap_Att") then
            pcall(function() inst:Destroy() end)
        elseif inst:IsA("Folder") and tostring(inst.Name):match("^Snapline_") then
            pcall(function() inst:Destroy() end)
        end
    end
end

local function createSnaplineBetween(localFus, targetFus, targetModel)
    if not localFus or not targetFus or not targetModel then return nil end

    local folder = Instance.new("Folder")
    folder.Name = "Snapline_" .. tostring(targetModel.Name)
    folder.Parent = workspace

    -- Create attachments parented to each fuselage part (unique names)
    local att0 = Instance.new("Attachment")
    att0.Name = "Snap_Att0_" .. tostring(targetModel.Name)
    att0.Parent = localFus
    att0.Position = Vector3.new(0, -localFus.Size.Y/2, 0)

    local att1 = Instance.new("Attachment")
    att1.Name = "Snap_Att1_" .. tostring(targetModel.Name)
    att1.Parent = targetFus
    att1.Position = Vector3.new(0, -targetFus.Size.Y/2, 0)

    -- Keep references so we can clean them up later
    local ref0 = Instance.new("ObjectValue")
    ref0.Name = "Ref_Att0"
    ref0.Value = att0
    ref0.Parent = folder

    local ref1 = Instance.new("ObjectValue")
    ref1.Name = "Ref_Att1"
    ref1.Value = att1
    ref1.Parent = folder

    -- Create beam
    local beam = Instance.new("Beam")
    beam.Name = "Snap_Beam"
    beam.Attachment0 = att0
    beam.Attachment1 = att1
    beam.Width0 = snaplineThickness
    beam.Width1 = snaplineThickness
    beam.FaceCamera = false
    beam.LightEmission = 1
    beam.Transparency = NumberSequence.new(0)
    beam.Parent = folder

    return folder, beam
end

local function applySnaplines()
    clearSnaplines()

    if not playerFolder then return end

    local localFus, localModel = getLocalFuselage()
    if not localFus then
        warn("Snaplines: local fuselage not found")
        return
    end

    for _, child in ipairs(getOtherPlayerModels()) do
        if child and child:IsA("Model") then
            if child == localModel then continue end

            local targetFus = child:FindFirstChild("Fuselage", true)
            if not (targetFus and targetFus:IsA("BasePart")) then continue end

            local isEnemy = not (playerTeamName and teams and teams[playerTeamName] and teams[playerTeamName]:FindFirstChild(child.Name))
            local shouldShow = snaplineTeamCheck and isEnemy or not snaplineTeamCheck
            -- Skip snaplines for friends
            if friendsSet[child.Name] then continue end
            if not shouldShow then continue end

            local folder, beam = createSnaplineBetween(localFus, targetFus, child)
            if folder and beam then
                local edgeColor = isEnemy and snaplineEnemyColor or snaplineFriendlyColor
                beam.Color = ColorSequence.new(edgeColor)
                snaplineContainers[child] = folder
            end
        end
    end
end

-- SELF ESP FUNCTIONS
local function clearSelfBox()
    if selfBoxFolder then
        pcall(function() if type(selfBoxFolder) == "table" and selfBoxFolder.Container then selfBoxFolder.Container:Destroy() elseif selfBoxFolder.Destroy then selfBoxFolder:Destroy() end end)
    end
    selfBoxFolder = nil
end

local function getPlayerPlaneModel()
    local cam = workspace.CurrentCamera or workspace:FindFirstChild("Camera")
    if not cam then
        if debugESP then warn("No camera found") end
        return nil
    end

    local planeModelFolder = cam:FindFirstChild("plane_model")
    if not planeModelFolder then
        if debugESP then warn("No plane_model folder found") end
        return nil
    end

    for _, child in ipairs(planeModelFolder:GetChildren()) do
        if child and child:IsA("Model") then
            if debugESP then pcall(function() print("Found plane model in camera:", child.Name) end) end
            return child
        end
    end

    return nil
end

local function applySelfBox()
    clearSelfBox()

    local playerModel = getPlayerPlaneModel()
    if not playerModel then
        if debugESP then warn("Could not find player plane model for Self Box") end
        return
    end

    local folder = Instance.new("Folder")
    folder.Name = "SelfBoxESP"
    folder.Parent = workspace

    local edges = {
        {1,2}, {2,3}, {3,4}, {4,1},
        {5,6}, {6,7}, {7,8}, {8,5},
        {1,5}, {2,6}, {3,7}, {4,8},
    }

    for i = 1, 8 do
        local p = Instance.new("Part")
        p.Name = "SelfCorner" .. i
        p.Size = Vector3.new(0.2, 0.2, 0.2)
        p.Transparency = 1
        p.CanCollide = false
        p.Anchored = true
        p.CastShadow = false
        p.Parent = folder
    end

    for _, edge in ipairs(edges) do
        local epart = Instance.new("Part")
        epart.Name = "SelfEdge_" .. edge[1] .. "_" .. edge[2]
        epart.Anchored = true
        epart.CanCollide = false
        epart.Transparency = 0
        epart.Material = Enum.Material.Neon
        epart.Size = Vector3.new(0.03, 0.03, 0.03)
        epart.Color = selfBoxColor
        epart.Parent = folder

        epart:SetAttribute("Edge1", edge[1])
        epart:SetAttribute("Edge2", edge[2])
        epart:SetAttribute("IsVertical", (edge[1] == 1 and edge[2] == 5) or (edge[1] == 2 and edge[2] == 6) or (edge[1] == 3 and edge[2] == 7) or (edge[1] == 4 and edge[2] == 8))
    end

    selfBoxFolder = {
        Container = folder,
        Model = playerModel,
    }

    if debugESP then pcall(function() print("Self Box created for player's plane model") end) end
end

local function updateSelfBox()
    if not selfBoxFolder or not selfBoxFolder.Container or not selfBoxFolder.Container.Parent then
        return
    end

    local playerModel = getPlayerPlaneModel()
    if not playerModel then
        clearSelfBox()
        return
    end

    selfBoxFolder.Model = playerModel

    local modelCF, localCenter, localSize = getModelOrientedBounds(playerModel)
    if not modelCF then
        if debugESP then warn("Could not get bounds for Self Box") end
        return
    end

    localSize = localSize * 1.2

    local localCorners = {
        CFrame.new(localCenter + Vector3.new(-localSize.X/2, -localSize.Y/2, -localSize.Z/2)),
        CFrame.new(localCenter + Vector3.new( localSize.X/2, -localSize.Y/2, -localSize.Z/2)),
        CFrame.new(localCenter + Vector3.new( localSize.X/2,  localSize.Y/2, -localSize.Z/2)),
        CFrame.new(localCenter + Vector3.new(-localSize.X/2,  localSize.Y/2, -localSize.Z/2)),
        CFrame.new(localCenter + Vector3.new(-localSize.X/2, -localSize.Y/2,  localSize.Z/2)),
        CFrame.new(localCenter + Vector3.new( localSize.X/2, -localSize.Y/2,  localSize.Z/2)),
        CFrame.new(localCenter + Vector3.new( localSize.X/2,  localSize.Y/2,  localSize.Z/2)),
        CFrame.new(localCenter + Vector3.new(-localSize.X/2,  localSize.Y/2,  localSize.Z/2)),
    }

    local worldCorners = {}
    for i, localCF in ipairs(localCorners) do
        worldCorners[i] = modelCF * localCF
    end

    for i = 1, 8 do
        local cornerPart = selfBoxFolder.Container:FindFirstChild("SelfCorner" .. i)
        if cornerPart and cornerPart:IsA("BasePart") then
            cornerPart.CFrame = worldCorners[i]
        end
    end

    for _, epart in ipairs(selfBoxFolder.Container:GetChildren()) do
        if epart:IsA("BasePart") and epart.Name:match("^SelfEdge_%d+_%d+") then
            local e1 = epart:GetAttribute("Edge1")
            local e2 = epart:GetAttribute("Edge2")
            local isVertical = epart:GetAttribute("IsVertical")
            if e1 and e2 and worldCorners[e1] and worldCorners[e2] then
                local p1 = worldCorners[e1].Position
                local p2 = worldCorners[e2].Position
                local mid = (p1 + p2) / 2
                local dir = p2 - p1
                local len = dir.Magnitude
                if len > 0 then
                    local thickness = isVertical and 0.06 or 0.03
                    epart.Size = Vector3.new(thickness, thickness, len)
                    epart.CFrame = CFrame.new(mid, p2)
                    epart.Color = Color3.fromRGB(255, 255, 255)
                end
            end
        end
    end
end

local function clearSelfOutline()
    if selfOutlineHighlight then
        pcall(function() selfOutlineHighlight:Destroy() end)
        selfOutlineHighlight = nil
    end
    selfOutlineEnabled = false
end

local function applySelfOutline()
    clearSelfOutline()
    local _, localModel = getLocalFuselage()
    if not localModel then return end
    local hl = Instance.new("Highlight")
    hl.Adornee = localModel
    hl.FillTransparency = 1
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.OutlineTransparency = 0
    hl.Enabled = true
    hl.Parent = localModel
    selfOutlineHighlight = hl
    selfOutlineEnabled = true
end


-- UI CONTROLS
-- Camera controls (FOV lock)
MainTab:Section({ Title = "Camera" })

-- Helper: find AlignOrientation named 'Gyro' under camera.plane_model (robust search)
local function findGyroAlignOrientation()
    local cam = workspace.CurrentCamera or workspace:FindFirstChild("Camera")
    if not cam then return nil end
    local pm = cam:FindFirstChild("plane_model")
    if not pm then return nil end
    for _, desc in ipairs(pm:GetDescendants()) do
        if desc and desc:IsA("AlignOrientation") and desc.Name == "Gyro" then
            return desc
        end
    end
    return nil
end

local function setCobraSpinEnabled(state)
    cobraSpinEnabled = state
    local ok, gyro = pcall(findGyroAlignOrientation)
    if ok and gyro and gyro:IsA("AlignOrientation") then
        pcall(function() gyro.PrimaryAxisOnly = state end)
    end
    -- update UI toggle control if available
    if CobraToggleControl and CobraToggleControl.Set then
        pcall(function() CobraToggleControl:Set(state) end)
    end
end

-- Friends scanning and logging
local Players = game:GetService("Players")
local function appendFriendLog(msg)
    local entry = "[+] " .. os.date("%X") .. " - " .. tostring(msg)
    table.insert(friendsLogs, entry)
    if #friendsLogs > 200 then table.remove(friendsLogs, 1) end
    if FriendsLogsInput and FriendsLogsInput.Set then
        pcall(function() FriendsLogsInput:Set(table.concat(friendsLogs, "\n")) end)
    end
end

local function updateFriendsScan()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            local isFriend = false
            pcall(function() isFriend = player:IsFriendsWith(p.UserId) end)
            if isFriend and not friendsSet[p.Name] then
                friendsSet[p.Name] = true
                appendFriendLog("Friend detected: " .. p.Name)
                -- apply blue highlight if their model exists
                for _, model in ipairs(getOtherPlayerModels()) do
                    if model.Name == p.Name and not friendHighlights[p.Name] then
                        local hl = Instance.new("Highlight")
                        hl.Adornee = model
                        hl.FillColor = Color3.fromRGB(0, 170, 255)
                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                        hl.FillTransparency = 0.5
                        hl.OutlineTransparency = 0
                        hl.Enabled = true
                        hl.Parent = model
                        table.insert(filledHighlights, hl)
                        friendHighlights[p.Name] = hl
                    end
                end
            elseif (not isFriend) and friendsSet[p.Name] then
                friendsSet[p.Name] = nil
                appendFriendLog("Friend left/unfriended: " .. p.Name)
                if friendHighlights[p.Name] then
                    pcall(function() friendHighlights[p.Name]:Destroy() end)
                    friendHighlights[p.Name] = nil
                end
            end
        end
    end
end

Players.PlayerAdded:Connect(function(p)
    task.spawn(function()
        updateFriendsScan()
    end)
end)

Players.PlayerRemoving:Connect(function(p)
    if friendsSet[p.Name] then
        friendsSet[p.Name] = nil
        appendFriendLog("Friend left: " .. p.Name)
        if friendHighlights[p.Name] then
            pcall(function() friendHighlights[p.Name]:Destroy() end)
            friendHighlights[p.Name] = nil
        end
    end
end)

-- initial friends scan
pcall(updateFriendsScan)

MainTab:Toggle({
    Flag = "LockFOV",
    Title = "Lock FOV",
    Value = false,
    Callback = function(state)
        fovEnabled = state
        if fovEnabled then
            if camera then pcall(function() camera.FieldOfView = fovValue end) end
        else
            if camera then pcall(function() camera.FieldOfView = 70 end) end
        end
    end
})

MainTab:Slider({
    Flag = "FOV",
    Title = "FOV",
    Value = { Min = 70, Max = 120, Default = 70 },
    Step = 1,
    Callback = function(val)
        fovValue = val
        if fovEnabled and camera then pcall(function() camera.FieldOfView = fovValue end) end
    end
})

MainTab:Section({ Title = "Team Checks" })

MainTab:Toggle({
    Flag = "HitboxTeamCheck",
    Title = "Hitbox Team Check",
    Value = true,
    Callback = function(state)
        hitboxTeamCheck = state
        if hitboxEnabled then applyHitboxes() end
    end
})

    MainTab:Section({ Title = "GUI" })
    MainTab:Keybind({
        Flag = "MinimizeKey",
        Title = "Minimize GUI Key",
        Value = "M",
        Callback = function(v)
            pcall(function()
                Window:SetToggleKey(Enum.KeyCode[v])
            end)
        end
    })

-- Cobra Spin controls
MainTab:Section({ Title = "Cobra Spin" })
CobraToggleControl = MainTab:Toggle({
    Flag = "CobraSpin",
    Title = "Enable Cobra Spin (PrimaryAxisOnly)",
    Value = false,
    Callback = function(state)
        setCobraSpinEnabled(state)
    end,
})

MainTab:Keybind({
    Flag = "CobraSpinKey",
    Title = "Cobra Spin Toggle Key",
    Value = "K",
    Callback = function(v)
        -- toggle cobra spin when keybind pressed
        setCobraSpinEnabled(not cobraSpinEnabled)
    end
})

-- Logs section in Input tab (first thing)
InputTab:Section({ Title = "Log s" })
-- Try to create a multiline TextArea/TextBox via WindUI; fallback to Input if unavailable
local function createLogsControl(tab)
    local ctrl = nil
    -- try TextArea
    -- Prefer a large multiline Input/Textarea so logs appear in the big box.
    local ok, res = pcall(function()
        return tab:Input({
            Title = "Friend Logs",
            Value = table.concat(friendsLogs, "\n"),
            Placeholder = "Friend join/leave logs will appear here...",
            Type = "Textarea",
            Callback = function() end,
        })
    end)
    if ok and res then
        ctrl = res
    else
        -- Try WindUI's TextArea (older/newer variants)
        local ok2, res2 = pcall(function()
            return tab:TextArea({
                Title = "Friend Logs",
                Value = table.concat(friendsLogs, "\n"),
                Placeholder = "Friend join/leave logs will appear here...",
                Callback = function() end,
            })
        end)
        if ok2 and res2 then
            ctrl = res2
        else
            -- Try TextBox
            local ok3, res3 = pcall(function()
                return tab:TextBox({
                    Title = "Friend Logs",
                    Value = table.concat(friendsLogs, "\n"),
                    Placeholder = "Friend join/leave logs will appear here...",
                    Callback = function() end,
                })
            end)
            if ok3 and res3 then
                ctrl = res3
            else
                -- Final fallback to Input without textarea
                local ok4, res4 = pcall(function()
                    return tab:Input({
                        Title = "Friend Logs",
                        Value = table.concat(friendsLogs, "\n"),
                        Placeholder = "Friend join/leave logs will appear here...",
                        Callback = function() end,
                    })
                end)
                if ok4 and res4 then
                    ctrl = res4
                end
            end
        end
    end
    return ctrl
end

FriendsLogsInput = createLogsControl(InputTab)


-- ESP Controls grouped into sections for clarity
ESPTab:Section({ Title = "Player ESP" })

ESPTab:Toggle({
    Flag = "FilledESP",
    Title = "Player ESP (Filled Glow)",
    Value = false,
    Callback = function(state)
        filledEspEnabled = state
        if state then
            applyFilledESP()
        else
            clearFilledESP()
        end
    end
})

ESPTab:Toggle({
    Flag = "FilledESPTeamCheck",
    Title = "Filled ESP Team Check",
    Value = true,
    Callback = function(state)
        filledEspTeamCheck = state
        if filledEspEnabled then applyFilledESP() end
    end
})

ESPTab:Section({ Title = "Box ESP" })

ESPTab:Toggle({
    Flag = "BoxESP",
    Title = "3D Box ESP (Wireframe)",
    Value = false,
    Callback = function(state)
        boxEspEnabled = state
        if state then
            applyBoxESP()
        else
            clearBoxESP()
        end
    end
})

ESPTab:Toggle({
    Flag = "BoxESPTeamCheck",
    Title = "Box ESP Team Check",
    Value = true,
    Callback = function(state)
        boxEspTeamCheck = state
        if boxEspEnabled then applyBoxESP() end
    end
})

ESPTab:Section({ Title = "Lobby" })

ESPTab:Toggle({
    Flag = "LobbyESP",
    Title = "Lobby ESP (Preview Plane)",
    Value = false,
    Callback = function(state)
        lobbyEspEnabled = state
        if state then
            applyLobbyESP()
        else
            clearLobbyESP()
        end
    end
})

ESPTab:Section({ Title = "Self" })

ESPTab:Toggle({
    Flag = "SelfBox",
    Title = "Self Box",
    Value = false,
    Callback = function(state)
        selfBoxEnabled = state
        if state then
            applySelfBox()
        else
            clearSelfBox()
        end
    end
})

ESPTab:Toggle({
    Flag = "SelfOutline",
    Title = "Self Outline",
    Value = false,
    Callback = function(state)
        if state then
            applySelfOutline()
        else
            clearSelfOutline()
        end
    end
})

ESPTab:Section({ Title = "Snaplines" })

ESPTab:Toggle({
    Flag = "Snaplines",
    Title = "Snaplines (Tracers)",
    Value = false,
    Callback = function(state)
        snaplineEnabled = state
        if state then
            applySnaplines()
        else
            clearSnaplines()
        end
    end
})

ESPTab:Toggle({
    Flag = "SnaplineTeamCheck",
    Title = "Snaplines Team Check",
    Value = true,
    Callback = function(state)
        snaplineTeamCheck = state
        if snaplineEnabled then applySnaplines() end
    end
})

ESPTab:Slider({
    Flag = "SnaplineThickness",
    Title = "Snapline Thickness",
    Value = { Min = 0.01, Max = 0.2, Default = 0.03 },
    Step = 0.01,
    Callback = function(val)
        snaplineThickness = val
        -- update existing beams
        for _, folder in pairs(snaplineContainers) do
            if folder and folder.Parent then
                local beam = folder:FindFirstChild("Snap_Beam")
                if beam and beam:IsA("Beam") then
                    beam.Width0 = snaplineThickness
                    beam.Width1 = snaplineThickness
                end
            end
        end
    end
})

HitboxTab:Section({ Title = "Hitbox Controls" })

HitboxTab:Toggle({
    Flag = "HitboxEnabled",
    Title = "Enable Hitbox Extension",
    Value = false,
    Callback = function(state)
        hitboxEnabled = state
        if not state then
            resetAllHitboxes()
        else
            applyHitboxes()
        end
    end
})

HitboxTab:Slider({
    Flag = "FuselageMultiplier",
    Title = "Fuselage Multiplier (%)",
    Value = { Min = 50, Max = 1000, Default = 100 },
    Step = 5,
    Callback = function(val)
        fuselageMultiplier = val
        if hitboxEnabled then
            applyHitboxes()
        end
    end
})

-- ESP Colors & Rainbow
ESPTab:Section({ Title = "ESP Colors" })

ESPTab:Colorpicker({
    Flag = "FilledEnemyColor",
    Title = "Filled ESP (Enemy)",
    Default = filledEnemyColor,
    Callback = function(color)
        filledEnemyColor = color
        if filledEspEnabled then applyFilledESP() end
    end
})

ESPTab:Colorpicker({
    Flag = "FilledFriendlyColor",
    Title = "Filled ESP (Friendly)",
    Default = filledFriendlyColor,
    Callback = function(color)
        filledFriendlyColor = color
        if filledEspEnabled then applyFilledESP() end
    end
})

ESPTab:Colorpicker({
    Flag = "BoxEnemyColor",
    Title = "Box ESP (Enemy)",
    Default = boxEnemyColor,
    Callback = function(color)
        boxEnemyColor = color
        if boxEspEnabled then applyBoxESP() end
    end
})

ESPTab:Colorpicker({
    Flag = "BoxFriendlyColor",
    Title = "Box ESP (Friendly)",
    Default = boxFriendlyColor,
    Callback = function(color)
        boxFriendlyColor = color
        if boxEspEnabled then applyBoxESP() end
    end
})

ESPTab:Colorpicker({
    Flag = "SnaplineEnemyColor",
    Title = "Snapline (Enemy)",
    Default = snaplineEnemyColor,
    Callback = function(color)
        snaplineEnemyColor = color
        if snaplineEnabled then applySnaplines() end
    end
})

ESPTab:Colorpicker({
    Flag = "SnaplineFriendlyColor",
    Title = "Snapline (Friendly)",
    Default = snaplineFriendlyColor,
    Callback = function(color)
        snaplineFriendlyColor = color
        if snaplineEnabled then applySnaplines() end
    end
})

ESPTab:Colorpicker({
    Flag = "LobbyBoxColor",
    Title = "Lobby Box Color",
    Default = lobbyBoxColor,
    Callback = function(color)
        lobbyBoxColor = color
        if lobbyEspEnabled then applyLobbyESP() end
    end
})

ESPTab:Colorpicker({
    Flag = "SelfBoxColor",
    Title = "Self Box Color",
    Default = selfBoxColor,
    Callback = function(color)
        selfBoxColor = color
        if selfBoxEnabled then applySelfBox() end
    end
})

ESPTab:Toggle({
    Flag = "RainbowAll",
    Title = "Rainbow All ESP",
    Value = false,
    Callback = function(state)
        rainbowAllEnabled = state
        if state then
            -- save current user colors
            savedUserColors = {
                filledEnemyColor = filledEnemyColor,
                filledFriendlyColor = filledFriendlyColor,
                boxEnemyColor = boxEnemyColor,
                boxFriendlyColor = boxFriendlyColor,
                snaplineEnemyColor = snaplineEnemyColor,
                snaplineFriendlyColor = snaplineFriendlyColor,
                lobbyBoxColor = lobbyBoxColor,
                selfBoxColor = selfBoxColor,
            }
            -- start rainbow task
            if not rainbowTask then
                rainbowTask = task.spawn(function()
                    local hue = 0
                    while rainbowAllEnabled do
                        hue = (hue + 0.005) % 1
                        local col = Color3.fromHSV(hue, 1, 1)
                        -- apply to filled highlights
                        for _, hl in ipairs(filledHighlights) do
                            if hl and hl:IsA("Highlight") then
                                hl.FillColor = col
                            end
                        end
                        -- apply to box edges
                        for _, folder in pairs(boxBeamContainers) do
                            if folder and folder.Parent then
                                for _, epart in ipairs(folder:GetChildren()) do
                                    if epart:IsA("BasePart") and epart.Name:match("^Edge_%d+_%d+") then
                                        epart.Color = col
                                    end
                                end
                            end
                        end
                        -- lobby
                        if previewPlaneBoxFolder and previewPlaneBoxFolder.Parent then
                            for _, epart in ipairs(previewPlaneBoxFolder:GetChildren()) do
                                if epart:IsA("BasePart") and epart.Name:match("^Edge_%d+_%d+") then
                                    epart.Color = col
                                end
                            end
                        end
                        -- self box
                        if selfBoxFolder and type(selfBoxFolder) == "table" and selfBoxFolder.Container and selfBoxFolder.Container.Parent then
                            for _, epart in ipairs(selfBoxFolder.Container:GetChildren()) do
                                if epart:IsA("BasePart") and epart.Name:match("^SelfEdge_%d+_%d+") then
                                    epart.Color = col
                                end
                            end
                        end
                        -- snaplines
                        for _, folder in pairs(snaplineContainers) do
                            if folder and folder.Parent then
                                local beam = folder:FindFirstChild("Snap_Beam")
                                if beam and beam:IsA("Beam") then
                                    beam.Color = ColorSequence.new(col)
                                end
                            end
                        end
                        task.wait(0.03)
                    end
                    rainbowTask = nil
                end)
            end
        else
            -- stop rainbow and restore user colors
            if savedUserColors and next(savedUserColors) then
                filledEnemyColor = savedUserColors.filledEnemyColor or filledEnemyColor
                filledFriendlyColor = savedUserColors.filledFriendlyColor or filledFriendlyColor
                boxEnemyColor = savedUserColors.boxEnemyColor or boxEnemyColor
                boxFriendlyColor = savedUserColors.boxFriendlyColor or boxFriendlyColor
                snaplineEnemyColor = savedUserColors.snaplineEnemyColor or snaplineEnemyColor
                snaplineFriendlyColor = savedUserColors.snaplineFriendlyColor or snaplineFriendlyColor
                lobbyBoxColor = savedUserColors.lobbyBoxColor or lobbyBoxColor
                selfBoxColor = savedUserColors.selfBoxColor or selfBoxColor
            end
            -- reapply visuals
            if filledEspEnabled then applyFilledESP() end
            if boxEspEnabled then applyBoxESP() end
            if lobbyEspEnabled then applyLobbyESP() end
            if snaplineEnabled then applySnaplines() end
            if selfBoxEnabled then applySelfBox() end
        end
    end
})

HitboxTab:Slider({
    Flag = "WingsMultiplier",
    Title = "Wings Multiplier (%)",
    Value = { Min = 50, Max = 1000, Default = 100 },
    Step = 5,
    Callback = function(val)
        wingsMultiplier = val
        if hitboxEnabled then
            applyHitboxes()
        end
    end
})

local DangerSection = MainTab:Section({ Title = "Misc" })

DangerSection:Button({
    Title = "Rejoin Server",
    Callback = function()
        WindUI:Notify({ Title = "Rejoin", Content = "Rejoining server..." })
        TeleportService:Teleport(game.PlaceId, player)
    end
})

DangerSection:Button({
    Title = "Infinite Yield",
    Callback = function()
        WindUI:Notify({ Title = "Infinite Yield", Content = "Loading Infinite Yield..." })
        local ok, err = pcall(function()
            loadstring(game:HttpGet('https://raw.githubusercontent.com/DarkNetworks/Infinite-Yield/main/latest.lua'))()
        end)
        if not ok then
            WindUI:Notify({ Title = "Infinite Yield", Content = "Failed to load: " .. tostring(err) })
        end
    end
})

DangerSection:Button({
    Title = "Reset All",
    Callback = function()
        hitboxEnabled = false
        filledEspEnabled = false
        boxEspEnabled = false
        lobbyEspEnabled = false
        selfBoxEnabled = false
        selfOutlineEnabled = false

        resetAllHitboxes()
        clearFilledESP()
        clearBoxESP()
        clearLobbyESP()
        clearSelfBox()
        clearSelfOutline()

        WindUI:Notify({ Title = "Reset", Content = "All features disabled and reset!" })
    end
})

DangerSection:Button({
    Title = "Destroy GUI",
    Callback = function()
        resetAllHitboxes()
        clearFilledESP()
        clearBoxESP()
        clearLobbyESP()
        clearSelfBox()
        clearSelfOutline()
        Window:Destroy()
    end
})

-- Config Tab (placed after Hitbox tab for visibility)


task.spawn(function()
    while task.wait(5) do
        checkPlayerTeam()

        if hitboxEnabled then
            applyHitboxes()
        end

        if filledEspEnabled then
            applyFilledESP()
        end

        if boxEspEnabled then
            applyBoxESP()
        end
        
        if lobbyEspEnabled then
            applyLobbyESP()
        end
        
        if snaplineEnabled then
            applySnaplines()
        end
        
        if selfBoxEnabled then
            -- Recreate if model changed
            local currentModel = getPlayerPlaneModel()
            if currentModel and (not selfBoxFolder or not selfBoxFolder.Model or selfBoxFolder.Model ~= currentModel) then
                applySelfBox()
            end
        else
            clearSelfBox()
        end

        if selfOutlineEnabled then
            applySelfOutline()
        else
            clearSelfOutline()
        end
    end
end)

-- Real-time box update loop (every frame for smooth tracking)
game:GetService("RunService").RenderStepped:Connect(function()
    if boxEspEnabled then
        updateBoxPositions()
    end
    
    if lobbyEspEnabled then
        updateLobbyBoxPositions()
    end
    
    -- Update Self Box if enabled
    if selfBoxEnabled then
        updateSelfBox()
    end

    -- Enforce FOV lock: keep camera.FieldOfView equal to slider value when enabled,
    -- otherwise ensure it resets to default 70.
    if camera then
        if fovEnabled then
            if camera.FieldOfView ~= fovValue then
                pcall(function() camera.FieldOfView = fovValue end)
            end 
            end
    end
end)

--to do the next time
--fix hitbox on local playyer
--fix box esp, glow fill on local plauer