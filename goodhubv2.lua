-- [[ GOOD HUB V3 完整手機版 - 全功能不省略 ]] --
repeat wait() until game:IsLoaded()

local HttpService = game:GetService("HttpService")
local FileName = "YUNUKE_CONFIG_V3_FINAL.json"

local Settings = {
    AimbotEnabled = false,
    SilentAimEnabled = false, 
    AimbotKey = "B",
    AimbotPart = "Head",
    AimbotHolding = false,
    AutoFireEnabled = false,
    AutoFireDelay = 0.05, 
    FlyEnabled = false,
    FlySpeed = 100,
    NoclipEnabled = false,
    SpinEnabled = false,
    SpinSpeed = 800,
    ESPEnabled = false,
    IsBinding = false,
    ChatSpamEnabled = false,
    ChatSpamText = "ezz",
    ChatSpamDelay = 3,
    UpsideDownEnabled = false,
}

-- [ 存檔與讀取系統 ]
local function SaveSettings()
    local success, encoded = pcall(function() return HttpService:JSONEncode(Settings) end)
    if success then writefile(FileName, encoded) end
end

local function LoadSettings()
    if isfile(FileName) then
        local success, content = pcall(function() return readfile(FileName) end)
        if success and content ~= "" then
            local decode_success, decoded = pcall(function() return HttpService:JSONDecode(content) end)
            if decode_success and type(decoded) == "table" then
                for k, v in pairs(decoded) do if Settings[k] ~= nil then Settings[k] = v end end
            end
        end
    end
end
LoadSettings()

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local lastAutoFireTime = 0
local lastChatTime = 0

local function GetRoot(char) return char and char:FindFirstChild("HumanoidRootPart") end

-- [[ 可視檢查：看到人才鎖碼 ]] --
local function IsVisible(targetPart)
    local char = LocalPlayer.Character
    if not char then return false end
    local rayParam = RaycastParams.new()
    rayParam.FilterType = Enum.RaycastFilterType.Exclude
    rayParam.FilterDescendantsInstances = {char, Camera}
    local rayDirection = (targetPart.Position - Camera.CFrame.Position)
    local rayResult = workspace:Raycast(Camera.CFrame.Position, rayDirection, rayParam)
    if not rayResult or rayResult.Instance:IsDescendantOf(targetPart.Parent) then
        return true
    end
    return false
end

-- [[ 人物發亮 (Highlight) + 血量 ESP ]] --
local function CreateESP(player)
    local function ApplyESP(char)
        if player == LocalPlayer then return end
        
        -- 發亮 (Chams)
        local highlight = char:FindFirstChild("YUNUKE_ESP") or Instance.new("Highlight")
        highlight.Name = "YUNUKE_ESP"
        highlight.Parent = char
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        
        -- 頭頂血量文字 (BillboardGui)
        local bill = char:FindFirstChild("YUNUKE_UI") or Instance.new("BillboardGui")
        bill.Name = "YUNUKE_UI"
        bill.Adornee = char:WaitForChild("Head", 5)
        bill.Size = UDim2.new(0, 100, 0, 50)
        bill.StudsOffset = Vector3.new(0, 3, 0)
        bill.AlwaysOnTop = true
        bill.Parent = char
        
        local label = bill:FindFirstChild("TextLabel") or Instance.new("TextLabel", bill)
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(1, 0, 1, 0)
        label.Font = Enum.Font.GothamBold
        label.TextSize = 14
        label.TextColor3 = Color3.new(1, 1, 1)

        local connection
        connection = RunService.RenderStepped:Connect(function()
            if not char or not char.Parent or not Settings.ESPEnabled then
                highlight.Enabled = false
                bill.Enabled = false
                if char and not char.Parent then connection:Disconnect() end
                return
            end
            
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                highlight.Enabled = true
                bill.Enabled = true
                local hp = math.floor(hum.Health)
                label.Text = player.Name .. "\nHP: " .. hp
                
                -- 血量變色邏輯
                local color = Color3.fromHSV(math.clamp(hum.Health/hum.MaxHealth, 0, 0.33), 1, 1)
                label.TextColor3 = color
                highlight.FillColor = color
            else
                highlight.Enabled = false
                bill.Enabled = false
            end
        end)
    end
    if player.Character then ApplyESP(player.Character) end
    player.CharacterAdded:Connect(ApplyESP)
end

for _, p in pairs(Players:GetPlayers()) do CreateESP(p) end
Players.PlayerAdded:Connect(CreateESP)

-- [[ UI 介面設定 ]] --
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
ScreenGui.Name = "YUNUKE_V3_FINAL"

-- OPEN 按鈕
local OpenBtn = Instance.new("TextButton", ScreenGui)
OpenBtn.Size = UDim2.new(0, 50, 0, 50)
OpenBtn.Position = UDim2.new(0, 10, 0.4, 0)
OpenBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
OpenBtn.Text = "OPEN"
OpenBtn.TextColor3 = Color3.new(1, 1, 1)
OpenBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(1, 0)

-- LOCK 按鈕 (Aimbot)
local MobileAimBtn = Instance.new("TextButton", ScreenGui)
MobileAimBtn.Size = UDim2.new(0, 65, 0, 65)
MobileAimBtn.Position = UDim2.new(0.85, -32, 0.5, -32)
MobileAimBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
MobileAimBtn.BackgroundTransparency = 0.5
MobileAimBtn.Text = "LOCK"
MobileAimBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", MobileAimBtn).CornerRadius = UDim.new(1, 0)

MobileAimBtn.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
        Settings.AimbotHolding = true
        MobileAimBtn.BackgroundTransparency = 0
    end
end)
MobileAimBtn.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
        Settings.AimbotHolding = false
        MobileAimBtn.BackgroundTransparency = 0.5
    end
end)

-- 主面板
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 200, 0, 380)
MainFrame.Position = UDim2.new(0.5, -100, 0.5, -190)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.Visible = false
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

OpenBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    OpenBtn.Text = MainFrame.Visible and "CLOSE" or "OPEN"
end)

local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, 0, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "GOOD HUB FINAL"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14

local Container = Instance.new("ScrollingFrame", MainFrame)
Container.Size = UDim2.new(1, -10, 1, -50)
Container.Position = UDim2.new(0, 5, 0, 45)
Container.BackgroundTransparency = 1
Container.CanvasSize = UDim2.new(0, 0, 0, 1100)
Container.ScrollBarThickness = 2
local UIList = Instance.new("UIListLayout", Container)
UIList.Padding = UDim.new(0, 8)

-- [ UI 元件函數 ]
local function CreateButton(text, key)
    local Btn = Instance.new("TextButton", Container)
    Btn.Size = UDim2.new(1, 0, 0, 35)
    Btn.BackgroundColor3 = Settings[key] and Color3.fromRGB(50, 180, 100) or Color3.fromRGB(40, 40, 40)
    Btn.Text = text .. ": " .. (Settings[key] and "ON" or "OFF")
    Btn.TextColor3 = Color3.new(1, 1, 1)
    Btn.Font = Enum.Font.Gotham
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
    Btn.MouseButton1Click:Connect(function()
        Settings[key] = not Settings[key]
        SaveSettings()
        Btn.BackgroundColor3 = Settings[key] and Color3.fromRGB(50, 180, 100) or Color3.fromRGB(40, 40, 40)
        Btn.Text = text .. ": " .. (Settings[key] and "ON" or "OFF")
    end)
end

local function CreateSlider(text, max, key)
    local Frame = Instance.new("Frame", Container)
    Frame.Size = UDim2.new(1, 0, 0, 50)
    Frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)
    local Label = Instance.new("TextLabel", Frame)
    Label.Size = UDim2.new(1, 0, 0, 20)
    Label.Text = text .. ": " .. Settings[key]
    Label.TextColor3 = Color3.new(1, 1, 1)
    Label.BackgroundTransparency = 1
    local Bar = Instance.new("Frame", Frame)
    Bar.Size = UDim2.new(1, -20, 0, 4)
    Bar.Position = UDim2.new(0, 10, 0, 35)
    local Fill = Instance.new("Frame", Bar)
    Fill.Size = UDim2.new(Settings[key]/max, 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
    
    Bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            local move = RunService.RenderStepped:Connect(function()
                local ratio = math.clamp((UserInputService:GetMouseLocation().X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
                Settings[key] = math.floor(ratio * max)
                Fill.Size = UDim2.new(ratio, 0, 1, 0)
                Label.Text = text .. ": " .. Settings[key]
            end)
            i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then move:Disconnect() SaveSettings() end end)
        end
    end)
end

-- 介面初始化 (所有功能)
CreateButton("Aimbot", "AimbotEnabled")
CreateButton("Silent Aim", "SilentAimEnabled")
CreateButton("Auto Fire", "AutoFireEnabled")
CreateButton("Highlight ESP", "ESPEnabled")
CreateButton("Fly (搖桿)", "FlyEnabled")
CreateButton("Noclip", "NoclipEnabled")
CreateButton("Spin Bot", "SpinEnabled")
CreateButton("Upside Down", "UpsideDownEnabled")
CreateButton("Chat Spam", "ChatSpamEnabled")

CreateSlider("Fly Speed", 500, "FlySpeed")
CreateSlider("Spin Speed", 3000, "SpinSpeed")
CreateSlider("AutoFire Delay", 1, "AutoFireDelay")

local SkinBtn = Instance.new("TextButton", Container)
SkinBtn.Size = UDim2.new(1, 0, 0, 35)
SkinBtn.Text = "GUN SKIN CHANGER"
SkinBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
SkinBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", SkinBtn).CornerRadius = UDim.new(0, 6)
SkinBtn.MouseButton1Click:Connect(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/endoverdosing/Soluna-API/refs/heads/main/skin-changer.lua",true))()
end)

-- [[ 核心計算：最近目標 + 可視 ]] --
local function GetClosestTarget()
    local target, dist = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            local part = p.Character:FindFirstChild(Settings.AimbotPart)
            if part then
                local pos, os = Camera:WorldToViewportPoint(part.Position)
                if os then
                    local mag = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                    if mag < dist and IsVisible(part) then 
                        dist = mag target = part 
                    end
                end
            end
        end
    end
    return target
end

-- [[ 拖動邏輯 ]] --
local Dragging, DragStart, StartPos
Header.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
        Dragging = true DragStart = i.Position StartPos = MainFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if Dragging and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = i.Position - DragStart
        MainFrame.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + delta.X, StartPos.Y.Scale, StartPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function() Dragging = false end)

-- [[ 主循環：每幀更新 ]] --
RunService.RenderStepped:Connect(function(dt)
    local char = LocalPlayer.Character
    local root = GetRoot(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    -- 1. 飛行邏輯 (偵測搖桿 MoveDirection)
    if Settings.FlyEnabled then
        hum.PlatformStand = true
        root.Velocity = Vector3.new(0, 0.5, 0) -- 抵消重力
        if hum.MoveDirection.Magnitude > 0 then
            root.CFrame = root.CFrame + (hum.MoveDirection * Settings.FlySpeed * dt)
        end
    else
        if hum.PlatformStand then hum.PlatformStand = false end
    end

    -- 2. 鎖碼邏輯
    local target = GetClosestTarget()
    if (Settings.AimbotEnabled and Settings.AimbotHolding) or (Settings.SilentAimEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)) then
        if target then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
            -- Auto Fire
            if Settings.AutoFireEnabled and tick() - lastAutoFireTime >= Settings.AutoFireDelay then
                if mouse1click then mouse1click() else warn("Executor does not support mouse1click") end
                lastAutoFireTime = tick()
            end
        end
    end

    -- 3. Spin Bot
    if Settings.SpinEnabled and not Settings.AimbotHolding then
        root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(Settings.SpinSpeed * dt), 0)
    end

    -- 4. Upside Down
    if Settings.UpsideDownEnabled then
        root.CFrame = root.CFrame * CFrame.Angles(0, 0, math.rad(180))
    end

    -- 5. Chat Spam
    if Settings.ChatSpamEnabled and tick() - lastChatTime >= Settings.ChatSpamDelay then
        local events = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        local say = events and events:FindFirstChild("SayMessageRequest")
        if say then say:FireServer(Settings.ChatSpamText, "All") end
        lastChatTime = tick()
    end
end)

-- Noclip 邏輯
RunService.Stepped:Connect(function()
    if Settings.NoclipEnabled and LocalPlayer.Character then
        for _, p in pairs(LocalPlayer.Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end)

print("GOOD HUB V3 FINAL LOADED - NO OMISSION")
