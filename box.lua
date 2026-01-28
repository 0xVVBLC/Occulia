local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local Settings = {
    Enabled = true,
    BoxMode = "Corners", -- "Box" or "Corners"
    CornerSize = 0.2,    -- 0.1 to 0.5
    BoxColor = Color3.fromRGB(0, 255, 0),
    HealthBar = true,
    Flags = true
}

local ESP_Objects = {}

local function createDrawing(class, properties)
    local obj = Drawing.new(class)
    for prop, val in pairs(properties) do
        obj[prop] = val
    end
    return obj
end

local function hideESP(box)
    for _, line in ipairs(box.Lines) do
        line.Visible = false
    end
    box.HealthBar.Visible = false
    box.HealthBarBG.Visible = false
    box.InfoFlags.Visible = false
end

local function createESP(player)
    if player == Players.LocalPlayer then
        return
    end

    local box = {
        Lines = {},
        HealthBarBG = createDrawing("Line", {
            Thickness = 3,
            Color = Color3.fromRGB(0, 0, 0),
            Transparency = 0.5,
            Visible = false
        }),
        HealthBar = createDrawing("Line", {
            Thickness = 1,
            Visible = false
        }),
        InfoFlags = createDrawing("Text", {
            Size = 13,
            Outline = true,
            Color = Color3.fromRGB(255, 255, 255),
            Visible = false
        }),
        Connection = nil
    }

    for i = 1, 8 do
        box.Lines[i] = createDrawing("Line", {
            Thickness = 1.5,
            Color = Settings.BoxColor,
            Visible = false
        })
    end

    box.Connection = RunService.RenderStepped:Connect(function()
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        if not character or not root or not humanoid or humanoid.Health <= 0 or not Settings.Enabled then
            hideESP(box)
            return
        end

        local cf = root.CFrame
        local corners = {
            cf * Vector3.new(-2,  3, 0),
            cf * Vector3.new( 2,  3, 0),
            cf * Vector3.new(-2, -3, 0),
            cf * Vector3.new( 2, -3, 0)
        }

        local minX, minY = math.huge, math.huge
        local maxX, maxY = -math.huge, -math.huge
        local anyVisible = false

        for _, worldPos in ipairs(corners) do
            local screenPos = Camera:WorldToViewportPoint(worldPos)
            if screenPos.Z > 0 then
                anyVisible = true
                minX = math.min(minX, screenPos.X)
                minY = math.min(minY, screenPos.Y)
                maxX = math.max(maxX, screenPos.X)
                maxY = math.max(maxY, screenPos.Y)
            end
        end

        if not anyVisible then
            hideESP(box)
            return
        end

        local width = maxX - minX
        local height = maxY - minY
        local scaledTextSize = math.clamp(height * 0.15, 8, 22)

        if Settings.BoxMode == "Box" then
            box.Lines[1].From, box.Lines[1].To = Vector2.new(minX, minY), Vector2.new(maxX, minY)
            box.Lines[2].From, box.Lines[2].To = Vector2.new(minX, maxY), Vector2.new(maxX, maxY)
            box.Lines[3].From, box.Lines[3].To = Vector2.new(minX, minY), Vector2.new(minX, maxY)
            box.Lines[4].From, box.Lines[4].To = Vector2.new(maxX, minY), Vector2.new(maxX, maxY)

            for i = 1, 4 do
                box.Lines[i].Visible = true
            end
            for i = 5, 8 do
                box.Lines[i].Visible = false
            end

        else -- Corners
            local cLen = width * Settings.CornerSize

            -- Top Left
            box.Lines[1].From, box.Lines[1].To = Vector2.new(minX, minY), Vector2.new(minX + cLen, minY)
            box.Lines[2].From, box.Lines[2].To = Vector2.new(minX, minY), Vector2.new(minX, minY + cLen)

            -- Top Right
            box.Lines[3].From, box.Lines[3].To = Vector2.new(maxX, minY), Vector2.new(maxX - cLen, minY)
            box.Lines[4].From, box.Lines[4].To = Vector2.new(maxX, minY), Vector2.new(maxX, minY + cLen)

            -- Bottom Left
            box.Lines[5].From, box.Lines[5].To = Vector2.new(minX, maxY), Vector2.new(minX + cLen, maxY)
            box.Lines[6].From, box.Lines[6].To = Vector2.new(minX, maxY), Vector2.new(minX, maxY - cLen)

            -- Bottom Right
            box.Lines[7].From, box.Lines[7].To = Vector2.new(maxX, maxY), Vector2.new(maxX - cLen, maxY)
            box.Lines[8].From, box.Lines[8].To = Vector2.new(maxX, maxY), Vector2.new(maxX, maxY - cLen)

            for i = 1, 8 do
                box.Lines[i].Visible = true
            end
        end

    if Settings.HealthBar then
    local healthPct = humanoid.Health / humanoid.MaxHealth

    box.HealthBarBG.From = Vector2.new(minX - 6, minY)
    box.HealthBarBG.To = Vector2.new(minX - 6, maxY)

    box.HealthBar.From = Vector2.new(minX - 6, maxY)
    box.HealthBar.To = Vector2.new(minX - 6, maxY - (height * healthPct))
    box.HealthBar.Color = Color3.fromHSV(healthPct * 0.3, 1, 1)

    box.HealthBar.Visible = true
    box.HealthBarBG.Visible = true
else
    box.HealthBar.Visible = false
    box.HealthBarBG.Visible = false
end

if Settings.Flags then
    local tool = character:FindFirstChildOfClass("Tool")
    local distance = (Camera.CFrame.Position - root.Position).Magnitude

    box.InfoFlags.Size = scaledTextSize
    box.InfoFlags.Position = Vector2.new(
        maxX + (scaledTextSize * 0.4),
        minY
    )

    box.InfoFlags.Text = string.format(
        "%s\nHP: %d\n[%s]\n%dm",
        player.Name,
        math.floor(humanoid.Health),
        tool and tool.Name or "Fists",
        math.floor(distance)
    )

    box.InfoFlags.Visible = true
else
    box.InfoFlags.Visible = false
end

    end)

    ESP_Objects[player] = box

    -- HealthBar
box.HealthBar.Visible = Settings.HealthBar and humanoid.Health > 0
box.HealthBarBG.Visible = Settings.HealthBar and humanoid.Health > 0

-- Flags
box.InfoFlags.Visible = Settings.Flags and humanoid.Health > 0

end

local function removeESP(player)
    local box = ESP_Objects[player]
    if not box then
        return
    end

    if box.Connection then
        box.Connection:Disconnect()
    end

    for _, line in ipairs(box.Lines) do
        line:Remove()
    end

    box.HealthBarBG:Remove()
    box.HealthBar:Remove()
    box.InfoFlags:Remove()

    ESP_Objects[player] = nil
end

Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(removeESP)

for _, player in ipairs(Players:GetPlayers()) do
    createESP(player)
end

return Settings
