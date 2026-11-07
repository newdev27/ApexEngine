
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
    FontAwesome = "https://raw.githubusercontent.com/B5RLAS/Neverlose/main/Font/FontAwesome.ttf",
    Museo500    = "https://raw.githubusercontent.com/B5RLAS/Neverlose/main/Font/Museo500.ttf",
    Museo900    = "https://raw.githubusercontent.com/B5RLAS/Neverlose/main/Font/Museo900.ttf",
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
local RunService       = game:GetService("RunService")
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

local ApexEngine = { Flags = {}, Icons = Icons, Theme = Theme, ToggleKey = Enum.KeyCode.Insert }
ApexEngine.__index = ApexEngine

function ApexEngine:CreateWindow(cfg)
    cfg = cfg or {}
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

    local sidebar = Panel(0, 0, 170, 500, 0, 0, 10, 0, 0.1)
    local topbar = Panel(170, 0, 520, 60, -10, 0, 10, 10, 0.05)
    New("Frame", { Size = UDim2.fromOffset(520, 1), Position = UDim2.fromOffset(170, 60), BackgroundColor3 = Theme.WindowBg, BackgroundTransparency = 0.1, BorderSizePixel = 0, Parent = main })
    local contentBg = Panel(170, 61, 520, 439, -10, -10, 10, 10, 0)

    local title = cfg.Title or "APEX ENGINE"
    Label({ Text = title, Font = Theme.FontBold, TextSize = 26, TextColor3 = Theme.Accent,
        TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.fromOffset(170, 30), Position = UDim2.fromOffset(15, 17), Parent = main })
    Label({ Text = title, Font = Theme.FontBold, TextSize = 26, TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.fromOffset(170, 30), Position = UDim2.fromOffset(14, 17), Parent = main })

    New("Frame", { Size = UDim2.fromOffset(170, 1), Position = UDim2.fromOffset(0, 450),
        BackgroundColor3 = Theme.WindowBg, BackgroundTransparency = 0.5, BorderSizePixel = 0, Parent = main })
    local av = New("ImageLabel", {
        Size = UDim2.fromOffset(30, 30), Position = UDim2.fromOffset(15, 460),
        BackgroundColor3 = Theme.FrameActive, Image = cfg.Avatar or Icons.avatar, Parent = main,
    }, { Corner(100) })
    if (cfg.Avatar or Icons.avatar) == "rbxassetid://0" then
        pcall(function()
            av.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
        end)
    end
    Label({ Text = cfg.User or LocalPlayer.Name, Size = UDim2.fromOffset(115, 14), Position = UDim2.fromOffset(50, 460), Parent = main })
    local till = Label({ Text = "Till:", TextColor3 = Theme.TextDisabled, Size = UDim2.fromOffset(25, 14), Position = UDim2.fromOffset(50, 475), Parent = main })
    till.Size = UDim2.fromOffset(till.TextBounds.X + 4, 14)
    Label({ Text = cfg.Till or "Lifetime", TextColor3 = Theme.Accent, Size = UDim2.fromOffset(90, 14),
        Position = UDim2.fromOffset(50 + 26, 475), Parent = main })

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

            function Sub:AddGroup(gname, gicon, side, height)
                local col = (side == "Right") and Sub.Right or Sub.Left
                local G = {}
                local holder = New("Frame", {
                    Size = UDim2.fromOffset(241, height or 404), BackgroundTransparency = 1,
                    LayoutOrder = #col:GetChildren(), Parent = col,
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
                    UserInputService.InputEnded:Connect(function(i)
                        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then sliding = false end
                    end)
                    UserInputService.InputChanged:Connect(function(i)
                        if sliding and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then update(i.Position.X) end
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
                    local arrow = Label({ Text = "▼", TextSize = 9, TextXAlignment = Enum.TextXAlignment.Center,
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
                        popup.Position = UDim2.fromOffset(ap.X, ap.Y + 22 + (gui.IgnoreGuiInset and 0 or 0))
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
                    UserInputService.InputChanged:Connect(function(i)
                        if mode and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then drag(i.Position) end
                    end)
                    UserInputService.InputEnded:Connect(function(i)
                        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then mode = nil end
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

    return Window
end

local Window = ApexEngine:CreateWindow({
    Title = "APEX ENGINE",
    User  = "Barlas",
    Till  = "Lifetime",
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
l1:AddSlider({ Name = "Strength", Min = 0, Max = 100, Default = 25, Suffix = "%", Flag = "lg_strength" })
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

local SGen = Scripts:AddSubtab("Configs")
local s1 = SGen:AddGroup("Configs", Icons.save, "Left")
s1:AddDropdown({ Name = "Config", Items = { "default", "legit", "rage", "custom" }, Flag = "cfg_sel" })
s1:AddTextbox({ Name = "New config", Flag = "cfg_name" })
s1:AddButton({ Name = "Create", Callback = function() print("config created") end })
s1:AddButton({ Name = "Load", Callback = function() print("config loaded") end })
s1:AddButton({ Name = "Delete", Callback = function() print("config deleted") end })
local s2 = SGen:AddGroup("Lua", Icons.code, "Right")
s2:AddCheckbox({ Name = "Allow scripts", Flag = "lua_allow" })
s2:AddCheckbox({ Name = "Auto load", Flag = "lua_autoload" })
s2:AddButton({ Name = "Reload scripts", Callback = function() print("scripts reloaded") end })

return ApexEngine
