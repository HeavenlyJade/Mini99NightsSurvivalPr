local game = game
local MainStorage = game:GetService("MainStorage")
local ClassMgr = require(MainStorage.code.common.ClassMgr) ---@type ClassMgr
local ViewBase = require(MainStorage.code.client.Ui.ViewBase) ---@type ViewBase
---@type ClientEventManager
local ClientEventManager = require(MainStorage.code.client.clientEvent.ClientEventManager)
local CustomUIConfig = require(MainStorage.config.CustomUIConfig) ---@type CustomUIConfig

---@class ClientCustomUI:ViewBase
local ClientCustomUI = ClassMgr.Class("ClientCustomUI", ViewBase)

function ClientCustomUI.Load(node, initFunc)
    local uiConfig = {
        uiName = node.Name,
        layer = 1,
        hideOnInit = true,
    }
    local ui = ClientCustomUI.New(node, uiConfig, initFunc)
    return ui
end

function ClientCustomUI:OnInit(node, uiConfig, initFunc)
    ViewBase.allUI[node.Name] = self
    local paths = {}
    if initFunc then
        paths = initFunc()
    end
    ClientEventManager.Subscribe("ViewCustomUI"..node.Name, function (evt)
        local customUI = CustomUIConfig.Get(evt.id)
        customUI.paths = paths
        customUI.view = self
        if not customUI.initUi then
            customUI.initUi = true
            --初始化UI控件
            customUI:C_InitUI()
        end
        customUI:C_BuildUI(evt)
        self:Open()
    end)
end

return ClientCustomUI