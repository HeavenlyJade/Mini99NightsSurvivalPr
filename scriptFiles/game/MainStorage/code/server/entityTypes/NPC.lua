------------------------------------------------------------------------------------
-- -*- coding: utf-8 -*-
--
-- @作者:         zhenghao
-- @创建日期:      2025-09-05
-- @模块名称:      NPC
-- @描述:         NPC类
-- @版本:         v1.0
------------------------------------------------------------------------------------
-- 引入管理对象
local game = game
local MainStorage = game:GetService("MainStorage")
---@type ClassMgr
local ClassMgr = require(MainStorage.code.common.ClassMgr)
---@type Entity
local Entity = require(MainStorage.code.server.entityTypes.Entity)
---@type gg
local gg = require(MainStorage.code.common.MGlobal)
---@type ServerEventManager
local ServerEventManager = require(MainStorage.code.server.serverEvent.ServerEventManager)
---@type ServerScheduler
local ServerScheduler = require(MainStorage.code.server.serverEvent.ServerScheduler)
------------------------------------------------------------------------------------
---@class NPC : Class
local _M = ClassMgr.Class('NPC', Entity)

-- 初始化实例类
function _M:OnInit(info, actor)
    self.actor = actor
    self.uuid = gg.create_uuid('u_Npc')
    -- 产生位置
    self.spawnPos = actor.LocalPosition
    -- 实例
    self:setGameActor(actor)
    -- 名称
    self.name = info["节点名"]
    -- 打开UI
    self.openUi = info["打开UI"]
    -- 交互后ModelId
    self.modelId = info["交互后ModelId"]

    -- 存储附近玩家的列表
    self.nearbyPlayers = {}
    --碰撞体
    local trigger = actor["交互体"]

    trigger.Touched:Connect(function(node)
        if node and node.UserId then

            if self.modelId and self.modelId == self.actor["金宝箱"].ModelId then

            else
                local player = gg.getPlayerByUin(node.UserId)
                if player then
                    if not player.Teleporting then
                        self:OnPlayerTouched(player)
                    end
                end
            end
        end
    end)
    trigger.TouchEnded:Connect(function(node)
        if node and node.UserId then
            local player = gg.getPlayerByUin(node.UserId)
            if player then
                if not player.Teleporting then
                    if self.target == player then
                        self:SetTarget(nil)
                    end
                    -- 从玩家的附近NPC列表中移除·
                    player:RemoveNearbyNpc(self)
                    -- 从NPC的附近玩家列表中移除
                    self.nearbyPlayers[player.uuid] = nil
                end
            end
        end
    end)
    -- 注册NPC交互事件处理器
    ServerEventManager.Subscribe("InteractWithNpc", function(evt)
        local player = evt.player
        local npcId = evt.npcId
        -- 查找NPC
        if self.uuid == npcId then
            -- 检查玩家是否在NPC附近
            if player.nearbyNpcs[npcId] then
                if not player.Teleporting then
                    self:HandleInteraction(player)
                end
            else
                player:SendHoverText("距离太远，无法交互")
            end
        end
    end)

    if info["匹配区域"] then
        self.startNum = 0
        self.actor["匹配提示"].Visible = true
        self.actor["匹配提示"]["匹配人数"].Visible = true
        self.actor["匹配提示"]["进入时间"].Visible = false
        self.actor["匹配提示"]["匹配人数"].Title = "创建队伍"
        self.actor["匹配区域"].Color = info["无人时"]
        -- 通知场景NPC 剩余玩家,当前匹配进度
        ServerEventManager.Subscribe("MatchProgressUpdate", function(evt)
            if evt.name == self.name then
                -- 玩家数量
                local currentCount = evt.currentCount
                -- 最大玩家数量
                local totalCount = evt.totalCount
                -- 剩余时间
                local remainingTime = evt.remainingTime
                if currentCount > 0 then
                    if currentCount >= totalCount then
                        self.actor["匹配区域"].Color = info["满人时"]
                    else
                        self.actor["匹配区域"].Color = info["人数未满时"]
                    end
                    self.actor["匹配提示"].Visible = true
                    self.actor["匹配提示"]["匹配人数"].Visible = true
                    self.actor["匹配提示"]["进入时间"].Visible = true
                    self.actor["匹配提示"]["匹配人数"].Title = string.format("匹配中%s/%s",currentCount,totalCount)
                    self.actor["匹配提示"]["进入时间"].Title = string.format("%s秒后进入",remainingTime)
                else
                    self.actor["匹配区域"].Color = info["无人时"]
                    self.actor["匹配提示"]["进入时间"].Visible = false
                    self.actor["匹配提示"]["匹配人数"].Visible = true
                    self.actor["匹配提示"]["匹配人数"].Title = "创建队伍"
                end
                self.startNum = currentCount
            end
        end)
    end
end



---设置NPC的目标
---@param target Player|nil
function _M:SetTarget(target)
    self.target = target
end

---处理玩家进入触发器
---@param player Player 玩家
function _M:OnPlayerTouched(player)
    -- 设置目标
    self:SetTarget(player)
    -- 玩家添加NPC
    player:AddNearbyNpc(self)
    -- 将玩家添加到附近玩家列表
    self.nearbyPlayers[player.uuid] = player
end

-- 获取NPC名字
function _M:GetName()
    return self.name
end

-- 处理NPC交互
function _M:HandleInteraction(player)
    if self.openUi then
        ServerEventManager.Publish("ClickMenu", { player = player, PageName = self.openUi })
    elseif self.name == "宝箱" then
        self.actor["金宝箱"].ModelId = self.modelId
        self:dropItem("樱桃")             --掉落物品
    end
end

-- 在触发器内的玩家数量
function _M:GetNearbyPlayerNum()
    local num = 0
    for i, v in pairs(self.nearbyPlayers) do
        num = num + 1
    end
    return num
end

return _M