--[[
    Apex Engine Mobile — Brisk Survival
    Mobile UI: draggable panel + dedicated Aimbot button + Open/Close button
]]

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

local T = {
    Bg     = Color3.fromRGB(8,8,12),
    Panel  = Color3.fromRGB(14,14,20),
    Accent = Color3.fromRGB(76,125,255),
    Text   = Color3.new(1,1,1),
    Dim    = Color3.fromRGB(130,132,143),
    On     = Color3.fromRGB(76,125,255),
    Off    = Color3.fromRGB(40,40,55),
    Red    = Color3.fromRGB(255,70,70),
    Green  = Color3.fromRGB(60,220,110),
    ABOn   = Color3.fromRGB(255,80,80),   -- aimbot button active colour
    ABOff  = Color3.fromRGB(40,20,20),
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

-- ── Flags ─────────────────────────────────────────────────
local Flags = {
    sa_enabled=true, sa_part="Head", sa_fov=120, sa_hitchance=100,
    no_recoil=true, no_spread=true, no_bullet_drop=false, instant_reload=false,
    ab_enabled=false,  -- toggled by the dedicated Aimbot button
    ab_part="Head", ab_fov=120, ab_smooth=8, ab_predict=true,
    esp_enabled=true, esp_box=true, esp_box_col=Color3.new(1,1,1),
    esp_name=true, esp_name_col=Color3.new(1,1,1),
    esp_health=true, esp_health_col=Color3.fromRGB(80,255,120),
    esp_dist=true, esp_maxdist=1500, esp_textsize=11,
    esp_chams=false, esp_fill_col=Color3.fromRGB(255,60,90),
    esp_fill_opacity=50, esp_outline_col=Color3.new(1,1,1),
    esp_tracer=false, esp_tracer_col=Color3.fromRGB(0,180,255),
    wesp_harv=false, wesp_ore=false, wesp_sleepers=false,
    wesp_c4=true, wesp_c4_alert=true, wesp_rockets=true,
    wesp_maxdist=1000, wesp_turrets=false, wesp_storage=false,
    wesp_beds=false, wesp_barricades=false, wesp_other=false,
    w_fullbright=false, w_nofog=false, w_noshadows=false,
    w_notrees=false, w_nograss=false,
    m_omnisprint=false, m_omnisprint_bonus=0,
    m_noclip=false, m_xray=false, m_xray_col=Color3.fromRGB(255,80,200),
    crosshair_enabled=true, crosshair_col=Color3.new(1,1,1),
    crosshair_gap=4, crosshair_size=8, crosshair_thick=1,
    _fire_held=false,
    tc_enabled=true,
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
        Size=UDim2.fromScale(0.88,0.40),BackgroundColor3=T.Bg,BorderSizePixel=0,Parent=kg})
    Corner(14,win)
    New("TextLabel",{Text="APEX ENGINE — KEY",BackgroundTransparency=1,
        Font=Enum.Font.GothamBlack,TextSize=sc(16),TextColor3=T.Accent,
        Size=UDim2.new(1,-20,0,sc(22)),Position=UDim2.fromOffset(10,10),Parent=win})
    local box=New("TextBox",{BackgroundColor3=T.Panel,BorderSizePixel=0,
        ClearTextOnFocus=false,Font=Enum.Font.Gotham,TextSize=sc(12),
        PlaceholderText="APEX-XXXXXX-XXXXXX-XX",PlaceholderColor3=T.Dim,
        Text="",TextColor3=T.Text,Size=UDim2.new(1,-20,0,sc(36)),
        Position=UDim2.fromOffset(10,sc(40)),Parent=win})
    Corner(8,box)
    New("UIPadding",{PaddingLeft=UDim.new(0,8),Parent=box})
    local st=New("TextLabel",{BackgroundTransparency=1,Font=Enum.Font.Gotham,
        TextSize=sc(11),TextColor3=T.Dim,Text="Enter your key and tap Submit.",
        Size=UDim2.new(1,-20,0,sc(16)),Position=UDim2.fromOffset(10,sc(84)),Parent=win})
    local sb=New("TextButton",{BackgroundColor3=T.Accent,AutoButtonColor=false,
        Text="Submit",Font=Enum.Font.GothamBold,TextSize=sc(13),
        TextColor3=Color3.fromRGB(8,8,8),Size=UDim2.new(0.48,-5,0,sc(36)),
        Position=UDim2.fromOffset(10,sc(108)),Parent=win})
    Corner(8,sb)
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
    Text="👁",
    AnchorPoint=Vector2.new(0,0.5),
    Position=UDim2.new(0,sc(76),0.5,0),
    Size=UDim2.fromOffset(sc(48),sc(48)),
    BackgroundColor3=T.On,
    AutoButtonColor=false,
    Font=Enum.Font.GothamBlack,
    TextSize=sc(20),
    TextColor3=Color3.new(1,1,1),
    ZIndex=20,
    Parent=rootGui,
})
Corner(sc(24),espBtn)
espBtn.Activated:Connect(function()
    Flags.esp_enabled=not Flags.esp_enabled
    Tween(espBtn,0.15,{BackgroundColor3=Flags.esp_enabled and T.On or T.Off})
end)

-- ══════════════════════════════════════════════════════════
-- OPEN / CLOSE BUTTON  (always visible, bottom-left)
-- Tap it to show/hide the settings panel
-- ══════════════════════════════════════════════════════════
local openBtn=New("TextButton",{
    Text="⚡",
    AnchorPoint=Vector2.new(0,1),
    Position=UDim2.new(0,sc(10),1,-sc(10)),
    Size=UDim2.fromOffset(sc(48),sc(48)),
    BackgroundColor3=T.Accent,
    AutoButtonColor=false,
    Font=Enum.Font.GothamBlack,
    TextSize=sc(22),
    TextColor3=Color3.new(1,1,1),
    ZIndex=20,
    Parent=rootGui,
})
Corner(sc(24),openBtn)

-- ══════════════════════════════════════════════════════════
-- AIMBOT BUTTON  (always visible, bottom-right)
-- Hold = aimbot active while held; tap = toggle lock-on
-- ══════════════════════════════════════════════════════════
local abBtn=New("TextButton",{
    Text="🎯",
    AnchorPoint=Vector2.new(0,0.5),
    Position=UDim2.new(0,sc(10),0.5,0),
    Size=UDim2.fromOffset(sc(56),sc(56)),
    BackgroundColor3=T.ABOff,
    AutoButtonColor=false,
    Font=Enum.Font.GothamBlack,
    TextSize=sc(24),
    TextColor3=Color3.new(1,1,1),
    ZIndex=20,
    Parent=rootGui,
})
Corner(sc(28),abBtn)

-- Aimbot button: hold = fire_held, tap = toggle ab_enabled
local _abHoldStart=0
abBtn.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
        _abHoldStart=os.clock()
        Flags._fire_held=true
        Tween(abBtn,0.1,{BackgroundColor3=T.ABOn,Size=UDim2.fromOffset(sc(52),sc(52))})
    end
end)
abBtn.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
        Flags._fire_held=false
        if os.clock()-_abHoldStart < 0.3 then
            Flags.ab_enabled = not Flags.ab_enabled
        end
        local col = Flags.ab_enabled and T.ABOn or T.ABOff
        Tween(abBtn,0.15,{BackgroundColor3=col,Size=UDim2.fromOffset(sc(56),sc(56))})
    end
end)

-- ══════════════════════════════════════════════════════════
-- SETTINGS PANEL  (draggable, shown/hidden by openBtn)
-- ══════════════════════════════════════════════════════════
local PANEL_SIZE = UDim2.fromScale(0.54, 0.62)
local panel=New("Frame",{
    AnchorPoint=Vector2.new(0,0),
    Position=UDim2.fromScale(0.01,0.06),
    Size=PANEL_SIZE,
    BackgroundColor3=T.Bg,
    BackgroundTransparency=0.06,
    BorderSizePixel=0,
    ClipsDescendants=true,
    ZIndex=10,
    Visible=true,
    Parent=rootGui,
})
Corner(12,panel)

-- open/close toggle
local panelOpen=true
openBtn.Activated:Connect(function()
    panelOpen=not panelOpen
    panel.Visible=panelOpen
    Tween(openBtn,0.15,{BackgroundColor3=panelOpen and T.Accent or T.Panel})
end)

-- top bar (drag handle)
local topBar=New("Frame",{Size=UDim2.new(1,0,0,sc(32)),
    BackgroundColor3=T.Panel,BorderSizePixel=0,ZIndex=11,Parent=panel})
Corner(12,topBar)
New("TextLabel",{Text="⚡ APEX MOBILE",BackgroundTransparency=1,
    Font=Enum.Font.GothamBlack,TextSize=sc(13),TextColor3=T.Accent,
    Size=UDim2.new(1,-sc(10),1,0),Position=UDim2.fromOffset(sc(8),0),
    ZIndex=12,Parent=topBar})

-- drag logic
do
    local dragging,dragStart,panStart
    topBar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true;dragStart=i.Position;panStart=panel.Position
            i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dragging=false end end)
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

-- tab bar
local TAB_NAMES={"Visual","World","Player"}
local tabBar=New("Frame",{Size=UDim2.new(1,0,0,sc(28)),Position=UDim2.fromOffset(0,sc(32)),
    BackgroundColor3=T.Panel,BorderSizePixel=0,ZIndex=11,Parent=panel})
New("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,SortOrder=Enum.SortOrder.LayoutOrder,Parent=tabBar})

-- scrollable content
local content=New("ScrollingFrame",{
    Size=UDim2.new(1,0,1,-sc(60)),Position=UDim2.fromOffset(0,sc(60)),
    BackgroundTransparency=1,BorderSizePixel=0,
    ScrollBarThickness=2,ScrollBarImageColor3=T.Accent,
    CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,
    ZIndex=11,Parent=panel,
})
New("UIListLayout",{Padding=UDim.new(0,sc(5)),SortOrder=Enum.SortOrder.LayoutOrder,Parent=content})
New("UIPadding",{PaddingTop=UDim.new(0,sc(6)),PaddingLeft=UDim.new(0,sc(8)),PaddingRight=UDim.new(0,sc(8)),Parent=content})

-- ── widget helpers ────────────────────────────────────────
local wOrder=0
local function nO() wOrder+=1; return wOrder end
local tabPages={}
local recTab=nil

local function makeRow()
    local r=New("Frame",{Size=UDim2.new(1,0,0,sc(28)),BackgroundTransparency=1,
        LayoutOrder=nO(),ZIndex=12,Parent=content})
    if recTab then tabPages[recTab][#tabPages[recTab]+1]=r end
    return r
end

local function makeSep(title)
    local r=New("Frame",{Size=UDim2.new(1,0,0,sc(18)),BackgroundTransparency=1,
        LayoutOrder=nO(),ZIndex=12,Parent=content})
    New("TextLabel",{Text=title or "",BackgroundTransparency=1,Font=Enum.Font.GothamBold,
        TextSize=sc(10),TextColor3=T.Dim,Size=UDim2.fromScale(1,1),ZIndex=13,Parent=r})
    New("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),
        BackgroundColor3=T.Dim,BackgroundTransparency=0.7,BorderSizePixel=0,Parent=r})
    if recTab then tabPages[recTab][#tabPages[recTab]+1]=r end
end

local function makeToggle(label,flagKey,defOverride)
    local state=defOverride~=nil and defOverride or (Flags[flagKey]==true)
    local row=makeRow()
    local lbl=New("TextLabel",{Text=label,BackgroundTransparency=1,Font=Enum.Font.Gotham,
        TextSize=sc(12),TextColor3=state and T.Text or T.Dim,
        Size=UDim2.new(1,-sc(44),1,0),ZIndex=13,Parent=row})
    local sw=New("TextButton",{Size=UDim2.fromOffset(sc(36),sc(20)),
        Position=UDim2.new(1,-sc(36),0.5,-sc(10)),
        BackgroundColor3=state and T.On or T.Off,AutoButtonColor=false,Text="",ZIndex=13,Parent=row})
    Corner(10,sw)
    local knob=New("Frame",{Size=UDim2.fromOffset(sc(16),sc(16)),
        AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.new(0,state and sc(26) or sc(10),0.5,0),
        BackgroundColor3=state and T.Accent or T.Dim,ZIndex=14,Parent=sw})
    Corner(8,knob)
    local function set(v)
        state=v; Flags[flagKey]=v
        Tween(sw,0.15,{BackgroundColor3=v and T.On or T.Off})
        Tween(knob,0.15,{Position=UDim2.new(0,v and sc(26) or sc(10),0.5,0),
            BackgroundColor3=v and T.Accent or T.Dim})
        lbl.TextColor3=v and T.Text or T.Dim
    end
    sw.Activated:Connect(function() set(not state) end)
    Flags[flagKey]=state
    return {Set=set,Get=function() return state end}
end

local function showTab(name)
    for tname,rows in pairs(tabPages) do
        local vis=tname==name
        for _,r in ipairs(rows) do r.Visible=vis end
    end
end

local tabBtns={}
for i,name in ipairs(TAB_NAMES) do
    tabPages[name]={}
    local btn=New("TextButton",{Text=name,BackgroundColor3=T.Panel,
        BackgroundTransparency=0.5,AutoButtonColor=false,
        Font=Enum.Font.GothamBold,TextSize=sc(11),TextColor3=T.Dim,
        Size=UDim2.new(1/#TAB_NAMES,0,1,0),LayoutOrder=i,ZIndex=12,Parent=tabBar})
    tabBtns[name]=btn
    btn.Activated:Connect(function()
        showTab(name)
        for n,b in pairs(tabBtns) do
            Tween(b,0.12,{BackgroundTransparency=n==name and 0 or 0.5})
            b.TextColor3=n==name and T.Accent or T.Dim
        end
    end)
end

-- ── VISUAL TAB ────────────────────────────────────────────
recTab="Visual"
makeSep("── Player ESP ──")
makeToggle("ESP Enabled",       "esp_enabled")
makeToggle("Box",               "esp_box")
makeToggle("Name",              "esp_name")
makeToggle("Health Bar",        "esp_health")
makeToggle("Distance",          "esp_dist")
makeToggle("Tracers",           "esp_tracer")
makeToggle("Highlight (Chams)", "esp_chams")
do
    -- ESP Max Distance slider: 100–2000m
    Flags.esp_maxdist = Flags.esp_maxdist or 1500
    local row=makeRow()
    New("TextLabel",{Text="ESP Distance",BackgroundTransparency=1,Font=Enum.Font.Gotham,
        TextSize=sc(12),TextColor3=T.Dim,Size=UDim2.new(0.45,0,1,0),ZIndex=13,Parent=row})
    local bar=New("TextButton",{Size=UDim2.fromOffset(sc(90),sc(6)),
        Position=UDim2.new(0.45,0,0.5,-sc(3)),
        BackgroundColor3=T.Off,AutoButtonColor=false,Text="",ZIndex=13,Parent=row})
    Corner(4,bar)
    local fill=New("Frame",{Size=UDim2.new(0,0,1,0),BackgroundColor3=T.Accent,
        BorderSizePixel=0,ZIndex=14,Parent=bar})
    Corner(4,fill)
    local grab=New("Frame",{Size=UDim2.fromOffset(sc(14),sc(14)),
        AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0,0,0.5,0),
        BackgroundColor3=T.Accent,ZIndex=15,Parent=bar})
    Corner(sc(7),grab)
    local valLbl=New("TextLabel",{BackgroundTransparency=1,Font=Enum.Font.GothamBold,
        TextSize=sc(11),TextColor3=T.Text,TextXAlignment=Enum.TextXAlignment.Right,
        Size=UDim2.new(0.18,0,1,0),Position=UDim2.new(0.82,0,0,0),ZIndex=13,Parent=row})
    local MIN,MAX=100,2000
    local function setDist(v)
        v=math.clamp(math.floor(v/50+0.5)*50,MIN,MAX)
        Flags.esp_maxdist=v
        local p=(v-MIN)/(MAX-MIN)
        fill.Size=UDim2.new(p,0,1,0)
        grab.Position=UDim2.new(p,0,0.5,0)
        valLbl.Text=tostring(v).."m"
    end
    setDist(Flags.esp_maxdist)
    local sliding=false
    bar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
            sliding=true
            local p=math.clamp((i.Position.X-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)
            setDist(MIN+(MAX-MIN)*p)
        end
    end)
    track(UserInputService.InputChanged:Connect(function(i)
        if not sliding then return end
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMovement then
            local p=math.clamp((i.Position.X-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)
            setDist(MIN+(MAX-MIN)*p)
        end
    end))
    track(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
            sliding=false
        end
    end))
end
makeSep("── Crosshair ──")
makeToggle("Crosshair",         "crosshair_enabled")
makeSep("── Team Check ──")
makeToggle("Team Check",        "tc_enabled")
makeSep("── Combat Visuals ──")
makeToggle("X-Ray",             "m_xray")

-- ── WORLD TAB ─────────────────────────────────────────────
recTab="World"
makeSep("── World ESP ──")
makeToggle("Harvestables",  "wesp_harv")
makeToggle("Ore / Stone",   "wesp_ore")
makeToggle("Sleepers",      "wesp_sleepers")
makeToggle("Placed C4",     "wesp_c4")
makeToggle("C4 Alert",      "wesp_c4_alert")
makeToggle("Rockets",       "wesp_rockets")
makeToggle("Turrets",       "wesp_turrets")
makeToggle("Storage",       "wesp_storage")
makeToggle("Sleeping Bags", "wesp_beds")
makeSep("── Lighting ──")
makeToggle("Full Bright",   "w_fullbright")
makeToggle("No Fog",        "w_nofog")
makeToggle("No Shadows",    "w_noshadows")
makeSep("── Environment ──")
makeToggle("No Leaves",     "w_notrees")
makeToggle("No Grass",      "w_nograss")

-- ── PLAYER TAB ────────────────────────────────────────────
recTab="Player"
makeSep("── Movement ──")
makeToggle("Omni Sprint (Crouch)", "m_omnisprint")
do
    -- Speed slider: 16–100, default 24
    Flags.m_omnisprint_bonus = 8  -- default bonus on top of base 16 = 24 total
    local row=makeRow()
    New("TextLabel",{Text="Sprint Speed",BackgroundTransparency=1,Font=Enum.Font.Gotham,
        TextSize=sc(12),TextColor3=T.Dim,Size=UDim2.new(0.45,0,1,0),ZIndex=13,Parent=row})
    local bar=New("TextButton",{Size=UDim2.fromOffset(sc(90),sc(6)),
        Position=UDim2.new(0.45,0,0.5,-sc(3)),
        BackgroundColor3=T.Off,AutoButtonColor=false,Text="",ZIndex=13,Parent=row})
    Corner(4,bar)
    local fill=New("Frame",{Size=UDim2.new(0,0,1,0),BackgroundColor3=T.Accent,
        BorderSizePixel=0,ZIndex=14,Parent=bar})
    Corner(4,fill)
    local grab=New("Frame",{Size=UDim2.fromOffset(sc(14),sc(14)),
        AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0,0,0.5,0),
        BackgroundColor3=T.Accent,ZIndex=15,Parent=bar})
    Corner(sc(7),grab)
    local valLbl=New("TextLabel",{BackgroundTransparency=1,Font=Enum.Font.GothamBold,
        TextSize=sc(11),TextColor3=T.Text,TextXAlignment=Enum.TextXAlignment.Right,
        Size=UDim2.new(0.18,0,1,0),Position=UDim2.new(0.82,0,0,0),ZIndex=13,Parent=row})
    local MIN,MAX=16,100
    local function setSpeed(v)
        v=math.clamp(math.floor(v+0.5),MIN,MAX)
        Flags.m_omnisprint_bonus=v-16
        local p=(v-MIN)/(MAX-MIN)
        fill.Size=UDim2.new(p,0,1,0)
        grab.Position=UDim2.new(p,0,0.5,0)
        valLbl.Text=tostring(v)
    end
    setSpeed(24)
    local sliding=false
    bar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
            sliding=true
            local p=math.clamp((i.Position.X-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)
            setSpeed(MIN+(MAX-MIN)*p)
        end
    end)
    track(UserInputService.InputChanged:Connect(function(i)
        if not sliding then return end
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMovement then
            local p=math.clamp((i.Position.X-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)
            setSpeed(MIN+(MAX-MIN)*p)
        end
    end))
    track(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
            sliding=false
        end
    end))
end
makeToggle("No Clip",              "m_noclip")
makeSep("── Combat ──")
makeToggle("Silent Aim",    "sa_enabled")
makeToggle("No Recoil",     "no_recoil")
makeToggle("No Spread",     "no_spread")
makeToggle("No Bullet Drop","no_bullet_drop")
makeToggle("Instant Reload","instant_reload")
makeToggle("Aimbot Lock",   "ab_enabled")

recTab=nil

-- default tab
showTab("Visual")
tabBtns["Visual"].TextColor3=T.Accent
Tween(tabBtns["Visual"],0,{BackgroundTransparency=0})

-- ══════════════════════════════════════════════════════════
-- MOBILE CONTROLS HOOK
-- Fire button → _fire_held (aimbot while held)
-- Crouch button → toggle OmniSprint
-- ══════════════════════════════════════════════════════════
task.spawn(function()
    local pg=LocalPlayer:WaitForChild("PlayerGui",30)
    if not pg then return end
    local function hookControls(gui)
        local function findBtn(root,name)
            for _,d in ipairs(root:GetDescendants()) do
                if (d:IsA("TextButton") or d:IsA("ImageButton") or d:IsA("Frame"))
                    and d.Name:lower()==name:lower() then return d end
            end
        end
        local fireBtn=findBtn(gui,"Fire")
        local crouchBtn=findBtn(gui,"Crouch")
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
                if i.UserInputType==Enum.UserInputType.Touch then
                    Flags.m_omnisprint=true
                end
            end)
            crouchBtn.InputEnded:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.Touch then
                    Flags.m_omnisprint=false
                end
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
        pg.ChildAdded:Connect(function(c) task.defer(function() hookControls(c) end) end)
    end
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

-- cache enemies list, refresh every frame for accurate positions
local _enemyCache={}
local _enemyCacheTick=0
local function getEnemies()
    local now=os.clock()
    if now == _enemyCacheTick then return _enemyCache end
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

local function screenDist(worldPos)
    local cam=workspace.CurrentCamera
    local sp,on=cam:WorldToViewportPoint(worldPos)
    if not on or sp.Z<=0 then return math.huge end
    local vps=cam.ViewportSize
    return math.sqrt((sp.X-vps.X*0.5)^2+(sp.Y-vps.Y*0.5)^2)
end

local function getClosest(partName,fovPx,maxWorldDist)
    local best,bestDist=nil,fovPx or math.huge
    local myRoot=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    for _,e in ipairs(getEnemies()) do
        local part=e.char:FindFirstChild(partName or "Head") or e.char:FindFirstChild("HumanoidRootPart")
        if part then
            if maxWorldDist and myRoot and (part.Position-myRoot.Position).Magnitude>maxWorldDist then continue end
            local d=screenDist(part.Position)
            if d<bestDist then bestDist=d;best=e end
        end
    end
    return best
end

-- ══════════════════════════════════════════════════════════
-- GUNFIRE HOOK  (Silent Aim + No Spread)
-- ══════════════════════════════════════════════════════════
local GunFire=nil
task.spawn(function()
    GunFire=game:GetService("ReplicatedStorage"):WaitForChild("GunFire",15)
end)

local _hooked=false
track(RunService.Heartbeat:Connect(function()
    if _hooked or not GunFire or not hookfunction then return end
    _hooked=true
    local orig=GunFire.FireServer
    hookfunction(orig,newcclosure(function(self,...)
        local args={...}
        local origin=typeof(args[1])=="Vector3" and args[1] or workspace.CurrentCamera.CFrame.Position

        if Flags.sa_enabled and math.random(100)<=(Flags.sa_hitchance or 100) then
            local target=getClosest(Flags.sa_part or "Head",Flags.sa_fov or 120,500)
            if target then
                local part=getR6Part(target.char,Flags.sa_part or "Head")
                if part and typeof(origin)=="Vector3" then
                    local vel=target.root.AssemblyLinearVelocity
                    local dist=(part.Position-origin).Magnitude
                    local ping=math.clamp((LocalPlayer:GetNetworkPing and LocalPlayer:GetNetworkPing() or 0.06),0,0.3)
                    local travelTime=dist/500+ping
                    local lateralVel=Vector3.new(vel.X,0,vel.Z)
                    local lateralSpeed=lateralVel.Magnitude
                    local extraLead=lateralSpeed>20 and (lateralSpeed/500) or 0
                    local aimPos=part.Position+vel*(travelTime+extraLead)
                    local dir=aimPos-origin
                    if Flags.no_bullet_drop then dir=Vector3.new(dir.X,0,dir.Z) end
                    if dir.Magnitude>0.01 then args[3]=dir.Unit end
                end
            end
        end

        if Flags.no_spread and typeof(args[3])=="Vector3" then
            args[3]=workspace.CurrentCamera.CFrame.LookVector
        end
        return orig(self,table.unpack(args))
    end))
end))

-- ── Instant Reload ──
local _reloadHookedM=false
track(RunService.Heartbeat:Connect(function()
    if _reloadHookedM or not hookfunction then return end
    local rs2=game:GetService("ReplicatedStorage")
    local rr=rs2:FindFirstChild("GunReload") or rs2:FindFirstChild("Reload") or rs2:FindFirstChild("ReloadGun")
    if not rr then return end
    _reloadHookedM=true
    local origR=rr.FireServer
    hookfunction(origR,newcclosure(function(self,...)
        if not Flags.instant_reload then return origR(self,...) end
        local res=origR(self,...)
        task.delay(0.05,function() pcall(origR,self,...) end)
        return res
    end))
end))
track(RunService.Heartbeat:Connect(function()
    if not Flags.instant_reload then return end
    local char=LocalPlayer.Character;if not char then return end
    for _,tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            RunService:UnbindFromRenderStep("Reload_"..tool.Name)
            RunService:UnbindFromRenderStep("GunReload_"..tool.Name)
        end
    end
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

-- ── Aimbot (RenderStepped, only when fire held OR ab_enabled toggle) ──
track(RunService.RenderStepped:Connect(function()
    if not Flags.ab_enabled and not Flags._fire_held then return end
    local partName=Flags.ab_part or "Head"
    local target=getClosest(partName,Flags.ab_fov or 120,500)
    if not target then return end
    local part=getR6Part(target.char,partName)
    if not part then return end
    local targetPos=part.Position
    if Flags.ab_predict then
        local vel=target.root.AssemblyLinearVelocity
        local dist=(targetPos-workspace.CurrentCamera.CFrame.Position).Magnitude
        local ping=math.clamp((LocalPlayer:GetNetworkPing and LocalPlayer:GetNetworkPing() or 0.06),0,0.3)
        local travelTime=dist/500+ping
        local lateralVel=Vector3.new(vel.X,0,vel.Z)
        local lateralSpeed=lateralVel.Magnitude
        local extraLead=lateralSpeed>20 and (lateralSpeed/500) or 0
        targetPos=targetPos+vel*(travelTime+extraLead)
    end
    local cam=workspace.CurrentCamera
    local _,onScreen=cam:WorldToViewportPoint(targetPos)
    if not onScreen then return end
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

            if Flags.esp_tracer then
                local origin=Flags.esp_tracer_origin or "Bottom"
                local ox,oy
                if origin=="Center" then ox,oy=vps.X*0.5,vps.Y*0.5
                elseif origin=="Mouse" then
                    local mp=UserInputService:GetMouseLocation();ox,oy=mp.X,mp.Y
                else ox,oy=vps.X*0.5,vps.Y end
                local tx=(x1+x2)*0.5;local ty=(y1+y2)*0.5  -- aim at torso center
                local dx,dy=tx-ox,ty-oy
                local len=math.sqrt(dx*dx+dy*dy)
                if len>=2 then
                    d.tr.Position=UDim2.fromOffset(ox,oy)
                    d.tr.Size=UDim2.fromOffset(len,1)
                    d.tr.Rotation=math.deg(math.atan2(dy,dx))
                    d.tr.BackgroundColor3=Flags.esp_tracer_col or Color3.fromRGB(0,180,255)
                    d.tr.BackgroundTransparency=0
                    d.tr.Visible=true
                else d.tr.Visible=false end
            else d.tr.Visible=false end

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
        if not Flags.m_omnisprint then
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
-- X-RAY  (throttled 0.3s)
-- ══════════════════════════════════════════════════════════
do
    local _xray={}
    local _xTick=0
    track(RunService.Heartbeat:Connect(function(dt)
        _xTick+=dt;if _xTick<0.3 then return end;_xTick=0
        local col=Flags.m_xray_col or Color3.fromRGB(255,80,200)
        for _,p in ipairs(Players:GetPlayers()) do
            if p==LocalPlayer then continue end
            if not _xray[p] then
                _xray[p]=New("Highlight",{DepthMode=Enum.HighlightDepthMode.AlwaysOnTop,
                    FillTransparency=0.5,OutlineTransparency=0,Enabled=false,Parent=GetGui()})
            end
            local hl=_xray[p]
            if Flags.m_xray and p.Character then
                hl.Adornee=p.Character;hl.FillColor=col;hl.OutlineColor=col;hl.Enabled=true
            else hl.Enabled=false end
        end
        for p in pairs(_xray) do
            if not p.Parent then pcall(function() _xray[p]:Destroy() end);_xray[p]=nil end
        end
    end))
    Players.PlayerRemoving:Connect(function(p)
        if _xray[p] then pcall(function() _xray[p]:Destroy() end);_xray[p]=nil end
    end)
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
        Size=UDim2.fromOffset(sc(180),sc(20)),BackgroundColor3=T.Bg,
        BackgroundTransparency=0.3,BorderSizePixel=0,Parent=wmGui})
    Corner(4,wmF)
    local wmL=New("TextLabel",{BackgroundTransparency=1,Font=Enum.Font.GothamBold,
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
        wmL.Text=string.format("APEX  |  %d:%02d  |  %dfps",math.floor(e/60),e%60,fps)
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
                    local tf=v:GetAttribute("TemplateFolder")
                    if tf=="Trees" or tf=="PineTrees" then hideLeaves(v) end
                end
                if not _noTreesConn then
                    _noTreesConn=sh.ChildAdded:Connect(function(v)
                        if not Flags.w_notrees then return end
                        local tf=v:GetAttribute("TemplateFolder")
                        if tf=="Trees" or tf=="PineTrees" then
                            task.defer(function() hideLeaves(v) end)
                        end
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

print("[ApexEngine Mobile] Ready.")
