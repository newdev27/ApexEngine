if getgenv().apexengine_mobile_loaded then
    while task.wait(99999) do end
end
getgenv().apexengine_mobile_loaded = true

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local HttpService      = game:GetService("HttpService")
local LocalPlayer      = Players.LocalPlayer

local _conn = {}
local function track(c) _conn[#_conn+1]=c; return c end

-- scale: base design 800px wide
local function sc(px)
    return math.max(1, math.floor(px * (workspace.CurrentCamera.ViewportSize.X / 800)))
end

local function GetGui()
    local ok,h = pcall(function() return gethui and gethui() end)
    if ok and h then return h end
    local ok2,c = pcall(function() return game:GetService("CoreGui") end)
    if ok2 and c then
        if pcall(function() local f=Instance.new("Folder");f.Parent=c;f:Destroy() end) then return c end
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- ── Project Apex brand palette ─────────────────────────────
-- Primary Accent (Apex Crimson)  #E63946
-- Secondary Accent / Glow        #FF4D5A
-- Background (Deep Obsidian)     #0B0B0E
-- Card / Section Background      #14141A (Dark Slate)
-- Border / Outline               #282834
-- Text                           #F1F1F5
local T = {
    Bg     = Color3.fromRGB(11,11,14),    -- #0B0B0E Deep Obsidian (main window)
    Panel  = Color3.fromRGB(20,20,26),    -- #14141A Dark Slate (cards / sections)
    Card   = Color3.fromRGB(20,20,26),    -- #14141A alias for section cards
    Border = Color3.fromRGB(40,40,52),    -- #282834 crisp 1px outline
    Accent = Color3.fromRGB(230,57,70),   -- #E63946 Apex Crimson (primary)
    Glow   = Color3.fromRGB(255,77,90),   -- #FF4D5A secondary glow
    Text   = Color3.fromRGB(241,241,245), -- #F1F1F5
    Dim    = Color3.fromRGB(130,132,143), -- muted secondary text
    On     = Color3.fromRGB(230,57,70),   -- toggle on fill = crimson
    Off    = Color3.fromRGB(40,40,52),    -- toggle off = border slate
    Red    = Color3.fromRGB(230,57,70),   -- status X / errors = crimson
    Green  = Color3.fromRGB(60,220,110),  -- status check / success
    ABOn   = Color3.fromRGB(230,57,70),   -- aimbot active = crimson
    ABOff  = Color3.fromRGB(28,18,20),
    TBOn   = Color3.fromRGB(255,77,90),   -- triggerbot active = glow red
    TBOff  = Color3.fromRGB(28,20,16),
}

local function New(cls, props, kids)
    local o = Instance.new(cls)
    for k,v in pairs(props or {}) do
        if k ~= "Parent" then o[k] = v end
    end
    for _,c in ipairs(kids or {}) do c.Parent = o end
    if props and props.Parent then o.Parent = props.Parent end
    return o
end
local function Corner(r,p) local c=New("UICorner",{CornerRadius=UDim.new(0,r)}); c.Parent=p; return c end
local function Tween(o,t,props)
    if t==0 then for k,v in pairs(props) do o[k]=v end; return end
    TweenService:Create(o,TweenInfo.new(t,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),props):Play()
end

-- ── GunFire (declared early so triggerbot can reference it) ─
local GunFire = nil
task.spawn(function()
    GunFire = game:GetService("ReplicatedStorage"):WaitForChild("GunFire", 15)
end)

-- ── Flags ─────────────────────────────────────────────────
local Flags = {
    sa_enabled=true, sa_part="Head", sa_fov=120, sa_hitchance=100, sa_maxdist=300,
    no_recoil=true, no_spread=true,
    sa_bulletspeed=2000,
    always_headshot=false,
    ab_part="Head", ab_fov=120, ab_smooth=8, ab_predict=true, ab_maxdist=300,
    esp_enabled=true, esp_box=true, esp_box_col=Color3.new(1,1,1),
    esp_name=true, esp_name_col=Color3.new(1,1,1),
    esp_health=true, esp_health_col=Color3.fromRGB(80,255,120),
    esp_dist=true, esp_maxdist=1500, esp_textsize=11,
    esp_chams=false, esp_fill_col=Color3.fromRGB(255,60,90),
    esp_fill_opacity=50, esp_outline_col=Color3.new(1,1,1),
    w_fovchanger=false, w_customfov=70,
    wesp_harv=false, wesp_ore=false, wesp_sleepers=false,
    wesp_c4=true, wesp_c4_alert=true, wesp_rockets=true,
    wesp_maxdist=1000, wesp_turrets=false, wesp_storage=false,
    wesp_beds=false, wesp_barricades=false, wesp_other=false,
    w_fullbright=false, w_nofog=false, w_noshadows=false,
    w_notrees=false, w_nograss=false,
    m_omnisprint=false, m_omnisprint_bonus=0,
    m_noclip=false, m_xray=false, m_xray_trans=0.85,
    m_freecam=false, m_freecam_speed=40,
    crosshair_enabled=true, crosshair_col=Color3.new(1,1,1),
    crosshair_gap=4, crosshair_size=8, crosshair_thick=1,
    _fire_held=false,
    _crouch_held=false,
    tc_enabled=true,
    tb_enabled=false,
    tb_fov=60,
    tb_delay=0,
    fr_enabled=false,
    fr_rpm=600,
}

-- ── Key system ────────────────────────────────────────────
local KEY_FILE  = "ApexEngine/key.dat"
local HWID_FILE = "ApexEngine/hwid.dat"
local KEYS_URL  = "https://raw.githubusercontent.com/newdev27/ApexEngine/main/Apex%20Engine/keys.json"
local SALT      = "AX_br27_$3cr3t_2k25"
local CHARS     = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

local function getHWID()
    local ok,id=pcall(function() return tostring(game:GetService("RbxAnalyticsService"):GetClientId()) end)
    return (ok and id or "unknown").."_"..tostring(LocalPlayer.UserId)
end
local function readFile(p) if isfile and isfile(p) then return readfile(p) end end
local function writeFile(p,d) if writefile then writefile(p,d) end end

local function validFormat(k)
    return k and type(k)=="string"
        and k:match("^APEX%-[A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9]%-[A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9]%-[A-Z0-9][A-Z0-9]$")~=nil
end
local TIERS={MN=true,HR=true,DY=true,FR=true,WK=true,MO=true,YR=true,LT=true}
local function verifyChecksum(k)
    local body=k:sub(1,-4); local exp=k:sub(-2)
    local hash=5381; local str=body..SALT
    for i=1,#str do hash=((hash*33)+string.byte(str,i))%1048576 end
    local c1=CHARS:sub((hash%#CHARS)+1,(hash%#CHARS)+1)
    local c2=CHARS:sub((math.floor(hash/#CHARS)%#CHARS)+1,(math.floor(hash/#CHARS)%#CHARS)+1)
    return (c1..c2)==exp
end
local function fetchKeys()
    local ok,res=pcall(function()
        return HttpService:JSONDecode(game:HttpGet(KEYS_URL.."?t="..tostring(os.time())))
    end)
    if ok and res and res.keys then return res.keys end
end
local function validateKey(inputKey)
    inputKey=tostring(inputKey or ""):upper():gsub("%s","")
    if not validFormat(inputKey) then return false,"Invalid key format." end
    if not TIERS[inputKey:sub(6,7)] then return false,"Invalid key format." end
    if not verifyChecksum(inputKey) then return false,"Invalid key." end
    local keys=fetchKeys()
    if not keys then return false,"Could not reach key server." end
    local entry=keys[inputKey]
    if not entry then return false,"Key not found." end
    if entry.blocked then return false,"Key revoked." end
    if entry.expires_at and entry.expires_at~=false and os.time()>entry.expires_at then return false,"Key expired." end
    local hwid=getHWID()
    if entry.hwid and entry.hwid~="" and entry.hwid~=hwid then return false,"HWID mismatch." end
    writeFile(KEY_FILE,inputKey); writeFile(HWID_FILE,hwid)
    return true,"OK",entry
end
local function getSavedKey()
    local k=readFile(KEY_FILE); local h=readFile(HWID_FILE)
    if k and h and h==getHWID() then return k end
    writeFile(KEY_FILE,""); writeFile(HWID_FILE,"")
end

-- ══════════════════════════════════════════════════════════
-- KEY GATE
-- ══════════════════════════════════════════════════════════
local authed = false
do
    local saved = getSavedKey()
    if saved then local ok=validateKey(saved); authed=ok end
end

if not authed then
    local done=false
    local kg=New("ScreenGui",{Name="ApexMobileKey",ResetOnSpawn=false,
        IgnoreGuiInset=true,DisplayOrder=999,Parent=GetGui()})
    New("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(0,0,0),
        BackgroundTransparency=0.45,BorderSizePixel=0,Parent=kg})
    local win=New("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
        Size=UDim2.fromScale(0.86,0.38),BackgroundColor3=T.Bg,BorderSizePixel=0,Parent=kg})
    Corner(sc(3),win)
    New("UIStroke",{Color=T.Border,Transparency=0,Thickness=1,
        ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Parent=win})
    New("TextLabel",{Text="PROJECT APEX [ MOBILE ]",BackgroundTransparency=1,
        Font=Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Bold),TextSize=sc(13),TextColor3=T.Accent,
        Size=UDim2.new(1,-20,0,sc(20)),Position=UDim2.fromOffset(10,10),TextXAlignment=Enum.TextXAlignment.Left,Parent=win})
    New("Frame",{Size=UDim2.new(1,-20,0,1),Position=UDim2.fromOffset(10,sc(30)),
        BackgroundColor3=T.Border,BorderSizePixel=0,Parent=win})
    local box=New("TextBox",{BackgroundColor3=T.Panel,BorderSizePixel=0,
        ClearTextOnFocus=false,Font=Enum.Font.RobotoMono,TextSize=sc(11),
        PlaceholderText="APEX-XXXXXX-XXXXXX-XX",PlaceholderColor3=T.Dim,
        Text="",TextColor3=T.Text,Size=UDim2.new(1,-20,0,sc(32)),
        Position=UDim2.fromOffset(10,sc(40)),Parent=win})
    Corner(sc(2),box)
    New("UIStroke",{Color=T.Border,Transparency=0,Thickness=1,
        ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Parent=box})
    New("UIPadding",{PaddingLeft=UDim.new(0,8),Parent=box})
    local st=New("TextLabel",{BackgroundTransparency=1,Font=Enum.Font.RobotoMono,
        TextSize=sc(10),TextColor3=T.Dim,Text="Enter your key and tap Submit.",
        Size=UDim2.new(1,-20,0,sc(14)),Position=UDim2.fromOffset(10,sc(78)),TextXAlignment=Enum.TextXAlignment.Left,Parent=win})
    local sb=New("TextButton",{BackgroundColor3=T.Accent,AutoButtonColor=false,
        Text="Submit",Font=Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Bold),TextSize=sc(11),
        TextColor3=T.Text,Size=UDim2.new(0.48,-5,0,sc(30)),
        Position=UDim2.fromOffset(10,sc(100)),Parent=win})
    Corner(sc(2),sb)
    local submitting=false
    sb.Activated:Connect(function()
        if submitting then return end
        local k=box.Text:match("^%s*(.-)%s*$")
        if k=="" then st.Text="Enter a key first.";st.TextColor3=T.Red;return end
        submitting=true;st.Text="Checking...";st.TextColor3=T.Dim
        task.spawn(function()
            local ok,msg=validateKey(k)
            if ok then
                st.Text="✓ Authenticated!";st.TextColor3=T.Green
                task.delay(0.4,function() kg:Destroy();done=true end)
            else st.Text=msg;st.TextColor3=T.Red;submitting=false end
        end)
    end)
    local raw=readFile(KEY_FILE)
    if raw and raw~="" then box.Text=raw;task.delay(0.3,function() sb.Activated:Fire() end) end
    repeat task.wait(0.1) until done
    authed=true
end

-- ══════════════════════════════════════════════════════════
-- ROOT GUI
-- ══════════════════════════════════════════════════════════
local rootGui=New("ScreenGui",{Name="ApexMobileUI",ResetOnSpawn=false,
    IgnoreGuiInset=true,ZIndexBehavior=Enum.ZIndexBehavior.Global,Parent=GetGui()})

-- ══════════════════════════════════════════════════════════
-- ESP TOGGLE BUTTON  (always visible, bottom-center)
-- ══════════════════════════════════════════════════════════
local espBtn=New("TextButton",{
    Text="ESP",
    AnchorPoint=Vector2.new(0,0.5),
    Position=UDim2.new(0,sc(10),0.5,sc(44)),
    Size=UDim2.fromOffset(sc(38),sc(38)),
    BackgroundColor3=T.On,
    AutoButtonColor=false,
    Font=Enum.Font.RobotoMono,
    TextSize=sc(11),
    TextColor3=T.Text,
    ZIndex=20,
    Parent=rootGui,
})
Corner(sc(3),espBtn)
New("UIStroke",{Color=T.Border,Transparency=0,Thickness=1,
    ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Parent=espBtn})
espBtn.Activated:Connect(function()
    Flags.esp_enabled=not Flags.esp_enabled
    Tween(espBtn,0.15,{BackgroundColor3=Flags.esp_enabled and T.On or T.Off})
end)

-- ══════════════════════════════════════════════════════════
-- APEX FLOATING PILL  (draggable, touch-friendly; tap = toggle panel)
-- ══════════════════════════════════════════════════════════
local togglePanel  -- forward declared; wired up after the panel is built
local openBtn=New("TextButton",{
    Text="APEX",
    AnchorPoint=Vector2.new(0,1),
    Position=UDim2.new(0,sc(10),1,-sc(12)),
    Size=UDim2.fromOffset(sc(58),sc(34)),
    BackgroundColor3=T.Accent,
    AutoButtonColor=false,
    Font=Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Bold),
    TextSize=sc(12),
    TextColor3=T.Text,
    ZIndex=20,
    Parent=rootGui,
})
Corner(sc(3),openBtn)
New("UIStroke",{Color=T.Border,Transparency=0,Thickness=1,
    ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Parent=openBtn})

-- drag + tap logic (Touch + MouseButton1 for emulator testing)
do
    local dragging,dragStart,btnStart,moved
    openBtn.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true; moved=false
            dragStart=i.Position; btnStart=openBtn.Position
            Tween(openBtn,0.10,{BackgroundColor3=T.Glow})
            i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dragging=false end end)
        end
    end)
    track(UserInputService.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=i.Position-dragStart
            if d.Magnitude>sc(6) then moved=true end
            openBtn.Position=UDim2.new(btnStart.X.Scale,btnStart.X.Offset+d.X,btnStart.Y.Scale,btnStart.Y.Offset+d.Y)
        end
    end))
    openBtn.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
            Tween(openBtn,0.15,{BackgroundColor3=T.Accent})
            if not moved and togglePanel then togglePanel() end
        end
    end)
end

-- ══════════════════════════════════════════════════════════
-- TRIGGERBOT BUTTON  (always visible, left side above aimbot)
-- ══════════════════════════════════════════════════════════
local tbBtn=New("TextButton",{
    Text="TB",
    AnchorPoint=Vector2.new(0,0.5),
    Position=UDim2.new(0,sc(10),0.5,-sc(44)),
    Size=UDim2.fromOffset(sc(38),sc(38)),
    BackgroundColor3=T.TBOff,
    AutoButtonColor=false,
    Font=Enum.Font.RobotoMono,
    TextSize=sc(11),
    TextColor3=T.Text,
    ZIndex=20,
    Parent=rootGui,
})
Corner(sc(3),tbBtn)
New("UIStroke",{Color=T.Border,Transparency=0,Thickness=1,
    ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Parent=tbBtn})
tbBtn.Activated:Connect(function()
    Flags.tb_enabled=not Flags.tb_enabled
    Tween(tbBtn,0.15,{BackgroundColor3=Flags.tb_enabled and T.TBOn or T.TBOff})
end)

-- ══════════════════════════════════════════════════════════
-- AIMBOT BUTTON  (always visible, bottom-right)
-- Hold = aimbot active while held; tap = toggle lock-on
-- ══════════════════════════════════════════════════════════
local abBtn=New("TextButton",{
    Text="AB",
    AnchorPoint=Vector2.new(0,0.5),
    Position=UDim2.new(0,sc(10),0.5,0),
    Size=UDim2.fromOffset(sc(38),sc(38)),
    BackgroundColor3=T.ABOff,
    AutoButtonColor=false,
    Font=Enum.Font.RobotoMono,
    TextSize=sc(11),
    TextColor3=T.Text,
    ZIndex=20,
    Parent=rootGui,
})
Corner(sc(3),abBtn)
New("UIStroke",{Color=T.Border,Transparency=0,Thickness=1,
    ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Parent=abBtn})

-- Aimbot button: hold = fire_held, tap = toggle ab_enabled
local _abHoldStart=0
abBtn.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
        _abHoldStart=os.clock()
        Flags._fire_held=true
        Tween(abBtn,0.1,{BackgroundColor3=T.ABOn,Size=UDim2.fromOffset(sc(34),sc(34))})
    end
end)
abBtn.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
        Flags._fire_held=false
        if os.clock()-_abHoldStart < 0.3 then
            Flags.ab_enabled = not Flags.ab_enabled
        end
        local col = Flags.ab_enabled and T.ABOn or T.ABOff
        Tween(abBtn,0.15,{BackgroundColor3=col,Size=UDim2.fromOffset(sc(38),sc(38))})
    end
end)

-- keep TB button color in sync
track(RunService.Heartbeat:Connect(function()
    tbBtn.BackgroundColor3=Flags.tb_enabled and T.TBOn or T.TBOff
end))

-- ══════════════════════════════════════════════════════════
-- PROJECT APEX [ MOBILE ] — SETTINGS PANEL
-- Compact "Switch Hub" terminal aesthetic: monospace, flat 1px borders,
-- square checkbox toggles, dense ~20px rows, label:value readouts,
-- all-caps crimson section headers. Mobile-first: centered + UIScale.
-- ══════════════════════════════════════════════════════════

local Mono      = Enum.Font.RobotoMono
local MonoBold  = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Bold)

-- mini logical design size; UIScale re-fits to viewport (clamped 0.5–1.2)
local PANEL_W, PANEL_H = 520, 340
local panel=New("Frame",{
    Name="ApexPanel",
    AnchorPoint=Vector2.new(0.5,0.5),
    Position=UDim2.fromScale(0.5,0.5),
    Size=UDim2.fromOffset(PANEL_W,PANEL_H),
    BackgroundColor3=T.Bg,
    BorderSizePixel=0,
    ClipsDescendants=true,
    ZIndex=10,
    Visible=true,
    Parent=rootGui,
})
Corner(sc(4),panel)
New("UIStroke",{Color=T.Border,Transparency=0,Thickness=1,
    ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Parent=panel})

local panelScale=New("UIScale",{Parent=panel})
track(RunService.RenderStepped:Connect(function()
    local v=workspace.CurrentCamera.ViewportSize
    local s=math.min((v.X-16)/PANEL_W,(v.Y-16)/PANEL_H,1.2)
    panelScale.Scale=math.max(0.5,s)
end))

-- open/close (wired to the APEX floating pill)
local panelOpen=true
togglePanel=function()
    panelOpen=not panelOpen
    panel.Visible=panelOpen
    Tween(openBtn,0.12,{BackgroundColor3=panelOpen and T.Accent or T.Panel})
end

-- ── top bar (drag handle + brand) ─────────────────────────
local TOP=sc(26)
local topBar=New("Frame",{Size=UDim2.new(1,0,0,TOP),
    BackgroundColor3=T.Bg,BorderSizePixel=0,ZIndex=11,Parent=panel})
New("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),
    BackgroundColor3=T.Border,BorderSizePixel=0,ZIndex=12,Parent=topBar})
New("TextLabel",{Text="Project Apex",BackgroundTransparency=1,
    Font=MonoBold,TextSize=sc(11),TextColor3=T.Accent,
    Size=UDim2.fromOffset(sc(90),TOP),Position=UDim2.fromOffset(sc(8),0),
    TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,
    ZIndex=12,Parent=topBar})
New("TextLabel",{Text="| Mobile",BackgroundTransparency=1,
    Font=Mono,TextSize=sc(10),TextColor3=T.Dim,
    Size=UDim2.fromOffset(sc(60),TOP),Position=UDim2.fromOffset(sc(92),0),
    TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,
    ZIndex=12,Parent=topBar})

-- drag logic (touch + MouseButton1)
do
    local dragging,dragStart,panStart
    topBar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true;dragStart=i.Position;panStart=panel.Position
        end
    end)
    track(UserInputService.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=i.Position-dragStart
            panel.Position=UDim2.new(panStart.X.Scale,panStart.X.Offset+d.X,panStart.Y.Scale,panStart.Y.Offset+d.Y)
        end
    end))
    track(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=false
        end
    end))
end

-- ── tab bar (flat, crimson active underline) ──────────────
local TAB_NAMES={"Stats","Visual","World","Player"}
local TAB_H=sc(22)
local tabBar=New("Frame",{Size=UDim2.new(1,0,0,TAB_H),Position=UDim2.fromOffset(0,TOP),
    BackgroundColor3=T.Bg,BorderSizePixel=0,ZIndex=11,Parent=panel})
New("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),
    BackgroundColor3=T.Border,BorderSizePixel=0,ZIndex=12,Parent=tabBar})
local tabScroll=New("ScrollingFrame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
    BorderSizePixel=0,ScrollBarThickness=0,CanvasSize=UDim2.new(),
    AutomaticCanvasSize=Enum.AutomaticSize.X,ScrollDirection=Enum.ScrollDirection.X,
    CanvasPosition=Vector2.new(0,0),Parent=tabBar})
New("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,
    SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,0),Parent=tabScroll})
New("UIPadding",{PaddingLeft=UDim.new(0,sc(2)),Parent=tabScroll})

-- ── content area: two scrollable columns ──────────────────
local COL_TOP=TOP+TAB_H
local COL_GAP=sc(4)
local contentWrap=New("Frame",{Size=UDim2.new(1,-COL_GAP*2,1,-COL_TOP-sc(4)),
    Position=UDim2.fromOffset(COL_GAP,COL_TOP),BackgroundTransparency=1,ZIndex=11,Parent=panel})
local leftCol=New("ScrollingFrame",{Size=UDim2.new(0.5,-COL_GAP/2,1,0),BackgroundTransparency=1,
    BorderSizePixel=0,ScrollBarThickness=sc(2),ScrollBarImageColor3=T.Accent,
    CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,
    ScrollDirection=Enum.ScrollDirection.Y,Parent=contentWrap})
local rightCol=New("ScrollingFrame",{Size=UDim2.new(0.5,-COL_GAP/2,1,0),
    Position=UDim2.new(0.5,COL_GAP/2,0,0),BackgroundTransparency=1,
    BorderSizePixel=0,ScrollBarThickness=sc(2),ScrollBarImageColor3=T.Accent,
    CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,
    ScrollDirection=Enum.ScrollDirection.Y,Parent=contentWrap})
for _,c in ipairs({leftCol,rightCol}) do
    New("UIListLayout",{Padding=UDim.new(0,sc(4)),SortOrder=Enum.SortOrder.LayoutOrder,Parent=c})
end

-- ── builder state ─────────────────────────────────────────
local tabCards={}
local tabBtns={}
local tabUnderline={}
local recTab,recCol,recSection
local _order=0
local function nO() _order+=1; return _order end

local function colFrame(side) return (side=="Right") and rightCol or leftCol end

local function showTab(name)
    for tname,cards in pairs(tabCards) do
        local vis=tname==name
        for _,c in ipairs(cards) do c.Visible=vis end
    end
end

-- ── Section card: flat panel, all-caps crimson header + 1px divider ──
local function makeSection(title, side)
    local col=colFrame(side or recCol or "Left")
    local card=New("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundColor3=T.Panel,BorderSizePixel=0,LayoutOrder=nO(),ZIndex=12,Parent=col})
    Corner(sc(3),card)
    New("UIStroke",{Color=T.Border,Transparency=0,Thickness=1,
        ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Parent=card})
    New("UIPadding",{PaddingTop=UDim.new(0,sc(6)),PaddingBottom=UDim.new(0,sc(6)),
        PaddingLeft=UDim.new(0,sc(7)),PaddingRight=UDim.new(0,sc(7)),Parent=card})
    New("UIListLayout",{Padding=UDim.new(0,sc(3)),SortOrder=Enum.SortOrder.LayoutOrder,Parent=card})
    -- header
    local head=New("Frame",{Size=UDim2.new(1,0,0,sc(13)),BackgroundTransparency=1,
        LayoutOrder=0,ZIndex=13,Parent=card})
    New("TextLabel",{Text=(title or ""):upper(),BackgroundTransparency=1,Font=MonoBold,
        TextSize=sc(9),TextColor3=T.Accent,TextXAlignment=Enum.TextXAlignment.Left,
        Size=UDim2.fromScale(1,1),TextYAlignment=Enum.TextYAlignment.Center,Parent=head})
    New("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,0),
        BackgroundColor3=T.Border,BorderSizePixel=0,Parent=head})
    recSection=card
    if recTab then tabCards[recTab][#tabCards[recTab]+1]=card end
    return card
end
local function makeSep(title) return makeSection(title) end

local function makeRow(h)
    return New("Frame",{Size=UDim2.new(1,0,0,h or sc(20)),BackgroundTransparency=1,
        LayoutOrder=nO(),ZIndex=13,Parent=recSection})
end

-- AddLabel: "prefix : value" monospace readout, :Set updates value
local function makeLabel(prefix, initial)
    local row=makeRow(sc(18))
    New("TextLabel",{Text=(prefix or "").." :",BackgroundTransparency=1,Font=Mono,
        TextSize=sc(10),TextColor3=T.Dim,TextXAlignment=Enum.TextXAlignment.Left,
        Size=UDim2.fromOffset(sc(72),sc(18)),TextYAlignment=Enum.TextYAlignment.Center,
        ZIndex=14,Parent=row})
    local val=New("TextLabel",{Text=tostring(initial or ""),BackgroundTransparency=1,Font=Mono,
        TextSize=sc(10),TextColor3=T.Text,TextXAlignment=Enum.TextXAlignment.Left,
        Size=UDim2.new(1,-sc(74),sc(18)),Position=UDim2.fromOffset(sc(74),0),
        TextYAlignment=Enum.TextYAlignment.Center,ZIndex=14,Parent=row})
    return {Set=function(s) val.Text=tostring(s) end, Get=function() return val.Text end}
end

-- AddStatusItem: green ✓ / red ✗ square + label
local function makeStatusItem(label, initial)
    local state=initial==true
    local row=makeRow(sc(18))
    local icon=New("TextLabel",{Text=state and "✓" or "✗",BackgroundTransparency=1,Font=MonoBold,
        TextSize=sc(11),TextColor3=state and T.Green or T.Red,
        Size=UDim2.fromOffset(sc(14),sc(18)),TextXAlignment=Enum.TextXAlignment.Left,
        TextYAlignment=Enum.TextYAlignment.Center,ZIndex=14,Parent=row})
    local lbl=New("TextLabel",{Text=label or "",BackgroundTransparency=1,Font=Mono,
        TextSize=sc(10),TextColor3=state and T.Text or T.Dim,TextXAlignment=Enum.TextXAlignment.Left,
        Size=UDim2.new(1,-sc(14),sc(18)),Position=UDim2.fromOffset(sc(14),0),
        TextYAlignment=Enum.TextYAlignment.Center,ZIndex=14,Parent=row})
    return {Set=function(v)
        state=v==true
        icon.Text=state and "✓" or "✗"
        icon.TextColor3=state and T.Green or T.Red
        lbl.TextColor3=state and T.Text or T.Dim
    end, Get=function() return state end}
end

-- AddToggle: square checkbox (crimson ✓ on / outlined empty off)
local function makeToggle(label, flagKey)
    local state=(Flags[flagKey]==true)
    local row=makeRow(sc(20))
    local lbl=New("TextLabel",{Text=label,BackgroundTransparency=1,Font=Mono,
        TextSize=sc(10),TextColor3=state and T.Text or T.Dim,
        Size=UDim2.new(1,-sc(18),1,0),TextXAlignment=Enum.TextXAlignment.Left,
        TextYAlignment=Enum.TextYAlignment.Center,ZIndex=14,Parent=row})
    local box=New("Frame",{Size=UDim2.fromOffset(sc(12),sc(12)),
        Position=UDim2.new(1,-sc(12),0.5,-sc(6)),
        BackgroundColor3=state and T.Accent or T.Panel,BorderSizePixel=0,ZIndex=14,Parent=row})
    Corner(sc(2),box)
    New("UIStroke",{Color=T.Border,Transparency=state and 1 or 0,Thickness=1,
        ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Parent=box})
    local mark=New("TextLabel",{Text=state and "✓" or "",BackgroundTransparency=1,Font=MonoBold,
        TextSize=sc(9),TextColor3=T.Text,Size=UDim2.fromScale(1,1),
        TextYAlignment=Enum.TextYAlignment.Center,Parent=box})
    -- full-row transparent hit target (touch-friendly)
    local hit=New("TextButton",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="",
        AutoButtonColor=false,ZIndex=20,Parent=row})
    local function set(v)
        state=v; Flags[flagKey]=v
        Tween(box,0.10,{BackgroundColor3=v and T.Accent or T.Panel})
        mark.Text=v and "✓" or ""
        lbl.TextColor3=v and T.Text or T.Dim
    end
    hit.Activated:Connect(function() set(not state) end)
    Flags[flagKey]=state
    return {Set=set, Get=function() return state end}
end

-- AddButton: flat, crimson text, crimson press flash
local function makeButton(label, cb)
    local row=makeRow(sc(22))
    local btn=New("TextButton",{Text=label or "",Size=UDim2.fromScale(1,1),
        BackgroundColor3=T.Panel,AutoButtonColor=false,Font=MonoBold,TextSize=sc(10),
        TextColor3=T.Accent,ZIndex=14,Parent=row})
    Corner(sc(2),btn)
    New("UIStroke",{Color=T.Border,Transparency=0,Thickness=1,
        ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Parent=btn})
    btn.Activated:Connect(function()
        Tween(btn,0.08,{BackgroundColor3=T.Accent,TextColor3=T.Text})
        task.delay(0.10,function() Tween(btn,0.16,{BackgroundColor3=T.Panel,TextColor3=T.Accent}) end)
        if cb then cb() end
    end)
    return btn
end

-- AddSlider: compact label/value + thin bar
local function makeSlider(label, minV, maxV, default, opts)
    opts=opts or {}
    local quant=opts.quant or function(v) return math.floor(v+0.5) end
    local fmt  =opts.fmt   or tostring
    local store=opts.store or function(v) end
    local row=makeRow(sc(28))
    New("TextLabel",{Text=label,BackgroundTransparency=1,Font=Mono,
        TextSize=sc(9),TextColor3=T.Dim,Size=UDim2.new(0.6,0,0,sc(13)),
        TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,ZIndex=14,Parent=row})
    local valLbl=New("TextLabel",{BackgroundTransparency=1,Font=MonoBold,
        TextSize=sc(9),TextColor3=T.Accent,TextXAlignment=Enum.TextXAlignment.Right,
        Size=UDim2.new(0.4,0,0,sc(13)),Position=UDim2.new(0.6,0,0,0),
        TextYAlignment=Enum.TextYAlignment.Center,ZIndex=14,Parent=row})
    local bar=New("TextButton",{Size=UDim2.new(1,0,0,sc(4)),Position=UDim2.new(0,0,0,sc(16)),
        BackgroundColor3=T.Off,AutoButtonColor=false,Text="",ZIndex=14,Parent=row})
    Corner(sc(2),bar)
    local fill=New("Frame",{Size=UDim2.new(0,0,1,0),BackgroundColor3=T.Accent,
        BorderSizePixel=0,ZIndex=15,Parent=bar})
    Corner(sc(2),fill)
    local grab=New("Frame",{Size=UDim2.fromOffset(sc(8),sc(8)),
        AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0,0,0.5,0),
        BackgroundColor3=T.Accent,BorderSizePixel=0,ZIndex=16,Parent=bar})
    Corner(sc(2),grab)
    local function apply(v)
        v=quant(math.clamp(v,minV,maxV))
        store(v)
        local p=(v-minV)/(maxV-minV)
        fill.Size=UDim2.new(p,0,1,0)
        grab.Position=UDim2.new(p,0,0.5,0)
        valLbl.Text=fmt(v)
    end
    apply(default)
    local sliding=false
    local function pt(i) return math.clamp((i.Position.X-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1) end
    bar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
            sliding=true; apply(minV+(maxV-minV)*pt(i))
        end
    end)
    track(UserInputService.InputChanged:Connect(function(i)
        if not sliding then return end
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMovement then
            apply(minV+(maxV-minV)*pt(i))
        end
    end))
    track(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
            sliding=false
        end
    end))
    return {Set=apply, Get=function() return Flags[opts.flag] end}
end

-- AddDropdown: compact flat, overlay menu
local function makeDropdown(label, options, default, cb)
    local cur=default or (options and options[1] or "")
    local row=makeRow(sc(22))
    New("TextLabel",{Text=label or "",BackgroundTransparency=1,Font=Mono,
        TextSize=sc(9),TextColor3=T.Dim,Size=UDim2.new(0.4,0,1,0),
        TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,ZIndex=14,Parent=row})
    local btn=New("TextButton",{Text=cur.."  ▾",Size=UDim2.new(0.6,-sc(2),1,0),
        Position=UDim2.new(0.4,0,0,0),BackgroundColor3=T.Panel,AutoButtonColor=false,
        Font=MonoBold,TextSize=sc(9),TextColor3=T.Accent,
        TextXAlignment=Enum.TextXAlignment.Right,ZIndex=14,Parent=row})
    Corner(sc(2),btn)
    New("UIStroke",{Color=T.Border,Transparency=0,Thickness=1,
        ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Parent=btn})
    local menu=nil
    local function close() if menu then menu:Destroy(); menu=nil end end
    btn.Activated:Connect(function()
        if menu then close(); return end
        local ap=btn.AbsolutePosition; local as=btn.AbsoluteSize
        menu=New("Frame",{Position=UDim2.fromOffset(ap.X,ap.Y+as.Y+sc(2)),
            Size=UDim2.fromOffset(as.X, sc(20)*#options+sc(6)),
            BackgroundColor3=T.Panel,BorderSizePixel=0,ClipsDescendants=true,ZIndex=30,Parent=panel})
        Corner(sc(2),menu)
        New("UIStroke",{Color=T.Accent,Transparency=0.2,Thickness=1,
            ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Parent=menu})
        New("UIListLayout",{Padding=UDim.new(0,0),Parent=menu})
        New("UIPadding",{PaddingTop=UDim.new(0,sc(3)),Parent=menu})
        for _,opt in ipairs(options) do
            local o=New("TextButton",{Text=" "..opt,Size=UDim2.new(1,0,0,sc(20)),
                BackgroundTransparency=1,AutoButtonColor=false,Font=Mono,
                TextSize=sc(9),TextColor3=(opt==cur) and T.Accent or T.Text,
                TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,
                ZIndex=31,Parent=menu})
            o.Activated:Connect(function()
                cur=opt; btn.Text=cur.."  ▾"
                if cb then cb(cur) end; close()
            end)
        end
    end)
    track(UserInputService.InputBegan:Connect(function(i)
        if not menu then return end
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
            local mp,ms=menu.AbsolutePosition,menu.AbsoluteSize
            local bp,bs=btn.AbsolutePosition,btn.AbsoluteSize
            local p=i.Position
            local outsideMenu=(p.X<mp.X or p.X>mp.X+ms.X or p.Y<mp.Y or p.Y>mp.Y+ms.Y)
            local onButton   =(p.X>=bp.X and p.X<=bp.X+bs.X and p.Y>=bp.Y and p.Y<=bp.Y+bs.Y)
            if outsideMenu and not onButton then close() end
        end
    end))
    return {Set=function(v) cur=v; btn.Text=cur.."  ▾" end, Get=function() return cur end}
end

-- ── tab buttons ───────────────────────────────────────────
for i,name in ipairs(TAB_NAMES) do
    tabCards[name]={}
    local wrap=New("Frame",{Size=UDim2.fromOffset(sc(58),TAB_H),BackgroundTransparency=1,
        LayoutOrder=i,ZIndex=12,Parent=tabScroll})
    local btn=New("TextButton",{Text=name,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
        AutoButtonColor=false,Font=MonoBold,TextSize=sc(10),TextColor3=T.Dim,
        TextYAlignment=Enum.TextYAlignment.Center,ZIndex=13,Parent=wrap})
    local underline=New("Frame",{Size=UDim2.new(1,0,0,2),
        AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,0,1,0),
        BackgroundColor3=T.Accent,BorderSizePixel=0,Visible=false,ZIndex=14,Parent=wrap})
    tabBtns[name]=btn; tabUnderline[name]=underline
    btn.Activated:Connect(function()
        showTab(name)
        for n,b in pairs(tabBtns) do
            local on=(n==name)
            b.TextColor3=on and T.Accent or T.Dim
            tabUnderline[n].Visible=on
        end
    end)
end

-- ══════════════════════════════════════════════════════════
-- TAB CONTENT (compact 2-column)
-- ══════════════════════════════════════════════════════════

-- ── STATS TAB (Project Apex example General tab) ──────────
recTab="Stats"
recCol="Left"
makeSep("Session")
local stTime=makeLabel("Time",    "0:00")
local stFps =makeLabel("FPS",     "0")
local stPl  =makeLabel("Players", "0")
local stPing=makeLabel("Ping",    "0ms")
makeSep("Build")
makeLabel("Hub",    "Apex Mobile")
makeLabel("Status", "Authed")
makeButton("Hide UI", function() if togglePanel then togglePanel() end end)

recCol="Right"
makeSep("Checklist")
local ckEsp  =makeStatusItem("Player ESP",   Flags.esp_enabled)
local ckAim  =makeStatusItem("Silent Aim",   Flags.sa_enabled)
local ckTb   =makeStatusItem("Triggerbot",   Flags.tb_enabled)
local ckXray =makeStatusItem("X-Ray",        Flags.m_xray)
local ckClip =makeStatusItem("No Clip",      Flags.m_noclip)
local ckFree =makeStatusItem("Free Cam",     Flags.m_freecam)
makeSep("Open Tab")
makeDropdown("Tab", TAB_NAMES, "Stats", function(v) showTab(v) end)

-- live Stats updater
do
    local _t0=os.clock(); local _fr=0; local _samp=_t0
    track(RunService.RenderStepped:Connect(function() _fr+=1 end))
    local _st=0
    track(RunService.Heartbeat:Connect(function(dt)
        _st+=dt; if _st<0.5 then return end; _st=0
        local now=os.clock(); local e=math.floor(now-_t0)
        local fps=math.floor(_fr/math.max(now-_samp,0.001)+0.5); _fr=0; _samp=now
        stTime.Set(string.format("%d:%02d", math.floor(e/60), e%60))
        stFps.Set(tostring(fps))
        stPl.Set(tostring(#Players:GetPlayers()))
        stPing.Set(math.floor(LocalPlayer:GetNetworkPing()*1000).."ms")
        ckEsp.Set(Flags.esp_enabled); ckAim.Set(Flags.sa_enabled)
        ckTb.Set(Flags.tb_enabled); ckXray.Set(Flags.m_xray)
        ckClip.Set(Flags.m_noclip); ckFree.Set(Flags.m_freecam)
    end))
end

-- ── VISUAL TAB ────────────────────────────────────────────
recTab="Visual"
recCol="Left"
makeSep("Player ESP")
makeToggle("ESP Enabled",       "esp_enabled")
makeToggle("Box",               "esp_box")
makeToggle("Name",              "esp_name")
makeToggle("Health Bar",        "esp_health")
makeToggle("Distance",          "esp_dist")
makeToggle("Highlight Chams",   "esp_chams")
Flags.esp_maxdist = Flags.esp_maxdist or 1500
makeSlider("ESP Distance", 100, 2000, Flags.esp_maxdist, {
    flag="esp_maxdist",
    quant=function(v) return math.floor(v/50+0.5)*50 end,
    fmt=function(v) return tostring(v).."m" end,
    store=function(v) Flags.esp_maxdist=v end,
})
makeSep("Crosshair")
makeToggle("Crosshair",         "crosshair_enabled")

recCol="Right"
makeSep("FOV")
makeToggle("FOV Changer",       "w_fovchanger")
makeSlider("Custom FOV", 30, 120, Flags.w_customfov or 70, {
    flag="w_customfov",
    fmt=tostring, store=function(v) Flags.w_customfov=v end,
})
makeSep("Team Check")
makeToggle("Team Check",        "tc_enabled")
makeSep("X-Ray")
makeToggle("X-Ray",             "m_xray")
makeSlider("X-Ray Trans", 0.1, 0.98, Flags.m_xray_trans or 0.85, {
    flag="m_xray_trans",
    quant=function(v) return math.floor(v*100+0.5)/100 end,
    fmt=function(v) return tostring(math.floor(v*100)).."%" end,
    store=function(v) Flags.m_xray_trans=v end,
})

-- ── WORLD TAB ─────────────────────────────────────────────
recTab="World"
recCol="Left"
makeSep("World ESP")
makeToggle("Harvestables",  "wesp_harv")
makeToggle("Ore / Stone",   "wesp_ore")
makeToggle("Sleepers",      "wesp_sleepers")
makeToggle("Placed C4",     "wesp_c4")
makeToggle("C4 Alert",      "wesp_c4_alert")
makeToggle("Rockets",       "wesp_rockets")
makeToggle("Turrets",       "wesp_turrets")
makeToggle("Storage",       "wesp_storage")
makeToggle("Sleeping Bags", "wesp_beds")

recCol="Right"
makeSep("Lighting")
makeToggle("Full Bright",   "w_fullbright")
makeToggle("No Fog",        "w_nofog")
makeToggle("No Shadows",    "w_noshadows")
makeSep("Environment")
makeToggle("No Leaves",     "w_notrees")
makeToggle("No Grass",      "w_nograss")

-- ── PLAYER TAB ────────────────────────────────────────────
recTab="Player"
recCol="Left"
makeSep("Movement")
makeToggle("Omni Sprint",       "m_omnisprint")
Flags.m_omnisprint_bonus = Flags.m_omnisprint_bonus or 8
makeSlider("Sprint Speed", 16, 100, 24, {
    flag="m_omnisprint_bonus",
    fmt=tostring, store=function(v) Flags.m_omnisprint_bonus=v-16 end,
})
makeToggle("No Clip",           "m_noclip")
makeToggle("Free Cam",          "m_freecam")
makeSlider("Cam Speed", 10, 200, Flags.m_freecam_speed or 40, {
    flag="m_freecam_speed",
    fmt=tostring, store=function(v) Flags.m_freecam_speed=v end,
})

recCol="Right"
makeSep("Combat")
makeToggle("Silent Aim",       "sa_enabled")
makeToggle("Always Headshot",  "always_headshot")
makeToggle("No Recoil",        "no_recoil")
makeToggle("No Spread",        "no_spread")
makeToggle("Fire Rate",        "fr_enabled")
makeSlider("Fire Rate RPM", 250, 1500, Flags.fr_rpm or 600, {
    flag="fr_rpm",
    quant=function(v) return math.floor(v/50+0.5)*50 end,
    fmt=tostring, store=function(v) Flags.fr_rpm=v end,
})
makeToggle("Triggerbot",       "tb_enabled")
makeSlider("TB FOV", 10, 200, Flags.tb_fov or 60, {
    flag="tb_fov",
    fmt=function(v) return tostring(v).."px" end, store=function(v) Flags.tb_fov=v end,
})

recTab=nil; recCol=nil; recSection=nil

-- ── default tab: land on the example Stats tab ────────────
showTab("Stats")
tabBtns["Stats"].TextColor3=T.Accent
tabUnderline["Stats"].Visible=true

-- ══════════════════════════════════════════════════════════
-- MOBILE CONTROLS HOOK
-- Fire button → _fire_held (aimbot while held)
-- Crouch button → toggle OmniSprint
-- ══════════════════════════════════════════════════════════
task.spawn(function()
    local pg=LocalPlayer:WaitForChild("PlayerGui",30)
    if not pg then return end
    local _hookedGuis={}
    local function hookControls(gui)
        if _hookedGuis[gui] then return end
        _hookedGuis[gui]=true
        local function findBtn(root,name)
            for _,d in ipairs(root:GetDescendants()) do
                if (d:IsA("TextButton") or d:IsA("ImageButton") or d:IsA("Frame"))
                    and d.Name:lower()==name:lower() then return d end
            end
        end
        local fireBtn=findBtn(gui,"Fire")
        local crouchBtn=findBtn(gui,"Crouch") or findBtn(gui,"Sprint") or findBtn(gui,"Run")
        if fireBtn then
            fireBtn.InputBegan:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.Touch then Flags._fire_held=true end
            end)
            fireBtn.InputEnded:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.Touch then Flags._fire_held=false end
            end)
        end
        if crouchBtn then
            crouchBtn.InputBegan:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.Touch then Flags._crouch_held=true end
            end)
            crouchBtn.InputEnded:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.Touch then Flags._crouch_held=false end
            end)
        end
    end
    local names={"BriskMobileControls","MobileControls","TouchGui","MobileGui"}
    local function tryFind()
        for _,n in ipairs(names) do
            local g=pg:FindFirstChild(n,true)
            if g then hookControls(g);return true end
        end
    end
    if not tryFind() then
        pg.ChildAdded:Connect(function(c)
            task.defer(function() hookControls(c) end)
        end)
    end
    -- re-hook on respawn in case GUI gets recreated
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(2)
        for _,n in ipairs(names) do
            local g=pg:FindFirstChild(n,true)
            if g then hookControls(g) end
        end
    end)
end)

-- ══════════════════════════════════════════════════════════
-- COMBAT HELPERS  (cached per-frame, not per-call)
-- ══════════════════════════════════════════════════════════
local R6={Head="Head",Torso="Torso",["Left Arm"]="Left Arm",
    ["Right Arm"]="Right Arm",["Left Leg"]="Left Leg",["Right Leg"]="Right Leg"}
local function getR6Part(char,name)
    return char:FindFirstChild(R6[name] or name)
        or char:FindFirstChild("Torso")
        or char:FindFirstChild("HumanoidRootPart")
end

-- cache enemies list, refresh once per frame
local _enemyCache={}
local _enemyCacheTick=0
local function getEnemies()
    local now=os.clock()
    if now==_enemyCacheTick then return _enemyCache end
    _enemyCacheTick=now
    local list={}
    local myClanId=Flags.tc_enabled and LocalPlayer:GetAttribute("ClanId")
    for _,p in ipairs(Players:GetPlayers()) do
        if p==LocalPlayer then continue end
        if myClanId~=nil and p:GetAttribute("ClanId")==myClanId then continue end
        local char=p.Character
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        local root=char and char:FindFirstChild("HumanoidRootPart")
        if char and hum and hum.Health>0 and root then
            list[#list+1]={player=p,char=char,hum=hum,root=root}
        end
    end
    _enemyCache=list
    return list
end

local function predictPos(partPos, vel, camPos)
    local bulletSpeed = Flags.sa_bulletspeed or 2000
    local dist = (partPos - camPos).Magnitude
    local travelTime = dist / bulletSpeed
    local pingOffset = math.min(LocalPlayer:GetNetworkPing(), 0.15)
    return partPos + vel * (travelTime + pingOffset)
end

local function screenDist(worldPos)
    local cam=workspace.CurrentCamera
    local sp,on=cam:WorldToViewportPoint(worldPos)
    if not on or sp.Z<=0 then return math.huge end
    local vps=cam.ViewportSize
    return math.sqrt((sp.X-vps.X*0.5)^2+(sp.Y-vps.Y*0.5)^2)
end

local _visParamsAim=RaycastParams.new()
_visParamsAim.FilterType=Enum.RaycastFilterType.Exclude
local function isEnemyVisible(e)
    local char=e.char
    local torso=char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
    if not torso then return false end
    local cam=workspace.CurrentCamera
    _visParamsAim.FilterDescendantsInstances={LocalPlayer.Character,char}
    local hit=workspace:Raycast(cam.CFrame.Position,torso.Position-cam.CFrame.Position,_visParamsAim)
    return hit==nil
end

local function getClosest(partName,fovPx,maxWorldDist)
    local bestVisible,bestVisibleDist=nil,math.huge
    local bestAny,bestAnyDist=nil,math.huge
    local myRoot=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    for _,e in ipairs(getEnemies()) do
        local part=e.char:FindFirstChild(partName or "Head") or e.char:FindFirstChild("HumanoidRootPart")
        if part then
            local worldDist=(part.Position-myRoot.Position).Magnitude
            if maxWorldDist and worldDist>maxWorldDist then continue end
            if fovPx and fovPx<math.huge then
                local sd=screenDist(part.Position)
                if sd>fovPx then continue end
            end
            if isEnemyVisible(e) then
                if worldDist<bestVisibleDist then bestVisibleDist=worldDist;bestVisible=e end
            else
                if worldDist<bestAnyDist then bestAnyDist=worldDist;bestAny=e end
            end
        end
    end
    return bestVisible or bestAny
end

-- ══════════════════════════════════════════════════════════
-- GUNFIRE HOOK  (Silent Aim + No Spread)
-- ══════════════════════════════════════════════════════════
local _hooked=false
local _frLastFired=0
track(RunService.Heartbeat:Connect(function()
    if _hooked or not GunFire or not hookfunction then return end
    _hooked=true
    local orig=GunFire.FireServer
    hookfunction(orig,newcclosure(function(self,...)
        local args={...}
        if Flags.fr_enabled then
            local cooldown=60/(Flags.fr_rpm or 600)
            local now=os.clock()
            if now-_frLastFired < cooldown then return end
            _frLastFired=now
        end
        local origin=typeof(args[1])=="Vector3" and args[1] or workspace.CurrentCamera.CFrame.Position
        local cam=workspace.CurrentCamera

        -- Aimbot headshot guarantee: when fire_held, always redirect to head
        if Flags._fire_held and not Flags.sa_enabled then
            local target=getClosest("Head",math.huge,Flags.ab_maxdist or 300)
            if target then
                local part=getR6Part(target.char,Flags.ab_part or "Head")
                if part then
                    local aimPos=predictPos(part.Position,target.root.AssemblyLinearVelocity,origin)
                    local dist=(part.Position-origin).Magnitude
                    if dist<=80 then args[1]=aimPos end
                    args[3]=(aimPos-origin).Unit
                end
            end
        end

        -- Always Headshot: closest on-screen head
        if Flags.always_headshot and not _rapidFireActive then
            local bestDist,bestHead=math.huge,nil
            for _,p in ipairs(Players:GetPlayers()) do
                if p~=LocalPlayer and p.Character then
                    local myClanId=Flags.tc_enabled and LocalPlayer:GetAttribute("ClanId")
                    if myClanId~=nil and p:GetAttribute("ClanId")==myClanId then continue end
                    local hum=p.Character:FindFirstChildOfClass("Humanoid")
                    local head=p.Character:FindFirstChild("Head")
                    if head and hum and hum.Health>0 then
                        local sp,onSc=cam:WorldToViewportPoint(head.Position)
                        if onSc and sp.Z>0 then
                            local vp=cam.ViewportSize
                            local d=(Vector2.new(sp.X,sp.Y)-Vector2.new(vp.X*0.5,vp.Y*0.5)).Magnitude
                            if d<bestDist then bestDist=d;bestHead=head end
                        end
                    end
                end
            end
            if bestHead then
                local dir=(bestHead.Position-origin)
                if dir.Magnitude>0.01 then args[3]=dir.Unit end
                return orig(self,table.unpack(args))
            end
        end

        -- Silent Aim
        if Flags.sa_enabled then
            local keyHeld=(not Flags.sa_key) or UserInputService:IsKeyDown(Flags.sa_key)
            if keyHeld and math.random(100)<=(Flags.sa_hitchance or 100) then
                local target=getClosest(Flags.sa_part or "Head",Flags.sa_fov or 120,Flags.sa_maxdist or 300)
                if target then
                    local part=getR6Part(target.char,Flags.sa_part or "Head")
                    if part and typeof(origin)=="Vector3" then
                        local aimPos=predictPos(part.Position,target.root.AssemblyLinearVelocity,origin)
                        local dist=(part.Position-origin).Magnitude
                        if dist<=80 then args[1]=aimPos end
                        args[3]=(aimPos-origin).Unit
                    end
                end
            end
        end

        -- No Spread
        if Flags.no_spread then
            if #args>=3 and typeof(args[3])=="Vector3" then
                args[3]=cam.CFrame.LookVector
            end
        end

        return orig(self,table.unpack(args))
    end))
end))

-- ── No Recoil (throttled: only unbind when tool changes) ──
local _lastTool=""
track(RunService.Heartbeat:Connect(function()
    if not Flags.no_recoil then return end
    local char=LocalPlayer.Character; if not char then return end
    for _,tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and tool.Name~=_lastTool then
            _lastTool=tool.Name
            RunService:UnbindFromRenderStep("Recoil_"..tool.Name)
        end
    end
end))

-- ── Aimbot (RenderStepped, only when fire held) ──
track(RunService.RenderStepped:Connect(function()
    if not Flags._fire_held then return end
    local partName=Flags.ab_part or "Head"
    local target=getClosest(partName,Flags.ab_fov or 120, Flags.ab_maxdist or 300)
    if not target then return end
    local part=getR6Part(target.char,partName)
    if not part then return end
    local targetPos=part.Position
    local cam=workspace.CurrentCamera
    if Flags.ab_predict then
        targetPos=predictPos(part.Position,target.root.AssemblyLinearVelocity,cam.CFrame.Position)
    end
    local sp,onScreen=cam:WorldToViewportPoint(targetPos)
    if not onScreen or sp.Z<=0 then return end
    local smooth=math.clamp((Flags.ab_smooth or 8)/50,0.01,1)
    local w=cam.CFrame
    cam.CFrame=w:Lerp(CFrame.lookAt(w.Position,targetPos),math.clamp(1-smooth,0.01,0.99))
end))

-- ══════════════════════════════════════════════════════════
-- ESP  (runs on Heartbeat at ~20fps cap to save perf)
-- ══════════════════════════════════════════════════════════
do
    local espGui=New("ScreenGui",{Name="ApexMobileESP",ResetOnSpawn=false,
        IgnoreGuiInset=true,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,Parent=GetGui()})
    local _espData={}

    local function getCharBounds(char)
        local cam=workspace.CurrentCamera
        local head=char:FindFirstChild("Head")
        local root=char:FindFirstChild("HumanoidRootPart")
        local lleg=char:FindFirstChild("Left Leg") or root
        if not head or not root then return nil end
        local topY=head.Position.Y+head.Size.Y*0.5
        local botY=(lleg or root).Position.Y-(lleg or root).Size.Y*0.5
        local spT,onT=cam:WorldToViewportPoint(Vector3.new(root.Position.X,topY,root.Position.Z))
        local spB,onB=cam:WorldToViewportPoint(Vector3.new(root.Position.X,botY,root.Position.Z))
        if (not onT and not onB) or (spT.Z<=0 and spB.Z<=0) then return nil end
        local h=math.abs(spT.Y-spB.Y)
        local cx=(spT.X+spB.X)*0.5
        return cx-h*0.45, math.min(spT.Y,spB.Y), cx+h*0.45, math.min(spT.Y,spB.Y)+h
    end

    -- 50Hz cached visibility raycast (shared params object)
    local _visCache={};local _visTick={}
    local _visParams=RaycastParams.new()
    _visParams.FilterType=Enum.RaycastFilterType.Exclude
    local VIS_RATE=0.02
    local function isVisible(p,char,root)
        local now=os.clock()
        if not _visTick[p] or (now-_visTick[p])>=VIS_RATE then
            _visTick[p]=now
            local cam=workspace.CurrentCamera
            _visParams.FilterDescendantsInstances={LocalPlayer.Character,char}
            local torso=char:FindFirstChild("Torso") or root
            local hit=workspace:Raycast(cam.CFrame.Position,torso.Position-cam.CFrame.Position,_visParams)
            _visCache[p]=(hit==nil)
        end
        return _visCache[p]
    end

    local function makeESP(p)
        if _espData[p] then return end
        local d={}
        local bf=New("Frame",{BackgroundTransparency=1,BorderSizePixel=0,
            Size=UDim2.fromOffset(0,0),Visible=false,Parent=espGui})
        local function ml()
            return New("Frame",{BorderSizePixel=0,BackgroundColor3=Color3.new(1,1,1),Parent=bf})
        end
        d.bT=ml();d.bB=ml();d.bL=ml();d.bR=ml();d.bf=bf
        d.nl=New("TextLabel",{BackgroundTransparency=1,Font=Enum.Font.GothamBold,
            TextSize=11,TextStrokeTransparency=0.5,TextStrokeColor3=Color3.new(0,0,0),
            Visible=false,Parent=espGui})
        d.hBg=New("Frame",{BackgroundColor3=Color3.fromRGB(30,30,30),BorderSizePixel=0,
            Visible=false,Parent=espGui})
        d.hFill=New("Frame",{BackgroundColor3=Color3.fromRGB(80,255,120),BorderSizePixel=0,
            AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,0,1,0),Parent=d.hBg})
        d.dl=New("TextLabel",{BackgroundTransparency=1,Font=Enum.Font.GothamBold,
            TextSize=10,TextStrokeTransparency=0.5,TextStrokeColor3=Color3.new(0,0,0),
            Visible=false,Parent=espGui})
        d.tr=New("Frame",{BackgroundColor3=Color3.fromRGB(0,180,255),BorderSizePixel=0,
            AnchorPoint=Vector2.new(0,0.5),Visible=false,Parent=espGui})
        d.hl=New("Highlight",{FillTransparency=0.5,OutlineTransparency=0,
            DepthMode=Enum.HighlightDepthMode.AlwaysOnTop,Enabled=false,Parent=espGui})
        _espData[p]=d
    end

    local function hideESP(d)
        d.bf.Visible=false;d.nl.Visible=false;d.hBg.Visible=false
        d.dl.Visible=false;d.tr.Visible=false;d.hl.Enabled=false
    end
    local function removeESP(p)
        local d=_espData[p];if not d then return end
        for _,k in ipairs({"bf","nl","hBg","dl","tr","hl"}) do
            pcall(function() d[k]:Destroy() end)
        end
        _espData[p]=nil
    end
    local function drawBox(d,x1,y1,x2,y2,col)
        local w,h=x2-x1,y2-y1
        d.bf.Position=UDim2.fromOffset(x1,y1);d.bf.Size=UDim2.fromOffset(w,h);d.bf.Visible=true
        d.bT.Position=UDim2.fromOffset(0,0);d.bT.Size=UDim2.fromOffset(w,1);d.bT.BackgroundColor3=col
        d.bB.Position=UDim2.fromOffset(0,h-1);d.bB.Size=UDim2.fromOffset(w,1);d.bB.BackgroundColor3=col
        d.bL.Position=UDim2.fromOffset(0,0);d.bL.Size=UDim2.fromOffset(1,h);d.bL.BackgroundColor3=col
        d.bR.Position=UDim2.fromOffset(w-1,0);d.bR.Size=UDim2.fromOffset(1,h);d.bR.BackgroundColor3=col
    end

    -- throttle ESP to ~20 updates/sec
    local _espTick=0
    track(RunService.Heartbeat:Connect(function(dt)
        _espTick+=dt; if _espTick<0.05 then return end; _espTick=0
        local myChar=LocalPlayer.Character
        local myRoot=myChar and myChar:FindFirstChild("HumanoidRootPart")
        local maxDist=Flags.esp_maxdist or 1500
        local cam=workspace.CurrentCamera
        local vps=cam.ViewportSize

        for _,p in ipairs(Players:GetPlayers()) do
            if p==LocalPlayer then continue end
            if not _espData[p] then makeESP(p) end
            local d=_espData[p];if not d then continue end
            local char=p.Character
            local hum=char and char:FindFirstChildOfClass("Humanoid")
            local root=char and char:FindFirstChild("HumanoidRootPart")
            local head=char and char:FindFirstChild("Head")
            if not Flags.esp_enabled or not char or not hum or hum.Health<=0 or not root or not head then
                hideESP(d);continue
            end
            local dist=myRoot and (root.Position-myRoot.Position).Magnitude or 0
            if dist>maxDist then hideESP(d);continue end
            local sp,on=cam:WorldToViewportPoint(head.Position)
            if not on then hideESP(d);continue end
            local x1,y1,x2,y2=getCharBounds(char)
            if not x1 then hideESP(d);continue end
            x1-=2;y1-=2;x2+=2;y2+=2
            local bw,bh=x2-x1,y2-y1

            local visible=isVisible(p,char,root)
            if Flags.esp_box then
                local col=visible and (Flags.esp_box_col or Color3.new(1,1,1)) or Color3.fromRGB(255,60,60)
                drawBox(d,x1,y1,x2,y2,col)
            else d.bf.Visible=false end

            if Flags.esp_name then
                d.nl.Text=p.DisplayName
                d.nl.TextColor3=Flags.esp_name_col or Color3.new(1,1,1)
                d.nl.TextSize=Flags.esp_textsize or 11
                d.nl.Size=UDim2.fromOffset(bw+20,14)
                d.nl.Position=UDim2.fromOffset(x1-10,y1-16)
                d.nl.TextXAlignment=Enum.TextXAlignment.Center
                d.nl.Visible=true
            else d.nl.Visible=false end

            if Flags.esp_health then
                local hp=math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1)
                d.hBg.Position=UDim2.fromOffset(x1-6,y1)
                d.hBg.Size=UDim2.fromOffset(3,bh)
                d.hBg.Visible=true
                d.hFill.BackgroundColor3=Flags.esp_health_col or Color3.fromRGB(80,255,120)
                d.hFill.Size=UDim2.new(1,0,hp,0)
            else d.hBg.Visible=false end

            if Flags.esp_dist then
                d.dl.Text=math.floor(dist).."m"
                d.dl.TextColor3=Flags.esp_name_col or Color3.new(1,1,1)
                d.dl.Size=UDim2.fromOffset(bw+20,12)
                d.dl.Position=UDim2.fromOffset(x1-10,y2+2)
                d.dl.TextXAlignment=Enum.TextXAlignment.Center
                d.dl.Visible=true
            else d.dl.Visible=false end

            d.tr.Visible=false

            if Flags.esp_chams then
                d.hl.Adornee=char
                d.hl.FillColor=Flags.esp_fill_col or Color3.fromRGB(255,60,90)
                d.hl.FillTransparency=1-(Flags.esp_fill_opacity or 50)/100
                d.hl.OutlineColor=Flags.esp_outline_col or Color3.new(1,1,1)
                d.hl.Enabled=true
            else d.hl.Enabled=false end
        end
        for p in pairs(_espData) do
            if not p.Parent then
                _visCache[p]=nil;_visTick[p]=nil
                removeESP(p)
            end
        end
    end))
    Players.PlayerRemoving:Connect(removeESP)
end

-- ══════════════════════════════════════════════════════════
-- FOV CHANGER
-- ══════════════════════════════════════════════════════════
do
    local _origFov=nil
    track(RunService.RenderStepped:Connect(function()
        if Flags.w_fovchanger then
            if not _origFov then _origFov=workspace.CurrentCamera.FieldOfView end
            workspace.CurrentCamera.FieldOfView=Flags.w_customfov or 70
        else
            if _origFov then
                workspace.CurrentCamera.FieldOfView=_origFov
                _origFov=nil
            end
        end
    end))
end

-- ══════════════════════════════════════════════════════════
-- WORLD ESP  (throttled ~10fps)
-- ══════════════════════════════════════════════════════════
do
    local wGui=New("ScreenGui",{Name="ApexMobileWorldESP",ResetOnSpawn=false,
        IgnoreGuiInset=true,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,Parent=GetGui()})
    local _wl={}
    local function getLabel(id)
        if not _wl[id] then
            local bg=New("Frame",{BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=0.5,
                BorderSizePixel=0,AutomaticSize=Enum.AutomaticSize.XY,Parent=wGui})
            local lbl=New("TextLabel",{BackgroundTransparency=1,Font=Enum.Font.GothamBold,
                TextSize=10,TextStrokeTransparency=0.4,TextStrokeColor3=Color3.new(0,0,0),
                AutomaticSize=Enum.AutomaticSize.XY,Parent=bg})
            _wl[id]={bg=bg,lbl=lbl}
        end
        return _wl[id]
    end
    local function hideL(id) local e=_wl[id];if e then e.bg.Visible=false end end
    local function placeL(id,pos,text,col)
        local sp,on=workspace.CurrentCamera:WorldToViewportPoint(pos)
        if not on or sp.Z<=0 then hideL(id);return end
        local e=getLabel(id);e.lbl.Text=text;e.lbl.TextColor3=col
        e.bg.Position=UDim2.fromOffset(sp.X,sp.Y);e.bg.Visible=true
    end

    local _wTick=0
    track(RunService.Heartbeat:Connect(function(dt)
        _wTick+=dt;if _wTick<0.1 then return end;_wTick=0
        local myRoot=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local maxD=Flags.wesp_maxdist or 1000
        local drawn={}

        local function scanFolder(fname,cb)
            local f=workspace:FindFirstChild(fname);if not f then return end
            for _,obj in ipairs(f:GetChildren()) do
                local pos=obj:IsA("BasePart") and obj.Position or (obj.PrimaryPart and obj.PrimaryPart.Position)
                if pos and (not myRoot or (pos-myRoot.Position).Magnitude<=maxD) then cb(obj,pos) end
            end
        end

        if Flags.wesp_harv or Flags.wesp_ore then
            scanFolder("SpawnedHarvestables",function(obj,pos)
                local isOre=obj.Name:find("Ore") or obj.Name=="Stone"
                local show=(isOre and Flags.wesp_ore) or (not isOre and Flags.wesp_harv)
                if show then
                    local id="h_"..obj:GetDebugId();drawn[id]=true
                    local dist=myRoot and math.floor((pos-myRoot.Position).Magnitude) or 0
                    placeL(id,pos,obj.Name.." ["..dist.."m]",isOre and Color3.fromRGB(250,204,21) or Color3.fromRGB(100,220,100))
                end
            end)
        end
        if Flags.wesp_sleepers then
            scanFolder("OfflineSleepers",function(obj,pos)
                local id="s_"..obj:GetDebugId();drawn[id]=true
                local dist=myRoot and math.floor((pos-myRoot.Position).Magnitude) or 0
                placeL(id,pos,"SLEEPER ["..dist.."m]",Color3.fromRGB(170,170,220))
            end)
        end
        if Flags.wesp_c4 then
            scanFolder("PlacedC4",function(obj,pos)
                local id="c4_"..obj:GetDebugId();drawn[id]=true
                local dist=myRoot and math.floor((pos-myRoot.Position).Magnitude) or 0
                placeL(id,pos,"C4 ["..dist.."m]",Color3.fromRGB(255,60,60))
            end)
        end
        if Flags.wesp_rockets then
            for _,fn in ipairs({"FiredRockets","SpawnedRockets","Rockets"}) do
                scanFolder(fn,function(obj,pos)
                    local id="r_"..obj:GetDebugId();drawn[id]=true
                    local dist=myRoot and math.floor((pos-myRoot.Position).Magnitude) or 0
                    placeL(id,pos,"ROCKET ["..dist.."m]",Color3.fromRGB(255,150,40))
                end)
            end
        end
        local anyDep=Flags.wesp_turrets or Flags.wesp_storage or Flags.wesp_beds or Flags.wesp_barricades or Flags.wesp_other
        if anyDep then
            scanFolder("PlacedDeployables",function(obj,pos)
                local kind=obj.Name;local col,show
                if kind=="Turret" and Flags.wesp_turrets then col=Color3.fromRGB(244,63,94);show=true
                elseif kind=="Storage" and Flags.wesp_storage then col=Color3.fromRGB(245,158,11);show=true
                elseif kind=="Bed" and Flags.wesp_beds then col=Color3.fromRGB(99,102,241);show=true
                elseif kind=="Barricade" and Flags.wesp_barricades then col=Color3.fromRGB(168,85,247);show=true
                elseif Flags.wesp_other then col=Color3.fromRGB(180,180,180);show=true end
                if show then
                    local id="d_"..obj:GetDebugId();drawn[id]=true
                    local dist=myRoot and math.floor((pos-myRoot.Position).Magnitude) or 0
                    placeL(id,pos,kind.." ["..dist.."m]",col)
                end
            end)
        end
        for id in pairs(_wl) do if not drawn[id] then hideL(id) end end
    end))
end

-- ══════════════════════════════════════════════════════════
-- LIGHTING  (Heartbeat, throttled 0.2s)
-- ══════════════════════════════════════════════════════════
do
    local origB=Lighting.Brightness;local origA=Lighting.Ambient
    local origO=Lighting.OutdoorAmbient;local origFE=Lighting.FogEnd;local origFS=Lighting.FogStart
    local prevFB,prevFog=false,false
    local _lTick=0
    track(RunService.Heartbeat:Connect(function(dt)
        _lTick+=dt;if _lTick<0.2 then return end;_lTick=0
        if Flags.w_fullbright then
            Lighting.Brightness=10;Lighting.Ambient=Color3.new(1,1,1);Lighting.OutdoorAmbient=Color3.new(1,1,1)
        elseif prevFB then
            Lighting.Brightness=origB;Lighting.Ambient=origA;Lighting.OutdoorAmbient=origO
        end
        prevFB=Flags.w_fullbright==true
        if Flags.w_nofog then Lighting.FogEnd=9e8;Lighting.FogStart=9e8
        elseif prevFog then Lighting.FogEnd=origFE;Lighting.FogStart=origFS end
        prevFog=Flags.w_nofog==true
        Lighting.GlobalShadows=not(Flags.w_noshadows==true)
    end))
end

-- ══════════════════════════════════════════════════════════
-- CROSSHAIR
-- ══════════════════════════════════════════════════════════
do
    local chGui=New("ScreenGui",{Name="ApexMobileCH",ResetOnSpawn=false,
        IgnoreGuiInset=true,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,Parent=GetGui()})
    local function ml() return New("Frame",{BorderSizePixel=0,AnchorPoint=Vector2.new(0.5,0.5),Parent=chGui}) end
    local chT=ml();local chB=ml();local chL=ml();local chR=ml()
    track(RunService.RenderStepped:Connect(function()
        if not Flags.crosshair_enabled then
            chT.Visible=false;chB.Visible=false;chL.Visible=false;chR.Visible=false;return
        end
        local vps=workspace.CurrentCamera.ViewportSize
        local cx,cy=vps.X*0.5,vps.Y*0.5
        local gap=Flags.crosshair_gap or 4;local size=Flags.crosshair_size or 8
        local thick=Flags.crosshair_thick or 1;local col=Flags.crosshair_col or Color3.new(1,1,1)
        chT.BackgroundColor3=col;chT.Size=UDim2.fromOffset(thick,size);chT.Position=UDim2.fromOffset(cx,cy-gap-size*0.5);chT.Visible=true
        chB.BackgroundColor3=col;chB.Size=UDim2.fromOffset(thick,size);chB.Position=UDim2.fromOffset(cx,cy+gap+size*0.5);chB.Visible=true
        chL.BackgroundColor3=col;chL.Size=UDim2.fromOffset(size,thick);chL.Position=UDim2.fromOffset(cx-gap-size*0.5,cy);chL.Visible=true
        chR.BackgroundColor3=col;chR.Size=UDim2.fromOffset(size,thick);chR.Position=UDim2.fromOffset(cx+gap+size*0.5,cy);chR.Visible=true
    end))
end

-- ══════════════════════════════════════════════════════════
-- OMNI SPRINT
-- ══════════════════════════════════════════════════════════
do
    local origWS=nil
    track(RunService.Heartbeat:Connect(function()
        local active=Flags.m_omnisprint or Flags._crouch_held
        if not active then
            if origWS then
                local char=LocalPlayer.Character
                local hum=char and char:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed=origWS end;origWS=nil
            end;return
        end
        local char=LocalPlayer.Character
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health<=0 then return end
        if not origWS then origWS=hum.WalkSpeed end
        hum.WalkSpeed=16+(Flags.m_omnisprint_bonus or 8)
    end))
end

-- ══════════════════════════════════════════════════════════
-- X-RAY  (world transparency)
-- ══════════════════════════════════════════════════════════
do
    local _xrayParts={}
    local _prevXray=false

    local function getCharParts()
        local set={}
        for _,p in ipairs(Players:GetPlayers()) do
            if p.Character then
                for _,v in ipairs(p.Character:GetDescendants()) do
                    if v:IsA("BasePart") then set[v]=true end
                end
            end
        end
        local char=LocalPlayer.Character
        if char then
            for _,v in ipairs(char:GetDescendants()) do
                if v:IsA("BasePart") then set[v]=true end
            end
        end
        return set
    end

    local function applyXray()
        local charParts=getCharParts()
        for _,v in ipairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and not charParts[v] then
                if _xrayParts[v]==nil then _xrayParts[v]=v.LocalTransparencyModifier end
                v.LocalTransparencyModifier=Flags.m_xray_trans or 0.85
            end
        end
    end

    local function removeXray()
        for part,orig in pairs(_xrayParts) do
            pcall(function() part.LocalTransparencyModifier=orig end)
        end
        table.clear(_xrayParts)
    end

    local _xTick=0
    track(RunService.Heartbeat:Connect(function(dt)
        local enabled=Flags.m_xray==true
        if enabled~=_prevXray then
            _prevXray=enabled
            if not enabled then removeXray() end
        end
        if not enabled then return end
        _xTick+=dt;if _xTick<0.5 then return end;_xTick=0
        applyXray()
    end))
end

-- ══════════════════════════════════════════════════════════
-- NO CLIP
-- ══════════════════════════════════════════════════════════
do
    local ncConn=nil;local prevNC=false
    track(RunService.Heartbeat:Connect(function()
        local cur=Flags.m_noclip==true
        if cur==prevNC then return end;prevNC=cur
        if cur then
            ncConn=RunService.Stepped:Connect(function()
                local char=LocalPlayer.Character;if not char then return end
                for _,p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide=false end
                end
            end)
        else
            if ncConn then ncConn:Disconnect();ncConn=nil end
            local char=LocalPlayer.Character;if not char then return end
            for _,p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide=true end
            end
        end
    end))
end

-- ══════════════════════════════════════════════════════════
-- WATERMARK  (top-right, updates every 0.5s)
-- ══════════════════════════════════════════════════════════
do
    local wmGui=New("ScreenGui",{Name="ApexMobileWM",ResetOnSpawn=false,
        IgnoreGuiInset=true,ZIndexBehavior=Enum.ZIndexBehavior.Global,Parent=GetGui()})
    local wmF=New("Frame",{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-6,0,6),
        Size=UDim2.fromOffset(sc(190),sc(18)),BackgroundColor3=T.Bg,
        BackgroundTransparency=0.15,BorderSizePixel=0,Parent=wmGui})
    Corner(sc(2),wmF)
    New("UIStroke",{Color=T.Border,Transparency=0,Thickness=1,
        ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Parent=wmF})
    local wmL=New("TextLabel",{BackgroundTransparency=1,Font=Enum.Font.RobotoMono,
        TextSize=sc(10),TextColor3=T.Accent,TextXAlignment=Enum.TextXAlignment.Center,
        Size=UDim2.fromScale(1,1),Parent=wmF})
    local _start=os.clock();local _frames=0;local _sample=_start
    track(RunService.RenderStepped:Connect(function() _frames+=1 end))
    local _wTick=0
    track(RunService.Heartbeat:Connect(function(dt)
        _wTick+=dt;if _wTick<0.5 then return end;_wTick=0
        local now=os.clock()
        local e=math.floor(now-_start)
        local fps=math.floor(_frames/math.max(now-_sample,0.001)+0.5)
        _frames=0;_sample=now
        wmL.Text=string.format("PROJECT APEX  |  %d:%02d  |  %dfps",math.floor(e/60),e%60,fps)
    end))
end

-- ══════════════════════════════════════════════════════════
-- NO LEAVES + NO GRASS
-- ══════════════════════════════════════════════════════════
do
    local _hiddenLeaves={} -- {obj, originalParent}
    local _noTreesConn=nil
    local _prevNoTrees=false

    local function hideLeaves(obj)
        local leaves=obj:FindFirstChild("Leaves")
        if leaves and leaves.Parent then
            _hiddenLeaves[#_hiddenLeaves+1]={leaves,leaves.Parent}
            leaves.Parent=nil
        end
    end
    local function applyNoTrees(on)
        if on then
            local sh=workspace:FindFirstChild("SpawnedHarvestables")
            if sh then
                for _,v in ipairs(sh:GetChildren()) do
                    local leaves=v:FindFirstChild("Leaves")
                    if leaves then hideLeaves(v) end
                end
                if not _noTreesConn then
                    _noTreesConn=sh.ChildAdded:Connect(function(v)
                        if not Flags.w_notrees then return end
                        task.defer(function()
                            local leaves=v:FindFirstChild("Leaves")
                            if leaves then hideLeaves(v) end
                        end)
                    end)
                end
            end
        else
            if _noTreesConn then _noTreesConn:Disconnect();_noTreesConn=nil end
            for _,entry in ipairs(_hiddenLeaves) do
                pcall(function() entry[1].Parent=entry[2] end)
            end
            table.clear(_hiddenLeaves)
        end
    end

    local _ntTick=0
    track(RunService.Heartbeat:Connect(function(dt)
        _ntTick+=dt;if _ntTick<0.5 then return end;_ntTick=0
        local cur=Flags.w_notrees==true
        if cur~=_prevNoTrees then _prevNoTrees=cur;applyNoTrees(cur) end
    end))

    -- No Grass: runs every frame so terrain can't re-enable it
    track(RunService.Heartbeat:Connect(function()
        if not Flags.w_nograss then return end
        local terrain=workspace:FindFirstChildOfClass("Terrain")
        if terrain then terrain.Decoration=false end
    end))

    -- Restore grass when toggled off
    local _prevGrass=false
    track(RunService.Heartbeat:Connect(function()
        local cur=Flags.w_nograss==true
        if _prevGrass and not cur then
            local terrain=workspace:FindFirstChildOfClass("Terrain")
            if terrain then terrain.Decoration=true end
        end
        _prevGrass=cur
    end))
end

-- ══════════════════════════════════════════════════════════
-- FREE CAM  (mobile two-finger touch: left=move, right=look)
-- Character is frozen in place while active
-- ══════════════════════════════════════════════════════════
do
    local _prevFC=false
    local _fcCamCF=nil
    local _fcYaw,_fcPitch=0,0
    local _bv,_bg=nil,nil

    -- touch state: left half = move joystick, right half = look drag
    local _moveStart=nil   -- Vector2 touch origin for move
    local _moveCur=nil     -- Vector2 current touch pos for move
    local _lookPrev=nil    -- Vector2 previous look touch pos
    local _moveTouchId=nil
    local _lookTouchId=nil

    local function freezeChar(on)
        local char=LocalPlayer.Character;if not char then return end
        local root=char:FindFirstChild("HumanoidRootPart")
        local hum=char:FindFirstChildOfClass("Humanoid")
        if not root then return end
        if on then
            if hum then hum.PlatformStand=true end
            if not _bv then
                _bv=Instance.new("BodyVelocity")
                _bv.Velocity=Vector3.zero;_bv.MaxForce=Vector3.new(1e5,1e5,1e5)
                _bv.P=1e4;_bv.Parent=root
            end
            if not _bg then
                _bg=Instance.new("BodyGyro")
                _bg.CFrame=root.CFrame;_bg.MaxTorque=Vector3.new(1e5,1e5,1e5)
                _bg.P=1e4;_bg.Parent=root
            end
        else
            if hum then hum.PlatformStand=false end
            if _bv then _bv:Destroy();_bv=nil end
            if _bg then _bg:Destroy();_bg=nil end
        end
    end

    track(UserInputService.TouchStarted:Connect(function(touch)
        if not Flags.m_freecam then return end
        local vps=workspace.CurrentCamera.ViewportSize
        local pos=Vector2.new(touch.Position.X,touch.Position.Y)
        if pos.X < vps.X*0.5 then
            -- left half: move joystick
            _moveTouchId=touch
            _moveStart=pos;_moveCur=pos
        else
            -- right half: look drag
            _lookTouchId=touch
            _lookPrev=pos
        end
    end))

    track(UserInputService.TouchMoved:Connect(function(touch)
        if not Flags.m_freecam then return end
        local pos=Vector2.new(touch.Position.X,touch.Position.Y)
        if touch==_moveTouchId then
            _moveCur=pos
        elseif touch==_lookTouchId then
            if _lookPrev then
                local delta=pos-_lookPrev
                local sens=0.006
                _fcYaw=_fcYaw-delta.X*sens
                _fcPitch=math.clamp(_fcPitch-delta.Y*sens,-math.pi*0.49,math.pi*0.49)
            end
            _lookPrev=pos
        end
    end))

    track(UserInputService.TouchEnded:Connect(function(touch)
        if touch==_moveTouchId then _moveTouchId=nil;_moveStart=nil;_moveCur=nil end
        if touch==_lookTouchId then _lookTouchId=nil;_lookPrev=nil end
    end))

    track(RunService.RenderStepped:Connect(function(dt)
        local cur=Flags.m_freecam==true
        if cur~=_prevFC then
            _prevFC=cur
            local cam=workspace.CurrentCamera
            if cur then
                _fcCamCF=cam.CFrame
                local lookVec=_fcCamCF.LookVector
                _fcYaw=math.atan2(-lookVec.X,-lookVec.Z)
                _fcPitch=math.asin(math.clamp(lookVec.Y,-1,1))
                cam.CameraType=Enum.CameraType.Scriptable
                freezeChar(true)
            else
                cam.CameraType=Enum.CameraType.Custom
                cam.CameraSubject=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                freezeChar(false)
                _moveStart=nil;_moveCur=nil;_lookPrev=nil
                _moveTouchId=nil;_lookTouchId=nil
            end
        end
        if not cur then return end
        local cam=workspace.CurrentCamera
        local rot=CFrame.Angles(0,_fcYaw,0)*CFrame.Angles(_fcPitch,0,0)
        -- movement from left-half drag offset
        local move=Vector3.zero
        if _moveStart and _moveCur then
            local d=_moveCur-_moveStart
            local deadzone=10
            local mx=math.abs(d.X)>deadzone and d.X/100 or 0
            local my=math.abs(d.Y)>deadzone and d.Y/100 or 0
            move=Vector3.new(math.clamp(mx,-1,1),0,math.clamp(my,-1,1))
        end
        local spd=(Flags.m_freecam_speed or 40)*dt
        local fwd=rot.LookVector;local right=rot.RightVector
        local newPos=_fcCamCF.Position+fwd*(-move.Z*spd)+right*(move.X*spd)
        _fcCamCF=CFrame.new(newPos)*rot
        cam.CFrame=_fcCamCF
    end))
end

print("[Project Apex Mobile] Ready.")
