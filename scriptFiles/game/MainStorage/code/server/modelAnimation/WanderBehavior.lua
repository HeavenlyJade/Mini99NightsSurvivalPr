------------------------------------------------------------------------------------
-- -*- coding: utf-8 -*-
--
-- @作者:         zhenghao
-- @创建日期:      2025-09-11
-- @模块名称:      WanderBehavior
-- @描述:         随机移动模型动画
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
-- 随机移动状态
---@class WanderBehavior:MobBehavior
local WanderBehavior = ClassMgr.Class("WanderBehavior", MobBehavior)
function WanderBehavior:OnInit()

    self.CanEnter = function(self, entity, behavior)
        -- 一定几率触发
        if behavior and behavior["类型"] == "随机移动" and gg.rand_int(100) < (behavior["几率"] or 100) then
            return true
        end
        return false
    end
    -- 进入动画
    self.OnEnter = function(self, entity)
        local behavior = entity:GetCurrentBehavior()
        local range = behavior["距离"] or 500

        -- 计算随机位置
        local randomOffset = Vector3.New(
                gg.rand_int_both(range),
                0,
                gg.rand_int_both(range)
        )

        if behavior["保持在出生点附近"] then
            randomOffset = gg.vec.Add3(entity.spawnPos, randomOffset.x, randomOffset.y, randomOffset.z)
        else
            randomOffset = gg.vec.Add3(entity:GetPosition(), randomOffset.x, randomOffset.y, randomOffset.z)
        end
        if entity.actor.NoPath then
            -- 调用移动
            entity.actor:NavigateTo(randomOffset)
        end
    end
    -- 更新动画
    self.Update = function(self, entity)
        if entity.actor.NoPath then
            entity:SetCurrentBehavior(nil)
        end
    end
    -- 是否退出
    self.CanExit = function(self, entity)
        return entity.actor.NoPath
    end
    -- 退出动画
    self.OnExit = function(self, entity)
        entity.actor:StopNavigate()
    end
end

return WanderBehavior