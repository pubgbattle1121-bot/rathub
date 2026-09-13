--[[
    Onyx Hub v1.1
    - ESP fixed
    - Aimbot: Mouse Follow / Center Lock modes
    - Rival Script intro
    - UI toggle: RightShift
    - Shutdown: ;
]]

--============ SERVICES ============--
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local CoreGui          = game:GetService("CoreGui")
local Workspace        = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

--============ DRAWING CHECK ============--
local HAS_DRAWING = pcall(function()
    local d = Drawing.new("Square")
    d:Remove()
end)

if not HAS_DRAWING then
    warn("[Onyx Hub] 이 executor는 Drawing을 지원하지 않음. ESP 비활성.")
end

--============ CONFIG ============--
local CONFIG = {
    UI_TOGGLE_KEY = Enum.KeyCode.RightShift,
    SHUTDOWN_KEY  = Enum.KeyCode.Semicolon,

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
        Mode        = "Mouse",   -- "Mouse" | "Center"
        FOV         = 120,
        Smoothness  = 5,
        TargetPart  = "Head",
        TeamCheck   = true,
        VisibleOnly = false,
        ShowFOV     = true,
        MouseOffsetX = 0,        -- 마우스 모드에서 커서 위치 보정
        MouseOffsetY = 0,
    },

    Misc = {
        CursorFree = false,
    },
}

--============ STATE ============--
local Connections = {}
local ESPCache    = {}
local FOVCircle   = nil
local Running     = true
local CurrentAimTarget = nil

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
end

--============ DRAWING HELPER ============--
local function newDrawing(class, props)
    if not HAS_DRAWING then return nil end
    local ok, d = pcall(function() return Drawing.new(class) end)
    if not ok or not d then return nil end
    for k, v in pairs(props or {}) do
        pcall(function() d[k] = v end)
    end
    return d
end

--============ TEAM HELPER ============--
local function isEnemy(player)
    if player == LocalPlayer then return false end
    if not CONFIG.ESP.TeamCheck and not CONFIG.AIM.TeamCheck then return true end

    local myTeam    = LocalPlayer.Team
    local theirTeam = player.Team

    -- FFA 서버 (양쪽 다 nil) → 모두 적
    if myTeam == nil and theirTeam == nil then return true end
    -- 한쪽만 nil → 팀 정보 없으니 적으로 처리 X (안전)
    if myTeam == nil or theirTeam == nil then return false end
    -- 둘 다 있으면 비교
    return myTeam ~= theirTeam
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
        box       = newDrawing("Square", { Thickness = 1, Filled = false, Color = Color3.fromRGB(255, 255, 255), Transparency = 1 }),
        boxFill   = newDrawing("Square", { Thickness = 1, Filled = true,  Color = Color3.fromRGB(0, 0, 0), Transparency = 0.55 }),
        name      = newDrawing("Text",   { Size = 14, Center = true, Outline = true, Color = Color3.fromRGB(255, 255, 255), Transparency = 1, Font = 2 }),
        distance  = newDrawing("Text",   { Size = 12, Center = true, Outline = true, Color = Color3.fromRGB(200, 200, 200), Transparency = 1, Font = 2 }),
        healthBg  = newDrawing("Line",   { Thickness = 3, Color = Color3.fromRGB(40, 40, 40), Transparency = 1 }),
        healthBar = newDrawing("Line",   { Thickness = 3, Color = Color3.fromRGB(0, 255, 120), Transparency = 1 }),
        tracer    = newDrawing("Line",   { Thickness = 1, Color = Color3.fromRGB(255, 255, 255), Transparency = 0.7 }),
    }
end

local function updateESP()
    if not CONFIG.ESP.Enabled or not HAS_DRAWING then
        for p in pairs(ESPCache) do clearESP(p) end
        return
    end

    local viewportSize = Camera.ViewportSize

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        -- 팀 체크 (ESP 기준)
        if CONFIG.ESP.TeamCheck and not isEnemy(player) then
            clearESP(player)
            continue
        end

        local char = player.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")

        if not (hrp and head and hum and hum.Health > 0) then
            clearESP(player)
            continue
        end

        local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
        if distance > CONFIG.ESP.MaxDistance then
            if ESPCache[player] then
                for _, obj in pairs(ESPCache[player]) do obj.Visible = false end
            end
            continue
        end

        if not ESPCache[player] then createESP(player) end
        local d = ESPCache[player]
        if not d or not d.box then continue end

        -- head 위쪽, hrp 아래쪽 기준으로 박스
        local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local rootPos, rootOnScreen = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))

        -- Z < 0 → 카메라 뒤
        if headPos.Z < 0 and rootPos.Z < 0 then
            for _, obj in pairs(d) do obj.Visible = false end
            continue
        end

        if not headOnScreen and not rootOnScreen then
            for _, obj in pairs(d) do obj.Visible = false end
            continue
        end

        local topY    = math.min(headPos.Y, rootPos.Y)
        local bottomY = math.max(headPos.Y, rootPos.Y)
        local height  = math.abs(bottomY - topY)
        local width   = height * 0.55
        local centerX = (headPos.X + rootPos.X) / 2

        local posX = centerX - width / 2
        local posY = topY

        -- 박스 (Square는 좌상단 기준)
        d.box.Visible      = CONFIG.ESP.Box
        d.boxFill.Visible  = CONFIG.ESP.Box
        if CONFIG.ESP.Box then
            d.box.Size         = Vector2.new(width, height)
            d.box.Position     = Vector2.new(posX, posY)
            d.boxFill.Size     = Vector2.new(width, height)
            d.boxFill.Position = Vector2.new(posX, posY)
            d.box.Color        = Color3.fromRGB(255, 255, 255)
            d.boxFill.Color    = Color3.fromRGB(0, 0, 0)
        end

        -- 이름
        d.name.Visible = CONFIG.ESP.Name
        if CONFIG.ESP.Name then
            d.name.Text     = player.Name
            d.name.Position = Vector2.new(centerX, posY - 16)
        end

        -- 거리
        d.distance.Visible = CONFIG.ESP.Distance
        if CONFIG.ESP.Distance then
            d.distance.Text     = string.format("[%d]", math.floor(distance))
            d.distance.Position = Vector2.new(centerX, posY + height + 4)
        end

        -- 체력바
        local healthPct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
        d.healthBg.Visible  = CONFIG.ESP.Health
        d.healthBar.Visible = CONFIG.ESP.Health
        if CONFIG.ESP.Health then
            local barX = posX - 6
            d.healthBg.From  = Vector2.new(barX, posY)
            d.healthBg.To    = Vector2.new(barX, posY + height)
            d.healthBar.From = Vector2.new(barX, posY + height * (1 - healthPct))
            d.healthBar.To   = Vector2.new(barX, posY + height)
            d.healthBar.Color = Color3.fromRGB(255 * (1 - healthPct), 255 * healthPct, 60)
        end

        -- 트레이서 (화면 하단 중앙 → 박스 하단 중앙)
        d.tracer.Visible = CONFIG.ESP.Tracer
        if CONFIG.ESP.Tracer then
            d.tracer.From = Vector2.new(viewportSize.X / 2, viewportSize.Y)
            d.tracer.To   = Vector2.new(centerX, posY + height)
        end
    end
end

--============ AIMBOT ============--
local function getClosestTarget()
    local closest, closestDist = nil, math.huge

    -- 마우스 모드는 커서 위치 기준, 센터 모드는 화면 중앙 기준
    local refPos
    if CONFIG.AIM.Mode == "Mouse" then
        local m = UserInputService:GetMouseLocation()
        refPos = Vector2.new(m.X + CONFIG.AIM.MouseOffsetX, m.Y + CONFIG.AIM.MouseOffsetY)
    else
        refPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if CONFIG.AIM.TeamCheck and not isEnemy(player) then continue end

        local char = player.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if not (char and hum and hum.Health > 0) then continue end

        local part = char:FindFirstChild(CONFIG.AIM.TargetPart)
        if not part then continue end

        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen or screenPos.Z < 0 then continue end

        local dist = (Vector2.new(screenPos.X, screenPos.Y) - refPos).Magnitude
        if dist > CONFIG.AIM.FOV then continue end

        if CONFIG.AIM.VisibleOnly then
            local origin = Camera.CFrame.Position
            local dir    = (part.Position - origin)
            local ray    = Ray.new(origin, dir)

            local ignoreList = { LocalPlayer.Character, Camera }
            local hit = Workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
            if hit and not hit:IsDescendantOf(char) then continue end
        end

        if dist < closestDist then
            closestDist = dist
            closest     = part
        end
    end

    return closest
end

local function updateAimbot()
    if not CONFIG.AIM.Enabled then
        CurrentAimTarget = nil
        return
    end

    local target = getClosestTarget()
    CurrentAimTarget = target
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
    if not HAS_DRAWING then return end

    if not (CONFIG.AIM.Enabled and CONFIG.AIM.ShowFOV) then
        if FOVCircle then FOVCircle.Visible = false end
        return
    end

    if not FOVCircle then
        FOVCircle = newDrawing("Circle", {
            Thickness    = 1,
            NumSides     = 64,
            Filled       = false,
            Color        = Color3.fromRGB(255, 255, 255),
            Transparency = 0.6,
        })
    end

    FOVCircle.Visible = true
    FOVCircle.Radius  = CONFIG.AIM.FOV
    FOVCircle.Position = CONFIG.AIM.Mode == "Mouse"
        and UserInputService:GetMouseLocation()
        or Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
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

--============ INTRO ============--
local Intro = Instance.new("Frame")
Intro.Size = UDim2.fromScale(1, 1)
Intro.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Intro.BackgroundTransparency = 1
Intro.BorderSizePixel = 0
Intro.ZIndex = 100
Intro.Visible = false
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
    Intro.Visible = true
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

    TweenService:Create(IntroText, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
    TweenService:Create(IntroSub, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
    TweenService:Create(Intro, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
    task.wait(0.7)
    Intro.Visible = false
end

--============ MAIN UI ============--
local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(600, 400)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
Main.BorderSizePixel = 0
Main.Visible = false
Main.ZIndex = 10
Main.Parent = ScreenGui

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)

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

Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 8)

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, -200, 1, 0)
TitleText.Position = UDim2.fromOffset(12, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "Onyx Hub"
TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 14
TitleText.ZIndex = 12
TitleText.Parent = TitleBar

-- Rival Script button
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

Instance.new("UICorner", RivalBtn).CornerRadius = UDim.new(0, 4)

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

local Pages, Tabs = {}, {}

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

    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 10)
    pad.Parent = btn

    local page = createPage(name)
    table.insert(Tabs, { btn = btn, page = page })
    Pages[name] = page

    btn.MouseButton1Click:Connect(function()
        for _, tab in ipairs(Tabs) do
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
    l.Size = UDim2.new(1, 0, 0, 26)
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
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

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
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 10)

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
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

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
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 3)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - minV) / (maxV - minV), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(120, 120, 255)
    fill.BorderSizePixel = 0
    fill.ZIndex = 14
    fill.Parent = bar
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 3)

    local dragging = false

    local function setFromX(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local val = minV + (maxV - minV) * rel
        if maxV - minV >= 10 then val = math.floor(val) end
        fill.Size = UDim2.new(rel, 0, 1, 0)
        lbl.Text = text .. ": " .. tostring(val)
        if callback then pcall(callback, val) end
    end

    track(UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            setFromX(input.Position.X)
        end
    end))

    track(bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            setFromX(input.Position.X)
        end
    end))

    track(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end))

    return row
end

-- Dropdown (모드 선택용)
local function addDropdown(parent, text, options, default, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 30)
    row.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
    row.BorderSizePixel = 0
    row.ZIndex = 12
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -140, 1, 0)
    lbl.Position = UDim2.fromOffset(10, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(220, 220, 230)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 13
    lbl.Parent = row

    local current = default or options[1]

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromOffset(120, 22)
    btn.Position = UDim2.new(1, -130, 0.5, -11)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    btn.BorderSizePixel = 0
    btn.Text = current
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 11
    btn.ZIndex = 13
    btn.Parent = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

    btn.MouseButton1Click:Connect(function()
        local idx = table.find(options, current) or 1
        idx = idx % #options + 1
        current = options[idx]
        btn.Text = current
        if callback then pcall(callback, current) end
    end)

    return row
end

--============ BUILD PAGES ============--
local MainPage     = createTab("Main")
local MiscPage     = createTab("Misc")
local SettingsPage = createTab("Settings")

-- ---- MAIN: ESP ----
addSection(MainPage, "ESP")
addToggle(MainPage, "ESP Enabled", CONFIG.ESP.Enabled,   function(v) CONFIG.ESP.Enabled = v end)
addToggle(MainPage, "Box",        CONFIG.ESP.Box,        function(v) CONFIG.ESP.Box = v end)
addToggle(MainPage, "Name",       CONFIG.ESP.Name,       function(v) CONFIG.ESP.Name = v end)
addToggle(MainPage, "Distance",   CONFIG.ESP.Distance,   function(v) CONFIG.ESP.Distance = v end)
addToggle(MainPage, "Health",     CONFIG.ESP.Health,     function(v) CONFIG.ESP.Health = v end)
addToggle(MainPage, "Tracer",     CONFIG.ESP.Tracer,     function(v) CONFIG.ESP.Tracer = v end)
addToggle(MainPage, "Team Check", CONFIG.ESP.TeamCheck,  function(v) CONFIG.ESP.TeamCheck = v end)
addSlider(MainPage, "Max Distance", 100, 5000, CONFIG.ESP.MaxDistance, function(v) CONFIG.ESP.MaxDistance = v end)

-- ---- MAIN: AIMBOT ----
addSection(MainPage, "Aimbot")
addToggle(MainPage, "Aimbot Enabled", CONFIG.AIM.Enabled,     function(v) CONFIG.AIM.Enabled = v end)
addDropdown(MainPage, "Aim Mode", { "Mouse", "Center" }, CONFIG.AIM.Mode, function(v) CONFIG.AIM.Mode = v end)
addToggle(MainPage, "Team Check",     CONFIG.AIM.TeamCheck,   function(v) CONFIG.AIM.TeamCheck = v end)
addToggle(MainPage, "Visible Only",   CONFIG.AIM.VisibleOnly, function(v) CONFIG.AIM.VisibleOnly = v end)
addToggle(MainPage, "Show FOV",       CONFIG.AIM.ShowFOV,     function(v) CONFIG.AIM.ShowFOV = v end)
addSlider(MainPage, "FOV",         10, 800, CONFIG.AIM.FOV,        function(v) CONFIG.AIM.FOV = v end)
addSlider(MainPage, "Smoothness",  1,  20,  CONFIG.AIM.Smoothness, function(v) CONFIG.AIM.Smoothness = v end)

-- ---- MISC ----
addSection(MiscPage, "Misc")
addLabel(MiscPage, "아직 기능 없음. 나중에 추가하면 여기 붙이면 됨.")

-- ---- SETTINGS ----
addSection(SettingsPage, "UI")
addLabel(SettingsPage, "UI 토글 키: RightShift")

addSection(SettingsPage, "Cursor")
addToggle(SettingsPage, "Cursor Free", false, function(v)
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
            dragging  = true
            dragStart = input.Position
            startPos  = Main.Position
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
    task.spawn(function()
        playIntro()
    end)
    task.delay(2.5, function()
        Main.Visible = true
        for _, tab in ipairs(Tabs) do
            tab.page.Visible = false
            tab.btn.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
            tab.btn.TextColor3 = Color3.fromRGB(180, 180, 190)
        end
        Pages["Main"].Visible = true
        Tabs[1].btn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
        Tabs[1].btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
end)

--============ KEYBINDS ============--
track(UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == CONFIG.UI_TOGGLE_KEY then
        Main.Visible = not Main.Visible
    elseif input.KeyCode == CONFIG.SHUTDOWN_KEY then
        cleanup()
        if ScreenGui then pcall(function() ScreenGui:Destroy() end) end
    end
end))

--============ FIRST OPEN ============--
Main.Visible = false
task.spawn(function()
    playIntro()
    Main.Visible = true
    Pages["Main"].Visible = true
    Tabs[1].btn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
    Tabs[1].btn.TextColor3 = Color3.fromRGB(255, 255, 255)
end)

print("[Onyx Hub] loaded | UI: RightShift | Shutdown: ;")
