--[[
    Onyx Hub — Loader
    loadstring(game:HttpGet("https://raw.githubusercontent.com/pubgbattle1121-bot/rathub/main/loader.lua", true))()
]]

local HUB_URL    = "https://raw.githubusercontent.com/pubgbattle1121-bot/rathub/main/hub.lua"
local CHUNK_NAME = "OnyxHub"

local function fetchSource(url)
    local ok, res = pcall(function()
        return game:HttpGet(url, true)
    end)
    if not ok then return nil, "HTTP 요청 실패: " .. tostring(res) end
    if not res or res == "" then return nil, "빈 응답 — URL 확인" end
    if res:sub(1, 3) == "404" then return nil, "404 Not Found: " .. url end
    return res, nil
end

local src, err = fetchSource(HUB_URL)
if not src then warn("[Onyx Hub] " .. err) return end

local fn, compileErr = loadstring(src, CHUNK_NAME)
if not fn then warn("[Onyx Hub] 컴파일 실패: " .. tostring(compileErr)) return end

local ok, runErr = pcall(fn)
if not ok then warn("[Onyx Hub] 실행 오류: " .. tostring(runErr)) end
