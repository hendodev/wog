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
local rageTransparency = 0.9

local hitboxEnabled = false
local hitboxTeamCheck = true

local filledEspEnabled = false
local boxEspEnabled = false
local lobbyEspEnabled = false

local filledHighlights = {}
local boxBeamContainers = {}

local originalSizes = {}
local rageHitParts = {}

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

-- RWR, Responsiveness, Noclip
local rwrEnabled = false
local rwrGui = nil

local maxRespEnabled = false
local originalResponsiveness = nil
local maxRespKeepConn = nil

local noclipEnabled = false
local noclipKey = "N"
local noclipOriginals = {} -- part -> {CanCollide, CanTouch, CanQuery}
local noclipToggleControl = nil
local noclipKeybindControl = nil

-- TriangleTerrain no-collide
local terrainNoCollideEnabled = false
local terrainOriginals = {} -- part -> {CanCollide, CanTouch, CanQuery}
local terrainEnforceConn = nil

-- Prediction ESP (2D circle) variables
local predictionEnabled = false
local predictionLeadTime = 0.2
local predictionCircleSize = 48
local predictionGui = nil
local predictionCircles = {} -- model -> Frame
local predictionProjectileSpeed = nil -- optional, unused for now
local prevSeatData = {} -- model -> {pos = Vector3, t = number}

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
    -- destroy any rage hit parts
    for m, p in pairs(rageHitParts) do
        pcall(function() if p and p.Parent then p:Destroy() end end)
        rageHitParts[m] = nil
    end
end

local function applyHitboxes()
    if not hitboxEnabled then return end

    -- Get all other players' plane models
    for _, model in ipairs(getOtherPlayerModels()) do
        if not model or not model:IsA("Model") then continue end

        -- Optional: skip friends
        if friendsSet and friendsSet[model.Name] then
            continue
        end

        -- Team check
        local isEnemy = true
        if hitboxTeamCheck and playerTeamName and teams then
            if teams[playerTeamName] and teams[playerTeamName]:FindFirstChild(model.Name) then
                isEnemy = false
            end
        end
        if not isEnemy then continue end

        if hitboxMode == "Legit" then
            -- Fuselage
            local fuselage = model:FindFirstChild("Fuselage", true)
            if fuselage and fuselage:IsA("BasePart") then
                storeOriginalIfNeeded(fuselage)
                local newSize = originalSizes[fuselage] * (fuselageMultiplier / 100)
                fuselage.Size = newSize
            end

            -- Left Wing
            local leftWing = model:FindFirstChild("LeftWing", true)
            if leftWing and leftWing:IsA("BasePart") then
                storeOriginalIfNeeded(leftWing)
                local newSize = originalSizes[leftWing] * (wingsMultiplier / 100)
                leftWing.Size = newSize
            end

            -- Right Wing
            local rightWing = model:FindFirstChild("RightWing", true)
            if rightWing and rightWing:IsA("BasePart") then
                storeOriginalIfNeeded(rightWing)
                local newSize = originalSizes[rightWing] * (wingsMultiplier / 100)
                rightWing.Size = newSize
            end

            -- ensure no rage part remains
            if rageHitParts[model] then
                pcall(function() if rageHitParts[model] and rageHitParts[model].Parent then rageHitParts[model]:Destroy() end end)
                rageHitParts[model] = nil
            end

        else
            -- Rage mode: keep as block part (existing behavior)
            local refPart = model.PrimaryPart or model:FindFirstChild("Fuselage", true) or model:FindFirstChildWhichIsA("BasePart")
            if refPart then
                local baseSize = 8
                local scale = math.max(0.05, fuselageMultiplier / 100)
                local sizeStuds = math.max(1, baseSize * scale)
                pcall(function()
                    local rp = rageHitParts[model]
                    if not rp or not rp.Parent then
                        rp = Instance.new("Part")
                        rp.Name = "Rage_HitPart"
                        rp.Anchored = false
                        rp.CanCollide = false
                        rp.Transparency = rageTransparency
                        rp.Massless = true
                        rp.Parent = model
                        rageHitParts[model] = rp
                    end
                    rp.Size = Vector3.new(sizeStuds, sizeStuds, sizeStuds)
                    rp.CFrame = refPart.CFrame
                    pcall(function() rp.Transparency = rageTransparency end)
                    if not rp:FindFirstChild("_rage_weld") then
                        local weld = Instance.new("WeldConstraint")
                        weld.Name = "_rage_weld"
                        weld.Part0 = rp
                        weld.Part1 = refPart
                        weld.Parent = rp
                    else
                        local weld = rp:FindFirstChild("_rage_weld")
                        if weld and weld:IsA("WeldConstraint") then
                            weld.Part1 = refPart
                        end
                    end
                end)
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

-- Ensure RWR GUI exists (top-center indicator)
local function ensureRWRGui()
    if rwrGui and rwrGui.Parent then return end
    local playerGui = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui")
    if not playerGui then return end
    rwrGui = Instance.new("ScreenGui")
    rwrGui.Name = "RWR_GUI"
    rwrGui.ResetOnSpawn = false
    rwrGui.IgnoreGuiInset = true
    rwrGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Name = "RWR_Frame"
    frame.Size = UDim2.new(0.4, 0, 0, 36)
    frame.Position = UDim2.new(0.5, -0.2 * workspace.CurrentCamera.ViewportSize.X, 0, 8)
    frame.AnchorPoint = Vector2.new(0.5, 0)
    frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    frame.BackgroundTransparency = 0
    frame.BorderSizePixel = 0
    frame.Parent = rwrGui

    local label = Instance.new("TextLabel")
    label.Name = "RWR_Label"
    label.Size = UDim2.new(1, -8, 1, -8)
    label.Position = UDim2.new(0, 4, 0, 4)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(0, 0, 0)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 18
    label.Text = "RADAR: CLEAR"
    label.Parent = frame
end

local function clearRWRGui()
    if rwrGui then
        pcall(function() rwrGui:Destroy() end)
        rwrGui = nil
    end
end

-- Simple aiming detection: raycast from other model's Fuselage forward towards local plane model
-- Simple aiming detection: check specific gun cursor part under camera.plane_viewmodels
local function isGunCursorAimingAtLocal(model)
    if not model then return false, nil end
    local cam = workspace.CurrentCamera or workspace:FindFirstChild("Camera")
    if not cam then return false, nil end

    -- find local plane model under camera.plane_model
    local localPlane = nil
    local pm_local = cam:FindFirstChild("plane_model")
    if pm_local then
        for _, c in ipairs(pm_local:GetChildren()) do
            if c:IsA("Model") then
                localPlane = c
                break
            end
        end
    end
    if not localPlane then return false, nil end

    -- find the corresponding viewmodel under camera.plane_viewmodels
    local viewmodels = cam:FindFirstChild("plane_viewmodels")
    local vm = nil
    if viewmodels then
        vm = viewmodels:FindFirstChild(model.Name)
    end
    if not vm then
        -- fallback: try searching model itself for the cursor part
        vm = model
    end

    -- look for gun_3d_cursor_part under vm (recursive)
    local cursorPart = nil
    for _, d in ipairs(vm:GetDescendants()) do
        if d.Name == "gun_3d_cursor_part" and d:IsA("BasePart") then
            cursorPart = d
            break
        end
    end
    -- Also accept MeshPart
    if not cursorPart and vm then
        for _, d in ipairs(vm:GetDescendants()) do
            if d.Name == "gun_3d_cursor_part" and d:IsA("MeshPart") then
                cursorPart = d
                break
            end
        end
    end
    if not cursorPart then return false, nil end

    local origin = cursorPart.Position
    local dir = cursorPart.CFrame.LookVector
    if not dir or dir.Magnitude == 0 then return false, nil end

    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {vm}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    local maxDist = 5000
    local result = workspace:Raycast(origin, dir * maxDist, rayParams)
    if result and result.Instance and result.Instance:IsDescendantOf(localPlane) then
        return true, model
    end
    return false, nil
end

local function updateRWRStatus()
    if not rwrEnabled or not rwrGui then return end
    local label = rwrGui:FindFirstChild("RWR_Frame") and rwrGui.RWR_Frame:FindFirstChild("RWR_Label")
    if not label then return end

    local foundAimer = nil
    for _, m in ipairs(getOtherPlayerModels()) do
        local ok, aiming, who = pcall(function() return isGunCursorAimingAtLocal(m) end)
        if ok and aiming and who then
            foundAimer = who
            break
        end
    end

    if foundAimer then
        rwrGui.RWR_Frame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        rwrGui.RWR_Frame.RWR_Label.Text = (foundAimer.Name or "PLAYER") .. " IS AIMING AT YOU!"
        rwrGui.RWR_Frame.RWR_Label.TextColor3 = Color3.fromRGB(255,255,255)
    else
        rwrGui.RWR_Frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        rwrGui.RWR_Frame.RWR_Label.Text = "RADAR: CLEAR"
        rwrGui.RWR_Frame.RWR_Label.TextColor3 = Color3.fromRGB(0,0,0)
    end
end

-- Prediction ESP GUI helpers
local function ensurePredictionGui()
    if predictionGui and predictionGui.Parent then return end
    local playerGui = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui")
    if not playerGui then return end
    predictionGui = Instance.new("ScreenGui")
    predictionGui.Name = "PredictionESP"
    predictionGui.ResetOnSpawn = false
    predictionGui.Parent = playerGui
end

local function clearPredictionGui()
    if predictionGui then
        pcall(function() predictionGui:Destroy() end)
        predictionGui = nil
    end
    predictionCircles = {}
end

local function createCircleForModel(model)
    if not predictionGui then ensurePredictionGui() end
    if not predictionGui then return nil end
    if predictionCircles[model] and predictionCircles[model].Parent then return predictionCircles[model] end
    local size = predictionCircleSize
    local frame = Instance.new("Frame")
    frame.Name = "PredCircle_" .. tostring(model.Name)
    frame.Size = UDim2.new(0, size, 0, size)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    frame.BackgroundTransparency = 0.6
    frame.BorderSizePixel = 0
    frame.Parent = predictionGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Name = "PredName"
    label.Size = UDim2.new(1, 0, 0, 16)
    label.Position = UDim2.new(0, 0, 1, 2)
    label.BackgroundTransparency = 1
    label.Text = tostring(model.Name)
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.TextSize = 14
    label.Font = Enum.Font.SourceSansBold
    label.Parent = frame

    predictionCircles[model] = frame
    return frame
end

local function updatePredictionESP()
    if not predictionEnabled then return end
    if not camera then camera = workspace.CurrentCamera end
    if not camera then return end

    for _, model in ipairs(getOtherPlayerModels()) do
        if not (model and model:IsA("Model")) then
            -- ignore invalid entries
        else
            -- skip friends and teammates; only show for enemies
            local isEnemy = not (playerTeamName and teams and teams[playerTeamName] and teams[playerTeamName]:FindFirstChild(model.Name))
            if not isEnemy then
                if predictionCircles[model] then
                    pcall(function() predictionCircles[model]:Destroy() end)
                    predictionCircles[model] = nil
                end
            else
                -- prefer Seat CFrame from camera viewmodels for velocity
                local cam = workspace.CurrentCamera or workspace:FindFirstChild("Camera")
                local seatPart = nil
                if cam then
                    local vmFolder = cam:FindFirstChild("plane_viewmodels") or playerFolder
                    if vmFolder then
                        local vm = vmFolder:FindFirstChild(model.Name)
                        if vm and vm:IsA("Model") then
                            seatPart = vm:FindFirstChild("Seat", true)
                        end
                    end
                end
                -- fallback: look inside model
                if not seatPart then
                    seatPart = model:FindFirstChild("Seat", true) or model:FindFirstChild("Fuselage", true) or model.PrimaryPart
                end

                if not seatPart or not seatPart:IsA("BasePart") then
                    if predictionCircles[model] then
                        pcall(function() predictionCircles[model]:Destroy() end)
                        predictionCircles[model] = nil
                    end
                else
                    local now = tick()
                    local pos = seatPart.CFrame.Position
                    local vel = Vector3.new(0,0,0)
                    local prev = prevSeatData[model]
                    if prev and prev.pos and prev.t and now > prev.t then
                        local dt = math.max(0.0001, now - prev.t)
                        vel = (pos - prev.pos) / dt
                    else
                        pcall(function() vel = seatPart.Velocity or seatPart.AssemblyLinearVelocity or vel end)
                    end
                    prevSeatData[model] = { pos = pos, t = now }

                    local lead = predictionLeadTime
                    local predPos = pos + vel * lead
                    local screenPos, onScreen = camera:WorldToViewportPoint(predPos)
                    local x, y = screenPos.X, screenPos.Y

                    if onScreen then
                        local frame = predictionCircles[model] or createCircleForModel(model)
                        if frame and frame.Parent then
                            local size = predictionCircleSize
                            frame.Size = UDim2.new(0, size, 0, size)
                            frame.Position = UDim2.new(0, x, 0, y)
                            if frame:FindFirstChild("PredName") then
                                frame.PredName.Text = model.Name
                            end
                        end
                    else
                        if predictionCircles[model] then
                            pcall(function() predictionCircles[model]:Destroy() end)
                            predictionCircles[model] = nil
                        end
                    end
                end
            end
        end
    end
    -- cleanup entries for models that no longer exist
    for m, f in pairs(predictionCircles) do
        if not m or not m.Parent then
            pcall(function() f:Destroy() end)
            predictionCircles[m] = nil
        end
    end
end

-- Max Responsiveness control
local function setMaxResponsiveness(state)
    maxRespEnabled = state
    local ok, gyro = pcall(findGyroAlignOrientation)
    if not ok then gyro = nil end
    if gyro and gyro:IsA("AlignOrientation") then
        if state then
            if originalResponsiveness == nil then
                originalResponsiveness = gyro.Responsiveness
            end
            pcall(function() gyro.Responsiveness = 10000 end)
            -- keep it forced
            if not maxRespKeepConn then
                maxRespKeepConn = game:GetService("RunService").RenderStepped:Connect(function()
                    if maxRespEnabled and gyro and gyro.Parent then
                        pcall(function() gyro.Responsiveness = 10000 end)
                    end
                end)
            end
        else
            if maxRespKeepConn then
                pcall(function() maxRespKeepConn:Disconnect() end)
                maxRespKeepConn = nil
            end
            if gyro and originalResponsiveness then
                pcall(function() gyro.Responsiveness = originalResponsiveness end)
            end
            originalResponsiveness = nil
        end
    end
end

-- Noclip functions
local function applyNoclipToModel(model)
    if not model then return end
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            if not noclipOriginals[part] then
                noclipOriginals[part] = {CanCollide = part.CanCollide, CanTouch = part.CanTouch, CanQuery = part.CanQuery}
            end
            pcall(function()
                part.CanCollide = false
                part.CanTouch = false
                part.CanQuery = false
            end)
        end
    end
end

local function restoreNoclipFromModel(model)
    if not model then return end
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") and noclipOriginals[part] then
            local orig = noclipOriginals[part]
            pcall(function()
                part.CanCollide = orig.CanCollide
                part.CanTouch = orig.CanTouch
                part.CanQuery = orig.CanQuery
            end)
            noclipOriginals[part] = nil
        end
    end
end

local function setNoclip(state)
    noclipEnabled = state
    local cam = workspace.CurrentCamera or workspace:FindFirstChild("Camera")
    if not cam then return end
    local pm = cam:FindFirstChild("plane_model")
    if not pm then return end
    for _, model in ipairs(pm:GetChildren()) do
        if model and model:IsA("Model") then
            if state then
                applyNoclipToModel(model)
            else
                restoreNoclipFromModel(model)
            end
        end
    end
end

local function setTerrainNoCollide(state)
    terrainNoCollideEnabled = state
    local tri = workspace:FindFirstChild("TriangleTerrain")
    if not tri then return end
    if state then
        -- store originals and disable collisions on all parts under TriangleTerrain
        for _, part in ipairs(tri:GetDescendants()) do
            if part:IsA("BasePart") then
                if not terrainOriginals[part] then
                    terrainOriginals[part] = { CanCollide = part.CanCollide, CanTouch = part.CanTouch, CanQuery = part.CanQuery }
                end
                pcall(function()
                    part.CanCollide = false
                    part.CanTouch = false
                    part.CanQuery = false
                end)
            end
        end
        if not terrainEnforceConn then
            terrainEnforceConn = game:GetService("RunService").RenderStepped:Connect(function()
                pcall(function()
                    if tri and tri.Parent then
                        for _, part in ipairs(tri:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                                part.CanTouch = false
                                part.CanQuery = false
                            end
                        end
                    end
                end)
            end)
        end
    else
        if terrainEnforceConn then
            pcall(function() terrainEnforceConn:Disconnect() end)
            terrainEnforceConn = nil
        end
        -- restore originals
        for part, orig in pairs(terrainOriginals) do
            if part and part.Parent then
                pcall(function()
                    part.CanCollide = orig.CanCollide
                    part.CanTouch = orig.CanTouch
                    part.CanQuery = orig.CanQuery
                end)
            end
            terrainOriginals[part] = nil
        end
        terrainOriginals = {}
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
                        -- Create full blue box ESP for friend (if not already)
                        if not boxBeamContainers[model] then
                            local container = createBoxAroundModel(model)
                            if container then
                                for _, epart in ipairs(container:GetChildren()) do
                                    if epart:IsA("BasePart") and epart.Name:match("^Edge_%d+_%d+") then
                                        epart.Color = Color3.fromRGB(0,170,255)
                                    end
                                end
                                boxBeamContainers[model] = container
                            end
                        end
                        -- Attempt snapline to friend (blue)
                        pcall(function()
                            local localFus, _ = getLocalFuselage()
                            local targetFus = model:FindFirstChild("Fuselage", true)
                            if localFus and targetFus and not snaplineContainers[model] then
                                local folder, beam = createSnaplineBetween(localFus, targetFus, model)
                                if folder and beam then
                                    beam.Color = ColorSequence.new(Color3.fromRGB(0,170,255))
                                    snaplineContainers[model] = folder
                                end
                            end
                        end)
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
        -- remove any box ESP created for this friend's model(s)
        for model, folder in pairs(boxBeamContainers) do
            if model and model.Name == p.Name then
                if folder then pcall(function() folder:Destroy() end) end
                boxBeamContainers[model] = nil
            end
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

-- Teleport Section (added above Team Checks)
MainTab:Section({ Title = "Teleport" })

local teleportEnabled = false
local teleportKey = "T"
local teleportDistance = 50

MainTab:Toggle({
    Flag = "TeleportToggle",
    Title = "Enable Teleport",
    Value = false,
    Callback = function(state)
        teleportEnabled = state
    end
})

MainTab:Keybind({
    Flag = "TeleportKey",
    Title = "Teleport Key",
    Value = "T",
    Callback = function(v)
        if type(v) == "string" and #v > 0 then
            teleportKey = v:upper()
        end
    end
})

MainTab:Slider({
    Flag = "TeleportDistance",
    Title = "Teleport Distance (studs)",
    Value = { Min = 5, Max = 500, Default = 50 },
    Step = 1,
    Callback = function(val)
        teleportDistance = math.clamp(val or 50, 5, 500)
    end
})

-- helper: safe getNil using provided global helper if available
local function getNilLocal(name, class)
    if type(getnilinstances) == "function" then
        for _, v in next, getnilinstances() do
            if v and v.ClassName == class and v.Name == name then
                return v
            end
        end
    end
    return nil
end

-- Input handlers: teleport and FOV zoom
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local zoomedIn = false
local activeZoomTween = nil
local function doTeleport()
    if not teleportEnabled then return end
    local cam = workspace.CurrentCamera or workspace:FindFirstChild("Camera")
    local moved = false

    -- helper to move a model or part forward based on its own forward vector
    local function moveForward(inst)
        if not inst then return end
        if inst:IsA("Model") then
            local ref = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
            if ref then
                local forward = ref.CFrame.LookVector * teleportDistance
                if inst.PrimaryPart then
                    inst:SetPrimaryPartCFrame(inst.PrimaryPart.CFrame + forward)
                else
                    for _, p in ipairs(inst:GetDescendants()) do
                        if p:IsA("BasePart") then
                            p.CFrame = p.CFrame + forward
                        end
                    end
                end
                moved = true
            end
        elseif inst:IsA("BasePart") then
            local forward = inst.CFrame.LookVector * teleportDistance
            inst.CFrame = inst.CFrame + forward
            moved = true
        end
    end

    -- move the player's plane model under Camera.plane_model (e.g., MiG17F)
    if cam then
        local pm = cam:FindFirstChild("plane_model")
        if pm and pm:IsA("Model") or pm and typeof(pm) == "Instance" then
            -- try to find a model matching player name, otherwise MiG17F, otherwise any model
            local targetModel = nil
            if pm:FindFirstChild(player.Name) then
                targetModel = pm:FindFirstChild(player.Name)
            elseif pm:FindFirstChild("MiG17F") then
                targetModel = pm:FindFirstChild("MiG17F")
            else
                for _, c in ipairs(pm:GetChildren()) do
                    if c:IsA("Model") then targetModel = c; break end
                end
            end
            if targetModel then
                pcall(function() moveForward(targetModel) end)
            end
        end

        -- move targ_holder and targ_holder2 under Camera.Ignore if present
        local ign = cam:FindFirstChild("Ignore")
        if ign then
            local h1 = ign:FindFirstChild("targ_holder") or getNilLocal("targ_holder", "Part")
            local h2 = ign:FindFirstChild("targ_holder2") or getNilLocal("targ_holder2", "Part")
            pcall(function() moveForward(h1) end)
            pcall(function() moveForward(h2) end)
        end
    end

    -- fallback: move humanoid root part if nothing else moved
    if not moved then
        local char = player and (player.Character or (player.CharacterAdded and player.Character)) or nil
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
            if hrp and hrp:IsA("BasePart") then
                pcall(function()
                    hrp.CFrame = hrp.CFrame + hrp.CFrame.LookVector * teleportDistance
                end)
            end
        end
    end
end

local function setCameraFOV(targetFov)
    if not camera then camera = workspace.CurrentCamera end
    if not camera then return end
    pcall(function()
        if activeZoomTween then
            pcall(function() activeZoomTween:Cancel() end)
            activeZoomTween = nil
        end
        local ti = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        activeZoomTween = TweenService:Create(camera, ti, { FieldOfView = targetFov })
        activeZoomTween:Play()
    end)
end
-- Single unified input handler for teleport and zoom (ignores typing in textboxes)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if UserInputService:GetFocusedTextBox() then return end
        local name = input.KeyCode and input.KeyCode.Name or tostring(input.KeyCode)
        if name == teleportKey and teleportEnabled then
            pcall(doTeleport)
            return
        end
        if name == "Z" and fovEnabled then
            zoomedIn = not zoomedIn
            if zoomedIn then
                setCameraFOV(28)
            else
                setCameraFOV(fovValue or 70)
            end
        end
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        if fovEnabled then
            zoomedIn = not zoomedIn
            if zoomedIn then
                setCameraFOV(28)
            else
                setCameraFOV(fovValue or 70)
            end
        end
    end
end)

-- Team Checks section follows
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

-- RWR and Utilities
MainTab:Section({ Title = "RWR [Beta]" })
MainTab:Toggle({
    Flag = "RWR",
    Title = "Enable RWR [Beta]",
    Value = false,
    Callback = function(state)
        rwrEnabled = state
        if state then
            ensureRWRGui()
        else
            clearRWRGui()
        end
    end
})

MainTab:Section({ Title = "Utilities" })
MainTab:Toggle({
    Flag = "MaxResponsiveness",
    Title = "Max Responsiveness",
    Value = false,
    Callback = function(state)
        setMaxResponsiveness(state)
    end
})

MainTab:Button({
    Title = "Max Responsiveness (One-shot)",
    Callback = function()
        local ok, gyro = pcall(findGyroAlignOrientation)
        if ok and gyro and gyro:IsA("AlignOrientation") then
            pcall(function()
                if originalResponsiveness == nil then originalResponsiveness = gyro.Responsiveness end
                gyro.Responsiveness = 10000
            end)
            WindUI:Notify({ Title = "MaxResp", Content = "Set Responsiveness to max (one-shot)" })
        else
            WindUI:Notify({ Title = "MaxResp", Content = "Gyro not found" })
        end
    end
})

-- Noclip toggle + keybind
-- noclip UI removed per user request; TriangleTerrain toggle handles map parts instead

-- Terrain CanCollide toggle
MainTab:Section({ Title = "Terrain" })
MainTab:Toggle({
    Flag = "TerrainNoCollide",
    Title = "Disable Terrain CanCollide",
    Value = false,
    Callback = function(state)
        setTerrainNoCollide(state)
    end,
})

-- Logs section in Input tab (first thing)
InputTab:Section({ Title = "Logs" })
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

    -- Prediction ESP controls
    ESPTab:Section({ Title = "Prediction ESP" })
    ESPTab:Toggle({
        Flag = "PredictionESP",
        Title = "Enable Prediction ESP (2D)",
        Value = false,
        Callback = function(state)
            predictionEnabled = state
            if state then
                ensurePredictionGui()
            else
                clearPredictionGui()
            end
        end,
    })

    ESPTab:Slider({
        Flag = "PredictionLead",
        Title = "Lead Time (s)",
        Value = { Min = 0, Max = 2, Default = 0.2 },
        Step = 0.05,
        Callback = function(val)
            predictionLeadTime = val
        end
    })

    ESPTab:Slider({
        Flag = "PredictionSize",
        Title = "Circle Size (px)",
        Value = { Min = 8, Max = 128, Default = 48 },
        Step = 1,
        Callback = function(val)
            predictionCircleSize = val
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

-- Hitbox Mode: Legit (existing) or Rage (resizes specific viewmodel parts)
local hitboxMode = "Legit" -- or "Rage"
HitboxTab:Dropdown({
    Title = "Hitbox Mode",
    Values = { "Legit", "Rage" },
    Value = "Legit",
    Callback = function(val)
        if type(val) == "string" then
            hitboxMode = val
            if hitboxEnabled then
                -- remove previous modifications and reapply in new mode
                resetAllHitboxes()
                applyHitboxes()
            end
        end
    end,
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

HitboxTab:Slider({
    Flag = "RageHitboxTransparency",
    Title = "Rage Hitbox Transparency (0 = opaque, 1 = invisible)",
    Value = { Min = 0, Max = 1, Default = rageTransparency },
    Step = 0.05,
    Callback = function(val)
        rageTransparency = math.clamp(val or 1, 0, 1)
        -- update existing rage parts
        for _, rp in pairs(rageHitParts) do
            if rp and rp.Parent then
                pcall(function() rp.Transparency = rageTransparency end)
            end
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
            -- disable main flags
            hitboxEnabled = false
            filledEspEnabled = false
            boxEspEnabled = false
            lobbyEspEnabled = false
            selfBoxEnabled = false
            selfOutlineEnabled = false
            snaplineEnabled = false
            predictionEnabled = false
            rwrEnabled = false
            terrainNoCollideEnabled = false
            maxRespEnabled = false
            noclipEnabled = false
            teleportEnabled = false
            rainbowAllEnabled = false

            -- reset visual and hitbox state
            resetAllHitboxes()
            clearFilledESP()
            clearBoxESP()
            clearLobbyESP()
            clearSelfBox()
            clearSelfOutline()
            clearSnaplines()
            clearPredictionGui()
            clearRWRGui()

            -- stop rainbow task (flag cleared above will end it)

            -- disconnect terrain enforcement and restore originals
            pcall(function()
                if terrainEnforceConn then terrainEnforceConn:Disconnect() end
            end)
            terrainEnforceConn = nil
            for part, orig in pairs(terrainOriginals) do
                if part and part.Parent then
                    pcall(function()
                        part.CanCollide = orig.CanCollide
                        part.CanTouch = orig.CanTouch
                        part.CanQuery = orig.CanQuery
                    end)
                end
                terrainOriginals[part] = nil
            end
            terrainOriginals = {}

            -- disconnect max responsiveness enforcement and restore gyro
            pcall(function()
                if maxRespKeepConn then maxRespKeepConn:Disconnect() end
            end)
            maxRespKeepConn = nil
            if originalResponsiveness then
                local ok, gyro = pcall(findGyroAlignOrientation)
                if ok and gyro and gyro:IsA("AlignOrientation") then
                    pcall(function() gyro.Responsiveness = originalResponsiveness end)
                end
            end
            originalResponsiveness = nil

            -- restore noclip for models under camera.plane_model
            pcall(function()
                local cam = workspace.CurrentCamera or workspace:FindFirstChild("Camera")
                if cam then
                    local pm = cam:FindFirstChild("plane_model")
                    if pm then
                        for _, m in ipairs(pm:GetChildren()) do
                            if m and m:IsA("Model") then
                                pcall(function() restoreNoclipFromModel(m) end)
                            end
                        end
                    end
                end
            end)

            -- clear helper containers
            for k, v in pairs(boxBeamContainers) do
                pcall(function() if v and v.Parent then v:Destroy() end end)
                boxBeamContainers[k] = nil
            end
            for k, v in pairs(snaplineContainers) do
                pcall(function() if v and v.Parent then v:Destroy() end end)
                snaplineContainers[k] = nil
            end
            for k, v in pairs(predictionCircles) do
                pcall(function() if v and v.Parent then v:Destroy() end end)
                predictionCircles[k] = nil
            end

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
    -- RWR update
    if rwrEnabled then
        pcall(updateRWRStatus)
    end
    -- Prediction ESP update
    if predictionEnabled then
        pcall(updatePredictionESP)
    end
end)
