--[[
    VillonHub ESP — Drawing-based replacement for shitaro esp.lua
    Interface-compatible with the original (esp.tSet.en.*, esp.Load/Unload).
    Uses Drawing API + Highlight for chams, no Luraph, no server.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

local esp = {
    _loaded = false,
    allowlocal = false,
    roles = {},
    tSet = {
        en = {
            en = false,
            box = false,
            boxCol = {Color3.fromRGB(255, 0, 100), 1},
            boxType = "Static",
            boxGrd = false,
            boxGrdCol = {Color3.fromRGB(255, 0, 100), Color3.fromRGB(0, 100, 255)},
            boxF = false,
            boxFCol = {Color3.fromRGB(255, 0, 100), 0.5},
            boxFGrd = false,
            boxFGrdCol = {Color3.fromRGB(255, 0, 100), Color3.fromRGB(0, 100, 255)},
            name = false,
            nCol = {Color3.new(1, 1, 1), 1},
            nGrd = false,
            nGrdCol = {Color3.new(1, 1, 1), Color3.fromRGB(255, 0, 0)},
            av = false,
            offAr = false,
            offArColMur = {Color3.fromRGB(255, 60, 60), 1},
            offArColInno = {Color3.new(1, 1, 1), 1},
            offArColShf = {Color3.fromRGB(0, 153, 255), 1},
            offArSz = 42,
            offArDis = 260,
            dis = false,
            dCol = {Color3.new(1, 1, 1), 1},
            dGrd = false,
            dGrdCol = {Color3.new(1, 1, 1), Color3.fromRGB(255, 0, 0)},
            skel = false,
            skelCol = {Color3.new(1, 1, 1), 1},
            chams = false,
            chamsFColMur = {Color3.fromRGB(255, 0, 0), 0.5},
            chamsOColMur = {Color3.fromRGB(255, 0, 0), 0},
            chamsFColInno = {Color3.new(1, 1, 1), 0.5},
            chamsOColInno = {Color3.new(1, 1, 1), 0},
            chamsFColShf = {Color3.fromRGB(0, 153, 255), 0.5},
            chamsOColShf = {Color3.fromRGB(0, 153, 255), 0},
            matChams = false,
            matChamsType = "ForceField",
            matChamsColMur = Color3.fromRGB(255, 0, 0),
            matChamsColInno = Color3.new(1, 1, 1),
            matChamsColShf = Color3.fromRGB(0, 153, 255),
            matChamsVisColMur = {Color3.fromRGB(255, 0, 0), 0},
            matChamsOccColMur = {Color3.fromRGB(0, 0, 255), 0},
            matChamsVisColInno = {Color3.new(1, 1, 1), 0},
            matChamsOccColInno = {Color3.fromRGB(77, 77, 77), 0},
            matChamsVisColShf = {Color3.fromRGB(0, 153, 255), 0},
            matChamsOccColShf = {Color3.fromRGB(0, 0, 255), 0},
            flag = false,
            flagMurCol = {Color3.fromRGB(255, 0, 0), 1},
            flagMurGrd = false,
            flagMurGrdCol = {Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 128, 0)},
            flagShfCol = {Color3.fromRGB(0, 153, 255), 1},
            flagShfGrd = false,
            flagShfGrdCol = {Color3.fromRGB(0, 153, 255), Color3.fromRGB(0, 255, 255)},
        },
    },
}

-- ============================ HELPERS ============================
local function getRoot(char)
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
        or char:FindFirstChild("Torso")
        or char:FindFirstChild("UpperTorso")
end

local function colorOf(t, fallback)
    if type(t) == "table" and typeof(t[1]) == "Color3" then
        return t[1], t[2] or 1
    end
    if typeof(t) == "Color3" then return t, 1 end
    return fallback or Color3.new(1, 1, 1), 1
end

local function roleOf(player)
    local name = typeof(player) == "Instance" and player.Name or tostring(player)
    local role = esp.roles and esp.roles[name]
    return role or "Innocent"
end

local function roleColor(player)
    local role = roleOf(player)
    local en = esp.tSet.en
    if role == "Murderer" then return en.chamsFColMur[1] end
    if role == "Sheriff" or role == "Hero" then return en.chamsFColShf[1] end
    return en.chamsFColInno[1]
end

-- ============================ STORAGE ============================
local VisualStorage = {}

local function InitializeVisualData(player)
    if VisualStorage[player] or (player == LocalPlayer and not esp.allowlocal) then return end
    VisualStorage[player] = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        NameRole = Drawing.new("Text"),
        HealthBar = Drawing.new("Line"),
        Tracer = Drawing.new("Line"),
        Highlight = nil,
        Skeleton = {
            HeadToTorso = Drawing.new("Line"),
            TorsoToLeftArm = Drawing.new("Line"),
            TorsoToRightArm = Drawing.new("Line"),
            TorsoToLeftLeg = Drawing.new("Line"),
            TorsoToRightLeg = Drawing.new("Line"),
        },
    }
    local s = VisualStorage[player]
    s.Box.Thickness = 1
    s.Box.Filled = false
    s.Name.Size = 8
    s.Name.Center = true
    s.Name.Outline = true
    s.Name.Color = Color3.new(1, 1, 1)
    s.NameRole.Size = 8
    s.NameRole.Center = true
    s.NameRole.Outline = true
    s.HealthBar.Thickness = 2
    s.Tracer.Thickness = 1
    for _, bone in pairs(s.Skeleton) do
        bone.Thickness = 1
        bone.Color = Color3.new(1, 1, 1)
    end
end

local function ClearVisualData(player)
    if not VisualStorage[player] then return end
    local s = VisualStorage[player]
    for _, obj in pairs(s) do
        if type(obj) == "table" then
            for _, bone in pairs(obj) do
                pcall(function() bone:Remove() end)
            end
        elseif typeof(obj) == "userdata" and obj.Remove then
            pcall(function() obj:Remove() end)
        elseif typeof(obj) == "Instance" then
            pcall(function() obj:Destroy() end)
        end
    end
    if s.Highlight then pcall(function() s.Highlight:Destroy() end) end
    VisualStorage[player] = nil
end

-- ============================ RENDER ============================
local _pAdded, _pRemoving, _loop

local function startRender()
    for _, p in ipairs(Players:GetPlayers()) do InitializeVisualData(p) end

    _pAdded = Players.PlayerAdded:Connect(InitializeVisualData)
    _pRemoving = Players.PlayerRemoving:Connect(ClearVisualData)

    local ScreenCenter = Camera.ViewportSize / 2

    _loop = RunService.RenderStepped:Connect(function()
        local en = esp.tSet.en
        if not en.en then
            -- hide everything
            for _, s in pairs(VisualStorage) do
                s.Box.Visible = false
                s.Name.Visible = false
                s.NameRole.Visible = false
                s.HealthBar.Visible = false
                s.Tracer.Visible = false
                for _, bone in pairs(s.Skeleton) do bone.Visible = false end
                if s.Highlight then s.Highlight.Enabled = false end
            end
            return
        end

        ScreenCenter = Camera.ViewportSize / 2

        for player, storage in pairs(VisualStorage) do
            if typeof(player) == "Instance" and player.Parent == Players then
                if player == LocalPlayer and not esp.allowlocal then
                    storage.Box.Visible = false
                    storage.Name.Visible = false
                    storage.NameRole.Visible = false
                    storage.HealthBar.Visible = false
                    storage.Tracer.Visible = false
                    for _, bone in pairs(storage.Skeleton) do bone.Visible = false end
                    if storage.Highlight then storage.Highlight.Enabled = false end
                else
                    local char = player.Character
                    local root = char and getRoot(char)
                    local head = char and char:FindFirstChild("Head")
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    if root and head and hum and hum.Health > 0 then
                        local rootPos, rootOn = Camera:WorldToViewportPoint(root.Position)
                        local headPos, headOn = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                        local legPos, legOn = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))

                        if rootOn and headOn and legOn then
                            local bHeight = math.abs(headPos.Y - legPos.Y)
                            local bWidth = bHeight / 1.8
                            local left = rootPos.X - bWidth / 2
                            local top = headPos.Y
                            local roleCol = roleColor(player)

                            -- Box
                            if en.box then
                                storage.Box.Size = Vector2.new(bWidth, bHeight)
                                storage.Box.Position = Vector2.new(left, top)
                                local c, t = colorOf(en.boxCol, roleCol)
                                storage.Box.Color = (roleOf(player) ~= "Innocent") and roleCol or c
                                storage.Box.Transparency = t
                                storage.Box.Visible = true
                            else
                                storage.Box.Visible = false
                            end

                            -- Name + Role
                            if en.name then
                                local c, t = colorOf(en.nCol, Color3.new(1, 1, 1))
                                storage.Name.Color = (roleOf(player) ~= "Innocent") and roleCol or c
                                storage.Name.Text = player.Name
                                storage.Name.Position = Vector2.new(rootPos.X, headPos.Y - 30)
                                storage.Name.Visible = true

                                local dist = (root.Position - (LocalPlayer.Character and getRoot(LocalPlayer.Character) and getRoot(LocalPlayer.Character).Position or Vector3.zero)).Magnitude
                                storage.NameRole.Text = "[" .. roleOf(player) .. "] [" .. math.floor(dist) .. "]"
                                storage.NameRole.Color = roleCol
                                storage.NameRole.Position = Vector2.new(rootPos.X, headPos.Y - 18)
                                storage.NameRole.Visible = true
                            else
                                storage.Name.Visible = false
                                storage.NameRole.Visible = false
                            end

                            -- HealthBar
                            if en.dis then
                                local pct = hum.Health / hum.MaxHealth
                                storage.HealthBar.From = Vector2.new(left - 5, legPos.Y)
                                storage.HealthBar.To = Vector2.new(left - 5, legPos.Y - (bHeight * pct))
                                local c = colorOf(en.dCol, Color3.fromRGB(255 * (1 - pct), 255 * pct, 0))
                                storage.HealthBar.Color = (roleOf(player) ~= "Innocent") and roleCol or c
                                storage.HealthBar.Visible = true
                            else
                                storage.HealthBar.Visible = false
                            end

                            -- Tracer
                            if en.offAr then
                                storage.Tracer.From = Vector2.new(ScreenCenter.X, ScreenCenter.Y * 2)
                                storage.Tracer.To = Vector2.new(rootPos.X, legPos.Y)
                                local c = colorOf(en.offArColInno, roleCol)
                                storage.Tracer.Color = (roleOf(player) ~= "Innocent") and roleCol or c
                                storage.Tracer.Visible = true
                            else
                                storage.Tracer.Visible = false
                            end

                            -- Skeleton
                            if en.skel and char:FindFirstChild("LeftUpperArm") and char:FindFirstChild("RightUpperArm") then
                                local c = colorOf(en.skelCol, roleCol)
                                for _, bone in pairs(storage.Skeleton) do
                                    bone.Color = (roleOf(player) ~= "Innocent") and roleCol or c
                                end
                                local function bonePos(name)
                                    local p = char[name]
                                    if not p then return Vector2.new(0, 0) end
                                    local v = Camera:WorldToViewportPoint(p.Position)
                                    return Vector2.new(v.X, v.Y)
                                end
                                storage.Skeleton.HeadToTorso.From = Vector2.new(headPos.X, headPos.Y)
                                storage.Skeleton.HeadToTorso.To = Vector2.new(rootPos.X, rootPos.Y)
                                storage.Skeleton.HeadToTorso.Visible = true
                                storage.Skeleton.TorsoToLeftArm.From = Vector2.new(rootPos.X, rootPos.Y)
                                storage.Skeleton.TorsoToLeftArm.To = bonePos("LeftUpperArm")
                                storage.Skeleton.TorsoToLeftArm.Visible = true
                                storage.Skeleton.TorsoToRightArm.From = Vector2.new(rootPos.X, rootPos.Y)
                                storage.Skeleton.TorsoToRightArm.To = bonePos("RightUpperArm")
                                storage.Skeleton.TorsoToRightArm.Visible = true
                                storage.Skeleton.TorsoToLeftLeg.From = Vector2.new(rootPos.X, rootPos.Y)
                                storage.Skeleton.TorsoToLeftLeg.To = Vector2.new(rootPos.X - bWidth/4, legPos.Y)
                                storage.Skeleton.TorsoToLeftLeg.Visible = true
                                storage.Skeleton.TorsoToRightLeg.From = Vector2.new(rootPos.X, rootPos.Y)
                                storage.Skeleton.TorsoToRightLeg.To = Vector2.new(rootPos.X + bWidth/4, legPos.Y)
                                storage.Skeleton.TorsoToRightLeg.Visible = true
                            else
                                for _, bone in pairs(storage.Skeleton) do bone.Visible = false end
                            end

                            -- Chams (Highlight)
                            if en.chams or en.matChams then
                                if not storage.Highlight then
                                    storage.Highlight = Instance.new("Highlight")
                                    storage.Highlight.Parent = CoreGui
                                end
                                storage.Highlight.Adornee = char
                                storage.Highlight.FillColor = roleCol
                                storage.Highlight.OutlineColor = roleCol
                                storage.Highlight.FillTransparency = 0.4
                                storage.Highlight.OutlineTransparency = 0.1
                                storage.Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                storage.Highlight.Enabled = true
                            else
                                if storage.Highlight then storage.Highlight.Enabled = false end
                            end
                        else
                            storage.Box.Visible = false
                            storage.Name.Visible = false
                            storage.NameRole.Visible = false
                            storage.HealthBar.Visible = false
                            storage.Tracer.Visible = false
                            for _, bone in pairs(storage.Skeleton) do bone.Visible = false end
                            if storage.Highlight then storage.Highlight.Enabled = false end
                        end
                    else
                        storage.Box.Visible = false
                        storage.Name.Visible = false
                        storage.NameRole.Visible = false
                        storage.HealthBar.Visible = false
                        storage.Tracer.Visible = false
                        for _, bone in pairs(storage.Skeleton) do bone.Visible = false end
                        if storage.Highlight then storage.Highlight.Enabled = false end
                    end
                end
            end
        end
    end)
end

local function stopRender()
    if _pAdded then pcall(function() _pAdded:Disconnect() end) _pAdded = nil end
    if _pRemoving then pcall(function() _pRemoving:Disconnect() end) _pRemoving = nil end
    if _loop then pcall(function() _loop:Disconnect() end) _loop = nil end
    for player in pairs(VisualStorage) do ClearVisualData(player) end
end

-- ============================ API ============================
function esp.Load()
    if esp._loaded then return end
    esp._loaded = true
    startRender()
end

function esp.Unload()
    if not esp._loaded then return end
    esp._loaded = false
    stopRender()
end

function esp.AddClone() return nil end
function esp.RemoveClone() end
function esp.UpdateClone() end

return esp
