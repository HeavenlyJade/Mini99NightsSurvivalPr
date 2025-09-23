------------------------------------------------------------------------------------
-- -*- coding: utf-8 -*-
--
-- @作者:         zhenghao
-- @创建日期:      2025-09-05
-- @模块名称:      ItemType
-- @描述:         ItemType类
-- @版本:         v1.0
------------------------------------------------------------------------------------
-- 引入管理对象
local game = game
local MainStorage = game:GetService("MainStorage")
---@type ClassMgr
local ClassMgr = require(MainStorage.code.common.ClassMgr)
---@type gg
local gg = require(MainStorage.code.common.MGlobal)
------------------------------------------------------------------------------------
---@class ItemType : Class
local _M = ClassMgr.Class('ItemType')

-- 初始化实例类
function _M:OnInit(info)
    -- 名字
    self.name = info["名字"] or ""
    -- 描述
    self.desc = info["描述"] or ""
    -- 详细属性
    self.detail = info["详细属性"] or ""
    -- 图标
    self.icon = info["图标"] or ""
    -- 品级
    self.rank = info["品级"] or "普通"
    -- 额外战力
    self.extraPower = info["额外战力"] or 0
    -- 强化等级
    self.EnhanceLevel = info["强化等级"] or 0
    -- 最大强化等级
    self.maxEnhanceLevel = info["最大强化等级"] or 0
    -- 属性
    self.attributes = info["属性"] or {}

    -- 位置
    self.pos = -1
    -- 颜色
    self.color = info["颜色"] or ColorQuad.New(255,255,255,255)

    -- 耐久度
    self.durability = info["耐久度"] or 100 --耐久度 每次使用损耗0.1
    -- 最大耐久度
    self.maxDurability = info["最大耐久度"] or 100 --耐久度 每次使用损耗0.1
    -- 需求职业
    self.NeedRole = info["需求职业"]
    -- 最大叠加数量
    self.StackableNum = info["最大叠加数量"]
    -- 类型
    self.itemType = info["类型"]
    -- 数量
    self.num = 0
    -- 攻击类型
    self.attackType = info["攻击类型"]
    -- 使用状态增益
    self.useState = info["使用状态增益"]
    -- 是否不可丢弃
    self.notDrop  = info["不可丢弃"]
    -- 容量
    self.Capacity = info["容量"]
    -- 显示准星
    self.showCrosshatch = info["显示准星"]
    -- 是否可手持
    self.canHand = info["可手持"]
    -- 弹药需求
    self.attackNeedItem = info["弹药需求"]
    -- 需求数量
    self.attackNeedItemNum = info["需求数量"]
    -- 弹药类型
    self.ammunitionType = info["弹药类型"]
    -- 增加数量
    self.ammunitionAddNum = info["增加数量"]
end



function _M:ToItem(count)
    local Item = require(MainStorage.code.server.entityTypes.Item) ---@type Item
    local item = Item.New()
    count = math.floor(count)
    item:Load({
        uuid = gg.create_uuid('item'),
        itemType = self,
        amount = count,
        el = 0,
        quality = ""
    })
    return item
end

return _M