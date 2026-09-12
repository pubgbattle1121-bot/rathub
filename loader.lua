--=========================================================
-- RAT HUB Loader v3
-- HWID 락 + 만료일 + Discord 로그
--=========================================================
local BASE = "https://raw.githubusercontent.com/pubgbattle1121-bot/rathub/main/"
local KEYS_URL = BASE .. "keys.txt"
local HUB_URL  = BASE .. "hub.lua"

-- ★ 여기에 Discord 웹훅 URL 넣기 (없으면 "" 그대로 두면 로그 안 감)
local DISCORD_WEBHOOK = ""

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--=========================================================
-- HWID 가져오기 (실행기별 여러 방법 시도)
--=========================================================
local function getHWID()
    local hwid
    pcall(function() if gethwid then hwid = gethwid() end end)
    if not hwid then pcall(function() if get_hwid then hwid = get_hwid() end end) end
    if not hwid then pcall(function() if game.GetClientId then hwid = game:GetClientId() end end) end
    if not hwid then
        pcall(function()
            hwid = game:GetService("RbxAnalyticsService"):GetClientId()
        end)
    end
    if not hwid then
        hwid = tostring(player.UserId) .. "_" .. tostring(game.PlaceId)
    end
    return tostring(hwid)
end

local MY_HWID = getHWID()

--=========================================================
-- keys.txt 파싱 (KEY:EXPIRY:HWID1,HWID2)
--=========================================================
local function fetchKeys()
    local ok, raw = pcall(function() return game:HttpGet(KEYS_URL, true) end)
    if not ok or not raw then return {} end
    local map = {}
    for line in raw:gmatch("[^\r\n]+") do
        local t = line:gsub("%s+", "")
        if t ~= "" and t:sub(1,1) ~= "#" then
            -- KEY:EXPIRY:HWIDS
            local key, rest = t:match("^([^:]+):(.*)$")
            if key then
                local expiry, hwids = rest:match("^([^:]*):?(.*)$")
                map[key:upper()] = {
                    expiry = expiry or "",
                    hwids = hwids or "",
                }
            end
        end
    end
    return map
end

local validKeys = fetchKeys()

--=========================================================
-- 검증 로직
--=========================================================
local function checkExpiry(expiry)
    if not expiry or expiry == "" then
        return false, "만료일 정보 없음"
    end
    if expiry:upper() == "PERM" then
        return true, "영구 라이선스"
    end
    local y, m, d = expiry:match("(%d+)-(%d+)-(%d+)")
    if not y then return false, "만료일 형식 오류" end
    local expTime = os.time({
        year = tonumber(y), month = tonumber(m), day = tonumber(d),
        hour = 23, min = 59, sec = 59,
    })
    local now = os.time()
    if now > expTime then
        return false, "만료된 키 (" .. expiry .. ")"
    end
    local daysLeft = math.floor((expTime - now) / 86400)
    return true, "유효 (" .. daysLeft .. "일 남음)"
end

-- HWID 바인딩 확인
local function checkHWID(hwids)
    if not hwids or hwids == "" then
        -- 아직 미바인딩 → 통과 (첫 사용)
        return true, "unbound"
    end
    for h in hwids:gmatch("[^,]+") do
        if h:upper() == MY_HWID:upper() then
            return true, "bound"
        end
    end
    return false, "다른 기기에 등록된 키입니다"
end

local function validate(k)
    if not k or k == "" then
        return false, "키를 입력하세요"
    end
    local key = k:upper():gsub("%s", "")
    local entry = validKeys[key]
    if not entry then
        return false, "유효하지 않은 키입니다"
    end

    -- 1) 만료일 체크
    local ok, msg = checkExpiry(entry.expiry)
    if not ok then return false, msg end

    -- 2) HWID 체크
    local hwidOK, hwidState = checkHWID(entry.hwids)
    if not hwidOK then return false, hwidState end

    return true, msg, hwidState
end

--=========================================================
-- Discord 로그 (첫 사용 감지용)
--=========================================================
local function sendWebhook(key, state)
    if DISCORD_WEBHOOK == "" then return end
    local payload = {
        content = nil,
        embeds = {{
            title = "RAT HUB Key Used",
            color = state == "unbound" and 16711680 or 65280,
            fields = {
                { name = "Key", value = key, inline = true },
                { name = "HWID", value = MY_HWID, inline = false },
                { name = "Player", value = player.Name .. " (" .. tostring(player.UserId) .. ")", inline = true },
                { name = "Game", value = tostring(game.PlaceId), inline = true },
                { name = "State", value = state == "unbound" and "🆕 첫 사용 (미바인딩)" or "✅ 기존 기기", inline = false },
            },
            timestamp = DateTime.now():ToIsoDate(),
        }},
    }
    pcall(function()
        HttpService:PostAsync(DISCORD_WEBHOOK, HttpService:JSONEncode(payload), Enum.HttpContentType.ApplicationJson)
    end)
end

--=========================================================
-- 본 스크립트 실행
--=========================================================
local function launchHub()
    local ok, err = pcall(function()
        loadstring(game:HttpGet(HUB_URL, true))()
    end)
    if not ok then warn("[RAT HUB] 로드 실패:", err) end
end

--=========================================================
-- 키 입력 UI
--=========================================================
local gui = Instance.new("ScreenGui")
gui.Name = "RATKeyGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Size = UDim2.fromOffset(420, 250)
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
title.Position = UDim2.new(0, 0, 0, 16)
title.BackgroundTransparency = 1
title.Text = "🔒 RAT HUB"
title.Font = Enum.Font.FredokaOne
title.TextSize = 32
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.ZIndex = 51
title.Parent = frame

local sub = Instance.new("TextLabel")
sub.Size = UDim2.new(1, 0, 0, 24)
sub.Position = UDim2.new(0, 0, 0, 60)
sub.BackgroundTransparency = 1
sub.Text = "라이선스 키를 입력하세요"
sub.Font = Enum.Font.GothamMedium
sub.TextSize = 14
sub.TextColor3 = Color3.fromRGB(150, 150, 165)
sub.ZIndex = 51
sub.Parent = frame

local input = Instance.new("TextBox")
input.Size = UDim2.new(1, -60, 0, 44)
input.Position = UDim2.new(0, 30, 0, 96)
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

local hwidLbl = Instance.new("TextLabel")
hwidLbl.Size = UDim2.new(1, -60, 0, 16)
hwidLbl.Position = UDim2.new(0, 30, 0, 144)
hwidLbl.BackgroundTransparency = 1
hwidLbl.Text = "HWID: " .. MY_HWID:sub(1, 24) .. "..."
hwidLbl.Font = Enum.Font.GothamMedium
hwidLbl.TextSize = 11
hwidLbl.TextColor3 = Color3.fromRGB(100, 100, 115)
hwidLbl.TextXAlignment = Enum.TextXAlignment.Left
hwidLbl.ZIndex = 51
hwidLbl.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -60, 0, 20)
status.Position = UDim2.new(0, 30, 0, 164)
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
    local k = input.Text or ""
    local ok, msg, hwidState = validate(k)

    if ok then
        status.TextColor3 = Color3.fromRGB(120, 255, 120)
        if hwidState == "unbound" then
            status.Text = "인증 성공! (첫 사용 — 관리자에게 HWID 전송됨)"
        else
            status.Text = "인증 성공! " .. msg
        end
        -- Discord 로그
        task.spawn(function()
            sendWebhook(k:upper():gsub("%s", ""), hwidState)
        end)
        task.wait(0.7)
        gui:Destroy()
        launchHub()
    else
        status.TextColor3 = Color3.fromRGB(255, 130, 130)
        status.Text = msg
    end
end

submit.MouseButton1Click:Connect(trySubmit)
input.FocusLost:Connect(function(enter) if enter then trySubmit() end end)
