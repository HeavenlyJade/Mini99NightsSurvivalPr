------------------------------------------------------------------------------------
-- -*- coding: utf-8 -*-
--
-- @作者:         zhenghao
-- @创建日期:      2025-09-15
-- @模块名称:      SceneType
-- @描述:         关卡类型 匹配人数
-- @版本:         v1.0
------------------------------------------------------------------------------------
-- 引入管理对象

local game = game
local MainStorage = game:GetService("MainStorage")
---@type ClassMgr
local ClassMgr = require(MainStorage.code.common.ClassMgr)
---@type gg
local gg = require(MainStorage.code.common.MGlobal)
---@type ServerEventManager
local ServerEventManager = require(MainStorage.code.server.serverEvent.ServerEventManager)
---@type SceneLevel
local SceneLevel = require(MainStorage.code.server.gameScene.SceneLevel)
---@type LevelConfig
local LevelConfig = require(MainStorage.config.LevelConfig)
---@type ServerScheduler
local ServerScheduler = require(MainStorage.code.server.serverEvent.ServerScheduler)

------------------------------------------------------------------------------------
---@class SceneType : Class
local _M = ClassMgr.Class('SceneType')

function _M:OnInit(data)
    self.startTime = data["匹配时间"] or 10 ---@type number
    -- 进入位置
    self.entryPoints = data["玩家进入位置"]



    -- 最大玩家数
    self.maxPlayers = 0
    -- 开始玩家
    self.startPlayers = self.maxPlayers
    -- 增加玩家减少时间/减少玩家增加时间
    self.extraPlayerTime = data["增加额外玩家时间"] or 1
    -- 关卡ID
    self.levelId = data["关卡ID"]
    --
    self.SceneName = data["场景"] or "GameScene"
    -- 初始化匹配相关属性
    -- 匹配队列
    self.matchQueue = {}
    -- 匹配玩家数量
    self.playerCount = 0 ---@type number
    -- 剩余时间
    self.remainingTime = data["匹配时间"] or 10 ---@type number
    -- 上次更新时间
    self.lastUpdateTime = 0 ---@type number
    -- 可用场景
    self.SceneLevels = {}
    -- 注册事件处理器
    -- 玩家离开匹配
    ServerEventManager.Subscribe("LeaveQueue", function(evt)
        local player = evt.player
        if player then
            -- 如果玩家在匹配队列中，将其移除
            self:LeaveQueue(player)
        end
    end)

    -- 玩家退出游戏
    ServerEventManager.Subscribe("PlayerLeaveGameEvent", function(event)
        local player = event.player
        if player then
            self:LeaveQueue(player)
        end
    end)
end

--------------------------------------------------
-- 匹配系统相关方法
--------------------------------------------------
---从匹配队列中移除
---@param player Player
function _M:LeaveQueue(player)
    if not self.matchQueue[player.uin] then
        -- 玩家不在匹配队列
        return
    end
    -- 清除玩家匹配队列数据
    self.matchQueue[player.uin] = nil
    -- 玩家数量 -1
    self.playerCount = self.playerCount - 1
    -- 玩家回到退出位置
    player:TeleportPos(Vector3.New(0, 200, 0))
    -- 玩家显示 已离开匹配队列
    player:SendHoverText("已离开匹配队列")
    -- 发送客户端事件玩家离开匹配队列
    player:SendEvent("MatchCancel")
    -- 玩家退出时，增加匹配时间
    self.remainingTime = self.remainingTime + self.extraPlayerTime
    if self.playerCount == 0 then
        self.maxPlayers = 0
    end
    -- 通知场景NPC 剩余玩家,当前匹配进度
    ServerEventManager.Publish("MatchProgressUpdate", {
        -- 区域名字
        name = self.levelId,
        -- 玩家数量
        currentCount = self.playerCount,
        -- 最大玩家数量
        totalCount = self.maxPlayers,
        -- 剩余时间
        remainingTime = self.remainingTime
    })
end


-- 创建定时器更新所有关卡类型的匹配时间
ServerScheduler.add(function()
    for _, levelType in pairs(LevelConfig.GetAll()) do
        levelType:UpdateMatchTime()
    end
end, 1, 1)

---加入匹配队列
---@param player Player
---@return boolean 成功进入
function _M:JoinQueue(player)
    local canJoin, reason = self:CanJoin(player)
    if not canJoin then
        return false
    end
    -- 加入匹配队列
    self.matchQueue[player.uin] = player
    -- 数量 + 1
    self.playerCount = self.playerCount + 1
    -- 显示加入匹配
    player:SendHoverText("已加入匹配队列")
    --gg.log("当前玩家数量",self.playerCount)
    -- 如果是第一个玩家，初始化匹配时间
    if self.playerCount == 1 then
        --gg.log("初始化匹配时间前",self.remainingTime,"最大人数",self.maxPlayers)
        -- 初始化匹配时间
        self.remainingTime = self.maxPlayers * self.startTime
        -- 初始化开始时间
        self.lastUpdateTime = os.time()
        --gg.log("初始化匹配时间后",self.remainingTime)
    else
        --gg.log("减少匹配时间前",self.remainingTime)
        -- 每加入一个玩家，减少匹配时间
        self.remainingTime = math.max(0, self.remainingTime - self.extraPlayerTime)
        --gg.log("减少匹配时间后",self.remainingTime)
    end
    --gg.log("最终匹配时间 = ",self.remainingTime)
    -- 通知场景NPC 当前匹配进度
    ServerEventManager.Publish("MatchProgressUpdate", {
        -- 区域名字
        name = self.levelId,
        -- 玩家数量
        currentCount = self.playerCount,
        -- 最大玩家数量
        totalCount = self.maxPlayers,
        -- 剩余时间
        remainingTime = self.remainingTime
    })
    -- 发送客户端事件玩家加入匹配队列
    player:SendEvent("MatchJoin")
    if self.entryPoints then
        -- 通知客户端改变场景
        player:ChangeScene("MainCity")
        -- 传送
        player:TeleportPos(self.entryPoints)
    end

    -- 检查是否可以开始游戏
    if self:CanStartGame() then
        self:StartLevel()
        return true
    end
    return false
end

---检查是否可以开始游戏
---@return boolean
function _M:CanStartGame()
    return self.remainingTime <= 0
end

---开始关卡
function _M:StartLevel()
    -- 找到一个可用的关卡实例
    local availableLevel = nil

    -- 遍历所有关卡实例，找到没有玩家的场景
    for _, level in ipairs(self.SceneLevels) do
        if not level:IsActive() then
            -- 检查场景中是否有玩家
            if level:GetPlayerCount() == 0 then
                availableLevel = level
                break
            end
        end
    end
    -- 如果没有找到可用的关卡实例，创建新的
    if not availableLevel then
        -- 克隆一个新的场景
        local scene = gg.server_scene_list[self.SceneName]
        local newScene =  scene:Clone()
        availableLevel = SceneLevel.New(self, newScene, #self.SceneLevels + 1)
        table.insert(self.SceneLevels, availableLevel)
    end

    -- 将队列中的玩家添加到关卡
    for _, player in pairs(self.matchQueue) do
        availableLevel.players[player.uin] = player
    end
    -- 清空匹配队列
    self.matchQueue = {}
    -- 清空玩家数量
    self.playerCount = 0

    -- 开始关卡
    availableLevel:Start()
    -- 通知所有玩家
    for _, player in pairs(availableLevel.players) do
     --   player:SendHoverText("匹配成功，关卡开始！")
        -- 通知客户端关卡开始
        player:SendEvent("GameStart")
    end
    -- 设置玩家为0
    self.maxPlayers = 0
    -- 通知场景NPC 当前匹配进度
    ServerEventManager.Publish("MatchProgressUpdate", {
        -- 区域名字
        name = self.levelId,
        -- 玩家数量
        currentCount = self.playerCount,
        -- 最大玩家数量
        totalCount = self.maxPlayers,
        -- 剩余时间
        remainingTime = self.remainingTime
    })
end

-- 新增：判断玩家是否可以加入关卡/匹配队列
---@param player Player
---@return boolean, string? #是否可加入,失败原因
function _M:CanJoin(player,maxNum)
    -- 检查是否已在队列
    if self.matchQueue[player.uin] then
        return false, "你已经在匹配队列中"
    end
    -- 检查人数是否满了
    if self.maxPlayers > 0 and self.playerCount >= self.maxPlayers then
        return false, "人数满了"
    end
    if self.maxPlayers == 0 and maxNum then
        self.maxPlayers = maxNum
    end
    return true
end

-- 更新匹配时间
function _M:UpdateMatchTime()
    if self.maxPlayers == 0 then
        return
    end

    local currentTime = os.time()
    local deltaTime = currentTime - self.lastUpdateTime
    self.lastUpdateTime = currentTime

    if self.remainingTime > 0 then
        self.remainingTime = math.max(0, self.remainingTime - deltaTime)
        -- 通知场景NPC 剩余玩家,当前匹配进度
        ServerEventManager.Publish("MatchProgressUpdate", {
            -- 区域名字
            name = self.levelId,
            -- 玩家数量
            currentCount = self.playerCount,
            -- 最大玩家数量
            totalCount = self.maxPlayers,
            -- 剩余时间
            remainingTime = self.remainingTime
        })
        -- 检查是否可以开始游戏
        if self:CanStartGame() then
            self:StartLevel()
        end
    end
end

return _M