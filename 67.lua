local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Modules = ReplicatedStorage:WaitForChild("Modules")

local LastUtilityRaycast
local LastGameplayRaycast

-- Utility
do
    local ok, Utility = pcall(function()
        return require(Modules:WaitForChild("Utility"))
    end)

    if ok
        and type(Utility) == "table"
        and type(Utility.Raycast) == "function"
    then
        local OldRaycast = Utility.Raycast

        Utility.Raycast = function(...)
            local args = table.pack(...)

            if checkcaller then
                pcall(checkcaller)
            end

            local result = OldRaycast(
                table.unpack(args, 1, args.n)
            )

            LastUtilityRaycast = result

            return result
        end
    end
end

-- GameplayUtility
do
    local ok, GameplayUtility = pcall(function()
        return require(
            Modules:WaitForChild("GameplayUtility")
        )
    end)

    if ok
        and type(GameplayUtility) == "table"
        and type(GameplayUtility.Raycast) == "function"
    then
        local OldRaycast = GameplayUtility.Raycast

        GameplayUtility.Raycast = function(...)
            local args = table.pack(...)

            if checkcaller then
                pcall(checkcaller)
            end

            local result = OldRaycast(
                table.unpack(args, 1, args.n)
            )

            LastGameplayRaycast = result

            return result
        end
    end
end

return {
    TargetPart = "Head",
    MaxDistance = 5000,
    TeamCheck = true,
    HitChance = 100,
    Enabled = true,
    WallCheck = true,
}
