
-- -*- coding: utf-8 -*-
--
-- @作者:         zhenghao
-- @创建日期:      2025-09-16
-- @模块名称:      BattleTypeMelee
-- @描述:         近身武器平砍
-- @版本:         v1.0
------------------------------------------------------------------------------------
-- 引入管理对象
local game = game
local MainStorage = game:GetService("MainStorage")
---@type ClassMgr
local ClassMgr = require(MainStorage.code.common.ClassMgr)
---@type BattleBase
local BattleBase = require(MainStorage.code.common.battle.BattleBase)
---@type gg
local gg = require(MainStorage.code.common.MGlobal)
---@type BattleUtils
local BattleUtils = require(MainStorage.code.common.battle.BattleUtils)
---@type BattleMgr
local BattleMgr = require(MainStorage.code.common.battle.BattleMgr)
---@type ServerScheduler
local ServerScheduler = require(MainStorage.code.server.serverEvent.ServerScheduler)
------------------------------------------------------------------------------------
---@class BattleTypeMelee : BattleBase
local _M = ClassMgr.Class('BattleTypeMelee', BattleBase)

function _M:OnInit( info_ )
    BattleBase:OnInit( info_ )
end


--攻击或者施法
--return  0=成功  大于0=失败
function _M:castSpell()
    local time = BattleBase:castSpell()

    if time > 0 then
        ServerScheduler.add(function()
            self:hitTarget()
            self.stat = 99
        end, time)
    end
end


-- 击中目标
function _M:hitTarget()
    --攻击发起者
    local attacker_ = self.from
    --检查攻击者和目标是否都存活
    if  BattleUtils.checkAlive( attacker_, self.skill_config ) > 0 then
        return 1
    end
    --被攻击点
    local actor_ = attacker_.actor

    local v3_dir = gg.getDirVector3( actor_ )    --朝向方向
    local xx = actor_.Position.x - v3_dir.x * 100
    local yy = actor_.Position.y
    local zz = actor_.Position.z - v3_dir.z * 100
    local pos1_ = Vector3.new( xx, yy, zz )   --攻击中心点

    -- 判断【攻击者】的【攻击点】是否击中【目标】
    local function tmp_attack_target_( target_ )
        local pos2_ = target_:GetPosition()
        if  gg.out_distance( pos1_, pos2_, self.skill_config.range ) then
            gg.log("未击中")
            return 0   --未击中
        else
            local damage_, eff_ = BattleMgr.calculate_attack( attacker_, target_, self.skill_config )
            if  damage_ > 0 then
                --gg.log("攻击[",target_.name ,"]造成[",damage_,"]伤害 距离：",(pos1_ - pos2_).length)
                -- 击中
                target_:Hurt(damage_, attacker_)
                -- 击中通知客户端
                attacker_:SendEvent("playerHitMonster", {})
                return 1
            end
            --gg.log("0 攻击[",target_.name ,"]造成[",damage_,"]伤害 距离：",(pos1_ - pos2_).length)
            return 0
        end
    end


    --优先判断当前锁定的目标
    if  attacker_.target then
        if  tmp_attack_target_( attacker_.target ) == 1 then
            return 0
        end
    else
        gg.log("没有目标")
    end
    return 0  --成功
end


return _M