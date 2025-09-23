local MainStorage  = game:GetService('MainStorage')
local ClassMgr = require(MainStorage.code.common.ClassMgr) ---@type ClassMgr
local ServerEventManager = require(MainStorage.code.server.serverEvent.ServerEventManager) ---@type ServerEventManager

-- ItemType class
---@class CustomUI:Class
---@field New fun( data:table ):CustomUI
local CustomUI = ClassMgr.Class("CustomUI")

-- 初始化ui
function CustomUI.Load(data)
    local uiClass = require(MainStorage.code.common.customUi[data["UI名"]])
    return uiClass.New(data)
end

function CustomUI:OnInit(data)
    self.id = data["ID"]
    self.uiName = data["UI名"]
    self.miscData = data
    self._serverInitUi = false
    self.view = nil ---@type ViewBase
    self.paths = {}
end

---@param player Player
function CustomUI:S_Open(player)
    if not self._serverInitUi then
        self._serverInitUi = true
        ServerEventManager.Subscribe("CustomUIEvent_".. self.id, function (evt)
            if evt.__func then
                self[evt.__func](self, evt.player, evt)
            end
        end)
    end
    local packet = {
        id = self.id,
        uiName = self.uiName,
    }
    self:S_BuildPacket(player, packet)
    player:SendEvent("ViewCustomUI"..self.uiName, packet)
end

--初始化UI控件
function CustomUI:C_InitUI()

end

function CustomUI:C_SendEvent(func, packet)
    local ClientEventManager = require(MainStorage.code.client.clientEvent.ClientEventManager) ---@type ClientEventManager
    packet.__func = func
    ClientEventManager.SendToServer("CustomUIEvent_".. self.id, packet)
end

return CustomUI