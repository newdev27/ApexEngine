
--Apex Engine UI library designed and developed by Barlas discord: 5nqs
 

local Icons = {
    crosshairs = "rbxassetid://96677288280405",
    ghost      = "rbxassetid://95400397758754",
    mouse      = "rbxassetid://74350468513068",
    user       = "rbxassetid://97066657594742",
    pallet     = "rbxassetid://83365140694071",
    hammer     = "rbxassetid://118512898552101",
    code       = "rbxassetid://100793810819046",
    save       = "rbxassetid://136566823798983",
    feather    = "rbxassetid://130188814728078",
    crown      = "rbxassetid://73317911385704",
    dagger     = "rbxassetid://133081986539088",
    baby       = "rbxassetid://127135446273067",
    ad         = "rbxassetid://134916447199398",
    axe_battle = "rbxassetid://91285868461583",
    avatar     = "rbxassetid://0",
}

local FontURLs = {
    FontAwesome = "https://raw.githubusercontent.com/B5RLAS/ApexEngine/main/Font/FontAwesome.ttf",
    Museo500    = "https://raw.githubusercontent.com/B5RLAS/ApexEngine/main/Font/Museo500.ttf",
    Museo900    = "https://raw.githubusercontent.com/B5RLAS/ApexEngine/main/Font/Museo900.ttf",
}

local function LoadFont(name)
    local ok, result = pcall(function()
        local folder = "ApexEngine"
        if isfolder and not isfolder(folder) then makefolder(folder) end
        local ttf = folder .. "/" .. name .. ".ttf"
        if not (isfile and isfile(ttf)) then
            writefile(ttf, game:HttpGet(FontURLs[name]))
        end
        local json = folder .. "/" .. name .. ".json"
        writefile(json, game:GetService("HttpService"):JSONEncode({
            name = name,
            faces = { { name = "Regular", weight = 400, style = "normal", assetId = getcustomasset(ttf) } },
        }))
        return Font.new(getcustomasset(json), Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    end)
    if ok then return result end
    warn("[ApexEngine] font load failed (" .. name .. "): " .. tostring(result))
    return nil
end

local Fonts = {
    Museo500    = LoadFont("Museo500"),
    Museo900    = LoadFont("Museo900"),
    FontAwesome = LoadFont("FontAwesome"),
}

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local LocalPlayer      = Players.LocalPlayer

local function rgbf(r, g, b) return Color3.new(r, g, b) end
local Theme = {
    Accent        = rgbf(0.30, 0.49, 1.00),
    Text          = rgbf(1, 1, 1),
    TextDisabled  = rgbf(0.51, 0.52, 0.56),
    Border        = rgbf(1, 1, 1),  BorderTransparency = 0.97,
    FrameInactive = rgbf(0.023, 0.039, 0.070),
    FrameActive   = rgbf(0.043, 0.070, 0.137),
    Button        = rgbf(0.031, 0.035, 0.058),
    ButtonHovered = rgbf(0.050, 0.054, 0.078),
    ButtonActive  = rgbf(0.070, 0.074, 0.098),
    GroupBoxBg    = rgbf(0.019, 0.035, 0.062),
    WindowBg      = Color3.fromRGB(2, 2, 2),
    Font          = Fonts.Museo500 or Enum.Font.GothamMedium,
    FontBold      = Fonts.Museo900 or Enum.Font.GothamBlack,
    TextSize      = 13,
}

local function New(class, props, children)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k == "Font" and typeof(v) == "Font" then
            o.FontFace = v
        elseif k ~= "Parent" then
            o[k] = v
        end
    end
    for _, c in ipairs(children or {}) do c.Parent = o end
    if props and props.Parent then o.Parent = props.Parent end
    return o
end

local function Corner(r) return New("UICorner", { CornerRadius = UDim.new(0, r) }) end
local function Stroke(color, trans)
    return New("UIStroke", {
        Color = color or Theme.Border,
        Transparency = trans or Theme.BorderTransparency,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Thickness = 1,
    })
end

local function Tween(obj, t, props, style)
    if t == 0 then for k, v in pairs(props) do obj[k] = v end return end
    local tw = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

local function Label(props)
    props.BackgroundTransparency = 1
    props.Font = props.Font or Theme.Font
    props.TextSize = props.TextSize or Theme.TextSize
    props.TextColor3 = props.TextColor3 or Theme.Text
    props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
    return New("TextLabel", props)
end

local function Icon(id, size, color, props)
    props = props or {}
    props.BackgroundTransparency = 1
    props.Image = id or ""
    props.ImageColor3 = color or Theme.Accent
    props.Size = UDim2.fromOffset(size, size)
    props.ScaleType = Enum.ScaleType.Fit
    return New("ImageLabel", props)
end

local function GetParentGui()
    local ok, hui = pcall(function() return gethui and gethui() end)
    if ok and hui then return hui end
    local ok2, core = pcall(function() return game:GetService("CoreGui") end)
    if ok2 and core then
        local test = pcall(function() local f = Instance.new("Folder"); f.Parent = core; f:Destroy() end)
        if test then return core end
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- Key System
local HttpService = game:GetService("HttpService")
local KEY_FILE    = "ApexEngine/key.dat"
local HWID_FILE   = "ApexEngine/hwid.dat"
local KEYS_URL    = "https://raw.githubusercontent.com/newdev27/ApexEngine/main/Apex%20Engine/keys.json"
local BIND_URL    = "https://api.github.com/repos/newdev27/ApexEngine/contents/Apex%20Engine/keys.json"
local SALT        = "AX_br27_$3cr3t_2k25"

-- HWID fingerprint
local function getHWID()
    local ok, id = pcall(function() return tostring(game:GetService("RbxAnalyticsService"):GetClientId()) end)
    return (ok and id or "unknown") .. "_" .. tostring(LocalPlayer.UserId)
end

local function readFile(path)
    if isfile and isfile(path) then return readfile(path) end
    return nil
end

local function writeFile(path, data)
    if writefile then writefile(path, data) end
end

-- Check 1: key format must match APEX-XXXXXX-XXXXXX-XX exactly
local function validFormat(key)
    return key ~= nil and type(key) == "string"
        and key:match("^APEX%-[A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9]%-[A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9]%-[A-Z0-9][A-Z0-9]$") ~= nil
end

-- Check 2: tier code in first 2 chars of seg1 must be valid
local VALID_TIER_CODES = { MN=true, HR=true, DY=true, FR=true, WK=true, MO=true, YR=true, LT=true }
local function validTierCode(key)
    local code = key:sub(6, 7)
    return VALID_TIER_CODES[code] == true
end

-- Check 3: checksum verification using salt
local CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
local function verifyChecksum(key)
    local body     = key:sub(1, -4)  -- everything before last -XX
    local expected = key:sub(-2)
    local hash     = 5381
    local str      = body .. SALT
    for i = 1, #str do
        hash = ((hash * 33) + string.byte(str, i)) % 1048576
    end
    local c1 = CHARS:sub((hash % #CHARS) + 1, (hash % #CHARS) + 1)
    local c2 = CHARS:sub(((math.floor(hash / #CHARS)) % #CHARS) + 1, ((math.floor(hash / #CHARS)) % #CHARS) + 1)
    return (c1 .. c2) == expected
end

-- Check 4: fetch keys from server
local function fetchKeys()
    local ok, res = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(KEYS_URL .. "?t=" .. tostring(os.time())))
    end)
    if ok and res and res.keys then return res.keys end
    return nil
end

-- Check 5: expiry check against server timestamp
local function isExpired(entry)
    if entry.expires_at == nil or entry.expires_at == false then return false end
    return os.time() > entry.expires_at
end

local KeySystem = {}

function KeySystem:Validate(inputKey)
    -- Sanitize input
    inputKey = tostring(inputKey or ""):upper():gsub("%s", "")

    -- Check 1: format
    if not validFormat(inputKey) then
        return false, "Invalid key format."
    end

    -- Check 2: tier code
    if not validTierCode(inputKey) then
        return false, "Invalid key format."
    end

    -- Check 3: checksum (anti-spoof)
    if not verifyChecksum(inputKey) then
        return false, "Invalid key."
    end

    -- Check 4: exists on server
    local keys = fetchKeys()
    if not keys then
        return false, "Could not reach key server. Check your connection."
    end
    local entry = keys[inputKey]
    if not entry then
        return false, "Key not found."
    end

    -- Check 5: blocked
    if entry.blocked then
        return false, "This key has been revoked."
    end

    -- Check 6: expiry
    if isExpired(entry) then
        return false, "Key expired. Renew at discord.gg/apexengine"
    end

    -- Check 7: HWID
    local hwid = getHWID()
    if entry.hwid ~= nil and entry.hwid ~= "" and entry.hwid ~= hwid then
        -- HWID mismatch = shared key, block it immediately
        pcall(function()
            -- signal backend to block (Discord bot will handle the actual JSON update)
            game:HttpGet("https://raw.githubusercontent.com/newdev27/ApexEngine/main/Apex%20Engine/keys.json?block=" .. inputKey)
        end)
        return false, "Key is locked to another device. Key has been flagged."
    end

    -- First use: bind HWID
    if entry.hwid == nil or entry.hwid == "" then
        pcall(function()
            game:HttpGet("https://raw.githubusercontent.com/newdev27/ApexEngine/main/Apex%20Engine/keys.json?bind=" .. inputKey .. "&hwid=" .. hwid)
        end)
    end

    -- Save locally
    writeFile(KEY_FILE, inputKey)
    writeFile(HWID_FILE, hwid)
    return true, "OK", entry
end

function KeySystem:GetSaved()
    local key  = readFile(KEY_FILE)
    local hwid = readFile(HWID_FILE)
    if key and hwid and hwid == getHWID() then
        return key
    end
    -- Clear mismatched files
    writeFile(KEY_FILE, "")
    writeFile(HWID_FILE, "")
    return nil
end

local ApexEngine = { Flags = {}, Icons = Icons, Theme = Theme, ToggleKey = Enum.KeyCode.Insert }
ApexEngine.__index = ApexEngine

-- Shared input routing to avoid per-widget UIS connections
local _sliders = {}
local _colorModes = {}
UserInputService.InputChanged:Connect(function(i)
    local t = i.UserInputType
    if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
        for _, fn in ipairs(_sliders) do fn(i.Position.X) end
        for _, fn in ipairs(_colorModes) do fn(i.Position) end
    end
end)
UserInputService.InputEnded:Connect(function(i)
    local t = i.UserInputType
    if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
        for _, fn in ipairs(_sliders) do fn(nil) end
        for _, fn in ipairs(_colorModes) do fn(nil) end
    end
end)

function ApexEngine:CreateWindow(cfg)
    cfg = cfg or {}

    -- Key gate
    local authed = false
    local savedKey = KeySystem:GetSaved()
    if savedKey then
        local ok, msg, entry = KeySystem:Validate(savedKey)
        authed = ok
        if ok and entry then
            cfg.Tier      = entry.tier
            cfg.ExpiresAt = entry.expires_at
        end
        if not ok then warn("[ApexEngine] Saved key rejected: " .. msg) end
    end

    if not authed then
        local done = false
        local keyGui = New("ScreenGui", {
            Name = "ApexEngineKey", ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Global, IgnoreGuiInset = true,
            Parent = GetParentGui(),
        })
        local bg = New("Frame", {
            Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0,0,0),
            BackgroundTransparency = 0.4, BorderSizePixel = 0, Active = false, Parent = keyGui,
        })
        local box = New("Frame", {
            Size = UDim2.fromOffset(340, 160), AnchorPoint = Vector2.new(.5,.5),
            Position = UDim2.fromScale(.5,.5), BackgroundColor3 = Theme.WindowBg,
            BorderSizePixel = 0, Parent = keyGui,
        }, { Corner(8), Stroke() })
        Label({ Text = "APEX ENGINE", Font = Theme.FontBold, TextSize = 20,
            TextColor3 = Theme.Accent, TextXAlignment = Enum.TextXAlignment.Center,
            Size = UDim2.new(1,0,0,30), Position = UDim2.fromOffset(0,16), Parent = box })
        Label({ Text = "Enter your key to continue", TextColor3 = Theme.TextDisabled,
            TextXAlignment = Enum.TextXAlignment.Center,
            Size = UDim2.new(1,0,0,16), Position = UDim2.fromOffset(0,48), Parent = box })
        local inputFrame = New("Frame", {
            Size = UDim2.fromOffset(280, 28), Position = UDim2.fromOffset(30, 74),
            BackgroundColor3 = Theme.FrameInactive, BorderSizePixel = 0, Parent = box,
        }, { Corner(4), Stroke() })
        local tb = New("TextBox", {
            Size = UDim2.new(1,-10,1,0), Position = UDim2.fromOffset(5,0),
            BackgroundTransparency = 1, PlaceholderText = "APEX-XXXX-XXXX-XXXX",
            Text = "", ClearTextOnFocus = false, Font = Theme.Font,
            TextSize = Theme.TextSize, TextColor3 = Theme.Text,
            PlaceholderColor3 = Theme.TextDisabled,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = inputFrame,
        })
        local statusLbl = Label({ Text = "", TextColor3 = Color3.fromRGB(255,80,80),
            TextXAlignment = Enum.TextXAlignment.Center,
            Size = UDim2.new(1,0,0,14), Position = UDim2.fromOffset(0,108), Parent = box })
        local submitBtn = New("TextButton", {
            Size = UDim2.fromOffset(80, 28), Position = UDim2.fromOffset(230, 74),
            BackgroundColor3 = Theme.Accent, AutoButtonColor = false,
            Text = "Submit", Font = Theme.FontBold, TextSize = 13,
            TextColor3 = Color3.new(1,1,1), Visible = false, Parent = box,
        }, { Corner(4) })
        -- show button when text entered
        tb:GetPropertyChangedSignal("Text"):Connect(function()
            local hasText = #tb.Text > 0
            submitBtn.Visible = hasText
            inputFrame.Size = hasText and UDim2.fromOffset(190, 28) or UDim2.fromOffset(280, 28)
        end)
        submitBtn.MouseButton1Click:Connect(function()
            statusLbl.Text = "Checking..."
            statusLbl.TextColor3 = Theme.TextDisabled
            task.spawn(function()
                local ok, msg, entry = KeySystem:Validate(tb.Text)
                if ok then
                    authed = true
                    done = true
                    if entry then
                        cfg.Tier      = entry.tier
                        cfg.ExpiresAt = entry.expires_at
                    end
                    keyGui:Destroy()
                    StartGameLogic()
                else
                    statusLbl.Text = msg
                    statusLbl.TextColor3 = Color3.fromRGB(255, 80, 80)
                    Tween(box, .06, { Position = UDim2.new(.5,-5,.5,0) })
                    task.wait(.06)
                    Tween(box, .06, { Position = UDim2.new(.5, 5,.5,0) })
                    task.wait(.06)
                    Tween(box, .06, { Position = UDim2.fromScale(.5,.5) })
                end
            end)
        end)
        -- wait until authed
        repeat task.wait(0.1) until done
    end

    local Window = { Tabs = {}, CurrentTab = nil }

    local gui = New("ScreenGui", {
        Name = "ApexEngineUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        IgnoreGuiInset = true,
        Parent = GetParentGui(),
    })
    Window.Gui = gui

    local blur = New("BlurEffect", { Size = 0, Name = "ApexEngineBlur", Parent = Lighting })
    Tween(blur, 0.4, { Size = cfg.Blur or 12 })

    local main = New("Frame", {
        Name = "Main",
        Size = UDim2.fromOffset(690, 500),
        Position = UDim2.new(0.5, -345, 0.5, -250),
        BackgroundTransparency = 1,
        Parent = gui,
    })
    Window.Main = main

    local function Panel(x, y, w, h, ox, oy, ew, eh, alpha)
        local clip = New("Frame", {
            Size = UDim2.fromOffset(w, h), Position = UDim2.fromOffset(x, y),
            BackgroundTransparency = 1, ClipsDescendants = true, BorderSizePixel = 0, Parent = main,
        })
        New("Frame", {
            Size = UDim2.fromOffset(w + ew, h + eh), Position = UDim2.fromOffset(ox, oy),
            BackgroundColor3 = Theme.WindowBg, BackgroundTransparency = alpha, BorderSizePixel = 0, Parent = clip,
        }, { Corner(8) })
        return clip
    end

    Panel(0, 0, 170, 500, 0, 0, 10, 0, 0.1)
    local topbar = Panel(170, 0, 520, 60, -10, 0, 10, 10, 0.05)
    New("Frame", { Size = UDim2.fromOffset(520, 1), Position = UDim2.fromOffset(170, 60), BackgroundColor3 = Theme.WindowBg, BackgroundTransparency = 0.1, BorderSizePixel = 0, Parent = main })
    Panel(170, 61, 520, 439, -10, -10, 10, 10, 0)

    local title = cfg.Title or "APEX ENGINE"
    Label({ Text = title, Font = Theme.FontBold, TextSize = 26, TextColor3 = Theme.Accent,
        TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.fromOffset(170, 30), Position = UDim2.fromOffset(15, 17), Parent = main })
    Label({ Text = title, Font = Theme.FontBold, TextSize = 26, TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.fromOffset(170, 30), Position = UDim2.fromOffset(14, 17), Parent = main })

    New("Frame", { Size = UDim2.fromOffset(170, 1), Position = UDim2.fromOffset(0, 450),
        BackgroundColor3 = Theme.WindowBg, BackgroundTransparency = 0.5, BorderSizePixel = 0, Parent = main })
    local av = New("ImageLabel", {
        Size = UDim2.fromOffset(30, 30), Position = UDim2.fromOffset(15, 460),
        BackgroundColor3 = Theme.FrameActive, Image = "", Parent = main,
    }, { Corner(100) })
    pcall(function()
        av.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
    end)
    Label({ Text = LocalPlayer.DisplayName, Size = UDim2.fromOffset(115, 14), Position = UDim2.fromOffset(50, 460), Parent = main })
    Label({ Text = "License:", TextColor3 = Theme.TextDisabled, Size = UDim2.fromOffset(50, 14), Position = UDim2.fromOffset(50, 475), Parent = main })
    local licLbl = Label({ Text = "...", TextColor3 = Theme.Accent, Size = UDim2.fromOffset(90, 14), Position = UDim2.fromOffset(102, 475), Parent = main })
    local function updateLicLabel()
        local expiresAt = cfg.ExpiresAt
        local tier = (cfg.Tier or "LT"):upper()
        if tier == "LT" then licLbl.Text = "Lifetime"
        elseif tier == "FR" then licLbl.Text = "Free"
        elseif expiresAt and type(expiresAt) == "number" then
            local left = math.max(0, expiresAt - os.time())
            if left == 0 then licLbl.Text = "Expired"; licLbl.TextColor3 = Color3.fromRGB(255,80,80); return end
            local d = math.floor(left/86400)
            local h = math.floor((left%86400)/3600)
            local m = math.floor((left%3600)/60)
            local s = left%60
            if d > 0 then licLbl.Text = d.."d "..h.."h"
            elseif h > 0 then licLbl.Text = h.."h "..m.."m"
            else licLbl.Text = m.."m "..s.."s" end
        else licLbl.Text = tier end
    end
    updateLicLabel()
    game:GetService("RunService").Heartbeat:Connect(updateLicLabel)

    local tabList = New("Frame", {
        Size = UDim2.fromOffset(150, 380), Position = UDim2.fromOffset(10, 70),
        BackgroundTransparency = 1, Parent = main,
    }, { New("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }) })
    local order = 0
    local function nextOrder() order += 1 return order end

    local saveBtn = New("TextButton", {
        Size = UDim2.fromOffset(100, 25), Position = UDim2.fromOffset(190, 20),
        BackgroundColor3 = Theme.Button, AutoButtonColor = false, Text = "", Parent = main,
    }, { Corner(4), Stroke() })
    local saveIcon = Icon(Icons.save, 12, Theme.TextDisabled, { Position = UDim2.fromOffset(24, 6), Parent = saveBtn })
    local saveTxt = Label({ Text = "Save", TextColor3 = Theme.TextDisabled, Size = UDim2.fromOffset(50, 25), Position = UDim2.fromOffset(42, 0), Parent = saveBtn })
    saveBtn.MouseEnter:Connect(function() Tween(saveBtn, .15, { BackgroundColor3 = Theme.ButtonHovered }); saveTxt.TextColor3 = Theme.Text; saveIcon.ImageColor3 = Theme.Text end)
    saveBtn.MouseLeave:Connect(function() Tween(saveBtn, .15, { BackgroundColor3 = Theme.Button }); saveTxt.TextColor3 = Theme.TextDisabled; saveIcon.ImageColor3 = Theme.TextDisabled end)
    saveBtn.MouseButton1Down:Connect(function() Tween(saveBtn, .1, { BackgroundColor3 = Theme.ButtonActive }) end)
    saveBtn.MouseButton1Up:Connect(function() Tween(saveBtn, .1, { BackgroundColor3 = Theme.ButtonHovered }) end)
    saveBtn.MouseButton1Click:Connect(function() if cfg.OnSave then cfg.OnSave(ApexEngine.Flags) end end)

    local subHolder = New("Frame", { Size = UDim2.fromOffset(240, 25), Position = UDim2.fromOffset(300, 20), BackgroundTransparency = 1, Parent = main })

    local pageHolder = New("Frame", {
        Size = UDim2.fromOffset(490, 404), Position = UDim2.fromOffset(185, 81),
        BackgroundTransparency = 1, ClipsDescendants = true, Parent = main,
    })
    local fade = New("CanvasGroup", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = pageHolder })

    local function animatePage()
        fade.GroupTransparency = 1
        pageHolder.Position = UDim2.fromOffset(185, 81)
        Tween(fade, 0.35, { GroupTransparency = 0 })
        Tween(pageHolder, 0.35, { Position = UDim2.fromOffset(185, 76) })
    end
    Window.Animate = animatePage

    do
        local dragging, dragStart, startPos
        local dragArea = New("Frame", { Size = UDim2.fromOffset(170, 60), BackgroundTransparency = 1, Parent = main })
        local function begin(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging, dragStart, startPos = true, input.Position, main.Position
                input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
            end
        end
        dragArea.InputBegan:Connect(begin)
        topbar.InputBegan:Connect(begin)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local d = input.Position - dragStart
                main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end)
    end

    UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and input.KeyCode == ApexEngine.ToggleKey then
            main.Visible = not main.Visible
            Tween(blur, 0.3, { Size = main.Visible and (cfg.Blur or 12) or 0 })
        end
    end)

    function Window:AddCategory(name)
        if order > 0 then
            New("Frame", { Size = UDim2.fromOffset(150, 8), BackgroundTransparency = 1, LayoutOrder = nextOrder(), Parent = tabList })
        end
        local t = Label({ Text = name, TextTransparency = 0.5, Size = UDim2.fromOffset(150, 16),
            LayoutOrder = nextOrder(), Parent = tabList })
        New("UIPadding", { PaddingLeft = UDim.new(0, 10), Parent = t })
    end

    function Window:AddTab(name, icon)
        local Tab = { Subtabs = {}, Current = nil }

        local btn = New("TextButton", {
            Size = UDim2.fromOffset(150, 30), BackgroundColor3 = Theme.FrameActive, BackgroundTransparency = 1,
            AutoButtonColor = false, Text = "", LayoutOrder = nextOrder(), Parent = tabList,
        }, { Corner(5) })
        Icon(icon or "", 14, Theme.Accent, { Position = UDim2.fromOffset(10, 8), Parent = btn })
        Label({ Text = name, Size = UDim2.fromOffset(110, 30), Position = UDim2.fromOffset(35, 0), Parent = btn })

        local subBar = New("Frame", {
            Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Button, Visible = false, Parent = subHolder,
        }, { Corner(4), Stroke(), New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder }) })

        Tab.Button, Tab.SubBar = btn, subBar

        local function layoutSubs()
            local n = #Tab.Subtabs
            subBar.Visible = n > 0 and Window.CurrentTab == Tab
            for _, s in ipairs(Tab.Subtabs) do s.Button.Size = UDim2.new(1 / math.max(n, 1), 0, 1, 0) end
        end

        function Tab:Select()
            if Window.CurrentTab == Tab then return end
            for _, t in ipairs(Window.Tabs) do
                Tween(t.Button, .3, { BackgroundTransparency = 1 })
                t.SubBar.Visible = false
                for _, s in ipairs(t.Subtabs) do s.Page.Visible = false end
            end
            Window.CurrentTab = Tab
            Tween(btn, .3, { BackgroundTransparency = 0.5 })
            layoutSubs()
            if Tab.Current then Tab.Current.Page.Visible = true elseif Tab.Subtabs[1] then Tab.Subtabs[1]:Select() end
            animatePage()
        end
        btn.MouseButton1Click:Connect(function() Tab:Select() end)

        function Tab:AddSubtab(sname)
            local Sub = {}
            local sb = New("TextButton", {
                BackgroundColor3 = Theme.FrameActive, BackgroundTransparency = 1, AutoButtonColor = false,
                Text = sname, Font = Theme.Font, TextSize = Theme.TextSize, TextColor3 = Theme.TextDisabled,
                LayoutOrder = #Tab.Subtabs + 1, Parent = subBar,
            }, { Corner(4) })

            local page = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = fade })
            local function column(x)
                return New("ScrollingFrame", {
                    Size = UDim2.fromOffset(241, 404), Position = UDim2.fromOffset(x, 0),
                    BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0,
                    CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = page,
                }, { New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })
            end
            Sub.Left, Sub.Right = column(0), column(249)
            Sub.Button, Sub.Page = sb, page

            function Sub:Select()
                for _, s in ipairs(Tab.Subtabs) do
                    s.Page.Visible = false
                    Tween(s.Button, .3, { BackgroundTransparency = 1 })
                    s.Button.TextColor3 = Theme.TextDisabled
                end
                Tab.Current = Sub
                page.Visible = true
                Tween(sb, .3, { BackgroundTransparency = 0.2 })
                sb.TextColor3 = Theme.Text
                animatePage()
            end
            sb.MouseButton1Click:Connect(function() Sub:Select() end)

            local groupCount = 0
            function Sub:AddGroup(gname, gicon, side, height)
                local col = (side == "Right") and Sub.Right or Sub.Left
                local G = {}
                groupCount += 1
                local holder = New("Frame", {
                    Size = UDim2.fromOffset(241, height or 404), BackgroundTransparency = 1,
                    LayoutOrder = groupCount, Parent = col,
                })
                local tx = 12
                if gicon then
                    Icon(gicon, 12, Theme.Text, { Position = UDim2.fromOffset(12, 2), ImageTransparency = 0.5, Parent = holder })
                    tx = 28
                end
                Label({ Text = gname, TextTransparency = 0.5, Size = UDim2.fromOffset(200, 16), Position = UDim2.fromOffset(tx, 0), Parent = holder })
                local box = New("Frame", {
                    Size = UDim2.new(1, 0, 1, -20), Position = UDim2.fromOffset(0, 20),
                    BackgroundColor3 = Theme.GroupBoxBg, BorderSizePixel = 0, Parent = holder,
                }, { Corner(6), Stroke() })
                local list = New("ScrollingFrame", {
                    Size = UDim2.new(1, -24, 1, -1), Position = UDim2.fromOffset(12, 1),
                    BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0,
                    CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = box,
                }, {
                    New("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
                    New("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) }),
                })
                local n = 0
                local function row(h)
                    n += 1
                    return New("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, LayoutOrder = n, Parent = list })
                end
                local function flag(f, v) if f then ApexEngine.Flags[f] = v end end

                function G:AddCheckbox(o)
                    o = type(o) == "string" and { Name = o } or o
                    local state = o.Default or false
                    local r = row(17)
                    local lbl = Label({ Text = o.Name, Size = UDim2.new(1, -40, 1, 0), TextColor3 = state and Theme.Text or Theme.TextDisabled, Parent = r })
                    if o.Icon then
                        Icon(o.Icon, 12, lbl.TextColor3, { Position = UDim2.fromOffset(lbl.TextBounds.X + 4, 2), Parent = r })
                    end
                    local sw = New("TextButton", {
                        Size = UDim2.fromOffset(30, 17), Position = UDim2.new(1, -30, 0, 0),
                        BackgroundColor3 = Theme.FrameInactive, AutoButtonColor = false, Text = "", Parent = r,
                    }, { Corner(10), Stroke() })
                    local knob = New("Frame", {
                        Size = UDim2.fromOffset(14, 14), AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.new(0, 8, 0.5, 0), BackgroundColor3 = Theme.TextDisabled, Parent = sw,
                    }, { Corner(7) })
                    local obj = {}
                    function obj:Set(v)
                        state = v
                        Tween(sw, .25, { BackgroundColor3 = v and Theme.FrameActive or Theme.FrameInactive })
                        Tween(knob, .25, { Position = UDim2.new(0, v and 22 or 8, 0.5, 0), BackgroundColor3 = v and Theme.Accent or Theme.TextDisabled })
                        lbl.TextColor3 = v and Theme.Text or Theme.TextDisabled
                        flag(o.Flag, v)
                        if o.Callback then task.spawn(o.Callback, v) end
                    end
                    function obj:Get() return state end
                    sw.MouseButton1Click:Connect(function() obj:Set(not state) end)
                    if state then sw.BackgroundColor3 = Theme.FrameActive; knob.Position = UDim2.new(0, 22, 0.5, 0); knob.BackgroundColor3 = Theme.Accent end
                    flag(o.Flag, state)
                    return obj
                end

                function G:AddSlider(o)
                    local min, max = o.Min or 0, o.Max or 100
                    local val = math.clamp(o.Default or min, min, max)
                    local suffix = o.Suffix or ""
                    local r = row(16)
                    Label({ Text = o.Name, TextColor3 = Theme.TextDisabled, Size = UDim2.new(1, -135, 1, 0), Parent = r })
                    local bar = New("TextButton", {
                        Size = UDim2.fromOffset(92, 4), Position = UDim2.new(1, -130, 0, 6),
                        BackgroundColor3 = Theme.FrameActive, AutoButtonColor = false, Text = "", Parent = r,
                    }, { Corner(5) })
                    local fill = New("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = bar }, { Corner(5) })
                    local grab = New("Frame", {
                        Size = UDim2.fromOffset(12, 12), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, -2, 0.5, 0),
                        BackgroundColor3 = Theme.Accent, Parent = bar,
                    }, { Corner(6) })
                    local box = New("Frame", {
                        Size = UDim2.fromOffset(30, 17), Position = UDim2.new(1, -30, 0, 1),
                        BackgroundColor3 = Theme.FrameInactive, Parent = r,
                    }, { Corner(4), Stroke() })
                    local vt = Label({ Text = "", TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = box })
                    local obj = {}
                    function obj:Set(v, instant)
                        v = math.clamp(v, min, max)
                        if not o.Decimals then v = math.floor(v + 0.5) else v = math.floor(v * 10 ^ o.Decimals + .5) / 10 ^ o.Decimals end
                        val = v
                        local p = (v - min) / (max - min)
                        local t = instant and 0 or .12
                        Tween(fill, t, { Size = UDim2.new(p, 0, 1, 0) })
                        Tween(grab, t, { Position = UDim2.new(p, -2, 0.5, 0) })
                        vt.Text = tostring(v) .. suffix
                        flag(o.Flag, v)
                        if o.Callback then task.spawn(o.Callback, v) end
                    end
                    function obj:Get() return val end
                    local sliding = false
                    local function update(x) obj:Set(min + (max - min) * math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)) end
                    bar.InputBegan:Connect(function(i)
                        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then sliding = true; update(i.Position.X) end
                    end)
                    table.insert(_sliders, function(x)
                        if x == nil then sliding = false
                        elseif sliding then update(x) end
                    end)
                    obj:Set(val, true)
                    return obj
                end

                function G:AddDropdown(o)
                    local items = o.Items or {}
                    local sel = o.Default or items[1]
                    local r = row(20)
                    r.ZIndex = 5
                    Label({ Text = o.Name, TextColor3 = Theme.TextDisabled, Size = UDim2.new(1, -135, 1, 0), Parent = r })
                    local box = New("TextButton", {
                        Size = UDim2.fromOffset(130, 20), Position = UDim2.new(1, -130, 0, 0),
                        BackgroundColor3 = Theme.FrameInactive, AutoButtonColor = false, Text = "", Parent = r,
                    }, { Corner(3), Stroke() })
                    local pv = Label({ Text = tostring(sel or ""), TextColor3 = Theme.TextDisabled, ClipsDescendants = true,
                        Size = UDim2.new(1, -24, 1, 0), Position = UDim2.fromOffset(4, 0), Parent = box })
                    Label({ Text = "▼", TextSize = 9, TextXAlignment = Enum.TextXAlignment.Center,
                        Size = UDim2.fromOffset(14, 20), Position = UDim2.new(1, -17, 0, 0), Parent = box })

                    local popup = New("ScrollingFrame", {
                        Visible = false, ZIndex = 50, Size = UDim2.fromOffset(130, 0),
                        BackgroundColor3 = Theme.FrameInactive, BackgroundTransparency = 0.1, BorderSizePixel = 0,
                        ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Accent,
                        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = gui,
                    }, { Corner(3), Stroke(), New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }) })
                    local obj, open = {}, false
                    local function build()
                        for _, c in ipairs(popup:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
                        for i, it in ipairs(items) do
                            local b = New("TextButton", {
                                Size = UDim2.new(1, 0, 0, 20), BackgroundColor3 = Theme.FrameActive,
                                BackgroundTransparency = (it == sel) and 0.3 or 1, AutoButtonColor = false, ZIndex = 51,
                                Text = "  " .. tostring(it), Font = Theme.Font, TextSize = Theme.TextSize,
                                TextColor3 = (it == sel) and Theme.Text or Theme.TextDisabled,
                                TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = i, Parent = popup,
                            })
                            b.MouseEnter:Connect(function() if it ~= sel then b.TextColor3 = Theme.Text end end)
                            b.MouseLeave:Connect(function() if it ~= sel then b.TextColor3 = Theme.TextDisabled end end)
                            b.MouseButton1Click:Connect(function() obj:Set(it); obj:Close() end)
                        end
                    end
                    function obj:Close()
                        open = false
                        Tween(popup, .15, { Size = UDim2.fromOffset(130, 0) }).Completed:Connect(function() if not open then popup.Visible = false end end)
                    end
                    function obj:Open()
                        open = true
                        build()
                        local ap = box.AbsolutePosition
                        popup.Position = UDim2.fromOffset(ap.X, ap.Y + 22)
                        popup.Visible = true
                        Tween(popup, .2, { Size = UDim2.fromOffset(130, math.min(#items, 8) * 20) })
                    end
                    function obj:Set(v)
                        sel = v; pv.Text = tostring(v)
                        flag(o.Flag, v)
                        if o.Callback then task.spawn(o.Callback, v) end
                    end
                    function obj:Refresh(newItems) items = newItems; if open then build() end end
                    function obj:Get() return sel end
                    box.MouseEnter:Connect(function() Tween(box, .2, { BackgroundColor3 = Theme.FrameInactive:Lerp(Theme.FrameActive, .5) }) end)
                    box.MouseLeave:Connect(function() Tween(box, .2, { BackgroundColor3 = Theme.FrameInactive }) end)
                    box.MouseButton1Click:Connect(function() if open then obj:Close() else obj:Open() end end)
                    UserInputService.InputBegan:Connect(function(i)
                        if open and i.UserInputType == Enum.UserInputType.MouseButton1 then
                            local m, p, s = i.Position, popup.AbsolutePosition, popup.AbsoluteSize
                            local b, bs = box.AbsolutePosition, box.AbsoluteSize
                            local inPop = m.X >= p.X and m.X <= p.X + s.X and m.Y >= p.Y and m.Y <= p.Y + s.Y
                            local inBox = m.X >= b.X and m.X <= b.X + bs.X and m.Y >= b.Y and m.Y <= b.Y + bs.Y
                            if not inPop and not inBox then obj:Close() end
                        end
                    end)
                    flag(o.Flag, sel)
                    return obj
                end
                G.AddCombo = G.AddDropdown

                function G:AddTextbox(o)
                    local r = row(20)
                    Label({ Text = o.Name, TextColor3 = Theme.TextDisabled, Size = UDim2.new(1, -135, 1, 0), Parent = r })
                    local frame = New("Frame", {
                        Size = UDim2.fromOffset(130, 20), Position = UDim2.new(1, -130, 0, 0),
                        BackgroundColor3 = Theme.FrameInactive, Parent = r,
                    }, { Corner(3), Stroke() })
                    local tb = New("TextBox", {
                        Size = UDim2.new(1, -8, 1, 0), Position = UDim2.fromOffset(4, 0), BackgroundTransparency = 1,
                        Text = o.Default or "", PlaceholderText = o.Placeholder or "", ClearTextOnFocus = false,
                        Font = Theme.Font, TextSize = Theme.TextSize, TextColor3 = Theme.Text,
                        PlaceholderColor3 = Theme.TextDisabled, TextXAlignment = Enum.TextXAlignment.Left,
                        ClipsDescendants = true, Parent = frame,
                    })
                    local mid = Theme.FrameInactive:Lerp(Theme.FrameActive, .5)
                    frame.MouseEnter:Connect(function() if not tb:IsFocused() then Tween(frame, .2, { BackgroundColor3 = Theme.FrameInactive:Lerp(Theme.FrameActive, .25) }) end end)
                    frame.MouseLeave:Connect(function() if not tb:IsFocused() then Tween(frame, .2, { BackgroundColor3 = Theme.FrameInactive }) end end)
                    tb.Focused:Connect(function() Tween(frame, .2, { BackgroundColor3 = mid }) end)
                    tb.FocusLost:Connect(function(enter)
                        Tween(frame, .2, { BackgroundColor3 = Theme.FrameInactive })
                        flag(o.Flag, tb.Text)
                        if o.Callback then task.spawn(o.Callback, tb.Text, enter) end
                    end)
                    flag(o.Flag, tb.Text)
                    return { Set = function(_, v) tb.Text = v; flag(o.Flag, v) end, Get = function() return tb.Text end }
                end
                G.AddInput = G.AddTextbox

                function G:AddColorPicker(o)
                    local h, s, v = (o.Default or Color3.new(1, 1, 1)):ToHSV()
                    local alpha = o.Alpha or 1
                    local r = row(16)
                    Label({ Text = o.Name, TextColor3 = Theme.TextDisabled, Size = UDim2.new(1, -30, 1, 0), Parent = r })
                    local prev = New("TextButton", {
                        Size = UDim2.fromOffset(16, 16), Position = UDim2.new(1, -16, 0, 0),
                        BackgroundColor3 = Color3.fromHSV(h, s, v), AutoButtonColor = false, Text = "", Parent = r,
                    }, { Corner(8) })

                    local pop = New("Frame", {
                        Visible = false, ZIndex = 60, Size = UDim2.fromOffset(180, 214),
                        BackgroundColor3 = Theme.FrameInactive, Parent = gui,
                    }, { Corner(4), Stroke() })
                    local sv = New("ImageButton", {
                        ZIndex = 61, Size = UDim2.fromOffset(164, 164), Position = UDim2.fromOffset(8, 8),
                        BackgroundColor3 = Color3.fromHSV(h, 1, 1), AutoButtonColor = false, Image = "", Parent = pop,
                    }, { Corner(4) })
                    New("Frame", { ZIndex = 62, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), Parent = sv }, {
                        Corner(4), New("UIGradient", { Transparency = NumberSequence.new(0, 1) }) })
                    New("Frame", { ZIndex = 63, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), Parent = sv }, {
                        Corner(4), New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }) })
                    local svKnob = New("Frame", { ZIndex = 64, Size = UDim2.fromOffset(8, 8), AnchorPoint = Vector2.new(.5, .5),
                        BackgroundTransparency = 1, Parent = sv }, { Corner(4), Stroke(Color3.new(1, 1, 1), 0) })

                    local hue = New("ImageButton", {
                        ZIndex = 61, Size = UDim2.fromOffset(164, 8), Position = UDim2.fromOffset(8, 178),
                        BackgroundColor3 = Color3.new(1, 1, 1), AutoButtonColor = false, Image = "", Parent = pop,
                    }, { Corner(4), New("UIGradient", { Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)), ColorSequenceKeypoint.new(1 / 6, Color3.fromHSV(1 / 6, 1, 1)),
                        ColorSequenceKeypoint.new(2 / 6, Color3.fromHSV(2 / 6, 1, 1)), ColorSequenceKeypoint.new(3 / 6, Color3.fromHSV(3 / 6, 1, 1)),
                        ColorSequenceKeypoint.new(4 / 6, Color3.fromHSV(4 / 6, 1, 1)), ColorSequenceKeypoint.new(5 / 6, Color3.fromHSV(5 / 6, 1, 1)),
                        ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)) }) }) })
                    local hueKnob = New("Frame", { ZIndex = 62, Size = UDim2.fromOffset(12, 12), AnchorPoint = Vector2.new(.5, .5),
                        Position = UDim2.new(h, 0, .5, 0), BackgroundColor3 = Color3.fromHSV(h, 1, 1), Parent = hue }, { Corner(6) })

                    local abar = New("ImageButton", {
                        ZIndex = 61, Size = UDim2.fromOffset(164, 8), Position = UDim2.fromOffset(8, 196),
                        BackgroundColor3 = Color3.fromHSV(h, s, v), AutoButtonColor = false, Image = "", Parent = pop,
                    }, { Corner(3), New("UIGradient", { Transparency = NumberSequence.new(1, 0) }) })
                    local aKnob = New("Frame", { ZIndex = 62, Size = UDim2.fromOffset(12, 12), AnchorPoint = Vector2.new(.5, .5),
                        Position = UDim2.new(alpha, 0, .5, 0), BackgroundColor3 = Color3.fromHSV(h, s, v), Parent = abar }, { Corner(6) })

                    local obj = {}
                    local function refresh()
                        local c = Color3.fromHSV(h, s, v)
                        prev.BackgroundColor3 = c
                        sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                        svKnob.Position = UDim2.fromScale(s, 1 - v)
                        hueKnob.Position = UDim2.new(h, 0, .5, 0); hueKnob.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                        abar.BackgroundColor3 = c; aKnob.Position = UDim2.new(alpha, 0, .5, 0); aKnob.BackgroundColor3 = c
                        flag(o.Flag, c)
                        if o.Callback then task.spawn(o.Callback, c, alpha) end
                    end
                    function obj:Set(c, a) h, s, v = c:ToHSV(); alpha = a or alpha; refresh() end
                    function obj:Get() return Color3.fromHSV(h, s, v), alpha end

                    local mode
                    local function drag(pos)
                        if mode == "sv" then
                            s = math.clamp((pos.X - sv.AbsolutePosition.X) / sv.AbsoluteSize.X, 0, 1)
                            v = 1 - math.clamp((pos.Y - sv.AbsolutePosition.Y) / sv.AbsoluteSize.Y, 0, 1)
                        elseif mode == "h" then
                            h = math.clamp((pos.X - hue.AbsolutePosition.X) / hue.AbsoluteSize.X, 0, 0.999)
                        elseif mode == "a" then
                            alpha = math.clamp((pos.X - abar.AbsolutePosition.X) / abar.AbsoluteSize.X, 0, 1)
                        end
                        refresh()
                    end
                    for el, m in pairs({ [sv] = "sv", [hue] = "h", [abar] = "a" }) do
                        el.InputBegan:Connect(function(i)
                            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then mode = m; drag(i.Position) end
                        end)
                    end
                    table.insert(_colorModes, function(pos)
                        if pos == nil then mode = nil
                        elseif mode then drag(pos) end
                    end)
                    prev.MouseButton1Click:Connect(function()
                        pop.Visible = not pop.Visible
                        local ap = prev.AbsolutePosition
                        pop.Position = UDim2.fromOffset(ap.X + 24, ap.Y)
                    end)
                    UserInputService.InputBegan:Connect(function(i)
                        if pop.Visible and i.UserInputType == Enum.UserInputType.MouseButton1 then
                            local m, p, sz = i.Position, pop.AbsolutePosition, pop.AbsoluteSize
                            local b = prev.AbsolutePosition
                            local inPop = m.X >= p.X and m.X <= p.X + sz.X and m.Y >= p.Y and m.Y <= p.Y + sz.Y
                            local inPrev = m.X >= b.X and m.X <= b.X + 16 and m.Y >= b.Y and m.Y <= b.Y + 16
                            if not inPop and not inPrev then pop.Visible = false end
                        end
                    end)
                    refresh()
                    return obj
                end

                function G:AddButton(o)
                    o = type(o) == "string" and { Name = o } or o
                    local r = row(25)
                    local b = New("TextButton", {
                        Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Button, AutoButtonColor = false,
                        Text = o.Name, Font = Theme.Font, TextSize = Theme.TextSize, TextColor3 = Theme.TextDisabled, Parent = r,
                    }, { Corner(4), Stroke() })
                    b.MouseEnter:Connect(function() Tween(b, .15, { BackgroundColor3 = Theme.ButtonHovered }); b.TextColor3 = Theme.Text end)
                    b.MouseLeave:Connect(function() Tween(b, .15, { BackgroundColor3 = Theme.Button }); b.TextColor3 = Theme.TextDisabled end)
                    b.MouseButton1Down:Connect(function() Tween(b, .1, { BackgroundColor3 = Theme.ButtonActive }) end)
                    b.MouseButton1Up:Connect(function() Tween(b, .1, { BackgroundColor3 = Theme.ButtonHovered }) end)
                    b.MouseButton1Click:Connect(function() if o.Callback then task.spawn(o.Callback) end end)
                    return b
                end

                function G:AddKeybind(o)
                    local key = o.Default
                    local r = row(20)
                    Label({ Text = o.Name, TextColor3 = Theme.TextDisabled, Size = UDim2.new(1, -75, 1, 0), Parent = r })
                    local b = New("TextButton", {
                        Size = UDim2.fromOffset(70, 20), Position = UDim2.new(1, -70, 0, 0), BackgroundColor3 = Theme.FrameInactive,
                        AutoButtonColor = false, Text = key and key.Name or "None", Font = Theme.Font, TextSize = 12,
                        TextColor3 = Theme.TextDisabled, Parent = r,
                    }, { Corner(3), Stroke() })
                    local listening = false
                    b.MouseButton1Click:Connect(function() listening = true; b.Text = "..." end)
                    UserInputService.InputBegan:Connect(function(i, gp)
                        if listening and i.UserInputType == Enum.UserInputType.Keyboard then
                            listening = false
                            key = (i.KeyCode ~= Enum.KeyCode.Escape) and i.KeyCode or nil
                            b.Text = key and key.Name or "None"
                            flag(o.Flag, key)
                        elseif not gp and key and i.KeyCode == key and o.Callback then
                            task.spawn(o.Callback, key)
                        end
                    end)
                    flag(o.Flag, key)
                end

                function G:AddSeparator()
                    local r = row(1)
                    r.BackgroundColor3 = Theme.Border; r.BackgroundTransparency = 0.94; r.BorderSizePixel = 0
                end

                function G:AddLabel(text)
                    local r = row(14)
                    return Label({ Text = text, TextColor3 = Theme.TextDisabled, Size = UDim2.fromScale(1, 1), Parent = r })
                end

                return G
            end

            table.insert(Tab.Subtabs, Sub)
            layoutSubs()
            if Window.CurrentTab == Tab and not Tab.Current then Sub:Select() end
            return Sub
        end

        function Tab:AddGroup(...)
            Tab._default = Tab._default or Tab:AddSubtab("General")
            return Tab._default:AddGroup(...)
        end

        table.insert(Window.Tabs, Tab)
        if not Window.CurrentTab then Tab:Select() end
        return Tab
    end

    function Window:Destroy()
        blur:Destroy()
        gui:Destroy()
    end

    if authed then task.spawn(StartGameLogic) end
    return Window
end

local StartGameLogic  -- forward declare so CreateWindow can reference it

local Window = ApexEngine:CreateWindow({
    Title  = "APEX ENGINE",
    OnSave = function(flags) print("[ApexEngine] saved", flags) end,
})

Window:AddCategory("Aimbot")
local Ragebot  = Window:AddTab("Ragebot",  Icons.crosshairs)
local AntiAim  = Window:AddTab("Anti-aim", Icons.ghost)
local Legitbot = Window:AddTab("Legitbot", Icons.mouse)

Window:AddCategory("Visuals")
local PlayersTab = Window:AddTab("Players", Icons.user)
local World      = Window:AddTab("World",   Icons.pallet)

Window:AddCategory("Miscellaneous")
local MainTab = Window:AddTab("Main",    Icons.hammer)
local Scripts = Window:AddTab("Scripts", Icons.code)

local Modes  = { "Default", "Smooth", "Instant", "Adaptive", "Custom" }
local Styles = { "Flat", "Gradient", "Outline", "Glow", "Shadow" }

local RGen = Ragebot:AddSubtab("General")
local RAdv = Ragebot:AddSubtab("Advanced")
local RPre = Ragebot:AddSubtab("Presets")

local g = RGen:AddGroup("Main", Icons.feather, "Left", 250)
g:AddCheckbox({ Name = "Enabled", Icon = Icons.dagger, Default = true, Flag = "rg_enabled" })
g:AddKeybind({ Name = "Activation key", Default = Enum.KeyCode.E, Flag = "rg_key" })
g:AddDropdown({ Name = "Mode", Items = Modes, Flag = "rg_mode" })
g:AddSlider({ Name = "Field of view", Min = 0, Max = 180, Default = 90, Suffix = "°", Flag = "rg_fov" })
g:AddSlider({ Name = "Smoothness", Min = 0, Max = 100, Default = 35, Suffix = "%", Flag = "rg_smooth" })
g:AddCheckbox({ Name = "Show indicator", Default = true, Flag = "rg_indicator" })
g:AddColorPicker({ Name = "Indicator color", Default = Color3.fromRGB(0, 180, 255), Flag = "rg_indicator_col" })

local g2 = RGen:AddGroup("Options", Icons.crown, "Right", 250)
g2:AddCheckbox({ Name = "Auto toggle", Flag = "rg_auto" })
g2:AddCheckbox({ Name = "Hold to use", Default = true, Flag = "rg_hold" })
g2:AddCheckbox({ Name = "Ignore team", Flag = "rg_team" })
g2:AddSeparator()
g2:AddDropdown({ Name = "Priority", Items = { "Closest", "Lowest", "Random", "Crosshair" }, Flag = "rg_priority" })
g2:AddSlider({ Name = "Delay", Min = 0, Max = 500, Default = 50, Suffix = "ms", Flag = "rg_delay" })
g2:AddSlider({ Name = "Max distance", Min = 10, Max = 1000, Default = 300, Suffix = "m", Flag = "rg_dist" })

local g3 = RGen:AddGroup("Extras", Icons.axe_battle, "Left", 180)
g3:AddCheckbox({ Name = "Notifications", Default = true, Flag = "rg_notify" })
g3:AddCheckbox({ Name = "Sound on toggle", Flag = "rg_sound" })
g3:AddDropdown({ Name = "Sound", Items = { "Click", "Pop", "Beep", "Ding" }, Flag = "rg_sound_type" })
g3:AddSlider({ Name = "Volume", Min = 0, Max = 100, Default = 60, Suffix = "%", Flag = "rg_volume" })

local g4 = RGen:AddGroup("Profile", Icons.save, "Right", 180)
g4:AddTextbox({ Name = "Profile name", Flag = "rg_profile" })
g4:AddButton({ Name = "Save profile", Callback = function() print("profile saved") end })
g4:AddButton({ Name = "Reset to default", Callback = function() print("profile reset") end })

local a1 = RAdv:AddGroup("Timing", Icons.hammer, "Left")
a1:AddSlider({ Name = "Update rate", Min = 1, Max = 240, Default = 60, Suffix = "hz", Flag = "adv_rate" })
a1:AddSlider({ Name = "Randomization", Min = 0, Max = 100, Default = 10, Suffix = "%", Flag = "adv_random" })
a1:AddCheckbox({ Name = "Predict movement", Flag = "adv_predict" })
a1:AddCheckbox({ Name = "Limit per second", Flag = "adv_limit" })
local a2 = RAdv:AddGroup("Behaviour", Icons.code, "Right")
a2:AddDropdown({ Name = "Curve", Items = { "Linear", "Ease in", "Ease out", "Ease in-out" }, Flag = "adv_curve" })
a2:AddCheckbox({ Name = "Only when visible", Default = true, Flag = "adv_visible" })
a2:AddCheckbox({ Name = "Stop on release", Default = true, Flag = "adv_release" })

local p1 = RPre:AddGroup("Presets", Icons.crown, "Left")
p1:AddDropdown({ Name = "Preset", Items = { "Balanced", "Aggressive", "Safe", "Custom" }, Flag = "pre_preset" })
p1:AddButton({ Name = "Load preset", Callback = function() print("preset loaded") end })

local AAGen = AntiAim:AddSubtab("General")
AntiAim:AddSubtab("Conditions")
local b1 = AAGen:AddGroup("Base", Icons.baby, "Left", 220)
b1:AddCheckbox({ Name = "Enabled", Flag = "aa_enabled" })
b1:AddDropdown({ Name = "Pitch", Items = { "None", "Up", "Down", "Zero", "Random" }, Flag = "aa_pitch" })
b1:AddDropdown({ Name = "Yaw base", Items = { "Local view", "At targets", "Static" }, Flag = "aa_yawbase" })
b1:AddSlider({ Name = "Yaw offset", Min = -180, Max = 180, Default = 0, Suffix = "°", Flag = "aa_yaw" })
b1:AddSlider({ Name = "Jitter", Min = 0, Max = 90, Default = 0, Suffix = "°", Flag = "aa_jitter" })
local b2 = AAGen:AddGroup("Keys", Icons.ad, "Left", 176)
b2:AddKeybind({ Name = "Manual left", Default = Enum.KeyCode.Z, Flag = "aa_left" })
b2:AddKeybind({ Name = "Manual right", Default = Enum.KeyCode.C, Flag = "aa_right" })
b2:AddKeybind({ Name = "Manual back", Default = Enum.KeyCode.X, Flag = "aa_back" })
local b3 = AAGen:AddGroup("Advanced", nil, "Right")
b3:AddCheckbox({ Name = "Freestanding", Flag = "aa_free" })
b3:AddCheckbox({ Name = "Disable on use", Default = true, Flag = "aa_use" })
b3:AddCheckbox({ Name = "Randomize body", Flag = "aa_body" })
b3:AddSlider({ Name = "Body limit", Min = 0, Max = 60, Default = 58, Suffix = "°", Flag = "aa_bodylim" })
b3:AddDropdown({ Name = "Fake mode", Items = { "Off", "Static", "Jitter", "Random" }, Flag = "aa_fake" })

local LGen = Legitbot:AddSubtab("General")
local l1 = LGen:AddGroup("Assist", Icons.mouse, "Left")
l1:AddCheckbox({ Name = "Enabled", Flag = "lg_enabled" })
l1:AddKeybind({ Name = "Key", Default = Enum.KeyCode.Q, Flag = "lg_key" })
l1:AddDropdown({ Name = "Target part", Items = { "Head", "UpperTorso", "LowerTorso", "HumanoidRootPart" }, Default = "Head", Flag = "lg_part" })
l1:AddSlider({ Name = "FOV", Min = 1, Max = 360, Default = 90, Suffix = "°", Flag = "lg_fov" })
l1:AddSlider({ Name = "Strength", Min = 0, Max = 100, Default = 25, Suffix = "%", Flag = "lg_strength" })
l1:AddSlider({ Name = "Smoothness", Min = 1, Max = 50, Default = 10, Flag = "lg_smooth" })
l1:AddSlider({ Name = "Reaction time", Min = 0, Max = 500, Default = 120, Suffix = "ms", Flag = "lg_react" })
local l2 = LGen:AddGroup("Draw", Icons.pallet, "Right")
l2:AddCheckbox({ Name = "Draw circle", Default = true, Flag = "lg_circle" })
l2:AddColorPicker({ Name = "Circle color", Default = Color3.fromRGB(255, 255, 255), Flag = "lg_circle_col" })
l2:AddSlider({ Name = "Thickness", Min = 1, Max = 5, Default = 1, Flag = "lg_thick" })
l2:AddCheckbox({ Name = "Filled", Flag = "lg_filled" })

local PGen = PlayersTab:AddSubtab("Enemies")
PlayersTab:AddSubtab("Teammates")
PlayersTab:AddSubtab("Local")
local v1 = PGen:AddGroup("Boxes", Icons.user, "Left", 230)
v1:AddCheckbox({ Name = "Box", Default = true, Flag = "pl_box" })
v1:AddColorPicker({ Name = "Box color", Default = Color3.fromRGB(255, 255, 255), Flag = "pl_box_col" })
v1:AddDropdown({ Name = "Box style", Items = { "Full", "Corner", "3D" }, Flag = "pl_box_style" })
v1:AddCheckbox({ Name = "Name", Default = true, Flag = "pl_name" })
v1:AddColorPicker({ Name = "Name color", Default = Color3.fromRGB(255, 255, 255), Flag = "pl_name_col" })
v1:AddCheckbox({ Name = "Health bar", Flag = "pl_health" })
v1:AddColorPicker({ Name = "Health color", Default = Color3.fromRGB(80, 255, 120), Flag = "pl_health_col" })
local v2 = PGen:AddGroup("Extra", Icons.ghost, "Right", 230)
v2:AddCheckbox({ Name = "Distance", Flag = "pl_dist" })
v2:AddCheckbox({ Name = "Tracers", Flag = "pl_tracer" })
v2:AddColorPicker({ Name = "Tracer color", Default = Color3.fromRGB(0, 180, 255), Flag = "pl_tracer_col" })
v2:AddDropdown({ Name = "Tracer origin", Items = { "Bottom", "Center", "Top", "Mouse" }, Flag = "pl_tracer_origin" })
v2:AddCheckbox({ Name = "Highlight", Flag = "pl_chams" })
v2:AddColorPicker({ Name = "Fill color", Default = Color3.fromRGB(255, 60, 90), Flag = "pl_fill" })
v2:AddColorPicker({ Name = "Outline color", Default = Color3.fromRGB(255, 255, 255), Flag = "pl_outline" })
local v3 = PGen:AddGroup("Settings", Icons.feather, "Left", 160)
v3:AddSlider({ Name = "Max distance", Min = 50, Max = 5000, Default = 1500, Suffix = "m", Flag = "pl_maxdist" })
v3:AddSlider({ Name = "Text size", Min = 8, Max = 24, Default = 13, Flag = "pl_textsize" })
v3:AddDropdown({ Name = "Font", Items = { "Museo", "Gotham", "Code", "Arcade" }, Flag = "pl_font" })

local WGen = World:AddSubtab("General")
local w1 = WGen:AddGroup("Lighting", Icons.pallet, "Left")
w1:AddCheckbox({ Name = "Custom ambient", Flag = "w_ambient" })
w1:AddColorPicker({ Name = "Ambient color", Default = Color3.fromRGB(120, 120, 160), Flag = "w_ambient_col" })
w1:AddSlider({ Name = "Brightness", Min = 0, Max = 10, Default = 2, Flag = "w_bright" })
w1:AddSlider({ Name = "Time of day", Min = 0, Max = 24, Default = 14, Suffix = "h", Flag = "w_time" })
w1:AddCheckbox({ Name = "Remove fog", Flag = "w_fog" })
local w2 = WGen:AddGroup("Sky", Icons.feather, "Right")
w2:AddDropdown({ Name = "Skybox", Items = { "Default", "Night", "Sunset", "Space", "Clouds" }, Flag = "w_sky" })
w2:AddColorPicker({ Name = "Sky tint", Default = Color3.fromRGB(255, 255, 255), Flag = "w_skytint" })
w2:AddDropdown({ Name = "Effect style", Items = Styles, Flag = "w_style" })
w2:AddCheckbox({ Name = "Bloom", Default = true, Flag = "w_bloom" })
w2:AddSlider({ Name = "Bloom intensity", Min = 0, Max = 100, Default = 40, Suffix = "%", Flag = "w_bloom_int" })

local MGen = MainTab:AddSubtab("General")
local m1 = MGen:AddGroup("Movement", Icons.hammer, "Left")
m1:AddCheckbox({ Name = "Auto jump", Flag = "m_bhop" })
m1:AddCheckbox({ Name = "Auto sprint", Flag = "m_sprint" })
m1:AddSlider({ Name = "Field of view", Min = 70, Max = 120, Default = 70, Suffix = "°", Flag = "m_camfov" })
m1:AddKeybind({ Name = "Zoom key", Default = Enum.KeyCode.V, Flag = "m_zoom" })
local m2 = MGen:AddGroup("Interface", Icons.code, "Right")
m2:AddColorPicker({ Name = "Accent color", Default = Theme.Accent, Flag = "m_accent" })
m2:AddDropdown({ Name = "Theme", Items = { "Dark", "Darker", "Midnight", "Ocean" }, Flag = "m_theme" })
m2:AddCheckbox({ Name = "Watermark", Default = true, Flag = "m_watermark" })
m2:AddCheckbox({ Name = "Keybind list", Default = true, Flag = "m_keybinds" })
m2:AddSlider({ Name = "Menu scale", Min = 50, Max = 150, Default = 100, Suffix = "%", Flag = "m_scale" })
m2:AddLabel("Menu key: Insert")

-- ============================================================
-- GAME LOGIC (only runs after auth)
-- ============================================================
StartGameLogic = function()
local RunService = game:GetService("RunService")
local Camera     = workspace.CurrentCamera

math.randomseed(tick())

local RIVALS_PLACE_ID = 317625359962
local IS_RIVALS = game.PlaceId == RIVALS_PLACE_ID
local GAME_NAME = IS_RIVALS and "Rivals" or "Universal"

-- ============================================================
-- SHARED MOVEMENT / WORLD LOGIC (works in any game)
-- ============================================================
Camera.FieldOfView = ApexEngine.Flags["m_camfov"] or 70

-- Bhop: use firesignal on Jump instead of writing hum.Jump directly
local function safejump(hum)
    pcall(function()
        if firesignal then
            firesignal(hum.Jumping, true)
        else
            hum.Jump = true
        end
    end)
end

UserInputService.JumpRequest:Connect(function()
    if ApexEngine.Flags["m_bhop"] then
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hrp and hrp.Velocity.Y < 1 then safejump(hum) end
    end
end)

-- Auto Sprint: LinearVelocity (BodyVelocity is deprecated)
local sprintLV = nil
local function setSprintLV(hrp, active)
    pcall(function()
        if active then
            if not sprintLV or not sprintLV.Parent then
                local att = Instance.new("Attachment", hrp)
                sprintLV = Instance.new("LinearVelocity")
                sprintLV.Attachment0 = att
                sprintLV.MaxForce = 1e4
                sprintLV.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
                sprintLV.RelativeTo = Enum.ActuatorRelativeTo.World
                sprintLV.Parent = hrp
            end
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            local dir = hum and hum.MoveDirection or Vector3.zero
            sprintLV.VectorVelocity = Vector3.new(dir.X * 24, hrp.AssemblyLinearVelocity.Y, dir.Z * 24)
        else
            if sprintLV and sprintLV.Parent then
                local att = sprintLV.Attachment0
                sprintLV:Destroy()
                if att then att:Destroy() end
            end
            sprintLV = nil
        end
    end)
end

local origFogEnd, origFogStart = Lighting.FogEnd, Lighting.FogStart
local origBrightness = Lighting.Brightness
local _espFrame = 0

RunService.Heartbeat:Connect(function(dt)
    _espFrame += 1
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")

    Camera.FieldOfView = ApexEngine.Flags["m_camfov"] or 70

    -- Bhop
    if ApexEngine.Flags["m_bhop"] and hum and hrp and math.abs(hrp.Velocity.Y) < 1 then
        safejump(hum)
    end

    -- Auto Sprint via LinearVelocity (avoids WalkSpeed write)
    if ApexEngine.Flags["m_sprint"] and hrp then
        setSprintLV(hrp, hum and hum.MoveDirection.Magnitude > 0)
    elseif sprintLV then
        setSprintLV(nil, false)
    end

    -- Fog
    if ApexEngine.Flags["w_fog"] then
        Lighting.FogEnd = 100000; Lighting.FogStart = 100000
    else
        Lighting.FogEnd = origFogEnd; Lighting.FogStart = origFogStart
    end

    -- Brightness
    Lighting.Brightness = ApexEngine.Flags["w_bright"] or origBrightness

    -- Ambient
    if ApexEngine.Flags["w_ambient"] then
        local c = ApexEngine.Flags["w_ambient_col"] or Color3.fromRGB(120,120,160)
        Lighting.Ambient = c; Lighting.OutdoorAmbient = c
    end

    -- Time of day
    if ApexEngine.Flags["w_time"] then
        Lighting.ClockTime = ApexEngine.Flags["w_time"] or 14
    end
end)

-- Bloom
local bloomEffect = Lighting:FindFirstChildOfClass("BloomEffect")
if not bloomEffect then
    bloomEffect = Instance.new("BloomEffect", Lighting)
end
RunService.Heartbeat:Connect(function()
    bloomEffect.Enabled   = ApexEngine.Flags["w_bloom"] ~= false
    bloomEffect.Intensity = (ApexEngine.Flags["w_bloom_int"] or 40) / 100 * 2
end)

-- Watermark
local wmGui = Instance.new("ScreenGui", GetParentGui())
wmGui.Name = "ApexWatermark"
wmGui.ResetOnSpawn = false
wmGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
local wmFrame = New("Frame", {
    Size = UDim2.fromOffset(200, 24), Position = UDim2.fromOffset(8, 8),
    BackgroundColor3 = Theme.WindowBg, BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = wmGui,
}, { Corner(4), Stroke() })
local wmLabel = Label({ Text = "APEX ENGINE  |  " .. GAME_NAME, Font = Theme.FontBold, TextSize = 12,
    TextColor3 = Theme.Accent, Size = UDim2.fromScale(1,1), TextXAlignment = Enum.TextXAlignment.Center, Parent = wmFrame })
RunService.Heartbeat:Connect(function()
    wmFrame.Visible = ApexEngine.Flags["m_watermark"] ~= false
end)

-- Live accent color
RunService.Heartbeat:Connect(function()
    local c = ApexEngine.Flags["m_accent"]
    if c then Theme.Accent = c end
end)

-- Menu scale
RunService.Heartbeat:Connect(function()
    local s = (ApexEngine.Flags["m_scale"] or 100) / 100
    Window.Main.Size = UDim2.fromOffset(math.floor(690 * s), math.floor(500 * s))
end)

-- ============================================================
-- ESP SYSTEM
-- ============================================================
local espFolder = Instance.new("Folder", workspace)
espFolder.Name = "ApexESP"

local espObjects = {}

local function removeESP(player)
    local o = espObjects[player]
    if not o then return end
    pcall(function()
        if o.highlight then o.highlight:Destroy() end
        if o.billboard then o.billboard:Destroy() end
        if o.box then for _, d in pairs(o.box) do d:Remove() end end
        if o.tracer then o.tracer:Remove() end
        if o.hpbar then for _, d in pairs(o.hpbar) do d:Remove() end end
    end)
    espObjects[player] = nil
end

local function createESP(player)
    if not player.Character then return end
    local char = player.Character
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChildOfClass("Humanoid")
    local head = char:FindFirstChild("Head")
    if not hrp or not hum or not head then return end
    removeESP(player)
    local obj = {}

    local hl = Instance.new("Highlight")
    hl.Adornee = char; hl.FillTransparency = 0.5; hl.OutlineTransparency = 0
    hl.Enabled = false; hl.Parent = espFolder
    obj.highlight = hl

    local bb = Instance.new("BillboardGui")
    bb.Adornee = head; bb.Size = UDim2.fromOffset(120, 40)
    bb.StudsOffset = Vector3.new(0, 2.2, 0); bb.AlwaysOnTop = true
    bb.ResetOnSpawn = false; bb.Parent = espFolder
    local nameLbl = Instance.new("TextLabel", bb)
    nameLbl.Size = UDim2.new(1,0,0.5,0); nameLbl.BackgroundTransparency = 1
    nameLbl.TextSize = 13; nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextStrokeTransparency = 0.5; nameLbl.TextStrokeColor3 = Color3.new(0,0,0)
    obj.billboard = bb; obj.nameLbl = nameLbl

    -- Box: 4 lines for Full, 8 lines for Corner
    local box = {}
    for i = 1, 8 do
        local l = Drawing.new("Line"); l.Thickness = 1; l.Visible = false; box[i] = l
    end
    obj.box = box

    -- Health bar: 2 lines (bg + fill)
    local hpbar = {}
    for i = 1, 2 do
        local l = Drawing.new("Line"); l.Thickness = 3; l.Visible = false; hpbar[i] = l
    end
    hpbar[1].Color = Color3.fromRGB(30, 30, 30)
    obj.hpbar = hpbar

    local tracer = Drawing.new("Line")
    tracer.Thickness = 1; tracer.Visible = false
    obj.tracer = tracer

    espObjects[player] = obj
end

local function getBoxScreen(char)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local _, size = char:GetBoundingBox()
    local cf = hrp.CFrame
    local corners = {
        cf * CFrame.new(-size.X/2, -size.Y/2, 0),
        cf * CFrame.new( size.X/2, -size.Y/2, 0),
        cf * CFrame.new( size.X/2,  size.Y/2, 0),
        cf * CFrame.new(-size.X/2,  size.Y/2, 0),
    }
    local pts = {}
    for _, c in ipairs(corners) do
        local sp, on = Camera:WorldToViewportPoint(c.Position)
        if not on then return nil end
        pts[#pts+1] = Vector2.new(sp.X, sp.Y)
    end
    return pts
end

local function drawBox(obj, pts, color, style)
    if not pts then
        for _, l in pairs(obj.box) do l.Visible = false end return
    end
    local tl, tr, br, bl = pts[4], pts[3], pts[2], pts[1]
    if style == "Corner" then
        local clen = (tr.X - tl.X) * 0.25
        local clenY = (bl.Y - tl.Y) * 0.25
        -- top-left
        obj.box[1].From=tl; obj.box[1].To=tl+Vector2.new(clen,0)
        obj.box[2].From=tl; obj.box[2].To=tl+Vector2.new(0,clenY)
        -- top-right
        obj.box[3].From=tr; obj.box[3].To=tr+Vector2.new(-clen,0)
        obj.box[4].From=tr; obj.box[4].To=tr+Vector2.new(0,clenY)
        -- bottom-left
        obj.box[5].From=bl; obj.box[5].To=bl+Vector2.new(clen,0)
        obj.box[6].From=bl; obj.box[6].To=bl+Vector2.new(0,-clenY)
        -- bottom-right
        obj.box[7].From=br; obj.box[7].To=br+Vector2.new(-clen,0)
        obj.box[8].From=br; obj.box[8].To=br+Vector2.new(0,-clenY)
        for i=1,8 do obj.box[i].Color=color; obj.box[i].Visible=true end
    else -- Full
        local edges = {{tl,tr},{tr,br},{br,bl},{bl,tl}}
        for i=1,4 do
            obj.box[i].From=edges[i][1]; obj.box[i].To=edges[i][2]
            obj.box[i].Color=color; obj.box[i].Visible=true
        end
        for i=5,8 do obj.box[i].Visible=false end
    end
end

local function drawHealthBar(obj, pts, hpPct, show)
    if not pts or not show then
        for _, l in pairs(obj.hpbar) do l.Visible = false end return
    end
    local tl, bl = pts[4], pts[1]
    local x = tl.X - 6
    local barH = bl.Y - tl.Y
    obj.hpbar[1].From = Vector2.new(x, tl.Y); obj.hpbar[1].To = Vector2.new(x, bl.Y)
    obj.hpbar[1].Visible = true
    obj.hpbar[2].From = Vector2.new(x, bl.Y); obj.hpbar[2].To = Vector2.new(x, bl.Y - barH * hpPct)
    obj.hpbar[2].Color = Color3.fromRGB(math.floor(255*(1-hpPct)), math.floor(255*hpPct), 60)
    obj.hpbar[2].Visible = true
end

RunService.Heartbeat:Connect(function()
    -- Throttle ESP to every 3 frames to reduce detection surface
    if _espFrame % 3 ~= 0 then return end

    local espOn   = ApexEngine.Flags["pl_box"] or ApexEngine.Flags["pl_name"] or ApexEngine.Flags["pl_chams"] or ApexEngine.Flags["pl_tracer"] or ApexEngine.Flags["pl_health"]
    local maxDist = ApexEngine.Flags["pl_maxdist"] or 1500
    local camPos  = Camera.CFrame.Position
    local vpSize  = Camera.ViewportSize
    local boxStyle = ApexEngine.Flags["pl_box_style"] or "Full"

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        local head = char and char:FindFirstChild("Head")

        if not espOn or not char or not hrp or not hum or not head then
            local o = espObjects[player]
            if o then
                if o.highlight then o.highlight.Enabled = false end
                if o.billboard then o.billboard.Enabled = false end
                if o.box then for _, l in pairs(o.box) do l.Visible = false end end
                if o.hpbar then for _, l in pairs(o.hpbar) do l.Visible = false end end
                if o.tracer then o.tracer.Visible = false end
            end
            continue
        end

        if not espObjects[player] then createESP(player) end
        local o = espObjects[player]
        if not o then continue end

        local dist     = (camPos - hrp.Position).Magnitude
        local inRange  = dist <= maxDist
        local sp, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        local hpPct    = hum.Health / math.max(hum.MaxHealth, 1)

        if o.highlight then
            o.highlight.Enabled      = ApexEngine.Flags["pl_chams"] and inRange or false
            o.highlight.FillColor    = ApexEngine.Flags["pl_fill"]    or Color3.fromRGB(255,60,90)
            o.highlight.OutlineColor = ApexEngine.Flags["pl_outline"] or Color3.new(1,1,1)
        end

        if o.billboard then
            o.billboard.Enabled = inRange and onScreen and (ApexEngine.Flags["pl_name"] or ApexEngine.Flags["pl_dist"])
            if o.nameLbl then
                o.nameLbl.Visible    = ApexEngine.Flags["pl_name"] or false
                o.nameLbl.TextColor3 = ApexEngine.Flags["pl_name_col"] or Color3.new(1,1,1)
                local distStr = ApexEngine.Flags["pl_dist"] and (" ["..math.floor(dist).."m]") or ""
                o.nameLbl.Text = player.Name .. distStr
            end
        end

        local pts = (ApexEngine.Flags["pl_box"] and inRange and onScreen) and getBoxScreen(char) or nil
        drawBox(o, pts, ApexEngine.Flags["pl_box_col"] or Color3.new(1,1,1), boxStyle)
        drawHealthBar(o, pts, hpPct, ApexEngine.Flags["pl_health"] and inRange and onScreen)

        if o.tracer then
            local origin = ApexEngine.Flags["pl_tracer_origin"]
            local fromY  = origin == "Top" and 0 or origin == "Center" and vpSize.Y/2 or vpSize.Y
            o.tracer.From    = Vector2.new(vpSize.X/2, fromY)
            o.tracer.To      = Vector2.new(sp.X, sp.Y)
            o.tracer.Color   = ApexEngine.Flags["pl_tracer_col"] or Color3.fromRGB(0,180,255)
            o.tracer.Visible = ApexEngine.Flags["pl_tracer"] and inRange and onScreen or false
        end
    end
end)

Players.PlayerRemoving:Connect(removeESP)
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function() task.wait(1); createESP(p) end)
end)
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer and p.Character then createESP(p) end
end

-- ============================================================
-- AIMBOT SHARED
-- ============================================================
local function getAimTarget(fovRadius, partName, skipTeam, visCheck)
    local vpCenter = Camera.ViewportSize / 2
    local camPos   = Camera.CFrame.Position
    local myTeam   = LocalPlayer.Team
    local bestDist, bestPart, bestChar = fovRadius, nil, nil

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if skipTeam and player.Team == myTeam then continue end
        local char = player.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        local part = char:FindFirstChild(partName) or char:FindFirstChild("HumanoidRootPart")
        if not part then continue end

        local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end
        local screenDist = (Vector2.new(sp.X, sp.Y) - vpCenter).Magnitude
        if screenDist >= bestDist then continue end

        if visCheck then
            local dir = part.Position - camPos
            local params = RaycastParams.new()
            params.FilterDescendantsInstances = { LocalPlayer.Character, espFolder }
            params.FilterType = Enum.RaycastFilterType.Exclude
            local hit = workspace:Raycast(camPos, dir.Unit * dir.Magnitude, params)
            if hit and not char:IsAncestorOf(hit.Instance) and hit.Instance ~= part then continue end
        end

        bestDist = screenDist
        bestPart = part
        bestChar = char
    end
    return bestPart, bestChar
end

local function predictPos(part, dt)
    local hrp = part.Parent and part.Parent:FindFirstChild("HumanoidRootPart")
    if not hrp then return part.Position end
    return part.Position + hrp.AssemblyLinearVelocity * dt
end

-- ============================================================
-- LEGITBOT
-- ============================================================
local lgCircle = Drawing.new("Circle")
lgCircle.Visible = false; lgCircle.Filled = false
lgCircle.Thickness = 1; lgCircle.Color = Color3.new(1,1,1); lgCircle.NumSides = 64

local lgHoldActive = false
local lgReactTimer = 0
local lgFired = false

UserInputService.InputBegan:Connect(function(i, gp)
    if not gp and ApexEngine.Flags["lg_key"] and i.KeyCode == ApexEngine.Flags["lg_key"] then
        lgHoldActive = true; lgReactTimer = 0; lgFired = false
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if ApexEngine.Flags["lg_key"] and i.KeyCode == ApexEngine.Flags["lg_key"] then
        lgHoldActive = false; lgFired = false
    end
end)

RunService.Heartbeat:Connect(function(dt)
    local vpCenter  = Camera.ViewportSize / 2
    local fovRadius = ApexEngine.Flags["lg_fov"] or 90

    lgCircle.Visible   = ApexEngine.Flags["lg_circle"] ~= false
    lgCircle.Radius    = fovRadius
    lgCircle.Position  = vpCenter
    lgCircle.Color     = ApexEngine.Flags["lg_circle_col"] or Color3.new(1,1,1)
    lgCircle.Thickness = ApexEngine.Flags["lg_thick"] or 1
    lgCircle.Filled    = ApexEngine.Flags["lg_filled"] or false

    if not ApexEngine.Flags["lg_enabled"] or not lgHoldActive then return end

    lgReactTimer += dt
    if lgReactTimer < (ApexEngine.Flags["lg_react"] or 120) / 1000 then return end
    lgFired = true

    local target = getAimTarget(fovRadius, ApexEngine.Flags["lg_part"] or "Head", true, true)
    if not target then return end

    local predPos  = predictPos(target, dt * 2)
    local sp       = Camera:WorldToViewportPoint(predPos)
    local delta    = (Vector2.new(sp.X, sp.Y) - vpCenter)
    local strength = (ApexEngine.Flags["lg_strength"] or 25) / 100
    local smooth   = math.max(ApexEngine.Flags["lg_smooth"] or 10, 1)
    mousemoverel(delta.X * strength / smooth, delta.Y * strength / smooth)
end)

-- ============================================================
-- RAGEBOT
-- ============================================================
local rgHoldActive = false
UserInputService.InputBegan:Connect(function(i, gp)
    if not gp and ApexEngine.Flags["rg_key"] and i.KeyCode == ApexEngine.Flags["rg_key"] then
        rgHoldActive = true
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if ApexEngine.Flags["rg_key"] and i.KeyCode == ApexEngine.Flags["rg_key"] then
        rgHoldActive = false
    end
end)

local rgDelayTimer = 0
RunService.Heartbeat:Connect(function(dt)
    if not ApexEngine.Flags["rg_enabled"] then return end
    if not rgHoldActive then return end

    rgDelayTimer += dt
    local delaySec = (ApexEngine.Flags["rg_delay"] or 50) / 1000
    if rgDelayTimer < delaySec then return end
    rgDelayTimer = 0

    local fov      = ApexEngine.Flags["rg_fov"] or 90
    local partName = "Head"
    local skipTeam = true
    local target, tchar = getAimTarget(fov, partName, skipTeam, ApexEngine.Flags["adv_visible"] ~= false)
    if not target then return end

    local maxDist = ApexEngine.Flags["rg_dist"] or 300
    local hrp = tchar and tchar:FindFirstChild("HumanoidRootPart")
    if hrp and (Camera.CFrame.Position - hrp.Position).Magnitude > maxDist then return end

    local smooth = math.max(ApexEngine.Flags["rg_smooth"] or 0, 1)
    local predPos = predictPos(target, 0.05)
    local sp = Camera:WorldToViewportPoint(predPos)
    local vpCenter = Camera.ViewportSize / 2
    local delta = Vector2.new(sp.X, sp.Y) - vpCenter
    -- Jitter: randomize by adv_random % to avoid bot pattern detection
    local jitterPct = (ApexEngine.Flags["adv_random"] or 10) / 100
    local jx = (math.random() - 0.5) * 2 * jitterPct * delta.X
    local jy = (math.random() - 0.5) * 2 * jitterPct * delta.Y
    mousemoverel((delta.X + jx) / smooth, (delta.Y + jy) / smooth)
end)

-- ============================================================
-- SILENT AIM
-- ============================================================
-- Hooks tool RemoteEvent FireServer and redirects CFrame arg toward target.
-- Never writes Camera.CFrame (server-detectable).

local function getSilentTarget()
    return getAimTarget(ApexEngine.Flags["rg_fov"] or 180, "Head", true, false)
end

local saHooked = {}

local function tryHookRemote(remote)
    if not remote or not remote:IsA("RemoteEvent") then return end
    if saHooked[remote] then return end
    saHooked[remote] = true
    local n = remote.Name:lower()
    if not (n:find("fire") or n:find("shoot") or n:find("attack") or n:find("hit")) then return end
    pcall(function()
        local orig = remote.FireServer
        hookfunction(orig, function(self, ...)
            if not (ApexEngine.Flags["rg_enabled"] and rgHoldActive) then
                return orig(self, ...)
            end
            local target = getSilentTarget()
            if not target then return orig(self, ...) end
            local aimCF = CFrame.lookAt(Camera.CFrame.Position, target.Position)
            local args = {...}
            for i, v in ipairs(args) do
                if typeof(v) == "CFrame" then args[i] = aimCF; break end
            end
            return orig(self, table.unpack(args))
        end)
    end)
end

local function hookCharTools(char)
    if not char then return end
    local function scanTool(v)
        if not v:IsA("Tool") then return end
        for _, d in ipairs(v:GetDescendants()) do tryHookRemote(d) end
        v.DescendantAdded:Connect(tryHookRemote)
    end
    for _, v in ipairs(char:GetChildren()) do scanTool(v) end
    char.ChildAdded:Connect(scanTool)
end

if LocalPlayer.Character then hookCharTools(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(hookCharTools)

-- ============================================================
-- CONFIG SYSTEM
-- ============================================================
local CFG_FOLDER = "ApexEngine/configs"
if isfolder and not isfolder(CFG_FOLDER) then
    pcall(function() makefolder(CFG_FOLDER) end)
end

local function listConfigs()
    local list = {}
    if listfiles then
        pcall(function()
            for _, f in ipairs(listfiles(CFG_FOLDER)) do
                local name = f:match("([^/\\]+)%.json$")
                if name then list[#list+1] = name end
            end
        end)
    end
    if #list == 0 then list = { "default" } end
    return list
end

local cfgDropdown
local function saveConfig(name)
    if not name or name == "" then return end
    local data = {}
    for k, v in pairs(ApexEngine.Flags) do
        local t = type(v)
        if t == "boolean" or t == "number" or t == "string" then
            data[k] = v
        elseif t == "userdata" and typeof(v) == "Color3" then
            data[k] = { r = v.R, g = v.G, b = v.B }
        end
    end
    pcall(function()
        writefile(CFG_FOLDER .. "/" .. name .. ".json", HttpService:JSONEncode(data))
    end)
end

local function loadConfig(name)
    if not name or name == "" then return end
    local raw = readFile(CFG_FOLDER .. "/" .. name .. ".json")
    if not raw then return end
    local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok or not data then return end
    for k, v in pairs(data) do
        if type(v) == "table" and v.r then
            ApexEngine.Flags[k] = Color3.new(v.r, v.g, v.b)
        else
            ApexEngine.Flags[k] = v
        end
    end
end

local function deleteConfig(name)
    if not name or name == "" then return end
    pcall(function() delfile(CFG_FOLDER .. "/" .. name .. ".json") end)
end

-- Wire up config buttons
local SGen = Scripts:AddSubtab("Configs")
local s1 = SGen:AddGroup("Configs", Icons.save, "Left")
cfgDropdown = s1:AddDropdown({ Name = "Config", Items = listConfigs(), Flag = "cfg_sel" })
local cfgNameBox = s1:AddTextbox({ Name = "New config", Flag = "cfg_name" })
s1:AddButton({ Name = "Save", Callback = function()
    local name = ApexEngine.Flags["cfg_name"]
    if not name or name == "" then name = ApexEngine.Flags["cfg_sel"] end
    saveConfig(name)
    cfgDropdown:Refresh(listConfigs())
end })
s1:AddButton({ Name = "Load", Callback = function()
    loadConfig(ApexEngine.Flags["cfg_sel"])
end })
s1:AddButton({ Name = "Delete", Callback = function()
    deleteConfig(ApexEngine.Flags["cfg_sel"])
    cfgDropdown:Refresh(listConfigs())
end })
local s2 = SGen:AddGroup("Lua", Icons.code, "Right")
s2:AddCheckbox({ Name = "Allow scripts", Flag = "lua_allow" })
s2:AddCheckbox({ Name = "Auto load", Flag = "lua_autoload" })
s2:AddButton({ Name = "Reload scripts", Callback = function() print("scripts reloaded") end })

-- ============================================================
-- SPRINT CLEANUP ON RESPAWN
-- ============================================================
local function cleanupSprint()
    pcall(function()
        if sprintLV and sprintLV.Parent then
            local att = sprintLV.Attachment0
            sprintLV:Destroy()
            if att then att:Destroy() end
        end
        sprintLV = nil
    end)
end
LocalPlayer.CharacterAdded:Connect(function(char)
    cleanupSprint()
    -- re-hook tools on new character
    hookCharTools(char)
end)

-- ============================================================
-- KEYBIND LIST
-- ============================================================
local kbGui = Instance.new("ScreenGui", GetParentGui())
kbGui.Name = "ApexKeybinds"
kbGui.ResetOnSpawn = false
kbGui.ZIndexBehavior = Enum.ZIndexBehavior.Global

local kbFrame = New("Frame", {
    Size = UDim2.fromOffset(160, 10),
    Position = UDim2.new(1, -168, 1, -8),
    BackgroundColor3 = Theme.WindowBg,
    BackgroundTransparency = 0.3,
    BorderSizePixel = 0,
    Parent = kbGui,
}, { Corner(4), Stroke() })

New("UIListLayout", {
    Padding = UDim.new(0, 2),
    SortOrder = Enum.SortOrder.LayoutOrder,
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    Parent = kbFrame,
})

local kbEntries = {}
local KB_WATCH = {
    { flag = "lg_key",  label = "Legitbot" },
    { flag = "rg_key",  label = "Ragebot"  },
    { flag = "m_zoom",  label = "Zoom"     },
    { flag = "aa_left", label = "AA Left"  },
    { flag = "aa_right",label = "AA Right" },
    { flag = "aa_back", label = "AA Back"  },
}

for i, kb in ipairs(KB_WATCH) do
    local row = New("Frame", {
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        LayoutOrder = i,
        Parent = kbFrame,
    })
    Label({ Text = kb.label, TextColor3 = Theme.TextDisabled,
        TextSize = 11, Size = UDim2.new(0.6, 0, 1, 0), Parent = row })
    local valLbl = Label({ Text = "None", TextColor3 = Theme.Accent,
        TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right,
        Size = UDim2.new(0.4, -4, 1, 0), Position = UDim2.new(0.6, 0, 0, 0), Parent = row })
    kbEntries[kb.flag] = valLbl
end

RunService.Heartbeat:Connect(function()
    local show = ApexEngine.Flags["m_keybinds"] ~= false
    kbGui.Enabled = show
    if not show then return end
    local totalH = 0
    for _, kb in ipairs(KB_WATCH) do
        local key = ApexEngine.Flags[kb.flag]
        local lbl = kbEntries[kb.flag]
        if lbl then
            lbl.Text = key and key.Name or "None"
            lbl.Parent.Visible = key ~= nil
            if key then totalH += 18 end
        end
    end
    kbFrame.Size = UDim2.fromOffset(160, math.max(totalH, 10))
end)

-- ============================================================
-- CONFIG AUTO-LOAD
-- ============================================================
if ApexEngine.Flags["lua_autoload"] then
    local sel = ApexEngine.Flags["cfg_sel"]
    if sel and sel ~= "" then
        pcall(function() loadConfig(sel) end)
    end
end

end -- StartGameLogic

return ApexEngine
