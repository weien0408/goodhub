-- [[ GOOD HUB V4 FULL (NO DELETE VERSION) ]] --
repeat wait() until game:IsLoaded()

local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

-- ⭐ 裝置偵測
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
print("Device:", isMobile and "Mobile" or "PC")

local FileName = "YUNUKE_CONFIG_V4.json"

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

-- 防重複UI
pcall(function()
    game.CoreGui:FindFirstChild("YUNUKE_V4"):Destroy()
end)

-- 存檔
local function SaveSettings()
    pcall(function()
        writefile(FileName, HttpService:JSONEncode(Settings))
    end)
end

local function LoadSettings()
    if isfile(FileName) then
        local data = HttpService:JSONDecode(readfile(FileName))
        for k,v in pairs(data) do
            if Settings[k] ~= nil then
                Settings[k] = v
            end
        end
    end
end
LoadSettings()

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local lastAutoFireTime = 0
local lastChatTime = 0

local function GetRoot(c) return c and c:FindFirstChild("HumanoidRootPart") end

-- ================= ESP =================
local function CreateESP(player)
    local function ApplyESP(char)
        if player == LocalPlayer then return end
        
        local highlight = char:FindFirstChild("YUNUKE_ESP") or Instance.new("Highlight")
        highlight.Name = "YUNUKE_ESP"
        highlight.Parent = char
        highlight.FillTransparency = 0.5
        
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

        RunService.RenderStepped:Connect(function()
            if not char.Parent or not Settings.ESPEnabled then
                highlight.Enabled = false
                bill.Enabled = false
                return
            end
            
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                highlight.Enabled = true
                bill.Enabled = true
                
                local hp = math.floor(hum.Health)
                label.Text = player.Name .. "\nHP: " .. hp
                
                local color = Color3.fromHSV(math.clamp(hum.Health/hum.MaxHealth,0,0.33),1,1)
                label.TextColor3 = color
                highlight.FillColor = color
            end
        end)
    end
    
    if player.Character then ApplyESP(player.Character) end
    player.CharacterAdded:Connect(ApplyESP)
end

for _,p in pairs(Players:GetPlayers()) do CreateESP(p) end
Players.PlayerAdded:Connect(CreateESP)

-- ================= UI =================
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "YUNUKE_V4"

-- 手機專用按鈕
local OpenBtn, MobileAimBtn

if isMobile then
    OpenBtn = Instance.new("TextButton", ScreenGui)
    OpenBtn.Size = UDim2.new(0,50,0,50)
    OpenBtn.Position = UDim2.new(0,10,0.4,0)
    OpenBtn.Text = "OPEN"
    OpenBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
    Instance.new("UICorner", OpenBtn)

    MobileAimBtn = Instance.new("TextButton", ScreenGui)
    MobileAimBtn.Size = UDim2.new(0,65,0,65)
    MobileAimBtn.Position = UDim2.new(0.85,-32,0.5,-32)
    MobileAimBtn.Text = "LOCK"
    MobileAimBtn.BackgroundColor3 = Color3.fromRGB(255,50,50)
    MobileAimBtn.BackgroundTransparency = 0.5
    Instance.new("UICorner", MobileAimBtn)

    MobileAimBtn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch then
            Settings.AimbotHolding = true
        end
    end)

    MobileAimBtn.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch then
            Settings.AimbotHolding = false
        end
    end)
end

-- 主面板
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0,200,0,380)
MainFrame.Position = UDim2.new(0.5,-100,0.5,-190)
MainFrame.Visible = false
MainFrame.BackgroundColor3 = Color3.fromRGB(25,25,25)
Instance.new("UICorner", MainFrame)

if OpenBtn then
    OpenBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = not MainFrame.Visible
    end)
end

-- UI 容器
local Container = Instance.new("ScrollingFrame", MainFrame)
Container.Size = UDim2.new(1,-10,1,-10)
Container.Position = UDim2.new(0,5,0,5)
Container.CanvasSize = UDim2.new(0,0,0,1000)

local Layout = Instance.new("UIListLayout", Container)
Layout.Padding = UDim.new(0,6)

-- 按鈕
local function CreateButton(text,key)
    local Btn = Instance.new("TextButton", Container)
    Btn.Size = UDim2.new(1,0,0,35)
    Btn.BackgroundColor3 = Settings[key] and Color3.fromRGB(50,180,100) or Color3.fromRGB(40,40,40)
    Btn.Text = text .. ": " .. (Settings[key] and "ON" or "OFF")
    
    Btn.MouseButton1Click:Connect(function()
        Settings[key] = not Settings[key]
        SaveSettings()
        Btn.Text = text .. ": " .. (Settings[key] and "ON" or "OFF")
    end)
end

-- 初始化所有功能
CreateButton("Aimbot","AimbotEnabled")
CreateButton("Silent Aim","SilentAimEnabled")
CreateButton("Auto Fire","AutoFireEnabled")
CreateButton("ESP","ESPEnabled")
CreateButton("Fly","FlyEnabled")
CreateButton("Noclip","NoclipEnabled")
CreateButton("Spin","SpinEnabled")
CreateButton("UpsideDown","UpsideDownEnabled")
CreateButton("ChatSpam","ChatSpamEnabled")

-- ===== 電腦鍵盤控制 =====
if not isMobile then
    UserInputService.InputBegan:Connect(function(i,g)
        if g then return end
        if i.KeyCode.Name == Settings.AimbotKey then
            Settings.AimbotHolding = true
        end
    end)

    UserInputService.InputEnded:Connect(function(i)
        if i.KeyCode.Name == Settings.AimbotKey then
            Settings.AimbotHolding = false
        end
    end)
end

-- ===== 可視 =====
local function IsVisible(part)
    local ray = RaycastParams.new()
    ray.FilterType = Enum.RaycastFilterType.Exclude
    ray.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    local result = workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, ray)
    return not result or result.Instance:IsDescendantOf(part.Parent)
end

-- ===== 目標 =====
local function GetTarget()
    local t,dist=nil,math.huge
    for _,p in pairs(Players:GetPlayers()) do
        if p~=LocalPlayer and p.Character and p.Character:FindFirstChild("Humanoid") then
            local part = p.Character:FindFirstChild(Settings.AimbotPart)
            if part then
                local pos,on=Camera:WorldToViewportPoint(part.Position)
                if on then
                    local mag=(Vector2.new(pos.X,pos.Y)-Camera.ViewportSize/2).Magnitude
                    if mag<dist and IsVisible(part) then
                        dist=mag
                        t=part
                    end
                end
            end
        end
    end
    return t
end

-- ===== 主循環 =====
RunService.RenderStepped:Connect(function(dt)
    local char = LocalPlayer.Character
    local root = GetRoot(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    if Settings.FlyEnabled then
        hum.PlatformStand = true
        root.CFrame += hum.MoveDirection * Settings.FlySpeed * dt
    else
        hum.PlatformStand = false
    end

    local target = GetTarget()

    if (Settings.AimbotEnabled and Settings.AimbotHolding) or
       (Settings.SilentAimEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)) then
        
        if target then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)

            if Settings.AutoFireEnabled and tick() - lastAutoFireTime >= Settings.AutoFireDelay then
                pcall(mouse1click)
                lastAutoFireTime = tick()
            end
        end
    end

    if Settings.SpinEnabled then
        root.CFrame *= CFrame.Angles(0, math.rad(Settings.SpinSpeed * dt), 0)
    end

    if Settings.UpsideDownEnabled then
        root.CFrame *= CFrame.Angles(0,0,math.rad(180))
    end

    if Settings.ChatSpamEnabled and tick() - lastChatTime >= Settings.ChatSpamDelay then
        local e = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        if e then
            e.SayMessageRequest:FireServer(Settings.ChatSpamText,"All")
        end
        lastChatTime = tick()
    end
end)

RunService.Stepped:Connect(function()
    if Settings.NoclipEnabled and LocalPlayer.Character then
        for _,v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
            end
        end
    end
end)

print("GOOD HUB V4 FULL LOADED")
