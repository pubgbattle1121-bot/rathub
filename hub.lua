--[[
    Onyx Hub v1
    - UI with intro animation
    - Main tab: ESP + Aimbot
    - Misc tab: reserved
    - Settings tab: UI toggle, cursor free, shutdown key (;)
]]

--============ SERVICES ============--
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local CoreGui           = game:GetService("CoreGui")
local Workspace         = game:GetService("Workspace")
local Lighting          = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

--============ CONFIG ============--
local CONFIG = {
    UI_TOGGLE_KEY   = Enum.KeyCode.RightShift,
    SHUTDOWN_KEY    = Enum.KeyCode.Semicolon, -- ;
    ESP = {
        Enabled     = false,
        Box         = true,
        Name        = true,
        Distance    = true,
        Health      = true,
        Tracer      = false,
        TeamCheck   = true,
        MaxDistance = 1000,
    },
    AIM = {
        Enabled     = false,
        FOV         = 120,
        Smoothness  = 5,
        Radius      = 100,
        TargetPart  = "Head",
        TeamCheck   = true,
        VisibleOnly = false,
        ShowFOV     = true,
    },
    Misc = {
        CursorFree = false,
    },
}

--============ STATE ============--
local Connections = {}
local ESPCache    = {}   -- [player] = {drawings...}
local FOVCircle   = nil
local Running     = true

local function track(c)
    table.insert(Connections, c)
    return c
end

--============ CLEANUP ============--
local function cleanup()
    Running = false

    for _, c in ipairs(Connections) do
        pcall(function() c:Disconnect() end)
    end
    Connections = {}

    for _, data in pairs(ESPCache) do
        for _, d in pairs(data) do
            pcall(function() d:Remove() end)
        end
    end
    ESPCache = {}

    if FOVCircle then
        pcall(function() FOVCircle:Remove() end)
        FOVCircle = nil
    end

    pcall(function() UserInputService.MouseIconEnabled = true end)
    pcall(function() LocalPlayer.CameraMode = Enum.CameraMode.Classic end)
end

--============ DRAWING HELPERS ============--
local function newDrawing(class, props)
    local ok, d = pcall(function() return Drawing.new(class) end)
    if not ok or not d then return nil end
    for k, v in pairs(props or {}) do
        pcall(function() d[k] = v end)
    end
    return d
end

--============ ESP ============--
local function clearESP(player)
    local data = ESPCache[player]
    if not data then return end
    for _, d in pairs(data) do
        pcall(function() d:Remove() end)
    end
    ESPCache[player] = nil
end

local function createESP(player)
    if player == LocalPlayer then return end
    clearESP(player)

    ESPCache[player] = {
        box       = newDrawing("Square",   { Thickness = 1, Filled = false, Color = Color3.fromRGB(255, 255, 255), Transparency = 1 }),
        boxFill   = newDrawing("Square",   { Thickness = 1, Filled = true,  Color = Color3.fromRGB(0, 0, 0), Transparency = 0.6 }),
        name      = newDrawing("Text",     { Size = 14, Center = true, Outline = true, Color = Color3.fromRGB(255, 255, 255), Transparency = 1, Font = 2 }),
        distance  = newDrawing("Text",     { Size = 12, Center = true, Outline = true, Color = Color3.fromRGB(200, 200, 200), Transparency = 1, Font = 2 }),
        healthBg  = newDrawing("Line",     { Thickness = 3, Color = Color3.fromRGB(40, 40, 40), Transparency = 1 }),
        healthBar = newDrawing("Line",     { Thickness = 3, Color = Color3.fromRGB(0, 255, 120), Transparency = 1 }),
        tracer    = newDrawing("Line",     { Thickness = 1, Color = Color3.fromRGB(255, 255, 255), Transparency = 1 }),
    }
end

local function isSameTeam(player)
    if not CONFIG.ESP.TeamCheck then return false end
    return player.Team == LocalPlayer.Team
end

local function updateESP()
    if not CONFIG.ESP.Enabled then
        for p in pairs(ESPCache) do clearESP(p) end
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if isSameTeam(player) then clearESP(player) continue end

        local char = player.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")

        if not (hrp and head and hum and hum.Health > 0) then
            clearESP(player)
            continue
        end

        if not ESPCache[player] then createESP(player) end
        local d = ESPCache[player]
        if not d then continue end

        local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
        if distance > CONFIG.ESP.MaxDistance then
            for _, obj in pairs(d) do obj.Visible = false end
            continue
        end

        local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position)
        local rootPos, rootOnScreen = Camera:WorldToViewportPoint(hrp.Position)

        if not headOnScreen and not rootOnScreen then
            for _, obj in pairs(d) do obj.Visible = false end
            continue
        end

        local height = math.abs(headPos.Y - rootPos.Y) * 2
        local width  = height / 2
        local size   = Vector2.new(width, height)
        local pos    = Vector2.new(headPos.X - width / 2, headPos.Y - height / 4)

        -- Box
        d.box.Visible     = CONFIG.ESP.Box
        d.boxFill.Visible = CONFIG.ESP.Box
        if CONFIG.ESP.Box then
            d.box.Size        = size
            d.box.Position    = pos
            d.boxFill.Size    = size
            d.boxFill.Position = pos
            d.box.Color       = Color3.fromRGB(255, 255, 255)
            d.boxFill.Color   = Color3.fromRGB(0, 0, 0)
        end

        -- Name
        d.name.Visible  = CONFIG.ESP.Name
        if CONFIG.ESP.Name then
            d.name.Text     = player.Name
            d.name.Position = Vector2.new(headPos.X, pos.Y - 16)
        end

        -- Distance
        d.distance.Visible = CONFIG.ESP.Distance
        if CONFIG.ESP.Distance then
            d.distance.Text     = string.format("[%d studs]", math.floor(distance))
            d.distance.Position = Vector2.new(headPos.X, pos.Y + height + 4)
        end

        -- Health bar
        local healthPct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
        d.healthBg.Visible  = CONFIG.ESP.Health
        d.healthBar.Visible = CONFIG.ESP.Health
        if CONFIG.ESP.Health then
            local barX = pos.X - 6
            d.healthBg.From      = Vector2.new(barX, pos.Y)
            d.healthBg.To        = Vector2.new(barX, pos.Y + height)
            d.healthBar.From     = Vector2.new(barX, pos.Y + height * (1 - healthPct))
            d.healthBar.To       = Vector2.new(barX, pos.Y + height)
            d.healthBar.Color    = Color3.fromRGB(255 * (1 - healthPct), 255 * healthPct, 60)
        end

        -- Tracer
        d.tracer.Visible = CONFIG.ESP.Tracer
        if CONFIG.ESP.Tracer then
            d.tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            d.tracer.To   = Vector2.new(headPos.X, pos.Y + height)
        end
    end
end

--============ AIMBOT ============--
local function getClosestTarget()
    local closest, closestDist = nil, math.huge
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if CONFIG.AIM.TeamCheck and player.Team == LocalPlayer.Team then continue end

        local char = player.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if not (char and hum and hum.Health > 0) then continue end

        local part = char:FindFirstChild(CONFIG.AIM.TargetPart)
        if not part then continue end

        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end

        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
        if dist > CONFIG.AIM.FOV then continue end

        if CONFIG.AIM.VisibleOnly then
            local ray = Ray.new(Camera.CFrame.Position, part.Position - Camera.CFrame.Position)
            local hit = Workspace:FindPartOnRayWithIgnoreList(ray, { LocalPlayer.Character, Camera })
            if hit and not hit:IsDescendantOf(char) then continue end
        end

        if dist < closestDist then
            closestDist = dist
            closest = part
        end
    end

    return closest
end

local function updateAimbot()
    if not CONFIG.AIM.Enabled then return end

    local target = getClosestTarget()
    if not target then return end

    local targetPos = target.Position
    local camPos    = Camera.CFrame.Position
    local aimDir    = (targetPos - camPos).Unit
    local aimCF     = CFrame.new(camPos, camPos + aimDir)

    local smooth = math.max(CONFIG.AIM.Smoothness, 1)
    Camera.CFrame = Camera.CFrame:Lerp(aimCF, 1 / smooth)
end

--============ FOV CIRCLE ============--
local function updateFOV()
    if not CONFIG.AIM.ShowFOV or not CONFIG.AIM.Enabled then
        if FOVCircle then FOVCircle.Visible = false end
        return
    end

    if not FOVCircle then
        FOVCircle = newDrawing("Circle", {
            Thickness   = 1,
            NumSides    = 64,
            Filled      = false,
            Color       = Color3.fromRGB(255, 255, 255),
            Transparency = 0.5,
        })
    end

    FOVCircle.Visible  = true
    FOVCircle.Position = UserInputService:GetMouseLocation()
    FOVCircle.Radius   = CONFIG.AIM.FOV
end

--============ CURSOR FREE ============--
local function applyCursorFree()
    if CONFIG.Misc.CursorFree then
        UserInputService.MouseIconEnabled = true
    else
        UserInputService.MouseIconEnabled = true -- roblox default, always on
    end
end

--============ MAIN LOOP ============--
track(RunService.RenderStepped:Connect(function()
    if not Running then return end
    pcall(updateESP)
    pcall(updateAimbot)
    pcall(updateFOV)
end))

--============ GUI ============--
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "OnyxHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function()
    if gethui then
        ScreenGui.Parent = gethui()
    elseif CoreGui then
        ScreenGui.Parent = CoreGui
    else
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end)

--============ INTRO (RIVAL SCRIPT) ============--
local Intro = Instance.new("Frame")
Intro.Name = "Intro"
Intro.Size = UDim2.fromScale(1, 1)
Intro.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Intro.BackgroundTransparency = 1
Intro.BorderSizePixel = 0
Intro.ZIndex = 100
Intro.Parent = ScreenGui

local IntroText = Instance.new("TextLabel")
IntroText.Size = UDim2.fromScale(1, 0.3)
IntroText.Position = UDim2.fromScale(0, 0.35)
IntroText.BackgroundTransparency = 1
IntroText.Text = "RIVAL SCRIPT"
IntroText.TextColor3 = Color3.fromRGB(255, 255, 255)
IntroText.TextScaled = true
IntroText.Font = Enum.Font.GothamBlack
IntroText.TextTransparency = 1
IntroText.ZIndex = 101
IntroText.Parent = Intro

local IntroSub = Instance.new("TextLabel")
IntroSub.Size = UDim2.fromScale(1, 0.1)
IntroSub.Position = UDim2.fromScale(0, 0.62)
IntroSub.BackgroundTransparency = 1
IntroSub.Text = "onyx hub"
IntroSub.TextColor3 = Color3.fromRGB(180, 180, 180)
IntroSub.TextScaled = true
IntroSub.Font = Enum.Font.Gotham
IntroSub.TextTransparency = 1
IntroSub.ZIndex = 101
IntroSub.Parent = Intro

local function playIntro()
    Intro.BackgroundTransparency = 1
    IntroText.TextTransparency = 1
    IntroSub.TextTransparency = 1
    IntroText.Position = UDim2.fromScale(0, 0.45)
    IntroSub.Position = UDim2.fromScale(0, 0.68)

    TweenService:Create(Intro, TweenInfo.new(0.4), { BackgroundTransparency = 0.2 }):Play()
    task.wait(0.2)
    TweenService:Create(IntroText, TweenInfo.new(0.5), { TextTransparency = 0, Position = UDim2.fromScale(0, 0.35) }):Play()
    task.wait(0.4)
    TweenService:Create(IntroSub, TweenInfo.new(0.4), { TextTransparency = 0, Position = UDim2.fromScale(0, 0.62) }):Play()
    task.wait(1.2)

    -- fade out
    TweenService:Create(IntroText, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
    TweenService:Create(IntroSub, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
    TweenService:Create(Intro, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
    task.wait(0.7)
    Intro.Visible = false
end

--============ MAIN UI ============--
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(560, 360)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
Main.BorderSizePixel = 0
Main.Visible = false
Main.ZIndex = 10
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(60, 60, 70)
MainStroke.Thickness = 1
MainStroke.Parent = Main

-- Title bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
TitleBar.BorderSizePixel = 0
TitleBar.ZIndex = 11
TitleBar.Parent = Main

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = TitleBar

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, -80, 1, 0)
TitleText.Position = UDim2.fromOffset(12, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "Onyx Hub"
TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 14
TitleText.ZIndex = 12
TitleText.Parent = TitleBar

-- Rival Script button (top of UI)
local RivalBtn = Instance.new("TextButton")
RivalBtn.Size = UDim2.fromOffset(110, 24)
RivalBtn.Position = UDim2.new(1, -120, 0, 6)
RivalBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
RivalBtn.BorderSizePixel = 0
RivalBtn.Text = "Rival Script"
RivalBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RivalBtn.Font = Enum.Font.GothamBold
RivalBtn.TextSize = 12
RivalBtn.ZIndex = 12
RivalBtn.Parent = TitleBar

local RivalCorner = Instance.new("UICorner")
RivalCorner.CornerRadius = UDim.new(0, 4)
RivalCorner.Parent = RivalBtn

-- Tab bar
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(0, 130, 1, -36)
TabBar.Position = UDim2.fromOffset(0, 36)
TabBar.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
TabBar.BorderSizePixel = 0
TabBar.ZIndex = 11
TabBar.Parent = Main

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -130, 1, -36)
Content.Position = UDim2.fromOffset(130, 36)
Content.BackgroundTransparency = 1
Content.ZIndex = 11
Content.Parent = Main

local Pages = {}
local Tabs = {}

local function createPage(name)
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.fromScale(1, 1)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 90)
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.ZIndex = 11
    page.Parent = Content

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 8)
    pad.PaddingLeft = UDim.new(0, 8)
    pad.PaddingRight = UDim.new(0, 8)
    pad.PaddingBottom = UDim.new(0, 8)
    pad.Parent = page

    return page
end

local function createTab(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -8, 0, 30)
    btn.Position = UDim2.new(0, 4, 0, 4 + (#Tabs * 34))
    btn.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(180, 180, 190)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.ZIndex = 12
    btn.Parent = TabBar

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 4)
    c.Parent = btn

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 10)
    pad.Parent = btn

    local page = createPage(name)

    table.insert(Tabs, { btn = btn, page = page })
    Pages[name] = page

    btn.MouseButton1Click:Connect(function()
        for n, tab in pairs(Tabs) do
            tab.page.Visible = false
            tab.btn.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
            tab.btn.TextColor3 = Color3.fromRGB(180, 180, 190)
        end
        page.Visible = true
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)

    return page
end

--============ WIDGETS ============--
local function addLabel(parent, text)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 22)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(200, 200, 210)
    l.Font = Enum.Font.Gotham
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 12
    l.Parent = parent
    return l
end

local function addSection(parent, text)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 24)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(255, 255, 255)
    l.Font = Enum.Font.GothamBold
    l.TextSize = 13
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 12
    l.Parent = parent
    return l
end

local function addToggle(parent, text, default, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 30)
    row.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
    row.BorderSizePixel = 0
    row.ZIndex = 12
    row.Parent = parent

    local rc = Instance.new("UICorner")
    rc.CornerRadius = UDim.new(0, 4)
    rc.Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.Position = UDim2.fromOffset(10, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(220, 220, 230)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 13
    lbl.Parent = row

    local state = default and true or false

    local box = Instance.new("TextButton")
    box.Size = UDim2.fromOffset(40, 20)
    box.Position = UDim2.new(1, -50, 0.5, -10)
    box.BackgroundColor3 = state and Color3.fromRGB(80, 180, 100) or Color3.fromRGB(60, 60, 70)
    box.BorderSizePixel = 0
    box.Text = state and "ON" or "OFF"
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Font = Enum.Font.GothamBold
    box.TextSize = 10
    box.ZIndex = 13
    box.Parent = row

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 10)
    bc.Parent = box

    box.MouseButton1Click:Connect(function()
        state = not state
        box.BackgroundColor3 = state and Color3.fromRGB(80, 180, 100) or Color3.fromRGB(60, 60, 70)
        box.Text = state and "ON" or "OFF"
        if callback then pcall(callback, state) end
    end)

    return row
end

local function addSlider(parent, text, minV, maxV, default, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 42)
    row.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
    row.BorderSizePixel = 0
    row.ZIndex = 12
    row.Parent = parent

    local rc = Instance.new("UICorner")
    rc.CornerRadius = UDim.new(0, 4)
    rc.Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 0, 18)
    lbl.Position = UDim2.fromOffset(10, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = text .. ": " .. tostring(default)
    lbl.TextColor3 = Color3.fromRGB(220, 220, 230)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 13
    lbl.Parent = row

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -20, 0, 6)
    bar.Position = UDim2.new(0, 10, 0, 28)
    bar.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    bar.BorderSizePixel = 0
    bar.ZIndex = 13
    bar.Parent = row

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 3)
    bc.Parent = bar

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - minV) / (maxV - minV), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(120, 120, 255)
    fill.BorderSizePixel = 0
    fill.ZIndex = 14
    fill.Parent = bar

    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(0, 3)
    fc.Parent = fill

    local dragging = false

    local function setFromX(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local val = minV + (maxV - minV) * rel
        if maxV - minV >= 10 then val = math.floor(val) end
        fill.Size = UDim2.new(rel, 0, 1, 0)
        lbl.Text = text .. ": " .. tostring(val)
        if callback then pcall(callback, val) end
    end

    local dragCon = UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            setFromX(input.Position.X)
        end
    end)
    track(dragCon)

    local beginCon = bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            setFromX(input.Position.X)
        end
    end)
    track(beginCon)

    local endCon = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    track(endCon)

    return row
end

--============ BUILD PAGES ============--
local MainPage = createTab("Main")
local MiscPage = createTab("Misc")
local SettingsPage = createTab("Settings")

-- ---- MAIN: ESP ----
addSection(MainPage, "ESP")
addToggle(MainPage, "ESP Enabled", CONFIG.ESP.Enabled, function(v) CONFIG.ESP.Enabled = v end)
addToggle(MainPage, "Box",        CONFIG.ESP.Box,        function(v) CONFIG.ESP.Box = v end)
addToggle(MainPage, "Name",       CONFIG.ESP.Name,       function(v) CONFIG.ESP.Name = v end)
addToggle(MainPage, "Distance",   CONFIG.ESP.Distance,   function(v) CONFIG.ESP.Distance = v end)
addToggle(MainPage, "Health",     CONFIG.ESP.Health,     function(v) CONFIG.ESP.Health = v end)
addToggle(MainPage, "Tracer",     CONFIG.ESP.Tracer,     function(v) CONFIG.ESP.Tracer = v end)
addToggle(MainPage, "Team Check", CONFIG.ESP.TeamCheck,  function(v) CONFIG.ESP.TeamCheck = v end)
addSlider(MainPage, "Max Distance", 100, 5000, CONFIG.ESP.MaxDistance, function(v) CONFIG.ESP.MaxDistance = v end)

-- ---- MAIN: AIMBOT ----
addSection(MainPage, "Aimbot")
addToggle(MainPage, "Aimbot Enabled", CONFIG.AIM.Enabled,   function(v) CONFIG.AIM.Enabled = v end)
addToggle(MainPage, "Team Check",     CONFIG.AIM.TeamCheck, function(v) CONFIG.AIM.TeamCheck = v end)
addToggle(MainPage, "Visible Only",   CONFIG.AIM.VisibleOnly, function(v) CONFIG.AIM.VisibleOnly = v end)
addToggle(MainPage, "Show FOV",       CONFIG.AIM.ShowFOV,   function(v) CONFIG.AIM.ShowFOV = v end)
addSlider(MainPage, "FOV",         10, 800, CONFIG.AIM.FOV,        function(v) CONFIG.AIM.FOV = v end)
addSlider(MainPage, "Radius",      10, 500, CONFIG.AIM.Radius,     function(v) CONFIG.AIM.Radius = v end)
addSlider(MainPage, "Smoothness",  1,  20,  CONFIG.AIM.Smoothness, function(v) CONFIG.AIM.Smoothness = v end)
addSlider(MainPage, "FOV Size",    10, 800, 120, function(v) CONFIG.AIM.FOV = v end)

-- ---- MISC ----
addSection(MiscPage, "Misc")
addLabel(MiscPage, "아직 기능 없음. 나중에 추가하면 여기 붙이면 됨.")

-- ---- SETTINGS ----
addSection(SettingsPage, "UI")
addToggle(SettingsPage, "UI Toggle Key (RightShift)", true, function(v)
    -- key 자체는 항상 활성. 토글로 on/off 편의용.
end)

addSection(SettingsPage, "Cursor")
addToggle(SettingsPage, "Cursor Free (라이벌 안 죽었을 때 커서 풀기)", false, function(v)
    CONFIG.Misc.CursorFree = v
    if v then
        UserInputService.MouseIconEnabled = true
    end
end)

addSection(SettingsPage, "Shutdown")
addLabel(SettingsPage, "전체 스크립트를 종료하는 키는  ;  입니다.")
addLabel(SettingsPage, "누르면 ESP, Aimbot, UI 전부 종료됩니다.")

--============ UI DRAG ============--
do
    local dragging, dragStart, startPos = false, nil, nil

    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
        end
    end)

    track(UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end))

    track(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end))
end

--============ RIVAL BUTTON ============--
RivalBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
    Intro.Visible = true
    playIntro()
    task.wait(2.5)  -- 2~3초 대기
    Main.Visible = true
    Pages["Main"].Visible = true
    for _, tab in ipairs(Tabs) do
        tab.btn.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
        tab.btn.TextColor3 = Color3.fromRGB(180, 180, 190)
    end
    Tabs[1].btn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
    Tabs[1].btn.TextColor3 = Color3.fromRGB(255, 255, 255)
end)

--============ KEYBINDS ============--
track(UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end

    if input.KeyCode == CONFIG.UI_TOGGLE_KEY then
        Main.Visible = not Main.Visible
    elseif input.KeyCode == CONFIG.SHUTDOWN_KEY then
        cleanup()
        if ScreenGui then
            pcall(function() ScreenGui:Destroy() end)
        end
    end
end))

--============ FIRST OPEN ============--
-- 처음 실행하면 인트로 재생 후 메뉴 띄움
Main.Visible = false
Intro.Visible = true
playIntro()
task.wait(2.5)
Main.Visible = true
Pages["Main"].Visible = true
Tabs[1].btn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
Tabs[1].btn.TextColor3 = Color3.fromRGB(255, 255, 255)

print("[Onyx Hub] loaded. UI toggle: RightShift | Shutdown: ;")
