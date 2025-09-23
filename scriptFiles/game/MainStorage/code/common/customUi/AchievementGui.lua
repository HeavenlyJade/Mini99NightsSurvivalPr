local MainStorage = game:GetService('MainStorage')
-- 导入全局工具模块
local gg = require(MainStorage.code.common.MGlobal) ---@type gg
local ClassMgr = require(MainStorage.code.common.ClassMgr) ---@type ClassMgr
local CustomUI = require(MainStorage.code.common.customUi.CustomUI)    ---@type CustomUI
local ViewButton = require(MainStorage.code.client.Ui.ViewButton) ---@type ViewButton
---@type ViewList
local ViewList = require(MainStorage.code.client.Ui.ViewList)

---@class AchievementGui:CustomUI
local AchievementGui = ClassMgr.Class("AchievementGui", CustomUI)


-- 初始花UI
function AchievementGui:OnInit(data)
    self.achievementList = {
        {name = "保卫行动",level = 1,desc = "描述【保卫行动】内容",Title = "保卫行动",giftGem = 10,have = false,getGift = false },
        {name = "共同生存",level = 2,desc = "描述【共同生存】内容",Title = "共同生存",giftGem = 11,have = false,getGift = false},
        {name = "救援行动",level = 3,desc = "描述【救援行动】内容",Title = "救援行动",giftGem = 12,have = false,getGift = false},
        {name = "救治队友",level = 4,desc = "描述【救治队友】内容",Title = "救治队友",giftGem = 13,have = false,getGift = false},
        {name = "美食大师",level = 5,desc = "描述【美食大师】内容",Title = "美食大师",giftGem = 14,have = false,getGift = false},
        {name = "皮毛大师",level = 1,desc = "描述【皮毛大师】内容",Title = "皮毛大师",giftGem = 15,have = false,getGift = false},
        {name = "清剿行动",level = 2,desc = "描述【清剿行动】内容",Title = "清剿行动",giftGem = 16,have = false,getGift = false},
        {name = "升级工作台",level = 3,desc = "描述【升级工作台】内容",Title = "升级工作台",giftGem = 17,have = false,getGift = false},
        {name = "升级篝火",level = 4,desc = "描述【升级篝火】内容",Title = "升级篝火",giftGem = 18,have = false,getGift = false},
        {name = "生存大师",level = 5,desc = "描述【生存大师】内容",Title = "生存大师",giftGem = 19,have = false,getGift = false},

        {name = "生存萌新",level = 1,desc = "描述【生存萌新】内容",Title = "生存萌新",giftGem = 20,have = false,getGift = false},
        {name = "团队合作",level = 2,desc = "描述【团队合作】内容",Title = "团队合作",giftGem = 21,have = false,getGift = false},
        {name = "园艺大师",level = 3,desc = "描述【园艺大师】内容",Title = "园艺大师",giftGem = 22,have = false,getGift = false},
        {name = "制作工具",level = 4,desc = "描述【制作工具】内容",Title = "制作工具",giftGem = 23,have = false,getGift = false},
    }
    self.showAchievementData = {}
    self.playerCurTitle = ""
end

-- 服务端进入
function AchievementGui:S_BuildPacket(player, packet)
    local ret_t = {}
    local playerData = player.achievementData
    local playerTitle = player.myTitle
    for idx, data in pairs(self.achievementList) do
        local name = data.name
        if playerData[name] then
            data.have = true
            data.getGift = playerData[name].getGift
        end
        if playerTitle == data.Title then
            packet.showAchievementData = data
        end
        table.insert(ret_t,data)
    end
    packet.achievementList = ret_t
    packet.playerCurTitle = playerTitle
end


-- 展示成就
function AchievementGui:showAchievementTitle(player, evt)
    local playerData = player.achievementData
    local playerTitle = player.myTitle
    -- 当前佩戴成就就是
    if evt.showAchievementData.Title == playerTitle then
        return false
    end
    -- 没拥有这个成就
    if not playerData[evt.showAchievementData.name] then
        return false
    end
    -- 更新角色标签
    player.myTitle = evt.showAchievementData.Title
    -- 更新角色显示
    player:UpdateHud()
    -- 重新打开界面刷新显示
    self:S_Open(player)
end

-- 卸下成就
function AchievementGui:UnAchievementTitle(player, evt)
    -- 更新角色标签
    player.myTitle = ""
    -- 更新角色显示
    player:UpdateHud()
    -- 重新打开界面刷新显示
    self:S_Open(player)
end

-- 领取钻石
function AchievementGui:GetGemGift(player, evt)
    local playerData = player.achievementData
    -- 没拥有这个成就
    if not playerData[evt.AchievementData.name] then
        return false
    end
    -- 已经领取过
    if playerData[evt.AchievementData.name].getGift then
        return false
    end
    -- 更新领取
    player.achievementData[evt.AchievementData.name].getGift = true

    -- 增加钻石
    player.money.gemNum = player.money.gemNum + evt.AchievementData.giftGem
    -- 更新角色显示
    player:UpdateHud()
    -- 重新打开界面刷新显示
    self:S_Open(player)
end
-----------------客户端
-- 客户端进入
function AchievementGui:C_BuildUI(packet)
    -- 成就列表
    self.achievementList = packet.achievementList
    -- 显示成就
    self.showAchievementData = packet.showAchievementData
    -- 玩家当前称号
    self.playerCurTitle = packet.playerCurTitle

    -- 图标列表初始化
    self.IconList:SetElementSize(0)
    for index, AchievementData in ipairs(self.achievementList) do
        local child = self.IconList:GetChild(index, 1)
        local IconBtn = child:Get(self.paths.IconBtn, ViewButton)
        IconBtn.node.Icon = string.format("sandboxId://ui/成就ui/成就图标/%s.png",AchievementData.name)
        IconBtn:SetNormalImg(IconBtn.node.Icon)

        if AchievementData.have then
            IconBtn.node.Enabled = true
            IconBtn.node.Grayed = false
            if not AchievementData.getGift then
                child:Get(self.paths.GemImg).node.Visible = true
                child:Get(self.paths.GemNum).node.Visible = true
                child:Get(self.paths.GemNum).node.Title = string.format("x%s",AchievementData.giftGem)
                IconBtn.clickCb = function(ui, button)
                    self:C_SendEvent("GetGemGift", { AchievementData = AchievementData })
                end
            else
                child:Get(self.paths.GemImg).node.Visible = false
                child:Get(self.paths.GemNum).node.Visible = false
                IconBtn.clickCb = function(ui, button)
                    packet.showAchievementData = AchievementData
                    self:C_BuildUI(packet)
                end
            end
        else
            -- 设置灰度
            IconBtn.node.Enabled = false
            IconBtn.node.Grayed = true

            -- 隐藏钻石
            child:Get(self.paths.GemImg).node.Visible = false
            child:Get(self.paths.GemNum).node.Visible = false

            -- 点击事件
            IconBtn.clickCb = function(ui, button)
                packet.showAchievementData = AchievementData
                self:C_BuildUI(packet)
            end
        end

        child:Get(self.paths.SelectIcon).node.Visible = false
        if not table.is_empty(self.showAchievementData) then
            if self.showAchievementData.name == AchievementData.name then
                child:Get(self.paths.SelectIcon).node.Visible = true
            end
        end
        for i = 1, 5 do
            if AchievementData.level >= i then
                child:Get(self.paths["IconStart_" .. i]).node.Visible = true
            else
                child:Get(self.paths["IconStart_" .. i]).node.Visible = false
            end
            child:Get(self.paths["IconStartLayer_" .. i]).node.Visible = true
        end
    end

    if not table.is_empty(self.showAchievementData) then
        self.ShowIcon.Visible = true
        self.ShowIconTitle.Visible = true
        self.ShowIconDesc.Visible = true
        -- 展示图标
        self.ShowIcon.Icon = string.format("sandboxId://ui/成就ui/成就图标/%s.png",self.showAchievementData.name)
        -- 展示图标 称号
        self.ShowIconTitle.Title = self.showAchievementData.Title
        -- 展示图标 描述
        self.ShowIconDesc.Title = self.showAchievementData.desc
        for i = 1, 5 do
            if self.showAchievementData.level >= i then
                self["ShowIconStart_" .. i].Visible = true
            else
                self["ShowIconStart_" .. i].Visible = false
            end
            self["ShowIconStartLayer_" .. i].Visible = true
        end

        if self.showAchievementData.Title == self.playerCurTitle then
            self.ShowIcon.Grayed = false
            self.ShowBtn.img.Visible = false
            self.NotShowBtn.img.Visible = true
        else
            if self.showAchievementData.have then
                self.ShowIcon.Grayed = false
                self.ShowBtn.img.Visible = true
                self.NotShowBtn.img.Visible = false
            else

                self.ShowIcon.Grayed = true
                self.ShowBtn.img.Visible = false
                self.NotShowBtn.img.Visible = false
            end
        end
    else
        self.ShowIcon.Visible = false
        self.ShowIconTitle.Visible = false
        self.ShowIconDesc.Visible = false
        self.ShowBtn.img.Visible = false
        self.NotShowBtn.img.Visible = false
        for i = 1, 5 do
            self["ShowIconStartLayer_" .. i].Visible = false
            self["ShowIconStart_" .. i].Visible = false
        end
    end
end

-- 初始化Ui
function AchievementGui:C_InitUI()
    local AchievementUi = self.view
    local AchievementPaths = self.paths
    local ui_size = gg.get_ui_size()
    AchievementUi:Get("背景").node.Size = Vector2.New(ui_size.x, ui_size.y)

    -- 注册关闭事件
    AchievementUi:Get(AchievementPaths.CloseButton, ViewButton).clickCb = function(ui, button)
        AchievementUi:Close()
    end
    -- 展示图标
    self.ShowIcon = AchievementUi:Get(AchievementPaths.ShowIcon).node
    -- 展示图标 称号
    self.ShowIconTitle = AchievementUi:Get(AchievementPaths.ShowIconTitle).node
    -- 展示图标 描述
    self.ShowIconDesc = AchievementUi:Get(AchievementPaths.ShowIconDesc).node
    -- 展示图标 星星底图
    self.ShowIconStartLayer_1 = AchievementUi:Get(AchievementPaths.ShowIconStartLayer_1).node
    self.ShowIconStartLayer_2 = AchievementUi:Get(AchievementPaths.ShowIconStartLayer_1).node
    self.ShowIconStartLayer_3 = AchievementUi:Get(AchievementPaths.ShowIconStartLayer_1).node
    self.ShowIconStartLayer_4 = AchievementUi:Get(AchievementPaths.ShowIconStartLayer_1).node
    self.ShowIconStartLayer_5 = AchievementUi:Get(AchievementPaths.ShowIconStartLayer_1).node
    -- 展示图标 星星
    self.ShowIconStart_1 = AchievementUi:Get(AchievementPaths.ShowIconStart_1).node
    self.ShowIconStart_2 = AchievementUi:Get(AchievementPaths.ShowIconStart_2).node
    self.ShowIconStart_3 = AchievementUi:Get(AchievementPaths.ShowIconStart_3).node
    self.ShowIconStart_4 = AchievementUi:Get(AchievementPaths.ShowIconStart_4).node
    self.ShowIconStart_5 = AchievementUi:Get(AchievementPaths.ShowIconStart_5).node

    -- 级别列表 右边底图/级别列表
    self.IconList = AchievementUi:Get(AchievementPaths.IconList, ViewList, function(child, childPath)
        local c = ViewButton.New(child, AchievementUi, childPath)
        return c
    end)
    -- 展示按钮
    self.ShowBtn = AchievementUi:Get(AchievementPaths.ShowBtn, ViewButton)
    self.ShowBtn.clickCb = function(ui, button)
        self:C_SendEvent("showAchievementTitle", { showAchievementData = self.showAchievementData})
    end

    -- 卸下按钮
    self.NotShowBtn = AchievementUi:Get(AchievementPaths.NotShowBtn, ViewButton)
    self.NotShowBtn.clickCb = function(ui, button)
        self:C_SendEvent("UnAchievementTitle", { })
    end
end

return AchievementGui