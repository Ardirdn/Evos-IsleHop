-- RemoveInventoryPopup Module
-- Used by AdminClient to show popup for removing player inventory items

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoveInventoryPopup = {}

local COLORS = {
	Background = Color3.fromRGB(25, 25, 30),
	Panel = Color3.fromRGB(30, 30, 35),
	Header = Color3.fromRGB(35, 35, 40),
	Button = Color3.fromRGB(45, 45, 50),
	Accent = Color3.fromRGB(88, 101, 242),
	Text = Color3.fromRGB(255, 255, 255),
	TextSecondary = Color3.fromRGB(180, 180, 185),
	Danger = Color3.fromRGB(237, 66, 69),
	Success = Color3.fromRGB(67, 181, 129),
	Border = Color3.fromRGB(50, 50, 55)
}

local function createCorner(radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	return corner
end

local function createStroke(color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return stroke
end

function RemoveInventoryPopup.Show(screenGui, targetPlayer, onClose)
	if not targetPlayer then return end
	
	local remoteFolder = ReplicatedStorage:FindFirstChild("AdminRemotes")
	if not remoteFolder then return end
	
	local getPlayerInventoryFunc = remoteFolder:FindFirstChild("GetPlayerInventory")
	local removeInventoryItemEvent = remoteFolder:FindFirstChild("RemoveInventoryItem")
	
	if not getPlayerInventoryFunc or not removeInventoryItemEvent then
		warn("[RemoveInventoryPopup] Remote events not found")
		return
	end
	
	-- Create popup
	local popup = Instance.new("Frame")
	popup.Name = "RemoveInventoryPopup"
	popup.Size = UDim2.new(0.35, 0, 0.7, 0)
	popup.Position = UDim2.new(0.5, 0, 0.5, 0)
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	popup.BackgroundColor3 = COLORS.Background
	popup.BorderSizePixel = 0
	popup.ZIndex = 30
	popup.ClipsDescendants = true
	popup.Parent = screenGui
	
	createCorner(12).Parent = popup
	createStroke(COLORS.Border, 2).Parent = popup
	
	-- Header
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0.1, 0)
	header.BackgroundColor3 = COLORS.Header
	header.BorderSizePixel = 0
	header.Parent = popup
	createCorner(12).Parent = header
	
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.85, 0, 1, 0)
	title.Position = UDim2.new(0.03, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.Text = "Remove Inventory - " .. targetPlayer.Name
	title.TextColor3 = COLORS.Text
	title.TextScaled = true
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header
	
	local titleConstraint = Instance.new("UITextSizeConstraint")
	titleConstraint.MaxTextSize = 18
	titleConstraint.Parent = title
	
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0.1, 0, 0.6, 0)
	closeBtn.Position = UDim2.new(0.88, 0, 0.2, 0)
	closeBtn.BackgroundColor3 = COLORS.Button
	closeBtn.BorderSizePixel = 0
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Text = "×"
	closeBtn.TextColor3 = COLORS.Text
	closeBtn.TextScaled = true
	closeBtn.Parent = header
	createCorner(6).Parent = closeBtn
	
	closeBtn.MouseButton1Click:Connect(function()
		popup:Destroy()
		if onClose then onClose() end
	end)
	
	-- Content scroll
	local contentScroll = Instance.new("ScrollingFrame")
	contentScroll.Size = UDim2.new(0.94, 0, 0.85, 0)
	contentScroll.Position = UDim2.new(0.03, 0, 0.12, 0)
	contentScroll.BackgroundTransparency = 1
	contentScroll.BorderSizePixel = 0
	contentScroll.ScrollBarThickness = 4
	contentScroll.ScrollBarImageColor3 = COLORS.Border
	contentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	contentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	contentScroll.Parent = popup
	
	local contentLayout = Instance.new("UIListLayout")
	contentLayout.Padding = UDim.new(0, 6)
	contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	contentLayout.Parent = contentScroll
	
	-- Loading text
	local loadingText = Instance.new("TextLabel")
	loadingText.Size = UDim2.new(1, 0, 0, 40)
	loadingText.BackgroundTransparency = 1
	loadingText.Font = Enum.Font.Gotham
	loadingText.Text = "Loading inventory..."
	loadingText.TextColor3 = COLORS.TextSecondary
	loadingText.TextSize = 14
	loadingText.Parent = contentScroll
	
	-- Fetch inventory
	task.spawn(function()
		local result = getPlayerInventoryFunc:InvokeServer(targetPlayer.UserId)
		
		if loadingText and loadingText.Parent then
			loadingText:Destroy()
		end
		
		if result and result.success and result.inventory then
			local function createItemFrame(itemType, itemId, layoutOrder)
				local itemFrame = Instance.new("Frame")
				itemFrame.Size = UDim2.new(1, 0, 0, 35)
				itemFrame.BackgroundColor3 = COLORS.Panel
				itemFrame.BorderSizePixel = 0
				itemFrame.LayoutOrder = layoutOrder
				itemFrame.Parent = contentScroll
				createCorner(6).Parent = itemFrame
				
				local typeIcon = Instance.new("TextLabel")
				typeIcon.Size = UDim2.new(0.1, 0, 1, 0)
				typeIcon.BackgroundTransparency = 1
				typeIcon.Font = Enum.Font.GothamBold
				typeIcon.Text = itemType == "Aura" and "✨" or (itemType == "Tool" and "🔧" or "🏷️")
				typeIcon.TextColor3 = COLORS.Accent
				typeIcon.TextSize = 16
				typeIcon.Parent = itemFrame
				
				local itemName = Instance.new("TextLabel")
				itemName.Size = UDim2.new(0.55, 0, 1, 0)
				itemName.Position = UDim2.new(0.1, 0, 0, 0)
				itemName.BackgroundTransparency = 1
				itemName.Font = Enum.Font.Gotham
				itemName.Text = itemId .. " (" .. itemType .. ")"
				itemName.TextColor3 = COLORS.Text
				itemName.TextSize = 13
				itemName.TextXAlignment = Enum.TextXAlignment.Left
				itemName.Parent = itemFrame
				
				local removeBtn = Instance.new("TextButton")
				removeBtn.Size = UDim2.new(0.25, 0, 0.7, 0)
				removeBtn.Position = UDim2.new(0.72, 0, 0.15, 0)
				removeBtn.BackgroundColor3 = COLORS.Danger
				removeBtn.BorderSizePixel = 0
				removeBtn.Font = Enum.Font.GothamBold
				removeBtn.Text = "Remove"
				removeBtn.TextColor3 = COLORS.Text
				removeBtn.TextSize = 12
				removeBtn.Parent = itemFrame
				createCorner(4).Parent = removeBtn
				
				removeBtn.MouseButton1Click:Connect(function()
					removeInventoryItemEvent:FireServer(targetPlayer.UserId, itemType, itemId)
					itemFrame:Destroy()
				end)
			end
			
			local order = 1
			local inv = result.inventory
			
			-- Auras section
			if inv.Auras and #inv.Auras > 0 then
				local auraHeader = Instance.new("TextLabel")
				auraHeader.Size = UDim2.new(1, 0, 0, 25)
				auraHeader.BackgroundTransparency = 1
				auraHeader.Font = Enum.Font.GothamBold
				auraHeader.Text = "✨ Auras (" .. #inv.Auras .. ")"
				auraHeader.TextColor3 = COLORS.Accent
				auraHeader.TextSize = 14
				auraHeader.TextXAlignment = Enum.TextXAlignment.Left
				auraHeader.LayoutOrder = order
				auraHeader.Parent = contentScroll
				order = order + 1
				
				for _, auraId in ipairs(inv.Auras) do
					createItemFrame("Aura", auraId, order)
					order = order + 1
				end
			end
			
			-- Tools section
			if inv.Tools and #inv.Tools > 0 then
				local toolHeader = Instance.new("TextLabel")
				toolHeader.Size = UDim2.new(1, 0, 0, 25)
				toolHeader.BackgroundTransparency = 1
				toolHeader.Font = Enum.Font.GothamBold
				toolHeader.Text = "🔧 Tools (" .. #inv.Tools .. ")"
				toolHeader.TextColor3 = COLORS.Success
				toolHeader.TextSize = 14
				toolHeader.TextXAlignment = Enum.TextXAlignment.Left
				toolHeader.LayoutOrder = order
				toolHeader.Parent = contentScroll
				order = order + 1
				
				for _, toolId in ipairs(inv.Tools) do
					createItemFrame("Tool", toolId, order)
					order = order + 1
				end
			end
			
			-- Titles section
			if inv.Titles and #inv.Titles > 0 then
				local titleHeader = Instance.new("TextLabel")
				titleHeader.Size = UDim2.new(1, 0, 0, 25)
				titleHeader.BackgroundTransparency = 1
				titleHeader.Font = Enum.Font.GothamBold
				titleHeader.Text = "🏷️ Titles (" .. #inv.Titles .. ")"
				titleHeader.TextColor3 = Color3.fromRGB(255, 193, 7)
				titleHeader.TextSize = 14
				titleHeader.TextXAlignment = Enum.TextXAlignment.Left
				titleHeader.LayoutOrder = order
				titleHeader.Parent = contentScroll
				order = order + 1
				
				for _, titleId in ipairs(inv.Titles) do
					createItemFrame("Title", titleId, order)
					order = order + 1
				end
			end
			
			-- Empty state
			if (not inv.Auras or #inv.Auras == 0) and (not inv.Tools or #inv.Tools == 0) and (not inv.Titles or #inv.Titles == 0) then
				local emptyText = Instance.new("TextLabel")
				emptyText.Size = UDim2.new(1, 0, 0, 40)
				emptyText.BackgroundTransparency = 1
				emptyText.Font = Enum.Font.Gotham
				emptyText.Text = "Player has no items in inventory"
				emptyText.TextColor3 = COLORS.TextSecondary
				emptyText.TextSize = 14
				emptyText.Parent = contentScroll
			end
		else
			local errorText = Instance.new("TextLabel")
			errorText.Size = UDim2.new(1, 0, 0, 40)
			errorText.BackgroundTransparency = 1
			errorText.Font = Enum.Font.Gotham
			errorText.Text = result and result.message or "Failed to load inventory"
			errorText.TextColor3 = COLORS.Danger
			errorText.TextSize = 14
			errorText.Parent = contentScroll
		end
	end)
	
	return popup
end

return RemoveInventoryPopup
