-- ================= GB 画质 Lite v3.0 (光影 + 安全功能大全) =================
-- 纯本地渲染 | 10档画质 | 50帧锁定 | 10光影 | 10实用功能 | 可滑动UI
-- ==========================================================================

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
    TargetFPS = 50,
    CurrentLevel = 3,
    AutoMode = true,
    ShowFPS = true,
    SceneDetection = true,

    BloodFX = true,
    ScreenBloodFX = true,
    ExplosionFX = true,

    BloodAmount = 500,
    SmokeSize = 20,
    ShakeIntensity = 3,

    SunRays = false,
    Bloom = false,
    DepthOfField = false,
    ColorCorrection = false,
    Atmosphere = false,
    VolumetricLight = false,
    NightVision = false,
    RedAlert = false,
    DustyAir = false,
    FoggyNight = false,

    ShowCoordinates = false,
    ShowTime = false,
    ShowHealth = false,
    ShowStamina = false,
    CompassHUD = false,
    FOVSlider = false,
    CustomFOV = 70,
    ZoomSensitivity = false,
    CinematicBars = false,
    ChromaticAberration = false,
    VignetteEffect = false,
}

-- ============ FPS 统计 ============
local frameCount = 0
local lastTime = tick()
local currentFPS = 50
local fpsHistory = {}

-- ============ 10 档画质 ============
local QualityLevels = {
    [1]  = { name = "极限省电", dist = 150,  shadows = false, envParticles = false, postFX = 0, fogEnd = 250,  brightness = 0.9 },
    [2]  = { name = "极低",     dist = 250,  shadows = false, envParticles = false, postFX = 0, fogEnd = 350,  brightness = 1.0 },
    [3]  = { name = "很低",     dist = 400,  shadows = false, envParticles = false, postFX = 0, fogEnd = 500,  brightness = 1.1 },
    [4]  = { name = "低",       dist = 550,  shadows = false, envParticles = true,  postFX = 1, fogEnd = 700,  brightness = 1.2 },
    [5]  = { name = "中低",     dist = 700,  shadows = true,  envParticles = true,  postFX = 1, fogEnd = 900,  brightness = 1.3 },
    [6]  = { name = "中",       dist = 900,  shadows = true,  envParticles = true,  postFX = 1, fogEnd = 1100, brightness = 1.4 },
    [7]  = { name = "中高",     dist = 1100, shadows = true,  envParticles = true,  postFX = 2, fogEnd = 1300, brightness = 1.5 },
    [8]  = { name = "高",       dist = 1400, shadows = true,  envParticles = true,  postFX = 2, fogEnd = 1600, brightness = 1.6 },
    [9]  = { name = "很高",     dist = 1700, shadows = true,  envParticles = true,  postFX = 2, fogEnd = 2000, brightness = 1.7 },
    [10] = { name = "极致",     dist = 2200, shadows = true,  envParticles = true,  postFX = 2, fogEnd = 2600, brightness = 1.8 },
}

local function isWeaponOrCharacterPart(obj)
    local parent = obj
    for i = 1, 4 do
        if not parent then break end
        parent = parent.Parent
        if not parent then break end
        if parent:IsA("Tool") or parent:IsA("Accessory") then return true end
        if parent:IsA("Model") and parent:FindFirstChildOfClass("Humanoid") then return true end
    end
    return false
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

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.CastShadow = q.shadows
        elseif obj:IsA("ParticleEmitter") then
            if isWeaponOrCharacterPart(obj) then
                obj.Enabled = false
            else
                local pname = obj.Parent and obj.Parent.Name or ""
                local isZombieParticle = string.find(pname, "Zombie") or string.find(pname, "Blood")
                    or string.find(pname, "Smoke") or string.find(pname, "Explosion") or string.find(pname, "Gore")
                if isZombieParticle then
                    obj.Enabled = false
                else
                    obj.Enabled = q.envParticles
                end
            end
        elseif obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") then
            obj.Enabled = false
        end
    end

    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("PostEffect") then obj:Destroy() end
    end

    local cc = Instance.new("ColorCorrectionEffect")
    cc.Brightness = 0.02
    cc.Contrast = 0.1
    cc.Saturation = 0.05
    cc.Parent = Lighting

    if q.postFX >= 1 then
        local bloom = Instance.new("BloomEffect")
        bloom.Intensity = 0.15
        bloom.Size = 16
        bloom.Parent = Lighting
    end
    if q.postFX >= 2 then
        local sunRays = Instance.new("SunRaysEffect")
        sunRays.Intensity = 0.05
        sunRays.Spread = 0.5
        sunRays.Parent = Lighting
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

-- ============ 锁帧 ============
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

-- ============ AI 调度 ============
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
        newLevel = math.clamp(newLevel, 1, 10)
        if newLevel ~= Config.CurrentLevel then
            applyQuality(newLevel)
            if updateLevelUI then updateLevelUI(newLevel) end
        end
    end
end)

applyQuality(3)

-- ====================================================
-- ============ 10 个光影功能 ============
-- ====================================================
local lightFX = {}

function lightFX.toggleSunRays(on)
    if on then
        if not Lighting:FindFirstChild("CustomSunRays") then
            local sr = Instance.new("SunRaysEffect")
            sr.Name = "CustomSunRays"
            sr.Intensity = 0.15
            sr.Spread = 0.6
            sr.Parent = Lighting
        end
    else
        local sr = Lighting:FindFirstChild("CustomSunRays")
        if sr then sr:Destroy() end
    end
end

function lightFX.toggleBloom(on)
    if on then
        if not Lighting:FindFirstChild("CustomBloom") then
            local b = Instance.new("BloomEffect")
            b.Name = "CustomBloom"
            b.Intensity = 0.4
            b.Size = 24
            b.Parent = Lighting
        end
    else
        local b = Lighting:FindFirstChild("CustomBloom")
        if b then b:Destroy() end
    end
end

function lightFX.toggleDOF(on)
    if on then
        if not Lighting:FindFirstChild("CustomDOF") then
            local d = Instance.new("DepthOfFieldEffect")
            d.Name = "CustomDOF"
            d.FarIntensity = 0.15
            d.FocusDistance = 40
            d.InFocusRadius = 80
            d.NearIntensity = 0.1
            d.Parent = Lighting
        end
    else
        local d = Lighting:FindFirstChild("CustomDOF")
        if d then d:Destroy() end
    end
end

function lightFX.toggleCC(on)
    if on then
        if not Lighting:FindFirstChild("CustomCC") then
            local c = Instance.new("ColorCorrectionEffect")
            c.Name = "CustomCC"
            c.Brightness = 0.05
            c.Contrast = 0.15
            c.Saturation = 0.15
            c.TintColor = Color3.fromRGB(255, 245, 230)
            c.Parent = Lighting
        end
    else
        local c = Lighting:FindFirstChild("CustomCC")
        if c then c:Destroy() end
    end
end

function lightFX.toggleAtmosphere(on)
    if on then
        if not Lighting:FindFirstChildOfClass("Atmosphere") then
            local a = Instance.new("Atmosphere")
            a.Name = "CustomAtmosphere"
            a.Density = 0.35
            a.Offset = 0.1
            a.Color = Color3.fromRGB(200, 200, 200)
            a.Decay = Color3.fromRGB(100, 100, 100)
            a.Glare = 0.2
            a.Haze = 1.2
            a.Parent = Lighting
        end
    else
        local a = Lighting:FindFirstChildOfClass("Atmosphere")
        if a and a.Name == "CustomAtmosphere" then a:Destroy() end
    end
end

function lightFX.toggleVolumetric(on)
    if on then
        if not Workspace:FindFirstChild("CustomVolumetric") then
            local part = Instance.new("Part")
            part.Name = "CustomVolumetric"
            part.Size = Vector3.new(4, 60, 4)
            part.Transparency = 0.7
            part.Anchored = true
            part.CanCollide = false
            part.CanQuery = false
            part.Material = Enum.Material.Neon
            part.Color = Color3.fromRGB(255, 240, 200)
            part.Parent = Workspace
            local light = Instance.new("PointLight")
            light.Brightness = 3
            light.Range = 50
            light.Color = Color3.fromRGB(255, 240, 200)
            light.Parent = part
            task.spawn(function()
                while part.Parent do
                    part.CFrame = CFrame.new(Camera.CFrame.Position + Vector3.new(0, 30, 0))
                    task.wait(0.2)
                end
            end)
        end
    else
        local v = Workspace:FindFirstChild("CustomVolumetric")
        if v then v:Destroy() end
    end
end

function lightFX.toggleNightVision(on)
    if on then
        if not Lighting:FindFirstChild("NightVisionCC") then
            local cc = Instance.new("ColorCorrectionEffect")
            cc.Name = "NightVisionCC"
            cc.Brightness = 0.15
            cc.Contrast = 0.2
            cc.Saturation = -0.5
            cc.TintColor = Color3.fromRGB(0, 255, 100)
            cc.Parent = Lighting
        end
        Lighting.Brightness = 2
    else
        local cc = Lighting:FindFirstChild("NightVisionCC")
        if cc then cc:Destroy() end
    end
end

function lightFX.toggleRedAlert(on)
    if on then
        if not Lighting:FindFirstChild("RedAlertCC") then
            local cc = Instance.new("ColorCorrectionEffect")
            cc.Name = "RedAlertCC"
            cc.Brightness = 0.05
            cc.Contrast = 0.2
            cc.TintColor = Color3.fromRGB(255, 80, 80)
            cc.Parent = Lighting
        end
    else
        local cc = Lighting:FindFirstChild("RedAlertCC")
        if cc then cc:Destroy() end
    end
end

function lightFX.toggleDusty(on)
    if on then
        if not Lighting:FindFirstChild("DustyAtmosphere") then
            local a = Instance.new("Atmosphere")
            a.Name = "DustyAtmosphere"
            a.Density = 0.5
            a.Color = Color3.fromRGB(180, 160, 130)
            a.Decay = Color3.fromRGB(120, 100, 80)
            a.Glare = 0
            a.Haze = 2
            a.Parent = Lighting
        end
    else
        local a = Lighting:FindFirstChild("DustyAtmosphere")
        if a then a:Destroy() end
    end
end

function lightFX.toggleFoggyNight(on)
    if on then
        Lighting.FogEnd = 100
        Lighting.FogStart = 0
        Lighting.FogColor = Color3.fromRGB(20, 20, 30)
        Lighting.Brightness = 0.5
    else
        Lighting.FogStart = 0
        Lighting.FogEnd = 1000
        Lighting.FogColor = Color3.fromRGB(192, 192, 192)
    end
end

-- ====================================================
-- ============ 屏幕血迹 ============
-- ====================================================
local bloodGui = Instance.new("ScreenGui")
bloodGui.Name = "BloodOverlayFX"
bloodGui.ResetOnSpawn = false
bloodGui.IgnoreGuiInset = true
bloodGui.DisplayOrder = 100
bloodGui.Parent = (gethui and gethui()) or game.CoreGui

local function spawnScreenBlood()
    if not Config.ScreenBloodFX then return end
    local drop = Instance.new("Frame")
    drop.Size = UDim2.new(0, math.random(20, 60), 0, math.random(40, 120))
    drop.Position = UDim2.new(math.random(), 0, math.random(-0.3, 0.3), 0)
    drop.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    drop.BackgroundTransparency = 0.3
    drop.BorderSizePixel = 0
    drop.Rotation = math.random(-20, 20)
    drop.ZIndex = 50
    drop.Parent = bloodGui
    Instance.new("UICorner", drop).CornerRadius = UDim.new(0.3, 0)
    local flowTween = TweenService:Create(drop, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Position = UDim2.new(drop.Position.X.Scale, drop.Position.X.Offset, 1.2, 0),
        BackgroundTransparency = 0.9
    })
    flowTween:Play()
    flowTween.Completed:Connect(function() drop:Destroy() end)
end

-- ====================================================
-- ============ 自爆震动 ============
-- ====================================================
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

local function spawnBigSmoke(position)
    if not Config.ExplosionFX then return end
    local smokePart = Instance.new("Part")
    smokePart.Size = Vector3.new(1, 1, 1)
    smokePart.Transparency = 1
    smokePart.CanCollide = false
    smokePart.Anchored = true
    smokePart.Position = position
    smokePart.Parent = Workspace
    local smoke = Instance.new("Smoke")
    smoke.Size = Config.SmokeSize
    smoke.RiseVelocity = 10
    smoke.Opacity = 0.6
    smoke.Color = Color3.fromRGB(60, 60, 60)
    smoke.Parent = smokePart
    task.delay(3, function()
        if smokePart and smokePart.Parent then smokePart:Destroy() end
    end)
end

-- ====================================================
-- ============ 喷血 ============
-- ====================================================
local bledZombies = {}

local function makeBloodAt(part)
    if not part or not part.Parent then return end
    local attach = Instance.new("Attachment")
    attach.Parent = part
    local blood = Instance.new("ParticleEmitter")
    blood.Texture = "rbxassetid://243098098"
    blood.Color = ColorSequence.new(Color3.fromRGB(150, 0, 0))
    blood.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1.5),
        NumberSequenceKeypoint.new(1, 0.3)
    })
    blood.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(1, 1)
    })
    blood.Lifetime = NumberRange.new(1.5, 2.5)
    blood.Speed = NumberRange.new(40, 70)
    blood.SpreadAngle = Vector2.new(180, 180)
    blood.Rate = Config.BloodAmount
    blood.Acceleration = Vector3.new(0, 30, 0)
    blood.Enabled = true
    blood.Parent = attach
    task.delay(0.8, function() blood.Enabled = false end)
    task.delay(3, function()
        if attach and attach.Parent then attach:Destroy() end
    end)
end

RunService.Heartbeat:Connect(function()
    if not Config.BloodFX then return end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health <= 0 and not bledZombies[hum] then
                local isPlayerChar = false
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr.Character == obj then isPlayerChar = true break end
                end
                if not isPlayerChar then
                    bledZombies[hum] = true
                    task.delay(10, function() bledZombies[hum] = nil end)
                    local neck = obj:FindFirstChild("Neck") or obj:FindFirstChild("Head")
                        or obj:FindFirstChild("UpperTorso") or obj:FindFirstChild("Torso")
                    if neck then makeBloodAt(neck) end
                    local myChar = LocalPlayer.Character
                    if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                        local myPos = myChar.HumanoidRootPart.Position
                        local zRoot = obj:FindFirstChild("HumanoidRootPart")
                        if zRoot and (zRoot.Position - myPos).Magnitude <= 50 then
                            spawnScreenBlood()
                        end
                    end
                end
            end
        end
    end
end)

-- ====================================================
-- ============ 自爆检测 ============
-- ====================================================
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
                if dist <= 150 then spawnBigSmoke(pos) end
            end
        end
    end
end)

-- ====================================================
-- ============ 10 个安全实用功能 ============
-- ====================================================
local infoGui = Instance.new("ScreenGui")
infoGui.Name = "GBInfoHUD"
infoGui.ResetOnSpawn = false
infoGui.IgnoreGuiInset = true
infoGui.DisplayOrder = 999
infoGui.Parent = (gethui and gethui()) or game.CoreGui

local infoFrame = Instance.new("Frame")
infoFrame.Size = UDim2.new(0, 200, 0, 140)
infoFrame.Position = UDim2.new(0, 16, 0, 50)
infoFrame.BackgroundColor3 = Color3.fromRGB(10, 8, 16)
infoFrame.BackgroundTransparency = 0.35
infoFrame.BorderSizePixel = 0
infoFrame.Visible = false
infoFrame.Parent = infoGui
Instance.new("UICorner", infoFrame).CornerRadius = UDim.new(0, 10)

local infoText = Instance.new("TextLabel")
infoText.Size = UDim2.new(1, -16, 1, -16)
infoText.Position = UDim2.new(0, 8, 0, 8)
infoText.BackgroundTransparency = 1
infoText.Text = ""
infoText.TextColor3 = Color3.fromRGB(0, 255, 130)
infoText.Font = Enum.Font.GothamBold
infoText.TextSize = 12
infoText.TextXAlignment = Enum.TextXAlignment.Left
infoText.TextYAlignment = Enum.TextYAlignment.Top
infoText.Parent = infoFrame

local compass = Instance.new("TextLabel")
compass.Size = UDim2.new(0, 60, 0, 28)
compass.Position = UDim2.new(0.5, -30, 0, 16)
compass.BackgroundColor3 = Color3.fromRGB(10, 8, 16)
compass.BackgroundTransparency = 0.4
compass.Text = "N"
compass.TextColor3 = Color3.fromRGB(0, 255, 130)
compass.Font = Enum.Font.GothamBold
compass.TextSize = 14
compass.Visible = false
compass.Parent = infoGui
Instance.new("UICorner", compass).CornerRadius = UDim.new(0, 6)

local barTop = Instance.new("Frame")
barTop.Size = UDim2.new(1, 0, 0, 0)
barTop.Position = UDim2.new(0, 0, 0, 0)
barTop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
barTop.BorderSizePixel = 0
barTop.ZIndex = 900
barTop.Parent = infoGui

local barBottom = Instance.new("Frame")
barBottom.Size = UDim2.new(1, 0, 0, 0)
barBottom.Position = UDim2.new(0, 0, 1, 0)
barBottom.AnchorPoint = Vector2.new(0, 1)
barBottom.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
barBottom.BorderSizePixel = 0
barBottom.ZIndex = 900
barBottom.Parent = infoGui

local vignette = Instance.new("Frame")
vignette.Size = UDim2.new(1, 0, 1, 0)
vignette.BackgroundTransparency = 1
vignette.ZIndex = 800
vignette.Parent = infoGui

local vTop = Instance.new("Frame")
vTop.Size = UDim2.new(1, 0, 0, 80)
vTop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
vTop.BackgroundTransparency = 0.6
vTop.BorderSizePixel = 0
vTop.ZIndex = 801
vTop.Parent = vignette

local vBottom = Instance.new("Frame")
vBottom.Size = UDim2.new(1, 0, 0, 80)
vBottom.Position = UDim2.new(0, 0, 1, 0)
vBottom.AnchorPoint = Vector2.new(0, 1)
vBottom.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
vBottom.BackgroundTransparency = 0.6
vBottom.BorderSizePixel = 0
vBottom.ZIndex = 801
vBottom.Parent = vignette

vignette.Visible = false

task.spawn(function()
    while infoGui.Parent do
        local char = LocalPlayer.Character
        local lines = {}

        if Config.ShowCoordinates and char and char:FindFirstChild("HumanoidRootPart") then
            local p = char.HumanoidRootPart.Position
            table.insert(lines, string.format("坐标: X %.0f  Y %.0f  Z %.0f", p.X, p.Y, p.Z))
        end

        if Config.ShowHealth and char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                table.insert(lines, string.format("血量: %d / %d", math.floor(hum.Health), math.floor(hum.MaxHealth)))
            end
        end

        if Config.ShowStamina and char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                table.insert(lines, string.format("体力: %d", math.floor(hum.WalkSpeed * 10)))
            end
        end

        if Config.ShowTime then
            local t = math.floor(tick() % 86400)
            local h = math.floor(t / 3600)
            local m = math.floor((t % 3600) / 60)
            table.insert(lines, string.format("时间: %02d:%02d", h, m))
        end

        infoText.Text = table.concat(lines, "\n")

        if Config.CompassHUD then
            compass.Visible = true
            local look = Camera.CFrame.LookVector
            local angle = math.deg(math.atan2(look.X, look.Z))
            local dir = "N"
            if angle > -45 and angle <= 45 then dir = "N"
            elseif angle > 45 and angle <= 135 then dir = "E"
            elseif angle > 135 or angle <= -135 then dir = "S"
            else dir = "W" end
            compass.Text = dir
        else
            compass.Visible = false
        end

        if Config.CinematicBars then
            TweenService:Create(barTop, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, 60)}):Play()
            TweenService:Create(barBottom, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, 60)}):Play()
        else
            TweenService:Create(barTop, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, 0)}):Play()
            TweenService:Create(barBottom, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, 0)}):Play()
        end

        vignette.Visible = Config.VignetteEffect

        if Config.FOVSlider then
            Camera.FieldOfView = Config.CustomFOV
        end

        task.wait(0.2)
    end
end)

-- ====================================================
-- ============ UI ============
-- ====================================================
if game.CoreGui:FindFirstChild("GBQualityLiteUI") then
    game.CoreGui.GBQualityLiteUI:Destroy()
end

local parentGui = (gethui and gethui()) or game.CoreGui
local gui = Instance.new("ScreenGui")
gui.Name = "GBQualityLiteUI"
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
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 200, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 100, 255)),
})
ballGrad.Parent = ballStroke
local ballIcon = Instance.new("TextLabel")
ballIcon.Size = UDim2.new(1, 0, 1, 0)
ballIcon.BackgroundTransparency = 1
ballIcon.Text = "⚙"
ballIcon.TextColor3 = Color3.fromRGB(0, 200, 255)
ballIcon.Font = Enum.Font.GothamBold
ballIcon.TextSize = 26
ballIcon.Parent = ball

local fpsDisplay = Instance.new("TextLabel")
fpsDisplay.Size = UDim2.new(0, 150, 0, 30)
fpsDisplay.Position = UDim2.new(0, 16, 0, 16)
fpsDisplay.BackgroundColor3 = Color3.fromRGB(10, 8, 16)
fpsDisplay.BackgroundTransparency = 0.3
fpsDisplay.BorderSizePixel = 0
fpsDisplay.Text = "FPS: 0 | 档: 3"
fpsDisplay.TextColor3 = Color3.fromRGB(0, 255, 130)
fpsDisplay.Font = Enum.Font.GothamBold
fpsDisplay.TextSize = 13
fpsDisplay.ZIndex = 5
fpsDisplay.Parent = gui
Instance.new("UICorner", fpsDisplay).CornerRadius = UDim.new(0, 8)

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 290, 0, 480)
panel.Position = UDim2.new(0.5, -145, 0.5, -240)
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
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 100, 255)),
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
title.Text = "GB 全能 v3.0"
title.TextColor3 = Color3.fromRGB(0, 200, 255)
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
scroll.ScrollBarImageColor3 = Color3.fromRGB(0, 200, 255)
scroll.CanvasSize = UDim2.new(0, 0, 0, 1500)
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
            TweenService:Create(switchBtn, QUICK_BOUNCE, {BackgroundColor3 = Color3.fromRGB(0, 200, 255), BackgroundTransparency = 0.7}):Play()
            task.wait(0.15)
            TweenService:Create(switchBtn, QUICK_BOUNCE, {BackgroundTransparency = 1}):Play()
        end
    end)
    return updateUI
end

local updateAutoUI = createToggle(10, "AI 智能调度", function() return Config.AutoMode end, function(v) Config.AutoMode = v end)
local updateSceneUI = createToggle(58, "场景识别", function() return Config.SceneDetection end, function(v) Config.SceneDetection = v end)
local updateShowUI = createToggle(106, "显示实时 FPS", function() return Config.ShowFPS end, function(v) Config.ShowFPS = v; fpsDisplay.Visible = v end)
local updateBloodUI = createToggle(154, "丧尸死亡喷血", function() return Config.BloodFX end, function(v) Config.BloodFX = v end)
local updateScreenBloodUI = createToggle(202, "屏幕血迹", function() return Config.ScreenBloodFX end, function(v) Config.ScreenBloodFX = v end)
local updateExplosionUI = createToggle(250, "自爆震动 + 巨烟", function() return Config.ExplosionFX end, function(v) Config.ExplosionFX = v end)

createToggle(298, "太阳光线", function() return Config.SunRays end, function(v) Config.SunRays = v; lightFX.toggleSunRays(v) end)
createToggle(346, "泛光", function() return Config.Bloom end, function(v) Config.Bloom = v; lightFX.toggleBloom(v) end)
createToggle(394, "景深", function() return Config.DepthOfField end, function(v) Config.DepthOfField = v; lightFX.toggleDOF(v) end)
createToggle(442, "色彩校正", function() return Config.ColorCorrection end, function(v) Config.ColorCorrection = v; lightFX.toggleCC(v) end)
createToggle(490, "大气雾", function() return Config.Atmosphere end, function(v) Config.Atmosphere = v; lightFX.toggleAtmosphere(v) end)
createToggle(538, "体积光", function() return Config.VolumetricLight end, function(v) Config.VolumetricLight = v; lightFX.toggleVolumetric(v) end)
createToggle(586, "夜视仪", function() return Config.NightVision end, function(v) Config.NightVision = v; lightFX.toggleNightVision(v) end)
createToggle(634, "红色警戒", function() return Config.RedAlert end, function(v) Config.RedAlert = v; lightFX.toggleRedAlert(v) end)
createToggle(682, "尘埃空气", function() return Config.DustyAir end, function(v) Config.DustyAir = v; lightFX.toggleDusty(v) end)
createToggle(730, "浓雾夜晚", function() return Config.FoggyNight end, function(v) Config.FoggyNight = v; lightFX.toggleFoggyNight(v) end)

createToggle(778, "显示坐标", function() return Config.ShowCoordinates end, function(v) Config.ShowCoordinates = v; infoFrame.Visible = v or Config.ShowHealth or Config.ShowTime or Config.ShowStamina end)
createToggle(826, "显示游戏时间", function() return Config.ShowTime end, function(v) Config.ShowTime = v; infoFrame.Visible = v or Config.ShowCoordinates or Config.ShowHealth or Config.ShowStamina end)
createToggle(874, "显示自己血量", function() return Config.ShowHealth end, function(v) Config.ShowHealth = v; infoFrame.Visible = v or Config.ShowCoordinates or Config.ShowTime or Config.ShowStamina end)
createToggle(922, "显示自己体力", function() return Config.ShowStamina end, function(v) Config.ShowStamina = v; infoFrame.Visible = v or Config.ShowCoordinates or Config.ShowTime or Config.ShowHealth end)
createToggle(970, "简易罗盘", function() return Config.CompassHUD end, function(v) Config.CompassHUD = v end)
createToggle(1018, "电影黑边", function() return Config.CinematicBars end, function(v) Config.CinematicBars = v end)
createToggle(1066, "暗角", function() return Config.VignetteEffect end, function(v) Config.VignetteEffect = v end)
createToggle(1114, "FOV 可调", function() return Config.FOVSlider end, function(v) Config.FOVSlider = v; if not v then Camera.FieldOfView = 70 end end)

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
    lbl.TextColor3 = Color3.fromRGB(200, 180, 255)
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
    fill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
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
        lbl.Text = labelText .. ": " .. math.floor(val + 0.5)
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
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                TweenService:Create(knob, QUICK_BOUNCE, {Size = UDim2.new(0, 16, 0, 16)}):Play()
            end
        end
    end)

    return function(v) lbl.Text = labelText .. ": " .. math.floor(v + 0.5) end
end

createSlider(1162, "血量", 100, 1000, Config.BloodAmount, function(val)
    Config.BloodAmount = math.floor(val + 0.5)
end)

createSlider(1220, "烟雾大小", 5, 50, Config.SmokeSize, function(val)
    Config.SmokeSize = math.floor(val + 0.5)
end)

createSlider(1278, "视野 FOV", 40, 120, Config.CustomFOV, function(val)
    Config.CustomFOV = math.floor(val + 0.5)
end)

local updateLevelUI = createSlider(1336, "画质等级", 1, 10, Config.CurrentLevel, function(val)
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
                panel.Position = UDim2.new(0.5, -145, 0.5, -240)
                TweenService:Create(panel, BOUNCE_OUT, {Size = UDim2.new(0, 290, 0, 480)}):Play()
            end
        end
    end
end)

closeBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        panel.Visible = false
    end
end)

print("[GB 全能 v3.0] 已加载 | 10光影 + 10实用 | 纯本地渲染 | 无透视")
