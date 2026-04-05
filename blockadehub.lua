local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local VIM = game:GetService("VirtualInputManager")
local CoolPlr = game.Players.LocalPlayer

-- ПЕРЕМЕННЫЕ (ПОЛНЫЙ СПИСОК)
local Turn, AttackTurn, EspTurn, AfkTurn, AutoReadyTurn, AutoETurn = false, false, false, false, false, false
local AutoVoteEnabled = false
local SelectedMode = "Рождество"
local OpenKey = Enum.KeyCode.LeftAlt
local ChangingKey, DroppedLang, DroppedMode = false, false, false
local CurrentLang = "Русский"
local LobbySpawnPos = nil
local IsTeleporting = false
local lastESpam = 0
local AttackDebounce = false

-- ПАРАМЕТРЫ ФАРМА
local FarmDelay = 5 
local EnemyDetectedTime = 0
local WaitingForFarm = false

-- РЕЖИМЫ (ВСЕ 13)
local Modes = {
    "Средний", "Сложный", "Экстримальный", "Безумный", "Кошмар", 
    "Босс Раш", "В тумане", "Зомби", "Рождество", "Адская волна", 
    "Темное измерение", "Вторжение", "Очаковок"
}

local Langs = {
    ["Русский"] = { Title = "BLOCKADE HUB", FarmT = "🤖 Авто", VisT = "👁️ Визуалы", SettT = "⚙️ Настройки", AFarm = "АВТО ФАРМ", AAtk = "АВТО АТАКА", ESP = "ВКЛЮЧИТЬ ESP", Bind = "КЛАВИША", Lang = "ЯЗЫК", AFK = "АНТИ-АФК", AReady = "АВТО ГОТОВНОСТЬ", AETxt = "АВТО [E]", ModeTxt = "РЕЖИМ", AVoteTxt = "АВТО ГОЛОСОВАНИЕ" },
    ["English"] = { Title = "BLOCKADE HUB", FarmT = "🤖 Auto", VisT = "👁️ Visuals", SettT = "⚙️ Settings", AFarm = "AUTO FARM", AAtk = "AUTO ATTACK", ESP = "ENABLE ESP", Bind = "KEYBIND", Lang = "LANGUAGE", AFK = "ANTI-AFK", AReady = "AUTO READY", AETxt = "AUTO [E]", ModeTxt = "MODE", AVoteTxt = "AUTO VOTE" }
}

-- ОТПРАВКА ГОЛОСА
local function sendVote(modeName)
    local voteEvent = game:GetService("ReplicatedStorage"):FindFirstChild("Vote")
    if voteEvent then voteEvent:FireServer(modeName) end
end

-- ПЕРЕТАСКИВАНИЕ
local function makeDraggable(frame)
    local dragging, dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = frame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local function findZone()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and (v.Name:lower():find("ready") or v.Name:lower():find("zone")) then return v end
    end
    return nil
end

-- АНТИ-АФК (КАМЕРА)
for _, v in pairs(getconnections(CoolPlr.Idled)) do v:Disable() end
CoolPlr.Idled:Connect(function()
    if AfkTurn then
        pcall(function()
            local cam = workspace.CurrentCamera
            cam.CFrame = cam.CFrame * CFrame.Angles(0, math.rad(0.1), 0)
        end)
    end
end)

-- ГУИ
local Gui = Instance.new("ScreenGui", CoolPlr.PlayerGui); Gui.Name = "BlockadeHub_Ultra"; Gui.ResetOnSpawn = false
local OpenBtn = Instance.new("TextButton", Gui)
OpenBtn.Size = UDim2.new(0, 50, 0, 50); OpenBtn.Position = UDim2.new(0.5, -25, 0.5, -25)
OpenBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30); OpenBtn.Text = "BH"; OpenBtn.TextColor3 = Color3.new(1, 1, 1); OpenBtn.Font = "GothamBold"; OpenBtn.TextSize = 18
Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(0, 25); Instance.new("UIStroke", OpenBtn).Thickness = 2
makeDraggable(OpenBtn)

local Main = Instance.new("CanvasGroup", Gui); Main.Size = UDim2.new(0, 500, 0, 420); Main.Position = UDim2.new(0.5, -250, 1.2, 0); Main.BackgroundColor3 = Color3.fromRGB(20, 20, 20); Main.Visible = false
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 15)

local Side = Instance.new("Frame", Main); Side.Size = UDim2.new(0, 150, 1, 0); Side.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
local SideList = Instance.new("UIListLayout", Side); SideList.Padding = UDim.new(0, 8); SideList.HorizontalAlignment = "Center"
local HubTitle = Instance.new("TextLabel", Side); HubTitle.Size = UDim2.new(1, 0, 0, 50); HubTitle.BackgroundTransparency = 1; HubTitle.TextColor3 = Color3.new(1, 1, 1); HubTitle.Font = "GothamBold"; HubTitle.TextSize = 16

local SideBtnFarm = Instance.new("TextButton", Side); local SideBtnVis = Instance.new("TextButton", Side); local SideBtnSett = Instance.new("TextButton", Side)
local function styleSide(btn) btn.Size = UDim2.new(0.9, 0, 0, 38); btn.BackgroundColor3 = Color3.fromRGB(25, 25, 25); btn.TextColor3 = Color3.fromRGB(200, 200, 200); btn.Font = "GothamSemibold"; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12) end
styleSide(SideBtnFarm); styleSide(SideBtnVis); styleSide(SideBtnSett)

local Pages = Instance.new("Frame", Main); Pages.Position = UDim2.new(0, 160, 0, 15); Pages.Size = UDim2.new(1, -175, 1, -30); Pages.BackgroundTransparency = 1
local FarmP = Instance.new("ScrollingFrame", Pages); local VisP = Instance.new("Frame", Pages); local SettP = Instance.new("Frame", Pages)
for _, p in pairs({FarmP, VisP, SettP}) do p.Size = UDim2.new(1,0,1,0); p.BackgroundTransparency = 1; p.Visible = false; if p:IsA("ScrollingFrame") then p.ScrollBarThickness = 0; p.CanvasSize = UDim2.new(0,0,1.4,0) end; Instance.new("UIListLayout", p).Padding = UDim.new(0,10) end
FarmP.Visible = true

local function createBtn(p)
    local b = Instance.new("TextButton", p); b.Size = UDim2.new(1, 0, 0, 45); b.BackgroundColor3 = Color3.fromRGB(30, 30, 30); b.TextColor3 = Color3.new(1, 1, 1); b.Font = "GothamSemibold"; b.TextXAlignment = "Left"
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 12); Instance.new("UIPadding", b).PaddingLeft = UDim.new(0, 15)
    return b
end

-- ВКЛАДКА АВТО
local TpB = createBtn(FarmP); local AtkB = createBtn(FarmP); local AutoEB = createBtn(FarmP); local ReadyB = createBtn(FarmP)

local ModeCont = Instance.new("Frame", FarmP); ModeCont.Size = UDim2.new(1, 0, 0, 50); ModeCont.BackgroundTransparency = 1
local ModeLab = Instance.new("TextLabel", ModeCont); ModeLab.Size = UDim2.new(0.3, 0, 1, 0); ModeLab.Position = UDim2.new(0, 10, 0, 0); ModeLab.BackgroundTransparency = 1; ModeLab.TextColor3 = Color3.new(1, 1, 1); ModeLab.Font = "GothamSemibold"; ModeLab.TextXAlignment = "Left"
local ModeDropBtn = Instance.new("TextButton", ModeCont); ModeDropBtn.Size = UDim2.new(0.65, 0, 0, 35); ModeDropBtn.Position = UDim2.new(0.32, 0, 0.15, 0); ModeDropBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35); ModeDropBtn.TextColor3 = Color3.new(1, 1, 1); ModeDropBtn.ZIndex = 5; Instance.new("UICorner", ModeDropBtn).CornerRadius = UDim.new(0, 8)
local ModeScroll = Instance.new("ScrollingFrame", ModeDropBtn); ModeScroll.Size = UDim2.new(1, 0, 0, 150); ModeScroll.Position = UDim2.new(0, 0, 1, 5); ModeScroll.BackgroundColor3 = Color3.fromRGB(30, 30, 30); ModeScroll.Visible = false; ModeScroll.ZIndex = 10; ModeScroll.ScrollBarThickness = 4; ModeScroll.CanvasSize = UDim2.new(0,0,0, #Modes * 35); Instance.new("UICorner", ModeScroll)
Instance.new("UIListLayout", ModeScroll)

for _, m in pairs(Modes) do
    local o = Instance.new("TextButton", ModeScroll); o.Size = UDim2.new(1, 0, 0, 35); o.BackgroundColor3 = Color3.fromRGB(40, 40, 40); o.TextColor3 = Color3.new(1, 1, 1); o.Text = m; o.ZIndex = 11; o.Font = "GothamSemibold"
    o.MouseButton1Click:Connect(function() SelectedMode = m; DroppedMode = false; ModeScroll.Visible = false; sendVote(m); updateUI() end)
end
local AutoVoteB = createBtn(FarmP)

-- ВИЗУАЛЫ И НАСТРОЙКИ
local EspB = createBtn(VisP)
local LangCont = Instance.new("Frame", SettP); LangCont.Size = UDim2.new(1, 0, 0, 50); LangCont.BackgroundTransparency = 1
local LangLab = Instance.new("TextLabel", LangCont); LangLab.Size = UDim2.new(0.5, 0, 1, 0); LangLab.Position = UDim2.new(0, 10, 0, 0); LangLab.BackgroundTransparency = 1; LangLab.TextColor3 = Color3.new(1, 1, 1); LangLab.Font = "GothamSemibold"; LangLab.TextXAlignment = "Left"
local LangDropBtn = Instance.new("TextButton", LangCont); LangDropBtn.Size = UDim2.new(0.45, 0, 0, 32); LangDropBtn.Position = UDim2.new(0.55, -5, 0, 9); LangDropBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35); LangDropBtn.TextColor3 = Color3.new(1, 1, 1); LangDropBtn.ZIndex = 5; Instance.new("UICorner", LangDropBtn).CornerRadius = UDim.new(0, 8)
local LangScroll = Instance.new("Frame", LangDropBtn); LangScroll.Size = UDim2.new(1, 0, 0, 70); LangScroll.Position = UDim2.new(0, 0, 1, 5); LangScroll.BackgroundColor3 = Color3.fromRGB(30, 30, 30); LangScroll.Visible = false; LangScroll.ZIndex = 10; Instance.new("UICorner", LangScroll)
local function createLangOpt(txt, y, lang)
    local o = Instance.new("TextButton", LangScroll); o.Size = UDim2.new(1, 0, 0, 35); o.Position = UDim2.new(0, 0, 0, y); o.BackgroundColor3 = Color3.fromRGB(40, 40, 40); o.TextColor3 = Color3.new(1, 1, 1); o.Text = txt; o.ZIndex = 11
    o.MouseButton1Click:Connect(function() CurrentLang = lang; DroppedLang = false; LangScroll.Visible = false; updateUI() end)
end
createLangOpt("English", 0, "English"); createLangOpt("Русский", 35, "Русский")
local BinB = createBtn(SettP); local AfkBBtn = createBtn(SettP)

function updateUI()
    local L = Langs[CurrentLang]
    HubTitle.Text = L.Title; SideBtnFarm.Text = L.FarmT; SideBtnVis.Text = L.VisT; SideBtnSett.Text = L.SettT
    TpB.Text = L.AFarm .. ": " .. (Turn and "ON" or "OFF"); AtkB.Text = L.AAtk .. ": " .. (AttackTurn and "ON" or "OFF")
    AutoEB.Text = L.AETxt .. ": " .. (AutoETurn and "ON" or "OFF"); ReadyB.Text = L.AReady .. ": " .. (AutoReadyTurn and "ON" or "OFF")
    EspB.Text = L.ESP .. ": " .. (EspTurn and "ON" or "OFF"); BinB.Text = L.Bind .. ": [" .. OpenKey.Name .. "]"
    AfkBBtn.Text = L.AFK .. ": " .. (AfkTurn and "ON" or "OFF"); LangLab.Text = L.Lang; LangDropBtn.Text = CurrentLang .. " ▼"
    ModeLab.Text = L.ModeTxt; ModeDropBtn.Text = SelectedMode .. " ▼"; AutoVoteB.Text = L.AVoteTxt .. ": " .. (AutoVoteEnabled and "ON" or "OFF")
    local function color(t) return t and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(30, 30, 30) end
    TpB.BackgroundColor3 = color(Turn); AtkB.BackgroundColor3 = color(AttackTurn); AutoEB.BackgroundColor3 = color(AutoETurn)
    ReadyB.BackgroundColor3 = color(AutoReadyTurn); EspB.BackgroundColor3 = color(EspTurn); AfkBBtn.BackgroundColor3 = color(AfkTurn); AutoVoteB.BackgroundColor3 = color(AutoVoteEnabled)
end

-- ЦИКЛЫ
task.spawn(function()
    while true do
        task.wait(0.5)
        local char = CoolPlr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if AutoReadyTurn and hrp then
            if not LobbySpawnPos then LobbySpawnPos = hrp.Position end
            if (hrp.Position - LobbySpawnPos).Magnitude <= 20 and not IsTeleporting then
                IsTeleporting = true; task.wait(2.5)
                local zone = findZone()
                if zone then hrp.CFrame = zone.CFrame + Vector3.new(0, 3, 0) else hrp.CFrame = hrp.CFrame * CFrame.new(0, 0, -18) end
                task.wait(5); IsTeleporting = false
            end
        end
        if AutoVoteEnabled then
            local playMenu = CoolPlr.PlayerGui:FindFirstChild("Play")
            local mainFrame = playMenu and playMenu:FindFirstChild("Main")
            if mainFrame and mainFrame.Visible then sendVote(SelectedMode); task.wait(5) end
        end
    end
end)

SideBtnFarm.MouseButton1Click:Connect(function() FarmP.Visible = true; VisP.Visible = false; SettP.Visible = false end)
SideBtnVis.MouseButton1Click:Connect(function() FarmP.Visible = false; VisP.Visible = true; SettP.Visible = false end)
SideBtnSett.MouseButton1Click:Connect(function() FarmP.Visible = false; VisP.Visible = false; SettP.Visible = true end)
TpB.MouseButton1Click:Connect(function() Turn = not Turn; updateUI() end)
AtkB.MouseButton1Click:Connect(function() AttackTurn = not AttackTurn; updateUI() end)
AutoEB.MouseButton1Click:Connect(function() AutoETurn = not AutoETurn; updateUI() end)
ReadyB.MouseButton1Click:Connect(function() AutoReadyTurn = not AutoReadyTurn; updateUI() end)
AfkBBtn.MouseButton1Click:Connect(function() AfkTurn = not AfkTurn; updateUI() end)
AutoVoteB.MouseButton1Click:Connect(function() AutoVoteEnabled = not AutoVoteEnabled; updateUI() end)
LangDropBtn.MouseButton1Click:Connect(function() DroppedLang = not DroppedLang; LangScroll.Visible = DroppedLang end)
ModeDropBtn.MouseButton1Click:Connect(function() DroppedMode = not DroppedMode; ModeScroll.Visible = DroppedMode end)
BinB.MouseButton1Click:Connect(function() ChangingKey = true; BinB.Text = "..." end)

local function toggleMain()
    if not Main.Visible then Main.Visible = true; TS:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Back), {Position = UDim2.new(0.5, -250, 0.5, -175)}):Play()
    else TS:Create(Main, TweenInfo.new(0.3), {Position = UDim2.new(0.5, -250, 1.2, 0)}):Play(); task.wait(0.3); Main.Visible = false end
end
OpenBtn.MouseButton1Click:Connect(toggleMain)
UIS.InputBegan:Connect(function(i, p) if ChangingKey and i.UserInputType == Enum.UserInputType.Keyboard then OpenKey = i.KeyCode; ChangingKey = false; updateUI() elseif not p and i.KeyCode == OpenKey then toggleMain() end end)

RunService.Heartbeat:Connect(function()
    if Turn and CoolPlr.Character and CoolPlr.Character:FindFirstChild("HumanoidRootPart") and CoolPlr.Character.Humanoid.Health > 0 then
        local t = nil; local liv = workspace:FindFirstChild("Living")
        if liv then for _, m in pairs(liv:GetChildren()) do if m:FindFirstChild("Humanoid") and m.Humanoid.Health > 0 and m:FindFirstChild("AI") then t = m break end end end
        if t then
            if not WaitingForFarm then WaitingForFarm = true; EnemyDetectedTime = tick() end
            if tick() - EnemyDetectedTime >= FarmDelay then CoolPlr.Character.HumanoidRootPart.CFrame = t.HumanoidRootPart.CFrame * CFrame.new(0, 0, 4) end
        else WaitingForFarm = false end
    else WaitingForFarm = false end
    if AutoETurn and (tick() - lastESpam >= 1) then lastESpam = tick(); VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game); task.wait(0.05); VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game) end
    if AttackTurn and not AttackDebounce then AttackDebounce = true; VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0); task.wait(0.05); VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0); task.delay(0.5, function() AttackDebounce = false end) end
end)
updateUI()
