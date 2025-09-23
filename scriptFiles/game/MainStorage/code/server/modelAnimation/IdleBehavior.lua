------------------------------------------------------------------------------------
-- -*- coding: utf-8 -*-
--
-- @作者:         zhenghao
-- @创建日期:      2025-09-11
-- @模块名称:      IdleBehavior
-- @描述:         空闲模型动画
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
-- 静止状态
---@class IdleBehavior:MobBehavior
local IdleBehavior = ClassMgr.Class("IdleBehavior", MobBehavior)
function IdleBehavior:OnInit()
    -- 进入条件
    self.CanEnter = function(self, entity,CanEnter)
        -- 空闲状态总是可以进入
        return true
    end
    -- 进入动画
    self.OnEnter = function(self, entity)
        entity:Freeze(0) -- 取消之前的冻结
    end
    -- 更新状态
    self.Update = function(self, entity)
        -- 空闲状态下不需要特殊更新
    end
    -- 退出条件
    self.CanExit = function(self, entity)
        return true -- 空闲状态总是可以退出
    end
    -- 退出动画
    self.OnExit = function(self, entity)
        -- 停止移动
        entity.actor:StopNavigate()
    end
end

return IdleBehavior