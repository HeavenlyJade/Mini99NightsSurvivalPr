local MainStorage = game:GetService('MainStorage')
local cloudService = game:GetService("CloudService")   ---@type CloudService
-- 导入全局工具模块
local gg = require(MainStorage.code.common.MGlobal) ---@type gg
local ClassMgr = require(MainStorage.code.common.ClassMgr) ---@type ClassMgr
local CustomUI = require(MainStorage.code.common.customUi.CustomUI)    ---@type CustomUI
local ViewButton = require(MainStorage.code.client.Ui.ViewButton) ---@type ViewButton
local ViewList = require(MainStorage.code.client.Ui.ViewList) ---@type ViewList
local ClientEventManager = require(MainStorage.code.client.clientEvent.ClientEventManager) ---@type ClientEventManager

-- 导入服务器事件管理器
local ServerEventManager = require(MainStorage.code.server.serverEvent.ServerEventManager) ---@type ServerEventManager

---@class Ranking:CustomUI
local Ranking = ClassMgr.Class("Ranking", CustomUI)


-- 初始花UI
function Ranking:OnInit(data)

end

-- 服务端进入
function Ranking:S_BuildPacket(player, packet)

end

-----------------客户端
-- 客户端进入
function Ranking:C_BuildUI(packet)
    local ui_size = gg.get_ui_size()
    self.view:Get("背景").node.Size = Vector2.New(ui_size.x, ui_size.y)
    if not self._testValueRegistered then
        local RankingUi = self.view
        local RankingPaths = self.paths
        -- 注册关闭事件
        RankingUi:Get(RankingPaths.RankingCloseButton, ViewButton).clickCb = function(ui, button)
            RankingUi:Close()
        end
        self._testValueRegistered = true
    end
end

return Ranking