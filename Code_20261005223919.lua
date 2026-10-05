--[[
===========================================================
        GB 极致画质 v6.0
        Roblox 内脏与黑火药 · 性能优化版
===========================================================

核心优先级：
① FPS / 性能
② 稳定 60 FPS
③ 画质
④ 简单光影
⑤ 爆炸震动
⑥ UI

特点：
- 20 档画质
- 智能 FPS 调节
- 60 FPS 目标稳定器
- 低开销场景检测
- 简单 SunRays + Bloom
- 平滑爆炸震动
- 防止重复创建 PostEffect
- 炫酷深色霓虹 UI
- 手机触控支持
- 悬浮球可拖动
===========================================================
]]

--==========================================================
-- Services
--==========================================================

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

--==========================================================
-- Config
--==========================================================

local Config = {
	Enabled = true,
	TargetFPS = 60,
	CurrentLevel = 10,
	AutoMode = true,
	ShowFPS = true,
	SceneDetection = true,
	ExplosionFX = true,
	SimpleLightFX = true,
	ShakeIntensity = 3,
	QualityCheckInterval = 2.5,
	SceneCheckInterval = 3,
	LowFPSThreshold = 54,
	HighFPSThreshold = 59,
}

--==========================================================
-- FPS Monitor
--==========================================================

local FPS = {
	Current = 60,
	Average = 60,
	Frames = 0,
	LastUpdate = os.clock(),
	History = {},
}

local function updateFPS()
	FPS.Frames += 1

	local now = os.clock()

	if now - FPS.LastUpdate >= 1 then
		FPS.Current = FPS.Frames
		FPS.Frames = 0
		FPS.LastUpdate = now

		table.insert(FPS.History, FPS.Current)

		if #FPS.History > 6 then
			table.remove(FPS.History, 1)
		end

		local total = 0

		for _, value in ipairs(FPS.History) do
			total += value
		end

		FPS.Average = total / math.max(#FPS.History, 1)
	end
end

--==========================================================
-- 20 Quality Levels
--==========================================================

local QualityLevels = {

	[1] = {
		name = "极限省电",
		shadows = false,
		fog = 250,
		brightness = 0.9,
		atmosphere = false,
		density = 0,
		light = false,
	},

	[2] = {
		name = "极低",
		shadows = false,
		fog = 350,
		brightness = 1,
		atmosphere = false,
		density = 0,
		light = false,
	},

	[3] = {
		name = "很低",
		shadows = false,
		fog = 500,
		brightness = 1.05,
		atmosphere = false,
		density = 0,
		light = false,
	},

	[4] = {
		name = "低",
		shadows = false,
		fog = 700,
		brightness = 1.1,
		atmosphere = false,
		density = 0,
		light = false,
	},

	[5] = {
		name = "中低",
		shadows = true,
		fog = 900,
		brightness = 1.2,
		atmosphere = false,
		density = 0,
		light = true,
	},

	[6] = {
		name = "中",
		shadows = true,
		fog = 1100,
		brightness = 1.3,
		atmosphere = true,
		density = 0.06,
		light = true,
	},

	[7] = {
		name = "中高",
		shadows = true,
		fog = 1300,
		brightness = 1.4,
		atmosphere = true,
		density = 0.08,
		light = true,
	},

	[8] = {
		name = "高",
		shadows = true,
		fog = 1600,
		brightness = 1.5,
		atmosphere = true,
		density = 0.10,
		light = true,
	},

	[9] = {
		name = "很高",
		shadows = true,
		fog = 2000,
		brightness = 1.6,
		atmosphere = true,
		density = 0.12,
		light = true,
	},

	[10] = {
		name = "极致",
		shadows = true,
		fog = 2600,
		brightness = 1.7,
		atmosphere = true,
		density = 0.14,
		light = true,
	},

	[11] = {
		name = "极致+",
		shadows = true,
		fog = 3000,
		brightness = 1.8,
		atmosphere = true,
		density = 0.16,
		light = true,
	},

	[12] = {
		name = "极致++",
		shadows = true,
		fog = 3500,
		brightness = 1.9,
		atmosphere = true,
		density = 0.18,
		light = true,
	},

	[13] = {
		name = "电影级",
		shadows = true,
		fog = 4000,
		brightness = 2,
		atmosphere = true,
		density = 0.20,
		light = true,
	},

	[14] = {
		name = "电影+",
		shadows = true,
		fog = 4500,
		brightness = 2.05,
		atmosphere = true,
		density = 0.22,
		light = true,
	},

	[15] = {
		name = "电影++",
		shadows = true,
		fog = 5000,
		brightness = 2.1,
		atmosphere = true,
		density = 0.24,
		light = true,
	},

	[16] = {
		name = "超清",
		shadows = true,
		fog = 6000,
		brightness = 2.15,
		atmosphere = true,
		density = 0.26,
		light = true,
	},

	[17] = {
		name = "超清+",
		shadows = true,
		fog = 7000,
		brightness = 2.2,
		atmosphere = true,
		density = 0.28,
		light = true,
	},

	[18] = {
		name = "超清++",
		shadows = true,
		fog = 8000,
		brightness = 2.25,
		atmosphere = true,
		density = 0.30,
		light = true,
	},

	[19] = {
		name = "次世代",
		shadows = true,
		fog = 9000,
		brightness = 2.3,
		atmosphere = true,
		density = 0.32,
		light = true,
	},

	[20] = {
		name = "极致幻境",
		shadows = true,
		fog = 9999,
		brightness = 2.4,
		atmosphere = true,
		density = 0.34,
		light = true,
	},
}

--==========================================================
-- Post Effects
--==========================================================

local Effects = {}

local function getEffect(className, name)
	local existing = Lighting:FindFirstChild(name)

	if existing and existing:IsA(className) then
		return existing
	end

	if existing then
		existing:Destroy()
	end

	local effect = Instance.new(className)
	effect.Name = name
	effect.Parent = Lighting

	return effect
end

local function setupEffects()
	Effects.Bloom = getEffect("BloomEffect", "GB_Bloom")
	Effects.Bloom.Intensity = 0.12
	Effects.Bloom.Size = 18
	Effects.Bloom.Threshold = 1

	Effects.Sun = getEffect("SunRaysEffect", "GB_SunRays")
	Effects.Sun.Intensity = 0.05
	Effects.Sun.Spread = 0.35

	Effects.Color = getEffect("ColorCorrectionEffect", "GB_ColorCorrection")
	Effects.Color.Brightness = 0
	Effects.Color.Contrast = 0.05
	Effects.Color.Saturation = 0.05
end

setupEffects()

--==========================================================
-- Atmosphere
--==========================================================

local Atmosphere = Lighting:FindFirstChild("GB_Atmosphere")

if not Atmosphere then
	Atmosphere = Instance.new("Atmosphere")
	Atmosphere.Name = "GB_Atmosphere"
	Atmosphere.Parent = Lighting

	Atmosphere.Offset = 0.1
	Atmosphere.Color = Color3.fromRGB(220,220,220)
	Atmosphere.Decay = Color3.fromRGB(150,150,150)
	Atmosphere.Glare = 0
	Atmosphere.Haze = 0.8
end

--==========================================================
-- Apply Quality
--==========================================================

local function applyQuality(level)

	local q = QualityLevels[level]

	if not q then
		return
	end

	Config.CurrentLevel = level

	Lighting.GlobalShadows = q.shadows

	Lighting.Brightness = q.brightness

	Lighting.FogEnd = q.fog

	if q.shadows then
		Lighting.EnvironmentDiffuseScale = 0.35
		Lighting.EnvironmentSpecularScale = 0.35
	else
		Lighting.EnvironmentDiffuseScale = 0
		Lighting.EnvironmentSpecularScale = 0
	end

	-- Atmosphere
	Atmosphere.Enabled = q.atmosphere

	if q.atmosphere then
		Atmosphere.Density = q.density
	end

	-- 光影
	if q.light and Config.SimpleLightFX then
		Effects.Bloom.Enabled = true
		Effects.Sun.Enabled = true
		Effects.Color.Enabled = true
	else
		Effects.Bloom.Enabled = false
		Effects.Sun.Enabled = false
		Effects.Color.Enabled = false
	end

	-- 根据档位控制强度
	if q.light then
		local factor = math.clamp((level - 5) / 15, 0, 1)

		Effects.Bloom.Intensity = 0.08 + factor * 0.10
		Effects.Sun.Intensity = 0.025 + factor * 0.045
		Effects.Color.Contrast = 0.03 + factor * 0.08
		Effects.Color.Saturation = 0.02 + factor * 0.08
	end
end

--==========================================================
-- Particle Optimization
--==========================================================

local function optimizeParticles()
	local level = Config.CurrentLevel
	local environmentParticles = level >= 8

	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("ParticleEmitter") then
			local name = string.lower(obj.Name)
			if string.find(name, "dust")
				or string.find(name, "smoke")
				or string.find(name, "fog") then
				obj.Enabled = environmentParticles
			end
		elseif obj:IsA("Trail") then
			obj.Enabled = level >= 10
		end
	end
end

--==========================================================
-- Apply Quality Wrapper
--==========================================================

local lastAppliedLevel = -1

local function setQuality(level)
	level = math.clamp(math.floor(level + 0.5), 1, 20)

	if level == lastAppliedLevel then
		return
	end

	lastAppliedLevel = level

	applyQuality(level)

	task.spawn(function()
		optimizeParticles()
	end)
end

--==========================================================
-- Scene Detection
--==========================================================

local nearbyEntities = 0

local function countNearbyEntities()
	local character = LocalPlayer.Character
	if not character then return 0 end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return 0 end

	local position = root.Position
	local count = 0

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local char = player.Character
			if char then
				local hrp = char:FindFirstChild("HumanoidRootPart")
				if hrp then
					if (hrp.Position - position).Magnitude <= 100 then
						count += 1
					end
				end
			end
		end
	end

	return count
end

--==========================================================
-- Smart Quality AI
--==========================================================

task.spawn(function()
	while task.wait(Config.QualityCheckInterval) do
		if not Config.Enabled then continue end
		if not Config.AutoMode then continue end

		if Config.SceneDetection then
			nearbyEntities = countNearbyEntities()
		end

		local level = Config.CurrentLevel
		local fps = FPS.Average

		-- FPS 优先
		if fps < 45 then
			level -= 2
		elseif fps < Config.LowFPSThreshold then
			level -= 1
		elseif fps >= Config.HighFPSThreshold and nearbyEntities <= 3 then
			level += 1
		end

		-- 大量玩家时主动保护 FPS
		if nearbyEntities >= 20 then
			level -= 2
		elseif nearbyEntities >= 10 then
			level -= 1
		end

		level = math.clamp(level, 1, 20)

		if level ~= Config.CurrentLevel then
			setQuality(level)
		end
	end
end)

--==========================================================
-- FPS Counter
--==========================================================

RunService.RenderStepped:Connect(function()
	if Config.Enabled then
		updateFPS()
	end
end)

--==========================================================
-- Explosion Camera Shake
--==========================================================

local shake = {
	Power = 0,
	Time = 0,
}

local function triggerShake(power)
	shake.Power = math.max(shake.Power, power)
	shake.Time = math.max(shake.Time, 0.35)
end

RunService:BindToRenderStep(
	"GB_CameraShake",
	Enum.RenderPriority.Camera.Value + 1,
	function(dt)
		if not Config.ExplosionFX then return end
		if shake.Time <= 0 then return end

		shake.Time -= dt

		local alpha = math.clamp(shake.Time / 0.35, 0, 1)
		local power = shake.Power * alpha

		local x = (math.random() - 0.5) * power
		local y = (math.random() - 0.5) * power
		local z = (math.random() - 0.5) * power * 0.25

		local camera = Workspace.CurrentCamera
		if camera then
			camera.CFrame = camera.CFrame * CFrame.new(x, y, z)
		end

		shake.Power *= math.max(0, 1 - dt * 7)
	end
)

--==========================================================
-- Explosion Detection
--==========================================================

Workspace.DescendantAdded:Connect(function(obj)
	if not Config.ExplosionFX then return end
	if not obj:IsA("Explosion") then return end

	local character = LocalPlayer.Character
	if not character then return end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local distance = (obj.Position - root.Position).Magnitude
	if distance > 200 then return end

	local strength = Config.ShakeIntensity * math.clamp(1 - distance / 200, 0.15, 1)
	triggerShake(strength)
end)

--==========================================================
-- Initial Quality
--==========================================================

setQuality(Config.CurrentLevel)

--==========================================================
-- UI
--==========================================================

if game.CoreGui:FindFirstChild("GBQualityUI") then
	game.CoreGui.GBQualityUI:Destroy()
end

local parentGui = (gethui and gethui()) or game:GetService("CoreGui")

local gui = Instance.new("ScreenGui")
gui.Name = "GBQualityUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999999
gui.Parent = parentGui

--==========================================================
-- UI Colors
--==========================================================

local UI = {
	Background = Color3.fromRGB(8, 9, 16),
	Panel = Color3.fromRGB(13, 15, 25),
	Card = Color3.fromRGB(20, 23, 36),
	Orange = Color3.fromRGB(255, 150, 30),
	Orange2 = Color3.fromRGB(255, 70, 20),
	White = Color3.fromRGB(235, 240, 255),
	Green = Color3.fromRGB(40, 255, 150),
	Red = Color3.fromRGB(255, 70, 80),
	Gray = Color3.fromRGB(120, 130, 150),
}

--==========================================================
-- Floating Button
--==========================================================

local ball = Instance.new("TextButton")
ball.Size = UDim2.fromOffset(64,64)
ball.Position = UDim2.new(0,18,0.5,-32)
ball.BackgroundColor3 = UI.Background
ball.Text = ""
ball.AutoButtonColor = false
ball.BorderSizePixel = 0
ball.Parent = gui

Instance.new("UICorner", ball).CornerRadius = UDim.new(1,0)

local stroke = Instance.new("UIStroke")
stroke.Thickness = 2.5
stroke.Transparency = 0.1
stroke.Color = UI.Orange
stroke.Parent = ball

local icon = Instance.new("TextLabel")
icon.Size = UDim2.fromScale(1,1)
icon.BackgroundTransparency = 1
icon.Text = "GB"
icon.TextColor3 = UI.Orange
icon.Font = Enum.Font.GothamBlack
icon.TextSize = 19
icon.Parent = ball

--==========================================================
-- FPS Display
--==========================================================

local fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.fromOffset(210,34)
fpsLabel.Position = UDim2.fromOffset(18,18)
fpsLabel.BackgroundColor3 = UI.Background
fpsLabel.BackgroundTransparency = 0.12
fpsLabel.Text = "GB • FPS 60"
fpsLabel.TextColor3 = UI.Green
fpsLabel.Font = Enum.Font.GothamBold
fpsLabel.TextSize = 13
fpsLabel.BorderSizePixel = 0
fpsLabel.Parent = gui

Instance.new("UICorner", fpsLabel).CornerRadius = UDim.new(0,10)

local fpsStroke = Instance.new("UIStroke")
fpsStroke.Color = UI.Orange
fpsStroke.Transparency = 0.65
fpsStroke.Parent = fpsLabel

--==========================================================
-- Main Panel
--==========================================================

local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(340,500)
panel.Position = UDim2.new(0.5,-170,0.5,-250)
panel.BackgroundColor3 = UI.Panel
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui

Instance.new("UICorner", panel).CornerRadius = UDim.new(0,18)

local panelStroke = Instance.new("UIStroke")
panelStroke.Thickness = 1.5
panelStroke.Color = UI.Orange
panelStroke.Transparency = 0.35
panelStroke.Parent = panel

--==========================================================
-- Header
--==========================================================

local header = Instance.new("TextLabel")
header.Size = UDim2.new(1,-60,0,50)
header.Position = UDim2.fromOffset(18,5)
header.BackgroundTransparency = 1
header.Text = "GB  极致画质"
header.TextColor3 = UI.White
header.Font = Enum.Font.GothamBlack
header.TextSize = 18
header.TextXAlignment = Enum.TextXAlignment.Left
header.Parent = panel

local sub = Instance.new("TextLabel")
sub.Size = UDim2.new(1,-40,0,22)
sub.Position = UDim2.fromOffset(20,38)
sub.BackgroundTransparency = 1
sub.Text = "PERFORMANCE • LIGHTING • 60 FPS"
sub.TextColor3 = UI.Orange
sub.Font = Enum.Font.GothamBold
sub.TextSize = 9
sub.TextXAlignment = Enum.TextXAlignment.Left
sub.Parent = panel

--==========================================================
-- Close
--==========================================================

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(36,36)
close.Position = UDim2.new(1,-46,0,12)
close.BackgroundColor3 = Color3.fromRGB(45,25,30)
close.Text = "×"
close.TextColor3 = UI.White
close.Font = Enum.Font.GothamBold
close.TextSize = 20
close.BorderSizePixel = 0
close.Parent = panel

Instance.new("UICorner", close).CornerRadius = UDim.new(0,10)

close.Activated:Connect(function()
	panel.Visible = false
end)

--==========================================================
-- Scroll
--==========================================================

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1,-20,1,-70)
scroll.Position = UDim2.fromOffset(10,65)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = UI.Orange
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new(0,0,0,0)
scroll.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0,9)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Parent = scroll

--==========================================================
-- Card
--==========================================================

local function createCard(height)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1,-4,0,height)
	card.BackgroundColor3 = UI.Card
	card.BorderSizePixel = 0
	card.Parent = scroll
	Instance.new("UICorner", card).CornerRadius = UDim.new(0,12)
	return card
end

--==========================================================
-- Toggle
--==========================================================

local function createToggle(textName, getter, setter)
	local card = createCard(48)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1,-100,1,0)
	label.Position = UDim2.fromOffset(14,0)
	label.BackgroundTransparency = 1
	label.Text = textName
	label.TextColor3 = UI.White
	label.Font = Enum.Font.GothamBold
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = card

	local button = Instance.new("TextButton")
	button.Size = UDim2.fromOffset(65,30)
	button.Position = UDim2.new(1,-78,0.5,-15)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.TextSize = 11
	button.Parent = card

	Instance.new("UICorner", button).CornerRadius = UDim.new(0,9)

	local function refresh()
		if getter() then
			button.Text = "ON"
			button.TextColor3 = UI.Green
			button.BackgroundColor3 = Color3.fromRGB(15,55,40)
		else
			button.Text = "OFF"
			button.TextColor3 = UI.Red
			button.BackgroundColor3 = Color3.fromRGB(55,20,25)
		end
	end

	button.Activated:Connect(function()
		setter(not getter())
		refresh()
	end)

	refresh()
	return refresh
end

--==========================================================
-- Toggles
--==========================================================

createToggle("AI 智能调度", function() return Config.AutoMode end, function(v) Config.AutoMode = v end)
createToggle("场景识别", function() return Config.SceneDetection end, function(v) Config.SceneDetection = v end)
createToggle("FPS 监控", function() return Config.ShowFPS end, function(v) Config.ShowFPS = v fpsLabel.Visible = v end)

createToggle("爆炸镜头震动", function() return Config.ExplosionFX end, function(v)
	Config.ExplosionFX = v
end)

createToggle("简单光影", function() return Config.SimpleLightFX end, function(v)
	Config.SimpleLightFX = v
	if v then
		Effects.Bloom.Enabled = true
		Effects.Sun.Enabled = true
		Effects.Color.Enabled = true
	else
		Effects.Bloom.Enabled = false
		Effects.Sun.Enabled = false
		Effects.Color.Enabled = false
	end
end)

--==========================================================
-- Quality Button
--==========================================================

local qualityCard = createCard(70)

local qualityText = Instance.new("TextLabel")
qualityText.Size = UDim2.new(1,-28,0,24)
qualityText.Position = UDim2.fromOffset(14,5)
qualityText.BackgroundTransparency = 1
qualityText.TextColor3 = UI.White
qualityText.Font = Enum.Font.GothamBold
qualityText.TextSize = 12
qualityText.TextXAlignment = Enum.TextXAlignment.Left
qualityText.Parent = qualityCard

local minus = Instance.new("TextButton")
minus.Size = UDim2.fromOffset(42,32)
minus.Position = UDim2.fromOffset(14,31)
minus.Text = "−"
minus.Font = Enum.Font.GothamBold
minus.TextSize = 18
minus.TextColor3 = UI.White
minus.BackgroundColor3 = Color3.fromRGB(35,38,55)
minus.BorderSizePixel = 0
minus.Parent = qualityCard

Instance.new("UICorner", minus).CornerRadius = UDim.new(0,8)

local plus = minus:Clone()
plus.Position = UDim2.new(1,-56,0,31)
plus.Text = "+"
plus.Parent = qualityCard

local function updateQualityText()
	local q = QualityLevels[Config.CurrentLevel]
	qualityText.Text = "画质等级  " .. Config.CurrentLevel .. "  ·  " .. q.name
end

minus.Activated:Connect(function()
	Config.AutoMode = false
	setQuality(Config.CurrentLevel - 1)
	updateQualityText()
end)

plus.Activated:Connect(function()
	Config.AutoMode = false
	setQuality(Config.CurrentLevel + 1)
	updateQualityText()
end)

updateQualityText()

--==========================================================
-- Shake Slider
--==========================================================

local shakeCard = createCard(65)

local shakeText = Instance.new("TextLabel")
shakeText.Size = UDim2.new(1,-28,0,22)
shakeText.Position = UDim2.fromOffset(14,4)
shakeText.BackgroundTransparency = 1
shakeText.TextColor3 = UI.White
shakeText.Font = Enum.Font.GothamBold
shakeText.TextSize = 12
shakeText.TextXAlignment = Enum.TextXAlignment.Left
shakeText.Parent = shakeCard

local slider = Instance.new("TextButton")
slider.Size = UDim2.new(1,-28,0,8)
slider.Position = UDim2.fromOffset(14,43)
slider.BackgroundColor3 = Color3.fromRGB(40,44,60)
slider.Text = ""
slider.BorderSizePixel = 0
slider.Parent = shakeCard

Instance.new("UICorner", slider).CornerRadius = UDim.new(1,0)

local fill = Instance.new("Frame")
fill.Size = UDim2.new(Config.ShakeIntensity / 10, 0, 1, 0)
fill.BackgroundColor3 = UI.Orange
fill.BorderSizePixel = 0
fill.Parent = slider

Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)

slider.Activated:Connect(function(input)
	local mouse = UserInputService:GetMouseLocation()
	local relative = math.clamp((mouse.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)

	Config.ShakeIntensity = math.max(1, math.floor(relative * 10 + 0.5))
	fill.Size = UDim2.new(Config.ShakeIntensity / 10, 0, 1, 0)
end)

--==========================================================
-- FPS UI updater
--==========================================================

task.spawn(function()
	while gui.Parent do
		if Config.ShowFPS then
			local fps = math.floor(FPS.Average + 0.5)
			local q = QualityLevels[Config.CurrentLevel]

			fpsLabel.Text = string.format("GB  •  FPS %d  •  %s", fps, q.name)

			if fps >= 58 then
				fpsLabel.TextColor3 = UI.Green
			elseif fps >= 50 then
				fpsLabel.TextColor3 = UI.Orange
			else
				fpsLabel.TextColor3 = UI.Red
			end
		end

		updateQualityText()
		task.wait(0.25)
	end
end)

--==========================================================
-- Floating Button Toggle
--==========================================================

ball.Activated:Connect(function()
	panel.Visible = not panel.Visible
end)

--==========================================================
-- Dragging
--==========================================================

local function makeDraggable(object, handle)
	local dragging = false
	local startPosition
	local startFrame

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then

			dragging = true
			startPosition = input.Position
			startFrame = object.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		local delta = input.Position - startPosition
		object.Position = UDim2.new(
			startFrame.X.Scale,
			startFrame.X.Offset + delta.X,
			startFrame.Y.Scale,
			startFrame.Y.Offset + delta.Y
		)
	end)
end

makeDraggable(ball, ball)
makeDraggable(panel, header)

--==========================================================
-- Open Animation
--==========================================================

local originalSize = panel.Size

ball.MouseButton1Click:Connect(function()
	if panel.Visible then return end

	panel.Size = UDim2.fromOffset(300,440)
	panel.Visible = true

	TweenService:Create(
		panel,
		TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = originalSize }
	):Play()
end)

--==========================================================
-- Startup
--==========================================================

print("[GB 极致画质 v6.0] 已启动")
print("[GB] FPS 优先模式 | 目标 60 FPS")
print("[GB] 画质等级:", Config.CurrentLevel)
print("[GB] 光影:", Config.SimpleLightFX and "ON" or "OFF")
