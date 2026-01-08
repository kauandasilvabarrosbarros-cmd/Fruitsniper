repeat task.wait() until game:IsLoaded()

-- ===== CONFIG =====
getgenv().FruitSniper = {
    ScanDelay = 0.4,
    HopDelay = 2,
    AutoReconnect = true
}

-- ===== CONTADORES =====
local Stats = {
    FruitsFound = 0,
    FruitsStored = 0,
    ServerHops = 0,
    StartTime = os.time()
}

-- ===== SERVICES =====
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local CommF = ReplicatedStorage.Remotes.CommF_

print("🍍 Fruit Sniper iniciado (SEM SUBSTITUIR FRUTA)")

-- ===== UI =====
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "FruitSniperCounter"
ScreenGui.ResetOnSpawn = false

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.fromScale(0.32, 0.18)
Frame.Position = UDim2.fromScale(0.02, 0.25)
Frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
Frame.BackgroundTransparency = 0.2
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true

local function NewLabel(y)
    local l = Instance.new("TextLabel", Frame)
    l.Size = UDim2.fromScale(1, 0.2)
    l.Position = UDim2.fromScale(0, y)
    l.BackgroundTransparency = 1
    l.TextColor3 = Color3.new(1,1,1)
    l.TextScaled = true
    l.Font = Enum.Font.GothamBold
    return l
end

local Title = NewLabel(0)
Title.Text = "🍍 Fruit Sniper (Safe)"

local L1 = NewLabel(0.2)
local L2 = NewLabel(0.4)
local L3 = NewLabel(0.6)
local L4 = NewLabel(0.8)

RunService.RenderStepped:Connect(function()
    L1.Text = "🍏 Frutas vistas: "..Stats.FruitsFound
    L2.Text = "📦 Guardadas: "..Stats.FruitsStored
    L3.Text = "🔄 Server hops: "..Stats.ServerHops
    L4.Text = "⏱ "..os.date("!%H:%M:%S", os.time() - Stats.StartTime)
end)

-- ===== AUTO RECONNECT =====
Player.AncestryChanged:Connect(function(_, parent)
    if not parent and getgenv().FruitSniper.AutoReconnect then
        task.wait(3)
        TeleportService:Teleport(game.PlaceId)
    end
end)

-- ===== AUTO PIRATES =====
local function AutoPirates()
    pcall(function()
        if not Player.Team or Player.Team.Name ~= "Pirates" then
            CommF:InvokeServer("SetTeam", "Pirates")
        end
    end)
end

Player.CharacterAdded:Connect(function()
    task.wait(1)
    AutoPirates()
end)

-- ===== VERIFICA SE JÁ TEM FRUTA GUARDADA =====
local function HasStoredFruit()
    local ok, data = pcall(function()
        return CommF:InvokeServer("GetFruits")
    end)
    if ok and type(data) == "table" then
        for _, v in pairs(data) do
            if v and v.Name then
                return true
            end
        end
    end
    return false
end

-- ===== SERVER HOP =====
local function HopServer()
    Stats.ServerHops += 1

    local ok, data = pcall(function()
        return HttpService:JSONDecode(
            game:HttpGet(
                "https://games.roblox.com/v1/games/" ..
                game.PlaceId ..
                "/servers/Public?sortOrder=Asc&limit=100"
            )
        )
    end)

    if not ok or not data or not data.data then
        TeleportService:Teleport(game.PlaceId)
        return
    end

    for _, s in pairs(data.data) do
        if s.playing < s.maxPlayers then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, Player)
            break
        end
    end
end

-- ===== FIND FRUIT =====
local function FindFruit()
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Tool") and v:FindFirstChild("Handle") then
            return v
        end
    end
end

-- ===== LOOP PRINCIPAL =====
task.spawn(function()
    while task.wait(getgenv().FruitSniper.ScanDelay) do
        AutoPirates()

        local char = Player.Character
        if not char then continue end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        local fruit = FindFruit()

        if fruit and fruit:FindFirstChild("Handle") then
            Stats.FruitsFound += 1

            -- se já tem fruta guardada, NÃO substitui
            if HasStoredFruit() then
                task.wait(1)
                HopServer()
                continue
            end

            hrp.CFrame = fruit.Handle.CFrame + Vector3.new(0,3,0)
            task.wait(0.3)

            firetouchinterest(hrp, fruit.Handle, 0)
            firetouchinterest(hrp, fruit.Handle, 1)

            task.wait(1)

            pcall(function()
                CommF:InvokeServer("StoreFruit")
                Stats.FruitsStored += 1
            end)

            task.wait(2)
            HopServer()
        else
            task.wait(getgenv().FruitSniper.HopDelay)
            HopServer()
        end
    end
end)
