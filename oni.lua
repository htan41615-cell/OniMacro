pcall(function()
    local LP = game:GetService("Players").LocalPlayer
    local UIS = game:GetService("UserInputService")
    local TS = game:GetService("TweenService")
    local runService = game:GetService("RunService")
    local VirtualInputManager = game:GetService("VirtualInputManager")
    
    local PG = LP:WaitForChild("PlayerGui")
    if PG:FindFirstChild("OniMacroHub") then PG.OniMacroHub:Destroy() end

    local Gui = Instance.new("ScreenGui")
    Gui.Name = "OniMacroHub"
    Gui.ResetOnSpawn = false
    Gui.Parent = PG

    local isRecording = false
    local isPlaying = false
    local autoLoop = true
    local recordCameraMove = true
    local returnToStart = true -- Tùy chọn có dịch chuyển về vị trí cũ hay không (Mặc định: Bật)
    
    local macroData = {}
    local savedMacros = {}
    local startTime = 0
    local playThread = nil

    -- Các mức kích thước Menu chính
    local sizes = {
        {Size = UDim2.new(0, 260, 0, 420), Offset = -210}, -- Nhỏ
        {Size = UDim2.new(0, 310, 0, 470), Offset = -235}, -- Vừa
        {Size = UDim2.new(0, 360, 0, 520), Offset = -260}  -- Lớn
    }
    local sizeNames = {"Nhỏ", "Vừa", "Lớn"}
    local currentSizeIdx = 2 -- Mặc định là Vừa

    -- Nút tròn logo ONI (👹)
    local Tgl = Instance.new("TextButton")
    Tgl.Size = UDim2.new(0, 50, 0, 50)
    Tgl.Position = UDim2.new(0.05, 0, 0.25, 0)
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

    -- Kéo thả nút logo
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
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then dragT = false end
    end)

    -- Khung Menu chính
    local Main = Instance.new("Frame")
    Main.Size = sizes[currentSizeIdx].Size
    Main.Position = UDim2.new(0.5, -Main.Size.X.Offset/2, 0.5, sizes[currentSizeIdx].Offset)
    Main.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    Main.Visible = false
    Main.ClipsDescendants = true
    Main.Parent = Gui

    local MainC = Instance.new("UICorner")
    MainC.CornerRadius = UDim.new(0, 10)
    MainC.Parent = Main

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Color3.fromRGB(231, 76, 60)
    MainStroke.Thickness = 1.5
    MainStroke.Parent = Main

    -- Thanh tiêu đề
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

    -- Nút Cài đặt (⚙️)
    local SetBtn = Instance.new("TextButton")
    SetBtn.Size = UDim2.new(0, 30, 0, 30)
    SetBtn.Position = UDim2.new(1, -35, 0, 5)
    SetBtn.BackgroundTransparency = 1
    SetBtn.Text = "⚙️"
    SetBtn.TextSize = 16
    SetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    SetBtn.Parent = Bar

    -- Kéo thả bảng chính
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
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then dragM = false end
    end)

    -- Nội dung chính
    local Content = Instance.new("Frame")
    Content.Size = UDim2.new(1, 0, 1, -40)
    Content.Position = UDim2.new(0, 0, 0, 40)
    Content.BackgroundTransparency = 1
    Content.Parent = Main

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

    local RecordBtn = CreateBtn("🔴 Ghi Hành Động", Color3.fromRGB(192, 57, 43), UDim2.new(0, 10, 0, 10), 135, 35, Content)
    local StopBtn = CreateBtn("⏹️ Dừng", Color3.fromRGB(127, 140, 141), UDim2.new(1, -145, 0, 10), 135, 35, Content)
    local PlayBtn = CreateBtn("▶️ Phát Oni Macro", Color3.fromRGB(41, 128, 185), UDim2.new(0, 10, 0, 55), 280, 35, Content)

    -- Danh sách các bản lưu Slot
    local ListLabel = Instance.new("TextLabel")
    ListLabel.Size = UDim2.new(1, -20, 0, 20)
    ListLabel.Position = UDim2.new(0, 10, 0, 95)
    ListLabel.BackgroundTransparency = 1
    ListLabel.Text = "📁 DANH SÁCH ONI MACRO SLOTS:"
    ListLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    ListLabel.TextSize = 12
    ListLabel.Font = Enum.Font.SourceSansBold
    ListLabel.TextXAlignment = Enum.TextXAlignment.Left
    ListLabel.Parent = Content

    local SaveSlotBtn = CreateBtn("💾 Lưu Macro Hiện Tại", Color3.fromRGB(142, 68, 173), UDim2.new(0, 10, 0, 120), 280, 30, Content)

    local ScrollSlots = Instance.new("ScrollingFrame")
    ScrollSlots.Size = UDim2.new(1, -20, 0, 200)
    ScrollSlots.Position = UDim2.new(0, 10, 0, 155)
    ScrollSlots.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    ScrollSlots.BorderSizePixel = 0
    ScrollSlots.CanvasSize = UDim2.new(0, 0, 0, 0)
    ScrollSlots.ScrollBarThickness = 4
    ScrollSlots.Parent = Content

    local ScrollC = Instance.new("UICorner")
    ScrollC.CornerRadius = UDim.new(0, 6)
    ScrollC.Parent = ScrollSlots

    local SlotLayout = Instance.new("UIListLayout")
    SlotLayout.Parent = ScrollSlots
    SlotLayout.Padding = UDim.new(0, 5)
    SlotLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ScrollSlots.CanvasSize = UDim2.new(0, 0, 0, SlotLayout.AbsoluteContentSize.Y + 5)
    end)

    -- BẢNG CÀI ĐẶT ⚙️
    local SetFrame = Instance.new("Frame")
    SetFrame.Size = UDim2.new(1, 0, 1, 0)
    SetFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    SetFrame.Visible = false
    SetFrame.ZIndex = 5
    SetFrame.Parent = Main

    local SetTitle = Instance.new("TextLabel")
    SetTitle.Size = UDim2.new(1, -20, 0, 35)
    SetTitle.Position = UDim2.new(0, 10, 0, 8)
    SetTitle.BackgroundTransparency = 1
    SetTitle.Text = "⚙️ CÀI ĐẶT ONI MACRO"
    SetTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    SetTitle.TextSize = 14
    SetTitle.Font = Enum.Font.SourceSansBold
    SetTitle.TextXAlignment = Enum.TextXAlignment.Left
    SetTitle.ZIndex = 6
    SetTitle.Parent = SetFrame

    -- 1. Cài đặt Lặp Lại
    local LoopToggleRow = Instance.new("Frame")
    LoopToggleRow.Size = UDim2.new(1, -20, 0, 35)
    LoopToggleRow.Position = UDim2.new(0, 10, 0, 48)
    LoopToggleRow.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    LoopToggleRow.ZIndex = 6
    LoopToggleRow.Parent = SetFrame

    local LoopC = Instance.new("UICorner")
    LoopC.CornerRadius = UDim.new(0, 6)
    LoopC.Parent = LoopToggleRow

    local LoopLabel = Instance.new("TextLabel")
    LoopLabel.Size = UDim2.new(1, -110, 1, 0)
    LoopLabel.Position = UDim2.new(0, 10, 0, 0)
    LoopLabel.BackgroundTransparency = 1
    LoopLabel.Text = "Tự động lặp lại (Loop):"
    LoopLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    LoopLabel.TextSize = 12
    LoopLabel.Font = Enum.Font.SourceSansBold
    LoopLabel.TextXAlignment = Enum.TextXAlignment.Left
    LoopLabel.ZIndex = 6
    LoopLabel.Parent = LoopToggleRow

    local LoopBtn = CreateBtn("Bật (ON)", Color3.fromRGB(39, 174, 96), UDim2.new(1, -95, 0, 4), 85, 27, LoopToggleRow)
    LoopBtn.ZIndex = 6

    LoopBtn.MouseButton1Click:Connect(function()
        autoLoop = not autoLoop
        if autoLoop then
            LoopBtn.Text = "Bật (ON)"
            LoopBtn.BackgroundColor3 = Color3.fromRGB(39, 174, 96)
        else
            LoopBtn.Text = "Tắt (OFF)"
            LoopBtn.BackgroundColor3 = Color3.fromRGB(149, 165, 166)
        end
    end)

    -- 2. Cài đặt Lưu Hướng Cam
    local CamToggleRow = Instance.new("Frame")
    CamToggleRow.Size = UDim2.new(1, -20, 0, 35)
    CamToggleRow.Position = UDim2.new(0, 10, 0, 88)
    CamToggleRow.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    CamToggleRow.ZIndex = 6
    CamToggleRow.Parent = SetFrame

    local CamC = Instance.new("UICorner")
    CamC.CornerRadius = UDim.new(0, 6)
    CamC.Parent = CamToggleRow

    local CamLabel = Instance.new("TextLabel")
    CamLabel.Size = UDim2.new(1, -110, 1, 0)
    CamLabel.Position = UDim2.new(0, 10, 0, 0)
    CamLabel.BackgroundTransparency = 1
    CamLabel.Text = "Lưu Hướng Camera:"
    CamLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    CamLabel.TextSize = 12
    CamLabel.Font = Enum.Font.SourceSansBold
    CamLabel.TextXAlignment = Enum.TextXAlignment.Left
    CamLabel.ZIndex = 6
    CamLabel.Parent = CamToggleRow

    local CamBtn = CreateBtn("Bật (ON)", Color3.fromRGB(39, 174, 96), UDim2.new(1, -95, 0, 4), 85, 27, CamToggleRow)
    CamBtn.ZIndex = 6

    CamBtn.MouseButton1Click:Connect(function()
        recordCameraMove = not recordCameraMove
        if recordCameraMove then
            CamBtn.Text = "Bật (ON)"
            CamBtn.BackgroundColor3 = Color3.fromRGB(39, 174, 96)
        else
            CamBtn.Text = "Tắt (OFF)"
            CamBtn.BackgroundColor3 = Color3.fromRGB(149, 165, 166)
        end
    end)

    -- 3. Cài đặt Quay Về Vị Trí Cũ (Return to Start)
    local ReturnToggleRow = Instance.new("Frame")
    ReturnToggleRow.Size = UDim2.new(1, -20, 0, 35)
    ReturnToggleRow.Position = UDim2.new(0, 10, 0, 128)
    ReturnToggleRow.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    ReturnToggleRow.ZIndex = 6
    ReturnToggleRow.Parent = SetFrame

    local ReturnC = Instance.new("UICorner")
    ReturnC.CornerRadius = UDim.new(0, 6)
    ReturnC.Parent = ReturnToggleRow

    local ReturnLabel = Instance.new("TextLabel")
    ReturnLabel.Size = UDim2.new(1, -110, 1, 0)
    ReturnLabel.Position = UDim2.new(0, 10, 0, 0)
    ReturnLabel.BackgroundTransparency = 1
    ReturnLabel.Text = "Về Vị Trí Cũ Khi Lặp:"
    ReturnLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    ReturnLabel.TextSize = 11
    ReturnLabel.Font = Enum.Font.SourceSansBold
    ReturnLabel.TextXAlignment = Enum.TextXAlignment.Left
    ReturnLabel.ZIndex = 6
    ReturnLabel.Parent = ReturnToggleRow

    local ReturnBtn = CreateBtn("Bật (ON)", Color3.fromRGB(39, 174, 96), UDim2.new(1, -95, 0, 4), 85, 27, ReturnToggleRow)
    ReturnBtn.ZIndex = 6

    ReturnBtn.MouseButton1Click:Connect(function()
        returnToStart = not returnToStart
        if returnToStart then
            ReturnBtn.Text = "Bật (ON)"
            ReturnBtn.BackgroundColor3 = Color3.fromRGB(39, 174, 96)
        else
            ReturnBtn.Text = "Tắt (OFF)"
            ReturnBtn.BackgroundColor3 = Color3.fromRGB(149, 165, 166)
        end
    end)

    -- 4. Cài đặt Thay đổi Kích Cỡ Menu
    local SizeToggleRow = Instance.new("Frame")
    SizeToggleRow.Size = UDim2.new(1, -20, 0, 35)
    SizeToggleRow.Position = UDim2.new(0, 10, 0, 168)
    SizeToggleRow.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    SizeToggleRow.ZIndex = 6
    SizeToggleRow.Parent = SetFrame

    local SizeC = Instance.new("UICorner")
    SizeC.CornerRadius = UDim.new(0, 6)
    SizeC.Parent = SizeToggleRow

    local SizeLabel = Instance.new("TextLabel")
    SizeLabel.Size = UDim2.new(1, -110, 1, 0)
    SizeLabel.Position = UDim2.new(0, 10, 0, 0)
    SizeLabel.BackgroundTransparency = 1
    SizeLabel.Text = "Kích Cỡ Menu:"
    SizeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    SizeLabel.TextSize = 12
    SizeLabel.Font = Enum.Font.SourceSansBold
    SizeLabel.TextXAlignment = Enum.TextXAlignment.Left
    SizeLabel.ZIndex = 6
    SizeLabel.Parent = SizeToggleRow

    local SizeBtn = CreateBtn(sizeNames[currentSizeIdx], Color3.fromRGB(41, 128, 185), UDim2.new(1, -95, 0, 4), 85, 27, SizeToggleRow)
    SizeBtn.ZIndex = 6

    SizeBtn.MouseButton1Click:Connect(function()
        currentSizeIdx = currentSizeIdx % #sizes + 1
        SizeBtn.Text = sizeNames[currentSizeIdx]
        
        local target = sizes[currentSizeIdx]
        Main.Size = target.Size
        Main.Position = UDim2.new(0.5, -target.Size.X.Offset/2, 0.5, target.Offset)
        
        if currentSizeIdx == 1 then
            ScrollSlots.Size = UDim2.new(1, -20, 0, 150)
        elseif currentSizeIdx == 2 then
            ScrollSlots.Size = UDim2.new(1, -20, 0, 200)
        else
            ScrollSlots.Size = UDim2.new(1, -20, 0, 250)
        end
    end)

    -- Nút Quay Lại
    local BackBtn = CreateBtn("⬅️ Quay Lại", Color3.fromRGB(52, 152, 219), UDim2.new(0, 10, 0, 215), 280, 35, SetFrame)
    BackBtn.ZIndex = 6

    SetBtn.MouseButton1Click:Connect(function() SetFrame.Visible = true end)
    BackBtn.MouseButton1Click:Connect(function() SetFrame.Visible = false end)

    Tgl.MouseButton1Click:Connect(function()
        local target = sizes[currentSizeIdx]
        if Main.Visible then
            local t = TS:Create(Main, TweenInfo.new(0.2), {Size = UDim2.new(0, 0, 0, 0)}) t:Play()
            t.Completed:Connect(function() Main.Visible = false Main.Size = target.Size end)
        else
            Main.Size = UDim2.new(0, 0, 0, 0) Main.Visible = true 
            TS:Create(Main, TweenInfo.new(0.2), {Size = target.Size}):Play()
        end
    end)

    -- LOGIC GHI HÀNH ĐỘNG
    local function recordEvent(type, data)
        if not isRecording then return end
        table.insert(macroData, {
            Time = tick() - startTime,
            Type = type,
            Data = data
        })
    end

    UIS.InputBegan:Connect(function(input)
        if not isRecording then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            recordEvent("KeyDown", input.KeyCode)
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local pos = input.Position
            recordEvent("Click", {pos.X, pos.Y})
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if not isRecording then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            recordEvent("KeyUp", input.KeyCode)
        end
    end)

    runService.RenderStepped:Connect(function()
        if not isRecording then return end
        if recordCameraMove then
            local cam = workspace.CurrentCamera
            if cam then
                recordEvent("Cam", cam.CFrame)
            end
        end
        local char = LP.Character
        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChildOfClass("Humanoid") then
            recordEvent("Pos", {char.HumanoidRootPart.CFrame, char.Humanoid.MoveDirection})
        end
    end)

    RecordBtn.MouseButton1Click:Connect(function()
        if isPlaying then return end
        isRecording = true
        macroData = {}
        startTime = tick()
        RecordBtn.Text = "🔴 Đang Ghi..."
        PlayBtn.Text = "Không thể phát khi đang ghi"
    end)

    StopBtn.MouseButton1Click:Connect(function()
        isRecording = false
        if isPlaying then
            isPlaying = false
            if playThread then
                task.cancel(playThread)
                playThread = nil
            end
        end
        RecordBtn.Text = "🔴 Ghi Hành Động"
        PlayBtn.Text = "▶️ Phát Oni Macro"
    end)

    local function refreshSlotUI()
        for _, c in ipairs(ScrollSlots:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end

        for name, data in pairs(savedMacros) do
            local f = Instance.new("Frame")
            f.Size = UDim2.new(1, -10, 0, 35)
            f.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            f.Parent = ScrollSlots

            local fc = Instance.new("UICorner")
            fc.CornerRadius = UDim.new(0, 5)
            fc.Parent = f

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -95, 1, 0)
            lbl.Position = UDim2.new(0, 8, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = name
            lbl.TextColor3 = Color3.fromRGB(240, 240, 240)
            lbl.TextSize = 12
            lbl.Font = Enum.Font.SourceSansBold
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = f

            local loadBtn = CreateBtn("Chạy", Color3.fromRGB(39, 174, 96), UDim2.new(1, -90, 0, 5), 40, 25, f)
            loadBtn.TextSize = 11
            loadBtn.MouseButton1Click:Connect(function()
                macroData = data
                PlayBtn.Text = "▶️ Phát: " + name
            end)

            local delBtn = CreateBtn("Xóa", Color3.fromRGB(192, 57, 43), UDim2.new(1, -45, 0, 5), 40, 25, f)
            delBtn.TextSize = 11
            delBtn.MouseButton1Click:Connect(function()
                savedMacros[name] = nil
                refreshSlotUI()
            end)
        end
    end

    SaveSlotBtn.MouseButton1Click:Connect(function()
        if #macroData == 0 then return end
        local slotName = "Oni_" .. (os.date("%H:%M:%S"))
        savedMacros[slotName] = macroData
        refreshSlotUI()
    end)

    -- LOGIC PHÁT LẠI HÀNH ĐỘNG
    PlayBtn.MouseButton1Click:Connect(function()
        if isRecording or #macroData == 0 or isPlaying then return end
        isPlaying = true
        PlayBtn.Text = "🔵 Đang Phát Oni Macro..."
        
        -- Lưu lại vị trí ban đầu của nhân vật trước khi bắt đầu phát macro
        local startCf = nil
        local char = LP.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            startCf = char.HumanoidRootPart.CFrame
        end
        
        playThread = task.spawn(function()
            while isPlaying do
                local playStart = tick()
                local duration = macroData[#macroData].Time
                local index = 1

                while isPlaying and (tick() - playStart) <= duration + 0.1 do
                    local elapsed = tick() - playStart
                    while index <= #macroData and macroData[index].Time <= elapsed do
                        if not isPlaying then break end
                        local event = macroData[index]
                        
                        if event.Type == "KeyDown" then
                            if event.Data == Enum.KeyCode.Space then
                                local c = LP.Character
                                if c and c:FindFirstChildOfClass("Humanoid") then c.Humanoid.Jump = true end
                            end
                        elseif event.Type == "Click" then
                            VirtualInputManager:SendMouseButtonEvent(event.Data[1], event.Data[2], 0, true, game, 1)
                            VirtualInputManager:SendMouseButtonEvent(event.Data[1], event.Data[2], 0, false, game, 1)
                        elseif event.Type == "Cam" then
                            local cam = workspace.CurrentCamera
                            if cam then
                                cam.CFrame = event.Data
                            end
                        elseif event.Type == "Pos" then
                            local c = LP.Character
                            if c and c:FindFirstChild("HumanoidRootPart") and c:FindFirstChildOfClass("Humanoid") then
                                c.HumanoidRootPart.CFrame = event.Data[1]
                                c.Humanoid:Move(event.Data[2], true)
                            end
                        end
                        index = index + 1
                    end
                    task.wait(0.01)
                end

                if not autoLoop then
                    break
                end
                
                -- Nếu bật tính năng "Về Vị Trí Cũ Khi Lặp", nhân vật sẽ dịch chuyển về chỗ lúc đầu bấm phát
                if returnToStart and startCf then
                    local c = LP.Character
                    if c and c:FindFirstChild("HumanoidRootPart") then
                        c.HumanoidRootPart.CFrame = startCf
                    end
                end
                
                task.wait(0.1)
            end

            isPlaying = false
            PlayBtn.Text = "▶️ Phát Oni Macro"
        end)
    end)
end)
        
