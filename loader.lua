--=========================================================
-- RAT HUB Loader (Key System)
--=========================================================
local BASE = "https://raw.githubusercontent.com/pubgbattle1121-bot/rathub/main/"
local KEYS_URL = BASE .. "keys.txt"
local HUB_URL  = BASE .. "hub.lua"

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--// 유효 키 목록 가져오기
local function fetchKeys()
    local ok, raw = pcall(function() return game:HttpGet(KEYS_URL, true) end)
    if not ok or not raw then return {} end
    local set = {}
    for line in raw:gmatch("[^\r\n]+") do
        local t = line:gsub("%s+", "")
        if t ~= "" and t:sub(1,1) ~= "#" then
            set[t:upper()] = true
        end
    end
    return set
end

local validKeys = fetchKeys()

--// 저장된 키
local SAVED_KEY = nil
pcall(function() SAVED_KEY = readfile and readfile("rathub_key.txt") end)

local function saveKey(k)
    pcall(function() if writefile then writefile("rathub_key.txt", k) end end)
end

local function isValid(k)
    if not k or k == "" then return false end
    return validKeys[k:upper()] == true
end

--// 본 스크립트 실행
local function launchHub()
    local ok, err = pcall(function()
        loadstring(game:HttpGet(HUB_URL, true))()
    end)
    if not ok then
        warn("[RAT HUB] 로드 실패:", err)
    end
end

--// 이미 저장된 키가 유효하면 바로 실행
if SAVED_KEY and isValid(SAVED_KEY) then
    launchHub()
    return
end

--// 키 입력 UI
local gui = Instance.new("ScreenGui")
gui.Name = "RATKeyGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Size = UDim2.fromOffset(420, 240)
frame.Position = UDim2.fromScale(0.5, 0.5)
frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
frame.BorderSizePixel = 0
frame.ZIndex = 50
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 16)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(220, 70, 70)
stroke.Thickness = 2
stroke.Transparency = 0.3
stroke.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 50)
title.Position = UDim2.new(0, 0, 0, 18)
title.BackgroundTransparency = 1
title.Text = "🔒 RAT HUB"
title.Font = Enum.Font.FredokaOne
title.TextSize = 32
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.ZIndex = 51
title.Parent = frame

local sub = Instance.new("TextLabel")
sub.Size = UDim2.new(1, 0, 0, 24)
sub.Position = UDim2.new(0, 0, 0, 62)
sub.BackgroundTransparency = 1
sub.Text = "라이선스 키를 입력하세요"
sub.Font = Enum.Font.GothamMedium
sub.TextSize = 14
sub.TextColor3 = Color3.fromRGB(150, 150, 165)
sub.ZIndex = 51
sub.Parent = frame

local input = Instance.new("TextBox")
input.Size = UDim2.new(1, -60, 0, 44)
input.Position = UDim2.new(0, 30, 0, 100)
input.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
input.BorderSizePixel = 0
input.Text = ""
input.PlaceholderText = "RAT-XXXX-XXXX-XXXX"
input.Font = Enum.Font.GothamBold
input.TextSize = 15
input.TextColor3 = Color3.fromRGB(240, 240, 240)
input.PlaceholderColor3 = Color3.fromRGB(100, 100, 115)
input.ClearTextOnFocus = false
input.ZIndex = 51
input.Parent = frame
Instance.new("UICorner", input).CornerRadius = UDim.new(0, 10)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -60, 0, 20)
status.Position = UDim2.new(0, 30, 0, 148)
status.BackgroundTransparency = 1
status.Text = ""
status.Font = Enum.Font.GothamMedium
status.TextSize = 13
status.TextColor3 = Color3.fromRGB(255, 130, 130)
status.TextXAlignment = Enum.TextXAlignment.Left
status.ZIndex = 51
status.Parent = frame

local submit = Instance.new("TextButton")
submit.Size = UDim2.new(1, -60, 0, 44)
submit.Position = UDim2.new(0, 30, 1, -60)
submit.BackgroundColor3 = Color3.fromRGB(220, 70, 70)
submit.Text = "인증"
submit.Font = Enum.Font.GothamBold
submit.TextSize = 16
submit.TextColor3 = Color3.fromRGB(255, 255, 255)
submit.AutoButtonColor = false
submit.ZIndex = 51
submit.Parent = frame
Instance.new("UICorner", submit).CornerRadius = UDim.new(0, 10)

local function trySubmit()
    local k = (input.Text or ""):upper():gsub("%s", "")
    if k == "" then
        status.Text = "키를 입력하세요"
        return
    end
    if isValid(k) then
        status.TextColor3 = Color3.fromRGB(120, 255, 120)
        status.Text = "인증 성공! 로딩중..."
        saveKey(k)
        task.wait(0.5)
        gui:Destroy()
        launchHub()
    else
        status.TextColor3 = Color3.fromRGB(255, 130, 130)
        status.Text = "유효하지 않은 키입니다"
    end
end

submit.MouseButton1Click:Connect(trySubmit)
input.FocusLost:Connect(function(enter)
    if enter then trySubmit() end
end)
