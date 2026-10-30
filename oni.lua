pcall(function()
    local LP = game:GetService("Players").LocalPlayer
    local UIS = game:GetService("UserInputService")
    local TS = game:GetService("TweenService")
    local runService = game:GetService("RunService")
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local HttpService = game:GetService("HttpService")
    
    local PG = LP:WaitForChild("PlayerGui")
    if PG:FindFirstChild("OniMacroHub") then PG.OniMacroHub:Destroy() end

    local Gui = Instance.new("ScreenGui")
    Gui.Name = "OniMacroHub"
    Gui.ResetOnSpawn = false
    Gui.Parent = PG

    -- Biến Dịch Chuyển (Waypoints)
    local waypoints = {}
    local wpCount = 0
    local useTween = true

    -- Biến Macro & Auto Click
    local isRecording = false
    local isPlaying = false
    local autoLoop = true
    local recordCameraMove = true
    local returnToStart = true
    local macroData = {}
    local savedMacros = {}
    local startTime = 0
    local playThread = nil

    -- Biến Vùng Giới Hạn Click (Click Zone)
    local zoneLocked = false
    local isZoneActive = true

    -- Các mức kích thước Menu chính
    local sizes = {
        {Size = UDim2.new(0, 260, 0, 420)}, -- Nhỏ
        {Size = UDim2.new(0, 310, 0, 470)}, -- Vừa
        {Size = UDim2.new(0, 360, 0, 520)}  -- Lớn
    }
    local sizeNames = {"Nhỏ", "Vừa", "Lớn"}
    local currentSizeIdx = 2

    -- Tọa độ lưu mặc định
    local savedMainPos = UDim2.new(0.5, -155, 0.5, -235)
    local savedZonePos = UDim2.new(0.5, -80, 0.4, -50)
    local savedTogglePos = UDim2.new(0.05, 0, 0.15, 0)

    -- --- HỆ THỐNG TỰ ĐỘNG LƯU & TẢI CÀI ĐẶT + VỊ TRÍ ---
    local settingFile = "OniMacro_Settings_v2.txt"
    local function saveSettings(mainFrame, zoneFrame, toggleBtn)
        local settingData = {
            Loop = autoLoop,
            Cam = recordCameraMove,
            Return = returnToStart,
            Zone = isZoneActive,
            SizeIdx = currentSizeIdx,
            MainXScale = mainFrame.Position.X.Scale, MainXOffset = mainFrame.Position.X.Offset,
            MainYScale = mainFrame.Position.Y.Scale, MainYOffset = mainFrame.Position.Y.Offset,
            ZoneXScale = zoneFrame.Position.X.Scale, ZoneXOffset = zoneFrame.Position.X.Offset,
            ZoneYScale = zoneFrame.Position.Y.Scale, ZoneYOffset = zoneFrame.Position.Y.Offset,
            TglXScale = toggleBtn.Position.X.Scale, TglXOffset = toggleBtn.Position.X.Offset,
            TglYScale = toggleBtn.Position.Y.Scale, TglYOffset = toggleBtn.Position.Y.Offset,
        }
        if writefile then
            pcall(function()
                writefile(settingFile, HttpService:JSONEncode(settingData))
            end)
        end
    end

    -- Khởi tạo nút logo trước
    local Tgl = Instance.new("TextButton")
    Tgl.Size = UDim2.new(0, 50, 0, 50)
    Tgl.Position = savedTogglePos
    Tgl.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Tgl.Text = "👹"
    Tgl.TextSize = 24
    Tgl.TextColor3 = Color3.fromRGB(255, 255, 255)
    Tgl.Parent = Gui

    local TglC = Instance.new("UICorner")
    TglC.CornerRadius = UDim.new(0, 25)
    TglC.Parent = Tgl

    local TglStroke = Instance.new("UIStroke")
    TglStroke.Color = Color3.fromRGB(231, 76, 60)
    TglStroke.Thickness = 2
    TglStroke.Parent = Tgl

    -- Khung Ô Vuông Click Zone
    local ClickZoneBox = Instance.new("Frame")
    ClickZoneBox.Size = UDim2.new(0, 160, 0, 100)
    ClickZoneBox.Position = savedZonePos
    ClickZoneBox.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    ClickZoneBox.BackgroundTransparency = 0.85
    ClickZoneBox.Visible = true
    ClickZoneBox.Parent = Gui

    local ZoneC = Instance.new("UICorner")
    ZoneC.CornerRadius = UDim.new(0, 8)
    ZoneC.Parent = ClickZoneBox

    local ZoneStroke = Instance.new("UIStroke")
    ZoneStroke.Color = Color3.fromRGB(46, 204, 113)
    ZoneStroke.Thickness = 2
    ZoneStroke.Parent = ClickZoneBox

    -- Khung Menu chính
    local Main = Instance.new("Frame")
    Main.Size = sizes[currentSizeIdx].Size
    Main.Position = savedMainPos
    Main.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    Main.Visible = false
    Main.ClipsDescendants = true
    Main.Parent = Gui

    -- Tải dữ liệu đã lưu từ trước
    if readfile and pcall(function() return readfile(settingFile) end) then
        local success, data = pcall(function() return HttpService:JSONDecode(readfile(settingFile)) end)
        if success and type(data) == "table" then
            if data.Loop ~= nil then autoLoop = data.Loop end
            if data.Cam ~= nil then recordCameraMove = data.Cam end
            if data.Return ~= nil then returnToStart = data.Return end
            if data.Zone ~= nil then isZoneActive = data.Zone end
            if data.SizeIdx ~= nil and sizes[data.SizeIdx] then currentSizeIdx = data.SizeIdx Main.Size = sizes[currentSizeIdx].Size end
            
            if data.MainXScale then Main.Position = UDim2.new(data.MainXScale, data.MainXOffset, data.MainYScale, data.MainYOffset) end
            if data.ZoneXScale then ClickZoneBox.Position = UDim2.new(data.ZoneXScale, data.ZoneXOffset, data.ZoneYScale, data.ZoneYOffset) end
            if data.TglXScale then Tgl.Position = UDim2.new(data.TglXScale, data.TglXOffset, data.TglYScale, data.TglYOffset) end
        end
    end

    ClickZoneBox.Visible = isZoneActive
            -- Kéo thả nút 👹 & Tự động lưu vị trí khi thả tay
    local dragT, dInT, dStartT, sPosT
    Tgl.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragT = true dStartT = i.Position sPosT = Tgl.Position
        end
    end)
    Tgl.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement then dInT = i end
    end)
    UIS.InputChanged:Connect(function(i)
        if i == dInT and dragT then
            local delta = i.Position - dStartT
            Tgl.Position = UDim2.new(sPosT.X.Scale, sPosT.X.Offset + delta.X, sPosT.Y.Scale, sPosT.Y.Offset + delta.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            if dragT then dragT = false saveSettings(Main, ClickZoneBox, Tgl) end
        end
    end)

    -- Nút Khóa / Mở khóa Click Zone
    local LockBtn = Instance.new("TextButton")
    LockBtn.Size = UDim2.new(0, 30, 0, 30)
    LockBtn.Position = UDim2.new(0, 5, 0, 5)
    LockBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    LockBtn.Text = "🔓"
    LockBtn.TextSize = 14
    LockBtn.Parent = ClickZoneBox

    local LockC = Instance.new("UICorner")
    LockC.CornerRadius = UDim.new(0, 6)
    LockC.Parent = LockBtn

    LockBtn.MouseButton1Click:Connect(function()
        zoneLocked = not zoneLocked
        if zoneLocked then
            LockBtn.Text = "🔒"
            ZoneStroke.Color = Color3.fromRGB(231, 76, 60)
            ClickZoneBox.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
        else
            LockBtn.Text = "🔓"
            ZoneStroke.Color = Color3.fromRGB(46, 204, 113)
            ClickZoneBox.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        end
    end)

    -- Kéo thả Click Zone & Lưu vị trí
    local dragZ, dInZ, dStartZ, sPosZ
    ClickZoneBox.InputBegan:Connect(function(i)
        if zoneLocked then return end
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragZ = true dStartZ = i.Position sPosZ = ClickZoneBox.Position
        end
    end)
    ClickZoneBox.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement then dInZ = i end
    end)
    UIS.InputChanged:Connect(function(i)
        if i == dInZ and dragZ and not zoneLocked then
            local delta = i.Position - dStartZ
            ClickZoneBox.Position = UDim2.new(sPosZ.X.Scale, sPosZ.X.Offset + delta.X, sPosZ.Y.Scale, sPosZ.Y.Offset + delta.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            if dragZ then dragZ = false saveSettings(Main, ClickZoneBox, Tgl) end
        end
    end)

    local function isInsideZone(x, y)
        if not isZoneActive then return true end
        local absPos = ClickZoneBox.AbsolutePosition
        local absSize = ClickZoneBox.AbsoluteSize
        return (x >= absPos.X and x <= absPos.X + absSize.X and y >= absPos.Y and y <= absPos.Y + absSize.Y)
    end

    local MainC = Instance.new("UICorner")
    MainC.CornerRadius = UDim.new(0, 10)
    MainC.Parent = Main

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Color3.fromRGB(231, 76, 60)
    MainStroke.Thickness = 1.5
    MainStroke.Parent = Main

    -- Thanh Tiêu Đề
    local Bar = Instance.new("Frame")
    Bar.Size = UDim2.new(1, 0, 0, 40)
    Bar.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    Bar.Parent = Main

    local BarC = Instance.new("UICorner")
    BarC.CornerRadius = UDim.new(0, 10)
    BarC.Parent = Bar

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -50, 1, 0)
    Title.Position = UDim2.new(0, 12, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "👹 ONI MACRO HUB PRO"
    Title.TextColor3 = Color3.fromRGB(231, 76, 60)
    Title.TextSize = 14
    Title.Font = Enum.Font.SourceSansBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Bar

    -- Kéo thả Menu chính & Lưu vị trí
    local dragM, dInM, dStartM, sPosM
    Bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragM = true dStartM = i.Position sPosM = Main.Position
        end
    end)
    Bar.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement then dInM = i end
    end)
    UIS.InputChanged:Connect(function(i)
        if i == dInM and dragM then
            local delta = i.Position - dStartM
            Main.Position = UDim2.new(sPosM.X.Scale, sPosM.X.Offset + delta.X, sPosM.Y.Scale, sPosM.Y.Offset + delta.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            if dragM then dragM = false saveSettings(Main, ClickZoneBox, Tgl) end
        end
    end)

    -- Nút Cài Đặt (⚙️)
    local SetBtn = Instance.new("TextButton")
    SetBtn.Size = UDim2.new(0, 30, 0, 30)
    SetBtn.Position = UDim2.new(1, -35, 0, 5)
    SetBtn.BackgroundTransparency = 1
    SetBtn.Text = "⚙️"
    SetBtn.TextSize = 16
    SetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    SetBtn.Parent = Bar

    -- Thanh Tab chuyển đổi (Dịch Chuyển <-> Hành Động)
    local TabBar = Instance.new("Frame")
    TabBar.Size = UDim2.new(1, 0, 0, 35)
    TabBar.Position = UDim2.new(0, 0, 0, 40)
    TabBar.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
    TabBar.Parent = Main

    local Content = Instance.new("Frame")
    Content.Size = UDim2.new(1, 0, 1, -75)
    Content.Position = UDim2.new(0, 0, 0, 75)
    Content.BackgroundTransparency = 1
    Content.Parent = Main

    local TabTeleFrame = Instance.new("Frame")
    TabTeleFrame.Size = UDim2.new(1, 0, 1, 0)
    TabTeleFrame.BackgroundTransparency = 1
    TabTeleFrame.Parent = Content

    local TabCycleFrame = Instance.new("Frame")
    TabCycleFrame.Size = UDim2.new(1, 0, 1, 0)
    TabCycleFrame.BackgroundTransparency = 1
    TabCycleFrame.Visible = false
    TabCycleFrame.Parent = Content

    -- BẢNG CÀI ĐẶT CHÍNH
    local SetFrame = Instance.new("Frame")
    SetFrame.Size = UDim2.new(1, 0, 1, 0)
    SetFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    SetFrame.Visible = false
    SetFrame.ZIndex = 10
    SetFrame.Parent = Content

    local SetTabBar = Instance.new("Frame")
    SetTabBar.Size = UDim2.new(1, 0, 0, 30)
    SetTabBar.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    SetTabBar.ZIndex = 11
    SetTabBar.Parent = SetFrame

    local function CreateTabBtn(text, pos, sizeX, parent)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, sizeX, 1, 0)
        b.Position = pos
        b.BackgroundTransparency = 1
        b.Text = text
        b.TextColor3 = Color3.fromRGB(140, 140, 140)
        b.Font = Enum.Font.SourceSansBold
        b.TextSize = 11
        b.ZIndex = 12
        b.Parent = parent
        return b
    end

    local TabTeleBtn = CreateTabBtn("📍 DỊCH CHUYỂN", UDim2.new(0, 0, 0, 0), 155, TabBar)
    local TabCycleBtn = CreateTabBtn("👹 HÀNH ĐỘNG", UDim2.new(0, 155, 0, 0), 155, TabBar)
    TabTeleBtn.TextColor3 = Color3.fromRGB(231, 76, 60)

    TabTeleBtn.MouseButton1Click:Connect(function()
        TabTeleFrame.Visible = true TabCycleFrame.Visible = false
        TabTeleBtn.TextColor3 = Color3.fromRGB(231, 76, 60) TabCycleBtn.TextColor3 = Color3.fromRGB(140, 140, 140)
    end)
    TabCycleBtn.MouseButton1Click:Connect(function()
        TabTeleFrame.Visible = false TabCycleFrame.Visible = true
        TabTeleBtn.TextColor3 = Color3.fromRGB(140, 140, 140) TabCycleBtn.TextColor3 = Color3.fromRGB(231, 76, 60)
    end)
            local SetMainContent = Instance.new("ScrollingFrame")
    SetMainContent.Size = UDim2.new(1, 0, 1, -30)
    SetMainContent.Position = UDim2.new(0, 0, 0, 30)
    SetMainContent.BackgroundTransparency = 1
    SetMainContent.CanvasSize = UDim2.new(0, 0, 0, 280)
    SetMainContent.ScrollBarThickness = 4
    SetMainContent.ZIndex = 11
    SetMainContent.Parent = SetFrame

    local SetWpContent = Instance.new("ScrollingFrame")
    SetWpContent.Size = UDim2.new(1, 0, 1, -30)
    SetWpContent.Position = UDim2.new(0, 0, 0, 30)
    SetWpContent.BackgroundTransparency = 1
    SetWpContent.Visible = false
    SetWpContent.CanvasSize = UDim2.new(0, 0, 0, 0)
    SetWpContent.ScrollBarThickness = 4
    SetWpContent.ZIndex = 11
    SetWpContent.Parent = SetFrame

    local SetWpLayout = Instance.new("UIListLayout")
    SetWpLayout.Parent = SetWpContent
    SetWpLayout.Padding = UDim.new(0, 5)
    SetWpLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        SetWpContent.CanvasSize = UDim2.new(0, 0, 0, SetWpLayout.AbsoluteContentSize.Y + 10)
    end)

    local SetTab1Btn = CreateTabBtn("⚙️ CÀI ĐẶT CHÍNH", UDim2.new(0, 0, 0, 0), 155, SetTabBar)
    local SetTab2Btn = CreateTabBtn("🗑️ XÓA ĐIỂM", UDim2.new(0, 155, 0, 0), 155, SetTabBar)
    SetTab1Btn.TextColor3 = Color3.fromRGB(231, 76, 60)

    SetTab1Btn.MouseButton1Click:Connect(function()
        SetMainContent.Visible = true SetWpContent.Visible = false
        SetTab1Btn.TextColor3 = Color3.fromRGB(231, 76, 60) SetTab2Btn.TextColor3 = Color3.fromRGB(140, 140, 140)
    end)
    SetTab2Btn.MouseButton1Click:Connect(function()
        SetMainContent.Visible = false SetWpContent.Visible = true
        SetTab1Btn.TextColor3 = Color3.fromRGB(140, 140, 140) SetTab2Btn.TextColor3 = Color3.fromRGB(231, 76, 60)
    end)

    local function CreateBtn(text, color, pos, sizeX, sizeY, parent)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, sizeX, 0, sizeY or 35)
        b.Position = pos
        b.BackgroundColor3 = color
        b.Text = text
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.Font = Enum.Font.SourceSansBold
        b.TextSize = 13
        b.Parent = parent
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = b
        return b
    end

    local function CreateRow(text, pos, parent)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, -20, 0, 35)
        f.Position = UDim2.new(0, 10, 0, pos)
        f.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        f.Parent = parent
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = f
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -110, 1, 0)
        l.Position = UDim2.new(0, 10, 0, 0)
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextColor3 = Color3.fromRGB(200, 200, 200)
        l.TextSize = 12
        l.Font = Enum.Font.SourceSansBold
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = f
        return f, l
    end

    -- --- TAB 1: DỊCH CHUYỂN ---
    local SaveBtn = CreateBtn("Lưu Vị Trí", Color3.fromRGB(46, 204, 113), UDim2.new(0, 10, 0, 10), 135, 35, TabTeleFrame)
    local ClearAllBtn = CreateBtn("Xóa Hết", Color3.fromRGB(231, 76, 60), UDim2.new(1, -145, 0, 10), 135, 35, TabTeleFrame)

    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Size = UDim2.new(1, -20, 1, -55)
    Scroll.Position = UDim2.new(0, 10, 0, 50)
    Scroll.BackgroundTransparency = 1
    Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    Scroll.ScrollBarThickness = 4
    Scroll.Parent = TabTeleFrame

    local List = Instance.new("UIListLayout")
    List.Parent = Scroll
    List.Padding = UDim.new(0, 6)
    List:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Scroll.CanvasSize = UDim2.new(0, 0, 0, List.AbsoluteContentSize.Y + 5)
    end)

    -- --- TAB 2: HÀNH ĐỘNG ---
    local RecordBtn = CreateBtn("🔴 Ghi Hành Động", Color3.fromRGB(192, 57, 43), UDim2.new(0, 10, 0, 10), 135, 35, TabCycleFrame)
    local StopBtn = CreateBtn("⏹️ Dừng", Color3.fromRGB(127, 140, 141), UDim2.new(1, -145, 0, 10), 135, 35, TabCycleFrame)
    local PlayBtn = CreateBtn("▶️ Phát Oni Macro", Color3.fromRGB(41, 128, 185), UDim2.new(0, 10, 0, 55), 280, 35, TabCycleFrame)
    local SaveSlotBtn = CreateBtn("💾 Lưu Macro Hiện Tại", Color3.fromRGB(142, 68, 173), UDim2.new(0, 10, 0, 95), 280, 30, TabCycleFrame)

    local ScrollSlots = Instance.new("ScrollingFrame")
    ScrollSlots.Size = UDim2.new(1, -20, 1, -135)
    ScrollSlots.Position = UDim2.new(0, 10, 0, 130)
    ScrollSlots.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    ScrollSlots.BorderSizePixel = 0
    ScrollSlots.CanvasSize = UDim2.new(0, 0, 0, 0)
    ScrollSlots.ScrollBarThickness = 4
    ScrollSlots.Parent = TabCycleFrame

    local ScrollC = Instance.new("UICorner")
    ScrollC.CornerRadius = UDim.new(0, 6)
    ScrollC.Parent = ScrollSlots

    local SlotLayout = Instance.new("UIListLayout")
    SlotLayout.Parent = ScrollSlots
    SlotLayout.Padding = UDim.new(0, 5)
    SlotLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ScrollSlots.CanvasSize = UDim2.new(0, 0, 0, SlotLayout.AbsoluteContentSize.Y + 5)
    end)

    -- --- CÁC MỤC TRONG TAB 1 CÀI ĐẶT CHÍNH ---
    local LoopRow, LoopLabel = CreateRow("Tự động lặp lại (Loop):", 10, SetMainContent)
    LoopRow.ZIndex = 12 LoopLabel.ZIndex = 12
    local LoopBtn = CreateBtn(autoLoop and "Bật (ON)" or "Tắt (OFF)", autoLoop and Color3.fromRGB(39, 174, 96) or Color3.fromRGB(149, 165, 166), UDim2.new(1, -95, 0, 4), 85, 27, LoopRow)
    LoopBtn.ZIndex = 13

    LoopBtn.MouseButton1Click:Connect(function()
        autoLoop = not autoLoop
        LoopBtn.Text = autoLoop and "Bật (ON)" or "Tắt (OFF)"
        LoopBtn.BackgroundColor3 = autoLoop and Color3.fromRGB(39, 174, 96) or Color3.fromRGB(149, 165, 166)
        saveSettings(Main, ClickZoneBox, Tgl)
    end)

    local CamRow, CamLabel = CreateRow("Lưu Hướng Camera:", 55, SetMainContent)
    CamRow.ZIndex = 12 CamLabel.ZIndex = 12
    local CamBtn = CreateBtn(recordCameraMove and "Bật (ON)" or "Tắt (OFF)", recordCameraMove and Color3.fromRGB(39, 174, 96) or Color3.fromRGB(149, 165, 166), UDim2.new(1, -95, 0, 4), 85, 27, CamRow)
    CamBtn.ZIndex = 13

    CamBtn.MouseButton1Click:Connect(function()
        recordCameraMove = not recordCameraMove
        CamBtn.Text = recordCameraMove and "Bật (ON)" or "Tắt (OFF)"
        CamBtn.BackgroundColor3 = recordCameraMove and Color3.fromRGB(39, 174, 96) or Color3.fromRGB(149, 165, 166)
        saveSettings(Main, ClickZoneBox, Tgl)
    end)

    local ReturnRow, ReturnLabel = CreateRow("Quay Về Điểm Đầu:", 100, SetMainContent)
    ReturnRow.ZIndex = 12 ReturnLabel.ZIndex = 12
    local ReturnBtn = CreateBtn(returnToStart and "Bật (ON)" or "Tắt (OFF)", returnToStart and Color3.fromRGB(39, 174, 96) or Color3.fromRGB(149, 165, 166), UDim2.new(1, -95, 0, 4), 85, 27, ReturnRow)
    ReturnBtn.ZIndex = 13

    ReturnBtn.MouseButton1Click:Connect(function()
        returnToStart = not returnToStart
        ReturnBtn.Text = returnToStart and "Bật (ON)" or "Tắt (OFF)"
        ReturnBtn.BackgroundColor3 = returnToStart and Color3.fromRGB(39, 174, 96) or Color3.fromRGB(149, 165, 166)
        saveSettings(Main, ClickZoneBox, Tgl)
    end)

    local ZoneRow, ZoneLabel = CreateRow("Khung Giới Hạn Click:", 145, SetMainContent)
    ZoneRow.ZIndex = 12 ZoneLabel.ZIndex = 12
    local ZoneBtn = CreateBtn(isZoneActive and "Hiển Thị" or "Ẩn", isZoneActive and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(149, 165, 166), UDim2.new(1, -95, 0, 4), 85, 27, ZoneRow)
    ZoneBtn.ZIndex = 13

    ZoneBtn.MouseButton1Click:Connect(function()
        isZoneActive = not isZoneActive
        ClickZoneBox.Visible = isZoneActive
        ZoneBtn.Text = isZoneActive and "Hiển Thị" or "Ẩn"
        ZoneBtn.BackgroundColor3 = isZoneActive and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(149, 165, 166)
        saveSettings(Main, ClickZoneBox, Tgl)
    end)

    local SizeRow, SizeLabel = CreateRow("Kích Thước Menu:", 190, SetMainContent)
    SizeRow.ZIndex = 12 SizeLabel.ZIndex = 12
    local SizeBtn = CreateBtn(sizeNames[currentSizeIdx], Color3.fromRGB(52, 152, 219), UDim2.new(1, -95, 0, 4), 85, 27, SizeRow)
    SizeBtn.ZIndex = 13

    SizeBtn.MouseButton1Click:Connect(function()
        currentSizeIdx = currentSizeIdx + 1
        if currentSizeIdx > #sizes then currentSizeIdx = 1 end
        Main.Size = sizes[currentSizeIdx].Size
        SizeBtn.Text = sizeNames[currentSizeIdx]
        saveSettings(Main, ClickZoneBox, Tgl)
    end)

    -- Mở / Đóng bảng Cài Đặt
    SetBtn.MouseButton1Click:Connect(function()
        SetFrame.Visible = not SetFrame.Visible
    end)

    -- Đóng / Mở Menu chính khi bấm vào nút 👹
    local mainToggled = false
    Tgl.MouseButton1Click:Connect(function()
        if dragT then return end
        mainToggled = not mainToggled
        Main.Visible = mainToggled
        if not mainToggled then SetFrame.Visible = false end
    end)
end)
