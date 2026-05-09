-- https://discord.gg/dBF9H8c3w2
repeat wait() until game:IsLoaded()

local HttpService = game:GetService("HttpService")
local FileName = "YUNUKE_CONFIG_V2.json"

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
    DanceEnabled = false,
    ESPEnabled = false,
    IsBinding = false,
    ChatSpamEnabled = false,
    ChatSpamText = "ezz",
    ChatSpamDelay = 3,
    UpsideDownEnabled = false,
    NightModeEnabled = false,
    CrosshairEnabled = false,
    CrosshairSize = 12, 
    CrosshairGap = 8,   
    CrosshairSpinSpeed = 150,
    FOVEnabled = false,
    FOVRadius = 150,
    ScreenColorEnabled = false,
    ScreenColorR = 255,
    ScreenColorG = 0,
    ScreenColorB = 0,
    HideKey = "RightShift", 
    IsBindingHide = false,
    ControllerSpoofEnabled = false,
    VrSpoofEnabled = false,
    RainEnabled = false,
    FPSBoostEnabled = false 
}

local function SaveSettings()
    local success, encoded = pcall(function() return HttpService:JSONEncode(Settings) end)
    if success then writefile(FileName, encoded) end
end

local function LoadSettings()
    if isfile(FileName) then
        local success, content = pcall(function() return readfile(FileName) end)
        if success and content ~= "" then
            local decode_success, decoded = pcall(function() 
                return HttpService:JSONDecode(content) 
            end)
            
            if decode_success and type(decoded) == "table" then
                for k, v in pairs(decoded) do 
                    if Settings[k] ~= nil then 
                        Settings[k] = v 
                    end 
                end
            else
                warn("設定檔格式錯誤，已載入預設值")
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
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local lastAutoFireTime = 0
local lastChatTime = 0

-- [邏輯保持原樣]
local function ApplyFPSBoost(state)
    if state then
        settings().Rendering.QualityLevel = 1
        for _, v in pairs(game:GetDescendants()) do
            if v:IsA("Part") or v:IsA("UnionOperation") or v:IsA("MeshPart") then
                v.Material = Enum.Material.Plastic
                v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                v.Enabled = false
            elseif v:IsA("Explosion") then
                v.Visible = false
            end
        end
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        settings().Physics.PhysicsEnvironmentalThrottle = 1
    else
        settings().Rendering.QualityLevel = Enum.QualityLevel.Default
        Lighting.GlobalShadows = true
    end
end

local function ApplyControllerSpoof(state)
    if state then
        pcall(function()
            local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Replication"):WaitForChild("Fighter"):WaitForChild("SetControls")
            remote:FireServer("MouseKeyboard")
            task.wait(0.3)
            remote:FireServer("Gamepad")
        end)
    else
        pcall(function()
            local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Replication"):WaitForChild("Fighter"):WaitForChild("SetControls")
            remote:FireServer("MouseKeyboard")
        end)
    end
end

local function ApplyVRSpoof(state)
    if state then
        pcall(function()
            local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Replication"):WaitForChild("Fighter"):WaitForChild("SetControls")
            remote:FireServer("MouseKeyboard")
            task.wait(0.3)
            remote:FireServer("VR")
        end)
    else
        pcall(function()
            local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Replication"):WaitForChild("Fighter"):WaitForChild("SetControls")
            remote:FireServer("MouseKeyboard")
        end)
    end
end

local RainEmitter = nil
local RainAttachment = nil
local function UpdateRain()
    if Settings.RainEnabled and LocalPlayer.Character then
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            if not RainEmitter then
                RainAttachment = Instance.new("Attachment", root)
                RainAttachment.Position = Vector3.new(0, 20, 0)
                RainEmitter = Instance.new("ParticleEmitter", RainAttachment)
                RainEmitter.Texture = "rbxassetid://133539157"
                RainEmitter.Size = NumberSequence.new(0.5)
                RainEmitter.Acceleration = Vector3.new(0, -100, 0)
                RainEmitter.Lifetime = NumberRange.new(1, 1.5)
                RainEmitter.Rate = 1000
                RainEmitter.Speed = NumberRange.new(50, 80)
                RainEmitter.Transparency = NumberSequence.new(0.6)
            end
            RainEmitter.Enabled = true
        end
    elseif RainEmitter then
        RainEmitter.Enabled = false
    end
end

local danceAnim = Instance.new("Animation")
danceAnim.AnimationId = "rbxassetid://507771019"
local currentDanceTrack = nil
local loadedDanceChar = nil

local function GetRoot(char) 
    return char and char:FindFirstChild("HumanoidRootPart") 
end

local function CreateESP(player)
    local Box = Drawing.new("Square")
    local HealthBarOutline = Drawing.new("Square")
    local HealthBar = Drawing.new("Square")
    local Skeleton = {}
    local BodyParts = {{"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"}, {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"}, {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"}, {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"}, {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}}
    local BodyPartsR6 = {{"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"}}

    for i = 1, 15 do
        local line = Drawing.new("Line")
        line.Visible = false
        line.Color = Color3.fromRGB(255, 255, 255)
        line.Thickness = 1
        table.insert(Skeleton, line)
    end

    local function Update()
        local connection
        connection = RunService.RenderStepped:Connect(function()
            if Settings.ESPEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 and player ~= LocalPlayer then
                local char = player.Character
                local hum = char.Humanoid
                local position, onScreen = Camera:WorldToViewportPoint(char.HumanoidRootPart.Position)
                if onScreen then
                    local sizeX, sizeY = 2200 / position.Z, 3200 / position.Z
                    local boxPos = Vector2.new(position.X - sizeX / 2, position.Y - sizeY / 2)
                    Box.Size, Box.Position, Box.Visible = Vector2.new(sizeX, sizeY), boxPos, true
                    local healthPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    HealthBarOutline.Size, HealthBarOutline.Position, HealthBarOutline.Visible = Vector2.new(5, sizeY + 2), Vector2.new(boxPos.X - 7, boxPos.Y - 1), true
                    HealthBar.Size, HealthBar.Position, HealthBar.Color, HealthBar.Visible = Vector2.new(3, sizeY * healthPercent), Vector2.new(boxPos.X - 6, boxPos.Y + (sizeY * (1 - healthPercent))), Color3.fromHSV(healthPercent * 0.3, 1, 1), true
                    local parts = (hum.RigType == Enum.HumanoidRigType.R15) and BodyParts or BodyPartsR6
                    for i, pair in pairs(parts) do
                        local p1, p2 = char:FindFirstChild(pair[1]), char:FindFirstChild(pair[2])
                        if p1 and p2 and Skeleton[i] then
                            local pos1, vis1 = Camera:WorldToViewportPoint(p1.Position)
                            local pos2, vis2 = Camera:WorldToViewportPoint(p2.Position)
                            if vis1 and vis2 then
                                Skeleton[i].From, Skeleton[i].To, Skeleton[i].Visible = Vector2.new(pos1.X, pos1.Y), Vector2.new(pos2.X, pos2.Y), true
                            else Skeleton[i].Visible = false end
                        end
                    end
                else
                    Box.Visible, HealthBarOutline.Visible, HealthBar.Visible = false, false, false
                    for _, l in pairs(Skeleton) do l.Visible = false end
                end
            else
                Box.Visible, HealthBarOutline.Visible, HealthBar.Visible = false, false, false
                for _, l in pairs(Skeleton) do l.Visible = false end
                if not player.Parent then connection:Disconnect() Box:Remove() HealthBarOutline:Remove() HealthBar:Remove() for _, l in pairs(Skeleton) do l:Remove() end end
            end
        end)
    end
    coroutine.wrap(Update)()
end

for _, v in pairs(Players:GetPlayers()) do if v ~= LocalPlayer then CreateESP(v) end end
Players.PlayerAdded:Connect(CreateESP)



local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
ScreenGui.Name = "YUNUKE_PIXEL_V2"
ScreenGui.ResetOnSpawn = false


local TintGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
TintGui.DisplayOrder = -1
local TintFrame = Instance.new("Frame", TintGui)
TintFrame.Size, TintFrame.BackgroundTransparency, TintFrame.BorderSizePixel, TintFrame.Visible = UDim2.new(1, 0, 1, 0), 0.7, 0, false


local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 420, 0, 320)
MainFrame.Position = UDim2.new(0.5, -210, 0.5, -160)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 35)
Header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Header.BorderSizePixel = 0

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, -10, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "GOOD HUB"
Title.TextColor3 = Color3.fromRGB(0, 0, 0)
Title.Font = Enum.Font.Code
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left


local TabHolder = Instance.new("Frame", MainFrame)
TabHolder.Size = UDim2.new(0, 100, 1, -45)
TabHolder.Position = UDim2.new(0, 5, 0, 40)
TabHolder.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
TabHolder.BorderSizePixel = 1
TabHolder.BorderColor3 = Color3.fromRGB(60, 60, 60)

local TabListLayout = Instance.new("UIListLayout", TabHolder)
TabListLayout.Padding = UDim.new(0, 2)


local ContentHolder = Instance.new("Frame", MainFrame)
ContentHolder.Size = UDim2.new(1, -115, 1, -45)
ContentHolder.Position = UDim2.new(0, 110, 0, 40)
ContentHolder.BackgroundTransparency = 1

local Pages = {}
local function CreatePage(name)
    local Page = Instance.new("ScrollingFrame", ContentHolder)
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.Visible = false
    Page.ScrollBarThickness = 2
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    Page.BorderSizePixel = 0
    local Layout = Instance.new("UIListLayout", Page)
    Layout.Padding = UDim.new(0, 5)
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    
    Pages[name] = Page
    
    local TabBtn = Instance.new("TextButton", TabHolder)
    TabBtn.Size = UDim2.new(1, 0, 0, 30)
    TabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    TabBtn.BorderSizePixel = 0
    TabBtn.Text = name:upper()
    TabBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
    TabBtn.Font = Enum.Font.Code
    TabBtn.TextSize = 14
    
    TabBtn.MouseButton1Click:Connect(function()
        for _, p in pairs(Pages) do p.Visible = false end
        Page.Visible = true
        for _, b in pairs(TabHolder:GetChildren()) do if b:IsA("TextButton") then b.TextColor3 = Color3.fromRGB(150, 150, 150) b.BackgroundColor3 = Color3.fromRGB(35, 35, 35) end end
        TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        TabBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end)
    return Page
end


local function AddToggle(parent, text, key, callback)
    local Btn = Instance.new("TextButton", parent)
    Btn.Size = UDim2.new(1, -5, 0, 30)
    Btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Btn.BorderSizePixel = 1
    Btn.BorderColor3 = Color3.fromRGB(60, 60, 60)
    Btn.Text = ""
    
    local L = Instance.new("TextLabel", Btn)
    L.Size = UDim2.new(1, -40, 1, 0)
    L.Position = UDim2.new(0, 5, 0, 0)
    L.BackgroundTransparency = 1
    L.Text = text:upper()
    L.TextColor3 = Color3.fromRGB(200, 200, 200)
    L.Font = Enum.Font.Code
    L.TextSize = 13
    L.TextXAlignment = Enum.TextXAlignment.Left
    
    local S = Instance.new("TextLabel", Btn)
    S.Size = UDim2.new(0, 30, 1, 0)
    S.Position = UDim2.new(1, -35, 0, 0)
    S.BackgroundTransparency = 1
    S.Text = Settings[key] and "[X]" or "[ ]"
    S.TextColor3 = Settings[key] and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    S.Font = Enum.Font.Code
    S.TextSize = 14

    Btn.MouseButton1Click:Connect(function()
        Settings[key] = not Settings[key]
        SaveSettings()
        S.Text = Settings[key] and "[X]" or "[ ]"
        S.TextColor3 = Settings[key] and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
        if callback then callback(Settings[key]) end
    end)
    parent.CanvasSize = UDim2.new(0, 0, 0, parent.UIListLayout.AbsoluteContentSize.Y)
end

local function AddSlider(parent, text, max, key)
    local Frame = Instance.new("Frame", parent)
    Frame.Size = UDim2.new(1, -5, 0, 45)
    Frame.BackgroundTransparency = 1
    
    local L = Instance.new("TextLabel", Frame)
    L.Size = UDim2.new(1, 0, 0, 20)
    L.Text = text:upper() .. ": " .. Settings[key]
    L.TextColor3 = Color3.fromRGB(200, 200, 200)
    L.Font = Enum.Font.Code
    L.TextSize = 12
    L.BackgroundTransparency = 1
    L.TextXAlignment = Enum.TextXAlignment.Left
    
    local Bar = Instance.new("TextButton", Frame)
    Bar.Size = UDim2.new(1, 0, 0, 15)
    Bar.Position = UDim2.new(0, 0, 0, 22)
    Bar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Bar.BorderSizePixel = 1
    Bar.Text = ""
    
    local Fill = Instance.new("Frame", Bar)
    Fill.Size = UDim2.new(Settings[key]/max, 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Fill.BorderSizePixel = 0
    
    local dragging = false
    local function Update()
        local ratio = math.clamp((UserInputService:GetMouseLocation().X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
        Settings[key] = math.floor(ratio * max)
        Fill.Size = UDim2.new(ratio, 0, 1, 0)
        L.Text = text:upper() .. ": " .. Settings[key]
    end
    Bar.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 and dragging then dragging = false SaveSettings() end end)
    RunService.RenderStepped:Connect(function() if dragging then Update() end end)
    parent.CanvasSize = UDim2.new(0, 0, 0, parent.UIListLayout.AbsoluteContentSize.Y)
end


local CombatPage = CreatePage("Combat")
local VisualPage = CreatePage("Visual")
local MovePage = CreatePage("Move")
local MiscPage = CreatePage("Misc")

AddToggle(CombatPage, "Aimbot", "AimbotEnabled")
AddToggle(CombatPage, "Auto Aimbot", "SilentAimEnabled")
AddToggle(CombatPage, "Auto Fire", "AutoFireEnabled")

AddToggle(VisualPage, "ESP", "ESPEnabled")
AddToggle(VisualPage, "Night Mode", "NightModeEnabled")
AddToggle(VisualPage, "Crosshair", "CrosshairEnabled")
AddToggle(VisualPage, "FOV Circle", "FOVEnabled")
AddToggle(VisualPage, "Screen Color Tint", "ScreenColorEnabled")
AddToggle(VisualPage, "Rain Effect", "RainEnabled")
AddSlider(VisualPage, "Crosshair Size", 50, "CrosshairSize")
AddSlider(VisualPage, "Crosshair Gap", 30, "CrosshairGap")
AddSlider(VisualPage, "FOV Radius", 800, "FOVRadius")

AddToggle(MovePage, "Fly", "FlyEnabled")
AddToggle(MovePage, "Noclip", "NoclipEnabled")
AddToggle(MovePage, "Spin Bot", "SpinEnabled")
AddToggle(MovePage, "Upside Down", "UpsideDownEnabled")
AddSlider(MovePage, "Spin Speed", 3000, "SpinSpeed")
AddSlider(MovePage, "Flight Speed", 1000, "FlySpeed")

AddToggle(MiscPage, "FPS Boost", "FPSBoostEnabled", function(v) ApplyFPSBoost(v) end)
AddToggle(MiscPage, "Gamepad Spoof", "ControllerSpoofEnabled", function(v) ApplyControllerSpoof(v) end)
AddToggle(MiscPage, "VR Spoof", "VRSpoofEnabled", function(v) ApplyVRSpoof(v) end)
AddToggle(MiscPage, "Dance", "DanceEnabled")


local SkinBtn = Instance.new("TextButton", MiscPage)
SkinBtn.Size, SkinBtn.BackgroundColor3, SkinBtn.Text, SkinBtn.Font, SkinBtn.TextColor3, SkinBtn.TextSize = UDim2.new(1, -5, 0, 30), Color3.fromRGB(40, 40, 80), "LOAD GUN SKIN", Enum.Font.Code, Color3.new(1, 1, 1), 13
SkinBtn.MouseButton1Click:Connect(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/endoverdosing/Soluna-API/refs/heads/main/skin-changer.lua",true))() end)

local BindBtn = Instance.new("TextButton", MiscPage)
BindBtn.Size, BindBtn.BackgroundColor3, BindBtn.Text, BindBtn.Font, BindBtn.TextColor3, BindBtn.TextSize = UDim2.new(1, -5, 0, 30), Color3.fromRGB(45, 45, 45), "AIM KEY: ["..Settings.AimbotKey.."]", Enum.Font.Code, Color3.new(1, 1, 1), 13
BindBtn.MouseButton1Click:Connect(function() Settings.IsBinding = true BindBtn.Text = "... PRESS ANY KEY ..." end)

local HideBtn = Instance.new("TextButton", MiscPage)
HideBtn.Size, HideBtn.BackgroundColor3, HideBtn.Text, HideBtn.Font, HideBtn.TextColor3, HideBtn.TextSize = UDim2.new(1, -5, 0, 30), Color3.fromRGB(45, 45, 45), "HIDE KEY: ["..Settings.HideKey.."]", Enum.Font.Code, Color3.new(1, 1, 1), 13
HideBtn.MouseButton1Click:Connect(function() Settings.IsBindingHide = true HideBtn.Text = "... PRESS ANY KEY ..." end)

Pages["Combat"].Visible = true 


local draggingUI, dragStartUI, startPosUI
Header.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingUI = true dragStartUI = input.Position startPosUI = MainFrame.Position end end)
UserInputService.InputChanged:Connect(function(input) if draggingUI and input.UserInputType == Enum.UserInputType.MouseMovement then local delta = input.Position - dragStartUI MainFrame.Position = UDim2.new(startPosUI.X.Scale, startPosUI.X.Offset + delta.X, startPosUI.Y.Scale, startPosUI.Y.Offset + delta.Y) end end)
UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingUI = false end end)

local MouseHolding = false
UserInputService.InputBegan:Connect(function(i, g)
    if Settings.IsBinding then
        local key = (i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode.Name) or i.UserInputType.Name
        Settings.AimbotKey = key BindBtn.Text = "AIM KEY: ["..key.."]" Settings.IsBinding = false SaveSettings() return
    end
    if Settings.IsBindingHide then
        local key = (i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode.Name) or i.UserInputType.Name
        Settings.HideKey = key HideBtn.Text = "HIDE KEY: ["..key.."]" Settings.IsBindingHide = false SaveSettings() return
    end
    if not g and (i.KeyCode.Name == Settings.HideKey or i.UserInputType.Name == Settings.HideKey) then ScreenGui.Enabled = not ScreenGui.Enabled end
    if i.UserInputType == Enum.UserInputType.MouseButton1 then MouseHolding = true end
    if not g and (i.KeyCode.Name == Settings.AimbotKey or i.UserInputType.Name == Settings.AimbotKey) then Settings.AimbotHolding = true end
end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then MouseHolding = false end if i.KeyCode.Name == Settings.AimbotKey or i.UserInputType.Name == Settings.AimbotKey then Settings.AimbotHolding = false end end)


local crosshairLines = {}
for i = 1, 4 do local line = Drawing.new("Line") line.Visible, line.Color, line.Thickness = false, Color3.fromRGB(15, 30, 150), 2.5 table.insert(crosshairLines, line) end
local crosshairText = Drawing.new("Text")
crosshairText.Visible, crosshairText.Color, crosshairText.Text, crosshairText.Size, crosshairText.Center, crosshairText.Outline, crosshairText.Font = false, Color3.fromRGB(15, 30, 150), "goodhub", 16, true, true, 2
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible, FOVCircle.Color, FOVCircle.Thickness, FOVCircle.Transparency, FOVCircle.NumSides = false, Color3.fromRGB(255, 255, 255), 1.5, 0.8, 100

local function GetClosestTarget()
    local target, dist = nil, Settings.FOVEnabled and Settings.FOVRadius or math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            local head = p.Character:FindFirstChild(Settings.AimbotPart)
            if head then
                local pos, os = Camera:WorldToViewportPoint(head.Position)
                if os then
                    local mag = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                    if mag < dist then dist = mag target = head end
                end
            end
        end
    end
    return target
end

RunService:BindToRenderStep("SOLIX_SYSTEM_LOCK", 201, function()
    if (Settings.AimbotEnabled and Settings.AimbotHolding) or (Settings.SilentAimEnabled and MouseHolding) then
        local target = GetClosestTarget()
        if target then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
            local root = GetRoot(LocalPlayer.Character)
            if root then root.CFrame = CFrame.new(root.Position, Vector3.new(target.Position.X, root.Position.Y, target.Position.Z)) end
            if Settings.AutoFireEnabled and tick() - lastAutoFireTime >= Settings.AutoFireDelay then if mouse1click then mouse1click() end lastAutoFireTime = tick() end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    UpdateRain()
    if Settings.ScreenColorEnabled then TintFrame.BackgroundColor3, TintFrame.Visible = Color3.fromRGB(Settings.ScreenColorR, Settings.ScreenColorG, Settings.ScreenColorB), true else TintFrame.Visible = false end
    Lighting.ClockTime = Settings.NightModeEnabled and 0 or 14
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    if Settings.CrosshairEnabled then
        local theta = math.rad(tick() * Settings.CrosshairSpinSpeed)
        for i = 1, 4 do
            local angle = theta + (math.pi / 2) * (i - 1)
            local dir = Vector2.new(math.cos(angle), math.sin(angle))
            crosshairLines[i].From, crosshairLines[i].To, crosshairLines[i].Visible = center + (dir * Settings.CrosshairGap), center + (dir * (Settings.CrosshairGap + Settings.CrosshairSize)), true
        end
        crosshairText.Position, crosshairText.Visible = Vector2.new(center.X, center.Y + Settings.CrosshairGap + Settings.CrosshairSize + 10), true
    else for i = 1, 4 do crosshairLines[i].Visible = false end crosshairText.Visible = false end
    if Settings.FOVEnabled then FOVCircle.Position, FOVCircle.Radius, FOVCircle.Visible = center, Settings.FOVRadius, true else FOVCircle.Visible = false end

    local char = LocalPlayer.Character
    local root = GetRoot(char)
    local hum = char and char:FindFirstChild("Humanoid")
    if not root or not hum then return end

    if Settings.DanceEnabled then
        if loadedDanceChar ~= char then
            if currentDanceTrack then currentDanceTrack:Stop() end
            local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
            currentDanceTrack = animator:LoadAnimation(danceAnim)
            currentDanceTrack.Looped = true currentDanceTrack:Play() loadedDanceChar = char
        elseif currentDanceTrack and not currentDanceTrack.IsPlaying then currentDanceTrack:Play() end
    elseif currentDanceTrack and currentDanceTrack.IsPlaying then currentDanceTrack:Stop() end

    if Settings.FlyEnabled then
        hum:ChangeState(11) root.Velocity = Vector3.zero
        local dt = task.wait() local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0) end
        if dir.Magnitude > 0 then root.CFrame += (dir.Unit * Settings.FlySpeed * dt) end
    elseif hum:GetState() == Enum.HumanoidStateType.Physics then hum:ChangeState(7) end

    if Settings.SpinEnabled and not (Settings.AimbotHolding or (Settings.SilentAimEnabled and MouseHolding)) then
        hum.AutoRotate = false root.CFrame *= CFrame.Angles(0, math.rad(Settings.SpinSpeed / 10), 0)
    elseif not Settings.SpinEnabled and not Settings.FlyEnabled then hum.AutoRotate = true end
    if Settings.UpsideDownEnabled then root.CFrame *= CFrame.Angles(0, 0, math.rad(180)) end
end)

RunService.Stepped:Connect(function() if Settings.NoclipEnabled and LocalPlayer.Character then for _, p in pairs(LocalPlayer.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end end)
