local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local boatRemotes = ReplicatedStorage:WaitForChild("BoatRemotes", 10)
if not boatRemotes then
	boatRemotes = Instance.new("Folder")
	boatRemotes.Name = "BoatRemotes"
	boatRemotes.Parent = ReplicatedStorage
end

local openShopGamepassEvent = boatRemotes:WaitForChild("OpenShopGamepassTab", 10)
if not openShopGamepassEvent then
	return
end

local COLORS = {
	Accent = Color3.fromRGB(70, 130, 255),
	Button = Color3.fromRGB(35, 35, 38),
}

local function tweenSize(object, endSize, time, callback)
	local tweenInfo = TweenInfo.new(time or 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local tween = TweenService:Create(object, tweenInfo, {Size = endSize})
	tween:Play()
	if callback then
		tween.Completed:Connect(callback)
	end
	return tween
end

local function openShopGamepassTab()
	task.wait(0.3)
	
	local shopGui = playerGui:FindFirstChild("ShopGUI")
	if not shopGui then
		return
	end
	
	local mainPanel = shopGui:FindFirstChild("MainPanel")
	if not mainPanel then
		return
	end
	
	shopGui.Enabled = true
	mainPanel.Size = UDim2.new(0, 0, 0, 0)
	mainPanel.Visible = true
	tweenSize(mainPanel, UDim2.new(0.7, 0, 0.9, 0), 0.3)
	
	task.wait(0.35)
	
	local tabFrame = nil
	for _, child in ipairs(mainPanel:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "Header" then
			local hasLayout = child:FindFirstChildOfClass("UIListLayout")
			if hasLayout then
				local hasTextButtons = false
				for _, subChild in ipairs(child:GetChildren()) do
					if subChild:IsA("TextButton") then
						hasTextButtons = true
						break
					end
				end
				if hasTextButtons then
					tabFrame = child
					break
				end
			end
		end
	end
	
	if tabFrame then
		for _, btn in ipairs(tabFrame:GetChildren()) do
			if btn:IsA("TextButton") then
				if btn.Text == "Gamepasses" then
					btn.BackgroundColor3 = COLORS.Accent
				else
					btn.BackgroundColor3 = COLORS.Button
				end
			end
		end
	end
	
	for _, child in ipairs(mainPanel:GetDescendants()) do
		if child:IsA("Frame") then
			if child.Name == "GamepassesContent" then
				child.Visible = true
			elseif child.Name == "AurasContent" or child.Name == "ToolsContent" or child.Name == "MoneyContent" then
				child.Visible = false
			end
		end
	end
end

openShopGamepassEvent.OnClientEvent:Connect(function()
	openShopGamepassTab()
end)
