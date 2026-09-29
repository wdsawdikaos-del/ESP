local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait() or Players.LocalPlayer
local Camera = workspace.CurrentCamera

type ESPContainer = {
	Box: any, Text: any, HealthBG: any, HealthBar: any, Tracer: any
}

local Cache: { [Player]: ESPContainer } = {}
local State = { Enabled = true, MaxDist = 1000 }

local C3_RED, C3_GREEN, C3_YELLOW, C3_WHITE = Color3.new(1,0,0), Color3.new(0,1,0), Color3.new(1,1,0), Color3.new(1,1,1)
local C3_BG = Color3.fromRGB(40, 40, 40)

local function draw(drawingType: string, properties: { [string]: any }): any
	local obj = Drawing.new(drawingType)
	for key, value in properties do obj[key] = value end
	return obj
end

local function setupESP(player: Player)
	if player == LocalPlayer then return end
	Cache[player] = {
		Box = draw("Square", { Thickness = 1.5, Filled = false, Visible = false }),
		Text = draw("Text", { Size = 13, Center = true, Outline = true, Color = C3_WHITE, Visible = false }),
		HealthBG = draw("Line", { Thickness = 2.5, Color = C3_BG, Visible = false }),
		HealthBar = draw("Line", { Thickness = 2.5, Visible = false }),
		Tracer = draw("Line", { Thickness = 1.2, Visible = false })
	}
end

local function clearESP(player: Player)
	if Cache[player] then
		for _, obj in Cache[player] :: any do obj:Remove() end
		Cache[player] = nil
	end
end

-- Luau 표준 제너럴 반복문 가동
for _, p in Players:GetPlayers() do setupESP(p) end
Players.PlayerAdded:Connect(setupESP)
Players.PlayerRemoving:Connect(clearESP)

RunService.RenderStepped:Connect(function()
	local myChar = LocalPlayer.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not myRoot or not Camera then return end

	local screenCenterBottom = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)

	for player, esp in Cache do
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local hum = char and char:FindFirstChild("Humanoid") :: Humanoid?

		if root and hum and State.Enabled then
			local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
			local dist = (myRoot.Position - root.Position).Magnitude

			if onScreen and dist <= State.MaxDist then
				local isTeam = player.Team == LocalPlayer.Team and player.Team ~= nil
				local col = isTeam and C3_GREEN or C3_RED
				
			
				local boxH = math.clamp(1000 / dist * 3.5, 35, 240)
				local boxW = boxH * 0.65
				local bX, bY, bY2 = pos.X - boxW / 2, pos.Y - boxH / 2, pos.Y + boxH / 2 + 6
				local hpRatio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)

			
				esp.Box.Size, esp.Box.Position, esp.Box.Color, esp.Box.Visible = Vector2.new(boxW, boxH), Vector2.new(bX, bY), col, true
				esp.Text.Text = string.format("%s (@%s)\n[%d Studs]", player.DisplayName, player.Name, math.floor(dist))
				esp.Text.Position, esp.Text.Visible = Vector2.new(pos.X, bY - 35), true
				
				esp.HealthBG.From, esp.HealthBG.To, esp.HealthBG.Visible = Vector2.new(bX, bY2), Vector2.new(pos.X + boxW / 2, bY2), true
				esp.HealthBar.From, esp.HealthBar.To, esp.HealthBar.Color, esp.HealthBar.Visible = Vector2.new(bX, bY2), Vector2.new(bX + boxW * hpRatio, bY2), hpRatio > 0.5 and C3_GREEN or (hpRatio > 0.2 and C3_YELLOW or C3_RED), true
				esp.Tracer.From, esp.Tracer.To, esp.Tracer.Color, esp.Tracer.Visible = screenCenterBottom, Vector2.new(pos.X, pos.Y + boxH / 2), col, true
				continue
			end
		end
		esp.Box.Visible, esp.Text.Visible, esp.HealthBG.Visible, esp.HealthBar.Visible, esp.Tracer.Visible = false, false, false, false, false
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.E then
		State.Enabled = not State.Enabled
	end
end)
