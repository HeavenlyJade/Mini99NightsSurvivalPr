------------------------------------------------------------------------------------
-- -*- coding: utf-8 -*-
--
-- @作者:         zhenghao
-- @创建日期:      2025-09-22
-- @模块名称:      BagManager
-- @描述:         战斗属性管理
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
---@type RoleConfig
local RoleConfig =require(MainStorage.config.RoleConfig)
---@type ItemTypeConfig
local ItemTypeConfig = require(MainStorage.config.ItemConfig)
------------------------------------------------------------------------------------
-- 所有玩家的背包装备管理，服务器侧
---@class BattleDataManager
local BattleDataManager = {
}

-- 基础数值模板
BattleDataManager.default_player_battle_data = {
    hp = 100,               -- 当前生命值
    hp_max = 100,           -- 最大生命值
    hp_add = 0.2,           -- 每秒恢复血量速度

    hunger = 100,           -- 饥饿度
    hunger_max = 100,       -- 最大饥饿度
    hunger_reduced = 0.1,   -- 每秒减少饥饿度

    energy = 100,           -- 能量条
    energy_max = 100,       -- 最大能量条
    energy_add = 0.1,       -- 每秒恢复能量条

    attack = 0,             -- 攻击力
    defence = 0,            -- 防御力

    SurvivalDays = 0,       -- 生存天数

    interact_speed = 6,      -- 交互速度
    attack_speed = 500,     -- 攻击速度
    move_speed = 500,       -- 移动速度
    reload_speed = 0,        -- 换弹速度
    -- 背包信息
    bagInfo = {
        [1] = ItemTypeConfig.Get("袋子"):ToItem(1),
        [2] = ItemTypeConfig.Get("石斧"):ToItem(1),
        [3] = ItemTypeConfig.Get("樱桃"):ToItem(10),
        [4] = ItemTypeConfig.Get("牛仔左轮"):ToItem(1),
        [5] = ItemTypeConfig.Get("子弹"):ToItem(60),
    },
    -- 材料背包
    smallBagInfo = {

    },
    -- 子弹背包
    ammunitionBagInfo = {
        ["箭头"] = {["备弹"] = 0,["弹夹容量"] = 1,["弹药数量"] = 0,},
        ["子弹"] = {["备弹"] = 0,["弹夹容量"] = 6,["弹药数量"] = 0,},
        ["散弹"] = {["备弹"] = 0,["弹夹容量"] = 2,["弹药数量"] = 0,},
        ["步枪子弹"] = {["备弹"] = 0,["弹夹容量"] = 30,["弹药数量"] = 0,},
    },
}

-- 职业数值模板
BattleDataManager.default_player_role_battle_data = {}

-- 获取玩家属性表 通过职业
function BattleDataManager.GetPlayerBattleDataByRole(RoleName)
    local RoleData_ = RoleConfig.Get(RoleName)
    if not RoleData_ then
        BattleDataManager.default_player_role_battle_data = BattleDataManager.default_player_battle_data
        return
    end
    local RoleData = RoleData_["属性"]
    -- 职业修改属性
    for Attribute, val in pairs(BattleDataManager.default_player_battle_data) do
        BattleDataManager.default_player_role_battle_data[Attribute] = val
        for Attribute_, val_ in pairs( RoleData ) do
            if Attribute == Attribute_ then
                BattleDataManager.default_player_role_battle_data[Attribute] = val_
            end
        end
    end
end

function BattleDataManager.GetPlayerBattleDataByEquip(equipData)
    if table.is_empty(equipData) then
       return  BattleDataManager.default_player_role_battle_data
    end
    local ret_t = {}
    for Attribute, val in pairs(BattleDataManager.default_player_role_battle_data) do
        ret_t[Attribute] = val
        for Attribute_, val_ in pairs( equipData ) do
            if Attribute == Attribute_ then
                ret_t[Attribute] = val + val_
            end
        end
    end
    return ret_t
end

return BattleDataManager