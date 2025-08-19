-- =======================
-- 白名单检测
-- =======================
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local localPlayer = Players.LocalPlayer

local url = "https://raw.githubusercontent.com/George78198/ximaonbszlyy/refs/heads/main/Ximaowhitelis.json"

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

if not WHITELIST[localPlayer.Name] then
    StarterGui:SetCore("SendNotification", {
        Title = "细猫自动脚本",
        Text = "需要购买白名单加QQ 366118610\n您的用户名不在白名单",
        Duration = 10
    })
    return
end

-- 白名单验证成功提示
StarterGui:SetCore("SendNotification", {
    Title = "细猫自动脚本",
    Text = "白名单验证成功",
    Duration = 3
})

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
    NOTIFICATION_DURATION = 3,
}

local TARGET_ITEM = "Money Printer"
local visitedServers = {}

-- =======================
-- UI 设置
-- =======================
local ScreenGui = Instance.new("ScreenGui", localPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "CatAutoScriptUI"

-- 中间文字逐字动画
local midTextLines = {
    "细猫印钞机脚本内测版",
    "成功绕开检测",
    "开启防600模式",
    "启动自动刷印钞机功能",
    "正在检测",
    "自动换服",
    "作者：细猫游戏解说"
}

local midLabel = Instance.new("TextLabel", ScreenGui)
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

task.spawn(function()
    while true do
        midLabel.Text = ""
        for _, line in ipairs(midTextLines) do
            for i = 1, #line do
                midLabel.Text = midLabel.Text .. line:sub(i,i)
                task.wait(0.03)
            end
            midLabel.Text = midLabel.Text .. "\n"
        end
        task.wait(1)
    end
end)

-- 右下角显示本地人数及状态
local function showNotification(text)
    StarterGui:SetCore("SendNotification", {
        Title = "细猫自动脚本",
        Text = text,
        Duration = CONFIG.NOTIFICATION_DURATION
    })
end

task.spawn(function()
    while true do
        local count = #Players:GetPlayers()
        showNotification("本地服务器人数："..count)
        task.wait(CONFIG.NOTIFICATION_DURATION)
    end
end)

-- =======================
-- 服务器列表与随机换服
-- =======================
local function fetchServerList()
    local url = string.format(
        "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100",
        game.PlaceId
    )
    local response = httpRequest and httpRequest({Url = url, Method = "GET", Timeout = 10})
    if not response or response.StatusCode ~= 200 then return nil end
    local data = HttpService:JSONDecode(response.Body)
    if not data or not data.data then return nil end

    local filtered = {}
    local currentJobId = game.JobId
    for _, server in ipairs(data.data) do
        if server.playing < server.maxPlayers and server.id ~= currentJobId and not visitedServers[server.id] then
            table.insert(filtered, server)
        end
    end
    return filtered
end

local function teleportToServer(serverId)
    local success, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, serverId, localPlayer)
    end)
    if not success then
        showNotification("传送失败: "..tostring(err):sub(1,30))
        return false
    end
    return true
end

-- =======================
-- 扫描 Money Printer 并拾取
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

-- =======================
-- 主循环：检测并换服
-- =======================
task.spawn(function()
    while true do
        local found = scanForMoneyPrinters()
        if #found > 0 then
            for _, data in ipairs(found) do
                local item = data.item
                humanoidRootPart.CFrame = item.CFrame + Vector3.new(0,3,0)
                task.wait(0.2)
                pcall(function() data.prompt:InputHoldBegin() end)
                task.wait(3)
                pcall(function() data.prompt:InputHoldEnd() end)
                showNotification("Picked up: "..TARGET_ITEM)
            end
        else
            showNotification("未找到可用物品，准备换服")
            task.wait(CONFIG.TELEPORT_COOLDOWN)
            local servers = fetchServerList()
            if servers and #servers > 0 then
                local server = servers[math.random(1,#servers)]
                visitedServers[server.id] = true
                teleportToServer(server.id)
            else
                showNotification("未找到可用服务器，稍后重试")
                task.wait(CONFIG.SERVER_FETCH_RETRY_DELAY)
            end
        end
        task.wait(3) -- 3秒换服间隔
    end
end)
