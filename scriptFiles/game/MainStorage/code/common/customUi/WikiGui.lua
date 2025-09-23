local MainStorage = game:GetService('MainStorage')
-- 导入全局工具模块
local gg = require(MainStorage.code.common.MGlobal) ---@type gg
local ClassMgr = require(MainStorage.code.common.ClassMgr) ---@type ClassMgr
local CustomUI = require(MainStorage.code.common.customUi.CustomUI)    ---@type CustomUI
local ViewButton = require(MainStorage.code.client.Ui.ViewButton) ---@type ViewButton

---@class WikiGui:CustomUI
local WikiGui = ClassMgr.Class("WikiGui", CustomUI)


-- 初始花UI
function WikiGui:OnInit(data)

end

-- 服务端进入
function WikiGui:S_BuildPacket(player, packet)

end

-----------------客户端
-- 客户端进入
function WikiGui:C_BuildUI(packet)
    local ui_size = gg.get_ui_size()
    self.view:Get("背景").node.Size = Vector2.New(ui_size.x, ui_size.y)

    if not self._testValueRegistered then
        local WikiUi = self.view
        local WikiPaths = self.paths
        -- 注册关闭事件
        WikiUi:Get(WikiPaths.CloseButton, ViewButton).clickCb = function(ui, button)
            WikiUi:Close()
        end
        self._testValueRegistered = true
    end
end

return WikiGui