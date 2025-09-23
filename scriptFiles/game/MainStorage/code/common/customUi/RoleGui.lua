local MainStorage = game:GetService('MainStorage')
local ColorQuad = ColorQuad
-- 导入全局工具模块
local gg = require(MainStorage.code.common.MGlobal) ---@type gg
local ClassMgr = require(MainStorage.code.common.ClassMgr) ---@type ClassMgr
local CustomUI = require(MainStorage.code.common.customUi.CustomUI)    ---@type CustomUI
local ViewButton = require(MainStorage.code.client.Ui.ViewButton) ---@type ViewButton
---@type ViewList
local ViewList = require(MainStorage.code.client.Ui.ViewList)
---@class RoleGui:CustomUI
local RoleGui = ClassMgr.Class("RoleGui", CustomUI)
---@type common_const
local common_const = require(MainStorage.code.common.Const)

-- 初始花UI
function RoleGui:OnInit(data)
    -- 职业列表
    self.roleList = data["职业配置"]["职业列表"]
    -- 玩家当前佩戴职业
    self.curRole = ""
    -- 最后一次选择
    self.lastSelect = nil
    -- 刷新天赋价格 30
    self.RefreshTalentPrice = data["职业配置"]["价格表"]["刷新天赋价格"] or 30
    -- 刷新商店价格 30
    self.RefreshShopPrice = data["职业配置"]["价格表"]["刷新商店价格"] or 30
    -- 解锁天赋等级 90
    self.UnlockTalentLevelPrice = data["职业配置"]["价格表"]["解锁天赋等级价格"] or 90
    -- 解锁天赋 60
    self.UnlockTalentPrice = data["职业配置"]["价格表"]["解锁天赋价格"] or 60
end

-- 服务端进入
function RoleGui:S_BuildPacket(player, packet)
    -- 职业信息表
    local ret_t = {}
    local playerRole = player.job
    -- 玩家职业信息表
    local jobData = player.jobData
    -- 玩家商店随机职业
    local shopJobData = player.shopRandomJobData.roleList
    -- 遍历职业信息
    for roleName, roleData in pairs(self.roleList) do
        local name = roleData["名称"]
        -- 基础信息
        local tmp_t = roleData
        -- 是否佩戴
        tmp_t["佩戴"] = playerRole == name
        -- 是否拥有
        tmp_t["拥有"] = jobData[name] and true or false
        -- 是否在库
        tmp_t["在库"] = shopJobData[name] and true or false
        if not tmp_t["在库"] and tmp_t["拥有"] then
            tmp_t["在库"] = true
        end
        -- 天赋阶段
        tmp_t["天赋阶段"] = tmp_t["拥有"] and jobData[name]["天赋阶段"] or 1
        -- 天赋
        tmp_t["天赋"] = tmp_t["拥有"] and jobData[name]["天赋"] or nil
        table.insert(ret_t, tmp_t)
    end
    -- 执行排序：先按"拥有"升序，再按"星级"升序
    table.sort(ret_t, function(a, b)
        if a["佩戴"] ~= b["佩戴"] then
            return a["佩戴"] and not b["佩戴"]
        elseif a["拥有"] ~= b["拥有"] then
            -- 如果a是true而b是false，a排在前面
            return a["拥有"] and not b["拥有"]
        elseif a["在库"] ~= b["在库"] then
            return a["在库"] and not b["在库"]
        else
            -- 当拥有字段相同时，按星级从小到大排序
            return a["星级"] < b["星级"]
        end
    end)

    -- 当前职业
    if playerRole and playerRole ~= "" then
        packet.curRole = playerRole
    elseif ret_t[1] and ret_t[1]["名称"] then
        packet.curRole = ret_t[1]["名称"]
    end
    -- 职业列表
    packet.roleList = ret_t
end


-- 购买职业
function RoleGui:BuyRole(player, evt)
    local roleData = player.jobData[evt.role]
    -- 已拥有该职业
    if roleData then
        player:SendHoverText("已拥有该职业")
        return
    end
    if player.money.gemNum < evt.price then
        player:SendHoverText("购买角色失败,钻石不足")
        return
    end
    -- 增加玩家角色
    player.jobData[evt.role] = { ["天赋阶段"] = 1 }
    -- 扣除钻石
    player.money.gemNum = player.money.gemNum - evt.price
    -- 更新角色显示
    player:UpdateHud()
    -- 显示消息
    player:SendHoverText("购买角色%s成功！", evt.role)
    -- 重新打开界面刷新显示
    self:S_Open(player)
end


-- 卸下职业
function RoleGui:UnloadRole(player, evt)
    if evt.role ~= player.job then
        return
    end
    -- 更新角色职业为空
    player.job = ""
    -- 更新角色显示
    player:UpdateHud()
    -- 显示消息
    player:SendHoverText("卸下职业:%s", evt.role)
    -- 重新打开界面刷新显示
    self:S_Open(player)
end

-- 切换/佩戴职业
function RoleGui:SwitchRole(player, evt)
    local roleData = player.jobData[evt.role]
    -- 未拥有该职业
    if not roleData then
        player:SendHoverText("佩戴失败,未拥有该职业")
        return
    end
    -- 更新角色职业为指定职业
    player.job = evt.role
    -- 显示消息
    player:UpdateHud()
    -- 显示消息
    player:SendHoverText("佩戴职业:%s", evt.role)
    -- 重新打开界面刷新显示
    self:S_Open(player)
end

-- 解锁天赋等级
function RoleGui:UnlockRoleLevel(player, evt)
    -- 金币不足
    if player.money.gemNum < evt.price then
        player:SendHoverText("解锁失败,钻石不足")
        return
    end
    local roleData = player.jobData[evt.role]
    -- 未拥有该职业
    if not roleData then
        player:SendHoverText("解锁失败,未拥有该职业")
        return
    end
    local talentLevel = roleData["天赋阶段"]
    -- 阶段已解锁
    if talentLevel + 1 > evt.level then
        player:SendHoverText("该阶段已解锁,请勿重复解锁")
        return
    end
    -- 需解锁上一阶段
    if talentLevel + 1 < evt.level then
        player:SendHoverText("解锁失败,需解锁上一阶段")
        return
    end
    -- 阶段提升
    player.jobData[evt.role]["天赋阶段"] = evt.level
    -- 扣除钻石
    player.money.gemNum = player.money.gemNum - evt.price
    -- 更新角色显示
    player:UpdateHud()
    -- 显示消息
    player:SendHoverText("解锁%s到%s级成功！", evt.role, evt.level)
    -- 重新打开界面刷新显示
    self:S_Open(player)
end

-- 解锁天赋
function RoleGui:RoleLockedTalent(player, evt)
    if player.money.gemNum < evt.price then
        player:SendHoverText("解锁失败,钻石不足")
        return
    end
    local roleData = player.jobData[evt.role]
    -- 未拥有该职业
    if not roleData then
        player:SendHoverText("解锁失败,未拥有该职业")
        return
    end
    if roleData["天赋阶段"] < 3 then
        player:SendHoverText("解锁失败,需要天赋达到3阶")
        return
    end
    if roleData["天赋"] then
        player:SendHoverText("解锁失败,该职业已拥有天赋")
        return
    end
    -- 可随机天赋列表
    local list = self.roleList[evt.role]["可随机天赋"]
    if table.is_empty(list) then
        player:SendHoverText("解锁失败,该职业没有可随机天赋列表")
        return
    end
    -- 随机天赋 TODO:按照概率星级
    roleData["天赋"] = list[math.random(1, #list)]
    -- 扣除钻石
    player.money.gemNum = player.money.gemNum - evt.price
    -- 更新角色显示
    player:UpdateHud()
    -- 显示消息
    player:SendHoverText("解锁%s天赋成功！", evt.role)
    -- 重新打开界面刷新显示
    self:S_Open(player)
end

-- 刷新天赋
function RoleGui:RoleRefreshTalent(player, evt)
    if player.money.gemNum < evt.price then
        player:SendHoverText("解锁失败,钻石不足")
        return
    end
    local roleData = player.jobData[evt.role]
    -- 未拥有该职业
    if not roleData then
        player:SendHoverText("解锁失败,未拥有该职业")
        return
    end
    if roleData["天赋阶段"] < 3 then
        player:SendHoverText("刷新失败,需要天赋达到3阶")
        return
    end
    if not roleData["天赋"] then
        player:SendHoverText("刷新失败,该职业未解锁天赋")
        return
    end
    -- 当前职业天赋
    local curRoleTalent = roleData["天赋"]
    -- 当前职业天赋 职业
    local role = curRoleTalent.role
    -- 当前职业天赋 描述
    local desc = curRoleTalent.desc
    -- 可随机天赋列表
    local list = self.roleList[evt.role]["可随机天赋"]
    -- TODO：移除当前天赋？重新随机
    -- 随机一个当前天赋外的天赋
    while roleData["天赋"].role == role and desc == roleData["天赋"].desc do
        roleData["天赋"] = list[math.random(1, #list)]
    end
    -- 扣除钻石
    player.money.gemNum = player.money.gemNum - evt.price
    -- 更新角色显示
    player:UpdateHud()
    -- 显示消息
    player:SendHoverText("随机%s天赋成功！", evt.role)
    -- 重新打开界面刷新显示
    self:S_Open(player)
end

-- 重新打开界面刷新显示
function RoleGui:refreshStoreUi(player)
    self:S_Open(player)
end

-- 刷新商店
function RoleGui:refreshStoreRole(player,evt)
    if player.money.gemNum < evt.price then
        player:SendHoverText("刷新失败,钻石不足")
        return
    end
    -- 扣除钻石
    player.money.gemNum = player.money.gemNum - evt.price
    -- 更新角色显示
    player:UpdateHud()
    -- 随机角色
    player:RandomJobShop()
    -- 显示消息
    player:SendHoverText("刷新商店成功！")
    self:S_Open(player)
end

-----------------客户端

-- 客户端进入
function RoleGui:C_BuildUI(packet)
    -- 职业列表
    self.roleList = packet.roleList
    -- 玩家当前佩戴职业
    self.curRole = packet.curRole
    -- 上次打开界面的职业
    self.lastSelect = self:GetLastSelectRole()
    -- 上次打开角色
    self.roleData = self:GetLastSelectRoleData()
    -- 更新左侧
    self:SetSelectRoleList()

    -- 更新中间
    local roleData = self.roleData
    -- 需求
    self.RoleUpDemand.Title = string.format("%s级别要求", roleData["天赋阶段"])
    -- 需求列表
    local needList = roleData["需求"][roleData["天赋阶段"]]
    -- 显示需求
    self:ShowRoleNeedList(needList)

    ---- 展示模型
    --self.RoleModel.ModelId = roleData["模型"]

    self.RoleImg.Icon = roleData["立绘"] or string.format("sandboxId://ui/职业ui/职业立绘/%s.png",roleData["名称"])
    -- 显示按钮
    self:ShowRoleSelectBtn(roleData)

    --更新右边
    local GameEquipList = roleData["开局工具"]
    -- 级别属性
    local LevelList = roleData["级别属性"]
    -- 天赋
    local roleTalent = roleData["天赋"]
    -- 开局工具列表
    self:ShowGameEquip(GameEquipList)
    -- 显示开局天赋列表
    self:ShowLevelTalentList(LevelList,roleData)
    -- 显示额外天赋
    self:ShowTalent(roleTalent)
end


function RoleGui:SetSelectRoleList()
    local RoleUi = self.view
    local RolePaths = self.paths
    self.RoleSelectList:SetElementSize(0)
    for index, RoleData in ipairs(self.roleList) do
        gg.log("[%s] 佩戴[%s] 在库[%s] 拥有[%s] [星级：%s]",RoleData["名称"],RoleData["佩戴"],RoleData["在库"],RoleData["拥有"],RoleData["星级"])
        local show = false
        if RoleUi:Get(RolePaths.onlyShowOwned).node.Visible then
            if RoleData["拥有"] then
                show = true
            end
        else
            show = true
        end
        if show then
            local child = nil
            if RoleData["拥有"] then
                child = self.RoleSelectList:GetChild(index, 1)
            else
                child = self.RoleSelectList:GetChild(index, 2)
            end
            -- 名称
            local name = RoleData["名称"]
            -- 图标
            local icon = common_const.JOB_ICON[name] or RoleData.Icon
            -- 星级
            local level = RoleData["星级"]

            -- 职业名称
            child:Get(RolePaths.RoleName).node.Title = name

            -- 职业头像
            child:Get(RolePaths.RoleHead).node.Icon = icon
            -- 星级
            local StartList = child:Get(RolePaths.StartList, ViewList, function(child_, childPath)
                local c = ViewButton.New(child_, RoleUi, childPath)
                return c
            end)
            StartList:SetElementSize(0)
            for i = 1, level do
                StartList:GetChild(i, 1)
            end
            -- 选择条
            local YellowSelectVisible = false
            -- 选择三角形
            local SelectImgVisible = false
            if self.lastSelect then
                if self.lastSelect == name then
                    YellowSelectVisible = true
                    SelectImgVisible = true
                end
            else
                if RoleData["佩戴"] then
                    YellowSelectVisible = true
                    SelectImgVisible = true
                end
            end
            -- 已拥有勾选
            child:Get(RolePaths.HaveRoleImg).node.Visible = RoleData["拥有"]
            if RoleData["拥有"] then
                -- 已拥有
                child:Get(RolePaths.HaveRole).node.Visible = true

                child:Get(RolePaths.RolePriceSelect).node.Visible = false
                child:Get(RolePaths.RolePrice).node.Title = tostring(RoleData["价格"])
            else
                child:Get(RolePaths.HaveRole).node.Visible = false
                child:Get(RolePaths.RolePriceSelect).node.Visible = true
                child:Get(RolePaths.RolePrice).node.Title = tostring(RoleData["价格"])
            end
            if RoleData["佩戴"] then
                child:Get(RolePaths.EquipRole).node.Icon = "sandboxId://ui/职业ui/拥有/已装备.png"
            elseif RoleData["在库"] then
                child:Get(RolePaths.EquipRole).node.Icon = "sandboxId://ui/职业ui/拥有/在库.png"
            elseif RoleData["拥有"] then
                child:Get(RolePaths.EquipRole).node.Icon = "sandboxId://ui/职业ui/拥有/在库.png"
            else
                child:Get(RolePaths.EquipRole).node.Icon = "sandboxId://ui/职业ui/拥有/未在库.png"
            end
            -- 选择条
            child:Get(RolePaths.YellowSelect).node.Visible = YellowSelectVisible
            -- 选择三角形
            child:Get(RolePaths.SelectImg).node.Visible = SelectImgVisible
        end
    end
end

-- 获取上次选择角色信息
function RoleGui:GetLastSelectRoleData()
    for index, RoleData in ipairs(self.roleList) do
        if self.lastSelect == RoleData["名称"] then
            return RoleData
        end
    end
    return {}
end

-- 获取上次选择角色
function RoleGui:GetLastSelectRole()
    -- 优先上次之选择
    -- 其次当前角色佩戴职业
    -- 最后列表第一职业
    local lastSelect = self.lastSelect or self.curRole
    if lastSelect == "" then
        lastSelect = self.roleList[1]["名称"]
    end
    return lastSelect
end

-- 显示角色需求列表
function RoleGui:ShowRoleNeedList(needList)
    -- 需求列表
    self.UpDemandList:SetElementSize(0)
    if not table.is_empty(needList) then
        for index, needData in ipairs(needList) do
            local child = self.UpDemandList:GetChild(index, 1)
            child:Get(self.paths.DemandDetails).node.Title = needData.name
            child:Get(self.paths.DemandProgress).node.Title = string.format("0/%s", needData.val)
        end
    end

end

-- 显示按钮
function RoleGui:ShowRoleSelectBtn(roleData)
    if roleData["佩戴"] then
        -- 卸下装备
        self.UnloadButton.node.Visible = true
        -- 装备按钮
        self.EquipButton.node.Visible = false
        -- 购买按钮
        self.buyButton.node.Visible = false
    elseif roleData["拥有"] then
        -- 卸下装备
        self.UnloadButton.node.Visible = false
        -- 装备按钮
        self.EquipButton.node.Visible = true
        -- 购买按钮
        self.buyButton.node.Visible = false
    elseif roleData["在库"] then
        -- 卸下装备
        self.UnloadButton.node.Visible = false
        -- 装备按钮
        self.EquipButton.node.Visible = false
        -- 购买按钮
        self.buyButton.node.Visible = true
        -- 购买价格
        self.BuyPrice.Title = string.format("购买:%s钻石", roleData["价格"])
    else
        self.UnloadButton.node.Visible = false
        -- 装备按钮
        self.EquipButton.node.Visible = false
        -- 购买按钮
        self.buyButton.node.Visible = false
    end
end

-- 显示开局工具
function RoleGui:ShowGameEquip(GameEquipList)
    self.GameEquipList:SetElementSize(0)
    for index, equipData in ipairs(GameEquipList) do
        local child = self.GameEquipList:GetChild(index, 1)
        child.node.Icon = equipData.Icon
        child:Get(self.paths.Num).node.Title = string.format("x%s", equipData.num)
        child:Get(self.paths.Name).node.Title = equipData.name
    end
end

-- 显示开局天赋列表
function RoleGui:ShowLevelTalentList(LevelList,roleData)
    -- 等级 天赋列表
    self.LevelList:SetElementSize(0)
    for index, LevelData in ipairs(LevelList) do
        -- 解锁
        local unLocked = false
        if roleData["拥有"] then
            if roleData["天赋阶段"] >= index then
                unLocked = true
            end
        end
        local child = self.LevelList:GetChild(index, 1)
        child:Get(self.paths.LockedImg).node.Visible = not unLocked
        local UnlockBtn = child:Get(self.paths.UnlockImg, ViewButton)
        UnlockBtn.node.Visible = not unLocked
        UnlockBtn.clickCb = function(ui, button)
            self:C_SendEvent("UnlockRoleLevel", { role = self.lastSelect, level = index, price =  self.UnlockTalentLevelPrice })
        end

        child:Get(self.paths.LevelText).node.Title = tostring(index)
        if unLocked then
            child:Get(self.paths.LevelText).node.TitleColor = ColorQuad.New(255, 255, 255, 255)
        else
            child:Get(self.paths.LevelText).node.TitleColor = ColorQuad.New(255, 255, 255, 155)
        end
        -- 星级
        local AttrList = child:Get(self.paths.AttrList, ViewList, function(child_, childPath)
            local c = ViewButton.New(child_, self.view, childPath)
            return c
        end)
        AttrList:SetElementSize(0)
        local attrList = LevelData
        for i, v in ipairs(attrList) do
            local child_ = AttrList:GetChild(i, 1)
            child_.node.Title = v.desc
            if unLocked then
                child_.node.TitleColor = ColorQuad.New(255, 255, 255, 255)
            else
                child_.node.TitleColor = ColorQuad.New(255, 255, 255, 155)
            end
        end
    end
end

function RoleGui:ShowTalent(roleTalent)
    if not table.is_empty(roleTalent) then
        self.UnlockedTalent.Visible = false
        self.LockedTalent.Visible = true
        self.TalentRoleHead.Icon = common_const.JOB_ICON[roleTalent.role]
        self.TalentReadme.Title = roleTalent.desc
        self.ProbabilityReadmeUi.Visible = false
    else
        self.UnlockedTalent.Visible = true
        self.LockedTalent.Visible = false
        self.ProbabilityReadmeUi.Visible = false
    end
end


-- 初始化Ui
function RoleGui:C_InitUI()
    local RoleUi = self.view
    local RolePaths = self.paths
    local ui_size = gg.get_ui_size()
    RoleUi:Get("背景").node.Size = Vector2.New(ui_size.x, ui_size.y)
    -- 已拥有勾选图标 左边底图/显示已拥有/已拥有勾选
    self.onlyShowOwned = RoleUi:Get(RolePaths.onlyShowOwned).node

    -- 需求 中间/阶段需求框/需求
    self.RoleUpDemand = RoleUi:Get(RolePaths.RoleUpDemand).node
    ---- 展示模型 中间/展示模型/职业模型
    --self.RoleModel = RoleUi:Get(RolePaths.RoleModel).node
    -- 展示立绘 中间/展示立绘
    self.RoleImg = RoleUi:Get(RolePaths.RoleImg).node
    -- 购买按钮 中间/购买/购买价格
    self.BuyPrice = RoleUi:Get(RolePaths.buyPrice).node

    -- 未解锁 右边底图/天赋/未解锁
    self.UnlockedTalent = RoleUi:Get(RolePaths.unlockedTalent).node
    -- 解锁 右边底图/天赋/解锁
    self.LockedTalent = RoleUi:Get(RolePaths.lockedTalent).node
    -- 概率说明 右边底图/天赋/概率说明
    self.ProbabilityReadmeUi = RoleUi:Get(RolePaths.ProbabilityReadmeUi).node
    -- 职业头像 右边底图/天赋/解锁/职业头像
    self.TalentRoleHead = RoleUi:Get(RolePaths.TalentRoleHead).node
    -- 额外天赋介绍 右边底图/天赋/解锁/介绍底图/额外天赋介绍
    self.TalentReadme = RoleUi:Get(RolePaths.TalentReadme).node

    -- 筛选拥有按钮 左边底图/显示已拥有
    RoleUi:Get(RolePaths.onlyShowOwnedButton, ViewButton).clickCb = function(ui, button)
        self.onlyShowOwned.Visible = (not self.onlyShowOwned.Visible)
        self:C_SendEvent("refreshStoreUi", {})
    end
    -- 刷新商店按钮 左边底图/刷新商店
    RoleUi:Get(RolePaths.refreshStoreButton, ViewButton).clickCb = function(ui, button)
        self:C_SendEvent("refreshStoreRole", {price = self.RefreshShopPrice})
    end

    -- 装备按钮 中间/装备
    self.EquipButton = RoleUi:Get(RolePaths.EquipButton, ViewButton)
    self.EquipButton.clickCb = function(ui, button)
        self:C_SendEvent("SwitchRole", { role = self.lastSelect, })
    end
    -- 卸下按钮 中间/卸下装备
    self.UnloadButton = RoleUi:Get(RolePaths.UnloadButton, ViewButton)
    self.UnloadButton.clickCb = function(ui, button)
        self:C_SendEvent("UnloadRole", { role = self.lastSelect, })
    end
    -- 购买按钮 中间/购买
    self.buyButton = RoleUi:Get(RolePaths.buyButton, ViewButton)
    self.buyButton.clickCb = function(ui, button)
        local Price = tonumber(string.match(self.BuyPrice.Title, "%d+"))  -- %d+ 匹配一个或多个数字
        self:C_SendEvent("BuyRole", { role = self.lastSelect, price = Price, })
    end

    -- 注册关闭事件 右边底图/关闭按钮
    RoleUi:Get(RolePaths.CloseButton, ViewButton).clickCb = function(ui, button)
        RoleUi:Close()
    end
    -- 解锁天赋 右边底图/天赋/未解锁/解锁天赋价格
    RoleUi:Get(RolePaths.unlockedTalentPriceButton, ViewButton).clickCb = function(ui, button)
        self:C_SendEvent("RoleLockedTalent", { role = self.lastSelect, price = self.UnlockTalentPrice })
    end
    -- 刷新天赋 右边底图/天赋/解锁/刷新天赋价格底图
    RoleUi:Get(RolePaths.refreshTalentPriceButton, ViewButton).clickCb = function(ui, button)
        self:C_SendEvent("RoleRefreshTalent", { role = self.lastSelect, price = self.RefreshTalentPrice })
    end
    -- 概率详情介绍 右边底图/天赋/概率详情介绍
    RoleUi:Get(RolePaths.ProbabilityReadme, ViewButton).clickCb = function(ui, button)
        self.UnlockedTalent.Visible = false
        self.LockedTalent.Visible = false
        self.ProbabilityReadmeUi.Visible = true
    end
    -- 概率关闭按钮 右边底图/天赋/概率说明/关闭按钮
    RoleUi:Get(RolePaths.ProbabilityReadmeClose, ViewButton).clickCb = function(ui, button)
        self.ProbabilityReadmeUi.Visible = false
        self:C_SendEvent("refreshStoreUi", {})
    end

    -- 角色选择列表 左边底图/角色选择列表
    self.RoleSelectList = RoleUi:Get(RolePaths.RoleSelectList, ViewList, function(child, childPath)
        local c = ViewButton.New(child, RoleUi, childPath)
        c.clickCb = function()
            -- 清空选中条
            self.RoleSelectList:cleanChildsSelect(RolePaths)
            -- 显示 选中黄条
            c:Get(RolePaths.SelectImg).node.Visible = true
            -- 显示 选中黄条
            c:Get(RolePaths.YellowSelect).node.Visible = true
            -- 最后一次选中名称
            self.lastSelect = c:Get(RolePaths.RoleName).node.Title
            self:C_SendEvent("refreshStoreUi", {})
        end
        return c
    end)

    -- 需求列表 中间/需求列表
    self.UpDemandList = RoleUi:Get(RolePaths.UpDemandList, ViewList, function(child, childPath)
        local c = ViewButton.New(child, RoleUi, childPath)
        return c
    end)

    -- 开局工具列表 右边底图/开局工具列表
    self.GameEquipList = RoleUi:Get(RolePaths.GameEquipList, ViewList, function(child, childPath)
        local c = ViewButton.New(child, RoleUi, childPath)
        return c
    end)
    -- 级别列表 右边底图/级别列表
    self.LevelList = RoleUi:Get(RolePaths.LevelList, ViewList, function(child, childPath)
        local c = ViewButton.New(child, RoleUi, childPath)
        return c
    end)
end

return RoleGui