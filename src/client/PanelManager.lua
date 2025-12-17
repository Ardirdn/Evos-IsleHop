local PanelManager = {}

local registeredPanels = {}
local currentOpenPanel = nil

function PanelManager:Register(panelName, closeFunction)
    registeredPanels[panelName] = {
        closeFunc = closeFunction,
        isOpen = false
    }
end

function PanelManager:Open(panelName)
    for name, panel in pairs(registeredPanels) do
        if name ~= panelName and panel.isOpen then
            if panel.closeFunc then
                panel.closeFunc()
            end
            panel.isOpen = false
        end
    end

    if registeredPanels[panelName] then
        registeredPanels[panelName].isOpen = true
        currentOpenPanel = panelName
    end
end

function PanelManager:Close(panelName)
    if registeredPanels[panelName] then
        registeredPanels[panelName].isOpen = false
        if currentOpenPanel == panelName then
            currentOpenPanel = nil
        end
    end
end

function PanelManager:IsOpen(panelName)
    if registeredPanels[panelName] then
        return registeredPanels[panelName].isOpen
    end
    return false
end

function PanelManager:GetCurrentPanel()
    return currentOpenPanel
end

function PanelManager:CloseAll()
    for name, panel in pairs(registeredPanels) do
        if panel.isOpen and panel.closeFunc then
            panel.closeFunc()
        end
        panel.isOpen = false
    end
    currentOpenPanel = nil
end

return PanelManager
