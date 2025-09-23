
-- -*- coding: utf-8 -*-
--
-- @作者:         zhenghao
-- @创建日期:      2025-09-16
-- @模块名称:      BattleTypeBow
-- @描述:         弓箭武器
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
---@class BattleTypeBow : BattleBase
local _M = ClassMgr.Class('BattleTypeBow', BattleBase)

function _M:OnInit( info_ )
    BattleBase:OnInit( info_ )
end


--攻击或者施法
function _M:castSpell()

end


-- 击中目标
function _M:hitTarget()

end


return _M