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
