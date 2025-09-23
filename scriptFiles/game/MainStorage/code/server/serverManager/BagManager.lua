------------------------------------------------------------------------------------
-- -*- coding: utf-8 -*-
--
-- @作者:         zhenghao
-- @创建日期:      2025-09-13
-- @模块名称:      BagManager
-- @描述:         背包管理
-- @版本:         v1.0
------------------------------------------------------------------------------------
-- 引入管理对象
local game = game
local MainStorage = game:GetService("MainStorage")
---@type ClassMgr
local ClassMgr = require(MainStorage.code.common.ClassMgr)
---@type NpcConfig
local NpcConfig = require(MainStorage.config.NpcConfig)
---@type gg
local gg = require(MainStorage.code.common.MGlobal)
---@type ServerEventManager
local ServerEventManager = require(MainStorage.code.server.serverEvent.ServerEventManager)
---@type NPC
local Npc = require(MainStorage.code.server.entityTypes.NPC)
---@type Entity
local Entity = require(MainStorage.code.server.entityTypes.Entity)
---@type common_const
local common_const = require(MainStorage.code.common.Const)
------------------------------------------------------------------------------------
-- 所有玩家的背包装备管理，服务器侧
---@class BagMgr
local BagMgr = {
}

--获得指定uin玩家的背包数据
function BagMgr.getPlayerBagData(uin_)
    return gg.getPlayerByUin(uin_)
end


--返回给客户端背包数据
function BagMgr.returnBagInfoByVer(uin, bagInfo)
    local ret_ = { cmd = 'PlayerUpFightUi', bagInfo = bagInfo }
    gg.network_channel:fireClient(uin, ret_)
end

--玩家获得一个物品
function BagMgr.tryGetItem(uin, item_info)
    -- 玩家信息
    local player_data = BagMgr.getPlayerBagData(uin)
    if not player_data then
        return -1
    end
    local canHand = item_info.itemType.canHand
    -- 不可手持物品
    if not canHand then
        local equipData = player_data.battle_data.bagInfo[player_data.curUseEquipIdx]
        if not equipData then
            return -1
        end
        if equipData.itemType.itemType ~= "袋子" then
            return -1
        end
        -- 容量
        local Capacity = equipData.itemType.Capacity
        if Capacity > 0 then
            local smallBagInfo = player_data.battle_data.smallBagInfo
            for i = 1, Capacity do
                local bagInfo = smallBagInfo[i]
                if table.is_empty(bagInfo) then
                    BagMgr.returnBagInfoByVer(uin, bagInfo)
                    bagInfo = item_info
                    return 1
                end
            end
        end
        return -1
    end
    local bigBagInfo = player_data.battle_data.bagInfo
    local canUsePos = 0
    -- 可叠加数量
    local StackableNum = item_info.itemType.StackableNum
    for bag_id = 1, 8 do
        local bagInfo = bigBagInfo[bag_id]
        if table.is_empty(bagInfo) then
            canUsePos = bag_id
        else
            if bagInfo.itemType.name == item_info.itemType.name then
                if bagInfo.amount + item_info.amount <= StackableNum then
                    canUsePos = bag_id
                    break
                end
            end
        end
    end
    if canUsePos > 0 then
        local bagInfo = bigBagInfo[canUsePos]
        if table.is_empty(bagInfo) then
            bagInfo = item_info
        else
            bagInfo.amount = bagInfo.amount + item_info.amount
        end
        BagMgr.returnBagInfoByVer(uin, bagInfo)
        return 1
    end
    return -1
end

--刷新玩家的背包数据 （ 服务器 to 客户端 ）
function BagMgr.s2c_PlayerBagItems(uin_, args1_)
    local player_data_ = BagMgr.getPlayerBagData(uin_)
    BagMgr.returnBagInfoByVer(uin_, player_data_, args1_.bag_ver)
end

return BagMgr