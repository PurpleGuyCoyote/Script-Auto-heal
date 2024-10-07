local player = game.Players.LocalPlayer
local isServer = not player -- Check if this is running on the server
local remoteEventName = "AutoHealEvent"

-- runs when script is executed on the server
if isServer then
    -- Setting up the RemoteEvent
    local remoteEvent = Instance.new("RemoteEvent")
    remoteEvent.Name = remoteEventName
    remoteEvent.Parent = game.ReplicatedStorage

    -- Function to handle healing request from the client
    remoteEvent.OnServerEvent:Connect(function(player, healAmount)
        local character = player.Character
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + healAmount)
            end
        end
    end)

else
    -- Client-Side Logic (runs on the client)
    
    -- Variables
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    local healThreshold = 0.5 -- Heal if health is below 50%
    local healingInterval = 1 -- Time between each heal pulse (in seconds)
    local healingAmount = 5 -- Amount of health restored per pulse
    local healingActive = false
    local remoteEvent = game.ReplicatedStorage:WaitForChild(remoteEventName)

    -- UI/Visual Feedback
    local healUI = Instance.new("ScreenGui")
    local healLabel = Instance.new("TextLabel")
    healUI.Name = "HealFeedback"
    healUI.Parent = player.PlayerGui
    healLabel.Parent = healUI
    healLabel.Size = UDim2.new(0.2, 0, 0.1, 0)
    healLabel.Position = UDim2.new(0.4, 0, 0, 0)
    healLabel.BackgroundTransparency = 0.5
    healLabel.BackgroundColor3 = Color3.new(0, 1, 0)
    healLabel.Text = "Healing Active!"
    healLabel.Visible = false

    -- Sound Effect
    local healSound = Instance.new("Sound", character)
    healSound.SoundId = "rbxassetid://2226293507" -- Heal sound ID
    healSound.Volume = 1

    -- Error Handling for Humanoid
    local function checkHumanoid()
        if not humanoid or not humanoid:IsDescendantOf(workspace) then
            character = player.Character or player.CharacterAdded:Wait()
            humanoid = character:WaitForChild("Humanoid")
        end
    end

    -- Function to trigger healing
    local function startHealing()
        if healingActive then return end
        healingActive = true
        healLabel.Visible = true

        while healingActive and humanoid.Health < humanoid.MaxHealth do
            -- Request healing from the server
            remoteEvent:FireServer(healingAmount)
            healSound:Play()
            wait(healingInterval)
        end

        healingActive = false
        healLabel.Visible = false
    end

    -- Monitor player's health
    humanoid.HealthChanged:Connect(function(health)
        checkHumanoid()

        if health / humanoid.MaxHealth < healThreshold and not healingActive then
            startHealing()
        end
    end)

    -- Stop healing when health reaches max
    humanoid.HealthChanged:Connect(function(health)
        if health >= humanoid.MaxHealth then
            healingActive = false
            healLabel.Visible = false
        end
    end)
end
