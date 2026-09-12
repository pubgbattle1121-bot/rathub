--=========================================================
-- 🐭 RAT HUB v17.1
-- X 버튼 연결 수정
--=========================================================
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera    = workspace.CurrentCamera

local UI_TOGGLE_KEY    = {type = Enum.UserInputType.Keyboard, code = Enum.KeyCode.RightShift}
local RIVAL_TOGGLE_KEY = {type = Enum.UserInputType.Keyboard, code = Enum.KeyCode.RightControl}

local CHAMS_FILL    = Color3.fromRGB(80, 160, 255)
local CHAMS_OUTLINE = Color3.fromRGB(255, 255, 255)
local CHAMS_FILL_TRANSPARENCY = 0.5
local RIVAL_CHAMS_FILL = Color3.fromRGB(255, 90, 90)

local FreeCursor = { Enabled = false }
local Wallbang = { Enabled = false }

local connections = {}
local function track(c) table.insert(connections, c); return c end

local allDrawings = {}
local function registerDrawing(d) if d then allDrawings[d] = true end return d end
local function unregisterDrawing(d) if d then allDrawings[d] = nil end end

local function newBind(t, c) return {type = t, code = c} end
local function bindMatches(bind, input)
    if not bind then return false end
    if bind.type == Enum.UserInputType.Keyboard then
        return input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == bind.code
    end
    return input.UserInputType == bind.type
end
local function bindLabel(bind)
    if not bind then return "?" end
    if bind.type == Enum.UserInputType.Keyboard then
        return bind.code and bind.code.Name or "?"
    end
    return bind.type.Name
end

local old = playerGui:FindFirstChild("MouseGui")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "MouseGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

--=========================================================
-- FREE CURSOR
--=========================================================
track(RunService.RenderStepped:Connect(function()
    if FreeCursor.Enabled then
        pcall(function()
            if UIS.MouseBehavior ~= Enum.MouseBehavior.Default then
                UIS.MouseBehavior = Enum.MouseBehavior.Default
            end
            if not UIS.MouseIconEnabled then UIS.MouseIconEnabled = true end
        end)
    end
end))

--=========================================================
-- WALLBANG
--=========================================================
local wallbangOK = false
local originalNamecall = nil

if hookmetamethod and newcclosure and getnamecallmethod then
    local unpackFn = table.unpack or unpack
    local ok = pcall(function()
        originalNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if Wallbang.Enabled then
                if method == "Raycast" then
                    local args = {...}
                    local params = args[3]
                    if typeof(params) == "RaycastParams" then
                        local np = RaycastParams.new()
                        np.FilterType = Enum.RaycastFilterType.Exclude
                        np.FilterDescendantsInstances = {}
                        pcall(function() np.IgnoreWater = params.IgnoreWater end)
                        pcall(function() np.CollisionGroup = params.CollisionGroup end)
                        args[3] = np
                    end
                    return originalNamecall(self, unpackFn(args))
                elseif method == "FindPartOnRayWithIgnoreList" then
                    local args = {...}
                    if typeof(args[2]) == "table" then args[2] = {} end
                    return originalNamecall(self, unpackFn(args))
                elseif method == "FindPartOnRay" then
                    local args = {...}
                    args[2] = nil
                    return originalNamecall(self, unpackFn(args))
                end
            end
            return originalNamecall(self, ...)
        end))
    end)
    wallbangOK = ok
    if ok then
        print("[RAT HUB] Wallbang 활성화됨")
    else
        warn("[RAT HUB] Wallbang 훅 실패")
    end
else
    warn("[RAT HUB] hookmetamethod 미지원")
end

--=========================================================
-- 0. HUB
--=========================================================
local hubFrame = Instance.new("Frame")
hubFrame.AnchorPoint = Vector2.new(0.5, 0.5)
hubFrame.Size = UDim2.fromOffset(420, 300)
hubFrame.Position = UDim2.fromScale(0.5, 0.5)
hubFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
hubFrame.BorderSizePixel = 0
hubFrame.ZIndex = 40
hubFrame.Parent = gui
Instance.new("UICorner", hubFrame).CornerRadius = UDim.new(0, 18)

local hubStroke = Instance.new("UIStroke")
hubStroke.Color = Color3.fromRGB(255, 255, 255)
hubStroke.Thickness = 2
hubStroke.Transparency = 0.4
hubStroke.Parent = hubFrame

task.spawn(function()
    local hue = 0
    while hubFrame and hubFrame.Parent do
        hue = (hue + 0.008) % 1
        pcall(function() hubStroke.Color = Color3.fromHSV(hue, 0.9, 1) end)
        task.wait(0.03)
    end
end)

local hubTitle = Instance.new("TextLabel")
hubTitle.AnchorPoint = Vector2.new(0.5, 0)
hubTitle.Size = UDim2.new(1, 0, 0, 60)
hubTitle.Position = UDim2.new(0.5, 0, 0, 20)
hubTitle.BackgroundTransparency = 1
hubTitle.Text = "RAT HUB"
hubTitle.Font = Enum.Font.FredokaOne
hubTitle.TextSize = 44
hubTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
hubTitle.ZIndex = 41
hubTitle.Parent = hubFrame

task.spawn(function()
    local hue = 0
    while hubTitle and hubTitle.Parent do
        hue = (hue + 0.01) % 1
        pcall(function() hubTitle.TextColor3 = Color3.fromHSV(hue, 0.7, 1) end)
        task.wait(0.03)
    end
end)

local hubSub = Instance.new("TextLabel")
hubSub.AnchorPoint = Vector2.new(0.5, 0)
hubSub.Size = UDim2.new(1, -40, 0, 24)
hubSub.Position = UDim2.new(0.5, 0, 0, 78)
hubSub.BackgroundTransparency = 1
hubSub.Text = "원하는 스크립트를 선택하세요"
hubSub.Font = Enum.Font.GothamMedium
hubSub.TextSize = 14
hubSub.TextColor3 = Color3.fromRGB(150, 150, 165)
hubSub.ZIndex = 41
hubSub.Parent = hubFrame

local function makeHubButton(text, yPos, color)
    local btn = Instance.new("TextButton")
    btn.AnchorPoint = Vector2.new(0.5, 0)
    btn.Size = UDim2.new(1, -60, 0, 60)
    btn.Position = UDim2.new(0.5, 0, 0, yPos)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 17
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.AutoButtonColor = false
    btn.ZIndex = 41
    btn.Parent = hubFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.5
    stroke.Parent = btn
    track(btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(
            math.min(color.R * 255 + 40, 255),
            math.min(color.G * 255 + 40, 255),
            math.min(color.B * 255 + 40, 255))}):Play()
    end))
    track(btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = color}):Play()
    end))
    return btn
end

local hubBtnMouse = makeHubButton("🐭 쥐새끼가 나타났닷!!!", 120, Color3.fromRGB(90, 130, 220))
local hubBtnRival = makeHubButton("⚔ 라이벌 전용 스크립트", 195, Color3.fromRGB(180, 70, 70))

local function closeHub()
    TweenService:Create(hubFrame, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
    TweenService:Create(hubStroke, TweenInfo.new(0.25), {Transparency = 1}):Play()
    hubTitle.TextTransparency = 1
    hubSub.TextTransparency = 1
    hubBtnMouse.TextTransparency = 1
    hubBtnMouse.BackgroundTransparency = 1
    hubBtnRival.TextTransparency = 1
    hubBtnRival.BackgroundTransparency = 1
    task.wait(0.26)
    hubFrame.Visible = false
end

--=========================================================
-- 1. 인트로
--=========================================================
local function makeIntro(emojiText, labelText, emojiColor)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromScale(1, 1)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.ZIndex = 45
    frame.Parent = gui

    local emoji = Instance.new("TextLabel")
    emoji.AnchorPoint = Vector2.new(0.5, 0.5)
    emoji.Position = UDim2.fromScale(0.5, 0.3)
    emoji.Size = UDim2.fromScale(0.1, 0.03)
    emoji.BackgroundTransparency = 1
    emoji.Text = emojiText
    emoji.TextScaled = true
    emoji.TextTransparency = 1
    emoji.TextColor3 = emojiColor or Color3.fromRGB(255, 255, 255)
    emoji.ZIndex = 46
    emoji.Parent = frame

    local label = Instance.new("TextLabel")
    label.AnchorPoint = Vector2.new(0.5, 0.5)
    label.Position = UDim2.fromScale(0.5, 0.5)
    label.Size = UDim2.fromScale(0.1, 0.03)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.Font = Enum.Font.FredokaOne
    label.TextColor3 = emojiColor or Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.TextTransparency = 1
    label.ZIndex = 46
    label.Parent = frame
    return frame, emoji, label
end

local introMouse, mouseEmoji, mouseIntroText = makeIntro("🐭", "쥐새끼가 나왔닷!!")
local introRival, rivalEmoji, rivalIntroText = makeIntro("⚔", "라이벌 등장!", Color3.fromRGB(255, 130, 130))

local function playIntro(frame, emoji, text)
    frame.Visible = true
    frame.BackgroundTransparency = 1
    emoji.TextTransparency = 1
    emoji.Size = UDim2.fromScale(0.1, 0.03)
    text.TextTransparency = 1
    text.Size = UDim2.fromScale(0.1, 0.03)
    TweenService:Create(frame, TweenInfo.new(0.4), {BackgroundTransparency = 0.4}):Play()
    task.wait(0.25)
    TweenService:Create(emoji, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        TextTransparency = 0, Size = UDim2.fromScale(0.35, 0.1)}):Play()
    task.wait(0.2)
    TweenService:Create(text, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        TextTransparency = 0, Size = UDim2.fromScale(0.8, 0.15)}):Play()
    task.wait(1.6)
    TweenService:Create(emoji, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
    TweenService:Create(text, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
    TweenService:Create(frame, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
    task.wait(0.45)
    frame.Visible = false
end

--=========================================================
-- 2. 모드 버튼
--=========================================================
local toggleBtn = Instance.new("TextButton")
toggleBtn.AnchorPoint = Vector2.new(1, 0.5)
toggleBtn.Size = UDim2.fromOffset(85, 85)
toggleBtn.Position = UDim2.new(1, 150, 0.5, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
toggleBtn.Text = "🐭"
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 42
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.AutoButtonColor = false
toggleBtn.Visible = false
toggleBtn.ZIndex = 20
toggleBtn.Parent = gui
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)
local btnStroke = Instance.new("UIStroke")
btnStroke.Color = Color3.fromRGB(255, 255, 255)
btnStroke.Thickness = 3
btnStroke.Transparency = 0.3
btnStroke.Parent = toggleBtn

local rivalBtn = Instance.new("TextButton")
rivalBtn.AnchorPoint = Vector2.new(1, 0.5)
rivalBtn.Size = UDim2.fromOffset(85, 85)
rivalBtn.Position = UDim2.new(1, 150, 0.5, 0)
rivalBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
rivalBtn.Text = "⚔"
rivalBtn.Font = Enum.Font.GothamBold
rivalBtn.TextSize = 42
rivalBtn.TextColor3 = Color3.fromRGB(255, 230, 230)
rivalBtn.AutoButtonColor = false
rivalBtn.Visible = false
rivalBtn.ZIndex = 20
rivalBtn.Parent = gui
Instance.new("UICorner", rivalBtn).CornerRadius = UDim.new(1, 0)
local rivalBtnStroke = Instance.new("UIStroke")
rivalBtnStroke.Color = Color3.fromRGB(255, 150, 150)
rivalBtnStroke.Thickness = 3
rivalBtnStroke.Transparency = 0.3
rivalBtnStroke.Parent = rivalBtn

task.spawn(function()
    local hue = 0
    while gui and gui.Parent do
        hue = (hue + 0.006) % 1
        pcall(function()
            if toggleBtn.Visible then
                toggleBtn.BackgroundColor3 = Color3.fromHSV(hue, 0.85, 1)
                btnStroke.Color = Color3.fromHSV((hue + 0.5) % 1, 0.9, 1)
            end
        end)
        task.wait(0.03)
    end
end)
task.spawn(function()
    local t = 0
    while gui and gui.Parent do
        t = t + 0.05
        pcall(function()
            if rivalBtn.Visible then
                local p = (math.sin(t) + 1) / 2
                rivalBtn.BackgroundColor3 = Color3.fromRGB(200, 60 + math.floor(p * 40), 60 + math.floor(p * 40))
            end
        end)
        task.wait(0.05)
    end
end)

track(toggleBtn.MouseEnter:Connect(function() TweenService:Create(toggleBtn, TweenInfo.new(0.15), {Size = UDim2.fromOffset(95, 95)}):Play() end))
track(toggleBtn.MouseLeave:Connect(function() TweenService:Create(toggleBtn, TweenInfo.new(0.15), {Size = UDim2.fromOffset(85, 85)}):Play() end))
track(rivalBtn.MouseEnter:Connect(function() TweenService:Create(rivalBtn, TweenInfo.new(0.15), {Size = UDim2.fromOffset(95, 95)}):Play() end))
track(rivalBtn.MouseLeave:Connect(function() TweenService:Create(rivalBtn, TweenInfo.new(0.15), {Size = UDim2.fromOffset(85, 85)}):Play() end))

--=========================================================
-- 3. 패널 팩토리
--=========================================================
local function createPanel(cfg)
    local W, H = cfg.w, cfg.h
    local WO, HO = cfg.wOpen, cfg.hOpen
    local style = cfg.style or "blue"
    local accentDim = style == "red" and Color3.fromRGB(80, 50, 50) or Color3.fromRGB(30, 30, 38)
    local accentActive = style == "red" and Color3.fromRGB(140, 60, 60) or Color3.fromRGB(80, 90, 130)
    local titleColor = style == "red" and Color3.fromRGB(255, 180, 180) or Color3.fromRGB(255, 255, 255)
    local bgColor = style == "red" and Color3.fromRGB(28, 14, 14) or Color3.fromRGB(20, 20, 25)
    local strokeColor = style == "red" and Color3.fromRGB(220, 70, 70) or Color3.fromRGB(255, 255, 255)

    local frame = Instance.new("Frame")
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Size = UDim2.fromOffset(W, H)
    frame.Position = UDim2.fromScale(0.5, 0.5)
    frame.BackgroundColor3 = bgColor
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.ZIndex = 15
    frame.Parent = gui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)

    local stroke = Instance.new("UIStroke")
    stroke.Color = strokeColor
    stroke.Thickness = style == "red" and 2 or 1.5
    stroke.Transparency = 0.7
    stroke.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -100, 0, 38)
    title.Position = UDim2.new(0, 20, 0, 14)
    title.BackgroundTransparency = 1
    title.Text = cfg.title
    title.Font = Enum.Font.FredokaOne
    title.TextSize = 24
    title.TextColor3 = titleColor
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 16
    title.Parent = frame

    local closeBtn = Instance.new("TextButton")
    closeBtn.AnchorPoint = Vector2.new(1, 0)
    closeBtn.Size = UDim2.fromOffset(34, 34)
    closeBtn.Position = UDim2.new(1, -18, 0, 18)
    closeBtn.BackgroundColor3 = style == "red" and Color3.fromRGB(80, 50, 50) or Color3.fromRGB(60, 60, 70)
    closeBtn.Text = "✕"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 15
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.ZIndex = 16
    closeBtn.Parent = frame
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)

    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, -40, 0, 40)
    tabBar.Position = UDim2.new(0, 20, 0, 62)
    tabBar.BackgroundColor3 = accentDim
    tabBar.BorderSizePixel = 0
    tabBar.ZIndex = 16
    tabBar.Parent = frame
    Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0, 10)

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.Parent = tabBar

    local tabPad = Instance.new("UIPadding")
    tabPad.PaddingLeft = UDim.new(0, 5)
    tabPad.PaddingRight = UDim.new(0, 5)
    tabPad.PaddingTop = UDim.new(0, 5)
    tabPad.PaddingBottom = UDim.new(0, 5)
    tabPad.Parent = tabBar

    local contentHolder = Instance.new("Frame")
    contentHolder.Size = UDim2.new(1, -40, 1, -122)
    contentHolder.Position = UDim2.new(0, 20, 0, 110)
    contentHolder.BackgroundTransparency = 1
    contentHolder.ZIndex = 16
    contentHolder.Parent = frame

    local pages = {}
    local tabButtons = {}
    local currentTab = nil
    local tabNames = {"MAIN", "MISC", "SETTINGS"}

    local function selectTab(name)
        if currentTab == name then return end
        currentTab = name
        for n, page in pairs(pages) do page.Visible = (n == name) end
        for n, btn in pairs(tabButtons) do
            local active = (n == name)
            TweenService:Create(btn, TweenInfo.new(0.15), {
                BackgroundColor3 = active and accentActive or accentDim}):Play()
            btn.TextColor3 = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 160)
        end
    end

    for i, name in ipairs(tabNames) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(1/#tabNames, -5, 1, 0)
        tabBtn.BackgroundColor3 = accentDim
        tabBtn.Text = name
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.TextSize = 15
        tabBtn.TextColor3 = Color3.fromRGB(150, 150, 160)
        tabBtn.LayoutOrder = i
        tabBtn.AutoButtonColor = false
        tabBtn.ZIndex = 17
        tabBtn.Parent = tabBar
        Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 8)
        tabButtons[name] = tabBtn

        local page = Instance.new("ScrollingFrame")
        page.Size = UDim2.fromScale(1, 1)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 5
        page.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 110)
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.Visible = false
        page.ZIndex = 17
        page.Parent = contentHolder

        local pl = Instance.new("UIListLayout")
        pl.Padding = UDim.new(0, 8)
        pl.SortOrder = Enum.SortOrder.LayoutOrder
        pl.Parent = page

        local pp = Instance.new("UIPadding")
        pp.PaddingRight = UDim.new(0, 8)
        pp.Parent = page

        pages[name] = page
        track(tabBtn.MouseButton1Click:Connect(function() selectTab(name) end))
    end

    selectTab("MAIN")

    local isOpen, isAnim = false, false
    local function open()
        if isOpen or isAnim then return end
        isAnim = true; isOpen = true
        frame.Visible = true
        frame.Size = UDim2.fromOffset(W, H)
        frame.BackgroundTransparency = 1
        stroke.Transparency = 1
        TweenService:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(WO, HO), BackgroundTransparency = 0}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.35), {Transparency = 0.7}):Play()
        task.wait(0.36); isAnim = false
    end
    local function close()
        if not isOpen or isAnim then return end
        isAnim = true; isOpen = false
        TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.fromOffset(W, H), BackgroundTransparency = 1}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.2), {Transparency = 1}):Play()
        task.wait(0.21); frame.Visible = false; isAnim = false
    end
    local function toggle()
        if isOpen then close() else open() end
    end

    -- ★ X 버튼 연결
    track(closeBtn.MouseButton1Click:Connect(function()
        close()
    end))

    return {
        frame = frame, pages = pages, selectTab = selectTab,
        open = open, close = close, toggle = toggle,
    }
end

--=========================================================
-- 4. UI 헬퍼
--=========================================================
local function getStyle(style)
    if style == "red" then
        return {
            rowBg = Color3.fromRGB(45, 28, 28), labelColor = Color3.fromRGB(240, 210, 210),
            switchOff = Color3.fromRGB(80, 50, 50), onColor = Color3.fromRGB(220, 80, 80),
            barBg = Color3.fromRGB(70, 45, 45), fillColor = Color3.fromRGB(220, 80, 80),
            valueColor = Color3.fromRGB(255, 160, 160), sectionColor = Color3.fromRGB(255, 130, 130),
            btnBg = Color3.fromRGB(80, 50, 50), btnText = Color3.fromRGB(255, 180, 180),
            expanderBg = Color3.fromRGB(60, 40, 40), expanderOpen = Color3.fromRGB(90, 55, 55),
        }
    else
        return {
            rowBg = Color3.fromRGB(34, 34, 42), labelColor = Color3.fromRGB(220, 220, 230),
            switchOff = Color3.fromRGB(60, 60, 72), onColor = Color3.fromRGB(80, 160, 255),
            barBg = Color3.fromRGB(50, 50, 60), fillColor = Color3.fromRGB(80, 160, 255),
            valueColor = Color3.fromRGB(120, 170, 255), sectionColor = Color3.fromRGB(120, 170, 255),
            btnBg = Color3.fromRGB(50, 55, 70), btnText = Color3.fromRGB(180, 200, 255),
            expanderBg = Color3.fromRGB(40, 40, 50), expanderOpen = Color3.fromRGB(50, 55, 70),
        }
    end
end

local function makeSection(parent, text, order, style)
    local s = getStyle(style)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 26)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 15
    lbl.TextColor3 = s.sectionColor
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = order
    lbl.ZIndex = 18
    lbl.Parent = parent
    return lbl
end

local function makeLabel(parent, text, order, color)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 26)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 14
    lbl.TextColor3 = color or Color3.fromRGB(200, 200, 210)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = order
    lbl.ZIndex = 18
    lbl.Parent = parent
    return lbl
end

local function makeToggle(parent, text, order, default, callback, style, indent)
    style = style or "blue"; indent = indent or 0
    local s = getStyle(style)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 40)
    row.BackgroundColor3 = s.rowBg
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.ZIndex = 18
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 9)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -100, 1, 0)
    label.Position = UDim2.new(0, 16 + indent, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 15
    label.TextColor3 = s.labelColor
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 19
    label.Parent = row

    local switch = Instance.new("Frame")
    switch.AnchorPoint = Vector2.new(1, 0.5)
    switch.Size = UDim2.fromOffset(46, 24)
    switch.Position = UDim2.new(1, -14, 0.5, 0)
    switch.BackgroundColor3 = s.switchOff
    switch.BorderSizePixel = 0
    switch.ZIndex = 19
    switch.Parent = row
    Instance.new("UICorner", switch).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(0, 0.5)
    knob.Size = UDim2.fromOffset(18, 18)
    knob.Position = UDim2.new(0, 3, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(210, 210, 220)
    knob.BorderSizePixel = 0
    knob.ZIndex = 20
    knob.Parent = switch
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local state = default and true or false
    local function render()
        TweenService:Create(switch, TweenInfo.new(0.18), {
            BackgroundColor3 = state and s.onColor or s.switchOff}):Play()
        TweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = state and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)}):Play()
    end
    render()

    local click = Instance.new("TextButton")
    click.Size = UDim2.fromScale(1, 1)
    click.BackgroundTransparency = 1
    click.Text = ""
    click.ZIndex = 21
    click.Parent = row
    track(click.MouseButton1Click:Connect(function()
        state = not state
        render()
        if callback then callback(state) end
    end))
    return row
end

local function makeSlider(parent, text, order, min, max, default, callback, style)
    style = style or "blue"
    local s = getStyle(style)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 56)
    row.BackgroundColor3 = s.rowBg
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.ZIndex = 18
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 9)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -100, 0, 24)
    label.Position = UDim2.new(0, 16, 0, 6)
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 15
    label.TextColor3 = s.labelColor
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 19
    label.Parent = row

    local valueLbl = Instance.new("TextLabel")
    valueLbl.AnchorPoint = Vector2.new(1, 0)
    valueLbl.Size = UDim2.new(0, 80, 0, 24)
    valueLbl.Position = UDim2.new(1, -14, 0, 6)
    valueLbl.BackgroundTransparency = 1
    valueLbl.Text = tostring(default)
    valueLbl.Font = Enum.Font.GothamBold
    valueLbl.TextSize = 14
    valueLbl.TextColor3 = s.valueColor
    valueLbl.TextXAlignment = Enum.TextXAlignment.Right
    valueLbl.ZIndex = 19
    valueLbl.Parent = row

    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(1, -32, 0, 9)
    barBg.Position = UDim2.new(0, 16, 0, 38)
    barBg.BackgroundColor3 = s.barBg
    barBg.BorderSizePixel = 0
    barBg.ZIndex = 19
    barBg.Parent = row
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

    local barFill = Instance.new("Frame")
    barFill.Size = UDim2.new(0, 0, 1, 0)
    barFill.BackgroundColor3 = s.fillColor
    barFill.BorderSizePixel = 0
    barFill.ZIndex = 20
    barFill.Parent = barBg
    Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Size = UDim2.fromOffset(16, 16)
    knob.Position = UDim2.new(0, 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(240, 240, 250)
    knob.BorderSizePixel = 0
    knob.ZIndex = 21
    knob.Parent = barBg
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local value = default
    local function render()
        local alpha = (max - min) > 0 and (value - min) / (max - min) or 0
        alpha = math.clamp(alpha, 0, 1)
        barFill.Size = UDim2.new(alpha, 0, 1, 0)
        knob.Position = UDim2.new(alpha, 0, 0.5, 0)
        valueLbl.Text = tostring(math.floor(value * 100) / 100)
    end
    render()

    local clicking = false
    local function setFromX(x)
        local barAbs = barBg.AbsolutePosition
        local barW = barBg.AbsoluteSize.X
        if barW <= 0 then return end
        local rel = math.clamp((x - barAbs.X) / barW, 0, 1)
        value = min + rel * (max - min)
        render()
        if callback then callback(value) end
    end

    local clickArea = Instance.new("TextButton")
    clickArea.Size = UDim2.new(1, 0, 0, 32)
    clickArea.Position = UDim2.new(0, 0, 1, -32)
    clickArea.BackgroundTransparency = 1
    clickArea.Text = ""
    clickArea.ZIndex = 22
    clickArea.Parent = row
    track(clickArea.MouseButton1Down:Connect(function(x) clicking = true; setFromX(x) end))
    track(UIS.InputChanged:Connect(function(input)
        if clicking and input.UserInputType == Enum.UserInputType.MouseMovement then setFromX(input.Position.X) end
    end))
    track(UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then clicking = false end
    end))
    return row
end

local function makeExpander(parent, text, order, targetContainer, style)
    style = style or "blue"
    local s = getStyle(style)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = s.expanderBg
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.LayoutOrder = order
    btn.ZIndex = 18
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 9)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -50, 1, 0)
    lbl.Position = UDim2.new(0, 16, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 15
    lbl.TextColor3 = s.labelColor
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 19
    lbl.Parent = btn

    local arrow = Instance.new("TextLabel")
    arrow.AnchorPoint = Vector2.new(1, 0.5)
    arrow.Size = UDim2.fromOffset(24, 24)
    arrow.Position = UDim2.new(1, -14, 0.5, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▶"
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 14
    arrow.TextColor3 = s.valueColor
    arrow.ZIndex = 19
    arrow.Parent = btn

    local open = false
    track(btn.MouseButton1Click:Connect(function()
        open = not open
        targetContainer.Visible = open
        arrow.Text = open and "▼" or "▶"
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = open and s.expanderOpen or s.expanderBg}):Play()
    end))
    return btn
end

local function makeKeybind(parent, text, order, initialBind, onChange, style)
    style = style or "blue"
    local s = getStyle(style)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 40)
    row.BackgroundColor3 = s.rowBg
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.ZIndex = 18
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 9)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -110, 1, 0)
    label.Position = UDim2.new(0, 16, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 15
    label.TextColor3 = s.labelColor
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 19
    label.Parent = row

    local bindBtn = Instance.new("TextButton")
    bindBtn.AnchorPoint = Vector2.new(1, 0.5)
    bindBtn.Size = UDim2.fromOffset(95, 26)
    bindBtn.Position = UDim2.new(1, -14, 0.5, 0)
    bindBtn.BackgroundColor3 = s.btnBg
    bindBtn.Text = bindLabel(initialBind)
    bindBtn.Font = Enum.Font.GothamBold
    bindBtn.TextSize = 12
    bindBtn.TextColor3 = s.btnText
    bindBtn.AutoButtonColor = false
    bindBtn.ZIndex = 19
    bindBtn.Parent = row
    Instance.new("UICorner", bindBtn).CornerRadius = UDim.new(0, 6)

    local listening = false
    bindBtn.MouseButton1Click:Connect(function()
        listening = true
        bindBtn.Text = "..."
        bindBtn.BackgroundColor3 = Color3.fromRGB(90, 60, 60)
        bindBtn.TextColor3 = Color3.fromRGB(255, 180, 180)
    end)

    track(UIS.InputBegan:Connect(function(input)
        if not listening then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            listening = false
            bindBtn.Text = input.KeyCode.Name
            bindBtn.BackgroundColor3 = s.btnBg
            bindBtn.TextColor3 = s.btnText
            if onChange then onChange(newBind(Enum.UserInputType.Keyboard, input.KeyCode)) end
        elseif input.UserInputType == Enum.UserInputType.MouseButton2
            or input.UserInputType == Enum.UserInputType.MouseButton3 then
            listening = false
            bindBtn.Text = input.UserInputType.Name
            bindBtn.BackgroundColor3 = s.btnBg
            bindBtn.TextColor3 = s.btnText
            if onChange then onChange(newBind(input.UserInputType)) end
        end
    end))
    return row
end

--=========================================================
-- 5. ESP 팩토리
--=========================================================
local HAS_DRAWING = (Drawing ~= nil)
if not HAS_DRAWING then
    warn("[RAT HUB] Drawing 미지원 — ESP 일부 비활성.")
end

local function killDrawing(d)
    if not d then return end
    pcall(function() if d.Visible ~= nil then d.Visible = false end end)
    pcall(function() if d.Text ~= nil then d.Text = "" end end)
    pcall(function() if d.Transparency ~= nil then d.Transparency = 0 end end)
    pcall(function() if d.Thickness ~= nil then d.Thickness = 0 end end)
    pcall(function() if d.Size ~= nil then d.Size = Vector2.new(0, 0) end end)
    pcall(function() if d.Radius ~= nil then d.Radius = 0 end end)
    pcall(function() if d.From ~= nil then d.From = Vector2.new(0, 0) end end)
    pcall(function() if d.To ~= nil then d.To = Vector2.new(0, 0) end end)
    pcall(function() if d.Position ~= nil then d.Position = Vector2.new(0, 0) end end)
    pcall(function() d:Remove() end)
    unregisterDrawing(d)
end

local function createESP(cfg)
    local esp = {
        Enabled = false, Skeleton = false, Box = false,
        Name = false, Distance = false, Health = false, Chams = false,
        fillColor = cfg and cfg.fillColor or CHAMS_FILL,
        outlineColor = cfg and cfg.outlineColor or CHAMS_OUTLINE,
    }
    local objects = {}
    local enabled = false

    local function hideAll(o)
        if o.box then killDrawing(o.box); o.box = nil end
        if o.name then killDrawing(o.name); o.name = nil end
        if o.dist then killDrawing(o.dist); o.dist = nil end
        if o.health then killDrawing(o.health); o.health = nil end
        if o.skel then
            for _, line in ipairs(o.skel) do killDrawing(line) end
            o.skel = {}
        end
    end

    local function cleanupPlayer(plr)
        local o = objects[plr]
        if not o then return end
        hideAll(o)
        if o.highlight then
            pcall(function() o.highlight.Adornee = nil end)
            if o.highlight.Parent then pcall(function() o.highlight:Destroy() end) end
            o.highlight = nil
        end
        objects[plr] = nil
    end

    local function newLine()
        if not HAS_DRAWING then return nil end
        local l = Drawing.new("Line")
        l.Thickness = 1; l.Color = Color3.fromRGB(255,255,255); l.Transparency = 1; l.Visible = false
        registerDrawing(l); return l
    end
    local function newText()
        if not HAS_DRAWING then return nil end
        local t = Drawing.new("Text")
        t.Size = 14; t.Center = true; t.Outline = true; t.Color = Color3.fromRGB(255,255,255); t.Visible = false
        registerDrawing(t); return t
    end
    local function newBox()
        if not HAS_DRAWING then return nil end
        local s = Drawing.new("Square")
        s.Thickness = 1; s.Filled = false; s.Color = Color3.fromRGB(255,255,255)
        s.Position = Vector2.new(0,0); s.Size = Vector2.new(0,0); s.Visible = false
        registerDrawing(s); return s
    end

    local function getSkeletonParts(char)
        local r15 = {
            {"Head","UpperTorso"}, {"UpperTorso","LowerTorso"},
            {"UpperTorso","LeftUpperArm"}, {"LeftUpperArm","LeftLowerArm"}, {"LeftLowerArm","LeftHand"},
            {"UpperTorso","RightUpperArm"}, {"RightUpperArm","RightLowerArm"}, {"RightLowerArm","RightHand"},
            {"LowerTorso","LeftUpperLeg"}, {"LeftUpperLeg","LeftLowerLeg"}, {"LeftLowerLeg","LeftFoot"},
            {"LowerTorso","RightUpperLeg"}, {"RightUpperLeg","RightLowerLeg"}, {"RightLowerLeg","RightFoot"},
        }
        local r6 = {
            {"Head","Torso"},
            {"Torso","Left Arm"}, {"Torso","Right Arm"},
            {"Torso","Left Leg"}, {"Torso","Right Leg"},
        }
        if char:FindFirstChild("UpperTorso") then return r15 end
        return r6
    end

    local function ensureESP(plr, char)
        if objects[plr] then return objects[plr] end
        local o = {box = newBox(), name = newText(), dist = newText(), health = nil, skel = {}, highlight = nil, character = char}
        for _ = 1, #getSkeletonParts(char) do table.insert(o.skel, newLine()) end
        objects[plr] = o
        return o
    end

    local function projectCorners(char)
        local ok, cf, size = pcall(function() return char:GetBoundingBox() end)
        if not ok then return nil end
        local pts = {}
        for x = -1, 1, 2 do for y = -1, 1, 2 do for z = -1, 1, 2 do
            local world = cf * Vector3.new(size.X/2*x, size.Y/2*y, size.Z/2*z)
            local sp, on = camera:WorldToViewportPoint(world)
            if on then table.insert(pts, Vector2.new(sp.X, sp.Y)) end
        end end end
        if #pts < 2 then return nil end
        local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
        for _, p in ipairs(pts) do
            minX = math.min(minX, p.X); minY = math.min(minY, p.Y)
            maxX = math.max(maxX, p.X); maxY = math.max(maxY, p.Y)
        end
        return minX, minY, maxX, maxY
    end

    local function w2s(pos)
        local sp, on = camera:WorldToViewportPoint(pos)
        return Vector2.new(sp.X, sp.Y), on
    end

    local function updatePlayer(plr)
        local char = plr.Character
        if not char then cleanupPlayer(plr); return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local head = char:FindFirstChild("Head")
        if not hum or not head or hum.Health <= 0 then cleanupPlayer(plr); return end

        local existing = objects[plr]
        if existing and existing.character ~= char then cleanupPlayer(plr) end

        local o = ensureESP(plr, char)
        if not o then return end

        local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end
        local dist = (myRoot.Position - head.Position).Magnitude

        if esp.Box then
            if not o.box then o.box = newBox() end
            local minX, minY, maxX, maxY = projectCorners(char)
            if minX then
                o.box.Visible = true
                o.box.Position = Vector2.new(minX, minY)
                o.box.Size = Vector2.new(maxX - minX, maxY - minY)
            else o.box.Visible = false end
        elseif o.box then killDrawing(o.box); o.box = nil end

        if esp.Skeleton then
            local joints = getSkeletonParts(char)
            if #o.skel < #joints then
                for _ = #o.skel + 1, #joints do table.insert(o.skel, newLine()) end
            end
            for i, joint in ipairs(joints) do
                local line = o.skel[i]
                if line then
                    local a = char:FindFirstChild(joint[1])
                    local b = char:FindFirstChild(joint[2])
                    if a and b then
                        local pa, oa = w2s(a.Position); local pb, ob = w2s(b.Position)
                        line.Visible = oa and ob; line.From = pa; line.To = pb
                    else line.Visible = false end
                end
            end
        else
            for _, line in ipairs(o.skel) do killDrawing(line) end
            o.skel = {}
        end

        if esp.Name then
            if not o.name then o.name = newText() end
            local pos, on = w2s(head.Position + Vector3.new(0, 1.5, 0))
            o.name.Visible = on; o.name.Position = pos; o.name.Text = plr.Name
        elseif o.name then killDrawing(o.name); o.name = nil end

        if esp.Distance then
            if not o.dist then o.dist = newText(); o.dist.Size = 13 end
            local pos, on = w2s(head.Position + Vector3.new(0, 1.1, 0))
            o.dist.Visible = on; o.dist.Position = pos
            o.dist.Text = string.format("%d m", math.floor(dist))
        elseif o.dist then killDrawing(o.dist); o.dist = nil end

        if esp.Health and HAS_DRAWING then
            if not o.health then
                o.health = newText(); o.health.Size = 12
                o.health.Color = Color3.fromRGB(120, 255, 120)
            end
            local pos, on = w2s(head.Position + Vector3.new(0, 0.8, 0))
            o.health.Visible = on; o.health.Position = pos
            o.health.Text = string.format("HP: %d", math.floor(hum.Health))
        elseif o.health then killDrawing(o.health); o.health = nil end

        if esp.Chams then
            if o.highlight and (not o.highlight.Parent or o.highlight.Adornee ~= char) then
                pcall(function() o.highlight.Adornee = nil end)
                if o.highlight.Parent then o.highlight:Destroy() end
                o.highlight = nil
            end
            if not o.highlight then
                local h = Instance.new("Highlight")
                h.Name = "RATChams"
                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                h.FillColor = esp.fillColor
                h.FillTransparency = CHAMS_FILL_TRANSPARENCY
                h.OutlineColor = esp.outlineColor
                h.OutlineTransparency = 0
                h.Adornee = char
                h.Parent = gui
                o.highlight = h
            end
        else
            if o.highlight then
                pcall(function() o.highlight.Adornee = nil end)
                if o.highlight.Parent then o.highlight:Destroy() end
                o.highlight = nil
            end
        end
    end

    track(RunService.RenderStepped:Connect(function()
        if not enabled then
            local snap = {}
            for plr in pairs(objects) do table.insert(snap, plr) end
            for _, plr in ipairs(snap) do cleanupPlayer(plr) end
            return
        end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player then updatePlayer(plr) end
        end
    end))

    track(Players.PlayerRemoving:Connect(cleanupPlayer))

    local function hookPlayer(plr)
        if plr == player then return end
        track(plr.CharacterRemoving:Connect(function() cleanupPlayer(plr) end))
    end
    for _, plr in ipairs(Players:GetPlayers()) do hookPlayer(plr) end
    track(Players.PlayerAdded:Connect(hookPlayer))

    esp.setEnabled = function(v)
        enabled = v
        esp.Enabled = v
        if not v then
            esp.Skeleton, esp.Box, esp.Name, esp.Distance, esp.Health, esp.Chams = false, false, false, false, false, false
            local snap = {}
            for plr in pairs(objects) do table.insert(snap, plr) end
            for _, plr in ipairs(snap) do cleanupPlayer(plr) end
        end
    end

    esp.destroy = function()
        local snap = {}
        for plr in pairs(objects) do table.insert(snap, plr) end
        for _, plr in ipairs(snap) do cleanupPlayer(plr) end
    end

    return esp
end

--=========================================================
-- 6. AIMBOT 팩토리
--=========================================================
local function isSameTeamFor(plr)
    if player.Team == nil or plr.Team == nil then return false end
    return player.Team == plr.Team
end

local function createAimbot(name, circleColor)
    local aim = {
        Enabled = false, FovShown = false, FovSize = 150,
        Smooth = 5, WallCheck = false, TeamCheck = false, SnapRadius = 8,
    }
    local fovCircle = nil
    if HAS_DRAWING then
        fovCircle = Drawing.new("Circle")
        fovCircle.Thickness = 1; fovCircle.NumSides = 60
        fovCircle.Radius = aim.FovSize
        fovCircle.Color = circleColor or Color3.fromRGB(255, 255, 255)
        fovCircle.Filled = false; fovCircle.Transparency = 1; fovCircle.Visible = false
        registerDrawing(fovCircle)
    end

    local function hasLineOfSight(char, targetPart)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { player.Character, char }
        local origin = camera.CFrame.Position
        local result = workspace:Raycast(origin, targetPart.Position - origin, params)
        return result == nil
    end

    local function findTarget()
        local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
        local best, bestPixDist = nil, math.huge
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player then
                local skip = false
                if aim.TeamCheck and isSameTeamFor(plr) then skip = true end
                if not skip then
                    local char = plr.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    local head = char and char:FindFirstChild("Head")
                    if char and hum and head and hum.Health > 0 then
                        local sp, on = camera:WorldToViewportPoint(head.Position)
                        if on and sp.Z > 0 then
                            local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                            if d <= aim.FovSize and d < bestPixDist then
                                if aim.WallCheck then
                                    if hasLineOfSight(char, head) then best = head; bestPixDist = d end
                                else
                                    best = head; bestPixDist = d
                                end
                            end
                        end
                    end
                end
            end
        end
        return best, bestPixDist
    end

    local bindName = name .. "_Aimbot"
    RunService:BindToRenderStep(bindName, Enum.RenderPriority.Camera.Value + 10, function(dt)
        if fovCircle then
            if aim.Enabled and aim.FovShown then
                fovCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
                fovCircle.Radius = aim.FovSize
                fovCircle.Visible = true
            else fovCircle.Visible = false end
        end
        if not aim.Enabled then return end
        local target, pixDist = findTarget()
        if not target then return end
        local targetCF = CFrame.new(camera.CFrame.Position, target.Position)
        if pixDist and pixDist < aim.SnapRadius then
            camera.CFrame = targetCF
        else
            local alpha
            if aim.Smooth <= 1 then alpha = 1
            else
                local speed = 20 / aim.Smooth
                alpha = math.clamp(1 - math.exp(-speed * dt), 0, 1)
            end
            camera.CFrame = camera.CFrame:Lerp(targetCF, alpha)
        end
    end)

    aim.destroy = function()
        pcall(function() RunService:UnbindFromRenderStep(bindName) end)
        if fovCircle then
            pcall(function() fovCircle.Visible = false end)
            pcall(function() fovCircle:Remove() end)
            unregisterDrawing(fovCircle)
            fovCircle = nil
        end
    end
    return aim
end

--=========================================================
-- 7. TRIGGERBOT 팩토리
--=========================================================
local function createTriggerbot(name)
    local tb = {
        Enabled = false,
        Bind = newBind(Enum.UserInputType.Keyboard, Enum.KeyCode.E),
        TeamCheck = false, Delay = 0.05,
    }
    local pressed = false
    local lastFire = 0

    local function fireMouse()
        pcall(function() mouse1click() end)
        pcall(function() mouse1down(); task.wait(0.02); mouse1up() end)
    end

    local function isTargetUnderCrosshair()
        local origin = camera.CFrame.Position
        local direction = camera.CFrame.LookVector * 500
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { player.Character }
        local result = workspace:Raycast(origin, direction, params)
        if result and result.Instance then
            local model = result.Instance:FindFirstAncestorOfClass("Model")
            if model then
                local hitPlr = Players:GetPlayerFromCharacter(model)
                if hitPlr and hitPlr ~= player then
                    local hum = model:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        if tb.TeamCheck and isSameTeamFor(hitPlr) then return false end
                        return true
                    end
                end
            end
        end
        return false
    end

    track(UIS.InputBegan:Connect(function(input, gp)
        if gp then return end
        if bindMatches(tb.Bind, input) then pressed = true end
    end))
    track(UIS.InputEnded:Connect(function(input)
        if bindMatches(tb.Bind, input) then pressed = false end
    end))

    track(RunService.RenderStepped:Connect(function()
        if not tb.Enabled then return end
        if not pressed then return end
        local now = tick()
        if now - lastFire < tb.Delay then return end
        if isTargetUnderCrosshair() then
            fireMouse(); lastFire = now
        end
    end))

    tb.resetPressed = function() pressed = false end
    return tb
end

--=========================================================
-- 8. 인스턴스 생성
--=========================================================
local mouseESP = createESP({fillColor = CHAMS_FILL, outlineColor = CHAMS_OUTLINE})
local rivalESP = createESP({fillColor = RIVAL_CHAMS_FILL, outlineColor = Color3.fromRGB(255, 200, 200)})
local mouseAimbot = createAimbot("Mouse", Color3.fromRGB(255, 255, 255))
local rivalAimbot = createAimbot("Rival", Color3.fromRGB(255, 130, 130))
local mouseTrigger = createTriggerbot("Mouse")
local rivalTrigger = createTriggerbot("Rival")

--=========================================================
-- 9. 패널
--=========================================================
local mousePanel = createPanel({
    title = "🐭 쥐새끼 메뉴", style = "blue",
    w = 560, h = 410, wOpen = 620, hOpen = 460,
})
local rivalPanel = createPanel({
    title = "⚔ 라이벌 전용", style = "red",
    w = 560, h = 410, wOpen = 620, hOpen = 460,
})

--=========================================================
-- 10. 쥐새끼 패널 컨텐츠
--=========================================================
local mMAIN = mousePanel.pages["MAIN"]
local mMISC = mousePanel.pages["MISC"]
local mSET = mousePanel.pages["SETTINGS"]

makeSection(mMAIN, "── ESP ──", 1, "blue")
makeToggle(mMAIN, "ESP ON", 2, false, function(on) mouseESP.setEnabled(on) end, "blue")

local mEspContainer = Instance.new("Frame")
mEspContainer.Size = UDim2.new(1, 0, 0, 0)
mEspContainer.AutomaticSize = Enum.AutomaticSize.Y
mEspContainer.BackgroundTransparency = 1
mEspContainer.LayoutOrder = 4
mEspContainer.Visible = false
mEspContainer.ZIndex = 18
mEspContainer.Parent = mMAIN
local mEspLayout = Instance.new("UIListLayout")
mEspLayout.Padding = UDim.new(0, 8)
mEspLayout.SortOrder = Enum.SortOrder.LayoutOrder
mEspLayout.Parent = mEspContainer

makeExpander(mMAIN, "ESP 기능", 3, mEspContainer, "blue")
makeToggle(mEspContainer, "SKELETON", 1, false, function(on) mouseESP.Skeleton = on end, "blue", 22)
makeToggle(mEspContainer, "BOX",      2, false, function(on) mouseESP.Box = on end, "blue", 22)
makeToggle(mEspContainer, "NAME",     3, false, function(on) mouseESP.Name = on end, "blue", 22)
makeToggle(mEspContainer, "DISTANCE", 4, false, function(on) mouseESP.Distance = on end, "blue", 22)
makeToggle(mEspContainer, "HEALTH",   5, false, function(on) mouseESP.Health = on end, "blue", 22)
makeToggle(mEspContainer, "CHAMS",    6, false, function(on) mouseESP.Chams = on end, "blue", 22)

makeSection(mMAIN, "── AIMBOT ──", 20, "blue")
makeToggle(mMAIN, "AIMBOT ON", 21, false, function(on) mouseAimbot.Enabled = on end, "blue")
makeToggle(mMAIN, "FOV", 22, false, function(on) mouseAimbot.FovShown = on end, "blue")
makeSlider(mMAIN, "FOV SIZE", 23, 20, 600, 150, function(v) mouseAimbot.FovSize = v end, "blue")
makeSlider(mMAIN, "SMOOTH", 24, 1, 20, 5, function(v) mouseAimbot.Smooth = v end, "blue")
makeSlider(mMAIN, "SNAP RADIUS", 25, 0, 50, 8, function(v) mouseAimbot.SnapRadius = v end, "blue")
makeToggle(mMAIN, "WALL CHECK", 26, false, function(on) mouseAimbot.WallCheck = on end, "blue")
makeToggle(mMAIN, "TEAM CHECK", 27, false, function(on) mouseAimbot.TeamCheck = on end, "blue")

makeSection(mMAIN, "── TRIGGERBOT ──", 40, "blue")
makeToggle(mMAIN, "TRIGGERBOT ON", 41, false, function(on) mouseTrigger.Enabled = on end, "blue")
makeKeybind(mMAIN, "TRIGGER KEY (키/마우스)", 42, mouseTrigger.Bind, function(bind)
    mouseTrigger.Bind = bind; mouseTrigger.resetPressed()
end, "blue")
makeSlider(mMAIN, "TRIGGER DELAY", 43, 0.01, 0.5, 0.05, function(v) mouseTrigger.Delay = v end, "blue")
makeToggle(mMAIN, "TRIGGER TEAM CHECK", 44, false, function(on) mouseTrigger.TeamCheck = on end, "blue")

makeSection(mMISC, "── 기타 ──", 1, "blue")
makeToggle(mMISC, "예시 기능 A", 2, false, function(s) print("MISC A:", s) end, "blue")
makeToggle(mMISC, "예시 기능 B", 3, false, function(s) print("MISC B:", s) end, "blue")

makeSection(mSET, "── 단축키 ──", 1, "blue")
makeKeybind(mSET, "UI 열기/닫기 키", 2, UI_TOGGLE_KEY, function(bind) UI_TOGGLE_KEY = bind end, "blue")
makeSection(mSET, "── 마우스 ──", 5, "blue")
makeToggle(mSET, "FREE CURSOR", 6, false, function(on) FreeCursor.Enabled = on end, "blue")
makeSection(mSET, "── 종료 ──", 10, "blue")
makeLabel(mSET, "; 키를 누르면 스크립트가 완전히 종료됩니다.", 11, Color3.fromRGB(255, 140, 140))
makeLabel(mSET, "(UI, 버튼, ESP, 에임봇 전부 사라짐)", 12, Color3.fromRGB(150, 150, 160))

--=========================================================
-- 11. 라이벌 패널 컨텐츠
--=========================================================
local rMAIN = rivalPanel.pages["MAIN"]
local rMISC = rivalPanel.pages["MISC"]
local rSET = rivalPanel.pages["SETTINGS"]

makeSection(rMAIN, "── ESP ──", 1, "red")
makeToggle(rMAIN, "ESP ON", 2, false, function(on) rivalESP.setEnabled(on) end, "red")

local rEspContainer = Instance.new("Frame")
rEspContainer.Size = UDim2.new(1, 0, 0, 0)
rEspContainer.AutomaticSize = Enum.AutomaticSize.Y
rEspContainer.BackgroundTransparency = 1
rEspContainer.LayoutOrder = 4
rEspContainer.Visible = false
rEspContainer.ZIndex = 18
rEspContainer.Parent = rMAIN
local rEspLayout = Instance.new("UIListLayout")
rEspLayout.Padding = UDim.new(0, 8)
rEspLayout.SortOrder = Enum.SortOrder.LayoutOrder
rEspLayout.Parent = rEspContainer

makeExpander(rMAIN, "ESP 기능", 3, rEspContainer, "red")
makeToggle(rEspContainer, "SKELETON", 1, false, function(on) rivalESP.Skeleton = on end, "red", 22)
makeToggle(rEspContainer, "BOX",      2, false, function(on) rivalESP.Box = on end, "red", 22)
makeToggle(rEspContainer, "NAME",     3, false, function(on) rivalESP.Name = on end, "red", 22)
makeToggle(rEspContainer, "DISTANCE", 4, false, function(on) rivalESP.Distance = on end, "red", 22)
makeToggle(rEspContainer, "HEALTH",   5, false, function(on) rivalESP.Health = on end, "red", 22)
makeToggle(rEspContainer, "CHAMS",    6, false, function(on) rivalESP.Chams = on end, "red", 22)

makeSection(rMAIN, "── RIVAL AIMBOT ──", 20, "red")
makeToggle(rMAIN, "AIMBOT ON", 21, false, function(on) rivalAimbot.Enabled = on end, "red")
makeToggle(rMAIN, "FOV", 22, false, function(on) rivalAimbot.FovShown = on end, "red")
makeSlider(rMAIN, "FOV SIZE", 23, 20, 600, 150, function(v) rivalAimbot.FovSize = v end, "red")
makeSlider(rMAIN, "SMOOTH", 24, 1, 20, 5, function(v) rivalAimbot.Smooth = v end, "red")
makeSlider(rMAIN, "SNAP RADIUS", 25, 0, 50, 8, function(v) rivalAimbot.SnapRadius = v end, "red")
makeToggle(rMAIN, "WALL CHECK", 26, false, function(on) rivalAimbot.WallCheck = on end, "red")
makeToggle(rMAIN, "TEAM CHECK", 27, false, function(on) rivalAimbot.TeamCheck = on end, "red")

makeSection(rMAIN, "── RIVAL TRIGGERBOT ──", 40, "red")
makeToggle(rMAIN, "TRIGGERBOT ON", 41, false, function(on) rivalTrigger.Enabled = on end, "red")
makeKeybind(rMAIN, "TRIGGER KEY (키/마우스)", 42, rivalTrigger.Bind, function(bind)
    rivalTrigger.Bind = bind; rivalTrigger.resetPressed()
end, "red")
makeSlider(rMAIN, "TRIGGER DELAY", 43, 0.01, 0.5, 0.05, function(v) rivalTrigger.Delay = v end, "red")
makeToggle(rMAIN, "TRIGGER TEAM CHECK", 44, false, function(on) rivalTrigger.TeamCheck = on end, "red")

makeSection(rMAIN, "── WALLBANG (월뱅) ──", 60, "red")
makeToggle(rMAIN, "WALLBANG ON", 61, false, function(on)
    if on and not wallbangOK then
        warn("[RAT HUB] 이 실행기에선 Wallbang 사용 불가")
        return
    end
    Wallbang.Enabled = on
end, "red")
makeLabel(rMAIN, "(벽 무시하고 관통 사격)", 62, Color3.fromRGB(180, 130, 130))

makeSection(rMISC, "── 라이벌 기타 ──", 1, "red")
makeToggle(rMISC, "RIVAL SPEED", 2, false, function(s) print("RIVAL SPEED:", s) end, "red")
makeToggle(rMISC, "RIVAL FLY", 3, false, function(s) print("RIVAL FLY:", s) end, "red")
makeToggle(rMISC, "RIVAL INF JUMP", 4, false, function(s) print("RIVAL INF JUMP:", s) end, "red")

makeSection(rSET, "── 라이벌 단축키 ──", 1, "red")
makeKeybind(rSET, "라이벌 UI 토글 키", 2, RIVAL_TOGGLE_KEY, function(bind) RIVAL_TOGGLE_KEY = bind end, "red")
makeSection(rSET, "── 마우스 ──", 5, "red")
makeToggle(rSET, "FREE CURSOR", 6, false, function(on) FreeCursor.Enabled = on end, "red")
makeLabel(rSET, "(살아있을 때도 커서 고정 해제)", 7, Color3.fromRGB(180, 130, 130))
makeSection(rSET, "── 종료 ──", 10, "red")
makeLabel(rSET, "; 키로 전체 스크립트 종료", 11, Color3.fromRGB(255, 140, 140))

--=========================================================
-- 12. 모드 활성화
--=========================================================
local mouseModeActive = false
local rivalModeActive = false

track(toggleBtn.MouseButton1Click:Connect(function() mousePanel.toggle() end))
track(rivalBtn.MouseButton1Click:Connect(function() rivalPanel.toggle() end))

track(hubBtnMouse.MouseButton1Click:Connect(function()
    closeHub()
    task.spawn(function()
        playIntro(introMouse, mouseEmoji, mouseIntroText)
        mouseModeActive = true
        toggleBtn.Visible = true
        TweenService:Create(toggleBtn, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(1, -30, 0.5, 0)}):Play()
    end)
end))

track(hubBtnRival.MouseButton1Click:Connect(function()
    closeHub()
    task.spawn(function()
        playIntro(introRival, rivalEmoji, rivalIntroText)
        rivalModeActive = true
        rivalBtn.Visible = true
        TweenService:Create(rivalBtn, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(1, -30, 0.5, 0)}):Play()
    end)
end))

--=========================================================
-- 13. 단축키
--=========================================================
track(UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if mouseModeActive and bindMatches(UI_TOGGLE_KEY, input) then mousePanel.toggle() end
    if rivalModeActive and bindMatches(RIVAL_TOGGLE_KEY, input) then rivalPanel.toggle() end
end))

--=========================================================
-- 14. 언로드
--=========================================================
local function unload()
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    connections = {}

    pcall(function() mouseESP.destroy() end)
    pcall(function() rivalESP.destroy() end)
    pcall(function() mouseAimbot.destroy() end)
    pcall(function() rivalAimbot.destroy() end)

    Wallbang.Enabled = false

    local drawSnap = {}
    for d in pairs(allDrawings) do table.insert(drawSnap, d) end
    for _, d in ipairs(drawSnap) do killDrawing(d) end
    allDrawings = {}

    for _, v in ipairs(gui:GetDescendants()) do
        if v:IsA("Highlight") then
            pcall(function() v.Adornee = nil; v:Destroy() end)
        end
    end

    if gui and gui.Parent then pcall(function() gui:Destroy() end) end
end

track(UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Semicolon then
        unload()
    end
end))
