repeat wait() until game:IsLoaded()

local HttpService = game:GetService("HttpService")
local FileName = "YUNUKE_CONFIG_FINAL.json"

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
    DanceID = "131758838511368",
    ESPEnabled = false,
    IsBinding = false,
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
    FPSBoostEnabled = false,
    DarkMapEnabled = false,
    Resolution43Enabled = false,
    WalkSpeedEnabled = false,
    WalkSpeedValue = 100,
    InfiniteJumpEnabled = false,
    StickToHeadEnabled = false 
}

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
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local lastAutoFireTime = 0

local DarkMapConnection = nil
local OriginalColors = {}

local function ApplyDarkMap(state)
    local darkColor = Color3.fromRGB(30, 35, 38)
    local targetColor = Color3.fromRGB(151, 153, 163)
    local function isColorClose(c1, c2, threshold)
        threshold = (threshold or 10) / 255
        return math.abs(c1.R - c2.R) < threshold and math.abs(c1.G - c2.G) < threshold and math.abs(c1.B - c2.B) < threshold
    end
    if state then
        for _, v in ipairs(workspace:GetDescendants()) do
            if (v:IsA("Part") or v:IsA("MeshPart") or v:IsA("UnionOperation")) and isColorClose(v.Color, targetColor) then
                OriginalColors[v] = v.Color v.Color = darkColor
            end
        end
        DarkMapConnection = workspace.DescendantAdded:Connect(function(desc)
            if (desc:IsA("Part") or desc:IsA("MeshPart") or desc:IsA("UnionOperation")) and isColorClose(desc.Color, targetColor) then
                OriginalColors[desc] = desc.Color desc.Color = darkColor
            end
        end)
    else
        if DarkMapConnection then DarkMapConnection:Disconnect() DarkMapConnection = nil end
        for part, origColor in pairs(OriginalColors) do if part and part.Parent then part.Color = origColor end end
        table.clear(OriginalColors)
    end
end

local NightModeConnection = nil
local function ApplyNightMode(state)
    if state then
        Lighting.ClockTime = 0
        NightModeConnection = Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
            if Settings.NightModeEnabled and Lighting.ClockTime ~= 0 then Lighting.ClockTime = 0 end
        end)
    else
        if NightModeConnection then NightModeConnection:Disconnect() NightModeConnection = nil end
        Lighting.ClockTime = 14
    end
end

local function ApplyFPSBoost(state)
    if state then
        settings().Rendering.QualityLevel = 1
        for _, v in pairs(game:GetDescendants()) do
            if v:IsA("Part") or v:IsA("UnionOperation") or v:IsA("MeshPart") then v.Material = Enum.Material.Plastic v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 1
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then v.Enabled = false
            elseif v:IsA("Explosion") then v.Visible = false end
        end
        Lighting.GlobalShadows, Lighting.FogEnd = false, 9e9
        settings().Physics.PhysicsEnvironmentalThrottle = 1
    else settings().Rendering.QualityLevel = Enum.QualityLevel.Default Lighting.GlobalShadows = true end
end

local function ApplyControllerSpoof(state)
    local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Replication"):WaitForChild("Fighter"):WaitForChild("SetControls")
    if state then pcall(function() remote:FireServer("MouseKeyboard") task.wait(0.3) remote:FireServer("Gamepad") end)
    else pcall(function() remote:FireServer("MouseKeyboard") end) end
end

local function ApplyVRSpoof(state)
    local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Replication"):WaitForChild("Fighter"):WaitForChild("SetControls")
    if state then pcall(function() remote:FireServer("MouseKeyboard") task.wait(0.3) remote:FireServer("VR") end)
    else pcall(function() remote:FireServer("MouseKeyboard") end) end
end

local danceAnim = Instance.new("Animation")
danceAnim.AnimationId = "rbxassetid://" .. Settings.DanceID
local currentDanceTrack, loadedDanceChar = nil, nil

local function GetRoot(char) return char and char:FindFirstChild("HumanoidRootPart") end

local function GetNearestPlayer(maxDist)
    local target, dist = nil, maxDist or math.huge
    local myRoot = GetRoot(LocalPlayer.Character)
    if not myRoot then return nil end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            local hum = p.Character:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                local d = (myRoot.Position - p.Character.Head.Position).Magnitude
                if d < dist then dist, target = d, p end
            end
        end
    end
    return target
end

local function CreateESP(player)
    local Box, HealthBarOutline, HealthBar = Drawing.new("Square"), Drawing.new("Square"), Drawing.new("Square")
    local Skeleton = {}
    local BodyParts = {{"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"}, {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"}, {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"}, {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"}, {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}}
    local BodyPartsR6 = {{"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"}}
    for i = 1, 15 do local line = Drawing.new("Line") line.Visible, line.Color, line.Thickness = false, Color3.fromRGB(255, 255, 255), 1 table.insert(Skeleton, line) end
    local function Update()
        local connection; connection = RunService.RenderStepped:Connect(function()
            if Settings.ESPEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 and player ~= LocalPlayer then
                local char, hum = player.Character, player.Character.Humanoid
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
                            if vis1 and vis2 then Skeleton[i].From, Skeleton[i].To, Skeleton[i].Visible = Vector2.new(pos1.X, pos1.Y), Vector2.new(pos2.X, pos2.Y), true
                            else Skeleton[i].Visible = false end
                        end
                    end
                else Box.Visible, HealthBarOutline.Visible, HealthBar.Visible = false, false, false for _, l in pairs(Skeleton) do l.Visible = false end end
            else 
                Box.Visible, HealthBarOutline.Visible, HealthBar.Visible = false, false, false for _, l in pairs(Skeleton) do l.Visible = false end
                if not player.Parent then connection:Disconnect() Box:Remove() HealthBarOutline:Remove() HealthBar:Remove() for _, l in pairs(Skeleton) do l:Remove() end end 
            end
        end)
    end
    coroutine.wrap(Update)()
end

for _, v in pairs(Players:GetPlayers()) do if v ~= LocalPlayer then CreateESP(v) end end
Players.PlayerAdded:Connect(CreateESP)

local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
ScreenGui.Name, ScreenGui.ResetOnSpawn = "YUNUKE_PIXEL_FINAL", false

local OpenBtn = Instance.new("TextButton", ScreenGui)
OpenBtn.Size, OpenBtn.Position = UDim2.new(0, 55, 0, 25), UDim2.new(0, 10, 0.45, 0)
OpenBtn.BackgroundColor3, OpenBtn.BorderSizePixel, OpenBtn.BorderColor3 = Color3.fromRGB(20, 20, 20), 2, Color3.fromRGB(255, 255, 255)
OpenBtn.Text, OpenBtn.TextColor3, OpenBtn.Font, OpenBtn.TextSize = "OPEN", Color3.new(1, 1, 1), Enum.Font.Code, 13

local TintGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
TintGui.DisplayOrder = -1
local TintFrame = Instance.new("Frame", TintGui)
TintFrame.Size, TintFrame.BackgroundTransparency, TintFrame.BorderSizePixel, TintFrame.Visible = UDim2.new(1, 0, 1, 0), 0.7, 0, false

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size, MainFrame.Position, MainFrame.BackgroundColor3, MainFrame.BorderSizePixel, MainFrame.BorderColor3, MainFrame.Visible = UDim2.new(0, 420, 0, 320), UDim2.new(0.5, -210, 0.5, -160), Color3.fromRGB(15, 15, 15), 2, Color3.fromRGB(255, 255, 255), false

OpenBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible OpenBtn.Text = MainFrame.Visible and "CLOSE" or "OPEN" end)

local Header = Instance.new("Frame", MainFrame)
Header.Size, Header.BackgroundColor3, Header.BorderSizePixel = UDim2.new(1, 0, 0, 35), Color3.fromRGB(255, 255, 255), 0
local Title = Instance.new("TextLabel", Header)
Title.Size, Title.Position, Title.BackgroundTransparency, Title.Text, Title.TextColor3, Title.Font, Title.TextSize, Title.TextXAlignment = UDim2.new(1, -10, 1, 0), UDim2.new(0, 10, 0, 0), 1, "GOOD HUB", Color3.fromRGB(0, 0, 0), Enum.Font.Code, 16, Enum.TextXAlignment.Left

local TabHolder = Instance.new("Frame", MainFrame)
TabHolder.Size, TabHolder.Position, TabHolder.BackgroundColor3, TabHolder.BorderSizePixel, TabHolder.BorderColor3 = UDim2.new(0, 100, 1, -45), UDim2.new(0, 5, 0, 40), Color3.fromRGB(25, 25, 25), 1, Color3.fromRGB(60, 60, 60)
Instance.new("UIListLayout", TabHolder).Padding = UDim.new(0, 2)

local ContentHolder = Instance.new("Frame", MainFrame)
ContentHolder.Size, ContentHolder.Position, ContentHolder.BackgroundTransparency = UDim2.new(1, -115, 1, -45), UDim2.new(0, 110, 0, 40), 1

local Pages = {}
local function CreatePage(name)
    local Page = Instance.new("ScrollingFrame", ContentHolder)
    Page.Size, Page.BackgroundTransparency, Page.Visible, Page.ScrollBarThickness, Page.CanvasSize, Page.BorderSizePixel = UDim2.new(1, 0, 1, 0), 1, false, 2, UDim2.new(0, 0, 0, 0), 0
    Instance.new("UIListLayout", Page).Padding, Pages[name] = UDim.new(0, 5), Page
    local TabBtn = Instance.new("TextButton", TabHolder)
    TabBtn.Size, TabBtn.BackgroundColor3, TabBtn.BorderSizePixel, TabBtn.Text, TabBtn.TextColor3, TabBtn.Font, TabBtn.TextSize = UDim2.new(1, 0, 0, 30), Color3.fromRGB(35, 35, 35), 0, name:upper(), Color3.fromRGB(150, 150, 150), Enum.Font.Code, 14
    TabBtn.MouseButton1Click:Connect(function() 
        for _, p in pairs(Pages) do p.Visible = false end Page.Visible = true 
        for _, b in pairs(TabHolder:GetChildren()) do if b:IsA("TextButton") then b.TextColor3, b.BackgroundColor3 = Color3.fromRGB(150, 150, 150), Color3.fromRGB(35, 35, 35) end end 
        TabBtn.TextColor3, TabBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255), Color3.fromRGB(60, 60, 60)
    end)
    return Page
end

local function AddToggle(parent, text, key, callback)
    local Btn = Instance.new("TextButton", parent)
    Btn.Size, Btn.BackgroundColor3, Btn.BorderSizePixel, Btn.BorderColor3, Btn.Text = UDim2.new(1, -5, 0, 30), Color3.fromRGB(30, 30, 30), 1, Color3.fromRGB(60, 60, 60), ""
    local L = Instance.new("TextLabel", Btn)
    L.Size, L.Position, L.BackgroundTransparency, L.Text, L.TextColor3, L.Font, L.TextSize, L.TextXAlignment = UDim2.new(1, -40, 1, 0), UDim2.new(0, 5, 0, 0), 1, text:upper(), Color3.fromRGB(200, 200, 200), Enum.Font.Code, 13, Enum.TextXAlignment.Left
    local S = Instance.new("TextLabel", Btn)
    S.Size, S.Position, S.BackgroundTransparency, S.Text, S.TextColor3, S.Font, S.TextSize = UDim2.new(0, 30, 1, 0), UDim2.new(1, -35, 0, 0), 1, Settings[key] and "[X]" or "[ ]", Settings[key] and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0), Enum.Font.Code, 14
    Btn.MouseButton1Click:Connect(function() Settings[key] = not Settings[key] SaveSettings() S.Text, S.TextColor3 = Settings[key] and "[X]" or "[ ]", Settings[key] and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0) if callback then callback(Settings[key]) end end)
    parent.CanvasSize = UDim2.new(0, 0, 0, parent.UIListLayout.AbsoluteContentSize.Y)
end

local function AddSlider(parent, text, max, key)
    local Frame = Instance.new("Frame", parent)
    Frame.Size, Frame.BackgroundTransparency = UDim2.new(1, -5, 0, 45), 1
    local L = Instance.new("TextLabel", Frame)
    L.Size, L.Text, L.TextColor3, L.Font, L.TextSize, L.BackgroundTransparency, L.TextXAlignment = UDim2.new(1, 0, 0, 20), text:upper() .. ": " .. Settings[key], Color3.fromRGB(200, 200, 200), Enum.Font.Code, 12, 1, Enum.TextXAlignment.Left
    local Bar = Instance.new("TextButton", Frame)
    Bar.Size, Bar.Position, Bar.BackgroundColor3, Bar.BorderSizePixel, Bar.Text = UDim2.new(1, 0, 0, 15), UDim2.new(0, 0, 0, 22), Color3.fromRGB(40, 40, 40), 1, ""
    local Fill = Instance.new("Frame", Bar)
    Fill.Size, Fill.BackgroundColor3, Fill.BorderSizePixel = UDim2.new(Settings[key]/max, 0, 1, 0), Color3.fromRGB(255, 255, 255), 0
    local dragging = false
    local function Update()
        local ratio = math.clamp((UserInputService:GetMouseLocation().X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
        Settings[key] = math.floor(ratio * max) Fill.Size, L.Text = UDim2.new(ratio, 0, 1, 0), text:upper() .. ": " .. Settings[key]
    end
    Bar.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 and dragging then dragging = false SaveSettings() end end)
    RunService.RenderStepped:Connect(function() if dragging then Update() end end)
    parent.CanvasSize = UDim2.new(0, 0, 0, parent.UIListLayout.AbsoluteContentSize.Y)
end

local CombatPage, VisualPage, MovePage, MiscPage = CreatePage("Combat"), CreatePage("Visual"), CreatePage("Move"), CreatePage("Misc")
AddToggle(CombatPage, "Aimbot", "AimbotEnabled")
AddToggle(CombatPage, "Auto Aimbot", "SilentAimEnabled")
AddToggle(CombatPage, "Auto Fire", "AutoFireEnabled")
AddToggle(VisualPage, "ESP", "ESPEnabled")
AddToggle(VisualPage, "Dark Map", "DarkMapEnabled", function(v) ApplyDarkMap(v) end)
AddToggle(VisualPage, "Night Mode", "NightModeEnabled", function(v) ApplyNightMode(v) end)
AddToggle(VisualPage, "4:3 Resolution", "Resolution43Enabled")
AddToggle(VisualPage, "Crosshair", "CrosshairEnabled")
AddToggle(VisualPage, "FOV Circle", "FOVEnabled")
AddToggle(VisualPage, "Screen Color Tint", "ScreenColorEnabled")
AddSlider(VisualPage, "Crosshair Size", 50, "CrosshairSize")
AddSlider(VisualPage, "Crosshair Gap", 30, "CrosshairGap")
AddSlider(VisualPage, "FOV Radius", 800, "FOVRadius")
AddToggle(MovePage, "Stick To Head (Loop)", "StickToHeadEnabled") 
AddToggle(MovePage, "Fly", "FlyEnabled")
AddToggle(MovePage, "Noclip", "NoclipEnabled")
AddToggle(MovePage, "Spin Bot", "SpinEnabled")
AddToggle(MovePage, "Upside Down", "UpsideDownEnabled")
AddSlider(MovePage, "Spin Speed", 3000, "SpinSpeed")
AddSlider(MovePage, "Flight Speed", 1000, "FlySpeed")
AddToggle(MovePage, "Walk Speed", "WalkSpeedEnabled")
AddSlider(MovePage, "Speed Value", 500, "WalkSpeedValue")
AddToggle(MovePage, "Infinite Jump", "InfiniteJumpEnabled")
AddToggle(MiscPage, "FPS Boost", "FPSBoostEnabled", function(v) ApplyFPSBoost(v) end)
AddToggle(MiscPage, "Gamepad Spoof", "ControllerSpoofEnabled", function(v) ApplyControllerSpoof(v) end)
AddToggle(MiscPage, "VR Spoof", "VRSpoofEnabled", function(v) ApplyVRSpoof(v) end)
AddToggle(MiscPage, "Dance", "DanceEnabled")

local DanceIDBox = Instance.new("TextBox", MiscPage)
DanceIDBox.Size, DanceIDBox.BackgroundColor3, DanceIDBox.PlaceholderText, DanceIDBox.Text, DanceIDBox.TextColor3, DanceIDBox.Font, DanceIDBox.TextSize = UDim2.new(1, -5, 0, 30), Color3.fromRGB(30, 30, 30), "Input Dance ID & Enter...", Settings.DanceID, Color3.new(1, 1, 1), Enum.Font.Code, 13
DanceIDBox.FocusLost:Connect(function(enter) if enter then Settings.DanceID = DanceIDBox.Text SaveSettings() danceAnim.AnimationId = "rbxassetid://" .. Settings.DanceID if currentDanceTrack then currentDanceTrack:Stop() currentDanceTrack = nil end loadedDanceChar = nil end end)

local SkinBtn = Instance.new("TextButton", MiscPage)
SkinBtn.Size, SkinBtn.BackgroundColor3, SkinBtn.Text, SkinBtn.Font, SkinBtn.TextColor3, SkinBtn.TextSize = UDim2.new(1, -5, 0, 30), Color3.fromRGB(40, 40, 80), "LOAD GUN SKIN", Enum.Font.Code, Color3.new(1, 1, 1), 13
SkinBtn.MouseButton1Click:Connect(function() task.spawn(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/endoverdosing/Soluna-API/refs/heads/main/skin-changer.lua",true))() end) end)

local BindBtn = Instance.new("TextButton", MiscPage)
BindBtn.Size, BindBtn.BackgroundColor3, BindBtn.Text, BindBtn.Font, BindBtn.TextColor3, BindBtn.TextSize = UDim2.new(1, -5, 0, 30), Color3.fromRGB(45, 45, 45), "AIM KEY: ["..Settings.AimbotKey.."]", Enum.Font.Code, Color3.new(1, 1, 1), 13
BindBtn.MouseButton1Click:Connect(function() Settings.IsBinding = true BindBtn.Text = "... PRESS ANY KEY ..." end)

local HideBtn = Instance.new("TextButton", MiscPage)
HideBtn.Size, HideBtn.BackgroundColor3, HideBtn.Text, HideBtn.Font, HideBtn.TextColor3, HideBtn.TextSize = UDim2.new(1, -5, 0, 30), Color3.fromRGB(45, 45, 45), "HIDE KEY: ["..Settings.HideKey.."]", Enum.Font.Code, Color3.new(1, 1, 1), 13
HideBtn.MouseButton1Click:Connect(function() Settings.IsBindingHide = true HideBtn.Text = "... PRESS ANY KEY ..." end)

Pages["Combat"].Visible = true
local draggingUI, dragStartUI, startPosUI
Header.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingUI, dragStartUI, startPosUI = true, input.Position, MainFrame.Position end end)
UserInputService.InputChanged:Connect(function(input) if draggingUI and input.UserInputType == Enum.UserInputType.MouseMovement then local delta = input.Position - dragStartUI MainFrame.Position = UDim2.new(startPosUI.X.Scale, startPosUI.X.Offset + delta.X, startPosUI.Y.Scale, startPosUI.Y.Offset + delta.Y) end end)
UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingUI = false end end)

local MouseHolding = false
UserInputService.InputBegan:Connect(function(i, g)
    if Settings.IsBinding then local key = (i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode.Name) or i.UserInputType.Name Settings.AimbotKey, Settings.IsBinding = key, false BindBtn.Text = "AIM KEY: ["..key.."]" SaveSettings() return end
    if Settings.IsBindingHide then local key = (i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode.Name) or i.UserInputType.Name Settings.HideKey, Settings.IsBindingHide = key, false HideBtn.Text = "HIDE KEY: ["..key.."]" SaveSettings() return end
    if not g and (i.KeyCode.Name == Settings.HideKey or i.UserInputType.Name == Settings.HideKey) then ScreenGui.Enabled = not ScreenGui.Enabled end
    if i.UserInputType == Enum.UserInputType.MouseButton1 then MouseHolding = true end
    if not g and (i.KeyCode.Name == Settings.AimbotKey or i.UserInputType.Name == Settings.AimbotKey) then Settings.AimbotHolding = true end
end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then MouseHolding = false end if i.KeyCode.Name == Settings.AimbotKey or i.UserInputType.Name == Settings.AimbotKey then Settings.AimbotHolding = false end end)
UserInputService.JumpRequest:Connect(function() if Settings.InfiniteJumpEnabled and LocalPlayer.Character then local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid") if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end end end)

local crosshairLines, crosshairText, FOVCircle = {}, Drawing.new("Text"), Drawing.new("Circle")
for i = 1, 4 do local line = Drawing.new("Line") line.Visible, line.Color, line.Thickness = false, Color3.fromRGB(15, 30, 150), 2.5 table.insert(crosshairLines, line) end
crosshairText.Visible, crosshairText.Color, crosshairText.Text, crosshairText.Size, crosshairText.Center, crosshairText.Outline, crosshairText.Font = false, Color3.fromRGB(15, 30, 150), "goodhub", 16, true, true, 2
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
                    if mag < dist then dist, target = mag, head end
                end
            end
        end
    end
    return target
end

-- 將優先級調到 2000 (最後渲染)，防止跟遊戲相機與畫面互相干擾閃爍
RunService:BindToRenderStep("SOLIX_SYSTEM_LOCK", 2000, function() 
    if (Settings.AimbotEnabled and Settings.AimbotHolding) or (Settings.SilentAimEnabled and MouseHolding) then
        local target = GetClosestTarget()
        if target then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
            local root = GetRoot(LocalPlayer.Character)
            if root then root.CFrame = CFrame.new(root.Position, Vector3.new(target.Position.X, root.Position.Y, target.Position.Z)) end
            if Settings.AutoFireEnabled and tick() - lastAutoFireTime >= Settings.AutoFireDelay then if mouse1click then mouse1click() end lastAutoFireTime = tick() end
        end
    end
    if Settings.Resolution43Enabled then Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, 1, 0, 0, 0, 0.75, 0, 0, 0, 0.75) end
end)

RunService.RenderStepped:Connect(function()
    if Settings.ScreenColorEnabled then TintFrame.BackgroundColor3, TintFrame.Visible = Color3.fromRGB(Settings.ScreenColorR, Settings.ScreenColorG, Settings.ScreenColorB), true else TintFrame.Visible = false end
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
    local root, hum = GetRoot(char), char and char:FindFirstChild("Humanoid")
    if not root or not hum then return end
    if Settings.StickToHeadEnabled then
        local targetPlayer = GetNearestPlayer(150) 
        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Head") then root.CFrame, root.Velocity = targetPlayer.Character.Head.CFrame * CFrame.new(0, 3.2, 0), Vector3.zero end
    end
    if Settings.WalkSpeedEnabled then hum.WalkSpeed = Settings.WalkSpeedValue end
    if Settings.DanceEnabled then
        if loadedDanceChar ~= char then
            if currentDanceTrack then currentDanceTrack:Stop() end
            local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
            currentDanceTrack = animator:LoadAnimation(danceAnim)
            currentDanceTrack.Looped = true currentDanceTrack:Play() loadedDanceChar = char
        elseif currentDanceTrack and not currentDanceTrack.IsPlaying then currentDanceTrack:Play() end
    elseif currentDanceTrack and currentDanceTrack.IsPlaying then currentDanceTrack:Stop() end
    if Settings.FlyEnabled and not Settings.StickToHeadEnabled then
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
    if Settings.SpinEnabled and not (Settings.AimbotHolding or (Settings.SilentAimEnabled and MouseHolding)) then hum.AutoRotate = false root.CFrame *= CFrame.Angles(0, math.rad(Settings.SpinSpeed / 10), 0)
    elseif not Settings.SpinEnabled and not Settings.FlyEnabled then hum.AutoRotate = true end
    if Settings.UpsideDownEnabled then root.CFrame *= CFrame.Angles(0, 0, math.rad(180)) end
end)

RunService.Stepped:Connect(function() if (Settings.NoclipEnabled or Settings.StickToHeadEnabled) and LocalPlayer.Character then for _, p in pairs(LocalPlayer.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end end)
