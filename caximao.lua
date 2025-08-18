-- =======================
-- 远程白名单检查
-- =======================
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local localPlayer = Players.LocalPlayer

-- 远程白名单 URL
local url = "https://raw.githubusercontent.com/George78198/ximaonbszlyy/refs/heads/main/Ximaowhitelis.json"

-- 获取远程白名单
local success, response = pcall(function()
    return game:HttpGet(url)
end)

local WHITELIST = {}
if success and response then
    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(response)
    end)
    if ok and decoded then
        WHITELIST = decoded
    else
        StarterGui:SetCore("SendNotification", {
            Title = "细猫自动脚本",
            Text = "白名单解析失败",
            Duration = 5
        })
        return
    end
else
    StarterGui:SetCore("SendNotification", {
        Title = "细猫自动脚本",
        Text = "获取白名单失败",
        Duration = 5
    })
    return
end

-- 检查本地用户名是否在白名单
if not WHITELIST[localPlayer.Name] then
    StarterGui:SetCore("SendNotification", {
        Title = "细猫自动脚本",
        Text = "需要购买白名单加QQ 366118610\n您的用户名不在白名单",
        Duration = 10
    })
    return
end

-- =======================
-- 模拟 W 键走一步
-- =======================
game:GetService("VirtualInputManager"):SendKeyEvent(true, "W", false, game)
task.wait(0.9)
game:GetService("VirtualInputManager"):SendKeyEvent(false, "W", false, game)

-- =======================
-- 配置
-- =======================
local TeleportService = game:GetService("TeleportService")
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

local CONFIG = {
    SERVER_FETCH_RETRY_DELAY = 10,
    TELEPORT_COOLDOWN = 3,
    FORBIDDEN_ZONE = {
        center = Vector3.new(352.884155, 13.0287256, -1353.05396),
        radius = 80
    },
    NOTIFICATION_DURATION = 5,
}

local TARGET_ITEM = "Money Printer"
local visitedServers = {}
local servers = {}

-- =======================
-- UI 设置
-- =======================
local ScreenGui = Instance.new("ScreenGui", localPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "CatAutoScriptUI"

local midTextLines = {
    "细猫印钞机脚本内测版",
    "成功绕开检测",
    "开启防600模式",
    "启动自动刷印钞机功能",
    "正在检测",
    "自动换服",
    "作者：细猫游戏解说"
}local midLabel = Instance.new("TextLabel", ScreenGui)
midLabel.AnchorPoint = Vector2.new(0.5, 0.5)
midLabel.Position = UDim2.new(0.5, 0, 0.4, 0)
midLabel.Size = UDim2.new(0.7, 0, 0.35, 0)
midLabel.BackgroundTransparency = 1
midLabel.TextColor3 = Color3.new(1,1,1)
midLabel.Font = Enum.Font.GothamBold
midLabel.TextSize = 36
midLabel.TextWrapped = true
midLabel.TextXAlignment = Enum.TextXAlignment.Center
midLabel.TextYAlignment = Enum.TextYAlignment.Center

local function animateMidLabel(label, lines, interval)
    while true do
        label.Text = ""
        for _, line in ipairs(lines) do
            for i = 1, #line do
                label.Text = label.Text .. line:sub(i,i)
                task.wait(interval)
            end
            label.Text = label.Text .. "\n"
        end
        task.wait(1)
    end
end

task.spawn(function()
    animateMidLabel(midLabel, midTextLines, 0.03)
end)

local function showNotification(text)
    StarterGui:SetCore("SendNotification", {
        Title = "细猫自动脚本",
        Text = text,
        Duration = CONFIG.NOTIFICATION_DURATION
    })
end

task.spawn(function()
    while true do
        showNotification("如果发现二改会立即删库")
        task.wait(CONFIG.NOTIFICATION_DURATION + 0.5)
        showNotification("作者QQ：366118610")
        task.wait(CONFIG.NOTIFICATION_DURATION + 0.5)
    end
end)

-- =======================
-- 随机服务器传送函数
-- =======================
local function getAvailableServersRandom()
    local url = string.format(
        "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100",
        game.PlaceId
    )
    local response = httpRequest and httpRequest({Url = url, Method = "GET", Timeout = 10})
    if not response or response.StatusCode ~= 200 then return {} end
    local data = HttpService:JSONDecode(response.Body)
    local available = {}
    for _, server in ipairs(data.data or {}) do
        if server.playing < server.maxPlayers and server.id ~= game.JobId and not visitedServers[server.id] then
            table.insert(available, server)
        end
    end
    return available
end

local function tryTeleportRandom()
    local servers = getAvailableServersRandom()
    if #servers == 0 then
        showNotification("未找到可用服务器，稍后重试")
        task.wait(CONFIG.SERVER_FETCH_RETRY_DELAY)
        return
    end
    local server = servers[math.random(1, #servers)]
    visitedServers[server.id] = true
    local success, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, localPlayer)
    end)
    if not success then
        showNotification("传送失败: " .. tostring(err):sub(1,30))
    end
end

-- =======================
-- 印钞机扫描函数
-- =======================
local function scanForMoneyPrinters()
    local found = {}
    for _, folder in pairs(workspace.Game.Entities.ItemPickup:GetChildren()) do
        for _, item in pairs(folder:GetChildren()) do
            if not (item:IsA("MeshPart") or item:IsA("Part")) then continue end
            local distance = (item.Position - CONFIG.FORBIDDEN_ZONE.center).Magnitude
            if distance <= CONFIG.FORBIDDEN_ZONE.radius then continue end
            for _, child in pairs(item:GetChildren()) do
                if child:IsA("ProximityPrompt") and child.ObjectText == TARGET_ITEM then
                    table.insert(found, {item = item, prompt = child})
                end
            end
        end
    end
    return found
end
