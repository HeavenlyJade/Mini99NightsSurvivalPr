------------------------------------------------------------------------------------
-- -*- coding: utf-8 -*-
--
-- @作者:         zhenghao
-- @创建日期:      2025-09-11
-- @模块名称:      MobBehavior
-- @描述:         模型动画
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
------------------------------------------------------------------------------------
---@class MobBehavior:Class
local MobBehavior = ClassMgr.Class("MobBehavior")

function MobBehavior:OnInit()
    -- 是否可进入
    self.CanEnter = function(self, entity) return true end
    -- 进入后
    self.OnEnter = function(self, entity) end
    -- 更新
    self.Update = function(self, entity) end
    -- 是否可退出
    self.CanExit = function(self, entity) return true end
    -- 退出后
    self.OnExit = function(self, entity) end
end

return MobBehavior