local MainStorage = game:GetService('MainStorage')
-- 导入全局工具模块
local gg = require(MainStorage.code.common.MGlobal) ---@type gg
local ClassMgr = require(MainStorage.code.common.ClassMgr) ---@type ClassMgr
local CustomUI = require(MainStorage.code.common.customUi.CustomUI)    ---@type CustomUI
---@type ViewButton
local ViewButton = require(MainStorage.code.client.Ui.ViewButton)
---@type LevelConfig
local LevelConfig = require(MainStorage.config.LevelConfig)
---@type ClientEventManager
local ClientEventManager = require(MainStorage.code.client.clientEvent.ClientEventManager)

---@class MatchGui:CustomUI
local MatchGui = ClassMgr.Class("MatchGui", CustomUI)


-- 初始花UI
function MatchGui:OnInit(data)

end

-- 服务端进入
function MatchGui:S_BuildPacket(player, packet)

end

---@param player Player
function MatchGui:onEnterDungeon(player, args)
    local levelType = LevelConfig.GetNearLevel(player)
    if levelType then
        local suc, reason = levelType:CanJoin(player,args.startNum)
        if not suc then
            return
        end
        levelType:JoinQueue(player)
    end
end
-----------------客户端
-- 客户端进入
function MatchGui:C_BuildUI(packet)

end

-- 初始化Ui
function MatchGui:C_InitUI()
    local MatchUi = self.view
    local MatchPaths = self.paths
    local ui_size = gg.get_ui_size()
    MatchUi:Get("背景").node.Size = Vector2.New(ui_size.x, ui_size.y)
    MatchUi:Get(MatchPaths.CreateTeam_1, ViewButton).clickCb = function(ui, button)
        --ClientEventManager.SendToServer("PlayerSelectNum", {
        --    startNum = 1,
        --})
        self:C_SendEvent("onEnterDungeon", {startNum = 1})
        MatchUi:Close()
    end
    MatchUi:Get(MatchPaths.CreateTeam_2, ViewButton).clickCb = function(ui, button)
        --ClientEventManager.SendToServer("PlayerSelectNum", {
        --    startNum = 2,
        --})
        self:C_SendEvent("onEnterDungeon", {startNum = 2})
        MatchUi:Close()
    end
    MatchUi:Get(MatchPaths.CreateTeam_3, ViewButton).clickCb = function(ui, button)
        --ClientEventManager.SendToServer("PlayerSelectNum", {
        --    startNum = 3,
        --})
        self:C_SendEvent("onEnterDungeon", {startNum = 3})
        MatchUi:Close()
    end
    MatchUi:Get(MatchPaths.CreateTeam_4, ViewButton).clickCb = function(ui, button)
        --ClientEventManager.SendToServer("PlayerSelectNum", {
        --    startNum = 4,
        --})
        self:C_SendEvent("onEnterDungeon", {startNum = 4})
        MatchUi:Close()
    end
    MatchUi:Get(MatchPaths.CreateTeam_5, ViewButton).clickCb = function(ui, button)
        --ClientEventManager.SendToServer("PlayerSelectNum", {
        --    startNum = 5,
        --})
        self:C_SendEvent("onEnterDungeon", {startNum = 5})
        MatchUi:Close()
    end
end

return MatchGui