local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local lp = Players.LocalPlayer

local function go(placeId, jobId)
	local ok = pcall(function()
		local opt = Instance.new("TeleportOptions")
		opt.ServerInstanceId = jobId
		TeleportService:TeleportAsync(placeId, { lp }, opt)
	end)
	if ok then return true end
	local ok2, err2 = pcall(function()
		TeleportService:TeleportToPlaceInstance(placeId, jobId, lp)
	end)
	if ok2 then return true end
	return false, tostring(err2)
end

local old = game:GetService("CoreGui"):FindFirstChild("ANSNJoin")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "ANSNJoin"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999998
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = lp:WaitForChild("PlayerGui") end

local card = Instance.new("Frame")
card.AnchorPoint = Vector2.new(0.5, 0.5)
card.Position = UDim2.fromScale(0.5, 0.4)
card.Size = UDim2.fromOffset(380, 132)
card.BackgroundColor3 = Color3.fromRGB(17, 19, 22)
card.BorderSizePixel = 1
card.BorderColor3 = Color3.fromRGB(35, 39, 45)
card.Active = true
card.Parent = gui
local c0 = Instance.new("UICorner")
c0.CornerRadius = UDim.new(0, 10)
c0.Parent = card

local bar = Instance.new("Frame")
bar.Size = UDim2.new(1, 0, 0, 3)
bar.BackgroundColor3 = Color3.fromRGB(79, 140, 255)
bar.BorderSizePixel = 0
bar.Parent = card
local c1 = Instance.new("UICorner")
c1.CornerRadius = UDim.new(0, 10)
c1.Parent = bar

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(20, 16)
title.Size = UDim2.new(1, -60, 0, 20)
title.BackgroundTransparency = 1
title.Text = "进入服务器"
title.TextColor3 = Color3.fromRGB(231, 233, 236)
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = card

local close = Instance.new("TextButton")
close.AnchorPoint = Vector2.new(1, 0)
close.Position = UDim2.new(1, -14, 0, 12)
close.Size = UDim2.fromOffset(26, 26)
close.BackgroundColor3 = Color3.fromRGB(28, 31, 36)
close.BorderSizePixel = 0
close.Text = "×"
close.TextColor3 = Color3.fromRGB(154, 161, 171)
close.Font = Enum.Font.GothamBold
close.TextSize = 17
close.Parent = card
local c2 = Instance.new("UICorner")
c2.CornerRadius = UDim.new(0, 6)
c2.Parent = close
close.MouseButton1Click:Connect(function() gui:Destroy() end)

local box = Instance.new("TextBox")
box.Position = UDim2.fromOffset(20, 44)
box.Size = UDim2.new(1, -108, 0, 38)
box.BackgroundColor3 = Color3.fromRGB(11, 12, 14)
box.BorderSizePixel = 1
box.BorderColor3 = Color3.fromRGB(44, 49, 56)
box.Text = ""
box.PlaceholderText = "粘贴 JobId"
box.TextColor3 = Color3.fromRGB(231, 233, 236)
box.PlaceholderColor3 = Color3.fromRGB(90, 97, 107)
box.Font = Enum.Font.Code
box.TextSize = 14
box.ClearTextOnFocus = false
box.TextXAlignment = Enum.TextXAlignment.Left
box.Parent = card
local c3 = Instance.new("UICorner")
c3.CornerRadius = UDim.new(0, 6)
c3.Parent = box

local goBtn = Instance.new("TextButton")
goBtn.AnchorPoint = Vector2.new(1, 0)
goBtn.Position = UDim2.new(1, -20, 0, 44)
goBtn.Size = UDim2.fromOffset(78, 38)
goBtn.BackgroundColor3 = Color3.fromRGB(79, 140, 255)
goBtn.BorderSizePixel = 0
goBtn.Text = "进入"
goBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
goBtn.Font = Enum.Font.GothamMedium
goBtn.TextSize = 14
goBtn.Parent = card
local c4 = Instance.new("UICorner")
c4.CornerRadius = UDim.new(0, 6)
c4.Parent = goBtn

local status = Instance.new("TextLabel")
status.Position = UDim2.fromOffset(20, 90)
status.Size = UDim2.new(1, -40, 0, 18)
status.BackgroundTransparency = 1
status.Text = ""
status.TextColor3 = Color3.fromRGB(154, 161, 171)
status.Font = Enum.Font.Gotham
status.TextSize = 11
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = card

local function setStatus(txt, color)
	status.Text = txt
	status.TextColor3 = color or Color3.fromRGB(154, 161, 171)
end

local function enter()
	local jid = (box.Text or ""):gsub("%s", "")
	if #jid < 8 then
		setStatus("JobId 不对，检查一下", Color3.fromRGB(235, 120, 120))
		return
	end
	if jid == tostring(game.JobId) then
		setStatus("你已经在这个服务器了", Color3.fromRGB(235, 190, 100))
		return
	end
	setStatus("正在传送…", Color3.fromRGB(140, 180, 255))
	goBtn.Text = "传送中"
	local ok, err = go(game.PlaceId, jid)
	if not ok then
		setStatus("失败：" .. tostring(err):sub(1, 50), Color3.fromRGB(235, 120, 120))
		goBtn.Text = "进入"
	end
end

goBtn.MouseButton1Click:Connect(enter)
box.FocusLost:Connect(function(enterPressed)
	if enterPressed then enter() end
end)

local dragging, dragStart, startPos
card.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = card.Position
	end
end)
card.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local d = input.Position - dragStart
		card.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end
end)
