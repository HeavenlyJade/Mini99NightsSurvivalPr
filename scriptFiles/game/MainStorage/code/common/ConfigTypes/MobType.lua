------------------------------------------------------------------------------------
-- -*- coding: utf-8 -*-
--
-- @作者:         zhenghao
-- @创建日期:      2025-09-17
-- @模块名称:      MobType
-- @描述:         模型初始化
-- @版本:         v1.0
------------------------------------------------------------------------------------
-- 引入管理对象
local game = game
local script = script
local Vector2 = Vector2
local MainStorage = game:GetService("MainStorage")
---@type ViewBase
local ViewBase = require(MainStorage.code.client.Ui.ViewBase)
---@type ClassMgr
local ClassMgr = require(MainStorage.code.common.ClassMgr)
---@type gg
local gg = require(MainStorage.code.common.MGlobal)
---@type ClientEventManager
local ClientEventManager = require(MainStorage.code.client.clientEvent.ClientEventManager)
---@type Monster
local Monster = require(MainStorage.code.server.entityTypes.Monster)
---@type common_const
local common_const = require(MainStorage.code.common.Const)
------------------------------------------------------------------------------------
-- StatType 类
---@class MobType:Class
local MobType = ClassMgr.Class("MobType")

function MobType:OnInit(data)
    self.id = data["怪物ID"]
    self.data = data
    -- 技能列表
    self.triggerSkills = {}
    -- 设置音效
    self.idleSound = data["闲置音效"]
    self.attackSound = data["攻击音效"]
    self.hitSound = data["受击音效"]
    self.deadSound = data["死亡音效"]
    self.dropMulti = data["掉落倍率"]
    self.isInvulnerable = data["无敌"]
end

-- 生产
---@param position Vector3 坐标
---@param scene Scene 场景
function MobType:Spawn(position, scene)
    if not position then
        return nil
    end
    -- 创建一个monsyer
    local monster_ = Monster.New({ position = position, mobType = self, npc_type = common_const.NPC_TYPE.MONSTER })
    -- 实例化怪物
    monster_:CreateModel(scene)
    -- 改变场景
    monster_:ChangeScene(scene)

    -- 场景添加怪物
    scene.monsters[monster_.uuid] = monster_
    -- 复活重置属性
    monster_:revive()
    return monster_
end

return MobType