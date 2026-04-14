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
    ESPEnabled = false,
    IsBinding = false,
    ChatSpamEnabled = false,
    ChatSpamText = "ezz",
    ChatSpamDelay = 3,
    UpsideDownEnabled = false,

}


local function SaveSettings()
    local success, encoded = pcall(function()
        return HttpService:JSONEncode(Settings)
    end)
    if success then
        writefile(FileName, encoded)
    end
end

local function LoadSettings()
    if isfile(FileName) then
        local success, content = pcall(function()
            return readfile(FileName)
        end)
        if success then
            local decoded = HttpService:JSONDecode(content)
            for k, v in pairs(decoded) do
                if Settings[k] ~= nil then
                    Settings[k] = v
                end
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


local function GetRoot(char)
    return char and char:FindFirstChild("HumanoidRootPart")
end


local function CreateESP(player)
    local Box = Drawing.new("Square")
    Box.Visible = false
    Box.Color = Color3.fromRGB(255, 255, 255)
    Box.Thickness = 1.5
    Box.Transparency = 1
    Box.Filled = false

    local HealthBarOutline = Drawing.new("Square")
    HealthBarOutline.Visible = false
    HealthBarOutline.Color = Color3.fromRGB(0, 0, 0)
    HealthBarOutline.Thickness = 1
    HealthBarOutline.Transparency = 1
    HealthBarOutline.Filled = true

    local HealthBar = Drawing.new("Square")
    HealthBar.Visible = false
    HealthBar.Color = Color3.fromRGB(0, 255, 0)
    HealthBar.Thickness = 1
    HealthBar.Transparency = 1
    HealthBar.Filled = true

    local function Update()
        local connection
        connection = RunService.RenderStepped:Connect(function()
            if Settings.ESPEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 and player ~= LocalPlayer then
                local rootPart = player.Character.HumanoidRootPart
                local hum = player.Character.Humanoid
                local position, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
                
                if onScreen then
                    local sizeX = 2200 / position.Z
                    local sizeY = 3200 / position.Z
                    local boxPos = Vector2.new(position.X - sizeX / 2, position.Y - sizeY / 2)
                    
                    Box.Size = Vector2.new(sizeX, sizeY)
                    Box.Position = boxPos
                    Box.Visible = true

                    local barWidth = 3
                    local barHeight = sizeY
                    local healthPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    
                    HealthBarOutline.Size = Vector2.new(barWidth + 2, barHeight + 2)
                    HealthBarOutline.Position = Vector2.new(boxPos.X - barWidth - 5, boxPos.Y - 1)
                    HealthBarOutline.Visible = true
                    
                    HealthBar.Size = Vector2.new(barWidth, barHeight * healthPercent)
                    HealthBar.Position = Vector2.new(boxPos.X - barWidth - 4, boxPos.Y + (barHeight * (1 - healthPercent)))
                    HealthBar.Color = Color3.fromHSV(healthPercent * 0.3, 1, 1)
                    HealthBar.Visible = true
                else
                    Box.Visible = false
                    HealthBarOutline.Visible = false
                    HealthBar.Visible = false
                end
            else
                Box.Visible = false
                HealthBarOutline.Visible = false
                HealthBar.Visible = false
                if not player.Parent then
                    Box:Remove()
                    HealthBarOutline:Remove()
                    HealthBar:Remove()
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

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 280, 0, 520)
MainFrame.Position = UDim2.new(0.5, -140, 0.5, -260)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true

local MainCorner = Instance.new("UICorner", MainFrame)
MainCorner.CornerRadius = UDim.new(0, 10)

local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 50)
Header.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
Header.BorderSizePixel = 0

local HeaderCorner = Instance.new("UICorner", Header)
HeaderCorner.CornerRadius = UDim.new(0, 10)

local HeaderHide = Instance.new("Frame", Header)
HeaderHide.Size = UDim2.new(1, 0, 0, 10)
HeaderHide.Position = UDim2.new(0, 0, 1, -10)
HeaderHide.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
HeaderHide.BorderSizePixel = 0

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
Container.CanvasSize = UDim2.new(0, 0, 0, 600)

local UIListLayout = Instance.new("UIListLayout", Container)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 8)

local SkinBtnFrame = Instance.new("TextButton", Container)
SkinBtnFrame.Size = UDim2.new(1, 0, 0, 40)
SkinBtnFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45) -- 預設顏色
SkinBtnFrame.AutoButtonColor = true
SkinBtnFrame.Text = ""

local SkinCorner = Instance.new("UICorner", SkinBtnFrame)
SkinCorner.CornerRadius = UDim.new(0, 6)

local SkinLabel = Instance.new("TextLabel", SkinBtnFrame)
SkinLabel.Size = UDim2.new(1, 0, 1, 0)
SkinLabel.BackgroundTransparency = 1
SkinLabel.Text = "GUN SKIN"
SkinLabel.TextColor3 = Color3.new(1, 1, 1)
SkinLabel.Font = Enum.Font.GothamBold
SkinLabel.TextSize = 13
SkinLabel.TextXAlignment = Enum.TextXAlignment.Center

local function CreateButton(text, key)
    local BtnFrame = Instance.new("TextButton", Container)
    BtnFrame.Size = UDim2.new(1, 0, 0, 40)
    BtnFrame.BackgroundColor3 = Settings[key] and Color3.fromRGB(50, 180, 100) or Color3.fromRGB(45, 45, 45)
    BtnFrame.AutoButtonColor = false
    BtnFrame.Text = ""
    
    local Corner = Instance.new("UICorner", BtnFrame)
    Corner.CornerRadius = UDim.new(0, 6)
    
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
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Right

    BtnFrame.MouseButton1Click:Connect(function()
        Settings[key] = not Settings[key]
        SaveSettings()
        
        local targetColor = Settings[key] and Color3.fromRGB(50, 180, 100) or Color3.fromRGB(45, 45, 45)
        TweenService:Create(BtnFrame, TweenInfo.new(0.3), {BackgroundColor3 = targetColor}):Play()
        StatusLabel.Text = Settings[key] and "ON" or "OFF"
    end)
end

local function CreateSlider(text, max, settingKey)
    local Frame = Instance.new("Frame", Container)
    Frame.Size = UDim2.new(1, 0, 0, 55)
    Frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    
    local Corner = Instance.new("UICorner", Frame)
    Corner.CornerRadius = UDim.new(0, 6)
    
    local Label = Instance.new("TextLabel", Frame)
    Label.Size = UDim2.new(1, -20, 0, 25)
    Label.Position = UDim2.new(0, 10, 0, 5)
    Label.BackgroundTransparency = 1
    Label.Text = text .. ": " .. tostring(Settings[settingKey])
    Label.TextColor3 = Color3.new(1, 1, 1)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left
    
    local Bar = Instance.new("Frame", Frame)
    Bar.Size = UDim2.new(1, -20, 0, 4)
    Bar.Position = UDim2.new(0, 10, 0, 40)
    Bar.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    
    local Fill = Instance.new("Frame", Bar)
    Fill.Size = UDim2.new(Settings[settingKey]/max, 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
    Fill.BorderSizePixel = 0
    
    local Dot = Instance.new("TextButton", Bar)
    Dot.Size = UDim2.new(0, 12, 0, 12)
    Dot.Position = UDim2.new(Settings[settingKey]/max, -6, 0.5, -6)
    Dot.BackgroundColor3 = Color3.new(1, 1, 1)
    Dot.Text = ""
    Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)
    
    local dragging = false
    local function UpdateSlider()
        local mousePos = UserInputService:GetMouseLocation().X
        local barPos = Bar.AbsolutePosition.X
        local barSize = Bar.AbsoluteSize.X
        local ratio = math.clamp((mousePos - barPos) / barSize, 0, 1)
        
        Fill.Size = UDim2.new(ratio, 0, 1, 0)
        Dot.Position = UDim2.new(ratio, -6, 0.5, -6)
        
        local val = math.floor(ratio * max)
        Settings[settingKey] = val
        Label.Text = text .. ": " .. tostring(val)
    end
    
    Dot.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputEnded:Connect(function(i) 
        if i.UserInputType == Enum.UserInputType.MouseButton1 then 
            if dragging then SaveSettings() end
            dragging = false 
        end 
    end)
    
    RunService.RenderStepped:Connect(function()
        if dragging then UpdateSlider() end
    end)
end


CreateButton("Aimbot", "AimbotEnabled")
CreateButton("Auto Aimbot", "SilentAimEnabled") 
CreateButton("Auto Fire", "AutoFireEnabled")
CreateButton("ESP", "ESPEnabled")
CreateButton("FlY", "FlyEnabled")
CreateButton("Noclip", "NoclipEnabled")
CreateButton("Spin Bot", "SpinEnabled")
CreateButton("Upside Down", "UpsideDownEnabled") 
CreateButton("SKIN", "SkinEnabled")
CreateButton("GOODHUB", "unknown")

CreateSlider("Spin Speed", 3000, "SpinSpeed")
CreateSlider("Flight Speed", 1000, "FlySpeed")

local BindBtn = Instance.new("TextButton", Container)
BindBtn.Size = UDim2.new(1, 0, 0, 40)
BindBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
BindBtn.Text = "Aimbot Key: [ " .. Settings.AimbotKey .. " ]"
BindBtn.TextColor3 = Color3.new(1, 1, 1)
BindBtn.Font = Enum.Font.Gotham
BindBtn.TextSize = 13
local BindCorner = Instance.new("UICorner", BindBtn)
BindCorner.CornerRadius = UDim.new(0, 6)

BindBtn.MouseButton1Click:Connect(function()
    Settings.IsBinding = true
    BindBtn.Text = "... Press Any Key ..."
end)


local draggingUI, dragInputUI, dragStartUI, startPosUI
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingUI = true
        dragStartUI = input.Position
        startPosUI = MainFrame.Position
    end
end)
Header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInputUI = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInputUI and draggingUI then
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
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        MouseHolding = true
    end
    if not g and (i.KeyCode.Name == Settings.AimbotKey or i.UserInputType.Name == Settings.AimbotKey) then
        Settings.AimbotHolding = true
    end
end)
SkinBtnFrame.MouseButton1Click:Connect(function()
    SkinBtnFrame.BackgroundColor3 = Color3.fromRGB(100, 100, 255) 
    
    local success, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/endoverdosing/Soluna-API/refs/heads/main/skin-changer.lua",true))()
    end)
    
    if not success then
        warn("Skin Changer Load Error: " .. tostring(err))
        SkinBtnFrame.BackgroundColor3 = Color3.fromRGB(200, 50, 50) 
    else
        print("Skin Changer Loaded Successfully!")
        task.wait(0.5)
        SkinBtnFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45) 
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        MouseHolding = false
    end
    if i.KeyCode.Name == Settings.AimbotKey or i.UserInputType.Name == Settings.AimbotKey then
        Settings.AimbotHolding = false
    end
end)


local function GetClosestTarget()
    local target = nil
    local dist = math.huge
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
            if root then
                root.CFrame = CFrame.new(root.Position, Vector3.new(target.Position.X, root.Position.Y, target.Position.Z))
            end

            if Settings.AutoFireEnabled and tick() - lastAutoFireTime >= Settings.AutoFireDelay then
                if mouse1click then
                    mouse1click()
                elseif mouse1press and mouse1release then
                    mouse1press()
                    task.wait()
                    mouse1release()
                end
                lastAutoFireTime = tick()
            end
        end
    end
end)


RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    local root = GetRoot(char)
    local hum = char and char:FindFirstChild("Humanoid")
    if not root or not hum then return end

    if Settings.FlyEnabled then
        hum:ChangeState(Enum.HumanoidStateType.Physics)
        root.Velocity = Vector3.new(0, 0, 0)
        if not FlyingBodyVelocity then
            FlyingBodyVelocity = Instance.new("BodyVelocity", root)
            FlyingBodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
            FlyingBodyGyro = Instance.new("BodyGyro", root)
            FlyingBodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        end
        FlyingBodyGyro.CFrame = Camera.CFrame
        local dir = Vector3.new(0,0,0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
        if dir.Magnitude > 0 then FlyingBodyVelocity.Velocity = dir * Settings.FlySpeed else FlyingBodyVelocity.Velocity = Vector3.new(0, 0.1, 0) end
    else
        if FlyingBodyVelocity then FlyingBodyVelocity:Destroy() FlyingBodyVelocity = nil FlyingBodyGyro:Destroy() FlyingBodyGyro = nil hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
    end

    if Settings.ChatSpamEnabled and tick() - lastChatTime >= Settings.ChatSpamDelay then
        local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        if chatEvents and chatEvents:FindFirstChild("SayMessageRequest") then
            chatEvents.SayMessageRequest:FireServer(Settings.ChatSpamText, "All")
        end
        lastChatTime = tick()
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
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end)
