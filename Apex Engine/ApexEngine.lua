
--[[
    Apex Engine — Brisk Survival cheat
    Designed and developed by Foreman (discord: TheOfficialForeman)
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
                    Label({ Text="v", TextSize=9, TextXAlignment=Enum.TextXAlignment.Center,
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
aimG:AddKeybind({  Name="SA Toggle Key", Default=Enum.KeyCode.Q, Flag="sa_key", Callback=function() ApexEngine.Flags["sa_enabled"] = not ApexEngine.Flags["sa_enabled"] end })
aimG:AddDropdown({ Name="Aim Part", Items={"Head","Torso","Left Arm","Right Arm","Left Leg","Right Leg"}, Default="Head", Flag="sa_part" })
aimG:AddSlider({   Name="FOV",           Min=10,Max=500,Default=80,Suffix="px",Flag="sa_fov" })
aimG:AddSlider({   Name="Hitchance",     Min=1, Max=100, Default=100, Suffix="%", Flag="sa_hitchance" })
aimG:AddSeparator()


-- Left: Aimbot
local abG = CombatPage:AddGroup("Aimbot", Icons.mouse, "Left", 340)
abG:AddCheckbox({ Name="Enabled",       Default=false, Flag="ab_enabled" })
abG:AddKeybind({  Name="AB Toggle Key", Default=Enum.KeyCode.E, Flag="ab_key", Callback=function() ApexEngine.Flags["ab_enabled"] = not ApexEngine.Flags["ab_enabled"] end })
abG:AddDropdown({ Name="Aim Part", Items={"Head","Torso","Left Arm","Right Arm","Left Leg","Right Leg"}, Default="Head", Flag="ab_part" })
abG:AddSlider({   Name="FOV",           Min=10,Max=500,Default=80,Suffix="px",Flag="ab_fov" })
abG:AddCheckbox({ Name="Prediction",    Default=true,  Flag="ab_predict" })
abG:AddSlider({   Name="Smoothness",    Min=1, Max=50, Default=10, Flag="ab_smooth" })
abG:AddSeparator()


-- Right: Misc Combat
local miscG = CombatPage:AddGroup("Misc", Icons.feather, "Right", 440)
miscG:AddCheckbox({ Name="No Recoil",      Default=false, Flag="no_recoil" })
miscG:AddCheckbox({ Name="No Spread",       Default=false, Flag="no_spread" })
miscG:AddSeparator()
miscG:AddCheckbox({ Name="Rapid Fire",      Default=false, Flag="rapid_fire" })
miscG:AddSlider({   Name="RF Multiplier",   Min=2, Max=10, Default=3, Flag="rapid_fire_mult" })
miscG:AddSeparator()
miscG:AddCheckbox({ Name="Always Headshot", Default=false, Flag="always_headshot" })
miscG:AddCheckbox({ Name="Instant Bullet",  Default=false, Flag="instant_bullet" })
miscG:AddSeparator()
miscG:AddCheckbox({ Name="Bullet Tracers",  Default=false, Flag="bullet_tracers" })
miscG:AddColorPicker({ Name="Tracer Color", Default=Color3.fromRGB(255,80,80), Flag="tracer_col" })
miscG:AddSeparator()
miscG:AddCheckbox({ Name="Spinbot",         Default=false, Flag="spinbot" })
miscG:AddSlider({   Name="Spin Speed",      Min=1,Max=50,Default=25,Flag="spinbot_speed" })
miscG:AddDropdown({ Name="Spin Pitch",      Items={"Normal","Down","Jitter"}, Default="Normal", Flag="spinbot_pitch" })

-- Right: Snapline
local snapG = CombatPage:AddGroup("Snapline", Icons.dagger, "Right", 220)
snapG:AddCheckbox({ Name="Enabled",       Default=false, Flag="snap_enabled" })
snapG:AddColorPicker({ Name="Color",       Default=Color3.fromRGB(255,200,0), Flag="snap_col" })
snapG:AddDropdown({ Name="Origin",        Items={"Bottom","Center"}, Default="Bottom", Flag="snap_origin" })
snapG:AddSlider({   Name="Thickness",     Min=1,Max=5,Default=1,Flag="snap_thick" })

-- Right: Target Lines
local tlineG = CombatPage:AddGroup("Target Lines", Icons.dagger, "Right", 260)
tlineG:AddCheckbox({ Name="Enabled",       Default=false, Flag="tl_enabled" })
tlineG:AddColorPicker({ Name="Color",       Default=Color3.fromRGB(255,50,50), Flag="tl_col" })
tlineG:AddDropdown({ Name="Target Part",   Items={"Head","Torso","Left Arm","Right Arm","Left Leg","Right Leg"}, Default="Head", Flag="tl_part" })
tlineG:AddDropdown({ Name="Origin",        Items={"Bottom","Center","Mouse"}, Default="Bottom", Flag="tl_origin" })
tlineG:AddCheckbox({ Name="Closest Only",  Default=true,  Flag="tl_closest" })
tlineG:AddSlider({   Name="Max Distance",  Min=50,Max=2000,Default=800,Suffix="m",Flag="tl_maxdist" })

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

local espR = VisualPage:AddGroup("Extra", Icons.ghost, "Right", 340)
espR:AddCheckbox({ Name="Tracers",        Default=false, Flag="esp_tracer" })
espR:AddColorPicker({ Name="Tracer Color",Default=Color3.fromRGB(0,180,255),   Flag="esp_tracer_col" })
espR:AddDropdown({ Name="Tracer Origin",  Items={"Bottom","Center","Mouse"},   Default="Bottom", Flag="esp_tracer_origin" })
espR:AddSeparator()
espR:AddCheckbox({ Name="Highlight",      Default=false, Flag="esp_chams" })
espR:AddColorPicker({ Name="Fill Color",  Default=Color3.fromRGB(255,60,90),   Flag="esp_fill_col" })
espR:AddSlider({   Name="Fill Opacity",   Min=0,Max=100,Default=50,Suffix="%", Flag="esp_fill_opacity" })
espR:AddColorPicker({ Name="Outline Color",Default=Color3.fromRGB(255,255,255),Flag="esp_outline_col" })
espR:AddSeparator()
espR:AddCheckbox({ Name="Crosshair",      Default=false, Flag="crosshair_enabled" })
espR:AddColorPicker({ Name="CH Color",    Default=Color3.fromRGB(255,255,255), Flag="crosshair_col" })
espR:AddSlider({   Name="CH Gap",         Min=1,Max=20,Default=4,Flag="crosshair_gap" })
espR:AddSlider({   Name="CH Size",        Min=2,Max=30,Default=8,Flag="crosshair_size" })
espR:AddSlider({   Name="CH Thickness",   Min=1,Max=5,Default=1,Flag="crosshair_thick" })

-- ============================================================
-- WORLD ESP TAB (extra subtab on Visual)
-- ============================================================
local WorldESPPage = VisualTab:AddSubtab("World")

local wespLeft = WorldESPPage:AddGroup("Resources", Icons.world, "Left", 380)
wespLeft:AddCheckbox({ Name="Harvestables",  Default=false, Flag="wesp_harv" })
wespLeft:AddCheckbox({ Name="Ore / Stone",   Default=false, Flag="wesp_ore" })
wespLeft:AddSeparator()
wespLeft:AddCheckbox({ Name="Sleepers",      Default=false, Flag="wesp_sleepers" })
wespLeft:AddSeparator()
wespLeft:AddCheckbox({ Name="Placed C4",     Default=false, Flag="wesp_c4" })
wespLeft:AddCheckbox({ Name="C4 Alert",      Default=false, Flag="wesp_c4_alert" })
wespLeft:AddSeparator()
wespLeft:AddCheckbox({ Name="Rockets",       Default=false, Flag="wesp_rockets" })
wespLeft:AddCheckbox({ Name="Rocket Timer",  Default=true,  Flag="wesp_rocket_timer" })
wespLeft:AddSeparator()
wespLeft:AddSlider({   Name="Max Distance",  Min=50,Max=3000,Default=1000,Suffix="m",Flag="wesp_maxdist" })

local wespRight = WorldESPPage:AddGroup("Deployables", Icons.hammer, "Right", 300)
wespRight:AddCheckbox({ Name="Turrets",       Default=false, Flag="wesp_turrets" })
wespRight:AddCheckbox({ Name="Storage Boxes", Default=false, Flag="wesp_storage" })
wespRight:AddCheckbox({ Name="Sleeping Bags", Default=false, Flag="wesp_beds" })
wespRight:AddCheckbox({ Name="Barricades",    Default=false, Flag="wesp_barricades" })
wespRight:AddCheckbox({ Name="Other",         Default=false, Flag="wesp_other" })

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

local envG = WorldPage:AddGroup("Environment", Icons.world, "Right", 300)
envG:AddCheckbox({ Name="No Leaves",        Default=false, Flag="w_notrees" })
envG:AddCheckbox({ Name="No Grass",         Default=false, Flag="w_nograss" })
envG:AddSeparator()
envG:AddCheckbox({ Name="Bloom",            Default=false, Flag="w_bloom" })
envG:AddSlider({   Name="Bloom Intensity",  Min=0,Max=100,Default=40,Suffix="%",Flag="w_bloom_int" })
envG:AddSeparator()
envG:AddCheckbox({ Name="FOV Changer",      Default=false, Flag="w_fovchanger" })
envG:AddSlider({   Name="Custom FOV",       Min=30,Max=120,Default=70,Flag="w_customfov" })

-- ============================================================
-- PLAYER TAB
-- ============================================================
local PlayerPage = PlayerTab:AddSubtab("Movement")

local moveG = PlayerPage:AddGroup("Movement", Icons.user, "Left", 220)
moveG:AddCheckbox({ Name="Omni Sprint",     Default=false, Flag="m_omnisprint" })
moveG:AddSlider({   Name="Sprint Speed",    Min=0, Max=30, Default=0, Flag="m_omnisprint_bonus" })
moveG:AddSeparator()
moveG:AddCheckbox({ Name="Fly",             Default=false, Flag="m_fly" })
moveG:AddKeybind({  Name="Fly Toggle Key",  Default=Enum.KeyCode.G, Flag="m_fly_key", Callback=function() ApexEngine.Flags["m_fly"] = not ApexEngine.Flags["m_fly"] end })
moveG:AddSlider({   Name="Fly Speed",       Min=1,Max=100,Default=20,Flag="m_flyspeed" })
moveG:AddSeparator()
moveG:AddCheckbox({ Name="Spectate",        Default=false, Flag="m_spectate" })
moveG:AddButton({   Name="Set Spectate Target", Callback=function()
    local pg = GetParentGui()
    local ov = New("ScreenGui",{Name="ApexSpecPrompt",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,IgnoreGuiInset=true,DisplayOrder=9999,Parent=pg})
    New("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=0.55,BorderSizePixel=0,Parent=ov})
    local bx=New("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(300,90),BackgroundColor3=Theme.WindowBg,BorderSizePixel=0,Parent=ov},{Corner(10),Stroke()})
    Label({Text="Spectate target username:",Font=Theme.FontBold,TextSize=12,Size=UDim2.new(1,-20,0,18),Position=UDim2.fromOffset(10,8),Parent=bx})
    local tb=New("TextBox",{BackgroundColor3=Theme.FrameInactive,BorderSizePixel=0,ClearTextOnFocus=false,Font=Theme.Font,TextSize=12,PlaceholderText="username...",PlaceholderColor3=Theme.TextDisabled,Text=ApexEngine.Flags["m_spectate_target"] or "",TextColor3=Theme.Text,Size=UDim2.new(1,-20,0,28),Position=UDim2.fromOffset(10,30),Parent=bx},{Corner(6),Stroke(Theme.Border,0.6)})
    New("UIPadding",{PaddingLeft=UDim.new(0,8),Parent=tb})
    local ok=New("TextButton",{BackgroundColor3=Theme.Accent,AutoButtonColor=false,Text="Set",Font=Theme.FontBold,TextSize=12,TextColor3=Color3.fromRGB(8,8,8),Size=UDim2.new(0.48,-5,0,24),Position=UDim2.fromOffset(10,62),Parent=bx},{Corner(6)})
    local cl=New("TextButton",{BackgroundColor3=Theme.Button,AutoButtonColor=false,Text="Cancel",Font=Theme.Font,TextSize=12,TextColor3=Theme.TextDisabled,Size=UDim2.new(0.48,-5,0,24),Position=UDim2.new(0.52,0,0,62),Parent=bx},{Corner(6)})
    ok.MouseButton1Click:Connect(function() ApexEngine.Flags["m_spectate_target"]=tb.Text:match("^%s*(.-)%s*$"); ov:Destroy() end)
    cl.MouseButton1Click:Connect(function() ov:Destroy() end)
    tb.FocusLost:Connect(function(e) if e then ApexEngine.Flags["m_spectate_target"]=tb.Text:match("^%s*(.-)%s*$"); ov:Destroy() end end)
    task.defer(function() tb:CaptureFocus() end)
end })

local miscPG = PlayerPage:AddGroup("Misc", Icons.hammer, "Right", 280)
miscPG:AddCheckbox({ Name="Free Cam",       Default=false, Flag="m_freecam" })
miscPG:AddKeybind({  Name="Free Cam Key",   Default=Enum.KeyCode.V, Flag="m_freecam_key", Callback=function()
    ApexEngine.Flags["m_freecam"] = not ApexEngine.Flags["m_freecam"]
end })
miscPG:AddSlider({   Name="Cam Speed",      Min=10, Max=200, Default=50, Flag="m_freecam_speed" })
miscPG:AddSeparator()
miscPG:AddCheckbox({ Name="No Clip",        Default=false, Flag="m_noclip" })
miscPG:AddKeybind({  Name="NC Toggle Key",  Default=Enum.KeyCode.N, Flag="m_noclip_key", Callback=function() ApexEngine.Flags["m_noclip"] = not ApexEngine.Flags["m_noclip"] end })
miscPG:AddCheckbox({ Name="Third Person",   Default=false, Flag="m_thirdperson" })
miscPG:AddKeybind({  Name="TP Toggle Key",  Default=Enum.KeyCode.T, Flag="m_thirdperson_key", Callback=function() ApexEngine.Flags["m_thirdperson"] = not ApexEngine.Flags["m_thirdperson"] end })
miscPG:AddSlider({   Name="TP Distance",    Min=5,Max=30,Default=12,Flag="m_thirdperson_dist" })
miscPG:AddSeparator()
miscPG:AddCheckbox({ Name="X-Ray",          Default=false, Flag="m_xray" })
miscPG:AddKeybind({  Name="XR Toggle Key",  Default=Enum.KeyCode.X, Flag="m_xray_key", Callback=function() ApexEngine.Flags["m_xray"] = not ApexEngine.Flags["m_xray"] end })
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

local cfgRight = ConfigPage:AddGroup("Interface", Icons.hammer, "Right", 210)
cfgRight:AddKeybind({ Name="Hide UI Key", Default=Enum.KeyCode.RightShift, Flag="hide_key", Callback=function(key)
    ApexEngine.ToggleKey = key
end })
cfgRight:AddCheckbox({ Name="Watermark", Default=true, Flag="m_watermark" })
cfgRight:AddCheckbox({ Name="Auto Load", Default=false, Flag="cfg_autoload" })
cfgRight:AddSeparator()
cfgRight:AddButton({ Name="Unload Script", Callback=function()
    -- Clean up all runtime connections
    for _, c in ipairs(_runtimeConnections) do pcall(function() c:Disconnect() end) end
    table.clear(_runtimeConnections)
    -- Destroy GUIs
    pcall(function() Window:Destroy() end)
    pcall(function()
        for _, gui in ipairs({ "ApexWatermark", "ApexESP", "ApexFOV", "ApexEngineUI" }) do
            local g = GetParentGui():FindFirstChild(gui)
            if g then g:Destroy() end
        end
    end)
    -- Remove blur
    pcall(function()
        local b = game:GetService("Lighting"):FindFirstChild("ApexEngineBlur")
        if b then b:Destroy() end
    end)
    -- Restore camera
    pcall(function()
        local cam = workspace.CurrentCamera
        cam.CameraType = Enum.CameraType.Custom
        cam.FieldOfView = 70
        game:GetService("UserInputService").MouseBehavior = Enum.MouseBehavior.Default
    end)
    getgenv().apexengine_loaded = nil
end })

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
    -- (Omni Sprint handled in dedicated block below)
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
                        local leaves = v:FindFirstChild("Leaves")
                        if leaves then hideObj(leaves) end
                    end
                end
                if not _noTreesConn then
                    _noTreesConn = sh.ChildAdded:Connect(function(v)
                        if not ApexEngine.Flags["w_notrees"] then return end
                        local tf = v:GetAttribute("TemplateFolder")
                        if tf=="Trees" or tf=="PineTrees" then
                            task.defer(function()
                                local leaves = v:FindFirstChild("Leaves")
                                if leaves then hideObj(leaves) end
                            end)
                        end
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
-- WORLD ESP LOGIC
-- ============================================================
do
    local worldEspGui = Instance.new("ScreenGui")
    worldEspGui.Name = "ApexWorldESP"
    worldEspGui.ResetOnSpawn = false
    worldEspGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    worldEspGui.IgnoreGuiInset = true
    worldEspGui.Parent = GetParentGui()

    -- label pool: id -> { bg, lbl }
    local _wlabels = {}

    local function getLabel(id, col)
        if not _wlabels[id] then
            local bg = Instance.new("Frame")
            bg.BackgroundColor3 = Color3.new(0,0,0)
            bg.BackgroundTransparency = 0.5
            bg.BorderSizePixel = 0
            bg.AutomaticSize = Enum.AutomaticSize.XY
            bg.Parent = worldEspGui
            local lbl = Instance.new("TextLabel")
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.GothamBold
            lbl.TextSize = 11
            lbl.TextStrokeTransparency = 0.4
            lbl.TextStrokeColor3 = Color3.new(0,0,0)
            lbl.AutomaticSize = Enum.AutomaticSize.XY
            lbl.Parent = bg
            _wlabels[id] = { bg = bg, lbl = lbl }
        end
        local e = _wlabels[id]
        e.lbl.TextColor3 = col or Color3.new(1,1,1)
        return e
    end

    local function hideLabel(id)
        local e = _wlabels[id]
        if e then e.bg.Visible = false end
    end

    local function placeLabel(id, worldPos, text, col)
        local cam = workspace.CurrentCamera
        local sp, onScreen = cam:WorldToViewportPoint(worldPos)
        if not onScreen or sp.Z <= 0 then hideLabel(id); return end
        local e = getLabel(id, col)
        e.lbl.Text = text
        e.bg.Position = UDim2.fromOffset(sp.X, sp.Y)
        e.bg.Visible = true
    end

    trackConnection(RunService.RenderStepped:Connect(function()
        local flags = ApexEngine.Flags
        local cam = workspace.CurrentCamera
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local maxDist = flags["wesp_maxdist"] or 1000
        local drawn = {}

        -- Harvestables
        if flags["wesp_harv"] or flags["wesp_ore"] then
            local folder = workspace:FindFirstChild("SpawnedHarvestables")
            if folder then
                for _, obj in ipairs(folder:GetChildren()) do
                    local pos = obj:IsA("BasePart") and obj.Position
                        or (obj.PrimaryPart and obj.PrimaryPart.Position)
                    if pos and myRoot and (pos - myRoot.Position).Magnitude <= maxDist then
                        local isOre = obj.Name:find("Ore") or obj.Name == "Stone"
                        local show = (isOre and flags["wesp_ore"]) or (not isOre and flags["wesp_harv"])
                        if show then
                            local id = "harv_" .. obj:GetDebugId()
                            drawn[id] = true
                            local dist = math.floor((pos - myRoot.Position).Magnitude)
                            local col = isOre and Color3.fromRGB(250,204,21) or Color3.fromRGB(100,220,100)
                            placeLabel(id, pos, obj.Name .. " [" .. dist .. "m]", col)
                        end
                    end
                end
            end
        end

        -- Sleepers
        if flags["wesp_sleepers"] then
            local folder = workspace:FindFirstChild("OfflineSleepers")
            if folder then
                for _, obj in ipairs(folder:GetChildren()) do
                    local pos = obj:IsA("BasePart") and obj.Position
                        or (obj.PrimaryPart and obj.PrimaryPart.Position)
                    if pos and myRoot and (pos - myRoot.Position).Magnitude <= maxDist then
                        local id = "slp_" .. obj:GetDebugId()
                        drawn[id] = true
                        local dist = math.floor((pos - myRoot.Position).Magnitude)
                        placeLabel(id, pos, "SLEEPER: " .. obj.Name .. " [" .. dist .. "m]",
                            Color3.fromRGB(170,170,220))
                    end
                end
            end
        end

        -- Deployables
        local anyDeploy = flags["wesp_turrets"] or flags["wesp_storage"]
            or flags["wesp_beds"] or flags["wesp_barricades"] or flags["wesp_other"]
        if anyDeploy then
            local folder = workspace:FindFirstChild("PlacedDeployables")
            if folder then
                for _, obj in ipairs(folder:GetChildren()) do
                    local pos = obj:IsA("BasePart") and obj.Position
                        or (obj.PrimaryPart and obj.PrimaryPart.Position)
                    if pos and myRoot and (pos - myRoot.Position).Magnitude <= maxDist then
                        local kind = obj.Name
                        local col, show
                        if kind == "Turret"     and flags["wesp_turrets"]    then col = Color3.fromRGB(244,63,94);   show = true
                        elseif kind == "Storage" and flags["wesp_storage"]   then col = Color3.fromRGB(245,158,11);  show = true
                        elseif kind == "Bed"     and flags["wesp_beds"]      then col = Color3.fromRGB(99,102,241);  show = true
                        elseif kind == "Barricade" and flags["wesp_barricades"] then col = Color3.fromRGB(168,85,247); show = true
                        elseif flags["wesp_other"] then col = Color3.fromRGB(180,180,180); show = true end
                        if show then
                            local id = "dep_" .. obj:GetDebugId()
                            drawn[id] = true
                            local dist = math.floor((pos - myRoot.Position).Magnitude)
                            placeLabel(id, pos, kind .. " [" .. dist .. "m]", col)
                        end
                    end
                end
            end
        end

        -- Hide stale labels
        for id in pairs(_wlabels) do
            if not drawn[id] then hideLabel(id) end
        end
    end))
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


    -- R6 aim part resolver
    local R6_PARTS = { Head="Head", Torso="Torso" }
    R6_PARTS["Left Arm"]  = "Left Arm"
    R6_PARTS["Right Arm"] = "Right Arm"
    R6_PARTS["Left Leg"]  = "Left Leg"
    R6_PARTS["Right Leg"] = "Right Leg"
    local function getR6Part(char, name)
        return char:FindFirstChild(R6_PARTS[name] or name)
            or char:FindFirstChild("Torso")
            or char:FindFirstChild("HumanoidRootPart")
    end

    -- Silent Aim
    local rs = game:GetService("ReplicatedStorage")
    task.spawn(function()
        local gf = rs:WaitForChild("GunFire", 15)
        if gf then GunFire = gf end
    end)

    -- Bullet tracer drawing (screen-space line from muzzle to hit)
    local _tracerGui = Instance.new("ScreenGui")
    _tracerGui.Name = "ApexBulletTracers"
    _tracerGui.ResetOnSpawn = false
    _tracerGui.IgnoreGuiInset = true
    _tracerGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    _tracerGui.Parent = GetParentGui()

    local function drawBulletTracer(fromWorld, toWorld)
        local cam = workspace.CurrentCamera
        local vp  = cam.ViewportSize
        local ax, ay = vp.X / 2, vp.Y / 2
        local spB, onSc = cam:WorldToViewportPoint(toWorld)
        if not onSc or spB.Z <= 0 then return end
        local bx, by = spB.X, spB.Y
        local dx, dy = bx - ax, by - ay
        local len = math.sqrt(dx*dx + dy*dy)
        if len < 2 then return end
        local line = Instance.new("Frame")
        line.BackgroundColor3 = ApexEngine.Flags["tracer_col"] or Color3.fromRGB(255,80,80)
        line.BorderSizePixel = 0
        -- midpoint anchor so rotation is correct in both directions
        line.AnchorPoint = Vector2.new(0.5, 0.5)
        line.Position = UDim2.fromOffset((ax + bx) / 2, (ay + by) / 2)
        line.Size = UDim2.fromOffset(len, 2)
        line.Rotation = math.deg(math.atan2(dy, dx))
        line.ZIndex = 10
        line.Parent = _tracerGui
        task.delay(0.25, function() if line and line.Parent then line:Destroy() end end)
    end

    local _rapidFireActive = false

    -- Hook ALL RemoteEvent:FireServer calls via hookmetamethod so we catch every gun
    -- regardless of which remote they use. The reference confirms the game uses GunFire
    -- but we also catch any remote that passes 2+ Vector3 args as a fallback.
    if hookmetamethod and newcclosure then
        local _origNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method ~= "FireServer" then return _origNamecall(self, ...) end
            if not self:IsA("RemoteEvent") then return _origNamecall(self, ...) end

            local name = self.Name
            local isGunFire = name == "GunFire" or name == "Fire" or name == "Shoot"
                or name == "BulletFire" or name == "ShootGun" or name == "FireGun"
                or name == "GunShoot" or name == "WeaponFire" or name == "ShootEvent"
                or name == "FireWeapon" or name == "FireBullet" or name == "BulletShoot"
                or name == "ShotFired" or name == "PlayerShoot" or name == "ClientFire"
            if not isGunFire then
                -- fallback: check for 2+ Vector3 args
                local a = {...}
                local v3c = 0
                for i = 1, math.min(#a, 6) do
                    if typeof(a[i]) == "Vector3" then v3c += 1 end
                    if v3c >= 2 then isGunFire = true; break end
                end
            end
            if not isGunFire then return _origNamecall(self, ...) end

            local args = {...}
            local flags = ApexEngine.Flags
            local cam = workspace.CurrentCamera
            local origin = (typeof(args[1]) == "Vector3") and args[1] or cam.CFrame.Position

            -- Always Headshot / Instant Bullet
            if (flags["always_headshot"] or flags["instant_bullet"]) and not _rapidFireActive then
                local vp = cam.ViewportSize
                local center = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
                local fovR = flags["sa_fov"] or math.huge
                local bestDist, bestHead = fovR, nil
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        local head = p.Character:FindFirstChild("Head")
                        if head then
                            local sp, onSc = cam:WorldToViewportPoint(head.Position)
                            if onSc and sp.Z > 0.01 then
                                local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                                if d < bestDist then bestDist = d; bestHead = head end
                            end
                        end
                    end
                end
                if bestHead then
                    local targetPos = bestHead.Position
                    if flags["instant_bullet"] then
                        local delta = origin - targetPos
                        local muzzle = delta.Magnitude > 0.01 and (targetPos + delta.Unit * 2) or (targetPos + Vector3.new(0,0,2))
                        if #args >= 1 and typeof(args[1]) == "Vector3" then args[1] = muzzle end
                        origin = muzzle
                    end
                    local dir = (targetPos - origin).Unit
                    if #args >= 3 and typeof(args[3]) == "Vector3" then args[3] = dir end
                    if flags["bullet_tracers"] then task.spawn(drawBulletTracer, origin, targetPos) end
                    if flags["rapid_fire"] and not _rapidFireActive then
                        local result = _origNamecall(self, table.unpack(args))
                        _rapidFireActive = true
                        task.spawn(function()
                            for _ = 1, math.max(1, math.floor(flags["rapid_fire_mult"] or 3) - 1) do
                                task.wait()
                                task.spawn(function() _origNamecall(self, table.unpack(args)) end)
                            end
                            _rapidFireActive = false
                        end)
                        return result
                    end
                    return _origNamecall(self, table.unpack(args))
                end
            end

            -- Silent Aim
            if flags["sa_enabled"] then
                if math.random(100) <= (flags["sa_hitchance"] or 100) then
                    local partName = flags["sa_part"] or "Head"
                    local target = getClosestEnemy(partName, flags["sa_fov"] or 80)
                    if target then
                        local part = getR6Part(target.char, partName)
                        if part then
                            local vel = target.root.AssemblyLinearVelocity
                            local travelTime = (part.Position - origin).Magnitude / 500
                            local predicted = part.Position + vel * travelTime
                            if #args >= 3 then args[3] = (predicted - origin).Unit end
                            if flags["bullet_tracers"] then task.spawn(drawBulletTracer, origin, predicted) end
                        end
                    end
                end
            end

            -- No Spread
            if flags["no_spread"] and not _rapidFireActive then
                local target = getClosestEnemy(flags["sa_part"] or "Head", flags["sa_fov"] or 80)
                if target then
                    local part = getR6Part(target.char, flags["sa_part"] or "Head")
                    if part and #args >= 3 and typeof(args[3]) == "Vector3" then
                        args[3] = (part.Position - origin).Unit
                    end
                end
            end

            -- Bullet Tracers standalone
            if flags["bullet_tracers"] and typeof(args[3]) == "Vector3" then
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Exclude
                params.FilterDescendantsInstances = {LocalPlayer.Character}
                local hit = workspace:Raycast(origin, args[3] * 900, params)
                task.spawn(drawBulletTracer, origin, hit and hit.Position or (origin + args[3] * 900))
            end

            -- Rapid Fire standalone
            if flags["rapid_fire"] and not _rapidFireActive then
                local result = _origNamecall(self, table.unpack(args))
                _rapidFireActive = true
                task.spawn(function()
                    for _ = 1, math.max(1, math.floor(flags["rapid_fire_mult"] or 3) - 1) do
                        task.wait()
                        task.spawn(function() _origNamecall(self, table.unpack(args)) end)
                    end
                    _rapidFireActive = false
                end)
                return result
            end

            return _origNamecall(self, table.unpack(args))
        end))
    end

    -- No Recoil
    -- Layer 1: hook BindToRenderStep + UnbindFromRenderStep to intercept ALL Recoil_* binds
    -- including guns equipped before injection and guns that rebind on reload.
    if hookfunction and newcclosure then
        local _origBTRS  = RunService.BindToRenderStep
        local _origUBTRS = RunService.UnbindFromRenderStep
        -- track wrapped names so unbind still works
        local _wrappedRecoil = {}
        hookfunction(_origBTRS, newcclosure(function(self, name, priority, fn)
            if type(name) == "string" and name:sub(1, 7) == "Recoil_" then
                _wrappedRecoil[name] = true
                return _origBTRS(self, name, priority, newcclosure(function(dt)
                    if not ApexEngine.Flags["no_recoil"] then fn(dt) end
                end))
            end
            return _origBTRS(self, name, priority, fn)
        end))
    end

    -- Layer 2: camera pitch-lock at Last priority — catches recoil from guns already
    -- equipped before the hook, and any executor that doesn't support hookfunction.
    -- Widened threshold (0.15 rad ~8.6°) covers high-recoil weapons.
    -- Also cancels any upward yaw-coupled recoil patterns (some guns kick diagonally).
    local _nrPitch = 0
    local _nrYaw   = 0
    RunService:BindToRenderStep("ApexNoRecoil", Enum.RenderPriority.Last.Value, function()
        local cam = workspace.CurrentCamera
        local cf  = cam.CFrame
        local rx, ry = cf:ToEulerAnglesYXZ()
        if not ApexEngine.Flags["no_recoil"] then
            _nrPitch = rx; _nrYaw = ry; return
        end
        local dp = rx - _nrPitch
        local dyaw = math.abs(ry - _nrYaw)
        -- cancel upward pitch jumps up to 0.15 rad with minimal yaw coupling (<0.05 rad)
        -- this covers all known Brisk Survival gun recoil patterns
        if dp < 0 and math.abs(dp) < 0.15 and dyaw < 0.05 then
            cam.CFrame = CFrame.new(cf.Position)
                * CFrame.Angles(0, _nrYaw, 0)
                * CFrame.Angles(_nrPitch, 0, 0)
        else
            _nrPitch = rx; _nrYaw = ry
        end
    end)

    -- Aimbot (toggle, improved: distance-based velocity prediction)
    trackConnection(RunService.RenderStepped:Connect(function(dt)
        local flags = ApexEngine.Flags
        if not flags["ab_enabled"] then return end
        local partName = flags["ab_part"] or "Head"
        local target = getClosestEnemy(partName, flags["ab_fov"] or 80)
        if not target then return end
        local part = getR6Part(target.char, partName)
        if not part then return end
        local targetPos = part.Position
        if flags["ab_predict"] then
            local vel = target.root.AssemblyLinearVelocity
            local cam = workspace.CurrentCamera
            local dist = (targetPos - cam.CFrame.Position).Magnitude
            local travelTime = math.clamp(dist / 500, 0, 0.3)
            targetPos = targetPos + vel * travelTime
        end
        local cam = workspace.CurrentCamera
        local sp, onScreen = cam:WorldToViewportPoint(targetPos)
        if not onScreen or sp.Z <= 0 then return end
        local smooth = math.clamp((flags["ab_smooth"] or 10) / 50, 0.01, 1)
        local lerpFactor = math.clamp(1 - smooth, 0.02, 0.98)
        local w = cam.CFrame
        cam.CFrame = w:Lerp(CFrame.lookAt(w.Position, targetPos), lerpFactor)
    end))

    -- Triggerbot removed
    -- Camlock (toggle) removed
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

    -- World -> screen with visibility check
    local function worldToScreen(pos)
        local cam = workspace.CurrentCamera
        local sp, onScreen = cam:WorldToViewportPoint(pos)
        return Vector2.new(sp.X, sp.Y), onScreen, sp.Z
    end

    -- Fast bounds: 2 VP calls using Head top + foot bottom
    local function getCharBounds(char)
        local cam  = workspace.CurrentCamera
        local head = char:FindFirstChild("Head")
        local root = char:FindFirstChild("HumanoidRootPart")
        local lleg = char:FindFirstChild("Left Leg") or root
        if not head or not root then return nil end
        -- top = head top, bottom = lowest leg bottom
        local topY    = head.Position.Y  + head.Size.Y  * 0.5
        local botY    = (lleg or root).Position.Y - (lleg or root).Size.Y * 0.5
        local spTop,  onT = cam:WorldToViewportPoint(Vector3.new(root.Position.X, topY, root.Position.Z))
        local spBot,  onB = cam:WorldToViewportPoint(Vector3.new(root.Position.X, botY, root.Position.Z))
        if (not onT and not onB) or (spTop.Z <= 0 and spBot.Z <= 0) then return nil end
        local h = math.abs(spTop.Y - spBot.Y)
        local w = h * 0.45  -- R6 aspect ratio approximation
        local cx = (spTop.X + spBot.X) * 0.5
        local minY = math.min(spTop.Y, spBot.Y)
        return cx - w, minY, cx + w, minY + h
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

        -- Health bar (bg + fill, left side vertical)
        local hBg = Instance.new("Frame")
        hBg.BackgroundColor3 = Color3.fromRGB(30,30,30)
        hBg.BorderSizePixel = 0
        hBg.Visible = false
        hBg.Parent = espGui
        local hFill = Instance.new("Frame")
        hFill.BackgroundColor3 = Color3.fromRGB(80,255,120)
        hFill.BorderSizePixel = 0
        hFill.AnchorPoint = Vector2.new(0, 1)  -- anchor bottom-left so it grows upward
        hFill.Position = UDim2.new(0, 0, 1, 0) -- pin to bottom of hBg
        hFill.Parent = hBg
        local hText = Instance.new("TextLabel")
        hText.BackgroundTransparency = 1
        hText.TextColor3 = Color3.new(1,1,1)
        hText.TextStrokeTransparency = 0.3
        hText.TextStrokeColor3 = Color3.new(0,0,0)
        hText.Font = Enum.Font.GothamBold
        hText.TextSize = 9
        hText.TextXAlignment = Enum.TextXAlignment.Center
        hText.Size = UDim2.new(3, 0, 0, 10)
        hText.Position = UDim2.new(-1, 0, 0, -11)  -- above the bar
        hText.Visible = false
        hText.Parent = hBg
        d.healthBg   = hBg
        d.healthFill = hFill
        d.healthText = hText

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
        tracerF.AnchorPoint = Vector2.new(0, 0.5)
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

        -- Target line
        local tl = Instance.new("Frame")
        tl.BackgroundColor3 = Color3.fromRGB(255,50,50)
        tl.BorderSizePixel = 0
        tl.AnchorPoint = Vector2.new(0, 0.5)
        tl.Visible = false
        tl.Parent = espGui
        d.targetLine = tl

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
        pcall(function() d.targetLine:Destroy() end)
        _espData[p] = nil
    end

    local function hideESP(d)
        d.boxFrame.Visible   = false
        d.nameLabel.Visible  = false
        d.healthBg.Visible   = false
        d.healthText.Visible = false
        d.distLabel.Visible  = false
        d.tracer.Visible     = false
        d.highlight.Enabled  = false
        d.targetLine.Visible = false
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

    -- Draw tracer line from origin to target screen pos
    local function drawTracer(d, tx, ty, col, originMode)
        local cam = workspace.CurrentCamera
        local vp  = cam.ViewportSize
        local ox, oy
        if originMode == "Center" then
            ox, oy = vp.X/2, vp.Y/2
        elseif originMode == "Mouse" then
            local mp = UserInputService:GetMouseLocation()
            ox, oy = mp.X, mp.Y
        else
            ox, oy = vp.X/2, vp.Y
        end
        local dx, dy = tx - ox, ty - oy
        local len = math.sqrt(dx*dx + dy*dy)
        if len < 1 then d.tracer.Visible = false; return end
        d.tracer.AnchorPoint      = Vector2.new(0.5, 0.5)
        d.tracer.Position         = UDim2.fromOffset((ox + tx) / 2, (oy + ty) / 2)
        d.tracer.Size             = UDim2.fromOffset(len, 2)  -- 2px so it's actually visible
        d.tracer.Rotation         = math.deg(math.atan2(dy, dx))
        d.tracer.BackgroundColor3 = col
        d.tracer.Visible          = true
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

            -- Health bar (left side, fixed 4x60px, grows bottom-up)
            if flags["esp_health"] then
                local hp  = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                local r   = math.clamp(2*(1-hp), 0, 1)
                local g   = math.clamp(2*hp, 0, 1)
                local col = flags["esp_health_col"] or Color3.new(r, g, 0.1)
                local barW, barH = 4, 60
                local headSP2 = cam:WorldToViewportPoint(head.Position)
                d.healthBg.Position = UDim2.fromOffset(headSP2.X - 20, headSP2.Y - barH/2)
                d.healthBg.Size     = UDim2.fromOffset(barW, barH)
                d.healthBg.Visible  = true
                d.healthFill.BackgroundColor3 = col
                d.healthFill.Size   = UDim2.new(1, 0, hp, 0)
                d.healthText.Text    = math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)
                d.healthText.Visible = true
            else
                d.healthBg.Visible   = false
                d.healthText.Visible = false
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

            -- Target line (R6)
            if flags["tl_enabled"] then
                local tlMaxDist = flags["tl_maxdist"] or 800
                local tlClosest = flags["tl_closest"] ~= false
                -- skip if closest-only and this isn't the closest enemy
                local skip = false
                if tlClosest then
                    local partName = flags["tl_part"] or "Head"
                    local closest = getClosestEnemy and getClosestEnemy(partName, tlMaxDist)
                    if not closest or closest.player ~= p then skip = true end
                end
                if not skip and dist <= (flags["tl_maxdist"] or 800) then
                    local partName = flags["tl_part"] or "Head"
                    -- R6 part name map
                    local R6_MAP = {
                        ["Head"]="Head", ["Torso"]="Torso",
                        ["Left Arm"]="Left Arm", ["Right Arm"]="Right Arm",
                        ["Left Leg"]="Left Leg", ["Right Leg"]="Right Leg",
                    }
                    local part = char:FindFirstChild(R6_MAP[partName] or partName)
                    if part then
                        local sp, onSc = cam:WorldToViewportPoint(part.Position)
                        if onSc and sp.Z > 0 then
                            local tx, ty = sp.X, sp.Y
                            local tlOrigin = flags["tl_origin"] or "Bottom"
                            local ox, oy
                            if tlOrigin == "Center" then
                                ox, oy = cam.ViewportSize.X/2, cam.ViewportSize.Y/2
                            elseif tlOrigin == "Mouse" then
                                local mp = UserInputService:GetMouseLocation()
                                ox, oy = mp.X, mp.Y
                            else
                                ox, oy = cam.ViewportSize.X/2, cam.ViewportSize.Y
                            end
                            local dx, dy = tx-ox, ty-oy
                            local len = math.sqrt(dx*dx+dy*dy)
                            if len >= 1 then
                                local col = flags["tl_col"] or Color3.fromRGB(255,50,50)
                                d.targetLine.AnchorPoint      = Vector2.new(0.5, 0.5)
                                d.targetLine.Position         = UDim2.fromOffset((ox+tx)/2, (oy+ty)/2)
                                d.targetLine.Size             = UDim2.fromOffset(len, 1)
                                d.targetLine.Rotation         = math.deg(math.atan2(dy, dx))
                                d.targetLine.BackgroundColor3 = col
                                d.targetLine.Visible          = true
                            else
                                d.targetLine.Visible = false
                            end
                        else
                            d.targetLine.Visible = false
                        end
                    else
                        d.targetLine.Visible = false
                    end
                else
                    d.targetLine.Visible = false
                end
            else
                d.targetLine.Visible = false
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
        -- Mouse delta -> yaw/pitch
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
-- X-RAY (make world parts transparent so enemies show through walls)
-- ============================================================
do
    local _xrayParts = {} -- [BasePart] = originalTransparency
    local _xrayActive = false

    local function applyXray()
        -- make all non-character BaseParts in workspace transparent
        local charSet = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then charSet[p.Character] = true end
        end
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                -- skip character parts and terrain
                local anc = obj:FindFirstAncestorOfClass("Model")
                if anc and charSet[anc] then continue end
                if not _xrayParts[obj] then
                    _xrayParts[obj] = obj.Transparency
                end
                obj.Transparency = 0.85
            end
        end
    end

    local function removeXray()
        for obj, orig in pairs(_xrayParts) do
            pcall(function() obj.Transparency = orig end)
        end
        table.clear(_xrayParts)
    end

    local _prevXray = false
    trackConnection(RunService.Heartbeat:Connect(function()
        local cur = ApexEngine.Flags["m_xray"] == true
        if cur == _prevXray then return end
        _prevXray = cur
        if cur then
            applyXray()
        else
            removeXray()
        end
    end))
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

-- ============================================================
-- CROSSHAIR
-- ============================================================
do
    local chGui = Instance.new("ScreenGui")
    chGui.Name = "ApexCrosshair"
    chGui.ResetOnSpawn = false
    chGui.IgnoreGuiInset = true
    chGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    chGui.Parent = GetParentGui()

    local function makeLine()
        local f = Instance.new("Frame")
        f.BorderSizePixel = 0
        f.AnchorPoint = Vector2.new(0.5, 0.5)
        f.Parent = chGui
        return f
    end
    local chTop    = makeLine()
    local chBottom = makeLine()
    local chLeft   = makeLine()
    local chRight  = makeLine()

    trackConnection(RunService.RenderStepped:Connect(function()
        local flags = ApexEngine.Flags
        if not flags["crosshair_enabled"] then
            chTop.Visible=false; chBottom.Visible=false
            chLeft.Visible=false; chRight.Visible=false
            return
        end
        local cam = workspace.CurrentCamera
        local vp  = cam.ViewportSize
        local cx, cy = vp.X/2, vp.Y/2
        local gap   = flags["crosshair_gap"]   or 4
        local size  = flags["crosshair_size"]  or 8
        local thick = flags["crosshair_thick"] or 1
        local col   = flags["crosshair_col"]   or Color3.new(1,1,1)
        -- Top
        chTop.BackgroundColor3 = col
        chTop.Size     = UDim2.fromOffset(thick, size)
        chTop.Position = UDim2.fromOffset(cx, cy - gap - size/2)
        chTop.Visible  = true
        -- Bottom
        chBottom.BackgroundColor3 = col
        chBottom.Size     = UDim2.fromOffset(thick, size)
        chBottom.Position = UDim2.fromOffset(cx, cy + gap + size/2)
        chBottom.Visible  = true
        -- Left
        chLeft.BackgroundColor3 = col
        chLeft.Size     = UDim2.fromOffset(size, thick)
        chLeft.Position = UDim2.fromOffset(cx - gap - size/2, cy)
        chLeft.Visible  = true
        -- Right
        chRight.BackgroundColor3 = col
        chRight.Size     = UDim2.fromOffset(size, thick)
        chRight.Position = UDim2.fromOffset(cx + gap + size/2, cy)
        chRight.Visible  = true
    end))
end

-- ============================================================
-- SNAPLINE
-- ============================================================
do
    local snapGui = Instance.new("ScreenGui")
    snapGui.Name = "ApexSnapline"
    snapGui.ResetOnSpawn = false
    snapGui.IgnoreGuiInset = true
    snapGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    snapGui.Parent = GetParentGui()

    local snapLine = Instance.new("Frame")
    snapLine.BorderSizePixel = 0
    snapLine.AnchorPoint = Vector2.new(0, 0.5)
    snapLine.Visible = false
    snapLine.Parent = snapGui

    trackConnection(RunService.RenderStepped:Connect(function()
        local flags = ApexEngine.Flags
        if not flags["snap_enabled"] then snapLine.Visible = false; return end
        -- find closest enemy
        local cam = workspace.CurrentCamera
        local vp  = cam.ViewportSize
        local cx, cy = vp.X/2, vp.Y/2
        local best, bestDist = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LocalPlayer then continue end
            local char = p.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            local head = char and char:FindFirstChild("Head")
            if hum and hum.Health > 0 and head then
                local sp, onSc = cam:WorldToViewportPoint(head.Position)
                if onSc and sp.Z > 0 then
                    local d = math.sqrt((sp.X-cx)^2+(sp.Y-cy)^2)
                    if d < bestDist then bestDist=d; best={sp=sp} end
                end
            end
        end
        if not best then snapLine.Visible=false; return end
        local tx, ty = best.sp.X, best.sp.Y
        local origin = flags["snap_origin"] or "Bottom"
        local ox = cx
        local oy = origin == "Center" and cy or vp.Y
        local dx, dy = tx-ox, ty-oy
        local len = math.sqrt(dx*dx+dy*dy)
        if len < 1 then snapLine.Visible=false; return end
        local col   = flags["snap_col"]   or Color3.fromRGB(255,200,0)
        local thick = flags["snap_thick"] or 1
        snapLine.BackgroundColor3 = col
        snapLine.AnchorPoint  = Vector2.new(0.5, 0.5)
        snapLine.Position     = UDim2.fromOffset((ox + tx) / 2, (oy + ty) / 2)
        snapLine.Size         = UDim2.fromOffset(len, thick)
        snapLine.Rotation     = math.deg(math.atan2(dy, dx))
        snapLine.Visible      = true
    end))
end



-- ============================================================
-- SPINBOT
-- ============================================================
do
    trackConnection(RunService.Heartbeat:Connect(function()
        local flags = ApexEngine.Flags
        if not flags["spinbot"] then return end
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local speed = (flags["spinbot_speed"] or 25) * 10
        local yaw   = (os.clock() * speed) % 360
        local pitch = 0
        local mode  = flags["spinbot_pitch"] or "Normal"
        if mode == "Down" then
            pitch = -1.3089969389957472
        elseif mode == "Jitter" then
            pitch = math.rad(math.random() > 0.5 and 65 or -75)
        end
        -- preserve position, only rotate — avoids physics fling
        local pos = root.Position
        root.CFrame = CFrame.new(pos)
            * CFrame.Angles(0, math.rad(yaw), 0)
            * CFrame.Angles(pitch, 0, 0)
        root.AssemblyLinearVelocity = Vector3.new(
            root.AssemblyLinearVelocity.X, root.AssemblyLinearVelocity.Y, root.AssemblyLinearVelocity.Z
        )
    end))
end

-- ============================================================
-- FOV CHANGER
-- ============================================================
do
    local _origFovChanger = nil
    trackConnection(RunService.RenderStepped:Connect(function()
        local flags = ApexEngine.Flags
        if flags["w_fovchanger"] then
            if not _origFovChanger then
                _origFovChanger = workspace.CurrentCamera.FieldOfView
            end
            workspace.CurrentCamera.FieldOfView = flags["w_customfov"] or 70
        else
            if _origFovChanger then
                workspace.CurrentCamera.FieldOfView = _origFovChanger
                _origFovChanger = nil
            end
        end
    end))
end

-- ============================================================
-- NO CLIP
-- ============================================================
do
    local _ncConn, _prevNC = nil, false
    trackConnection(RunService.Heartbeat:Connect(function()
        local cur = ApexEngine.Flags["m_noclip"] == true
        if cur == _prevNC then return end
        _prevNC = cur
        local char = LocalPlayer.Character
        if cur then
            _ncConn = RunService.PreSimulation:Connect(function()
                local c = LocalPlayer.Character
                if not c then return end
                local r = c:FindFirstChild("HumanoidRootPart")
                if r then
                    r.AssemblyLinearVelocity = Vector3.new(
                        r.AssemblyLinearVelocity.X,
                        math.max(r.AssemblyLinearVelocity.Y, 0),
                        r.AssemblyLinearVelocity.Z
                    )
                end
                -- disable collision on character AND held tool
                for _, p in ipairs(c:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
                local tool = c:FindFirstChildOfClass("Tool")
                if tool then
                    for _, p in ipairs(tool:GetDescendants()) do
                        if p:IsA("BasePart") then p.CanCollide = false end
                    end
                end
            end)
        else
            if _ncConn then _ncConn:Disconnect(); _ncConn = nil end
            if char then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = true end
                end
            end
        end
    end))
end

-- ============================================================
-- FLY
-- ============================================================
do
    local _flyConn    = nil
    local _flyInput   = nil
    local _flyActive  = false
    local _flyBV      = nil
    local _flyBG      = nil
    local _flyYaw     = 0
    local _flyPitch   = 0

    local function enableFly()
        if _flyActive then return end
        _flyActive = true
        local char = LocalPlayer.Character
        if not char then _flyActive = false; return end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum  = char:FindFirstChildOfClass("Humanoid")
        if not root or not hum then _flyActive = false; return end

        -- Seed yaw/pitch from current camera so direction matches where you're looking
        local camCF = workspace.CurrentCamera.CFrame
        local rx, ry = camCF:ToEulerAnglesYXZ()
        _flyYaw   = ry
        _flyPitch = math.clamp(rx, -math.pi/2 + 0.01, math.pi/2 - 0.01)

        hum.PlatformStand = true
        workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

        local bv = Instance.new("BodyVelocity")
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        bv.Parent = root
        _flyBV = bv

        local bg = Instance.new("BodyGyro")
        bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        bg.D = 200
        bg.P = 1e4
        bg.Parent = root
        _flyBG = bg

        -- Mouse delta drives yaw/pitch
        _flyInput = UserInputService.InputChanged:Connect(function(i)
            if not _flyActive then return end
            if i.UserInputType == Enum.UserInputType.MouseMovement then
                _flyYaw   = _flyYaw   - i.Delta.X * 0.003
                _flyPitch = math.clamp(_flyPitch - i.Delta.Y * 0.003, -math.pi/2 + 0.01, math.pi/2 - 0.01)
            end
        end)

        _flyConn = RunService.RenderStepped:Connect(function(dt)
            if not _flyActive then return end
            local speed = ApexEngine.Flags["m_flyspeed"] or 20
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then speed = speed * 2 end

            -- Build direction from yaw+pitch (horizontal yaw, vertical pitch)
            local cf    = CFrame.Angles(0, _flyYaw, 0) * CFrame.Angles(_flyPitch, 0, 0)
            local fwd   = cf.LookVector
            local right = cf.RightVector
            local up    = Vector3.new(0, 1, 0)
            local move  = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += fwd   end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= fwd   end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += right end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= right end
            if UserInputService:IsKeyDown(Enum.KeyCode.E) then move += up    end
            if UserInputService:IsKeyDown(Enum.KeyCode.Q) then move -= up    end

            if _flyBV then
                _flyBV.Velocity = move.Magnitude > 0.001 and move.Unit * speed or Vector3.new(0, 0, 0)
            end
            -- Lock body rotation to yaw only (no pitch tilt on character)
            if _flyBG and _flyBG.Parent then
                _flyBG.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, _flyYaw, 0)
            end
            -- Sync camera to fly direction so it feels 1:1
            if workspace.CurrentCamera.CameraType == Enum.CameraType.Scriptable then
                workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position)
                    * CFrame.Angles(0, _flyYaw, 0)
                    * CFrame.Angles(_flyPitch, 0, 0)
            end
        end)
    end

    local function disableFly()
        if not _flyActive then return end
        _flyActive = false
        if _flyConn  then _flyConn:Disconnect();  _flyConn  = nil end
        if _flyInput then _flyInput:Disconnect(); _flyInput = nil end
        if _flyBV    then _flyBV:Destroy();       _flyBV    = nil end
        if _flyBG    then _flyBG:Destroy();       _flyBG    = nil end
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = false end
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                for _, v in ipairs(root:GetChildren()) do
                    if v:IsA("BodyGyro") or v:IsA("BodyVelocity") then v:Destroy() end
                end
            end
        end
        -- Restore camera to Roblox default
        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    end

    local _prevFly = false
    trackConnection(RunService.Heartbeat:Connect(function()
        local cur = ApexEngine.Flags["m_fly"] == true
        if cur == _prevFly then return end
        _prevFly = cur
        if cur then enableFly() else disableFly() end
    end))
    LocalPlayer.CharacterAdded:Connect(function()
        if _flyActive then disableFly(); ApexEngine.Flags["m_fly"] = false end
    end)
end

-- ============================================================
-- SPECTATE
-- ============================================================
do
    local _prevSpec = false
    trackConnection(RunService.Heartbeat:Connect(function()
        local flags = ApexEngine.Flags
        if not flags["m_spectate"] then
            if _prevSpec then
                local cam = workspace.CurrentCamera
                local char = LocalPlayer.Character
                local hum  = char and char:FindFirstChildOfClass("Humanoid")
                if hum then cam.CameraSubject = hum end
                cam.CameraType = Enum.CameraType.Custom
                _prevSpec = false
            end
            return
        end
        _prevSpec = true
        local target = flags["m_spectate_target"]
        if not target or target == "" then return end
        local cam = workspace.CurrentCamera
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and (p.Name:lower() == target:lower() or p.DisplayName:lower() == target:lower()) then
                local char = p.Character
                local hum  = char and char:FindFirstChildOfClass("Humanoid")
                if hum and cam.CameraSubject ~= hum then
                    cam.CameraSubject = hum
                    cam.CameraType = Enum.CameraType.Follow
                end
                return
            end
        end
    end))
end

-- ============================================================
-- OMNI SPRINT RESTORE
-- ============================================================
do
    local _origWalkSpeed = nil
    trackConnection(RunService.Heartbeat:Connect(function()
        local flags = ApexEngine.Flags
        if not flags["m_omnisprint"] then
            if _origWalkSpeed then
                local char = LocalPlayer.Character
                local hum  = char and char:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = _origWalkSpeed end
                _origWalkSpeed = nil
            end
            return
        end
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return end
        if not _origWalkSpeed then _origWalkSpeed = hum.WalkSpeed end
        if hum.MoveDirection.Magnitude > 0.05 then
            hum.WalkSpeed = 16 + (flags["m_omnisprint_bonus"] or 0)
        else
            hum.WalkSpeed = _origWalkSpeed
        end
    end))
end

-- ============================================================
-- WORLD ESP: C4 + ROCKETS (extended)
-- ============================================================
do
    local _c4Cache    = {} -- id -> {pos, expireAt}
    local _rocketData = {} -- id -> {pos, expireAt, blast}
    local _rocketFolders = {"FiredRockets","SpawnedRockets","Rockets"}

    local function playAlertSound(dist)
        local vol = math.clamp(1 - dist/500, 0.1, 1)
        local snd = Instance.new("Sound")
        snd.SoundId = "rbxassetid://9125402735"
        snd.Volume  = vol
        snd.Parent  = workspace
        snd:Play()
        game:GetService("Debris"):AddItem(snd, 2)
    end

    local _c4Gui = Instance.new("ScreenGui")
    _c4Gui.Name = "ApexC4ESP"
    _c4Gui.ResetOnSpawn = false
    _c4Gui.IgnoreGuiInset = true
    _c4Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    _c4Gui.Parent = GetParentGui()

    local _c4Labels = {}
    local function getC4Label(id)
        if not _c4Labels[id] then
            local bg = Instance.new("Frame")
            bg.BackgroundColor3 = Color3.new(0,0,0)
            bg.BackgroundTransparency = 0.5
            bg.BorderSizePixel = 0
            bg.AutomaticSize = Enum.AutomaticSize.XY
            bg.Parent = _c4Gui
            local lbl = Instance.new("TextLabel")
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.GothamBold
            lbl.TextSize = 11
            lbl.TextStrokeTransparency = 0.4
            lbl.TextStrokeColor3 = Color3.new(0,0,0)
            lbl.AutomaticSize = Enum.AutomaticSize.XY
            lbl.Parent = bg
            _c4Labels[id] = {bg=bg, lbl=lbl}
        end
        return _c4Labels[id]
    end
    local function hideC4Label(id)
        local e = _c4Labels[id]
        if e then e.bg.Visible = false end
    end
    local function placeC4Label(id, worldPos, text, col)
        local cam = workspace.CurrentCamera
        local sp, onSc = cam:WorldToViewportPoint(worldPos)
        if not onSc or sp.Z <= 0 then hideC4Label(id); return end
        local e = getC4Label(id)
        e.lbl.Text = text
        e.lbl.TextColor3 = col
        e.bg.Position = UDim2.fromOffset(sp.X, sp.Y)
        e.bg.Visible = true
    end

    trackConnection(RunService.RenderStepped:Connect(function()
        local flags = ApexEngine.Flags
        local cam   = workspace.CurrentCamera
        local camPos = cam.CFrame.Position
        local t = os.clock()
        local drawn = {}

        -- C4
        if flags["wesp_c4"] then
            local c4folder = workspace:FindFirstChild("PlacedC4")
            if c4folder then
                for _, obj in ipairs(c4folder:GetChildren()) do
                    local pos = obj:IsA("BasePart") and obj.Position
                        or (obj.PrimaryPart and obj.PrimaryPart.Position)
                    if pos then
                        local id = "c4_"..obj:GetDebugId()
                        if not _c4Cache[id] then
                            _c4Cache[id] = {pos=pos, expireAt=t+30}
                            if flags["wesp_c4_alert"] then
                                task.spawn(playAlertSound, (pos-camPos).Magnitude)
                            end
                        else
                            _c4Cache[id].pos = pos
                        end
                    end
                end
            end
            for id, data in pairs(_c4Cache) do
                local remaining = data.expireAt - t
                if remaining > 0 then
                    drawn[id] = true
                    local dist = math.floor((data.pos-camPos).Magnitude)
                    placeC4Label(id, data.pos,
                        string.format("C4 [%dm | %.1fs]", dist, remaining),
                        Color3.fromRGB(255,60,60))
                else
                    _c4Cache[id] = nil
                    hideC4Label(id)
                end
            end
        end

        -- Rockets
        if flags["wesp_rockets"] then
            for _, fname in ipairs(_rocketFolders) do
                local folder = workspace:FindFirstChild(fname)
                if folder then
                    for _, obj in ipairs(folder:GetChildren()) do
                        local pos = obj:IsA("BasePart") and obj.Position
                            or (obj.PrimaryPart and obj.PrimaryPart.Position)
                        if pos then
                            local id = "rkt_"..obj:GetDebugId()
                            if not _rocketData[id] then
                                _rocketData[id] = {pos=pos, expireAt=t+15, blast=false}
                            else
                                _rocketData[id].pos = pos
                            end
                        end
                    end
                end
            end
            for id, data in pairs(_rocketData) do
                local remaining = data.expireAt - t
                if remaining > 0 then
                    drawn[id] = true
                    local dist = math.floor((data.pos-camPos).Magnitude)
                    local label
                    if flags["wesp_rocket_timer"] then
                        label = string.format("ROCKET [%dm | %.1fs]", dist, remaining)
                    else
                        label = string.format("ROCKET [%dm]", dist)
                    end
                    placeC4Label(id, data.pos, label, Color3.fromRGB(255,150,40))
                else
                    _rocketData[id] = nil
                    hideC4Label(id)
                end
            end
        end

        -- Hide stale
        for id in pairs(_c4Labels) do
            if not drawn[id] then hideC4Label(id) end
        end
    end))
end

-- ============================================================
-- THIRD PERSON
-- ============================================================
do
    local _tpActive = false
    local _tpOrigType = nil
    local _tpOrigSubj = nil
    local _tpOrigFOV  = nil

    local function enableTP()
        if _tpActive then return end
        _tpActive = true
        local cam = workspace.CurrentCamera
        _tpOrigType = cam.CameraType
        _tpOrigSubj = cam.CameraSubject
        _tpOrigFOV  = cam.FieldOfView
        cam.CameraType = Enum.CameraType.Custom
        -- set subject to humanoid so Roblox handles the orbit, just push the zoom out
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then cam.CameraSubject = hum end
    end

    local function disableTP()
        if not _tpActive then return end
        _tpActive = false
        local cam = workspace.CurrentCamera
        cam.CameraType = _tpOrigType or Enum.CameraType.Custom
        if _tpOrigSubj then cam.CameraSubject = _tpOrigSubj end
        cam.FieldOfView = _tpOrigFOV or 70
    end

    local _prevTP = false
    trackConnection(RunService.RenderStepped:Connect(function()
        local flags = ApexEngine.Flags
        local cur = flags["m_thirdperson"] == true
        if cur ~= _prevTP then
            _prevTP = cur
            if cur then enableTP() else disableTP() end
        end
        if not _tpActive then return end
        -- push camera back by TP distance using CameraOffset on HRP
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local dist = flags["m_thirdperson_dist"] or 12
            hrp.CameraOffset = Vector3.new(0, 2, dist)
        end
    end))

    LocalPlayer.CharacterAdded:Connect(function()
        if _tpActive then
            -- re-apply subject on respawn
            task.defer(function()
                local char = LocalPlayer.Character
                local hum  = char and char:FindFirstChildOfClass("Humanoid")
                if hum then workspace.CurrentCamera.CameraSubject = hum end
            end)
        end
    end)
end

return ApexEngine
