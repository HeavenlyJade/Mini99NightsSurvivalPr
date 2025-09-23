------------------------------------------------------------------------------------
-- -*- coding: utf-8 -*-
--
-- @作者:         zhenghao
-- @创建日期:      2025-09-05
-- @模块名称:      Item
-- @描述:         Item类
-- @版本:         v1.0
------------------------------------------------------------------------------------
-- 引入管理对象
local game = game
local MainStorage = game:GetService("MainStorage")
---@type ClassMgr
local ClassMgr = require(MainStorage.code.common.ClassMgr)
------------------------------------------------------------------------------------
---@class Item : Class
local _M = ClassMgr.Class('Item')

-- 初始化实例类
function _M:OnInit(info)
    self.itemType = nil
    self.amount = 0
    self.uuid = ""
    self.slot = nil

    -----------装备-----------

    self.quality = nil
    self.enhanceLevel = 0
end


---@param data SerializedItem 物品数据
function _M:Load(data)
    if not data or not data.itemType then
        return
    end
    self.uuid = data.uuid or ""
    self.amount = data.amount or 0
    self.enhanceLevel = data.el or 0
    self.itemType = data.itemType
end


---@param level number 强化等级
function _M:SetEnhanceLevel(level)
    if not self.itemType then
        return
    end

    local maxLevel = self.itemType.maxEnhanceLevel
    self.enhanceLevel = math.min(math.max(0, level), maxLevel)
end

---@return number 当前强化等级
function _M:GetEnhanceLevel()
    return self.enhanceLevel
end

---@return number 物品数量
function _M:GetAmount()
    return self.amount
end

---@param amount number 设置物品数量
function _M:SetAmount(amount)
    self.amount = math.max(0, amount)
end

---@return string 物品唯一标识
function _M:GetUUID()
    return self.uuid
end

---@return ItemQuality 物品品质
function _M:GetQuality()
    return self.quality
end

---@return number 物品等级
function _M:GetLevel()
    return self.level
end

---@return number 装备位置
function _M:GetPos()
    return self.pos
end

---@return string 物品类型
function _M:GetType()
    return self.itype
end

---@return string 物品名称
function _M:GetName()
    return self.itemType.name
end


return _M