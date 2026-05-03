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
    local BodyParts = {
        {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
        {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
        {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
        {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
        {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
    }

    local BodyPartsR6 = {
        {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
        {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
    }

    local function CreateLines(amt)
        for i = 1, amt do
            local line = Drawing.new("Line")
            line.Visible = false
            line.Color = Color3.fromRGB(255, 255, 255)
            line.Thickness = 1
            line.Transparency = 1
            table.insert(Skeleton, line)
        end
    end
    CreateLines(15) 

    local function Update()
        local connection
        connection = RunService.RenderStepped:Connect(function()
            if Settings.ESPEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 and player ~= LocalPlayer then
                local char = player.Character
                local rootPart = char.HumanoidRootPart
                local hum = char.Humanoid
                local position, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
                
                if onScreen then
                    local sizeX = 2200 / position.Z
                    local sizeY = 3200 / position.Z
                    local boxPos = Vector2.new(position.X - sizeX / 2, position.Y - sizeY / 2)
                    
                    Box.Size = Vector2.new(sizeX, sizeY)
                    Box.Position = boxPos
                    Box.Visible = true

                    local healthPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    HealthBarOutline.Size = Vector2.new(5, sizeY + 2)
                    HealthBarOutline.Position = Vector2.new(boxPos.X - 7, boxPos.Y - 1)
                    HealthBarOutline.Visible = true
                    
                    HealthBar.Size = Vector2.new(3, sizeY * healthPercent)
                    HealthBar.Position = Vector2.new(boxPos.X - 6, boxPos.Y + (sizeY * (1 - healthPercent)))
                    HealthBar.Color = Color3.fromHSV(healthPercent * 0.3, 1, 1)
                    HealthBar.Visible = true

                    local parts = (hum.RigType == Enum.HumanoidRigType.R15) and BodyParts or BodyPartsR6
                    for i, pair in pairs(parts) do
                        local p1 = char:FindFirstChild(pair[1])
                        local p2 = char:FindFirstChild(pair[2])
                        if p1 and p2 and Skeleton[i] then
                            local pos1, vis1 = Camera:WorldToViewportPoint(p1.Position)
                            local pos2, vis2 = Camera:WorldToViewportPoint(p2.Position)
                            if vis1 and vis2 then
                                Skeleton[i].From = Vector2.new(pos1.X, pos1.Y)
                                Skeleton[i].To = Vector2.new(pos2.X, pos2.Y)
                                Skeleton[i].Visible = true
                            else
                                Skeleton[i].Visible = false
                            end
                        end
                    end
                else
                    Box.Visible = false
                    HealthBarOutline.Visible = false
                    HealthBar.Visible = false
                    for _, l in pairs(Skeleton) do l.Visible = false end
                end
            else
                Box.Visible = false
                HealthBarOutline.Visible = false
                HealthBar.Visible = false
                for _, l in pairs(Skeleton) do l.Visible = false end
                
                if not player.Parent then
                    Box:Remove()
                    HealthBarOutline:Remove()
                    HealthBar:Remove()
                    for _, l in pairs(Skeleton) do l:Remove() end
                    connection:Disconnect()
                end
            end
        end)
    end
    coroutine.wrap(Update)()
end

for _, v in pairs(Players:GetPlayers()) do 
    if v ~= LocalPlayer then CreateESP(v) end 
end
Players.PlayerAdded:Connect(CreateESP)

local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
ScreenGui.Name = "YUNUKE_V2_UI"
ScreenGui.ResetOnSpawn = false

-- [全新] 螢幕變色專用的無敵透明圖層
local TintGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
TintGui.Name = "YUNUKE_TINT_GUI"
TintGui.ResetOnSpawn = false
TintGui.IgnoreGuiInset = true -- 無視遊戲的頂部選單，確保覆蓋全畫面
TintGui.DisplayOrder = -1 -- 放在你的作弊選單下面，免得擋到操作

local TintFrame = Instance.new("Frame", TintGui)
TintFrame.Size = UDim2.new(1, 0, 1, 0)
TintFrame.BackgroundTransparency = 0.7 -- 變色透明度 (0是全滿看不到，1是全透)，設 0.7 看起來比較舒服
TintFrame.BorderSizePixel = 0
TintFrame.Visible = false

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 280, 0, 520)
MainFrame.Position = UDim2.new(0.5, -140, 0.5, -260)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 50)
Header.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, 0, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "GOOD HUB"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16

local Container = Instance.new("ScrollingFrame", MainFrame)
Container.Size = UDim2.new(1, -20, 1, -70)
Container.Position = UDim2.new(0, 10, 0, 60)
Container.BackgroundTransparency = 1
Container.ScrollBarThickness = 2
Container.CanvasSize = UDim2.new(0, 0, 0, 1950) 
local UIListLayout = Instance.new("UIListLayout", Container)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 8)

local function CreateButton(text, key)
    local BtnFrame = Instance.new("TextButton", Container)
    BtnFrame.Size = UDim2.new(1, 0, 0, 40)
    BtnFrame.BackgroundColor3 = Settings[key] and Color3.fromRGB(20, 20, 30) or Color3.fromRGB(45, 45, 45)
    BtnFrame.Text = ""
    Instance.new("UICorner", BtnFrame).CornerRadius = UDim.new(0, 6)
    
    local Label = Instance.new("TextLabel", BtnFrame)
    Label.Size = UDim2.new(1, -20, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.new(1, 1, 1)
    Label.Font = Enum.Font.GothamSemibold
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    
    local StatusLabel = Instance.new("TextLabel", BtnFrame)
    StatusLabel.Size = UDim2.new(0, 40, 1, 0)
    StatusLabel.Position = UDim2.new(1, -50, 0, 0)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = Settings[key] and "ON" or "OFF"
    StatusLabel.TextColor3 = Color3.new(1, 1, 1)
    StatusLabel.Font = Enum.Font.GothamBold
    StatusLabel.TextSize = 12

    BtnFrame.MouseButton1Click:Connect(function()
        Settings[key] = not Settings[key]
        SaveSettings()
        TweenService:Create(BtnFrame, TweenInfo.new(0.3), {BackgroundColor3 = Settings[key] and Color3.fromRGB(50, 180, 100) or Color3.fromRGB(45, 45, 45)}):Play()
        StatusLabel.Text = Settings[key] and "ON" or "OFF"
    end)
end

local function CreateSlider(text, max, settingKey)
    local Frame = Instance.new("Frame", Container)
    Frame.Size = UDim2.new(1, 0, 0, 55)
    Frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)
    
    local Label = Instance.new("TextLabel", Frame)
    Label.Size = UDim2.new(1, -20, 0, 25)
    Label.Position = UDim2.new(0, 10, 0, 5)
    Label.BackgroundTransparency = 1
    Label.Text = text .. ": " .. tostring(Settings[settingKey])
    Label.TextColor3 = Color3.new(1, 1, 1)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 12
    
    local Bar = Instance.new("Frame", Frame)
    Bar.Size = UDim2.new(1, -20, 0, 4)
    Bar.Position = UDim2.new(0, 10, 0, 40)
    Bar.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    
    local Fill = Instance.new("Frame", Bar)
    Fill.Size = UDim2.new(Settings[settingKey]/max, 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
    
    local Dot = Instance.new("TextButton", Bar)
    Dot.Size = UDim2.new(0, 12, 0, 12)
    Dot.Position = UDim2.new(Settings[settingKey]/max, -6, 0.5, -6)
    Dot.Text = ""
    Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)
    
    local dragging = false
    Dot.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputEnded:Connect(function(i) 
        if i.UserInputType == Enum.UserInputType.MouseButton1 then 
            dragging = false 
            SaveSettings() 
        end 
    end)
    
    RunService.RenderStepped:Connect(function()
        if dragging then
            local ratio = math.clamp((UserInputService:GetMouseLocation().X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
            Fill.Size = UDim2.new(ratio, 0, 1, 0)
            Dot.Position = UDim2.new(ratio, -6, 0.5, -6)
            Settings[settingKey] = math.floor(ratio * max)
            Label.Text = text .. ": " .. Settings[settingKey]
        end
    end)
end

local SkinBtnFrame = Instance.new("TextButton", Container)
SkinBtnFrame.Size = UDim2.new(1, 0, 0, 40)
SkinBtnFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
SkinBtnFrame.Text = "GUN SKIN"
SkinBtnFrame.TextColor3 = Color3.new(1, 1, 1)
SkinBtnFrame.Font = Enum.Font.GothamBold
SkinBtnFrame.TextSize = 13
Instance.new("UICorner", SkinBtnFrame).CornerRadius = UDim.new(0, 6)

CreateButton("Aimbot", "AimbotEnabled")
CreateButton("Auto Aimbot", "SilentAimEnabled") 
CreateButton("Auto Fire", "AutoFireEnabled")
CreateButton("ESP", "ESPEnabled")
CreateButton("Fly", "FlyEnabled")
CreateButton("Noclip", "NoclipEnabled")
CreateButton("Spin Bot", "SpinEnabled")
CreateButton("Dance", "DanceEnabled")
CreateButton("Upside Down", "UpsideDownEnabled")

CreateButton("Night Mode", "NightModeEnabled")
CreateButton("Crosshair", "CrosshairEnabled")
CreateButton("FOV Circle", "FOVEnabled")
CreateButton("Screen Color Tint", "ScreenColorEnabled")

CreateSlider("Spin Speed", 3000, "SpinSpeed")
CreateSlider("Flight Speed", 1000, "FlySpeed")

CreateSlider("Crosshair Size", 50, "CrosshairSize")
CreateSlider("Crosshair Gap", 30, "CrosshairGap")
CreateSlider("Crosshair Spin Speed", 360, "CrosshairSpinSpeed")
CreateSlider("FOV Radius", 800, "FOVRadius")

CreateSlider("Tint Red (R)", 255, "ScreenColorR")
CreateSlider("Tint Green (G)", 255, "ScreenColorG")
CreateSlider("Tint Blue (B)", 255, "ScreenColorB")

local BindBtn = Instance.new("TextButton", Container)
BindBtn.Size = UDim2.new(1, 0, 0, 40)
BindBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
BindBtn.Text = "Aimbot Key: [ " .. Settings.AimbotKey .. " ]"
BindBtn.TextColor3 = Color3.new(1, 1, 1)
BindBtn.Font = Enum.Font.Gotham
BindBtn.TextSize = 13
Instance.new("UICorner", BindBtn).CornerRadius = UDim.new(0, 6)

BindBtn.MouseButton1Click:Connect(function()
    Settings.IsBinding = true
    Settings.IsBindingHide = false
    BindBtn.Text = "... Press Any Key ..."
end)

local HideBindBtn = Instance.new("TextButton", Container)
HideBindBtn.Size = UDim2.new(1, 0, 0, 40)
HideBindBtn.BackgroundColor3 = Color3.fromRGB(70, 50, 60)
HideBindBtn.Text = "Hide UI Key: [ " .. Settings.HideKey .. " ]"
HideBindBtn.TextColor3 = Color3.new(1, 1, 1)
HideBindBtn.Font = Enum.Font.Gotham
HideBindBtn.TextSize = 13
Instance.new("UICorner", HideBindBtn).CornerRadius = UDim.new(0, 6)

HideBindBtn.MouseButton1Click:Connect(function()
    Settings.IsBindingHide = true
    Settings.IsBinding = false
    HideBindBtn.Text = "... Press Any Key ..."
end)

local draggingUI, dragInputUI, dragStartUI, startPosUI
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingUI = true 
        dragStartUI = input.Position 
        startPosUI = MainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingUI and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStartUI
        MainFrame.Position = UDim2.new(startPosUI.X.Scale, startPosUI.X.Offset + delta.X, startPosUI.Y.Scale, startPosUI.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input) 
    if input.UserInputType == Enum.UserInputType.MouseButton1 then 
        draggingUI = false 
    end 
end)

local MouseHolding = false
UserInputService.InputBegan:Connect(function(i, g)
    if Settings.IsBinding then
        local key = (i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode.Name) or i.UserInputType.Name
        Settings.AimbotKey = key
        BindBtn.Text = "Aimbot Key: [ " .. key .. " ]"
        Settings.IsBinding = false
        SaveSettings()
        return
    end

    if Settings.IsBindingHide then
        local key = (i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode.Name) or i.UserInputType.Name
        Settings.HideKey = key
        HideBindBtn.Text = "Hide UI Key: [ " .. key .. " ]"
        Settings.IsBindingHide = false
        SaveSettings()
        return
    end

    if not g and (i.KeyCode.Name == Settings.HideKey or i.UserInputType.Name == Settings.HideKey) then
        ScreenGui.Enabled = not ScreenGui.Enabled
    end

    if i.UserInputType == Enum.UserInputType.MouseButton1 then MouseHolding = true end
    if not g and (i.KeyCode.Name == Settings.AimbotKey or i.UserInputType.Name == Settings.AimbotKey) then Settings.AimbotHolding = true end
end)

SkinBtnFrame.MouseButton1Click:Connect(function()
    SkinBtnFrame.BackgroundColor3 = Color3.fromRGB(100, 100, 255) 
    local success = pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/endoverdosing/Soluna-API/refs/heads/main/skin-changer.lua",true))() end)
    task.wait(0.5)
    SkinBtnFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45) 
end)

UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then MouseHolding = false end
    if i.KeyCode.Name == Settings.AimbotKey or i.UserInputType.Name == Settings.AimbotKey then Settings.AimbotHolding = false end
end)

local crosshairLines = {}
for i = 1, 4 do
    local line = Drawing.new("Line")
    line.Visible = false
    line.Color = Color3.fromRGB(15, 30, 150) 
    line.Thickness = 2.5 
    line.Transparency = 1
    table.insert(crosshairLines, line)
end

local crosshairText = Drawing.new("Text")
crosshairText.Visible = false
crosshairText.Color = Color3.fromRGB(15, 30, 150)
crosshairText.Text = "goodhub"
crosshairText.Size = 16
crosshairText.Center = true
crosshairText.Outline = true 
crosshairText.Font = 2 
crosshairText.Transparency = 1

local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Thickness = 1.5
FOVCircle.Transparency = 0.8
FOVCircle.NumSides = 100 
FOVCircle.Filled = false

local function GetClosestTarget()
    local target = nil
    local dist = Settings.FOVEnabled and Settings.FOVRadius or math.huge

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            local head = p.Character:FindFirstChild(Settings.AimbotPart)
            if head then
                local pos, os = Camera:WorldToViewportPoint(head.Position)
                if os then
                    local mag = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                    if mag < dist then 
                        dist = mag 
                        target = head 
                    end
                end
            end
        end
    end
    return target
end

RunService:BindToRenderStep("SOLIX_SYSTEM_LOCK", Enum.RenderPriority.Camera.Value + 1, function()
    if (Settings.AimbotEnabled and Settings.AimbotHolding) or (Settings.SilentAimEnabled and MouseHolding) then
        local target = GetClosestTarget()
        if target then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
            local root = GetRoot(LocalPlayer.Character)
            if root then root.CFrame = CFrame.new(root.Position, Vector3.new(target.Position.X, root.Position.Y, target.Position.Z)) end
            if Settings.AutoFireEnabled and tick() - lastAutoFireTime >= Settings.AutoFireDelay then
                if mouse1click then mouse1click() end
                lastAutoFireTime = tick()
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    -- [無敵版] UI 螢幕變色，不受遊戲光影控制
    if Settings.ScreenColorEnabled then
        TintFrame.BackgroundColor3 = Color3.fromRGB(Settings.ScreenColorR, Settings.ScreenColorG, Settings.ScreenColorB)
        TintFrame.Visible = true
    else
        TintFrame.Visible = false
    end

    if Settings.NightModeEnabled then 
        Lighting.ClockTime = 0 
    else 
        Lighting.ClockTime = 14 
    end

    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    if Settings.CrosshairEnabled then
        local theta = math.rad(tick() * Settings.CrosshairSpinSpeed)
        local gap = Settings.CrosshairGap
        local size = Settings.CrosshairSize

        for i = 1, 4 do
            local angle = theta + (math.pi / 2) * (i - 1)
            local dir = Vector2.new(math.cos(angle), math.sin(angle))
            
            crosshairLines[i].From = center + (dir * gap)
            crosshairLines[i].To = center + (dir * (gap + size))
            crosshairLines[i].Visible = true
        end

        crosshairText.Position = Vector2.new(center.X, center.Y + gap + size + 10)
        crosshairText.Visible = true
    else
        for i = 1, 4 do
            crosshairLines[i].Visible = false
        end
        crosshairText.Visible = false
    end

    if Settings.FOVEnabled then
        FOVCircle.Position = center
        FOVCircle.Radius = Settings.FOVRadius
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end

    local char = LocalPlayer.Character 
    local root = GetRoot(char) 
    local hum = char and char:FindFirstChild("Humanoid")
    
    if not root or not hum then return end
    
    if Settings.DanceEnabled then
        if loadedDanceChar ~= char then
            if currentDanceTrack then currentDanceTrack:Stop() end
            local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
            currentDanceTrack = animator:LoadAnimation(danceAnim)
            currentDanceTrack.Looped = true
            currentDanceTrack:Play()
            loadedDanceChar = char
        elseif currentDanceTrack and not currentDanceTrack.IsPlaying then
            currentDanceTrack:Play()
        end
    else
        if currentDanceTrack and currentDanceTrack.IsPlaying then
            currentDanceTrack:Stop()
        end
    end

    if Settings.FlyEnabled then
        hum:ChangeState(Enum.HumanoidStateType.Physics)
        root.Velocity = Vector3.new(0, 0, 0)
        
        local dt = task.wait() 
        local dir = Vector3.new(0, 0, 0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end

        if dir.Magnitude > 0 then
            root.CFrame = root.CFrame + (dir.Unit * Settings.FlySpeed * dt)
        end
    else
        if hum:GetState() == Enum.HumanoidStateType.Physics then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            root.Velocity = Vector3.new(0, 0, 0)
            root.RotVelocity = Vector3.new(0, 0, 0)
        end
    end

    if Settings.SpinEnabled and not (Settings.AimbotHolding or (Settings.SilentAimEnabled and MouseHolding)) then
        hum.AutoRotate = false 
        root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(Settings.SpinSpeed / 10), 0)
    elseif not Settings.SpinEnabled and not Settings.FlyEnabled then 
        hum.AutoRotate = true 
    end
    
    if Settings.UpsideDownEnabled then 
        root.CFrame = root.CFrame * CFrame.Angles(0, 0, math.rad(180)) 
    end
end)

RunService.Stepped:Connect(function()
    if Settings.NoclipEnabled and LocalPlayer.Character then
        for _, p in pairs(LocalPlayer.Character:GetDescendants()) do 
            if p:IsA("BasePart") then 
                p.CanCollide = false 
            end 
        end
    end
end)
