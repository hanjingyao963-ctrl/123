-- ================= GB AI 画质 v1.0 (iPhone 12 + Delta) =================
-- 智能调度 10 档画质 | 场景识别 | 锁 50 帧 | 锐化增强
-- ======================================================================

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

-- ============ 配置 ============
local Config = {
    Enabled = true,
    TargetFPS = 50,
    CurrentLevel = 5,
    AutoMode = true,
    ShowFPS = true,
    SceneDetection = true,
}

-- ============ FPS 统计 ============
local frameCount = 0
local lastTime = tick()
local currentFPS = 50
local fpsHistory = {}

-- ============ 10 档画质预设 ============
local QualityLevels = {
    [1]  = { name = "极限省电",  renderDist = 150,  shadows = false, particles = false, postFX = 0, fogEnd = 300,  brightness = 1.0, sharpness = 0.5, textureQuality = 0 },
    [2]  = { name = "极低",      renderDist = 250,  shadows = false, particles = false, postFX = 0, fogEnd = 400,  brightness = 1.0, sharpness = 0.6, textureQuality = 0 },
    [3]  = { name = "很低",      renderDist = 400,  shadows = false, particles = true,  postFX = 0, fogEnd = 500,  brightness = 1.2, sharpness = 0.7, textureQuality = 1 },
    [4]  = { name = "低",        renderDist = 600,  shadows = true,  particles = true,  postFX = 1, fogEnd = 700,  brightness = 1.3, sharpness = 0.8, textureQuality = 1 },
    [5]  = { name = "中低",      renderDist = 800,  shadows = true,  particles = true,  postFX = 1, fogEnd = 900,  brightness = 1.4, sharpness = 0.9, textureQuality = 2 },
    [6]  = { name = "中",        renderDist = 1000, shadows = true,  particles = true,  postFX = 2, fogEnd = 1100, brightness = 1.5, sharpness = 1.0, textureQuality = 2 },
    [7]  = { name = "中高",      renderDist = 1200, shadows = true,  particles = true,  postFX = 2, fogEnd = 1300, brightness = 1.6, sharpness = 1.1, textureQuality = 3 },
    [8]  = { name = "高",        renderDist = 1500, shadows = true,  particles = true,  postFX = 3, fogEnd = 1600, brightness = 1.7, sharpness = 1.2, textureQuality = 3 },
    [9]  = { name = "很高",      renderDist = 1800, shadows = true,  particles = true,  postFX = 3, fogEnd = 2000, brightness = 1.8, sharpness = 1.4, textureQuality = 4 },
    [10] = { name = "极致",      renderDist = 2500, shadows = true,  particles = true,  postFX = 4, fogEnd = 3000, brightness = 2.0, sharpness = 1.5, textureQuality = 4 },
}

-- ============ 应用画质等级 ============
local function applyQuality(level)
    local q = QualityLevels[level]
    if not q then return end
    Config.CurrentLevel = level

    Lighting.GlobalShadows = q.shadows
    Lighting.Brightness = q.brightness
    Lighting.FogEnd = q.fogEnd
    Lighting.EnvironmentDiffuseScale = q.shadows and 0.5 or 0
    Lighting.EnvironmentSpecularScale = q.shadows and 0.5 or 0

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.CastShadow = q.shadows
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") then
            obj.Enabled = q.particles
        end
    end

    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("PostEffect") then
            obj:Destroy()
        end
    end

    local colorCorrection = Instance.new("ColorCorrectionEffect")
    colorCorrection.Brightness = 0.02 * q.sharpness
    colorCorrection.Contrast = 0.15 * q.sharpness
    colorCorrection.Saturation = 0.05 * q.sharpness
    colorCorrection.Parent = Lighting

    if q.postFX >= 1 then
        local bloom = Instance.new("BloomEffect")
        bloom.Intensity = 0.2 * q.postFX
        bloom.Size = 16 + q.postFX * 4
        bloom.Parent = Lighting
    end

    if q.postFX >= 2 then
        local sunRays = Instance.new("SunRaysEffect")
        sunRays.Intensity = 0.05 * q.postFX
        sunRays.Spread = 0.5
        sunRays.Parent = Lighting
    end

    if q.postFX >= 3 then
        local blur = Instance.new("BlurEffect")
        blur.Size = 1
        blur.Parent = Lighting
    end

    if q.postFX >= 4 then
        local depthOfField = Instance.new("DepthOfFieldEffect")
        depthOfField.FarIntensity = 0.1
        depthOfField.FocusDistance = 50
        depthOfField.InFocusRadius = 100
        depthOfField.NearIntensity = 0.1
        depthOfField.Parent = Lighting
    end
end

-- ============ 场景识别 ============
local function countNearbyEntities()
    local char = game.Players.LocalPlayer.Character
    if not char then return 0 end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return 0 end

    local myPos = hrp.Position
    local count = 0

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
            local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("UpperTorso") or obj:FindFirstChild("Torso")
            if root and (root.Position - myPos).Magnitude <= 100 then
                count = count + 1
            end
        end
    end

    return count
end

-- ============ 锁帧 ============
local targetInterval = 1 / Config.TargetFPS
local lastFrameTime = tick()

RunService.RenderStepped:Connect(function()
    local now = tick()
    local actualDelta = now - lastFrameTime
    lastFrameTime = now

    if Config.Enabled then
        local waitTime = targetInterval - actualDelta
        if waitTime > 0.001 then
            task.wait(waitTime)
        end
    end

    frameCount = frameCount + 1
    if now - lastTime >= 1 then
        currentFPS = frameCount
        frameCount = 0
        lastTime = now

        table.insert(fpsHistory, currentFPS)
        if #fpsHistory > 5 then
            table.remove(fpsHistory, 1)
        end
    end
end)

-- ============ AI 智能调度 ============
task.spawn(function()
    local lastAdjustTime = 0
    local entityCount = 0

    while true do
        task.wait(1)

        if not Config.Enabled or not Config.AutoMode then
            continue
        end

        if Config.SceneDetection then
            if tick() - lastAdjustTime >= 3 then
                entityCount = countNearbyEntities()
                lastAdjustTime = tick()
            end
        end

        local avgFPS = 0
        for _, f in ipairs(fpsHistory) do
            avgFPS = avgFPS + f
        end
        avgFPS = avgFPS / math.max(#fpsHistory, 1)

        local target = Config.TargetFPS
        local newLevel = Config.CurrentLevel

        local sceneOffset = 0
        if entityCount >= 20 then
            sceneOffset = -3
        elseif entityCount >= 10 then
            sceneOffset = -2
        elseif entityCount >= 5 then
            sceneOffset = -1
        elseif entityCount <= 2 then
            sceneOffset = 1
        end

        if avgFPS < target - 8 then
            newLevel = Config.CurrentLevel - 2
        elseif avgFPS < target - 3 then
            newLevel = Config.CurrentLevel - 1
        elseif avgFPS > target + 5 then
            newLevel = Config.CurrentLevel + 1
        elseif avgFPS > target + 10 then
            newLevel = Config.CurrentLevel + 2
        end

        newLevel = newLevel + sceneOffset
        newLevel = math.clamp(newLevel, 1, 10)

        if newLevel ~= Config.CurrentLevel then
            applyQuality(newLevel)
            if updateLevelUI then updateLevelUI(newLevel) end
        end
    end
end)

-- ============ 初始化 ============
applyQuality(5)

-- ============ UI ============
if game.CoreGui:FindFirstChild("GBAIQualityUI") then
    game.CoreGui.GBAIQualityUI:Destroy()
end

local parentGui = (gethui and gethui()) or game.CoreGui
local gui = Instance.new("ScreenGui")
gui.Name = "GBAIQualityUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 2147483647
gui.Parent = parentGui

local QUICK_BOUNCE = TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local BOUNCE_OUT = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

-- 悬浮球
local ball = Instance.new("TextButton")
ball.Size = UDim2.new(0, 62, 0, 62)
ball.Position = UDim2.new(0, 16, 0, 360)
ball.BackgroundColor3 = Color3.fromRGB(10, 8, 16)
ball.Text = ""
ball.AutoButtonColor = false
ball.BorderSizePixel = 0
ball.Parent = gui
Instance.new("UICorner", ball).CornerRadius = UDim.new(1, 0)

local ballStroke = Instance.new("UIStroke")
ballStroke.Thickness = 2
ballStroke.Transparency = 0.15
ballStroke.Parent = ball
local ballGrad = Instance.new("UIGradient")
ballGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 200, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 0, 255)),
})
ballGrad.Parent = ballStroke

local ballIcon = Instance.new("TextLabel")
ballIcon.Size = UDim2.new(1, 0, 1, 0)
ballIcon.BackgroundTransparency = 1
ballIcon.Text = "AI"
ballIcon.TextColor3 = Color3.fromRGB(0, 200, 255)
ballIcon.Font = Enum.Font.GothamBlack
ballIcon.TextSize = 20
ballIcon.Parent = ball

-- FPS 显示
local fpsDisplay = Instance.new("TextLabel")
fpsDisplay.Size = UDim2.new(0, 150, 0, 32)
fpsDisplay.Position = UDim2.new(0, 16, 0, 16)
fpsDisplay.BackgroundColor3 = Color3.fromRGB(10, 8, 16)
fpsDisplay.BackgroundTransparency = 0.3
fpsDisplay.BorderSizePixel = 0
fpsDisplay.Text = "FPS: 0 | 档: 5"
fpsDisplay.TextColor3 = Color3.fromRGB(0, 255, 130)
fpsDisplay.Font = Enum.Font.GothamBold
fpsDisplay.TextSize = 13
fpsDisplay.ZIndex = 5
fpsDisplay.Parent = gui
Instance.new("UICorner", fpsDisplay).CornerRadius = UDim.new(0, 8)

local fpsStroke = Instance.new("UIStroke")
fpsStroke.Thickness = 1
fpsStroke.Transparency = 0.4
fpsStroke.Parent = fpsDisplay
local fpsGrad = Instance.new("UIGradient")
fpsGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 200, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 0, 255)),
})
fpsGrad.Parent = fpsStroke

-- 主面板
local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 290, 0, 380)
panel.Position = UDim2.new(0.5, -145, 0.5, -190)
panel.BackgroundColor3 = Color3.fromRGB(10, 8, 16)
panel.BackgroundTransparency = 0.05
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)

local panelStroke = Instance.new("UIStroke")
panelStroke.Thickness = 1.5
panelStroke.Transparency = 0.3
panelStroke.Parent = panel
local psGrad = Instance.new("UIGradient")
psGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 200, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 0, 255)),
})
psGrad.Parent = panelStroke

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 42)
titleBar.BackgroundTransparency = 1
titleBar.ZIndex = 2
titleBar.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -50, 1, 0)
title.Position = UDim2.new(0, 14, 0, 0)
title.BackgroundTransparency = 1
title.Text = "AI 画质 (50帧)"
title.TextColor3 = Color3.fromRGB(0, 200, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 38, 0, 38)
closeBtn.Position = UDim2.new(1, -46, 0.5, -19)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
closeBtn.Text = "x"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 22
closeBtn.AutoButtonColor = false
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

-- AI 自动模式开关
local autoRow = Instance.new("TextButton")
autoRow.Size = UDim2.new(1, -20, 0, 46)
autoRow.Position = UDim2.new(0, 10, 0, 52)
autoRow.BackgroundColor3 = Color3.fromRGB(20, 30, 50)
autoRow.Text = ""
autoRow.AutoButtonColor = false
autoRow.BorderSizePixel = 0
autoRow.Parent = panel
Instance.new("UICorner", autoRow).CornerRadius = UDim.new(0, 10)

local arLabel = Instance.new("TextLabel")
arLabel.Size = UDim2.new(1, -100, 1, 0)
arLabel.Position = UDim2.new(0, 14, 0, 0)
arLabel.BackgroundTransparency = 1
arLabel.Text = "AI 智能调度"
arLabel.TextColor3 = Color3.fromRGB(220, 230, 255)
arLabel.Font = Enum.Font.GothamBold
arLabel.TextSize = 14
arLabel.TextXAlignment = Enum.TextXAlignment.Left
arLabel.Parent = autoRow

local arState = Instance.new("TextLabel")
arState.Size = UDim2.new(0, 40, 1, 0)
arState.Position = UDim2.new(1, -50, 0, 0)
arState.BackgroundTransparency = 1
arState.Text = "ON"
arState.TextColor3 = Color3.fromRGB(0, 255, 130)
arState.Font = Enum.Font.GothamBold
arState.TextSize = 14
arState.TextXAlignment = Enum.TextXAlignment.Right
arState.Parent = autoRow

-- 手动档位滑块
local levelRow = Instance.new("Frame")
levelRow.Size = UDim2.new(1, -20, 0, 76)
levelRow.Position = UDim2.new(0, 10, 0, 106)
levelRow.BackgroundColor3 = Color3.fromRGB(20, 30, 50)
levelRow.BorderSizePixel = 0
levelRow.Parent = panel
Instance.new("UICorner", levelRow).CornerRadius = UDim.new(0, 10)

local levelLabel = Instance.new("TextLabel")
levelLabel.Size = UDim2.new(1, -24, 0, 24)
levelLabel.Position = UDim2.new(0, 14, 0, 6)
levelLabel.BackgroundTransparency = 1
levelLabel.Text = "画质等级: 5 (中低)"
levelLabel.TextColor3 = Color3.fromRGB(0, 220, 255)
levelLabel.Font = Enum.Font.GothamBold
levelLabel.TextSize = 13
levelLabel.TextXAlignment = Enum.TextXAlignment.Left
levelLabel.Parent = levelRow

local trackBg = Instance.new("Frame")
trackBg.Size = UDim2.new(1, -28, 0, 8)
trackBg.Position = UDim2.new(0, 14, 1, -28)
trackBg.BackgroundColor3 = Color3.fromRGB(40, 50, 70)
trackBg.BorderSizePixel = 0
trackBg.Parent = levelRow
Instance.new("UICorner", trackBg).CornerRadius = UDim.new(1, 0)

local fill = Instance.new("Frame")
fill.Size = UDim2.new((Config.CurrentLevel - 1) / 9, 0, 1, 0)
fill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
fill.BorderSizePixel = 0
fill.Parent = trackBg
Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

local knob = Instance.new("Frame")
knob.Size = UDim2.new(0, 20, 0, 20)
knob.Position = UDim2.new((Config.CurrentLevel - 1) / 9, -10, 0.5, -10)
knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
knob.BorderSizePixel = 0
knob.ZIndex = 2
knob.Parent = trackBg
Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

-- 更新等级 UI
updateLevelUI = function(level)
    local q = QualityLevels[level]
    levelLabel.Text = "画质等级: " .. level .. " (" .. q.name .. ")"
    local relX = (level - 1) / 9
    fill.Size = UDim2.new(relX, 0, 1, 0)
    knob.Position = UDim2.new(relX, -10, 0.5, -10)
end

-- 场景识别开关
local sceneRow = Instance.new("TextButton")
sceneRow.Size = UDim2.new(1, -20, 0, 46)
sceneRow.Position = UDim2.new(0, 10, 0, 192)
sceneRow.BackgroundColor3 = Color3.fromRGB(20, 30, 50)
sceneRow.Text = ""
sceneRow.AutoButtonColor = false
sceneRow.BorderSizePixel = 0
sceneRow.Parent = panel
Instance.new("UICorner", sceneRow).CornerRadius = UDim.new(0, 10)

local scLabel = Instance.new("TextLabel")
scLabel.Size = UDim2.new(1, -100, 1, 0)
scLabel.Position = UDim2.new(0, 14, 0, 0)
scLabel.BackgroundTransparency = 1
scLabel.Text = "场景识别"
scLabel.TextColor3 = Color3.fromRGB(220, 230, 255)
scLabel.Font = Enum.Font.GothamBold
scLabel.TextSize = 14
scLabel.TextXAlignment = Enum.TextXAlignment.Left
scLabel.Parent = sceneRow

local scState = Instance.new("TextLabel")
scState.Size = UDim2.new(0, 40, 1, 0)
scState.Position = UDim2.new(1, -50, 0, 0)
scState.BackgroundTransparency = 1
scState.Text = "ON"
scState.TextColor3 = Color3.fromRGB(0, 255, 130)
scState.Font = Enum.Font.GothamBold
scState.TextSize = 14
scState.TextXAlignment = Enum.TextXAlignment.Right
scState.Parent = sceneRow

-- 显示 FPS 开关
local showRow = Instance.new("TextButton")
showRow.Size = UDim2.new(1, -20, 0, 46)
showRow.Position = UDim2.new(0, 10, 0, 248)
showRow.BackgroundColor3 = Color3.fromRGB(20, 30, 50)
showRow.Text = ""
showRow.AutoButtonColor = false
showRow.BorderSizePixel = 0
showRow.Parent = panel
Instance.new("UICorner", showRow).CornerRadius = UDim.new(0, 10)

local sfLabel = Instance.new("TextLabel")
sfLabel.Size = UDim2.new(1, -100, 1, 0)
sfLabel.Position = UDim2.new(0, 14, 0, 0)
sfLabel.BackgroundTransparency = 1
sfLabel.Text = "显示实时 FPS"
sfLabel.TextColor3 = Color3.fromRGB(220, 230, 255)
sfLabel.Font = Enum.Font.GothamBold
sfLabel.TextSize = 14
sfLabel.TextXAlignment = Enum.TextXAlignment.Left
sfLabel.Parent = showRow

local sfState = Instance.new("TextLabel")
sfState.Size = UDim2.new(0, 40, 1, 0)
sfState.Position = UDim2.new(1, -50, 0, 0)
sfState.BackgroundTransparency = 1
sfState.Text = "ON"
sfState.TextColor3 = Color3.fromRGB(0, 255, 130)
sfState.Font = Enum.Font.GothamBold
sfState.TextSize = 14
sfState.TextXAlignment = Enum.TextXAlignment.Right
sfState.Parent = showRow

-- 手动档位按钮
local presetRow = Instance.new("Frame")
presetRow.Size = UDim2.new(1, -20, 0, 42)
presetRow.Position = UDim2.new(0, 10, 0, 304)
presetRow.BackgroundTransparency = 1
presetRow.Parent = panel

for i = 1, 10 do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 24, 0, 42)
    btn.Position = UDim2.new(0, (i-1) * 26, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(30, 22, 48)
    btn.Text = tostring(i)
    btn.TextColor3 = Color3.fromRGB(200, 150, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0
    btn.Parent = presetRow
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    if i == Config.CurrentLevel then
        btn.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end

    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Config.AutoMode = false
            arState.Text = "OFF"
            arState.TextColor3 = Color3.fromRGB(255, 80, 80)
            applyQuality(i)
            updateLevelUI(i)
            for _, c in ipairs(presetRow:GetChildren()) do
                if c:IsA("TextButton") then
                    local isCurrent = c.Text == tostring(i)
                    TweenService:Create(c, QUICK_BOUNCE, {
                        BackgroundColor3 = isCurrent and Color3.fromRGB(0, 200, 255) or Color3.fromRGB(30, 22, 48),
                        TextColor3 = isCurrent and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 150, 255),
                    }):Play()
                end
            end
        end
    end)
end

-- ========== 事件 ==========
autoRow.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        Config.AutoMode = not Config.AutoMode
        arState.Text = Config.AutoMode and "ON" or "OFF"
        arState.TextColor3 = Config.AutoMode and Color3.fromRGB(0, 255, 130) or Color3.fromRGB(255, 80, 80)
    end
end)

sceneRow.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        Config.SceneDetection = not Config.SceneDetection
        scState.Text = Config.SceneDetection and "ON" or "OFF"
        scState.TextColor3 = Config.SceneDetection and Color3.fromRGB(0, 255, 130) or Color3.fromRGB(255, 80, 80)
    end
end)

showRow.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        Config.ShowFPS = not Config.ShowFPS
        sfState.Text = Config.ShowFPS and "ON" or "OFF"
        sfState.TextColor3 = Config.ShowFPS and Color3.fromRGB(0, 255, 130) or Color3.fromRGB(255, 80, 80)
        fpsDisplay.Visible = Config.ShowFPS
    end
end)

-- ========== 滑块拖拽 ==========
local draggingSlider = false
local function updateSlider(inputX)
    local relX = math.clamp((inputX - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X, 0, 1)
    local val = math.floor(1 + relX * 9 + 0.5)
    Config.AutoMode = false
    arState.Text = "OFF"
    arState.TextColor3 = Color3.fromRGB(255, 80, 80)
    applyQuality(val)
    updateLevelUI(val)
end

trackBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingSlider = true
        updateSlider(input.Position.X)
        TweenService:Create(knob, QUICK_BOUNCE, {Size = UDim2.new(0, 28, 0, 28)}):Play()
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateSlider(input.Position.X)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if draggingSlider then
            draggingSlider = false
            TweenService:Create(knob, QUICK_BOUNCE, {Size = UDim2.new(0, 20, 0, 20)}):Play()
        end
    end
end)

-- ========== FPS 刷新 ==========
task.spawn(function()
    while gui.Parent do
        if Config.ShowFPS then
            fpsDisplay.Text = string.format("FPS: %d | 档: %d", currentFPS, Config.CurrentLevel)
            if currentFPS >= Config.TargetFPS - 5 then
                fpsDisplay.TextColor3 = Color3.fromRGB(0, 255, 130)
            elseif currentFPS >= Config.TargetFPS * 0.7 then
                fpsDisplay.TextColor3 = Color3.fromRGB(255, 200, 0)
            else
                fpsDisplay.TextColor3 = Color3.fromRGB(255, 80, 80)
            end
        end
        task.wait(0.5)
    end
end)

-- ========== 面板开关 ==========
ball.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local start = input.Position
        local moved = false
        local conn = UserInputService.InputChanged:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
                if (inp.Position - start).Magnitude > 10 then
                    moved = true
                end
            end
        end)
        local ended = false
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                ended = true
                conn:Disconnect()
                if not moved then
                    panel.Visible = not panel.Visible
                end
            end
        end)
    end
end)

closeBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        panel.Visible = false
    end
end)

-- ========== 拖拽 ==========
local function makeDraggable(frame)
    local dragging, dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            local newX = startPos.X.Offset + delta.X
            local newY = startPos.Y.Offset + delta.Y
            local vp = gui.AbsoluteSize
            newX = math.clamp(newX, 0, vp.X - frame.AbsoluteSize.X)
            newY = math.clamp(newY, 0, vp.Y - frame.AbsoluteSize.Y)
            frame.Position = UDim2.new(0, newX, 0, newY)
        end
    end)
end

makeDraggable(panel)
makeDraggable(fpsDisplay)
makeDraggable(ball)
