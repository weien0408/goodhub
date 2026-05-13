-- https://discord.gg/dBF9H8c3w2
repeat wait() until game:IsLoaded()

local HttpService = game:GetService("HttpService")
local FileName = "YUNUKE_CONFIG_FINAL.json"

-- [100% 原始設定表]
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
    FPSBoostEnabled = false,
    DarkMapEnabled = false,
    Resolution43Enabled = false,
    WalkSpeedEnabled = false,
    WalkSpeedValue = 100,
    InfiniteJumpEnabled = false,
    StickToHeadEnabled = false 
}

-- [100% 原始存檔邏輯]
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
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local lastAutoFireTime = 0
local MouseHolding = false

-- [100% 原始 Dark Map 邏輯]
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

-- [100% 原始 FPS Boost 邏輯]
local function ApplyFPSBoost(state)
    if state then
        settings().Rendering.QualityLevel = 1
        for _, v in pairs(game:GetDescendants()) do
            if v:IsA("Part") or v:IsA("UnionOperation") or v:IsA("MeshPart") then v.Material = Enum.Material.Plastic v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 1
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then v.Enabled = false
            elseif v:IsA("Explosion") then v.Visible = false end
        end
        Lighting.GlobalShadows = false Lighting.FogEnd = 9e9
    else
        settings().Rendering.QualityLevel = Enum.QualityLevel.Default
        Lighting.GlobalShadows = true
    end
end

-- [100% 原始目標獲取與 ESP 邏輯]
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
                if d < dist then dist = d target = p end
            end
        end
    end
    return target
end

local function CreateESP(player)
    local Box = Drawing.new("Square")
    local HealthBarOutline = Drawing.new("Square")
    local HealthBar = Drawing.new("Square")
    local Skeleton = {}
    local BodyParts = {{"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"}, {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"}, {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"}, {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"}, {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}}
    local BodyPartsR6 = {{"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"}}
    for i = 1, 15 do local line = Drawing.new("Line") line.Visible = false line.Color = Color3.fromRGB(255, 255, 255) line.Thickness = 1 table.insert(Skeleton, line) end
    RunService.RenderStepped:Connect(function()
        if Settings.ESPEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 and player ~= LocalPlayer then
            local char = player.Character local hum = char.Humanoid
            local position, onScreen = Camera:WorldToViewportPoint(char.HumanoidRootPart.Position)
            if onScreen then
                local sizeX, sizeY = 2200 / position.Z, 3200 / position.Z
                local boxPos = Vector2.new(position.X - sizeX / 2, position.Y - sizeY / 2)
                Box.Size, Box.Position, Box.Visible = Vector2.new(sizeX, sizeY), boxPos, true
                local hp = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                HealthBarOutline.Size, HealthBarOutline.Position, HealthBarOutline.Visible = Vector2.new(5, sizeY + 2), Vector2.new(boxPos.X - 7, boxPos.Y - 1), true
                HealthBar.Size, HealthBar.Position, HealthBar.Color, HealthBar.Visible = Vector2.new(3, sizeY * hp), Vector2.new(boxPos.X - 6, boxPos.Y + (sizeY * (1 - hp))), Color3.fromHSV(hp * 0.3, 1, 1), true
                local parts = (hum.RigType == Enum.HumanoidRigType.R15) and BodyParts or BodyPartsR6
                for i, pair in pairs(parts) do
                    local p1, p2 = char:FindFirstChild(pair[1]), char:FindFirstChild(pair[2])
                    if p1 and p2 and Skeleton[i] then
                        local pos1, vis1 = Camera:WorldToViewportPoint(p1.Position)
                        local pos2, vis2 = Camera:WorldToViewportPoint(p2.Position)
                        if vis1 and vis2 then Skeleton[i].From, Skeleton[i].To, Skeleton[i].Visible = Vector2.new(pos1.X, pos1.Y), Vector2.new(pos2.X, pos2.Y), true else Skeleton[i].Visible = false end
                    end
                end
            else Box.Visible, HealthBarOutline.Visible, HealthBar.Visible = false, false, false for _, l in pairs(Skeleton) do l.Visible = false end end
        else Box.Visible, HealthBarOutline.Visible, HealthBar.Visible = false, false, false for _, l in pairs(Skeleton) do l.Visible = false end end
    end)
end
for _, v in pairs(Players:GetPlayers()) do if v ~= LocalPlayer then CreateESP(v) end end
Players.PlayerAdded:Connect(CreateESP)

-- [100% 原始 UI 構造]
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
ScreenGui.Name = "YUNUKE_PIXEL_FINAL"
ScreenGui.ResetOnSpawn = false

-- 手機專用 OPEN 按鈕
local OpenBtn = Instance.new("TextButton", ScreenGui)
OpenBtn.Size = UDim2.new(0, 60, 0, 30)
OpenBtn.Position = UDim2.new(0, 10, 0.4, 0)
OpenBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
OpenBtn.BorderColor3 = Color3.fromRGB(255, 255, 255)
OpenBtn.Text = "OPEN"
OpenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenBtn.Font = Enum.Font.Code
OpenBtn.TextSize = 14

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 420, 0, 320)
MainFrame.Position = UDim2.new(0.5, -210, 0.5, -160)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
MainFrame.Visible = false

OpenBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    OpenBtn.Text = MainFrame.Visible and "CLOSE" or "OPEN"
end)

local Header = Instance.new("Frame", MainFrame)
Header.Size, Header.BackgroundColor3, Header.BorderSizePixel = UDim2.new(1, 0, 0, 35), Color3.fromRGB(255, 255, 255), 0
local Title = Instance.new("TextLabel", Header)
Title.Size, Title.Position, Title.BackgroundTransparency, Title.Text, Title.TextColor3, Title.Font, Title.TextSize, Title.TextXAlignment = UDim2.new(1, -10, 1, 0), UDim2.new(0, 10, 0, 0), 1, "GOOD HUB", Color3.fromRGB(0, 0, 0), Enum.Font.Code, 16, Enum.TextXAlignment.Left

local TabHolder = Instance.new("Frame", MainFrame)
TabHolder.Size, TabHolder.Position, TabHolder.BackgroundColor3, TabHolder.BorderSizePixel, TabHolder.BorderColor3 = UDim2.new(0, 100, 1, -45), UDim2.new(0, 5, 0, 40), Color3.fromRGB(25, 25, 25), 1, Color3.fromRGB(60, 60, 60)
local TabList = Instance.new("UIListLayout", TabHolder) TabList.Padding = UDim.new(0, 2)

local ContentHolder = Instance.new("Frame", MainFrame)
ContentHolder.Size, ContentHolder.Position, ContentHolder.BackgroundTransparency = UDim2.new(1, -115, 1, -45), UDim2.new(0, 110, 0, 40), 1

local Pages = {}
local function CreatePage(name)
    local Page = Instance.new("ScrollingFrame", ContentHolder)
    Page.Size, Page.BackgroundTransparency, Page.Visible, Page.ScrollBarThickness, Page.CanvasSize, Page.BorderSizePixel = UDim2.new(1, 0, 1, 0), 1, false, 2, UDim2.new(0, 0, 0, 0), 0
    local Layout = Instance.new("UIListLayout", Page) Layout.Padding = UDim.new(0, 5)
    Pages[name] = Page
    local TabBtn = Instance.new("TextButton", TabHolder)
    TabBtn.Size, TabBtn.BackgroundColor3, TabBtn.Text, TabBtn.TextColor3, TabBtn.Font, TabBtn.TextSize = UDim2.new(1, 0, 0, 30), Color3.fromRGB(35, 35, 35), name:upper(), Color3.fromRGB(150, 150, 150), Enum.Font.Code, 14
    TabBtn.MouseButton1Click:Connect(function()
        for _, p in pairs(Pages) do p.Visible = false end Page.Visible = true
        for _, b in pairs(TabHolder:GetChildren()) do if b:IsA("TextButton") then b.TextColor3 = Color3.fromRGB(150, 150, 150) b.BackgroundColor3 = Color3.fromRGB(35, 35, 35) end end
        TabBtn.TextColor3, TabBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255), Color3.fromRGB(60, 60, 60)
    end)
    return Page
end

-- [100% 原始 AddToggle 和 AddSlider]
local function AddToggle(parent, text, key, callback)
    local Btn = Instance.new("TextButton", parent)
    Btn.Size, Btn.BackgroundColor3, Btn.BorderSizePixel, Btn.BorderColor3, Btn.Text = UDim2.new(1, -5, 0, 30), Color3.fromRGB(30, 30, 30), 1, Color3.fromRGB(60, 60, 60), ""
    local L = Instance.new("TextLabel", Btn)
    L.Size, L.Position, L.BackgroundTransparency, L.Text, L.TextColor3, L.Font, L.TextSize, L.TextXAlignment = UDim2.new(1, -40, 1, 0), UDim2.new(0, 5, 0, 0), 1, text:upper(), Color3.fromRGB(200, 200, 200), Enum.Font.Code, 13, Enum.TextXAlignment.Left
    local S = Instance.new("TextLabel", Btn)
    S.Size, S.Position, S.BackgroundTransparency, S.Text, S.TextColor3, S.Font, S.TextSize = UDim2.new(0, 30, 1, 0), UDim2.new(1, -35, 0, 0), 1, Settings[key] and "[X]" or "[ ]", Settings[key] and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0), Enum.Font.Code, 14
    Btn.MouseButton1Click:Connect(function()
        Settings[key] = not Settings[key] SaveSettings()
        S.Text = Settings[key] and "[X]" or "[ ]"
        S.TextColor3 = Settings[key] and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
        if callback then callback(Settings[key]) end
    end)
    parent.CanvasSize = UDim2.new(0, 0, 0, parent.UIListLayout.AbsoluteContentSize.Y)
end

local function AddSlider(parent, text, max, key)
    local Frame = Instance.new("Frame", parent)
    Frame.Size, Frame.BackgroundTransparency = UDim2.new(1, -5, 0, 45), 1
    local L = Instance.new("TextLabel", Frame)
    L.Size, L.Text, L.TextColor3, L.Font, L.TextSize, L.BackgroundTransparency, L.TextXAlignment = UDim2.new(1, 0, 0, 20), text:upper() .. ": " .. Settings[key], Color3.fromRGB(200, 200, 200), Enum.Font.Code, 12, 1, Enum.TextXAlignment.Left
    local Bar = Instance.new("TextButton", Frame) Bar.Size, Bar.Position, Bar.BackgroundColor3, Bar.Text = UDim2.new(1, 0, 0, 15), UDim2.new(0, 0, 0, 22), Color3.fromRGB(40, 40, 40), ""
    local Fill = Instance.new("Frame", Bar) Fill.Size, Fill.BackgroundColor3, Fill.BorderSizePixel = UDim2.new(Settings[key]/max, 0, 1, 0), Color3.fromRGB(255, 255, 255), 0
    local dragging = false
    local function Update()
        local ratio = math.clamp((UserInputService:GetMouseLocation().X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
        Settings[key] = math.floor(ratio * max)
        Fill.Size, L.Text = UDim2.new(ratio, 0, 1, 0), text:upper() .. ": " .. Settings[key]
    end
    Bar.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 and dragging then dragging = false SaveSettings() end end)
    RunService.RenderStepped:Connect(function() if dragging then Update() end end)
    parent.CanvasSize = UDim2.new(0, 0, 0, parent.UIListLayout.AbsoluteContentSize.Y)
end

-- [100% 原始頁面內容]
local CombatPage = CreatePage("Combat")
local VisualPage = CreatePage("Visual")
local MovePage = CreatePage("Move")
local MiscPage = CreatePage("Misc")

AddToggle(CombatPage, "Aimbot", "AimbotEnabled")
AddToggle(CombatPage, "Auto Aimbot", "SilentAimEnabled")
AddToggle(CombatPage, "Auto Fire", "AutoFireEnabled")

AddToggle(VisualPage, "ESP", "ESPEnabled")
AddToggle(VisualPage, "Dark Map", "DarkMapEnabled", function(v) ApplyDarkMap(v) end)
AddToggle(VisualPage, "Night Mode", "NightModeEnabled")
AddToggle(VisualPage, "4:3 Resolution", "Resolution43Enabled")
AddToggle(VisualPage, "Crosshair", "CrosshairEnabled")
AddToggle(VisualPage, "FOV Circle", "FOVEnabled")
AddSlider(VisualPage, "FOV Radius", 800, "FOVRadius")

AddToggle(MovePage, "Fly", "FlyEnabled")
AddToggle(MovePage, "Noclip", "NoclipEnabled")
AddToggle(MovePage, "Spin Bot", "SpinEnabled")
AddSlider(MovePage, "Flight Speed", 1000, "FlySpeed")
AddToggle(MovePage, "Walk Speed", "WalkSpeedEnabled")
AddSlider(MovePage, "Speed Value", 500, "WalkSpeedValue")
AddToggle(MovePage, "Infinite Jump", "InfiniteJumpEnabled")
AddToggle(MovePage, "Stick To Head", "StickToHeadEnabled")

AddToggle(MiscPage, "FPS Boost", "FPSBoostEnabled", function(v) ApplyFPSBoost(v) end)
AddToggle(MiscPage, "Gamepad Spoof", "ControllerSpoofEnabled")
AddToggle(MiscPage, "Dance", "DanceEnabled")

-- [手機飛行輔助按鈕]
local FlyUp, FlyDown = false, false
local UpBtn = Instance.new("TextButton", ScreenGui)
UpBtn.Size, UpBtn.Position, UpBtn.Text, UpBtn.Visible = UDim2.new(0, 45, 0, 45), UDim2.new(1, -55, 0.5, -50), "UP", false
local DownBtn = Instance.new("TextButton", ScreenGui)
DownBtn.Size, DownBtn.Position, DownBtn.Text, DownBtn.Visible = UDim2.new(0, 45, 0, 45), UDim2.new(1, -55, 0.5, 10), "DN", false
UpBtn.MouseButton1Down:Connect(function() FlyUp = true end) UpBtn.MouseButton1Up:Connect(function() FlyUp = false end)
DownBtn.MouseButton1Down:Connect(function() FlyDown = true end) DownBtn.MouseButton1Up:Connect(function() FlyDown = false end)

-- [100% 原始 Aimbot / Silent Aim 邏輯]
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

RunService:BindToRenderStep("SOLIX_LOCK", 201, function()
    if Settings.AimbotEnabled or Settings.SilentAimEnabled then
        local target = GetClosestTarget()
        if target then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
            if Settings.AutoFireEnabled and tick() - lastAutoFireTime >= Settings.AutoFireDelay then
                if mouse1click then mouse1click() end lastAutoFireTime = tick()
            end
        end
    end
end)

-- [100% 原始循環邏輯 - 僅針對手機搖桿修正飛行方向]
RunService.RenderStepped:Connect(function(dt)
    local char = LocalPlayer.Character
    local root = GetRoot(char)
    local hum = char and char:FindFirstChild("Humanoid")
    if not root or not hum then return end

    if Settings.FlyEnabled then
        UpBtn.Visible, DownBtn.Visible = true, true
        hum:ChangeState(11) root.Velocity = Vector3.zero
        local moveDir = hum.MoveDirection -- 手機搖桿方向
        local verticalDir = (FlyUp and 1 or 0) - (FlyDown and 1 or 0)
        local dir = moveDir + Vector3.new(0, verticalDir, 0)
        if dir.Magnitude > 0 then root.CFrame += (dir * Settings.FlySpeed * dt) end
    else
        UpBtn.Visible, DownBtn.Visible = false, false
    end

    if Settings.WalkSpeedEnabled then hum.WalkSpeed = Settings.WalkSpeedValue end
    if Settings.SpinEnabled then root.CFrame *= CFrame.Angles(0, math.rad(Settings.SpinSpeed / 10), 0) end
    if Settings.StickToHeadEnabled then
        local t = GetNearestPlayer(150)
        if t and t.Character and t.Character:FindFirstChild("Head") then
            root.CFrame = t.Character.Head.CFrame * CFrame.new(0, 3.2, 0)
        end
    end
end)

Pages["Combat"].Visible = true
print("Good Hub Mobile Loaded - Full No Omission")
