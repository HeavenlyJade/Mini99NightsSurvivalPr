------------------------------------------------------------------------------------
-- -*- coding: utf-8 -*-
--
-- @作者:         zhenghao
-- @创建日期:      2025-09-05
-- @模块名称:      CloudDataMgr
-- @描述:         云端存档
-- @版本:         v1.0
------------------------------------------------------------------------------------
-- 引入管理对象
local game = game
local MainStorage     = game:GetService("MainStorage")
local cloudService = game:GetService("CloudService")
---@type gg
local gg                = require(MainStorage.code.common.MGlobal)
------------------------------------------------------------------------------------
---@class CloudDataMgr
local CloudDataMgr = {
    last_time_player = 0, --最后一次玩家存盘时间
    last_time_bag = 0, --最后一次背包存盘时间
    CONST_CLOUD_SAVE_TIME = 30 --每60秒存盘一次
}

local function SaveAll()

    for _, player in pairs(gg.server_players_list) do
        player:Save()
    end
end

local timer = SandboxNode.New("Timer", game.WorkSpace) ---@type Timer
timer.LocalSyncFlag = Enum.NodeSyncLocalFlag.DISABLE
timer.Name = 'SAVE_ALL'
timer.Delay = 0.1
timer.Loop = true      -- 是否循环
timer.Interval = 60   -- 循环间隔多少秒 (1秒=10帧)
timer.Callback = SaveAll
timer:Start()

-- 读取玩家的数据
function CloudDataMgr.ReadPlayerData(uin_)
    local ret_, ret2_ = cloudService:GetTableOrEmpty('playerData_' .. uin_)
    if ret_ then
        if ret2_ then
            return 0, ret2_
        end
        return 0, {}
    else
        return 1, {}       --数据失败，踢玩家下线，不然数据洗白了
    end
end

-- 保存玩家数据
function CloudDataMgr.SavePlayerData(uin_, promptly)
    if not promptly then
        local now_ = os.time()
        if now_ - CloudDataMgr.last_time_player < CloudDataMgr.CONST_CLOUD_SAVE_TIME then
            return
        else
            CloudDataMgr.last_time_player = now_
        end
    end

    local player_ = gg.server_players_list[uin_]
    if player_ then
        local data_ = {
            -- 玩家uin
            uin = uin_,
            -- 玩家货币
            money = player_.money,
            -- 玩家当前职业
            job = player_.job,
            -- 称号
            myTitle = player_.myTitle,
            -- 最高存活天数
            maxSurvivalDays = player_.maxSurvivalDays,
            -- 职业列表
            jobData = player_.jobData,
            -- 玩家变量（VariableSystem）
            variables = (player_.variableSystem and player_.variableSystem:GetVariablesDictionary()) or {}
        }
        cloudService:SetTableAsync('playerData_' .. uin_, data_, function(ret_)
        end)
    end
end

return CloudDataMgr