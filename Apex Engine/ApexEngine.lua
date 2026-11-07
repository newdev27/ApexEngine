
--[[
    Apex Engine — Brisk Survival cheat
    Designed and developed by Barlas (discord: 5nqs)
]]

if getgenv().apexengine_loaded then
    while task.wait(99999999) do end
end
getgenv().apexengine_loaded = true

local _runtimeConnections = {}
local function trackConnection(c)
    _runtimeConnections[#_runtimeConnections + 1] = c
    return c
end

-- ── Services ──────────────────────────────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local HttpService      = game:GetService("HttpService")
local LocalPlayer      = Players.LocalPlayer

-- ── Game identity ─────────────────────────────────────────
local GAME_IDS = {
    ["131634900549298"] = "Brisk Survival",
}
local GAME_NAME = GAME_IDS[tostring(game.PlaceId)] or "Unknown"

-- ── Fonts ─────────────────────────────────────────────────
local FontURLs = {
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
    Museo500 = LoadFont("Museo500"),
    Museo900 = LoadFont("Museo900"),
}

-- ── Theme ─────────────────────────────────────────────────
local function rgbf(r,g,b) return Color3.new(r,g,b) end
local Theme = {
    Accent        = rgbf(0.30, 0.49, 1.00),
    Text          = rgbf(1, 1, 1),
    TextDisabled  = rgbf(0.51, 0.52, 0.56),
    Border        = rgbf(1, 1, 1), BorderTransparency = 0.97,
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

-- ── UI helpers ────────────────────────────────────────────
local function New(class, props, children)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k == "Font" and typeof(v) == "Font" then o.FontFace = v
        elseif k ~= "Parent" then o[k] = v end
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
    if t == 0 then for k,v in pairs(props) do obj[k]=v end return end
    local tw = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    tw:Play(); return tw
end
local function Label(props)
    props.BackgroundTransparency = 1
    props.Font        = props.Font     or Theme.Font
    props.TextSize    = props.TextSize or Theme.TextSize
    props.TextColor3  = props.TextColor3 or Theme.Text
    props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
    return New("TextLabel", props)
end
local function GetParentGui()
    local ok, hui = pcall(function() return gethui and gethui() end)
    if ok and hui then return hui end
    local ok2, core = pcall(function() return game:GetService("CoreGui") end)
    if ok2 and core then
        local test = pcall(function() local f=Instance.new("Folder"); f.Parent=core; f:Destroy() end)
        if test then return core end
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- ── Key system ────────────────────────────────────────────
local KEY_FILE  = "ApexEngine/key.dat"
local HWID_FILE = "ApexEngine/hwid.dat"
local KEYS_URL  = "https://raw.githubusercontent.com/newdev27/ApexEngine/main/Apex%20Engine/keys.json"
local SALT      = "AX_br27_$3cr3t_2k25"
local DISCORD_INVITE = "discord.gg/apexengine"

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

local function validFormat(key)
    return key ~= nil and type(key) == "string"
        and key:match("^APEX%-[A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9]%-[A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9]%-[A-Z0-9][A-Z0-9]$") ~= nil
end
local VALID_TIER_CODES = { MN=true,HR=true,DY=true,FR=true,WK=true,MO=true,YR=true,LT=true }
local function validTierCode(key) return VALID_TIER_CODES[key:sub(6,7)] == true end

local CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
local function verifyChecksum(key)
    local body = key:sub(1,-4); local expected = key:sub(-2)
    local hash = 5381; local str = body .. SALT
    for i = 1, #str do hash = ((hash*33)+string.byte(str,i)) % 1048576 end
    local c1 = CHARS:sub((hash%#CHARS)+1,(hash%#CHARS)+1)
    local c2 = CHARS:sub((math.floor(hash/#CHARS)%#CHARS)+1,(math.floor(hash/#CHARS)%#CHARS)+1)
    return (c1..c2) == expected
end
local function fetchKeys()
    local ok, res = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(KEYS_URL.."?t="..tostring(os.time())))
    end)
    if ok and res and res.keys then return res.keys end
    return nil
end
local function isExpired(entry)
    if entry.expires_at == nil or entry.expires_at == false then return false end
    return os.time() > entry.expires_at
end

local KeySystem = {}
function KeySystem:Validate(inputKey)
    inputKey = tostring(inputKey or ""):upper():gsub("%s","")
    if not validFormat(inputKey)    then return false, "Invalid key format." end
    if not validTierCode(inputKey)  then return false, "Invalid key format." end
    if not verifyChecksum(inputKey) then return false, "Invalid key." end
    local keys = fetchKeys()
    if not keys then return false, "Could not reach key server. Check your connection." end
    local entry = keys[inputKey]
    if not entry then return false, "Key not found." end
    if entry.blocked then return false, "This key has been revoked." end
    if isExpired(entry) then return false, "Key expired. Renew at discord.gg/apexengine" end
    local hwid = getHWID()
    if entry.hwid ~= nil and entry.hwid ~= "" and entry.hwid ~= hwid then
        return false, "Key is locked to another device. Key has been flagged."
    end
    writeFile(KEY_FILE, inputKey)
    writeFile(HWID_FILE, hwid)
    return true, "OK", entry
end
function KeySystem:GetSaved()
    local key = readFile(KEY_FILE); local hwid = readFile(HWID_FILE)
    if key and hwid and hwid == getHWID() then return key end
    writeFile(KEY_FILE,""); writeFile(HWID_FILE,"")
    return nil
end

-- ── Discord helper ────────────────────────────────────────
local function JoinDiscord()
    local code = DISCORD_INVITE:match("discord%.gg/([%w]+)") or DISCORD_INVITE
    local copy = setclipboard or toclipboard
    if copy then pcall(copy, "https://discord.gg/"..code) end
    local req = request or (syn and syn.request) or (http and http.request)
    if req then
        pcall(req, {
            Url = "http://127.0.0.1:6463/rpc?v=1", Method = "POST",
            Headers = { ["Content-Type"]="application/json", ["Origin"]="https://discord.com" },
            Body = HttpService:JSONEncode({ cmd="INVITE_BROWSER", args={code=code}, nonce=HttpService:GenerateGUID(false) }),
            Timeout = 2,
        })
    end
end

-- ── Shared slider/colorpicker input routing ───────────────
local _sliders, _colorModes = {}, {}
trackConnection(UserInputService.InputChanged:Connect(function(i)
    local t = i.UserInputType
    if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
        for _, fn in ipairs(_sliders)    do fn(i.Position.X) end
        for _, fn in ipairs(_colorModes) do fn(i.Position)   end
    end
end))
trackConnection(UserInputService.InputEnded:Connect(function(i)
    local t = i.UserInputType
    if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
        for _, fn in ipairs(_sliders)    do fn(nil) end
        for _, fn in ipairs(_colorModes) do fn(nil) end
    end
end))

-- ── ApexEngine core ───────────────────────────────────────
local ApexEngine = { Flags = {}, Theme = Theme, ToggleKey = Enum.KeyCode.RightShift }
ApexEngine.__index = ApexEngine

function ApexEngine:Destroy()
    getgenv().apexengine_loaded = nil
    for _, c in ipairs(_runtimeConnections) do pcall(function() c:Disconnect() end) end
    table.clear(_runtimeConnections)
end

function ApexEngine:CreateWindow(cfg)
    cfg = cfg or {}

    -- Key gate
    local authed = false
    local savedKey = KeySystem:GetSaved()
    if savedKey then
        local ok, msg, entry = KeySystem:Validate(savedKey)
        authed = ok
        if ok and entry then cfg.Tier = entry.tier; cfg.ExpiresAt = entry.expires_at end
        if not ok then warn("[ApexEngine] Saved key rejected: "..msg) end
    end

    if not authed then
        local done, submitting = false, false
        local keyGui = New("ScreenGui", {
            Name="ApexEngineKey", ResetOnSpawn=false,
            ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
            IgnoreGuiInset=true, DisplayOrder=999,
            Parent=GetParentGui(),
        })
        New("Frame", { Size=UDim2.fromScale(1,1), BackgroundColor3=Color3.new(0,0,0),
            BackgroundTransparency=0.5, BorderSizePixel=0, Parent=keyGui })

        local window = New("CanvasGroup", {
            Name="KeyWindow", AnchorPoint=Vector2.new(0.5,0.5),
            BackgroundColor3=Theme.WindowBg, BorderSizePixel=0,
            ClipsDescendants=true, GroupTransparency=1,
            Position=UDim2.fromScale(0.5,0.5), Size=UDim2.fromOffset(520,310),
            Parent=keyGui,
        }, { Corner(14) })

        local sidebar = New("Frame", {
            BackgroundColor3=Color3.fromRGB(8,8,10), BorderSizePixel=0,
            Size=UDim2.fromOffset(148,310), ZIndex=2, Parent=window,
        })
        New("Frame", { BackgroundColor3=Theme.Border, BackgroundTransparency=0.90,
            BorderSizePixel=0, Position=UDim2.new(1,-1,0,0), Size=UDim2.new(0,1,1,0), Parent=sidebar })

        local brand = New("Frame", { BackgroundColor3=Color3.fromRGB(14,14,18), BorderSizePixel=0,
            Position=UDim2.fromOffset(10,10), Size=UDim2.new(1,-20,0,42), Parent=sidebar }, { Corner(10) })
        New("Frame", { BackgroundColor3=Theme.Accent, BorderSizePixel=0,
            Size=UDim2.fromOffset(3,24), Position=UDim2.fromOffset(10,9), Parent=brand }, { Corner(2) })
        Label({ Text=cfg.Title or "APEX ENGINE", Font=Theme.FontBold, TextSize=12,
            TextColor3=Theme.Accent, TextTruncate=Enum.TextTruncate.AtEnd,
            Size=UDim2.new(1,-32,0,18), Position=UDim2.fromOffset(20,6), Parent=brand })
        Label({ Text="Key system", TextColor3=Theme.TextDisabled, TextSize=10,
            Size=UDim2.new(1,-32,0,13), Position=UDim2.fromOffset(20,22), Parent=brand })

        local footerBtn = New("TextButton", {
            BackgroundColor3=Color3.fromRGB(14,14,18), BorderSizePixel=0,
            AutoButtonColor=false, Text="",
            Position=UDim2.new(0,10,1,-53), Size=UDim2.new(1,-20,0,44), Parent=sidebar,
        }, { Corner(10) })
        Label({ Text=DISCORD_INVITE, Font=Theme.FontBold, TextSize=10,
            TextColor3=Theme.Accent, TextXAlignment=Enum.TextXAlignment.Center,
            Size=UDim2.new(1,-12,0,20), Position=UDim2.fromOffset(6,4), Parent=footerBtn })
        local footerSub = Label({ Text="Click to join", TextColor3=Theme.TextDisabled, TextSize=10,
            TextXAlignment=Enum.TextXAlignment.Center,
            Size=UDim2.new(1,-12,0,14), Position=UDim2.fromOffset(6,22), Parent=footerBtn })
        footerBtn.MouseEnter:Connect(function() Tween(footerBtn,0.12,{BackgroundColor3=Theme.GroupBoxBg}) end)
        footerBtn.MouseLeave:Connect(function() Tween(footerBtn,0.12,{BackgroundColor3=Color3.fromRGB(14,14,18)}) end)
        footerBtn.Activated:Connect(function()
            task.spawn(JoinDiscord)
            footerSub.Text="Copied to clipboard!"
            task.delay(2, function() footerSub.Text="Click to join" end)
        end)

        local main = New("Frame", { BackgroundColor3=Theme.WindowBg, BorderSizePixel=0,
            Position=UDim2.fromOffset(148,0), Size=UDim2.new(1,-148,1,0), ZIndex=2, Parent=window })
        local header = New("Frame", { BackgroundColor3=Color3.fromRGB(5,5,7), BorderSizePixel=0,
            Size=UDim2.new(1,0,0,58), Parent=main })
        New("Frame", { BackgroundColor3=Theme.Border, BackgroundTransparency=0.90, BorderSizePixel=0,
            Position=UDim2.new(0,0,1,-1), Size=UDim2.new(1,0,0,1), Parent=header })
        Label({ Text="Key verification", Font=Theme.FontBold, TextSize=15,
            Size=UDim2.new(1,-50,0,22), Position=UDim2.fromOffset(14,10), Parent=header })
        Label({ Text="Submit your key to unlock the script", TextColor3=Theme.TextDisabled, TextSize=11,
            TextTruncate=Enum.TextTruncate.AtEnd,
            Size=UDim2.new(1,-50,0,14), Position=UDim2.fromOffset(14,32), Parent=header })

        local content = New("Frame", { BackgroundTransparency=1, BorderSizePixel=0,
            Position=UDim2.fromOffset(14,68), Size=UDim2.new(1,-28,1,-78), Parent=main })
        Label({ Text="ACCESS KEY", Font=Theme.FontBold, TextColor3=Theme.TextDisabled, TextSize=11,
            Size=UDim2.fromOffset(80,20), Parent=content })
        New("Frame", { BackgroundColor3=Theme.Border, BackgroundTransparency=0.80, BorderSizePixel=0,
            Position=UDim2.new(0,88,0,9), Size=UDim2.new(1,-88,0,1), Parent=content })

        local keyBox = New("TextBox", {
            Name="KeyInput", BackgroundColor3=Color3.fromRGB(10,10,14), BorderSizePixel=0,
            ClearTextOnFocus=false, Font=Theme.Font,
            PlaceholderColor3=Theme.TextDisabled, PlaceholderText="APEX-XXXXXX-XXXXXX-XX",
            Size=UDim2.new(1,0,0,36), Position=UDim2.fromOffset(0,24),
            Text="", TextColor3=Theme.Text, TextSize=11,
            TextXAlignment=Enum.TextXAlignment.Left, Parent=content,
        }, { Corner(8) })
        New("UIPadding", { PaddingLeft=UDim.new(0,10), PaddingRight=UDim.new(0,10), Parent=keyBox })
        local kbStroke = Stroke(Theme.Border, 0.70); kbStroke.Parent = keyBox
        keyBox.Focused:Connect(function()
            Tween(keyBox,0.12,{BackgroundColor3=Color3.fromRGB(14,14,20)})
            Tween(kbStroke,0.12,{Color=Theme.Accent,Transparency=0.30})
        end)

        local submitBtn = New("TextButton", {
            BackgroundColor3=Theme.Accent, AutoButtonColor=false,
            Position=UDim2.fromOffset(0,72), Size=UDim2.new(0.6,-4,0,29),
            Text="Submit key", Font=Theme.FontBold, TextSize=12,
            TextColor3=Color3.fromRGB(8,8,8), Parent=content,
        }, { Corner(8) })
        local getKeyBtn = New("TextButton", {
            BackgroundColor3=Theme.Button, AutoButtonColor=false,
            Position=UDim2.new(0.6,4,0,72), Size=UDim2.new(0.4,-4,0,29),
            Text="Get key", Font=Theme.FontBold, TextSize=12,
            TextColor3=Theme.TextDisabled, Parent=content,
        }, { Corner(8) })
        local function animBtn(b,normal,hover)
            b.MouseEnter:Connect(function() Tween(b,0.12,{BackgroundColor3=hover}) end)
            b.MouseLeave:Connect(function() Tween(b,0.12,{BackgroundColor3=normal}) end)
            b.MouseButton1Down:Connect(function() Tween(b,0.07,{BackgroundColor3=normal:Lerp(Color3.new(0,0,0),0.1)}) end)
            b.MouseButton1Up:Connect(function() Tween(b,0.1,{BackgroundColor3=hover}) end)
        end
        animBtn(submitBtn, Theme.Accent, Theme.Accent:Lerp(Color3.new(1,1,1),0.08))
        animBtn(getKeyBtn, Theme.Button, Theme.ButtonHovered)

        local resultFrame = New("Frame", { BackgroundColor3=Theme.GroupBoxBg, BorderSizePixel=0,
            Position=UDim2.fromOffset(0,114), Size=UDim2.new(1,0,0,38), Parent=content,
        }, { Corner(8), Stroke(Theme.Border,0.75) })
        local resultDot = New("Frame", { BackgroundColor3=Theme.TextDisabled, BorderSizePixel=0,
            Position=UDim2.fromOffset(10,15), Size=UDim2.fromOffset(7,7), Parent=resultFrame }, { Corner(4) })
        local resultLbl = Label({ Text="Enter your key and press Submit key.",
            Font=Theme.Font, TextColor3=Theme.TextDisabled, TextSize=11,
            TextTruncate=Enum.TextTruncate.AtEnd,
            Size=UDim2.new(1,-36,1,0), Position=UDim2.fromOffset(26,0), Parent=resultFrame })
        local resultStroke = resultFrame:FindFirstChildWhichIsA("UIStroke")

        local function setKeyResult(message, kind)
            local color = Theme.TextDisabled
            if kind=="success" then color=Theme.Accent
            elseif kind=="error" then color=Color3.fromRGB(241,112,112) end
            resultLbl.Text = tostring(message or "")
            Tween(resultLbl,0.12,{TextColor3=color})
            Tween(resultDot,0.12,{BackgroundColor3=color})
            if resultStroke then
                Tween(resultStroke,0.12,{Color=color,Transparency=(kind=="info") and 0.75 or 0.40})
            end
        end

        local function trySubmit()
            if submitting then return end
            local key = (keyBox.Text or ""):match("^%s*(.-)%s*$")
            if key=="" then setKeyResult("Enter a key before submitting.","error"); return end
            submitting = true
            setKeyResult("Checking key...","info")
            task.spawn(function()
                local ok, msg, entry = KeySystem:Validate(key)
                if ok then
                    authed = true; submitting = false
                    if entry then cfg.Tier=entry.tier; cfg.ExpiresAt=entry.expires_at end
                    setKeyResult("Success! Loading script...","success")
                    Tween(window,0.20,{GroupTransparency=1})
                    task.delay(0.22, function() keyGui:Destroy(); done=true end)
                else
                    setKeyResult(msg,"error")
                    local orig = window.Position
                    for _, ox in ipairs({-6,6,-4,4,-2,2,0}) do
                        window.Position = UDim2.new(orig.X.Scale,orig.X.Offset+ox,orig.Y.Scale,orig.Y.Offset)
                        task.wait(0.045)
                    end
                    submitting = false
                end
            end)
        end

        keyBox.FocusLost:Connect(function(enter)
            Tween(keyBox,0.12,{BackgroundColor3=Color3.fromRGB(10,10,14)})
            Tween(kbStroke,0.12,{Color=Theme.Border,Transparency=0.70})
            if enter then task.spawn(trySubmit) end
        end)
        submitBtn.Activated:Connect(trySubmit)
        getKeyBtn.Activated:Connect(function()
            task.spawn(JoinDiscord)
            setKeyResult("Invite copied! Check Discord for your key.","info")
        end)

        -- Drag key window
        local dragInput, dragStart, winStart
        header.InputBegan:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
                dragInput=input; dragStart=input.Position; winStart=window.Position
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if not dragInput then return end
            local isMouse = dragInput.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement
            local isTouch = dragInput.UserInputType==Enum.UserInputType.Touch and input==dragInput
            if isMouse or isTouch then
                local d = input.Position - dragStart
                window.Position = UDim2.new(winStart.X.Scale,winStart.X.Offset+d.X,winStart.Y.Scale,winStart.Y.Offset+d.Y)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input==dragInput then dragInput=nil end
        end)

        local rawSaved = (isfile and isfile(KEY_FILE)) and readfile(KEY_FILE) or nil
        if rawSaved and rawSaved~="" then keyBox.Text=rawSaved; task.delay(0.4,trySubmit) end
        Tween(window,0.24,{GroupTransparency=0})
        repeat task.wait(0.1) until done
    end

    -- Window shell
    local Window = { Tabs = {}, CurrentTab = nil }
    local gui = New("ScreenGui", {
        Name="ApexEngineUI", ResetOnSpawn=false,
        ZIndexBehavior=Enum.ZIndexBehavior.Global,
        IgnoreGuiInset=true, Parent=GetParentGui(),
    })
    Window.Gui = gui
    local blur = New("BlurEffect", { Size=0, Name="ApexEngineBlur", Parent=Lighting })
    Tween(blur, 0.4, { Size=cfg.Blur or 12 })

    local main = New("Frame", {
        Name="Main", Size=UDim2.fromOffset(690,500),
        Position=UDim2.new(0.5,-345,0.5,-250),
        BackgroundTransparency=1, Parent=gui,
    })
    Window.Main = main

    local function Panel(x,y,w,h,ox,oy,ew,eh,alpha)
        local clip = New("Frame", {
            Size=UDim2.fromOffset(w,h), Position=UDim2.fromOffset(x,y),
            BackgroundTransparency=1, ClipsDescendants=true, BorderSizePixel=0, Parent=main,
        })
        New("Frame", {
            Size=UDim2.fromOffset(w+ew,h+eh), Position=UDim2.fromOffset(ox,oy),
            BackgroundColor3=Theme.WindowBg, BackgroundTransparency=alpha, BorderSizePixel=0, Parent=clip,
        }, { Corner(8) })
        return clip
    end

    Panel(0,0,170,500,0,0,10,0,0.1)
    local topbar = Panel(170,0,520,60,-10,0,10,10,0.05)
    New("Frame", { Size=UDim2.fromOffset(520,1), Position=UDim2.fromOffset(170,60),
        BackgroundColor3=Theme.WindowBg, BackgroundTransparency=0.1, BorderSizePixel=0, Parent=main })
    Panel(170,61,520,439,-10,-10,10,10,0)

    local title = cfg.Title or "APEX ENGINE"
    Label({ Text=title, Font=Theme.FontBold, TextSize=26, TextColor3=Theme.Accent,
        TextXAlignment=Enum.TextXAlignment.Left, Size=UDim2.fromOffset(170,30),
        Position=UDim2.fromOffset(15,17), Parent=main })
    Label({ Text=title, Font=Theme.FontBold, TextSize=26, TextColor3=Theme.Text,
        TextXAlignment=Enum.TextXAlignment.Left, Size=UDim2.fromOffset(170,30),
        Position=UDim2.fromOffset(14,17), Parent=main })

    New("Frame", { Size=UDim2.fromOffset(170,1), Position=UDim2.fromOffset(0,450),
        BackgroundColor3=Theme.WindowBg, BackgroundTransparency=0.5, BorderSizePixel=0, Parent=main })
    local av = New("ImageLabel", {
        Size=UDim2.fromOffset(30,30), Position=UDim2.fromOffset(15,460),
        BackgroundColor3=Theme.FrameActive, Image="", Parent=main,
    }, { Corner(100) })
    pcall(function()
        av.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
    end)
    Label({ Text=LocalPlayer.DisplayName, Size=UDim2.fromOffset(115,14), Position=UDim2.fromOffset(50,460), Parent=main })
    Label({ Text="License:", TextColor3=Theme.TextDisabled, Size=UDim2.fromOffset(50,14), Position=UDim2.fromOffset(50,475), Parent=main })
    local licLbl = Label({ Text="...", TextColor3=Theme.Accent, Size=UDim2.fromOffset(90,14), Position=UDim2.fromOffset(102,475), Parent=main })

    local function updateLicLabel()
        local expiresAt = cfg.ExpiresAt
        local tier = (cfg.Tier or "LT"):upper()
        if tier=="LT" then licLbl.Text="Lifetime"
        elseif tier=="FR" then licLbl.Text="Free"
        elseif expiresAt and type(expiresAt)=="number" then
            local left = math.max(0, expiresAt - os.time())
            if left==0 then licLbl.Text="Expired"; licLbl.TextColor3=Color3.fromRGB(255,80,80); return end
            local d=math.floor(left/86400); local h=math.floor((left%86400)/3600)
            local m=math.floor((left%3600)/60); local s=left%60
            if d>0 then licLbl.Text=d.."d "..h.."h"
            elseif h>0 then licLbl.Text=h.."h "..m.."m"
            else licLbl.Text=m.."m "..s.."s" end
        else licLbl.Text=tier end
    end
    updateLicLabel()
    local _licTick = 0
    trackConnection(RunService.Heartbeat:Connect(function(dt)
        _licTick += dt
        if _licTick < 1 then return end
        _licTick = 0; updateLicLabel()
    end))

    local tabList = New("Frame", {
        Size=UDim2.fromOffset(150,380), Position=UDim2.fromOffset(10,70),
        BackgroundTransparency=1, Parent=main,
    }, { New("UIListLayout", { Padding=UDim.new(0,4), SortOrder=Enum.SortOrder.LayoutOrder }) })
    local order = 0
    local function nextOrder() order+=1; return order end

    local subHolder = New("Frame", { Size=UDim2.fromOffset(240,25), Position=UDim2.fromOffset(300,20), BackgroundTransparency=1, Parent=main })
    local pageHolder = New("Frame", {
        Size=UDim2.fromOffset(490,404), Position=UDim2.fromOffset(185,81),
        BackgroundTransparency=1, ClipsDescendants=true, Parent=main,
    })
    local fade = New("CanvasGroup", { Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Parent=pageHolder })

    local function animatePage()
        fade.GroupTransparency=1
        pageHolder.Position=UDim2.fromOffset(185,81)
        Tween(fade,0.35,{GroupTransparency=0})
        Tween(pageHolder,0.35,{Position=UDim2.fromOffset(185,76)})
    end
    Window.Animate = animatePage

    do
        local dragging, dragStart, startPos
        local dragArea = New("Frame", { Size=UDim2.fromOffset(170,60), BackgroundTransparency=1, Parent=main })
        local function beginDrag(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
                dragging,dragStart,startPos = true,input.Position,main.Position
                input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false end end)
            end
        end
        dragArea.InputBegan:Connect(beginDrag)
        topbar.InputBegan:Connect(beginDrag)
        trackConnection(UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
                local d = input.Position - dragStart
                main.Position = UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
            end
        end))
    end

    trackConnection(UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and input.KeyCode == ApexEngine.ToggleKey then
            main.Visible = not main.Visible
            Tween(blur,0.3,{Size=main.Visible and (cfg.Blur or 12) or 0})
        end
    end))

    function Window:AddTab(name, icon)
        local Tab = { Subtabs={}, Current=nil }
        local btn = New("TextButton", {
            Size=UDim2.fromOffset(150,30), BackgroundColor3=Theme.FrameActive, BackgroundTransparency=1,
            AutoButtonColor=false, Text="", LayoutOrder=nextOrder(), Parent=tabList,
        }, { Corner(5) })
        if icon and icon~="" then
            New("ImageLabel", { BackgroundTransparency=1, Image=icon, ImageColor3=Theme.Accent,
                Size=UDim2.fromOffset(14,14), Position=UDim2.fromOffset(10,8),
                ScaleType=Enum.ScaleType.Fit, Parent=btn })
        end
        Label({ Text=name, Size=UDim2.fromOffset(110,30), Position=UDim2.fromOffset(35,0), Parent=btn })
        local subBar = New("Frame", {
            Size=UDim2.fromScale(1,1), BackgroundColor3=Theme.Button, Visible=false, Parent=subHolder,
        }, { Corner(4), Stroke(), New("UIListLayout", { FillDirection=Enum.FillDirection.Horizontal, SortOrder=Enum.SortOrder.LayoutOrder }) })
        Tab.Button, Tab.SubBar = btn, subBar
        local function layoutSubs()
            local n=#Tab.Subtabs
            subBar.Visible = n>0 and Window.CurrentTab==Tab
            for _,s in ipairs(Tab.Subtabs) do s.Button.Size=UDim2.new(1/math.max(n,1),0,1,0) end
        end
        function Tab:Select()
            if Window.CurrentTab==Tab then return end
            for _,t in ipairs(Window.Tabs) do
                Tween(t.Button,.3,{BackgroundTransparency=1})
                t.SubBar.Visible=false
                for _,s in ipairs(t.Subtabs) do s.Page.Visible=false end
            end
            Window.CurrentTab=Tab
            Tween(btn,.3,{BackgroundTransparency=0.5})
            layoutSubs()
            if Tab.Current then Tab.Current.Page.Visible=true
            elseif Tab.Subtabs[1] then Tab.Subtabs[1]:Select() end
            animatePage()
        end
        btn.MouseButton1Click:Connect(function() Tab:Select() end)
        function Tab:AddSubtab(sname)
            local Sub={}
            local sb = New("TextButton", {
                BackgroundColor3=Theme.FrameActive, BackgroundTransparency=1, AutoButtonColor=false,
                Text=sname, Font=Theme.Font, TextSize=Theme.TextSize, TextColor3=Theme.TextDisabled,
                LayoutOrder=#Tab.Subtabs+1, Parent=subBar,
            }, { Corner(4) })
            local page = New("Frame", { Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Visible=false, Parent=fade })
            local function column(x)
                return New("ScrollingFrame", {
                    Size=UDim2.fromOffset(241,404), Position=UDim2.fromOffset(x,0),
                    BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=0,
                    CanvasSize=UDim2.new(), AutomaticCanvasSize=Enum.AutomaticSize.Y, Parent=page,
                }, { New("UIListLayout", { Padding=UDim.new(0,8), SortOrder=Enum.SortOrder.LayoutOrder }) })
            end
            Sub.Left,Sub.Right = column(0),column(249)
            Sub.Button,Sub.Page = sb,page
            function Sub:Select()
                for _,s in ipairs(Tab.Subtabs) do
                    s.Page.Visible=false
                    Tween(s.Button,.3,{BackgroundTransparency=1})
                    s.Button.TextColor3=Theme.TextDisabled
                end
                Tab.Current=Sub; page.Visible=true
                Tween(sb,.3,{BackgroundTransparency=0.2}); sb.TextColor3=Theme.Text
                animatePage()
            end
            sb.MouseButton1Click:Connect(function() Sub:Select() end)
            local groupCount=0
            function Sub:AddGroup(gname, gicon, side, height)
                local col=(side=="Right") and Sub.Right or Sub.Left
                local G={}; groupCount+=1
                local holder = New("Frame", {
                    Size=UDim2.fromOffset(241,height or 404), BackgroundTransparency=1,
                    LayoutOrder=groupCount, Parent=col,
                })
                local tx=12
                if gicon then
                    New("ImageLabel", { BackgroundTransparency=1, Image=gicon, ImageColor3=Theme.Text,
                        ImageTransparency=0.5, Size=UDim2.fromOffset(12,12),
                        Position=UDim2.fromOffset(12,2), ScaleType=Enum.ScaleType.Fit, Parent=holder })
                    tx=28
                end
                Label({ Text=gname, TextTransparency=0.5, Size=UDim2.fromOffset(200,16), Position=UDim2.fromOffset(tx,0), Parent=holder })
                local box = New("Frame", {
                    Size=UDim2.new(1,0,1,-20), Position=UDim2.fromOffset(0,20),
                    BackgroundColor3=Theme.GroupBoxBg, BorderSizePixel=0, Parent=holder,
                }, { Corner(6), Stroke() })
                local list = New("ScrollingFrame", {
                    Size=UDim2.new(1,-24,1,-1), Position=UDim2.fromOffset(12,1),
                    BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=0,
                    CanvasSize=UDim2.new(), AutomaticCanvasSize=Enum.AutomaticSize.Y, Parent=box,
                }, {
                    New("UIListLayout", { Padding=UDim.new(0,10), SortOrder=Enum.SortOrder.LayoutOrder }),
                    New("UIPadding", { PaddingTop=UDim.new(0,10), PaddingBottom=UDim.new(0,10) }),
                })
                local n=0
                local function row(h) n+=1; return New("Frame", { Size=UDim2.new(1,0,0,h), BackgroundTransparency=1, LayoutOrder=n, Parent=list }) end
                local function flag(f,v) if f then ApexEngine.Flags[f]=v end end

                function G:AddCheckbox(o)
                    o = type(o)=="string" and {Name=o} or o
                    local state=o.Default or false
                    local r=row(17)
                    local lbl=Label({ Text=o.Name, Size=UDim2.new(1,-40,1,0), TextColor3=state and Theme.Text or Theme.TextDisabled, Parent=r })
                    local sw=New("TextButton", {
                        Size=UDim2.fromOffset(30,17), Position=UDim2.new(1,-30,0,0),
                        BackgroundColor3=Theme.FrameInactive, AutoButtonColor=false, Text="", Parent=r,
                    }, { Corner(10), Stroke() })
                    local knob=New("Frame", {
                        Size=UDim2.fromOffset(14,14), AnchorPoint=Vector2.new(0.5,0.5),
                        Position=UDim2.new(0,8,0.5,0), BackgroundColor3=Theme.TextDisabled, Parent=sw,
                    }, { Corner(7) })
                    local obj={}
                    function obj:Set(v)
                        state=v
                        Tween(sw,.25,{BackgroundColor3=v and Theme.FrameActive or Theme.FrameInactive})
                        Tween(knob,.25,{Position=UDim2.new(0,v and 22 or 8,0.5,0), BackgroundColor3=v and Theme.Accent or Theme.TextDisabled})
                        lbl.TextColor3=v and Theme.Text or Theme.TextDisabled
                        flag(o.Flag,v)
                        if o.Callback then task.spawn(o.Callback,v) end
                    end
                    function obj:Get() return state end
                    sw.MouseButton1Click:Connect(function() obj:Set(not state) end)
                    if state then sw.BackgroundColor3=Theme.FrameActive; knob.Position=UDim2.new(0,22,0.5,0); knob.BackgroundColor3=Theme.Accent end
                    flag(o.Flag,state); return obj
                end

                function G:AddSlider(o)
                    local min,max=o.Min or 0,o.Max or 100
                    local val=math.clamp(o.Default or min,min,max)
                    local suffix=o.Suffix or ""
                    local r=row(16)
                    Label({ Text=o.Name, TextColor3=Theme.TextDisabled, Size=UDim2.new(1,-135,1,0), Parent=r })
                    local bar=New("TextButton", {
                        Size=UDim2.fromOffset(92,4), Position=UDim2.new(1,-130,0,6),
                        BackgroundColor3=Theme.FrameActive, AutoButtonColor=false, Text="", Parent=r,
                    }, { Corner(5) })
                    local fill=New("Frame", { Size=UDim2.new(0,0,1,0), BackgroundColor3=Theme.Accent, BorderSizePixel=0, Parent=bar }, { Corner(5) })
                    local grab=New("Frame", {
                        Size=UDim2.fromOffset(12,12), AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0,-2,0.5,0),
                        BackgroundColor3=Theme.Accent, Parent=bar,
                    }, { Corner(6) })
                    local vbox=New("Frame", { Size=UDim2.fromOffset(30,17), Position=UDim2.new(1,-30,0,1), BackgroundColor3=Theme.FrameInactive, Parent=r }, { Corner(4), Stroke() })
                    local vt=Label({ Text="", TextSize=12, TextXAlignment=Enum.TextXAlignment.Center, Size=UDim2.fromScale(1,1), Parent=vbox })
                    local obj={}
                    function obj:Set(v,instant)
                        v=math.clamp(v,min,max)
                        if not o.Decimals then v=math.floor(v+0.5) else v=math.floor(v*10^o.Decimals+.5)/10^o.Decimals end
                        val=v
                        local p=(v-min)/(max-min); local t=instant and 0 or .12
                        Tween(fill,t,{Size=UDim2.new(p,0,1,0)}); Tween(grab,t,{Position=UDim2.new(p,-2,0.5,0)})
                        vt.Text=tostring(v)..suffix; flag(o.Flag,v)
                        if o.Callback then task.spawn(o.Callback,v) end
                    end
                    function obj:Get() return val end
                    local sliding=false
                    local function update(x) obj:Set(min+(max-min)*math.clamp((x-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)) end
                    bar.InputBegan:Connect(function(i)
                        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then sliding=true; update(i.Position.X) end
                    end)
                    table.insert(_sliders, function(x) if x==nil then sliding=false elseif sliding then update(x) end end)
                    obj:Set(val,true); return obj
                end

                function G:AddDropdown(o)
                    local items=o.Items or {}; local sel=o.Default or items[1]
                    local r=row(20); r.ZIndex=5
                    Label({ Text=o.Name, TextColor3=Theme.TextDisabled, Size=UDim2.new(1,-135,1,0), Parent=r })
                    local box=New("TextButton", {
                        Size=UDim2.fromOffset(130,20), Position=UDim2.new(1,-130,0,0),
                        BackgroundColor3=Theme.FrameInactive, AutoButtonColor=false, Text="", Parent=r,
                    }, { Corner(3), Stroke() })
                    local pv=Label({ Text=tostring(sel or ""), TextColor3=Theme.TextDisabled, ClipsDescendants=true,
                        Size=UDim2.new(1,-24,1,0), Position=UDim2.fromOffset(4,0), Parent=box })
                    Label({ Text="▼", TextSize=9, TextXAlignment=Enum.TextXAlignment.Center,
                        Size=UDim2.fromOffset(14,20), Position=UDim2.new(1,-17,0,0), Parent=box })
                    local popup=New("ScrollingFrame", {
                        Visible=false, ZIndex=50, Size=UDim2.fromOffset(130,0),
                        BackgroundColor3=Theme.FrameInactive, BackgroundTransparency=0.1, BorderSizePixel=0,
                        ScrollBarThickness=2, ScrollBarImageColor3=Theme.Accent,
                        CanvasSize=UDim2.new(), AutomaticCanvasSize=Enum.AutomaticSize.Y, Parent=gui,
                    }, { Corner(3), Stroke(), New("UIListLayout", { SortOrder=Enum.SortOrder.LayoutOrder }) })
                    local obj,open={},false
                    local function build()
                        for _,c in ipairs(popup:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
                        for i,it in ipairs(items) do
                            local b=New("TextButton", {
                                Size=UDim2.new(1,0,0,20), BackgroundColor3=Theme.FrameActive,
                                BackgroundTransparency=(it==sel) and 0.3 or 1, AutoButtonColor=false, ZIndex=51,
                                Text="  "..tostring(it), Font=Theme.Font, TextSize=Theme.TextSize,
                                TextColor3=(it==sel) and Theme.Text or Theme.TextDisabled,
                                TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=i, Parent=popup,
                            })
                            b.MouseEnter:Connect(function() if it~=sel then b.TextColor3=Theme.Text end end)
                            b.MouseLeave:Connect(function() if it~=sel then b.TextColor3=Theme.TextDisabled end end)
                            b.MouseButton1Click:Connect(function() obj:Set(it); obj:Close() end)
                        end
                    end
                    function obj:Close()
                        open=false
                        Tween(popup,.15,{Size=UDim2.fromOffset(130,0)}).Completed:Connect(function() if not open then popup.Visible=false end end)
                    end
                    function obj:Open()
                        open=true; build(); popup.Visible=true
                        Tween(popup,.2,{Size=UDim2.fromOffset(130,math.min(#items,8)*20)})
                        task.defer(function() if not open then return end; local ap=box.AbsolutePosition; popup.Position=UDim2.fromOffset(ap.X,ap.Y+22) end)
                    end
                    function obj:Set(v) sel=v; pv.Text=tostring(v); flag(o.Flag,v); if o.Callback then task.spawn(o.Callback,v) end end
                    function obj:Refresh(newItems) items=newItems; if open then build() end end
                    function obj:Get() return sel end
                    box.MouseEnter:Connect(function() Tween(box,.2,{BackgroundColor3=Theme.FrameInactive:Lerp(Theme.FrameActive,.5)}) end)
                    box.MouseLeave:Connect(function() Tween(box,.2,{BackgroundColor3=Theme.FrameInactive}) end)
                    box.MouseButton1Click:Connect(function() if open then obj:Close() else obj:Open() end end)
                    UserInputService.InputBegan:Connect(function(i)
                        if open and i.UserInputType==Enum.UserInputType.MouseButton1 then
                            local m,p,s=i.Position,popup.AbsolutePosition,popup.AbsoluteSize
                            local b,bs=box.AbsolutePosition,box.AbsoluteSize
                            if not (m.X>=p.X and m.X<=p.X+s.X and m.Y>=p.Y and m.Y<=p.Y+s.Y) and
                               not (m.X>=b.X and m.X<=b.X+bs.X and m.Y>=b.Y and m.Y<=b.Y+bs.Y) then obj:Close() end
                        end
                    end)
                    flag(o.Flag,sel); return obj
                end
                G.AddCombo = G.AddDropdown

                function G:AddColorPicker(o)
                    local h,s,v=(o.Default or Color3.new(1,1,1)):ToHSV()
                    local alpha=o.Alpha or 1
                    local r=row(16)
                    Label({ Text=o.Name, TextColor3=Theme.TextDisabled, Size=UDim2.new(1,-30,1,0), Parent=r })
                    local prev=New("TextButton", {
                        Size=UDim2.fromOffset(16,16), Position=UDim2.new(1,-16,0,0),
                        BackgroundColor3=Color3.fromHSV(h,s,v), AutoButtonColor=false, Text="", Parent=r,
                    }, { Corner(8) })
                    local pop=New("Frame", { Visible=false, ZIndex=60, Size=UDim2.fromOffset(180,214), BackgroundColor3=Theme.FrameInactive, Parent=gui }, { Corner(4), Stroke() })
                    local sv=New("ImageButton", { ZIndex=61, Size=UDim2.fromOffset(164,164), Position=UDim2.fromOffset(8,8), BackgroundColor3=Color3.fromHSV(h,1,1), AutoButtonColor=false, Image="", Parent=pop }, { Corner(4) })
                    New("Frame", { ZIndex=62, Size=UDim2.fromScale(1,1), BackgroundColor3=Color3.new(1,1,1), Parent=sv }, { Corner(4), New("UIGradient", { Transparency=NumberSequence.new(0,1) }) })
                    New("Frame", { ZIndex=63, Size=UDim2.fromScale(1,1), BackgroundColor3=Color3.new(0,0,0), Parent=sv }, { Corner(4), New("UIGradient", { Rotation=90, Transparency=NumberSequence.new(1,0) }) })
                    local svKnob=New("Frame", { ZIndex=64, Size=UDim2.fromOffset(8,8), AnchorPoint=Vector2.new(.5,.5), BackgroundTransparency=1, Parent=sv }, { Corner(4), Stroke(Color3.new(1,1,1),0) })
                    local hue=New("ImageButton", { ZIndex=61, Size=UDim2.fromOffset(164,8), Position=UDim2.fromOffset(8,178), BackgroundColor3=Color3.new(1,1,1), AutoButtonColor=false, Image="", Parent=pop }, { Corner(4), New("UIGradient", { Color=ColorSequence.new({ ColorSequenceKeypoint.new(0,Color3.fromHSV(0,1,1)), ColorSequenceKeypoint.new(1/6,Color3.fromHSV(1/6,1,1)), ColorSequenceKeypoint.new(2/6,Color3.fromHSV(2/6,1,1)), ColorSequenceKeypoint.new(3/6,Color3.fromHSV(3/6,1,1)), ColorSequenceKeypoint.new(4/6,Color3.fromHSV(4/6,1,1)), ColorSequenceKeypoint.new(5/6,Color3.fromHSV(5/6,1,1)), ColorSequenceKeypoint.new(1,Color3.fromHSV(1,1,1)) }) }) })
                    local hueKnob=New("Frame", { ZIndex=62, Size=UDim2.fromOffset(12,12), AnchorPoint=Vector2.new(.5,.5), Position=UDim2.new(h,0,.5,0), BackgroundColor3=Color3.fromHSV(h,1,1), Parent=hue }, { Corner(6) })
                    local abar=New("ImageButton", { ZIndex=61, Size=UDim2.fromOffset(164,8), Position=UDim2.fromOffset(8,196), BackgroundColor3=Color3.fromHSV(h,s,v), AutoButtonColor=false, Image="", Parent=pop }, { Corner(3), New("UIGradient", { Transparency=NumberSequence.new(1,0) }) })
                    local aKnob=New("Frame", { ZIndex=62, Size=UDim2.fromOffset(12,12), AnchorPoint=Vector2.new(.5,.5), Position=UDim2.new(alpha,0,.5,0), BackgroundColor3=Color3.fromHSV(h,s,v), Parent=abar }, { Corner(6) })
                    local obj={}
                    local function refresh()
                        local c=Color3.fromHSV(h,s,v); prev.BackgroundColor3=c; sv.BackgroundColor3=Color3.fromHSV(h,1,1)
                        svKnob.Position=UDim2.fromScale(s,1-v); hueKnob.Position=UDim2.new(h,0,.5,0); hueKnob.BackgroundColor3=Color3.fromHSV(h,1,1)
                        abar.BackgroundColor3=c; aKnob.Position=UDim2.new(alpha,0,.5,0); aKnob.BackgroundColor3=c
                        flag(o.Flag,c); if o.Callback then task.spawn(o.Callback,c,alpha) end
                    end
                    function obj:Set(c,a) h,s,v=c:ToHSV(); alpha=a or alpha; refresh() end
                    function obj:Get() return Color3.fromHSV(h,s,v),alpha end
                    local mode
                    local function drag(pos)
                        if mode=="sv" then s=math.clamp((pos.X-sv.AbsolutePosition.X)/sv.AbsoluteSize.X,0,1); v=1-math.clamp((pos.Y-sv.AbsolutePosition.Y)/sv.AbsoluteSize.Y,0,1)
                        elseif mode=="h" then h=math.clamp((pos.X-hue.AbsolutePosition.X)/hue.AbsoluteSize.X,0,0.999)
                        elseif mode=="a" then alpha=math.clamp((pos.X-abar.AbsolutePosition.X)/abar.AbsoluteSize.X,0,1) end
                        refresh()
                    end
                    for el,m in pairs({[sv]="sv",[hue]="h",[abar]="a"}) do
                        el.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then mode=m; drag(i.Position) end end)
                    end
                    table.insert(_colorModes, function(pos) if pos==nil then mode=nil elseif mode then drag(pos) end end)
                    prev.MouseButton1Click:Connect(function()
                        pop.Visible=not pop.Visible
                        if pop.Visible then task.defer(function() if not pop.Visible then return end; local ap=prev.AbsolutePosition; pop.Position=UDim2.fromOffset(ap.X+24,ap.Y) end) end
                    end)
                    UserInputService.InputBegan:Connect(function(i)
                        if pop.Visible and i.UserInputType==Enum.UserInputType.MouseButton1 then
                            local m,p,sz=i.Position,pop.AbsolutePosition,pop.AbsoluteSize; local b=prev.AbsolutePosition
                            if not (m.X>=p.X and m.X<=p.X+sz.X and m.Y>=p.Y and m.Y<=p.Y+sz.Y) and
                               not (m.X>=b.X and m.X<=b.X+16 and m.Y>=b.Y and m.Y<=b.Y+16) then pop.Visible=false end
                        end
                    end)
                    refresh(); return obj
                end

                function G:AddKeybind(o)
                    local key=o.Default; local r=row(20)
                    Label({ Text=o.Name, TextColor3=Theme.TextDisabled, Size=UDim2.new(1,-75,1,0), Parent=r })
                    local b=New("TextButton", {
                        Size=UDim2.fromOffset(70,20), Position=UDim2.new(1,-70,0,0), BackgroundColor3=Theme.FrameInactive,
                        AutoButtonColor=false, Text=key and key.Name or "None", Font=Theme.Font, TextSize=12,
                        TextColor3=Theme.TextDisabled, Parent=r,
                    }, { Corner(3), Stroke() })
                    local listening=false
                    b.MouseButton1Click:Connect(function() listening=true; b.Text="..." end)
                    UserInputService.InputBegan:Connect(function(i,gp)
                        if listening and i.UserInputType==Enum.UserInputType.Keyboard then
                            listening=false; key=(i.KeyCode~=Enum.KeyCode.Escape) and i.KeyCode or nil
                            b.Text=key and key.Name or "None"; flag(o.Flag,key)
                        elseif not gp and key and i.KeyCode==key and o.Callback then
                            task.spawn(o.Callback,key)
                        end
                    end)
                    flag(o.Flag,key)
                end

                function G:AddButton(o)
                    o=type(o)=="string" and {Name=o} or o; local r=row(25)
                    local b=New("TextButton", {
                        Size=UDim2.fromScale(1,1), BackgroundColor3=Theme.Button, AutoButtonColor=false,
                        Text=o.Name, Font=Theme.Font, TextSize=Theme.TextSize, TextColor3=Theme.TextDisabled, Parent=r,
                    }, { Corner(4), Stroke() })
                    b.MouseEnter:Connect(function() Tween(b,.15,{BackgroundColor3=Theme.ButtonHovered}); b.TextColor3=Theme.Text end)
                    b.MouseLeave:Connect(function() Tween(b,.15,{BackgroundColor3=Theme.Button}); b.TextColor3=Theme.TextDisabled end)
                    b.MouseButton1Down:Connect(function() Tween(b,.1,{BackgroundColor3=Theme.ButtonActive}) end)
                    b.MouseButton1Up:Connect(function() Tween(b,.1,{BackgroundColor3=Theme.ButtonHovered}) end)
                    b.MouseButton1Click:Connect(function() if o.Callback then task.spawn(o.Callback) end end)
                    return b
                end

                function G:AddSeparator()
                    local r=row(1); r.BackgroundColor3=Theme.Border; r.BackgroundTransparency=0.94; r.BorderSizePixel=0
                end
                function G:AddLabel(text)
                    local r=row(14); return Label({ Text=text, TextColor3=Theme.TextDisabled, Size=UDim2.fromScale(1,1), Parent=r })
                end
                return G
            end
            table.insert(Tab.Subtabs,Sub); layoutSubs()
            if Window.CurrentTab==Tab and not Tab.Current then Sub:Select() end
            return Sub
        end
        function Tab:AddGroup(...) Tab._default=Tab._default or Tab:AddSubtab("General"); return Tab._default:AddGroup(...) end
        table.insert(Window.Tabs,Tab)
        if not Window.CurrentTab then Tab:Select() end
        return Tab
    end

    function Window:Destroy() blur:Destroy(); gui:Destroy(); ApexEngine:Destroy() end
    Window._authed = authed
    return Window
end

-- ============================================================
-- ICONS
-- ============================================================
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
    eye        = "rbxassetid://95400397758754",
    world      = "rbxassetid://83365140694071",
    config     = "rbxassetid://136566823798983",
}

-- ============================================================
-- CREATE WINDOW
-- ============================================================
local Window = ApexEngine:CreateWindow({ Title = "APEX ENGINE", Blur = 12 })

-- ============================================================
-- TABS
-- ============================================================
local CombatTab  = Window:AddTab("Combat",  Icons.crosshairs)
local VisualTab  = Window:AddTab("Visual",  Icons.eye)
local WorldTab   = Window:AddTab("World",   Icons.world)
local PlayerTab  = Window:AddTab("Player",  Icons.user)
local ConfigTab  = Window:AddTab("Configs", Icons.config)

-- ============================================================
-- COMBAT TAB
-- ============================================================
local CombatPage = CombatTab:AddSubtab("Main")

-- Left: Aim Assistance
local aimG = CombatPage:AddGroup("Aim Assistance", Icons.crosshairs, "Left", 320)
aimG:AddCheckbox({ Name="Silent Aim",    Default=false, Flag="sa_enabled" })
aimG:AddKeybind({  Name="Silent Aim Key",Default=Enum.KeyCode.Q, Flag="sa_key" })
aimG:AddDropdown({ Name="Aim Part", Items={"Head","UpperTorso","LowerTorso","HumanoidRootPart"}, Default="Head", Flag="sa_part" })
aimG:AddSlider({   Name="FOV",           Min=10,Max=500,Default=80,Suffix="px",Flag="sa_fov" })
aimG:AddSlider({   Name="Hitchance",     Min=1, Max=100, Default=100, Suffix="%", Flag="sa_hitchance" })
aimG:AddSeparator()
aimG:AddCheckbox({ Name="Triggerbot",    Default=false, Flag="tb_enabled" })
aimG:AddKeybind({  Name="Triggerbot Key",Default=Enum.KeyCode.CapsLock, Flag="tb_key" })
aimG:AddSlider({   Name="Trigger FOV",  Min=1, Max=60, Default=15, Suffix="px", Flag="tb_fov" })
aimG:AddSlider({   Name="Reaction Delay",Min=0,Max=500,Default=50,Suffix="ms",Flag="tb_delay" })

-- Left: Aimbot
local abG = CombatPage:AddGroup("Aimbot", Icons.mouse, "Left", 260)
abG:AddCheckbox({ Name="Enabled",       Default=false, Flag="ab_enabled" })
abG:AddKeybind({  Name="Aimbot Key",    Default=Enum.KeyCode.E, Flag="ab_key" })
abG:AddDropdown({ Name="Aim Part", Items={"Head","UpperTorso","LowerTorso","HumanoidRootPart"}, Default="Head", Flag="ab_part" })
abG:AddSlider({   Name="FOV",           Min=10,Max=500,Default=80,Suffix="px",Flag="ab_fov" })
abG:AddCheckbox({ Name="Prediction",    Default=true,  Flag="ab_predict" })
abG:AddSlider({   Name="Smoothness",    Min=1, Max=50, Default=10, Flag="ab_smooth" })
abG:AddSlider({   Name="Strength",      Min=1, Max=100,Default=50, Suffix="%", Flag="ab_strength" })

-- Right: Misc Combat
local miscG = CombatPage:AddGroup("Misc", Icons.feather, "Right", 200)
miscG:AddCheckbox({ Name="No Recoil",   Default=false, Flag="no_recoil" })
miscG:AddSeparator()
miscG:AddCheckbox({ Name="Tracer",      Default=false, Flag="tracer_enabled" })
miscG:AddColorPicker({ Name="Tracer Color", Default=Color3.fromRGB(255,80,80), Flag="tracer_col" })
miscG:AddDropdown({ Name="Tracer Origin", Items={"Bottom","Center","Top"}, Default="Bottom", Flag="tracer_origin" })

-- ============================================================
-- VISUAL TAB
-- ============================================================
local VisualPage = VisualTab:AddSubtab("ESP")

local espG = VisualPage:AddGroup("ESP", Icons.eye, "Left", 340)
espG:AddCheckbox({ Name="Enabled",        Default=false, Flag="esp_enabled" })
espG:AddSeparator()
espG:AddCheckbox({ Name="Box",            Default=true,  Flag="esp_box" })
espG:AddColorPicker({ Name="Box Color",   Default=Color3.fromRGB(255,255,255), Flag="esp_box_col" })
espG:AddSeparator()
espG:AddCheckbox({ Name="Name",           Default=true,  Flag="esp_name" })
espG:AddColorPicker({ Name="Name Color",  Default=Color3.fromRGB(255,255,255), Flag="esp_name_col" })
espG:AddSeparator()
espG:AddCheckbox({ Name="Health Bar",     Default=true,  Flag="esp_health" })
espG:AddColorPicker({ Name="Health Color",Default=Color3.fromRGB(80,255,120),  Flag="esp_health_col" })
espG:AddSeparator()
espG:AddCheckbox({ Name="Distance",       Default=false, Flag="esp_dist" })
espG:AddSlider({   Name="Max Distance",   Min=50,Max=5000,Default=1500,Suffix="m",Flag="esp_maxdist" })
espG:AddSlider({   Name="Text Size",      Min=8,Max=24,Default=13,Flag="esp_textsize" })

local espR = VisualPage:AddGroup("Extra", Icons.ghost, "Right", 260)
espR:AddCheckbox({ Name="Tracers",        Default=false, Flag="esp_tracer" })
espR:AddColorPicker({ Name="Tracer Color",Default=Color3.fromRGB(0,180,255),   Flag="esp_tracer_col" })
espR:AddDropdown({ Name="Tracer Origin",  Items={"Bottom","Center","Mouse"},   Default="Bottom", Flag="esp_tracer_origin" })
espR:AddSeparator()
espR:AddCheckbox({ Name="Highlight",      Default=false, Flag="esp_chams" })
espR:AddColorPicker({ Name="Fill Color",  Default=Color3.fromRGB(255,60,90),   Flag="esp_fill_col" })
espR:AddSlider({   Name="Fill Opacity",   Min=0,Max=100,Default=50,Suffix="%", Flag="esp_fill_opacity" })
espR:AddColorPicker({ Name="Outline Color",Default=Color3.fromRGB(255,255,255),Flag="esp_outline_col" })

-- ============================================================
-- WORLD TAB
-- ============================================================
local WorldPage = WorldTab:AddSubtab("Environment")

local lightG = WorldPage:AddGroup("Lighting", Icons.pallet, "Left", 300)
lightG:AddCheckbox({ Name="Full Bright",    Default=false, Flag="w_fullbright" })
lightG:AddCheckbox({ Name="No Fog",         Default=false, Flag="w_nofog" })
lightG:AddCheckbox({ Name="No Shadows",     Default=false, Flag="w_noshadows" })
lightG:AddSeparator()
lightG:AddCheckbox({ Name="Custom Ambient", Default=false, Flag="w_ambient" })
lightG:AddColorPicker({ Name="Ambient Color",Default=Color3.fromRGB(120,120,160), Flag="w_ambient_col" })
lightG:AddSlider({   Name="Brightness",     Min=0,Max=10,Default=2,Decimals=1,Flag="w_bright" })
lightG:AddSeparator()
lightG:AddCheckbox({ Name="Force Time",     Default=false, Flag="w_forcetime" })
lightG:AddSlider({   Name="Time of Day",    Min=0,Max=24,Default=14,Suffix="h",Flag="w_time" })

local envG = WorldPage:AddGroup("Environment", Icons.world, "Right", 220)
envG:AddCheckbox({ Name="No Trees",         Default=false, Flag="w_notrees" })
envG:AddCheckbox({ Name="No Grass",         Default=false, Flag="w_nograss" })
envG:AddSeparator()
envG:AddCheckbox({ Name="Bloom",            Default=false, Flag="w_bloom" })
envG:AddSlider({   Name="Bloom Intensity",  Min=0,Max=100,Default=40,Suffix="%",Flag="w_bloom_int" })

-- ============================================================
-- PLAYER TAB
-- ============================================================
local PlayerPage = PlayerTab:AddSubtab("Movement")

local moveG = PlayerPage:AddGroup("Movement", Icons.user, "Left", 160)
moveG:AddCheckbox({ Name="Omni Sprint",     Default=false, Flag="m_omnisprint" })
moveG:AddSeparator()
moveG:AddCheckbox({ Name="Fly",             Default=false, Flag="m_fly" })
moveG:AddSlider({   Name="Fly Speed",       Min=1,Max=100,Default=20,Flag="m_flyspeed" })

local miscPG = PlayerPage:AddGroup("Misc", Icons.hammer, "Right", 280)
miscPG:AddCheckbox({ Name="Free Cam",       Default=false, Flag="m_freecam" })
miscPG:AddKeybind({  Name="Free Cam Key",   Default=Enum.KeyCode.V, Flag="m_freecam_key", Callback=function()
    ApexEngine.Flags["m_freecam"] = not ApexEngine.Flags["m_freecam"]
end })
miscPG:AddSlider({   Name="Cam Speed",      Min=10, Max=200, Default=50, Flag="m_freecam_speed" })
miscPG:AddSeparator()
miscPG:AddCheckbox({ Name="No Clip",        Default=false, Flag="m_noclip" })
miscPG:AddSeparator()
miscPG:AddCheckbox({ Name="X-Ray",          Default=false, Flag="m_xray" })
miscPG:AddColorPicker({ Name="X-Ray Color", Default=Color3.fromRGB(255, 80, 200), Flag="m_xray_col" })
miscPG:AddSeparator()
miscPG:AddCheckbox({ Name="Zoom",           Default=false, Flag="m_zoom" })
miscPG:AddKeybind({  Name="Zoom Key",       Default=Enum.KeyCode.Z, Flag="m_zoom_key" })
miscPG:AddSlider({   Name="Zoom FOV",       Min=5, Max=60, Default=20, Flag="m_zoom_fov" })

-- ============================================================
-- CONFIG TAB
-- ============================================================
local CFG_FOLDER = "ApexEngine/configs"
if isfolder and not isfolder(CFG_FOLDER) then pcall(function() makefolder(CFG_FOLDER) end) end

local function listConfigs()
    local list={}
    if listfiles then pcall(function() for _,f in ipairs(listfiles(CFG_FOLDER)) do local n=f:match("([^/\\]+)%.json$"); if n then list[#list+1]=n end end end) end
    if #list==0 then list={"default"} end
    return list
end
local function saveConfig(name)
    if not name or name=="" then return end
    local data={}
    for k,v in pairs(ApexEngine.Flags) do
        local t=type(v)
        if t=="boolean" or t=="number" or t=="string" then data[k]=v
        elseif t=="userdata" then
            if typeof(v)=="Color3" then data[k]={__type="Color3",r=v.R,g=v.G,b=v.B}
            elseif typeof(v)=="EnumItem" then data[k]={__type="EnumItem",enum=tostring(v.EnumType),value=v.Name} end
        end
    end
    pcall(function() writefile(CFG_FOLDER.."/"..name..".json", game:GetService("HttpService"):JSONEncode(data)) end)
end
local function loadConfig(name)
    if not name or name=="" then return end
    local raw = (isfile and isfile(CFG_FOLDER.."/"..name..".json")) and readfile(CFG_FOLDER.."/"..name..".json") or nil
    if not raw then return end
    local ok,data=pcall(function() return game:GetService("HttpService"):JSONDecode(raw) end)
    if not ok or not data then return end
    for k,v in pairs(data) do
        if type(v)=="table" then
            if v.__type=="Color3" then ApexEngine.Flags[k]=Color3.new(v.r,v.g,v.b)
            elseif v.__type=="EnumItem" then pcall(function() ApexEngine.Flags[k]=Enum[v.enum][v.value] end) end
        else ApexEngine.Flags[k]=v end
    end
end

local ConfigPage = ConfigTab:AddSubtab("Configs")
local cfgLeft = ConfigPage:AddGroup("Configs", Icons.save, "Left", 240)
local cfgDrop = cfgLeft:AddDropdown({ Name="Config", Items=listConfigs(), Flag="cfg_sel" })
-- Name input via keybind label trick: use a slider as a name index isn't ideal,
-- so we store a pending name in a closure updated by the Save button prompt.
-- Simple approach: save uses cfg_sel name, user renames via OS or picks from list.
cfgLeft:AddButton({ Name="Save (overwrite)", Callback=function()
    local name=ApexEngine.Flags["cfg_sel"]; if not name or name=="" then return end
    saveConfig(name); cfgDrop:Refresh(listConfigs()); cfgDrop:Set(name)
end })
cfgLeft:AddButton({ Name="Save as 'new'", Callback=function()
    local name="new"
    saveConfig(name); cfgDrop:Refresh(listConfigs()); cfgDrop:Set(name)
end })
cfgLeft:AddButton({ Name="Load", Callback=function()
    local name=ApexEngine.Flags["cfg_sel"]; if not name or name=="" then return end; loadConfig(name)
end })
cfgLeft:AddButton({ Name="Delete", Callback=function()
    local name=ApexEngine.Flags["cfg_sel"]; if not name or name=="" then return end
    pcall(function() delfile(CFG_FOLDER.."/"..name..".json") end); cfgDrop:Refresh(listConfigs())
end })

local cfgRight = ConfigPage:AddGroup("Interface", Icons.hammer, "Right", 160)
cfgRight:AddKeybind({ Name="Hide UI Key", Default=Enum.KeyCode.RightShift, Flag="hide_key", Callback=function(key)
    ApexEngine.ToggleKey = key
end })
cfgRight:AddCheckbox({ Name="Watermark", Default=true, Flag="m_watermark" })
cfgRight:AddCheckbox({ Name="Auto Load", Default=false, Flag="cfg_autoload" })

-- ============================================================
-- WATERMARK + FPS
-- ============================================================
local Camera = workspace.CurrentCamera
local wmGui = Instance.new("ScreenGui", GetParentGui())
wmGui.Name="ApexWatermark"; wmGui.ResetOnSpawn=false; wmGui.ZIndexBehavior=Enum.ZIndexBehavior.Global

local wmFrame = New("Frame", {
    Size=UDim2.fromOffset(300,24), Position=UDim2.fromOffset(8,8),
    BackgroundColor3=Theme.WindowBg, BackgroundTransparency=0.3, BorderSizePixel=0, Parent=wmGui,
}, { Corner(4), Stroke() })
local wmLabel = Label({ Text="APEX ENGINE  |  "..GAME_NAME.."  |  0:00  |  0 fps  |  0 ms",
    Font=Theme.FontBold, TextSize=12, TextColor3=Theme.Accent,
    Size=UDim2.fromScale(1,1), TextXAlignment=Enum.TextXAlignment.Center, Parent=wmFrame })

local _wmStart = os.clock()
local _wmFrames = 0
local _wmFpsSample = _wmStart
RunService.RenderStepped:Connect(function() _wmFrames+=1 end)

local _hbTick = 0
RunService.Heartbeat:Connect(function(dt)
    local flags = ApexEngine.Flags
    _hbTick += dt
    if _hbTick < 0.1 then return end
    _hbTick = 0

    wmFrame.Visible = flags["m_watermark"] ~= false
    if wmFrame.Visible then
        local now = os.clock()
        local elapsed = math.floor(now - _wmStart)
        local h=math.floor(elapsed/3600); local m=math.floor(elapsed%3600/60); local s=elapsed%60
        local timeStr = h>0 and string.format("%d:%02d:%02d",h,m,s) or string.format("%d:%02d",m,s)
        local dur = math.max(now-_wmFpsSample,0.001)
        local fps = math.floor(_wmFrames/dur+0.5)
        local ms  = math.floor(dt*1000+0.5)
        _wmFrames=0; _wmFpsSample=now
        wmLabel.Text = "APEX ENGINE  |  "..GAME_NAME.."  |  "..timeStr.."  |  "..fps.." fps  |  "..ms.." ms"
    end

    -- ── World ────────────────────────────────────────────
    -- Fullbright / ambient
    if flags["w_fullbright"] then
        Lighting.Brightness=10
        Lighting.Ambient=Color3.new(1,1,1)
        Lighting.OutdoorAmbient=Color3.new(1,1,1)
    elseif flags["w_ambient"] then
        local c=flags["w_ambient_col"] or Color3.fromRGB(120,120,160)
        Lighting.Ambient=c; Lighting.OutdoorAmbient=c
        Lighting.Brightness=flags["w_bright"] or 2
    end
    -- No fog
    if flags["w_nofog"] then
        Lighting.FogEnd=9e8; Lighting.FogStart=9e8
    end
    -- No shadows
    Lighting.GlobalShadows = not (flags["w_noshadows"] == true)
    -- Force time
    if flags["w_forcetime"] then
        Lighting.ClockTime = flags["w_time"] or 14
    end
    -- Bloom
    local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
    if bloom then
        bloom.Enabled = flags["w_bloom"] == true
        if bloom.Enabled then bloom.Intensity=(flags["w_bloom_int"] or 40)/100*2 end
    end
    -- No grass (force every tick so terrain can't re-enable it)
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then terrain.Decoration = flags["w_nograss"] ~= true end

    -- ── Player ───────────────────────────────────────────
    -- Omni Sprint: override WalkSpeed to sprint speed in any move direction
    if flags["m_omnisprint"] then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 and hum.MoveDirection.Magnitude > 0.05 then
            hum.WalkSpeed = 20
        end
    end
end)

-- ============================================================
-- WORLD: persistent watchers
-- ============================================================
do
    -- Saved originals for restore
    local _origBrightness    = Lighting.Brightness
    local _origAmbient       = Lighting.Ambient
    local _origOutdoor       = Lighting.OutdoorAmbient
    local _origFogEnd        = Lighting.FogEnd
    local _origFogStart      = Lighting.FogStart
    local _origGlobalShadows = Lighting.GlobalShadows
    local _origClockTime     = Lighting.ClockTime

    -- Restore lighting when features turn off
    local _prevFullbright, _prevAmbient, _prevFog, _prevShadows, _prevTime = false,false,false,false,false
    trackConnection(RunService.Heartbeat:Connect(function()
        local flags = ApexEngine.Flags
        -- Fullbright restore
        if _prevFullbright and not flags["w_fullbright"] and not flags["w_ambient"] then
            Lighting.Brightness=_origBrightness; Lighting.Ambient=_origAmbient; Lighting.OutdoorAmbient=_origOutdoor
        end
        _prevFullbright = flags["w_fullbright"] == true
        -- Ambient restore
        if _prevAmbient and not flags["w_ambient"] and not flags["w_fullbright"] then
            Lighting.Brightness=_origBrightness; Lighting.Ambient=_origAmbient; Lighting.OutdoorAmbient=_origOutdoor
        end
        _prevAmbient = flags["w_ambient"] == true
        -- Fog restore
        if _prevFog and not flags["w_nofog"] then
            Lighting.FogEnd=_origFogEnd; Lighting.FogStart=_origFogStart
        end
        _prevFog = flags["w_nofog"] == true
        -- Shadows restore
        if _prevShadows and not flags["w_noshadows"] then
            Lighting.GlobalShadows=_origGlobalShadows
        end
        _prevShadows = flags["w_noshadows"] == true
        -- Time restore
        if _prevTime and not flags["w_forcetime"] then
            Lighting.ClockTime=_origClockTime
        end
        _prevTime = flags["w_forcetime"] == true
    end))

    -- No Trees: unparent existing + watch ChildAdded
    local _noTreesConn = nil
    local _hiddenTrees = {} -- {obj, originalParent}

    local function hideObj(obj, parent)
        if obj.Parent then
            _hiddenTrees[#_hiddenTrees+1] = {obj, obj.Parent}
            obj.Parent = nil
        end
    end

    local function applyNoTrees(enabled)
        if enabled then
            local sh = workspace:FindFirstChild("SpawnedHarvestables")
            if sh then
                for _,v in ipairs(sh:GetChildren()) do
                    local tf = v:GetAttribute("TemplateFolder")
                    if tf=="Trees" or tf=="PineTrees" then
                        hideObj(v)
                    end
                    -- also hide Leaves inside any tree container
                    local leaves = v:FindFirstChild("Leaves")
                    if leaves then hideObj(leaves) end
                end
                if not _noTreesConn then
                    _noTreesConn = sh.ChildAdded:Connect(function(v)
                        if not ApexEngine.Flags["w_notrees"] then return end
                        local tf = v:GetAttribute("TemplateFolder")
                        if tf=="Trees" or tf=="PineTrees" then
                            task.defer(function() hideObj(v) end)
                        end
                        local leaves = v:FindFirstChild("Leaves")
                        if leaves then task.defer(function() hideObj(leaves) end) end
                    end)
                end
            end
        else
            if _noTreesConn then _noTreesConn:Disconnect(); _noTreesConn=nil end
            for _,entry in ipairs(_hiddenTrees) do
                pcall(function() entry[1].Parent = entry[2] end)
            end
            table.clear(_hiddenTrees)
        end
    end

    local _prevNoTrees = false
    trackConnection(RunService.Heartbeat:Connect(function()
        local cur = ApexEngine.Flags["w_notrees"] == true
        if cur ~= _prevNoTrees then
            _prevNoTrees = cur
            applyNoTrees(cur)
        end
    end))
end

-- Auto load config
if ApexEngine.Flags["cfg_autoload"] then
    local sel=ApexEngine.Flags["cfg_sel"]
    if sel and sel~="" then pcall(function() loadConfig(sel) end) end
end

-- ============================================================
-- COMBAT
-- ============================================================
do
    local GunFire = nil

    -- ── Shared helpers ────────────────────────────────────────
    local function getEnemies()
        local list = {}
        local myChar = LocalPlayer.Character
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LocalPlayer then continue end
            local char = p.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if char and hum and hum.Health > 0 and root then
                list[#list+1] = { player=p, char=char, hum=hum, root=root }
            end
        end
        return list
    end

    local function getAimPart(char, partName)
        return char:FindFirstChild(partName) or char:FindFirstChild("HumanoidRootPart")
    end

    local function screenDist(worldPos)
        local cam = workspace.CurrentCamera
        local sp, onScreen = cam:WorldToViewportPoint(worldPos)
        if not onScreen or sp.Z <= 0 then return math.huge end
        local vp = cam.ViewportSize
        local cx, cy = vp.X/2, vp.Y/2
        return math.sqrt((sp.X-cx)^2 + (sp.Y-cy)^2)
    end

    local function getClosestEnemy(partName, fovPx)
        local best, bestDist = nil, fovPx or math.huge
        for _, e in ipairs(getEnemies()) do
            local part = getAimPart(e.char, partName or "Head")
            if part then
                local d = screenDist(part.Position)
                if d < bestDist then bestDist = d; best = e end
            end
        end
        return best
    end

    -- ── FOV circle ────────────────────────────────────────────
    local fovGui = Instance.new("ScreenGui")
    fovGui.Name = "ApexFOV"
    fovGui.ResetOnSpawn = false
    fovGui.IgnoreGuiInset = true
    fovGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    fovGui.Parent = GetParentGui()

    local fovCircle = Instance.new("Frame")
    fovCircle.BackgroundTransparency = 1
    fovCircle.BorderSizePixel = 0
    fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
    fovCircle.Visible = false
    fovCircle.Parent = fovGui
    local fovStroke = Instance.new("UICorner")
    fovStroke.CornerRadius = UDim.new(1, 0)
    fovStroke.Parent = fovCircle
    local fovBorder = Instance.new("UIStroke")
    fovBorder.Color = Color3.fromRGB(255,255,255)
    fovBorder.Transparency = 0.4
    fovBorder.Thickness = 1
    fovBorder.Parent = fovCircle

    trackConnection(RunService.RenderStepped:Connect(function()
        local flags = ApexEngine.Flags
        local showFov = (flags["sa_enabled"] or flags["ab_enabled"]) == true
        if showFov then
            local cam = workspace.CurrentCamera
            local vp  = cam.ViewportSize
            local fov = flags["sa_enabled"] and (flags["sa_fov"] or 80) or (flags["ab_fov"] or 80)
            fovCircle.Position = UDim2.fromOffset(vp.X/2, vp.Y/2)
            fovCircle.Size     = UDim2.fromOffset(fov*2, fov*2)
            fovCircle.Visible  = true
        else
            fovCircle.Visible = false
        end
    end))

    -- ── Silent Aim ────────────────────────────────────────────
    -- GunFire:FireServer(muzzlePos, origin, direction, gunName, serverTime, isADS, sessionId, shotSeq, droneViewPose)
    -- We replace `direction` (arg 3 after self) with unit vector toward aim part.
    local rs = game:GetService("ReplicatedStorage")
    task.spawn(function()
        local gf = rs:WaitForChild("GunFire", 15)
        if gf then GunFire = gf end
    end)

    local _saHooked = false
    trackConnection(RunService.Heartbeat:Connect(function()
        local flags = ApexEngine.Flags
        if not _saHooked and GunFire and hookfunction then
            _saHooked = true
            local orig = GunFire.FireServer
            hookfunction(orig, newcclosure(function(self, muzzlePos, origin, direction, gunName, ...)
                if flags["sa_enabled"] and UserInputService:IsKeyDown(flags["sa_key"] or Enum.KeyCode.Q) then
                    local hitchance = flags["sa_hitchance"] or 100
                    if math.random(1,100) <= hitchance then
                        local partName = flags["sa_part"] or "Head"
                        local fov      = flags["sa_fov"] or 80
                        local target   = getClosestEnemy(partName, fov)
                        if target then
                            local part = getAimPart(target.char, partName)
                            if part and typeof(muzzlePos) == "Vector3" then
                                direction = (part.Position - muzzlePos).Unit
                            end
                        end
                    end
                end
                return orig(self, muzzlePos, origin, direction, gunName, ...)
            end))
        end
    end))

    -- ── No Recoil ─────────────────────────────────────────────
    -- The recoil RenderStep is bound as "Recoil_" .. tool.Name per ClientGun.
    -- Unbinding it each frame when no_recoil is on is the cleanest approach.
    local _noRecoilUnbound = {}
    trackConnection(RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        if not char then table.clear(_noRecoilUnbound); return end
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                local bindName = "Recoil_" .. tool.Name
                if ApexEngine.Flags["no_recoil"] then
                    RunService:UnbindFromRenderStep(bindName)
                    _noRecoilUnbound[bindName] = true
                elseif _noRecoilUnbound[bindName] then
                    -- Was unbound; ClientGun will rebind on next shot naturally
                    _noRecoilUnbound[bindName] = nil
                end
            end
        end
    end))

    -- ── Aimbot ────────────────────────────────────────────────
    trackConnection(RunService.RenderStepped:Connect(function(dt)
        local flags = ApexEngine.Flags
        if not flags["ab_enabled"] then return end
        local key = flags["ab_key"] or Enum.KeyCode.E
        if not UserInputService:IsKeyDown(key) then return end

        local partName = flags["ab_part"] or "Head"
        local fov      = flags["ab_fov"] or 80
        local smooth   = flags["ab_smooth"] or 10
        local strength = (flags["ab_strength"] or 50) / 100

        local target = getClosestEnemy(partName, fov)
        if not target then return end

        local part = getAimPart(target.char, partName)
        if not part then return end

        -- Prediction: lead target by velocity
        local targetPos = part.Position
        if flags["ab_predict"] then
            local root = target.root
            local vel  = root.AssemblyLinearVelocity
            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if myRoot then
                local dist = (targetPos - myRoot.Position).Magnitude
                local travelTime = dist / 500 -- approx bullet speed
                targetPos = targetPos + vel * travelTime
            end
        end

        local cam = workspace.CurrentCamera
        local sp, onScreen = cam:WorldToViewportPoint(targetPos)
        if not onScreen or sp.Z <= 0 then return end

        local vp = cam.ViewportSize
        local cx, cy = vp.X/2, vp.Y/2
        local dx = (sp.X - cx) * strength
        local dy = (sp.Y - cy) * strength
        local lerpFactor = math.clamp(dt * (100 / smooth), 0, 1)

        -- Move mouse toward target
        if mousemoverel then
            mousemoverel(dx * lerpFactor, dy * lerpFactor)
        elseif mouse1press then
            -- fallback: CFrame camera nudge
            local cf = cam.CFrame
            local targetCF = CFrame.lookAt(cf.Position, targetPos)
            cam.CFrame = cf:Lerp(targetCF, lerpFactor * strength)
        end
    end))

    -- ── Triggerbot ────────────────────────────────────────────
    local _tbLastFire = 0
    trackConnection(RunService.Heartbeat:Connect(function()
        local flags = ApexEngine.Flags
        if not flags["tb_enabled"] then return end
        local key = flags["tb_key"] or Enum.KeyCode.CapsLock
        if not UserInputService:IsKeyDown(key) then return end

        local fov   = flags["tb_fov"] or 15
        local delay = (flags["tb_delay"] or 50) / 1000
        if os.clock() - _tbLastFire < delay then return end

        local target = getClosestEnemy("Head", fov)
        if not target then return end

        _tbLastFire = os.clock()
        -- Simulate left click
        if mouse1press and mouse1release then
            mouse1press()
            task.delay(0.05, mouse1release)
        end
    end))
end

-- ============================================================
-- ESP
-- ============================================================
do
    local espGui = Instance.new("ScreenGui")
    espGui.Name = "ApexESP"
    espGui.ResetOnSpawn = false
    espGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    espGui.IgnoreGuiInset = true
    espGui.Parent = GetParentGui()

    -- Per-player ESP state
    local _espData = {} -- [player] = { box, nameLabel, healthBg, healthFill, distLabel, tracer, highlight }

    local function getChar(p)
        return p ~= LocalPlayer and p.Character or nil
    end
    local function getHum(char)
        return char and char:FindFirstChildOfClass("Humanoid")
    end
    local function getRoot(char)
        return char and char:FindFirstChild("HumanoidRootPart")
    end
    local function getHead(char)
        return char and char:FindFirstChild("Head")
    end

    -- World → screen with visibility check
    local function worldToScreen(pos)
        local cam = workspace.CurrentCamera
        local sp, onScreen = cam:WorldToViewportPoint(pos)
        return Vector2.new(sp.X, sp.Y), onScreen, sp.Z
    end

    -- Get 2D bounding box from character
    local function getCharBounds(char)
        local cam = workspace.CurrentCamera
        local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
        local visible = false
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                local sp, onScreen = cam:WorldToViewportPoint(part.Position)
                if onScreen and sp.Z > 0 then
                    visible = true
                    if sp.X < minX then minX = sp.X end
                    if sp.Y < minY then minY = sp.Y end
                    if sp.X > maxX then maxX = sp.X end
                    if sp.Y > maxY then maxY = sp.Y end
                end
            end
        end
        if not visible then return nil end
        return minX, minY, maxX, maxY
    end

    local function makeESP(p)
        if _espData[p] then return end
        local d = {}

        -- Box (4 lines via Frames)
        local boxFrame = Instance.new("Frame")
        boxFrame.BackgroundTransparency = 1
        boxFrame.BorderSizePixel = 0
        boxFrame.Size = UDim2.fromOffset(0, 0)
        boxFrame.Visible = false
        boxFrame.Parent = espGui
        local function makeLine()
            local f = Instance.new("Frame")
            f.BorderSizePixel = 0
            f.BackgroundColor3 = Color3.new(1,1,1)
            f.Parent = boxFrame
            return f
        end
        d.boxTop    = makeLine()
        d.boxBottom = makeLine()
        d.boxLeft   = makeLine()
        d.boxRight  = makeLine()
        d.boxFrame  = boxFrame

        -- Name label
        local nameL = Instance.new("TextLabel")
        nameL.BackgroundTransparency = 1
        nameL.TextStrokeTransparency = 0.5
        nameL.TextStrokeColor3 = Color3.new(0,0,0)
        nameL.Font = Enum.Font.GothamBold
        nameL.TextSize = 13
        nameL.Visible = false
        nameL.Parent = espGui
        d.nameLabel = nameL

        -- Health bar (bg + fill)
        local hBg = Instance.new("Frame")
        hBg.BackgroundColor3 = Color3.fromRGB(20,20,20)
        hBg.BorderSizePixel = 0
        hBg.Visible = false
        hBg.Parent = espGui
        local hFill = Instance.new("Frame")
        hFill.BackgroundColor3 = Color3.fromRGB(80,255,120)
        hFill.BorderSizePixel = 0
        hFill.AnchorPoint = Vector2.new(0,1)
        hFill.Parent = hBg
        d.healthBg   = hBg
        d.healthFill = hFill

        -- Distance label
        local distL = Instance.new("TextLabel")
        distL.BackgroundTransparency = 1
        distL.TextStrokeTransparency = 0.5
        distL.TextStrokeColor3 = Color3.new(0,0,0)
        distL.Font = Enum.Font.GothamBold
        distL.TextSize = 11
        distL.Visible = false
        distL.Parent = espGui
        d.distLabel = distL

        -- Tracer (single line Frame)
        local tracerF = Instance.new("Frame")
        tracerF.BackgroundColor3 = Color3.fromRGB(0,180,255)
        tracerF.BorderSizePixel = 0
        tracerF.AnchorPoint = Vector2.new(0.5, 0)
        tracerF.Visible = false
        tracerF.Parent = espGui
        d.tracer = tracerF

        -- Highlight (chams)
        local hl = Instance.new("Highlight")
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Enabled = false
        hl.Parent = espGui
        d.highlight = hl

        _espData[p] = d
    end

    local function removeESP(p)
        local d = _espData[p]
        if not d then return end
        pcall(function() d.boxFrame:Destroy() end)
        pcall(function() d.nameLabel:Destroy() end)
        pcall(function() d.healthBg:Destroy() end)
        pcall(function() d.distLabel:Destroy() end)
        pcall(function() d.tracer:Destroy() end)
        pcall(function() d.highlight:Destroy() end)
        _espData[p] = nil
    end

    local function hideESP(d)
        d.boxFrame.Visible  = false
        d.nameLabel.Visible = false
        d.healthBg.Visible  = false
        d.distLabel.Visible = false
        d.tracer.Visible    = false
        d.highlight.Enabled = false
    end

    -- Draw a box using 4 line frames
    local function drawBox(d, x1, y1, x2, y2, col, thick)
        thick = thick or 1
        local w, h = x2-x1, y2-y1
        d.boxFrame.Position = UDim2.fromOffset(x1, y1)
        d.boxFrame.Size     = UDim2.fromOffset(w, h)
        d.boxFrame.Visible  = true
        -- top
        d.boxTop.Position    = UDim2.fromOffset(0, 0)
        d.boxTop.Size        = UDim2.fromOffset(w, thick)
        d.boxTop.BackgroundColor3 = col
        -- bottom
        d.boxBottom.Position = UDim2.fromOffset(0, h - thick)
        d.boxBottom.Size     = UDim2.fromOffset(w, thick)
        d.boxBottom.BackgroundColor3 = col
        -- left
        d.boxLeft.Position   = UDim2.fromOffset(0, 0)
        d.boxLeft.Size       = UDim2.fromOffset(thick, h)
        d.boxLeft.BackgroundColor3 = col
        -- right
        d.boxRight.Position  = UDim2.fromOffset(w - thick, 0)
        d.boxRight.Size      = UDim2.fromOffset(thick, h)
        d.boxRight.BackgroundColor3 = col
    end

    -- Draw tracer line from origin point to target screen pos
    local function drawTracer(d, tx, ty, col, origin)
        local cam = workspace.CurrentCamera
        local vp  = cam.ViewportSize
        local ox, oy
        if origin == "Center" then
            ox, oy = vp.X/2, vp.Y/2
        elseif origin == "Mouse" then
            local mp = UserInputService:GetMouseLocation()
            ox, oy = mp.X, mp.Y
        else -- Bottom
            ox, oy = vp.X/2, vp.Y
        end
        local dx, dy = tx - ox, ty - oy
        local len = math.sqrt(dx*dx + dy*dy)
        if len < 1 then d.tracer.Visible = false; return end
        local angle = math.atan2(dy, dx)
        d.tracer.Position  = UDim2.fromOffset(ox, oy)
        d.tracer.Size      = UDim2.fromOffset(len, 1)
        d.tracer.Rotation  = math.deg(angle)
        d.tracer.BackgroundColor3 = col
        d.tracer.Visible   = true
    end

    -- Main ESP update loop
    trackConnection(RunService.RenderStepped:Connect(function()
        local flags = ApexEngine.Flags
        local enabled = flags["esp_enabled"] == true
        local cam = workspace.CurrentCamera
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local maxDist = flags["esp_maxdist"] or 1500
        local textSize = flags["esp_textsize"] or 13

        for _, p in ipairs(Players:GetPlayers()) do
            if p == LocalPlayer then continue end

            -- Ensure ESP objects exist
            if not _espData[p] then makeESP(p) end
            local d = _espData[p]
            if not d then continue end

            local char = getChar(p)
            local hum  = getHum(char)
            local root = getRoot(char)
            local head = getHead(char)

            -- Hide if disabled or dead/no char
            if not enabled or not char or not hum or hum.Health <= 0 or not root or not head then
                hideESP(d); continue
            end

            -- Distance check
            local dist = myRoot and (root.Position - myRoot.Position).Magnitude or 0
            if dist > maxDist then hideESP(d); continue end

            -- Check on screen
            local headSP, onScreen = worldToScreen(head.Position)
            if not onScreen then hideESP(d); continue end

            -- Bounding box
            local x1, y1, x2, y2 = getCharBounds(char)
            if not x1 then hideESP(d); continue end

            -- Pad box slightly
            local pad = 2
            x1 -= pad; y1 -= pad; x2 += pad; y2 += pad
            local bw, bh = x2-x1, y2-y1

            -- Box
            if flags["esp_box"] then
                local col = flags["esp_box_col"] or Color3.new(1,1,1)
                drawBox(d, x1, y1, x2, y2, col, 1)
            else
                d.boxFrame.Visible = false
            end

            -- Name
            if flags["esp_name"] then
                local col = flags["esp_name_col"] or Color3.new(1,1,1)
                d.nameLabel.Text      = p.DisplayName
                d.nameLabel.TextColor3 = col
                d.nameLabel.TextSize  = textSize
                d.nameLabel.Size      = UDim2.fromOffset(bw + 20, textSize + 4)
                d.nameLabel.Position  = UDim2.fromOffset(x1 - 10, y1 - textSize - 4)
                d.nameLabel.TextXAlignment = Enum.TextXAlignment.Center
                d.nameLabel.Visible   = true
            else
                d.nameLabel.Visible = false
            end

            -- Health bar (left side, vertical)
            if flags["esp_health"] then
                local hp  = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                local col = flags["esp_health_col"] or Color3.fromRGB(80,255,120)
                local barW = 3
                d.healthBg.Position = UDim2.fromOffset(x1 - barW - 2, y1)
                d.healthBg.Size     = UDim2.fromOffset(barW, bh)
                d.healthBg.Visible  = true
                d.healthFill.BackgroundColor3 = col
                d.healthFill.Size     = UDim2.new(1, 0, hp, 0)
                d.healthFill.Position = UDim2.new(0, 0, 1 - hp, 0)
            else
                d.healthBg.Visible = false
            end

            -- Distance
            if flags["esp_dist"] then
                local col = flags["esp_name_col"] or Color3.new(1,1,1)
                d.distLabel.Text       = math.floor(dist).."m"
                d.distLabel.TextColor3 = col
                d.distLabel.TextSize   = textSize - 2
                d.distLabel.Size       = UDim2.fromOffset(bw + 20, textSize)
                d.distLabel.Position   = UDim2.fromOffset(x1 - 10, y2 + 2)
                d.distLabel.TextXAlignment = Enum.TextXAlignment.Center
                d.distLabel.Visible    = true
            else
                d.distLabel.Visible = false
            end

            -- Tracer
            if flags["esp_tracer"] then
                local col    = flags["esp_tracer_col"] or Color3.fromRGB(0,180,255)
                local origin = flags["esp_tracer_origin"] or "Bottom"
                local cx     = (x1 + x2) / 2
                drawTracer(d, cx, y2, col, origin)
            else
                d.tracer.Visible = false
            end

            -- Highlight / chams
            if flags["esp_chams"] then
                local fillCol     = flags["esp_fill_col"]     or Color3.fromRGB(255,60,90)
                local outlineCol  = flags["esp_outline_col"]  or Color3.new(1,1,1)
                local fillOpacity = (flags["esp_fill_opacity"] or 50) / 100
                d.highlight.Adornee          = char
                d.highlight.FillColor        = fillCol
                d.highlight.FillTransparency = 1 - fillOpacity
                d.highlight.OutlineColor     = outlineCol
                d.highlight.OutlineTransparency = 0
                d.highlight.Enabled          = true
            else
                d.highlight.Enabled = false
            end
        end

        -- Clean up left players
        for p, _ in pairs(_espData) do
            if not p.Parent then removeESP(p) end
        end
    end))

    -- Hook player added/removed
    Players.PlayerAdded:Connect(function(p)
        p.CharacterRemoving:Connect(function()
            local d = _espData[p]
            if d then hideESP(d) end
        end)
    end)
    Players.PlayerRemoving:Connect(removeESP)

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            p.CharacterRemoving:Connect(function()
                local d = _espData[p]
                if d then hideESP(d) end
            end)
        end
    end
end

-- ============================================================
-- FREE CAM
-- ============================================================
do
    local Camera       = workspace.CurrentCamera
    local _fcActive    = false
    local _fcCF        = CFrame.new(0, 20, 0)
    local _fcYaw       = 0
    local _fcPitch     = 0
    local _fcConn      = nil
    local _fcInputConn = nil
    local _origCamType = nil
    local _origCamSubj = nil

    local function enableFreeCam()
        if _fcActive then return end
        _fcActive = true
        Camera = workspace.CurrentCamera
        _origCamType = Camera.CameraType
        _origCamSubj = Camera.CameraSubject
        -- Seed position from current camera
        _fcCF = Camera.CFrame
        local rx, ry, rz = _fcCF:ToEulerAnglesYXZ()
        _fcYaw   = ry
        _fcPitch = rx
        Camera.CameraType = Enum.CameraType.Scriptable
        -- Lock mouse
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        -- Mouse delta → yaw/pitch
        _fcInputConn = UserInputService.InputChanged:Connect(function(i)
            if not _fcActive then return end
            if i.UserInputType == Enum.UserInputType.MouseMovement then
                local sens = 0.003
                _fcYaw   = _fcYaw   - i.Delta.X * sens
                _fcPitch = math.clamp(_fcPitch - i.Delta.Y * sens, -math.pi/2 + 0.01, math.pi/2 - 0.01)
            end
        end)
        -- RenderStepped: move + apply CFrame
        _fcConn = RunService.RenderStepped:Connect(function(dt)
            if not _fcActive then return end
            Camera = workspace.CurrentCamera
            local speed = (ApexEngine.Flags["m_freecam_speed"] or 50) * dt
            -- Shift = 3x boost
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then speed = speed * 3 end
            local cf = CFrame.new(_fcCF.Position) * CFrame.Angles(0, _fcYaw, 0) * CFrame.Angles(_fcPitch, 0, 0)
            local fwd   = cf.LookVector
            local right = cf.RightVector
            local up    = Vector3.new(0, 1, 0)
            local move  = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + fwd   end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - fwd   end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + right end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - right end
            if UserInputService:IsKeyDown(Enum.KeyCode.E) then move = move + up    end
            if UserInputService:IsKeyDown(Enum.KeyCode.Q) then move = move - up    end
            if move.Magnitude > 0.001 then
                _fcCF = CFrame.new(_fcCF.Position + move.Unit * speed)
            end
            Camera.CFrame = CFrame.new(_fcCF.Position) * CFrame.Angles(0, _fcYaw, 0) * CFrame.Angles(_fcPitch, 0, 0)
        end)
    end

    local function disableFreeCam()
        if not _fcActive then return end
        _fcActive = false
        if _fcConn      then _fcConn:Disconnect();      _fcConn      = nil end
        if _fcInputConn then _fcInputConn:Disconnect(); _fcInputConn = nil end
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        Camera = workspace.CurrentCamera
        Camera.CameraType    = _origCamType or Enum.CameraType.Custom
        Camera.CameraSubject = _origCamSubj
    end

    -- Watch flag changes
    local _prevFC = false
    trackConnection(RunService.Heartbeat:Connect(function()
        local cur = ApexEngine.Flags["m_freecam"] == true
        if cur == _prevFC then return end
        _prevFC = cur
        if cur then enableFreeCam() else disableFreeCam() end
    end))

    -- Disable on character respawn (camera subject resets)
    LocalPlayer.CharacterAdded:Connect(function()
        if _fcActive then
            disableFreeCam()
            ApexEngine.Flags["m_freecam"] = false
        end
    end)
end

-- ============================================================
-- X-RAY
-- ============================================================
do
    local _xrayData = {} -- [player] = Highlight

    local function ensureXray(p)
        if _xrayData[p] then return end
        local hl = Instance.new("Highlight")
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
        hl.Enabled = false
        hl.Parent = game:GetService("CoreGui")
        _xrayData[p] = hl
    end

    local function removeXray(p)
        local hl = _xrayData[p]
        if hl then pcall(function() hl:Destroy() end); _xrayData[p] = nil end
    end

    trackConnection(RunService.Heartbeat:Connect(function()
        local flags = ApexEngine.Flags
        local enabled = flags["m_xray"] == true
        local col = flags["m_xray_col"] or Color3.fromRGB(255, 80, 200)
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LocalPlayer then continue end
            ensureXray(p)
            local hl = _xrayData[p]
            local char = p.Character
            if enabled and char then
                hl.Adornee = char
                hl.FillColor = col
                hl.OutlineColor = col
                hl.Enabled = true
            else
                hl.Enabled = false
            end
        end
        -- clean up
        for p in pairs(_xrayData) do
            if not p.Parent then removeXray(p) end
        end
    end))

    Players.PlayerRemoving:Connect(removeXray)
end

-- ============================================================
-- ZOOM
-- ============================================================
do
    local _origFOV = nil
    local _zooming = false

    trackConnection(RunService.RenderStepped:Connect(function()
        local flags = ApexEngine.Flags
        if not flags["m_zoom"] then
            if _zooming then
                workspace.CurrentCamera.FieldOfView = _origFOV or 70
                _zooming = false; _origFOV = nil
            end
            return
        end
        local key = flags["m_zoom_key"] or Enum.KeyCode.Z
        local holding = UserInputService:IsKeyDown(key)
        if holding and not _zooming then
            _origFOV = workspace.CurrentCamera.FieldOfView
            _zooming = true
        elseif not holding and _zooming then
            workspace.CurrentCamera.FieldOfView = _origFOV or 70
            _zooming = false; _origFOV = nil
        end
        if _zooming then
            workspace.CurrentCamera.FieldOfView = flags["m_zoom_fov"] or 20
        end
    end))
end

return ApexEngine
