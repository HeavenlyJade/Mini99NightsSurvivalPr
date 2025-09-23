------------------------------------------------------------------------------------
-- -*- coding: utf-8 -*-
--
-- @作者:         zhenghao
-- @创建日期:      2025-09-11
-- @模块名称:      WanderBehavior
-- @描述:         攻击模型动画
-- @版本:         v1.0
------------------------------------------------------------------------------------
-- 引入管理对象
local game = game
local MainStorage = game:GetService("MainStorage")
---@type ClassMgr
local ClassMgr = require(MainStorage.code.common.ClassMgr)
---@type gg
local gg = require(MainStorage.code.common.MGlobal)
---@type ServerScheduler
local ServerScheduler = require(MainStorage.code.server.serverEvent.ServerScheduler)
---@type MobBehavior
local MobBehavior = require(MainStorage.code.server.modelAnimation.MobBehavior)
------------------------------------------------------------------------------------
-- 近战攻击状态
---@class MeleeBehavior:MobBehavior
local MeleeBehavior = ClassMgr.Class("MeleeBehavior", MobBehavior)

function MeleeBehavior:OnInit()

    self.CanEnter = function(self, entity, behavior)
        if not entity.target then
            if behavior["无限视距"] then
                entity:TryFindTarget()
                if not entity.target then
                    return false
                end
            else
                local searchRadius = behavior["主动索敌"] + entity:GetSize().x
                if searchRadius and searchRadius > 0 then
                    entity:TryFindTarget(searchRadius)
                    if not entity.target then
                        return false
                    end
                else
                    return false
                end
            end
        end
        return true
    end

    ---@param self MeleeBehavior
    ---@param entity Monster
    self.OnEnter = function(self, entity)
        -- 进入战斗状态
        entity.attackTimer = 0
        entity.isAttacking = false
        entity.skillCheckCounter = 0 -- 初始化技能检查计数器
    end

    ---@param self MeleeBehavior
    ---@param entity Monster
    self.Update = function(self, entity)
        if not entity.target then
            entity:SetCurrentBehavior(nil)
            return
        end
        -- 当前行为
        local behavior = entity:GetCurrentBehavior()
        -- 获取位置
        local targetPos = entity.target:GetPosition()
        -- 与目标距离
        local distanceSq = gg.vec.DistanceSq3(entity:GetPosition(), targetPos)

        -- 可攻击距离
        local attackRange = entity:GetSize().x + (behavior["额外攻击距离"] or 0)
        local attackRangeSq = attackRange * attackRange

        if distanceSq > attackRangeSq then
            -- 不在攻击范围内，移动接近目标
            --gg.log("与目标距离 = ",distanceSq,"可攻击距离 = ",attackRangeSq,"不在攻击范围内，移动接近目标")
            entity.actor:NavigateTo(targetPos)
            return
        end
        --gg.log("与目标距离 = ",distanceSq,"可攻击距离 = ",attackRangeSq,"开始攻击")
        entity.actor:StopNavigate()
        -- 开始攻击
        entity.isAttacking = true

        -- 播放攻击音效
        if behavior["播放攻击音效"] then
            entity.scene:PlaySound(behavior["播放攻击音效"], entity.actor, 1.0, 1.0)
        end
        -- 延迟执行攻击
        local attackDelay = entity.modelPlayer:OnAttack()

        -- 伤害
        local amount = 100
        if attackDelay > 0 then
            ServerScheduler.add(function()
                if entity.target and entity.isAttacking then -- 再次检查是否仍在攻击状态
                    entity:Attack(entity.target, amount)
                end
            end, attackDelay)
        else
            entity:Attack(entity.target,amount)
        end
        -- 僵直1秒
        entity:Freeze(entity:GetAttackDuration())
        -- 取消攻击任务
        if entity.attackResetCb then
            ServerScheduler.cancel(entity.attackResetCb)
        end
        -- 1秒后攻击取消
        entity.attackResetCb = ServerScheduler.add(function()
            entity.isAttacking = false
        end, entity:GetAttackDuration())
    end

    ---@param self MeleeBehavior
    ---@param entity Monster
    ---@return boolean
    self.CanExit = function(self, entity)
        if not entity.target then
            entity:SetTarget(nil)
            return true
        end
        local behavior = entity:GetCurrentBehavior()
        if behavior["脱战距离"] and behavior["脱战距离"] > 0 then
            local distanceSq = gg.vec.DistanceSq3(entity:GetPosition(), entity.target:GetPosition())
            return distanceSq <= behavior["脱战距离"] + entity:GetSize().x ^ 2
        end
        return false
    end

    ---@param self MeleeBehavior
    ---@param entity Monster
    self.OnExit = function(self, entity)
        entity.actor:StopNavigate()
        entity.isAttacking = false
    end
end

return MeleeBehavior