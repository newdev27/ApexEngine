--[[
    Reference.txt / Yes.luau — Extracted readable logic
    The file uses a custom Lua VM (not LuaRap). The VM itself cannot be
    statically deobfuscated. These are the two human-readable functions
    extracted verbatim and cleaned up.
]]

-- ── FireServer hook (function `j`) ────────────────────────────────────────
-- Hooks RemoteEvent:FireServer. Detects gun-fire events by name, then:
--   • AlwaysHeadshot: finds closest head in FOV, redirects args[3] direction
--   • NoSpread:       replaces args[3] with (target.Position - origin).Unit
--   • RapidFire:      re-fires N extra times after the original shot
--   • InstantBullet:  moves muzzle position (args[1]) to near the target
--   • BulletTracers:  draws a tracer line from origin to hit position

local function FireServerHook(self, ...)
    -- Guard: only intercept FireServer remotes
    local remoteName = self.Name
    local isGunFire = remoteName == "GunFire"
        or remoteName == "Fire"
        or remoteName == "Shoot"
        or remoteName == "BulletFire"
        or remoteName == "ShootGun"
        or remoteName == "FireGun"
        or remoteName == "GunShoot"
        or remoteName == "WeaponFire"
        or remoteName == "ShootEvent"
        or remoteName == "FireWeapon"
        or remoteName == "FireBullet"
        or remoteName == "BulletShoot"
        or remoteName == "ShotFired"
        or remoteName == "PlayerShoot"
        or remoteName == "ClientFire"

    -- Fallback: if name doesn't match, check if 2+ Vector3 args exist
    if not isGunFire then
        local args = {...}
        local vec3count = 0
        for i = 1, math.min(#args, 6) do
            if typeof(args[i]) == "Vector3" then
                vec3count += 1
                if vec3count >= 2 then isGunFire = true; break end
            end
        end
    end

    if not isGunFire then
        return self:FireServer(...)  -- original call
    end

    -- Record last shot time (for external checks)
    -- MatterDaddy.LastShot = tick()

    local silentAimEnabled = Settings.SilentAim and Settings.SilentAim.Enabled

    -- ── AlwaysHeadshot / AlwaysHit / InstantBullet path ──────────────────
    if (Settings.Aimbot.AlwaysHit or Settings.Aimbot.InstantBullet or Settings.Aimbot.AlwaysHeadshot)
        and not RapidFireActive
        and not silentAimEnabled
    then
        local args = {...}
        local origin = (typeof(args[1]) == "Vector3") and args[1] or Camera.CFrame.Position

        local targetPart = nil
        local targetPos  = nil

        if Settings.Aimbot.AlwaysHeadshot then
            -- Find closest head within FOV
            local bestDist = Settings.FOV.Radius
            local center   = Vector2.new(Camera.ViewportSize.X * 0.5, Camera.ViewportSize.Y * 0.5)
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    if Settings.Aimbot.TeamCheck and player.Team == LocalPlayer.Team then continue end
                    local head = player.Character:FindFirstChild("Head")
                    if head then
                        local sp, onScreen = Camera:WorldToViewportPoint(head.Position)
                        if onScreen and sp.Z > 0.01 then
                            local dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                            if dist < Settings.FOV.Radius and dist < bestDist then
                                bestDist   = dist
                                targetPart = head
                            end
                        end
                    end
                end
            end
            if not targetPart then
                return self:FireServer(table.unpack(args))  -- no target, fire normally
            end
            targetPos = targetPart.Position
        else
            -- Use closest enemy from aim system
            local t = GetClosestTarget(origin)
            if t and t.Parent then
                targetPart = t
                targetPos  = t.Position
            end
        end

        if not targetPart then return end

        local muzzle = origin
        if Settings.Aimbot.InstantBullet then
            -- Move muzzle to just behind target so bullet arrives instantly
            local delta = origin - targetPos
            if delta.Magnitude > 0.01 then
                muzzle = targetPos + delta.Unit * 2
            else
                muzzle = targetPos + Vector3.new(0, 0, 2)
            end
        end

        local shootFrom = Settings.Aimbot.InstantBullet and muzzle or origin
        local direction = (targetPos - shootFrom).Unit

        -- Redirect direction arg
        if #args >= 3 and typeof(args[3]) == "Vector3" then
            args[3] = direction
            if Settings.Aimbot.InstantBullet then
                args[1] = muzzle
            end
        end

        -- Bullet tracer
        task.spawn(function()
            local hum = targetPart.Parent and targetPart.Parent:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                if Settings.Combat.BulletTracers then
                    DrawTracer(shootFrom, targetPart.Position)
                end
                NotifyHit(targetPart.Parent and Players:GetPlayerFromCharacter(targetPart.Parent))
            end
        end)

        -- RapidFire
        if Settings.Combat.RapidFire and not RapidFireActive then
            local result = self:FireServer(table.unpack(args))
            RapidFireActive = true
            task.spawn(function()
                local extra = math.random(1, math.floor(Settings.Combat.RapidFireMultiplier) - 1)
                for _ = 1, extra do
                    task.wait()
                    task.spawn(function() self:FireServer(table.unpack(args)) end)
                end
                RapidFireActive = false
            end)
            return result
        else
            return self:FireServer(table.unpack(args))
        end
    end

    -- ── NoSpread path ─────────────────────────────────────────────────────
    if not silentAimEnabled and not RapidFireActive then
        local args = {...}
        local origin = (typeof(args[1]) == "Vector3") and args[1] or Camera.CFrame.Position

        if Settings.Combat.NoSpread and not RapidFireActive then
            local target = CurrentTarget  -- from aim system
            if target and target.Parent and #args >= 3 and typeof(args[3]) == "Vector3" then
                args[3] = (target.Position - origin).Unit
            end
        end

        -- Bullet tracer (visual only, no redirect)
        local dir = nil
        if #args >= 3 and typeof(args[3]) == "Vector3" then
            local raw = args[3]
            dir = (raw.Magnitude <= 1.5) and raw or (raw - origin).Unit
        end
        if dir and Settings.Combat.BulletTracers then
            task.spawn(function()
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Exclude
                params.FilterDescendantsInstances = {LocalPlayer.Character}
                local result = workspace:Raycast(origin, dir * 900, params)
                if result and result.Instance then
                    local model = result.Instance:FindFirstAncestorOfClass("Model")
                    local hum   = model and model:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        local isPlayer = false
                        for _, p in ipairs(Players:GetPlayers()) do
                            if p.Character == model then isPlayer = true; break end
                        end
                        if isPlayer then
                            NotifyHit(Players:GetPlayerFromCharacter(model))
                            if Settings.Combat.BulletTracers then DrawTracer(origin, result.Position) end
                        else
                            if Settings.Combat.BulletTracers then DrawTracer(origin, origin + dir * 900) end
                        end
                    end
                end
            end)
        end
    end

    -- ── RapidFire standalone path ─────────────────────────────────────────
    if Settings.Combat.RapidFire and not RapidFireActive then
        local args = {...}
        local result = self:FireServer(table.unpack(args))
        RapidFireActive = true
        task.spawn(function()
            local extra = math.random(1, math.floor(Settings.Combat.RapidFireMultiplier) - 1)
            for _ = 1, extra do
                task.wait()
                task.spawn(function() self:FireServer(table.unpack(args)) end)
            end
            RapidFireActive = false
        end)
        return result
    end

    return self:FireServer(...)
end


-- ── RenderStepped loop (function `h`) ─────────────────────────────────────
-- Runs every frame. Handles: FOV circle, crosshair, camlock aimbot,
-- spinbot, triggerbot, world ESP (players, C4, rockets, deployables,
-- harvestables, sleepers).

local function OnRenderStepped()
    local vp     = Camera.ViewportSize
    local cx, cy = vp.X * 0.5, vp.Y * 0.5
    local camCF  = Camera.CFrame
    local camPos = camCF.Position

    -- FOV circle
    local fovSettings = Settings.FOV
    local fovOrigin   = fovSettings.FollowMouse and UserInputService:GetMouseLocation()
                        or Vector2.new(cx, cy)
    FOVCircle.Position = fovOrigin
    FOVCircle.Radius   = fovSettings.Radius
    FOVCircle.Visible  = fovSettings.Visible
    FOVCircle.Color    = Settings.Aimbot.Active and AimbotActiveColor or fovSettings.Color

    -- Crosshair
    local ch = Settings.Crosshair
    if ch.Enabled then
        local gap, size = ch.Gap, ch.Size
        local col, thick = ch.Color, ch.Thickness
        -- Top line
        CrosshairLines.Top.From      = Vector2.new(cx,       cy - gap)
        CrosshairLines.Top.To        = Vector2.new(cx,       cy - gap - size)
        CrosshairLines.Top.Visible   = true
        CrosshairLines.Top.Color     = col
        CrosshairLines.Top.Thickness = thick
        -- Bottom line
        CrosshairLines.Bottom.From      = Vector2.new(cx,       cy + gap)
        CrosshairLines.Bottom.To        = Vector2.new(cx,       cy + gap + size)
        CrosshairLines.Bottom.Visible   = true
        CrosshairLines.Bottom.Color     = col
        CrosshairLines.Bottom.Thickness = thick
        -- Left line
        CrosshairLines.Left.From      = Vector2.new(cx - gap,       cy)
        CrosshairLines.Left.To        = Vector2.new(cx - gap - size, cy)
        CrosshairLines.Left.Visible   = true
        CrosshairLines.Left.Color     = col
        CrosshairLines.Left.Thickness = thick
        -- Right line
        CrosshairLines.Right.From      = Vector2.new(cx + gap,       cy)
        CrosshairLines.Right.To        = Vector2.new(cx + gap + size, cy)
        CrosshairLines.Right.Visible   = true
        CrosshairLines.Right.Color     = col
        CrosshairLines.Right.Thickness = thick
    else
        CrosshairLines.Top.Visible    = false
        CrosshairLines.Bottom.Visible = false
        CrosshairLines.Left.Visible   = false
        CrosshairLines.Right.Visible  = false
    end

    -- Custom FOV
    if Settings.Exploits.FovChanger then
        Camera.FieldOfView = Settings.Exploits.CustomFov
    end

    -- Update aim target (throttled to 33ms)
    local now = os.clock()
    if now - LastTargetUpdate >= 0.033 then
        LastTargetUpdate = now
        local ab = Settings.Aimbot
        CurrentTarget = (ab.Enabled or ab.Camlock) and FindBestTarget(camPos) or nil
        HasTarget = CurrentTarget ~= nil
    end

    -- Camlock aimbot
    local ab = Settings.Aimbot
    if ab.Camlock and ab.Active and CurrentTarget then
        local targetPos = CurrentTarget.Position
        local hroot = CurrentTarget.Parent and CurrentTarget.Parent:FindFirstChild("HumanoidRootPart")
        if hroot and ab.Prediction > 0 then
            targetPos = targetPos + hroot.AssemblyLinearVelocity * (ab.Prediction * 0.12)
        end
        local lookCF = CFrame.lookAt(camPos, targetPos)
        Camera.CFrame = camCF:Lerp(lookCF, math.clamp(1 - ab.Smoothness, 0.01, 1))
    end

    -- Snapline (target line from screen edge to target)
    local snapline = Settings.Snapline
    if snapline.Enabled and CurrentTarget and CurrentTarget.Parent
        and (ab.Camlock or ab.SilentAim)
    then
        local sp, onScreen = Camera:WorldToViewportPoint(CurrentTarget.Position)
        if onScreen and sp.Z > 0.01 then
            local origin2D = (snapline.Origin == "Center")
                and Vector2.new(cx, cy)
                or  Vector2.new(cx, vp.Y)
            SnapLine.Visible     = true
            SnapLine.Color       = snapline.Color
            SnapLine.Thickness   = snapline.Thickness
            SnapLine.Transparency = snapline.Transparency
            SnapLine.From        = origin2D
            SnapLine.To          = Vector2.new(sp.X, sp.Y)
        else
            SnapLine.Visible = false
        end
    else
        SnapLine.Visible = false
    end

    -- Spinbot
    if Settings.Exploits.Spinbot and LocalPlayer.Character then
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root and not Settings.Exploits.Freecam then
            local speed = (Settings.Exploits.SpinbotSpeed or 25) * 10
            local yaw   = (os.clock() * speed) % 360
            local pitch = 0
            if Settings.Exploits.SpinbotPitch == "Down" then
                pitch = -1.3089969389957472  -- ~-75 deg
            elseif Settings.Exploits.SpinbotPitch == "Jitter" then
                pitch = math.rad(math.random() > 0.5 and 65 or -75)
            end
            root.CFrame = CFrame.new(root.Position)
                * CFrame.Angles(0, math.rad(yaw), 0)
                * CFrame.Angles(pitch, 0, 0)
        end
    end

    -- Triggerbot
    if Settings.Combat.Triggerbot and GunFireRemote then
        local screenCenter = vp * 0.5
        local ray = Camera:ViewportPointToRay(screenCenter.X, screenCenter.Y)
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = {LocalPlayer.Character}
        local hit = workspace:Raycast(ray.Origin, ray.Direction * 800, params)
        if hit and hit.Instance then
            local model = hit.Instance:FindFirstAncestorOfClass("Model")
            if model and model ~= LocalPlayer.Character and IsEnemy(model) then
                local hum   = model:FindFirstChildOfClass("Humanoid")
                local hroot = model:FindFirstChild("HumanoidRootPart")
                if hum and hroot then
                    local t = os.clock()
                    _G.__lastTriggerbotFire = _G.__lastTriggerbotFire or 0
                    local delay = Settings.Combat.TriggerbotDelay or 0.05
                    if t - _G.__lastTriggerbotFire >= delay then
                        _G.__lastTriggerbotFire = t
                        task.spawn(function()
                            task.spawn(function()
                                GunFireRemote:FireServer(
                                    ray.Origin,
                                    hit.Position,
                                    (hit.Position - ray.Origin).Unit
                                )
                            end)
                        end)
                    end
                end
            end
        end
    end

    -- World ESP (players)
    local worldESP = Settings.WorldESP
    if worldESP.Enabled and worldESP.Players then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local head = player.Character:FindFirstChild("Head")
                local hum  = player.Character:FindFirstChildOfClass("Humanoid")
                if head and hum then
                    DrawPlayerESP(player, head.Position, hum)
                end
            else
                RemovePlayerESP(player.UserId or player.Name)
            end
        end
    else
        ClearAllESP()
    end

    -- World ESP: Placed C4
    local drawnThisFrame = {}
    if worldESP.PlacedC4 then
        local c4folder = workspace:FindFirstChild("PlacedC4")
        local t = os.clock()
        if c4folder then
            for _, obj in ipairs(c4folder:GetChildren()) do
                local pos = obj:IsA("BasePart") and obj.Position
                    or (obj.PrimaryPart and obj.PrimaryPart.Position)
                if pos then
                    local id = "c4_" .. obj:GetDebugId()
                    if not C4Cache[id] then
                        C4Cache[id] = { pos = pos, expireAt = t + 30 }
                        if worldESP.PlacedC4Alert then
                            local dist = (pos - camPos).Magnitude
                            PlayAlert(dist * 0.28)
                        end
                    else
                        C4Cache[id].pos = pos
                    end
                end
            end
        end
        for id, data in pairs(C4Cache) do
            local remaining = data.expireAt - t
            if remaining > 0 then
                drawnThisFrame[id] = true
                local dist = math.floor((data.pos - camPos).Magnitude)
                local label = string.format("C4 [%d STUDS | %.1fs]", dist, remaining)
                DrawWorldLabel(id, data.pos, label, Color3.fromRGB(255, 60, 60))
            else
                C4Cache[id] = nil
                HideWorldLabel(id)
            end
        end
    end

    -- World ESP: Rockets
    if worldESP.Rockets then
        -- (rocket spot tracking omitted for brevity — same pattern as C4)
    end

    -- World ESP: Deployables (turrets, storage, beds, barricades, etc.)
    local deployFolder = workspace:FindFirstChild("PlacedDeployables")
    if deployFolder then
        for _, obj in ipairs(deployFolder:GetChildren()) do
            local pos = obj:IsA("BasePart") and obj.Position
                or (obj.PrimaryPart and obj.PrimaryPart.Position)
            if pos then
                local dist = math.floor((pos - camPos).Magnitude)
                local id   = "dep_" .. obj:GetDebugId()
                local kind = obj.Name  -- "Turret", "Storage", "Bed", "Barricade", etc.
                if kind == "Turret" and worldESP.Turrets then
                    drawnThisFrame[id] = true
                    DrawWorldLabel(id, pos, obj.Name .. " [" .. dist .. " STUDS]", Color3.fromRGB(244, 63, 94))
                elseif kind == "Storage" and worldESP.StorageBoxes then
                    drawnThisFrame[id] = true
                    DrawWorldLabel(id, pos, obj.Name .. " [" .. dist .. " STUDS]", Color3.fromRGB(245, 158, 11))
                elseif kind == "Bed" and worldESP.SleepingBags then
                    drawnThisFrame[id] = true
                    DrawWorldLabel(id, pos, obj.Name .. " [" .. dist .. " STUDS]", Color3.fromRGB(99, 102, 241))
                elseif kind == "Barricade" and worldESP.Barricades then
                    drawnThisFrame[id] = true
                    DrawWorldLabel(id, pos, obj.Name .. " [" .. dist .. " STUDS]", Color3.fromRGB(168, 85, 247))
                elseif (kind == "Special" or kind == "Other") and worldESP.OtherDeployables then
                    drawnThisFrame[id] = true
                    DrawWorldLabel(id, pos, obj.Name .. " [" .. dist .. " STUDS]", Color3.fromRGB(56, 189, 248))
                end
            end
        end
    end

    -- World ESP: Harvestables
    if worldESP.Harvestables then
        local harvestFolder = workspace:FindFirstChild("SpawnedHarvestables")
        if harvestFolder then
            for _, obj in ipairs(harvestFolder:GetChildren()) do
                local pos = obj:IsA("BasePart") and obj.Position
                    or (obj.PrimaryPart and obj.PrimaryPart.Position)
                if pos then
                    local id   = "harv_" .. obj:GetDebugId()
                    drawnThisFrame[id] = true
                    local dist  = math.floor((pos - camPos).Magnitude)
                    local color = Color3.fromRGB(100, 220, 100)
                    if obj.Name:find("Ore") or obj.Name == "Stone" then
                        color = Color3.fromRGB(250, 204, 21)
                    end
                    DrawWorldLabel(id, pos, obj.Name .. " [" .. dist .. " STUDS]", color)
                end
            end
        end
    end

    -- World ESP: Sleepers
    if worldESP.Sleepers then
        local sleeperFolder = workspace:FindFirstChild("OfflineSleepers")
        if sleeperFolder then
            for _, obj in ipairs(sleeperFolder:GetChildren()) do
                local pos = obj:IsA("BasePart") and obj.Position
                    or (obj.PrimaryPart and obj.PrimaryPart.Position)
                if pos then
                    local id   = "slp_" .. obj:GetDebugId()
                    drawnThisFrame[id] = true
                    local dist = math.floor((pos - camPos).Magnitude)
                    DrawWorldLabel(id, pos, "SLEEPER: " .. obj.Name .. " [" .. dist .. " STUDS]",
                        Color3.fromRGB(170, 170, 180))
                end
            end
        end
    end

    -- Hide labels no longer drawn this frame
    for id, data in pairs(WorldLabelCache) do
        if not drawnThisFrame[id] then
            if data.Label then data.Label.Visible = false end
        end
    end
end
