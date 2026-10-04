-- ================= GB 极致画质 v5.3 (锁帧 + 锐化) =================
-- 稳锁60帧 | 超强锐化 | 20档画质 | 枪炮不冒烟 | 地图不乌烟瘴气
-- =================================================================

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ============ 配置 ============
local Config = {
    Enabled = true,
    TargetFPS = 60,
    CurrentLevel = 10,
    AutoMode = true,
    ShowFPS = true,
    SceneDetection = true,
    ExplosionFX = true,
    ShakeIntensity = 3,
    Sharpness = 2.0,
}

-- ============ FPS 统计 ============
local frameCount = 0
local lastTime = tick()
local currentFPS = 60
local fpsHistory = {}

-- ============ 20 档极致画质 ============
local QualityLevels = {
    [1]  = { name = "极限省电", dist = 150,  shadows = false, envParticles = false, postFX = 0, fogEnd = 250,  brightness = 0.9, atmosphere = false, atmoDensity = 0 },
    [2]  = { name = "极低",     dist = 250,  shadows = false, envParticles = false, postFX = 0, fogEnd = 350,  brightness = 1.0, atmosphere = false, atmoDensity = 0 },
    [3]  = { name = "很低",     dist = 400,  shadows = false, envParticles = false, postFX = 0, fogEnd = 500,  brightness = 1.1, atmosphere = false, atmoDensity = 0 },
    [4]  = { name = "低",       dist = 550,  shadows = false, envParticles = false, postFX = 0, fogEnd = 700,  brightness = 1.2, atmosphere = false, atmoDensity = 0 },
    [5]  = { name = "中低",     dist = 700,  shadows = true,  envParticles = false, postFX = 1, fogEnd = 900,  brightness = 1.3, atmosphere = false, atmoDensity = 0 },
    [6]  = { name = "中",       dist = 900,  shadows = true,  envParticles = false, postFX = 1, fogEnd = 1100, brightness = 1.4, atmosphere = true,  atmoDensity = 0.1 },
    [7]  = { name = "中高",     dist = 1100, shadows = true,  envParticles = false, postFX = 1, fogEnd = 1300, brightness = 1.5, atmosphere = true,  atmoDensity = 0.12 },
    [8]  = { name = "高",       dist = 1400, shadows = true,  envParticles = false, postFX = 2, fogEnd = 1600, brightness = 1.6, atmosphere = true,  atmoDensity = 0.14 },
    [9]  = { name = "很高",     dist = 1700, shadows = true,  envParticles = false, postFX = 2, fogEnd = 2000, brightness = 1.7, atmosphere = true,  atmoDensity = 0.16 },
    [10] = { name = "极致",     dist = 2200, shadows = true,  envParticles = false, postFX = 2, fogEnd = 2600, brightness = 1.8, atmosphere = true,  atmoDensity = 0.18 },
    [11] = { name = "极致+",    dist = 2600, shadows = true,  envParticles = false, postFX = 3, fogEnd = 3000, brightness = 1.9, atmosphere = true,  atmoDensity = 0.2 },
    [12] = { name = "极致++",   dist = 3000, shadows = true,  envParticles = false, postFX = 3, fogEnd = 3500, brightness = 2.0, atmosphere = true,  atmoDensity = 0.22 },
    [13] = { name = "电影级",   dist = 3500, shadows = true,  envParticles = false, postFX = 3, fogEnd = 4000, brightness = 2.1, atmosphere = true,  atmoDensity = 0.24 },
    [14] = { name = "电影+",    dist = 4000, shadows = true,  envParticles = false, postFX = 4, fogEnd = 4500, brightness = 2.2, atmosphere = true,  atmoDensity = 0.26 },
    [15] = { name = "电影++",   dist = 4500, shadows = true,  envParticles = false, postFX = 4, fogEnd = 5000, brightness = 2.3, atmosphere = true,  atmoDensity = 0.28 },
    [16] = { name = "超清",     dist = 5000, shadows = true,  envParticles = false, postFX = 4, fogEnd = 6000, brightness = 2.4, atmosphere = true,  atmoDensity = 0.3 },
    [17] = { name = "超清+",    dist = 6000, shadows = true,  envParticles = false, postFX = 5, fogEnd = 7000, brightness = 2.5, atmosphere = true,  atmoDensity = 0.32 },
    [18] = { name = "超清++",   dist = 7000, shadows = true,  envParticles = false, postFX = 5, fogEnd = 8000, brightness = 2.6, atmosphere = true,  atmoDensity = 0.34 },
    [19] = { name = "次世代",   dist = 8000, shadows = true,  envParticles = false, postFX = 6, fogEnd = 9000, brightness = 2.7, atmosphere = true,  atmoDensity = 0.36 },
    [20] = { name = "极致幻境", dist = 9999, shadows = true,  envParticles = false, postFX = 6, fogEnd = 9999, brightness = 2.9, atmosphere = true,  atmoDensity = 0.4 },
}

local function shouldDisableParticle(obj)
    local parent = obj
    for i = 1, 6 do
        if not parent then break end
        parent = parent.Parent
        if not parent then break end
        if parent:IsA("Tool") or parent:IsA("Accessory") then return true end
        if parent:IsA("Model") and parent:FindFirstChildOfClass("Humanoid") then return true end
        local n = string.lower(parent.Name)
        if string.find(n, "gun") or string.find(n, "cannon") or string.find(n, "musket")
            or string.find(n, "weapon") or string.find(n, "rifle") or string.find(n, "pistol") then
            return true
        end
    end
    local pname = obj.Parent and obj.Parent.Name or ""
    local pnameLow = string.lower(pname)
    if string.find(pnameLow, "smoke") or string.find(pnameLow, "fire")
        or string.find(pnameLow, "spark") or string.find(pnameLow, "explosion")
        or string.find(pnameLow, "gun") or string.find(pnameLow, "muzzle")
        or string.find(pnameLow, "cannon") or string.find(pnameLow, "musket") then
        return true
    end
    return false
end

local function applySharpness()
    local cc = Lighting:FindFirstChild("SharpenCC")
    if not cc then
        cc = Instance.new("ColorCorrectionEffect")
        cc.Name = "SharpenCC"
        cc.Parent = Lighting
    end
    local s = Config.Sharpness
    cc.Contrast = 0.1 + s * 0.15
    cc.Saturation = 0.1 + s * 0.1
    cc.Brightness = 0.02 + s * 0.02
    cc.TintColor = Color3.fromRGB(255, 255, 255)
end

local function applyQuality(level)
    local q = QualityLevels[level]
    if not q then return end
    Config.CurrentLevel = level

    Lighting.GlobalShadows = q.shadows
    Lighting.Brightness = q.brightness
    Lighting.FogEnd = q.fogEnd
    Lighting.EnvironmentDiffuseScale = q.shadows and 0.4 or 0
    Lighting.EnvironmentSpecularScale = q.shadows and 0.4 or 0

    local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
    if q.atmosphere then
        if not atmo then
            atmo = Instance.new("Atmosphere")
            atmo.Name = "CustomAtmosphere"
            atmo.Offset = 0.1
            atmo.Color = Color3.fromRGB(220, 220, 220)
            atmo.Decay = Color3.fromRGB(140, 140, 140)
            atmo.Glare = 0
            atmo.Haze = 0.8
            atmo.Parent = Lighting
        end
        atmo.Density = q.atmoDensity
    elseif atmo and atmo.Name == "CustomAtmosphere" then
        atmo:Destroy()
    end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.CastShadow = q.shadows
        elseif obj:IsA("ParticleEmitter") then
            if shouldDisableParticle(obj) then
                obj.Enabled = false
            else
                obj.Enabled = q.envParticles
            end
        elseif obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
            obj.Enabled = false
        end
    end

    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("PostEffect") and obj.Name ~= "SharpenCC" then
            obj:Destroy()
        end
    end

    applySharpness()

    if q.postFX >= 1 then
        local bloom = Instance.new("BloomEffect")
        bloom.Intensity = 0.15
        bloom.Size = 18
        bloom.Parent = Lighting
    end
    if q.postFX >= 2 then
        local sunRays = Instance.new("SunRaysEffect")
        sunRays.Intensity = 0.05
        sunRays.Spread = 0.5
        sunRays.Parent = Lighting
    end
    if q.postFX >= 3 then
        local dof = Instance.new("DepthOfFieldEffect")
        dof.FarIntensity = 0.08
        dof.FocusDistance = 60
        dof.InFocusRadius = 120
        dof.NearIntensity = 0.03
        dof.Parent = Lighting
    end
    if q.postFX >= 4 then
        local cc2 = Instance.new("ColorCorrectionEffect")
        cc2.Brightness = 0.05
        cc2.Contrast = 0.15
        cc2.Saturation = 0.15
        cc2.TintColor = Color3.fromRGB(255, 252, 245)
        cc2.Parent = Lighting
    end
    if q.postFX >= 5 then
        local blur = Instance.new("BlurEffect")
        blur.Size = 1
        blur.Parent = Lighting
    end
    if q.postFX >= 6 then
        local bloom2 = Instance.new("BloomEffect")
        bloom2.Intensity = 0.25
        bloom2.Size = 28
        bloom2.Threshold = 0.85
        bloom2.Parent = Lighting
    end
end

local function countNearbyEntities()
    local char = LocalPlayer.Character
    if not char then return 0 end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return 0 end
    local myPos = hrp.Position
    local count = 0
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
            local root = obj:FindFirstChild("HumanoidRootPart")
            if root and (root.Position - myPos).Magnitude <= 100 then
                count = count + 1
            end
        end
    end
    return count
end

local targetInterval = 1 / Config.TargetFPS
local lastFrameTime = tick()

RunService.RenderStepped:Connect(function()
    local now = tick()
    local actualDelta = now - lastFrameTime
    lastFrameTime = now

    if Config.Enabled then
        local waitTime = targetInterval - actualDelta
        if waitTime > 0.001 then task.wait(waitTime) end
    end

    frameCount = frameCount + 1
    if now - lastTime >= 1 then
        currentFPS = frameCount
        frameCount = 0
        lastTime = now
        table.insert(fpsHistory, currentFPS)
        if #fpsHistory > 5 then table.remove(fpsHistory, 1) end
    end
end)

task.spawn(function()
    local lastSceneCheck = 0
    local entityCount = 0
    while true do
        task.wait(1)
        if not Config.Enabled or not Config.AutoMode then continue end
        if Config.SceneDetection and tick() - lastSceneCheck >= 3 then
            entityCount = countNearbyEntities()
            lastSceneCheck = tick()
        end
        local avgFPS = 0
        for _, f in ipairs(fpsHistory) do avgFPS = avgFPS + f end
        avgFPS = avgFPS / math.max(#fpsHistory, 1)
        local target = Config.TargetFPS
        local newLevel = Config.CurrentLevel
        local sceneOffset = 0
        if entityCount >= 20 then sceneOffset = -3
        elseif entityCount >= 10 then sceneOffset = -2
        elseif entityCount >= 5 then sceneOffset = -1
        elseif entityCount <= 2 then sceneOffset = 1 end
        if avgFPS < target - 8 then newLevel = Config.CurrentLevel - 2
        elseif avgFPS < target - 3 then newLevel = Config.CurrentLevel - 1
        elseif avgFPS > target + 8 then newLevel = Config.CurrentLevel + 1 end
        newLevel = newLevel + sceneOffset
        newLevel = math.clamp(newLevel, 1, 20)
        if newLevel ~= Config.CurrentLevel then
            applyQuality(newLevel)
            if updateLevelUI then updateLevelUI(newLevel) end
        end
    end
end)

applyQuality(10)

local shakeIntensity = 0
local shakeDecay = 5

local function triggerShake(intensity)
    shakeIntensity = math.max(shakeIntensity, intensity)
end

RunService.RenderStepped:Connect(function(dt)
    if shakeIntensity > 0.01 then
        local offset = Vector3.new(
            (math.random() - 0.5) * shakeIntensity,
            (math.random() - 0.5) * shakeIntensity,
            (math.random() - 0.5) * shakeIntensity
        )
        Camera.CFrame = Camera.CFrame * CFrame.new(offset)
        shakeIntensity = shakeIntensity - shakeDecay * dt
    else
        shakeIntensity = 0
    end
end)

Workspace.DescendantAdded:Connect(function(descendant)
    if not Config.ExplosionFX then return end
    if descendant:IsA("Explosion") or (descendant:IsA("Part") and string.find(string.lower(descendant.Name), "explosion")) then
        local pos = descendant.Position
        local myChar = LocalPlayer.Character
        if myChar and myChar:FindFirstChild("HumanoidRootPart") then
            local dist = (pos - myChar.HumanoidRootPart.Position).Magnitude
            if dist <= 200 then
                local intensity = math.clamp(Config.ShakeIntensity - dist / 100, 0.3, Config.ShakeIntensity)
                triggerShake(intensity)
            end
        end
    end
end)

if game.CoreGui:FindFirstChild("GBQualityUI") then
    game.CoreGui.GBQualityUI:Destroy()
end

local parentGui = (gethui and gethui()) or game.CoreGui
local gui = Instance.new("ScreenGui")
gui.Name = "GBQualityUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 2147483647
gui.Parent = parentGui

local QUICK_BOUNCE = TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local BOUNCE_OUT = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local ball = Instance.new("TextButton")
ball.Size = UDim2.new(0, 60, 0, 60)
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
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 180, 0)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 80, 0)),
})
ballGrad.Parent = ballStroke
local ballIcon = Instance.new("TextLabel")
ballIcon.Size = UDim2.new(1, 0, 1, 0)
ballIcon.BackgroundTransparency = 1
ballIcon.Text = "★"
ballIcon.TextColor3 = Color3.fromRGB(255, 180, 0)
ballIcon.Font = Enum.Font.GothamBold
ballIcon.TextSize = 28
ballIcon.Parent = ball

local fpsDisplay = Instance.new("TextLabel")
fpsDisplay.Size = UDim2.new(0, 180, 0, 30)
fpsDisplay.Position = UDim2.new(0, 16, 0, 16)
fpsDisplay.BackgroundColor3 = Color3.fromRGB(10, 8, 16)
fpsDisplay.BackgroundTransparency = 0.3
fpsDisplay.BorderSizePixel = 0
fpsDisplay.Text = "FPS: 0 | 档: 10"
fpsDisplay.TextColor3 = Color3.fromRGB(255, 180, 0)
fpsDisplay.Font = Enum.Font.GothamBold
fpsDisplay.TextSize = 13
fpsDisplay.ZIndex = 5
fpsDisplay.Parent = gui
Instance.new("UICorner", fpsDisplay).CornerRadius = UDim.new(0, 8)

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 300, 0, 460)
panel.Position = UDim2.new(0.5, -150, 0.5, -230)
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
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 180, 0)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 80, 0)),
})
psGrad.Parent = panelStroke

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundTransparency = 1
titleBar.ZIndex = 2
titleBar.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -50, 1, 0)
title.Position = UDim2.new(0, 14, 0, 0)
title.BackgroundTransparency = 1
title.Text = "极致画质 v5.3"
title.TextColor3 = Color3.fromRGB(255, 180, 0)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 36, 0, 36)
closeBtn.Position = UDim2.new(1, -44, 0.5, -18)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 20
closeBtn.AutoButtonColor = false
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, 0, 1, -40)
scroll.Position = UDim2.new(0, 0, 0, 40)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 180, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Active = true
scroll.Parent = panel

local function createToggle(yPos, labelText, getter, setter)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -20, 0, 44)
    row.Position = UDim2.new(0, 10, 0, yPos)
    row.BackgroundColor3 = Color3.fromRGB(20, 30, 50)
    row.BorderSizePixel = 0
    row.Parent = scroll
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -110, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(220, 230, 255)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local switchBtn = Instance.new("TextButton")
    switchBtn.Size = UDim2.new(0, 60, 1, 0)
    switchBtn.Position = UDim2.new(1, -65, 0, 0)
    switchBtn.BackgroundTransparency = 1
    switchBtn.Text = ""
    switchBtn.AutoButtonColor = false
    switchBtn.BorderSizePixel = 0
    switchBtn.Parent = row

    local state = Instance.new("TextLabel")
    state.Size = UDim2.new(1, 0, 1, 0)
    state.BackgroundTransparency = 1
    state.Text = getter() and "ON" or "OFF"
    state.TextColor3 = getter() and Color3.fromRGB(0, 255, 130) or Color3.fromRGB(255, 80, 80)
    state.Font = Enum.Font.GothamBold
    state.TextSize = 13
    state.TextXAlignment = Enum.TextXAlignment.Right
    state.Parent = switchBtn

    local function updateUI()
        state.Text = getter() and "ON" or "OFF"
        state.TextColor3 = getter() and Color3.fromRGB(0, 255, 130) or Color3.fromRGB(255, 80, 80)
    end

    switchBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            setter(not getter())
            updateUI()
            TweenService:Create(switchBtn, QUICK_BOUNCE, {BackgroundColor3 = Color3.fromRGB(255, 180, 0), BackgroundTransparency = 0.7}):Play()
            task.wait(0.15)
            TweenService:Create(switchBtn, QUICK_BOUNCE, {BackgroundTransparency = 1}):Play()
        end
    end)
    return updateUI
end

local updateAutoUI = createToggle(10, "AI 智能调度", function() return Config.AutoMode end, function(v) Config.AutoMode = v end)
local updateSceneUI = createToggle(58, "场景识别", function() return Config.SceneDetection end, function(v) Config.SceneDetection = v end)
local updateShowUI = createToggle(106, "显示实时 FPS", function() return Config.ShowFPS end, function(v) Config.ShowFPS = v; fpsDisplay.Visible = v end)
local updateExplosionUI = createToggle(154, "自爆震动", function() return Config.ExplosionFX end, function(v) Config.ExplosionFX = v end)

local function createSlider(yPos, labelText, min, max, initVal, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -20, 0, 56)
    row.Position = UDim2.new(0, 10, 0, yPos)
    row.BackgroundColor3 = Color3.fromRGB(20, 30, 50)
    row.BorderSizePixel = 0
    row.Parent = scroll
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -24, 0, 20)
    lbl.Position = UDim2.new(0, 14, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText .. ": " .. initVal
    lbl.TextColor3 = Color3.fromRGB(255, 200, 100)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -28, 0, 8)
    track.Position = UDim2.new(0, 14, 1, -18)
    track.BackgroundColor3 = Color3.fromRGB(40, 50, 70)
    track.BorderSizePixel = 0
    track.Parent = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((initVal - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
    fill.BorderSizePixel = 0
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new((initVal - min) / (max - min), -8, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.ZIndex = 2
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local dragging = false
    local function updateSlider(inputX)
        local relX = math.clamp((inputX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = min + relX * (max - min)
        callback(val, relX)
        fill.Size = UDim2.new(relX, 0, 1, 0)
        knob.Position = UDim2.new(relX, -8, 0.5, -8)
        lbl.Text = labelText .. ": " .. math.floor(val * 10 + 0.5) / 10
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateSlider(input.Position.X)
            TweenService:Create(knob, QUICK_BOUNCE, {Size = UDim2.new(0, 22, 0, 22)}):Play()
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            TweenService:Create(knob, QUICK_BOUNCE, {Size = UDim2.new(0, 16, 0, 16)}):Play()
        end
    end)

    return function(v) lbl.Text = labelText .. ": " .. math.floor(v * 10 + 0.5) / 10 end
end

createSlider(202, "锐化强度", 0, 5, Config.Sharpness, function(val)
    Config.Sharpness = math.floor(val * 10 + 0.5) / 10
    applySharpness()
end)

createSlider(260, "震动强度", 1, 10, Config.ShakeIntensity, function(val)
    Config.ShakeIntensity = math.floor(val + 0.5)
end)

local updateLevelUI = createSlider(318, "画质等级", 1, 20, Config.CurrentLevel, function(val)
    val = math.floor(val + 0.5)
    Config.AutoMode = false
    if updateAutoUI then updateAutoUI() end
    applyQuality(val)
end)

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

local function makeDraggable(frame, handle)
    local dragging, dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
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

makeDraggable(panel, titleBar)
makeDraggable(fpsDisplay, fpsDisplay)

local ballHoldStart = 0
local ballMoved = false
local ballDragging = false
local ballDragStart, ballStartPos

ball.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        ballHoldStart = os.clock()
        ballMoved = false
        ballDragging = true
        ballDragStart = input.Position
        ballStartPos = ball.Position
        TweenService:Create(ball, QUICK_BOUNCE, {Size = UDim2.new(0, 52, 0, 52)}):Play()
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if ballDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - ballDragStart
        if math.abs(delta.X) > 12 or math.abs(delta.Y) > 12 then ballMoved = true end
        if ballMoved then
            local newX = ballStartPos.X.Offset + delta.X
            local newY = ballStartPos.Y.Offset + delta.Y
            local vp = gui.AbsoluteSize
            newX = math.clamp(newX, 0, vp.X - 60)
            newY = math.clamp(newY, 0, vp.Y - 60)
            ball.Position = UDim2.new(0, newX, 0, newY)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if ballDragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        ballDragging = false
        TweenService:Create(ball, QUICK_BOUNCE, {Size = UDim2.new(0, 60, 0, 60)}):Play()
        local holdTime = os.clock() - ballHoldStart
        if holdTime < 0.5 and not ballMoved then
            if panel.Visible then
                panel.Visible = false
            else
                panel.Visible = true
                panel.Size = UDim2.new(0, 0, 0, 0)
                panel.Position = UDim2.new(0.5, -150, 0.5, -230)
                TweenService:Create(panel, BOUNCE_OUT, {Size = UDim2.new(0, 300, 0, 460)}):Play()
            end
        end
    end
end)

closeBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        panel.Visible = false
    end
end)

print("[GB 极致画质 v5.3] 已加载 | 锁帧 + 疯狂锐化")
