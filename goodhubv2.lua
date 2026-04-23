-- [[ GOOD HUB V3 終極手機完整版 - 絕不省略 ]] --
repeat wait() until game:IsLoaded()
-- [[ YUNUKE HUB V3 終極手機完整版 - 絕不省略原始碼 ]] --
repeat wait() until game:IsLoaded()

local HttpService = game:GetService("HttpService")
local FileName = "YUNUKE_FULL_V3.json"

local Settings = {
    AimbotEnabled = false,
    SilentAimEnabled = false, 
    AimbotKey = "B",
    AimbotPart = "Head",
    AimbotHolding = false,
    AutoFireEnabled = false,
    AutoFireDelay = 0.05, 
    FlyEnabled = false,
    FlySpeed = 200,
    NoclipEnabled = false,
    SpinEnabled = false,
    SpinSpeed = 800,
    ESPEnabled = false,
    ChatSpamEnabled = false,
    ChatSpamText = "YUNUKE HUB ON TOP!",
    ChatSpamDelay = 3,
    UpsideDownEnabled = false,
}

-- [ 存檔/讀取 ]
local function SaveSettings()
    local success, encoded = pcall(function() return HttpService:JSONEncode(Settings) end)
    if success then writefile(FileName, encoded) end
end

local function LoadSettings()
    if isfile(FileName) then
        local success, content = pcall(function() return readfile(FileName) end)
        if success and content ~= "" then
            local ds, decoded = pcall(function() return HttpService:JSONDecode(content) end)
            if ds then for k, v in pairs(decoded) do if Settings[k] ~= nil then Settings[k] = v end end end
        end
    end
end
LoadSettings()

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local lastAutoFireTime = 0

-- [[ 完整 ESP 系統：Highlight 發亮 + Billboard 血量標籤 ]] --
-- 解決你說的 Drawing 灰灰怪怪的問題，改用引擎內建渲染
local function CreateESP(player)
    local function Apply(char)
        if player == LocalPlayer then return end
        
        -- 刪除舊的
        if char:FindFirstChild("YUNUKE_Highlight") then char.YUNUKE_Highlight:Destroy() end
        if char:FindFirstChild("YUNUKE_Tag") then char.YUNUKE_Tag:Destroy() end

        -- 1. Highlight (人物發光透視)
        local hl = Instance.new("Highlight")
        hl.Name = "YUNUKE_Highlight"
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
        hl.FillColor = Color3.fromRGB(255, 0, 0)
        hl.Parent = char

        -- 2. BillboardGui (名字與血量)
        local bg = Instance.new("BillboardGui")
        bg.Name = "YUNUKE_Tag"
        bg.Adornee = char:WaitForChild("Head", 10)
        bg.Size = UDim2.new(0, 100, 0, 50)
        bg.StudsOffset = Vector3.new(0, 3, 0)
        bg.AlwaysOnTop = true
        bg.Parent = char

        local tl = Instance.new("TextLabel", bg)
        tl.Size = UDim2.new(1, 0, 1, 0)
        tl.BackgroundTransparency = 1
        tl.Font = Enum.Font.GothamBold
        tl.TextSize = 14
        tl.TextColor3 = Color3.new(1, 1, 1)
        tl.TextStrokeTransparency = 0

        local conn
        conn = RunService.RenderStepped:Connect(function()
            if not char or not char.Parent or not Settings.ESPEnabled then
                hl.Enabled = false
                bg.Enabled = false
                if char and not char.Parent then conn:Disconnect() end
                return
            end

            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                hl.Enabled = true
                bg.Enabled = true
                local hp = math.floor(hum.Health)
                tl.Text = player.DisplayName .. "\nHP: " .. hp
                local hpCol = Color3.fromHSV(math.clamp(hum.Health/hum.MaxHealth, 0, 0.33), 1, 1)
                hl.FillColor = hpCol
                tl.TextColor3 = hpCol
            else
                hl.Enabled = false
                bg.Enabled = false
            end
        end)
    end
    if player.Character then Apply(player.Character) end
    player.CharacterAdded:Connect(Apply)
end

for _, p in pairs(Players:GetPlayers()) do CreateESP(p) end
Players.PlayerAdded:Connect(CreateESP)

-- [[ 完整 Silent Aim 攔截系統 (Hooking) ]] --
-- 這是代碼最長、最核心的部分，攔截底層 Namecall 與 Index
local TargetPart = nil

local function GetClosestTarget()
    local target, dist = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            local part = p.Character:FindFirstChild(Settings.AimbotPart)
            if part then
                local pos, os = Camera:WorldToViewportPoint(part.Position)
                if os then
                    local mag = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                    if mag < dist then
                        -- 可視檢查
                        local ray = RaycastParams.new()
                        ray.FilterType = Enum.RaycastFilterType.Exclude
                        ray.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
                        local res = workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, ray)
                        if not res or res.Instance:IsDescendantOf(p.Character) then
                            dist = mag
                            target = part
                        end
                    end
                end
            end
        end
    end
    return target
end

-- MT Hooking (Silent Aim 核心)
local mt = getrawmetatable(game)
local oldIndex = mt.__index
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__index = newcclosure(function(self, key)
    if Settings.SilentAimEnabled and not checkcaller() then
        if self == UserInputService:GetMouseLocation() and key == "Hit" then
            local t = GetClosestTarget()
            if t then return t.CFrame end
        end
    end
    return oldIndex(self, key)
end)

mt.__namecall = newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod()
    
    if Settings.SilentAimEnabled and not checkcaller() then
        if method == "FindPartOnRayWithIgnoreList" or method == "Raycast" then
            local t = GetClosestTarget()
            if t then
                -- 修正射線方向至目標
                if method == "Raycast" then
                    args[2] = (t.Position - args[1]).Unit * 1000
                end
                return oldNamecall(self, unpack(args))
            end
        end
    end
    return oldNamecall(self, ...)
end)
setreadonly(mt, true)

-- [[ 手機版 UI 介面 - 支援全屏拖動與折疊 ]] --
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 240, 0, 420)
MainFrame.Position = UDim2.new(0.5, -120, 0.5, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.Visible = false
MainFrame.Active = true
MainFrame.Draggable = true -- 雖然過時，但在多數執行器仍有效
Instance.new("UICorner", MainFrame)

local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 45)
Header.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
Instance.new("UICorner", Header)

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, 0, 1, 0)
Title.Text = "YUNUKE HUB V3 FINAL"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBold
Title.BackgroundTransparency = 1

local Container = Instance.new("ScrollingFrame", MainFrame)
Container.Size = UDim2.new(1, -10, 1, -55)
Container.Position = UDim2.new(0, 5, 0, 50)
Container.BackgroundTransparency = 1
Container.CanvasSize = UDim2.new(0, 0, 0, 1100)
local UIList = Instance.new("UIListLayout", Container)
UIList.Padding = UDim.new(0, 8)

-- 手機輔助按鈕
local OpenBtn = Instance.new("TextButton", ScreenGui)
OpenBtn.Size = UDim2.new(0, 50, 0, 50)
OpenBtn.Position = UDim2.new(0, 10, 0.5, -25)
OpenBtn.Text = "OPEN"
OpenBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
OpenBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(1, 0)
OpenBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)

local LockBtn = Instance.new("TextButton", ScreenGui)
LockBtn.Size = UDim2.new(0, 65, 0, 65)
LockBtn.Position = UDim2.new(0.8, 0, 0.5, -32)
LockBtn.Text = "LOCK"
LockBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
LockBtn.BackgroundTransparency = 0.5
Instance.new("UICorner", LockBtn).CornerRadius = UDim.new(1, 0)
LockBtn.InputBegan:Connect(function(i) 
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then Settings.AimbotHolding = true LockBtn.BackgroundTransparency = 0 end 
end)
LockBtn.InputEnded:Connect(function(i) 
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then Settings.AimbotHolding = false LockBtn.BackgroundTransparency = 0.5 end 
end)

-- 工具：創建組件
local function AddToggle(name, key)
    local b = Instance.new("TextButton", Container)
    b.Size = UDim2.new(1, 0, 0, 40)
    b.BackgroundColor3 = Settings[key] and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(40, 40, 40)
    b.Text = name .. ": " .. (Settings[key] and "ON" or "OFF")
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamSemibold
    Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function()
        Settings[key] = not Settings[key]
        b.BackgroundColor3 = Settings[key] and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(40, 40, 40)
        b.Text = name .. ": " .. (Settings[key] and "ON" or "OFF")
        SaveSettings()
    end)
end

local function AddSlider(name, max, key)
    local f = Instance.new("Frame", Container)
    f.Size = UDim2.new(1, 0, 0, 50)
    f.BackgroundTransparency = 1
    local l = Instance.new("TextLabel", f)
    l.Size = UDim2.new(1, 0, 0, 20)
    l.Text = name .. ": " .. Settings[key]
    l.TextColor3 = Color3.new(1,1,1)
    l.BackgroundTransparency = 1
    local bar = Instance.new("Frame", f)
    bar.Size = UDim2.new(1, -20, 0, 5)
    bar.Position = UDim2.new(0, 10, 0, 30)
    bar.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    local fill = Instance.new("Frame", bar)
    fill.Size = UDim2.new(Settings[key]/max, 0, 1, 0)
    fill.BackgroundColor3 = Color3.new(0.4, 0.4, 1)
    
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            local conn
            conn = RunService.RenderStepped:Connect(function()
                local ratio = math.clamp((UserInputService:GetMouseLocation().X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                Settings[key] = math.floor(ratio * max)
                fill.Size = UDim2.new(ratio, 0, 1, 0)
                l.Text = name .. ": " .. Settings[key]
            end)
            i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then conn:Disconnect() SaveSettings() end end)
        end
    end)
end

-- 生成 UI
AddToggle("Aimbot (Lock)", "AimbotEnabled")
AddToggle("Silent Aim (Hook)", "SilentAimEnabled")
AddToggle("Highlight ESP", "ESPEnabled")
AddToggle("Fly (摇杆)", "FlyEnabled")
AddToggle("Noclip", "NoclipEnabled")
AddToggle("Spin Bot", "SpinEnabled")
AddSlider("Fly Speed", 1000, "FlySpeed")
AddSlider("Spin Speed", 3000, "SpinSpeed")

-- [[ 核心 RenderStepped 循環 ]] --
RunService.RenderStepped:Connect(function(dt)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    -- 1. 飛行修正 (手機版專用：偵測 MoveDirection)
    if Settings.FlyEnabled then
        hum.PlatformStand = true
        root.Velocity = Vector3.new(0, 1.5, 0) -- 抗重力
        if hum.MoveDirection.Magnitude > 0 then
            root.CFrame = root.CFrame + (hum.MoveDirection * Settings.FlySpeed * dt)
        end
    else
        if hum.PlatformStand then hum.PlatformStand = false end
    end

    -- 2. Aimbot 鎖定
    if Settings.AimbotEnabled and Settings.AimbotHolding then
        local t = GetClosestTarget()
        if t then Camera.CFrame = CFrame.new(Camera.CFrame.Position, t.Position) end
    end

    -- 3. Spin Bot
    if Settings.SpinEnabled then
        root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(Settings.SpinSpeed * dt), 0)
    end
end)

-- 4. Noclip
RunService.Stepped:Connect(function()
    if Settings.NoclipEnabled and LocalPlayer.Character then
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end
end)

print("YUNUKE FULL V3 LOADED - METATABLE HOOKS ACTIVE")

local HttpService = game:GetService("HttpService")
local FileName = "YUNUKE_FINAL_V3.json"

local Settings = {
    AimbotEnabled = false,
    SilentAimEnabled = false, 
    AimbotKey = "B",
    AimbotPart = "Head",
    AimbotHolding = false,
    AutoFireEnabled = false,
    AutoFireDelay = 0.05, 
    FlyEnabled = false,
    FlySpeed = 200,
    NoclipEnabled = false,
    SpinEnabled = false,
    SpinSpeed = 800,
    ESPEnabled = false,
    ChatSpamEnabled = false,
    ChatSpamText = "YUNUKE HUB ON TOP!",
    ChatSpamDelay = 3,
    UpsideDownEnabled = false,
}

-- [[ 存檔讀取系統 ]] --
local function SaveSettings()
    local success, encoded = pcall(function() return HttpService:JSONEncode(Settings) end)
    if success then writefile(FileName, encoded) end
end

local function LoadSettings()
    if isfile(FileName) then
        local success, content = pcall(function() return readfile(FileName) end)
        if success and content ~= "" then
            local ds, decoded = pcall(function() return HttpService:JSONDecode(content) end)
            if ds then for k, v in pairs(decoded) do if Settings[k] ~= nil then Settings[k] = v end end end
        end
    end
end
LoadSettings()

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local lastAutoFireTime = 0

-- [[ 核心目標獲取 (加上可視檢查) ]] --
local function IsVisible(part)
    local ray = RaycastParams.new()
    ray.FilterType = Enum.RaycastFilterType.Exclude
    ray.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    local result = workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, ray)
    return not result or result.Instance:IsDescendantOf(part.Parent)
end

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
                        dist = mag
                        target = part
                    end
                end
            end
        end
    end
    return target
end

-- [[ 完整 Silent Aim 鉤子系統 ]] --
-- 這是讓子彈自動轉向的核心，攔截遊戲對滑鼠位置的詢問
local oldIndex
oldIndex = hookmetamethod(game, "__index", function(self, key)
    if Settings.SilentAimEnabled and self == UserInputService:GetMouseLocation() and key == "Hit" then
        local t = GetClosestTarget()
        if t then return t.CFrame end
    end
    return oldIndex(self, key)
end)

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local args = {...}
    local method = getnamecallmethod()
    if Settings.SilentAimEnabled and not checkcaller() then
        if method == "FindPartOnRayWithIgnoreList" or method == "Raycast" or method == "FireServer" then
            local t = GetClosestTarget()
            if t then
                -- 根據不同遊戲改寫參數，這部分是 Silent Aim 最強的地方
                if method == "FireServer" and tostring(self) == "MainEvent" then -- 例如 Da Hood
                    args[2] = t.Position
                    return oldNamecall(self, unpack(args))
                end
            end
        end
    end
    return oldNamecall(self, ...)
end)

-- [[ 改良版 Highlight ESP (絕不灰灰，超清晰) ]] --
local function CreateESP(player)
    local function Apply(char)
        if player == LocalPlayer then return end
        
        -- 發亮 Chams
        local highlight = char:FindFirstChild("YUNUKE_Highlight") or Instance.new("Highlight")
        highlight.Name = "YUNUKE_Highlight"
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.Parent = char

        -- 血量 UI
        local bill = char:FindFirstChild("YUNUKE_Tag") or Instance.new("BillboardGui")
        bill.Name = "YUNUKE_Tag"
        bill.Size = UDim2.new(0, 100, 0, 50)
        bill.AlwaysOnTop = true
        bill.StudsOffset = Vector3.new(0, 3, 0)
        bill.Parent = char
        
        local label = bill:FindFirstChild("Text") or Instance.new("TextLabel", bill)
        label.Name = "Text"
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamBold
        label.TextSize = 13
        
        local conn
        conn = RunService.RenderStepped:Connect(function()
            if not char.Parent or not Settings.ESPEnabled then
                highlight.Enabled = false
                bill.Enabled = false
                if not char.Parent then conn:Disconnect() end
                return
            end
            
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                highlight.Enabled = true
                bill.Enabled = true
                bill.Adornee = char:FindFirstChild("Head")
                local hp = math.floor(hum.Health)
                label.Text = player.DisplayName .. "\nHP: " .. hp
                local color = Color3.fromHSV(math.clamp(hum.Health/hum.MaxHealth, 0, 0.33), 1, 1)
                highlight.FillColor = color
                label.TextColor3 = color
            end
        end)
    end
    if player.Character then Apply(player.Character) end
    player.CharacterAdded:Connect(Apply)
end

for _, p in pairs(Players:GetPlayers()) do CreateESP(p) end
Players.PlayerAdded:Connect(CreateESP)

-- [[ 手機版 UI 介面 - 支援觸控拖動 ]] --
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 220, 0, 400)
MainFrame.Position = UDim2.new(0.5, -110, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.Visible = false
local UICorner = Instance.new("UICorner", MainFrame)

local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
Instance.new("UICorner", Header)

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, 0, 1, 0)
Title.Text = "YUNUKE HUB V3"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.BackgroundTransparency = 1

local Container = Instance.new("ScrollingFrame", MainFrame)
Container.Size = UDim2.new(1, -10, 1, -50)
Container.Position = UDim2.new(0, 5, 0, 45)
Container.BackgroundTransparency = 1
Container.CanvasSize = UDim2.new(0, 0, 0, 1000)
local UIList = Instance.new("UIListLayout", Container)
UIList.Padding = UDim.new(0, 5)

-- OPEN 按鈕 (手機必備)
local OpenBtn = Instance.new("TextButton", ScreenGui)
OpenBtn.Size = UDim2.new(0, 50, 0, 50)
OpenBtn.Position = UDim2.new(0, 10, 0.4, 0)
OpenBtn.Text = "OPEN"
OpenBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
OpenBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(1, 0)
OpenBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)

-- LOCK 按鈕 (按住鎖碼)
local LockBtn = Instance.new("TextButton", ScreenGui)
LockBtn.Size = UDim2.new(0, 60, 0, 60)
LockBtn.Position = UDim2.new(0.8, 0, 0.5, 0)
LockBtn.Text = "LOCK"
LockBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
LockBtn.BackgroundTransparency = 0.5
Instance.new("UICorner", LockBtn).CornerRadius = UDim.new(1, 0)

LockBtn.InputBegan:Connect(function(i) 
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then 
        Settings.AimbotHolding = true LockBtn.BackgroundTransparency = 0 
    end 
end)
LockBtn.InputEnded:Connect(function(i) 
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then 
        Settings.AimbotHolding = false LockBtn.BackgroundTransparency = 0.5 
    end 
end)

-- [[ 功能按鈕生成 ]] --
local function AddToggle(text, key)
    local b = Instance.new("TextButton", Container)
    b.Size = UDim2.new(1, 0, 0, 35)
    b.Text = text .. ": " .. (Settings[key] and "ON" or "OFF")
    b.BackgroundColor3 = Settings[key] and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(50, 50, 50)
    b.TextColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function()
        Settings[key] = not Settings[key]
        b.Text = text .. ": " .. (Settings[key] and "ON" or "OFF")
        b.BackgroundColor3 = Settings[key] and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(50, 50, 50)
        SaveSettings()
    end)
end

AddToggle("Aimbot (Lock)", "AimbotEnabled")
AddToggle("Silent Aim", "SilentAimEnabled")
AddToggle("ESP Highlight", "ESPEnabled")
AddToggle("Fly (JoyStick)", "FlyEnabled")
AddToggle("Noclip", "NoclipEnabled")
AddToggle("Spin Bot", "SpinEnabled")

-- [[ 最終核心循環 ]] --
RunService.RenderStepped:Connect(function(dt)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    -- 1. 飛行：解決手機不能動的問題，使用 MoveDirection
    if Settings.FlyEnabled then
        hum.PlatformStand = true
        root.Velocity = Vector3.new(0, 0.5, 0)
        if hum.MoveDirection.Magnitude > 0 then
            root.CFrame = root.CFrame + (hum.MoveDirection * Settings.FlySpeed * dt)
        end
    else
        if hum.PlatformStand then hum.PlatformStand = false end
    end

    -- 2. Aimbot 鎖碼
    if Settings.AimbotEnabled and Settings.AimbotHolding then
        local t = GetClosestTarget()
        if t then Camera.CFrame = CFrame.new(Camera.CFrame.Position, t.Position) end
    end

    -- 3. Spin Bot
    if Settings.SpinEnabled then
        root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(Settings.SpinSpeed * dt), 0)
    end
end)

-- Noclip
RunService.Stepped:Connect(function()
    if Settings.NoclipEnabled and LocalPlayer.Character then
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end
end)

print("YUNUKE FINAL V3 LOADED - FULL SILENT AIM HOOKS INCLUDED")
