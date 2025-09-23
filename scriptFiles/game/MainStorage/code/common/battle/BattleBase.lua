-- -*- coding: utf-8 -*-
--
-- @作者:         zhenghao
-- @创建日期:      2025-09-16
-- @模块名称:      BattleBase
-- @描述:         攻击基础
-- @版本:         v1.0
------------------------------------------------------------------------------------
-- 引入管理对象
local game = game
local MainStorage = game:GetService("MainStorage")
---@type ClassMgr
local ClassMgr = require(MainStorage.code.common.ClassMgr)
---@type gg
local gg = require(MainStorage.code.common.MGlobal)
---@type common_const
local common_const = require(MainStorage.code.common.Const)
---@type BattleUtils
local BattleUtils = require(MainStorage.code.common.battle.BattleUtils)

------------------------------------------------------------------------------------
---@class BattleBase
local _M = ClassMgr.Class('BattleBase')

function _M:OnInit( info_ )
    self.info = info_
    self.uuid = gg.create_uuid( 'bt' )    --uniq id

    self.stat      = 0                   -- 0, 1, 2, 3 .. (阶段)   99=等待清理
    self.tick      = 0
    self.tick_wait = 0

    self.from       = info_.from      --技能发起者
    self.scene_name = info_.from.scene_name

    self.target   = nil             --被攻击者（可选）
    self.skillType = info_.skillType

    self.skill_config = common_const.SKILL_DEF[info_.skillType]
end

--攻击或者施法
--return  0=成功  大于0=失败
function _M:castSpell()
    --攻击发起者
    local attacker_ = self.from
    --检查攻击者和目标是否都存活
    if  BattleUtils.checkAlive( attacker_, self.skill_config ) > 0 then
        return -1
    end
    --施法成功后，设置cd并扣除魔法值
    attacker_:setAttackSpellByConfig( self.skillType, self.skill_config )   --计算攻速cd间隔 扣除法力
    -- 播放攻击动画

    return attacker_.modelPlayer:OnAttack()
end

--清理技能
function _M:DestroySkill()
end

--tick
function _M:update()
    self.tick = self.tick + 1
    return self.stat
end


return _M


-- BattleBase

-- 弓箭 bow

-- 枪械 gun

-- 近战 Melee

-- 防御 Defensive

-- 范围 aoe

