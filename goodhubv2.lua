repeat wait() until game:IsLoaded()

-- [[ 裝置偵測 ]]
local UIS = game:GetService("UserInputService")
local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

-- [[ Services ]]
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- [[ 設定 ]]
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

    ChatSpamEnabled = false,
    ChatSpamText = "ezz",
    ChatSpamDelay = 3,

    UpsideDownEnabled = false,
}

-- [[ 儲存 ]]
pcall(function()
    if isfile(FileName) then
        local data = HttpService:JSONDecode(readfile(FileName))
        for k,v in pairs(data) do
            if Settings[k] ~= nil then
                Settings[k] = v
            end
        end
    end
end)

local function Save()
    writefile(FileName, HttpService:JSONEncode(Settings))
end

-- [[ 工具 ]]
local function GetRoot(c)
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function IsVisible(part)
    local char = LocalPlayer.Character
    if not char then return false end

    local ray = RaycastParams.new()
    ray.FilterType = Enum.RaycastFilterType.Exclude
    ray.FilterDescendantsInstances = {char, Camera}

    local result = workspace:Raycast(
        Camera.CFrame.Position,
        part.Position - Camera.CFrame.Position,
        ray
    )

    return not result or result.Instance:IsDescendantOf(part.Parent)
end

-- [[ 目標搜尋（完全照你原版） ]]
local function GetClosestTarget()
    local target, dist = nil, math.huge

    for _,p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            
            local part = p.Character:FindFirstChild(Settings.AimbotPart)
            if part then
                local pos, visible = Camera:WorldToViewportPoint(part.Position)
                if visible then
                    local mag = (Vector2.new(pos.X,pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
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

-- [[ 手機 LOCK ]]
if isMobile then
    local gui = Instance.new("ScreenGui", game.CoreGui)

    local lock = Instance.new("TextButton", gui)
    lock.Size = UDim2.new(0,60,0,60)
    lock.Position = UDim2.new(0.8,0,0.5,0)
    lock.Text = "LOCK"

    lock.InputBegan:Connect(function()
        Settings.AimbotHolding = true
    end)

    lock.InputEnded:Connect(function()
        Settings.AimbotHolding = false
    end)
end

-- [[ PC 控制（還原） ]]
local MouseHolding = false

UIS.InputBegan:Connect(function(i,g)
    if g then return end

    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        MouseHolding = true
    end

    if i.KeyCode.Name == Settings.AimbotKey then
        Settings.AimbotHolding = true
    end
end)

UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        MouseHolding = false
    end

    if i.KeyCode.Name == Settings.AimbotKey then
        Settings.AimbotHolding = false
    end
end)

-- [[ 主鎖定（🔥已修復） ]]
local lastShot = 0

RunService:BindToRenderStep("AIMBOT_V4",201,function()

    local target = GetClosestTarget()
    if not target then return end

    local shouldAim =
        (Settings.AimbotEnabled and Settings.AimbotHolding)
        or (Settings.SilentAimEnabled and MouseHolding)

    if shouldAim then

        -- 🔥 相機鎖定（你原本的）
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)

        -- 🔥 身體跟隨（你原本的）
        local root = GetRoot(LocalPlayer.Character)
        if root then
            root.CFrame = CFrame.new(
                root.Position,
                Vector3.new(target.Position.X, root.Position.Y, target.Position.Z)
            )
        end

        -- 🔥 AutoFire（完全還原）
        if Settings.AutoFireEnabled and tick() - lastShot >= Settings.AutoFireDelay then
            if mouse1click then
                mouse1click()
            end
            lastShot = tick()
        end
    end
end)

-- [[ 其他功能（完整保留） ]]
RunService.RenderStepped:Connect(function(dt)

    local char = LocalPlayer.Character
    local root = GetRoot(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    if not root or not hum then return end

    -- Fly
    if Settings.FlyEnabled then
        hum:ChangeState(Enum.HumanoidStateType.Physics)
        root.Velocity = Vector3.zero

        local dir = hum.MoveDirection
        if dir.Magnitude > 0 then
            root.CFrame += dir * Settings.FlySpeed * dt
        end
    end

    -- Spin
    if Settings.SpinEnabled and not Settings.AimbotHolding then
        root.CFrame *= CFrame.Angles(0, math.rad(Settings.SpinSpeed * dt), 0)
    end

    -- UpsideDown
    if Settings.UpsideDownEnabled then
        root.CFrame *= CFrame.Angles(0,0,math.rad(180))
    end

    -- ChatSpam
    if Settings.ChatSpamEnabled then
        local ev = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        local say = ev and ev:FindFirstChild("SayMessageRequest")
        if say then
            say:FireServer(Settings.ChatSpamText,"All")
        end
    end
end)

-- Noclip
RunService.Stepped:Connect(function()
    if Settings.NoclipEnabled and LocalPlayer.Character then
        for _,v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
            end
        end
    end
end)

print("✅ V4 LOADED (AIMBOT FIXED)")
