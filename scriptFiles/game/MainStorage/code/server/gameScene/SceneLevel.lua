------------------------------------------------------------------------------------
-- -*- coding: utf-8 -*-
--
-- @作者:         zhenghao
-- @创建日期:      2025-09-15
-- @模块名称:      Scene
-- @描述:         关卡类
-- @版本:         v1.0
------------------------------------------------------------------------------------
-- 引入管理对象
local game = game
local Vector3 = Vector3
local MainStorage = game:GetService("MainStorage")
---@type ClassMgr
local ClassMgr = require(MainStorage.code.common.ClassMgr)
---@type gg
local gg = require(MainStorage.code.common.MGlobal)
---@type ServerScheduler
local ServerScheduler = require(MainStorage.code.server.serverEvent.ServerScheduler)
---@type Monster
local Monster = require(MainStorage.code.server.entityTypes.Monster)
---@type common_const
local common_const = require(MainStorage.code.common.Const)
---@type SpawningMob
local SpawningMob = require(MainStorage.code.common.ConfigTypes.SpawningMob)
---@type ServerEventManager
local ServerEventManager = require(MainStorage.code.server.serverEvent.ServerEventManager)
---@type BattleDataManager
local BattleDataManager = require(MainStorage.code.server.serverManager.BattleDataManager)
------------------------------------------------------------------------------------
---@class SceneLevel : Class
local _M = ClassMgr.Class('SceneLevel')

local activeLevels = {}
-- 初始化实例类
function _M:OnInit(levelType, scene, index)

    self.scene = scene ---@type Scene

    self.levelType = levelType

    local sceneNode = scene.node

    -- 玩家进入点
    self.playerSpawnPoints = sceneNode["出生点"].Position

    -- 更新任务
    self.updateTask = nil

    -- 玩家列表
    self.players = {} ---@type table<string, Player>
    -- 玩家初始位置表
    self.playerOriginalPositions = {}
    -- 关卡开始时间
    self.startTime = 0
    -- 关卡结束时间
    self.endTime = 0
    -- 生存天数
    self.curDay = 1
    self.LastDay = 0

    self.CurDayMonster = {
        1, 2, 3, 4, 5, 6, 7, 8, 9

    }
    self.spawningMob = SpawningMob.New()

    -- 怪物相关
    -- 怪物列表
    self.monsterList = {}


    -- 监听玩家死亡事件
    ServerEventManager.Subscribe("PlayerDeadEvent", function(data)
        if not self:IsActive() then
            return false
        end
        if not data.player or not self.players[data.player.uin] then
            return false
        end
        -- 播放失败音效
        for _, player in pairs(self.players) do
            if player.uin ~= data.player.uin then
                player:SendHoverText(string.format("玩家 %s 已阵亡", data.player.name))
            end
        end
        self:RemovePlayer(data.player, false, "死亡")
    end)
end


---移除玩家
---@param player Player
---@param success boolean|nil
---@param reason string 移除原因
function _M:RemovePlayer(player, success, reason)
    if self.players[player.uin] then
        -- 清理关卡传送标记
        player.Teleporting = false

        self.players[player.uin] = nil


        -- 怪物仇恨转移：将target为该玩家的怪物直接SetTarget为随机其它玩家
        local playersList = {}
        for uin, p in pairs(self.players) do
            table.insert(playersList, p)
        end
        for i, mob in pairs(self.monsterList) do
            if mob.target == player then
                mob:SetTarget(nil)
            end
        end
        -- 玩家回到退出位置
        player:TeleportPos(Vector3.New(0, 200, 0))
    end

    if self:GetPlayerCount() == 0 then
        self:EndSceneLevel(false)
    end
end


---结束关卡
---@param success boolean 是否成功完成
function _M:EndSceneLevel(success)
    if not self:IsActive() then
        return
    end
    self.endTime = os.time()

    -- 从活跃关卡列表中移除
    activeLevels[self.scene] = nil

    if self.updateTask then
        ServerScheduler.cancel(self.updateTask)
        self.updateTask = nil
    end

    -- 处理排名掉落物

    for uin, player in pairs(self.players) do
        player.Teleporting = false
        -- 复活死亡的玩家
        if player.isDead then
            player:CompleteRespawn()
        end
        -- 玩家回到退出位置
        player:TeleportPos(Vector3.New(0, 200, 0))
    end
    self.players = {}
    -- 清理场景
    self:Cleanup()
end


---清理场景
function _M:Cleanup()
    -- 更新任务
    self.updateTask = nil
    -- 玩家列表
    self.players = {} ---@type table<string, Player>
    -- 玩家初始位置表
    self.playerOriginalPositions = {}
    -- 关卡开始时间
    self.startTime = 0
    -- 关卡结束时间
    self.endTime = 0
    -- 生存天数
    self.curDay = 1
    self.LastDay = 0
    self.spawningMob = SpawningMob.New()
    for i, mob in pairs(self.monsterList) do
        mob:DestroyObject()
    end
    if self.scene and self.scene.node and self.scene.node["怪物容器"] then
        local monsterContainer = self.scene.node["怪物容器"]
        if monsterContainer.Children then
            -- 移除所有怪物子节点
            for _, child in pairs(monsterContainer.Children) do
                if child then
                    child:Destroy()
                end
            end
        end
    end
end

-- 判断关卡是否活跃
function _M:IsActive()
    if self.updateTask == nil then
        return false
    end
    return true
end

-- 获取关卡玩家数量
function _M:GetPlayerCount()
    local count = 0
    for _, _ in pairs(self.players) do
        count = count + 1
    end
    return count
end

---开始关卡
function _M:Start()
    -- 关卡活跃退出
    if self:IsActive() then
        return
    end
    -- sz关卡开始时间
    self.startTime = os.time()

    -- 将关卡添加到活跃关卡列表
    activeLevels[self.scene] = self

    local playersQueueing = self.players
    self.players = {}
    for _, player in pairs(playersQueueing) do
        self:AddPlayer(player)
    end
    -- 12 秒后开始加载游戏
    ServerScheduler.add(function()
        -- 确保重新初始化游戏
        self:InitGameData()
        -- 开始天数
        self:StartDay()
        self:StartUpdateTask()
    end, 11)
end

-- 初始化游戏
function _M:InitGameData()

end

-- 初始化游戏
function _M:StartDay()


end

-- 更新任务
function _M:StartUpdateTask()
    if self.updateTask then
        ServerScheduler.cancel(self.updateTask)
    end

    self.updateTask = ServerScheduler.add(function()
        self:Update()
    end, 3, 1.0) -- 立即开始，每秒执行一次
end

---更新关卡状态
function _M:Update()
    -- 生存天数
    if self.curDay == self.LastDay then
        -- 判断怪物数量
        if table.is_empty(self.scene.monsters) then
            self.curDay = self.curDay + 1
            for _, player in pairs(self.players) do
                player:SendEvent("UpDataGameDay", { day = self.curDay })
            end
        end
    else

        local monsterListData = {
            ["刷新怪物"] = {
                {
                    ["怪物类型"] = "野兔",
                    ["比重"] = 0
                },
                {
                    ["怪物类型"] = "凶恶猫头鹰",
                    ["比重"] = 0
                },
                {
                    ["怪物类型"] = "站立恐怖鹿",
                    ["比重"] = 0
                },
                {
                    ["怪物类型"] = "狂暴邪恶鹿",
                    ["比重"] = 0
                },
                {
                    ["怪物类型"] = "黑熊",
                    ["比重"] = 100
                },
                {
                    ["怪物类型"] = "野猪",
                    ["比重"] = 100
                },
            }
        }



        local spawnedMobs = self.spawningMob:TrySpawn(monsterListData,self.curDay + 1,self.scene,self.playerSpawnPoints,5000)


        -- 处理生成的怪物
        for _, mob in ipairs(spawnedMobs) do
            -- 缓存怪物实例
            self.monsterList[mob.uuid] = mob
            ---- 随机选择一个活着的玩家作为目标
            --local alivePlayers = {}
            --for _, player in pairs(self.players) do
            --    if not player.isDead then
            --        table.insert(alivePlayers, player)
            --    end
            --end
            --if #alivePlayers > 0 then
            --    local randomPlayer = alivePlayers[math.random(1, #alivePlayers)]
            --    mob:SetTarget(randomPlayer)
            --end
        end


        --local SpawnNum = self.CurDayMonster[self.curDay]
        ---- 生成怪物
        --for i = SpawnNum, 1, -1 do
        --    -- 随机坐标位置
        --    local spawnPoints = gg.randomPointOnCirclePerimeter(self.playerSpawnPoints.x, 200, self.playerSpawnPoints.z, 5000)
        --    -- 生产一个怪物
        --    local monster_ = Monster.New({
        --        npc_type = common_const.NPC_TYPE.MONSTER,
        --        position = spawnPoints,
        --        name = "小鹿"
        --    })
        --    -- 实例化怪物
        --
        --    if self.curDay == 2 then
        --        monster_:CreateModel(self.scene,"resId&usev2=1://430145453558976520")
        --        monster_:SetFuryType(true)
        --    else
        --        monster_:CreateModel(self.scene)
        --        monster_:SetFuryType(false)
        --    end
        --
        --    monster_:revive()
        --
        --    monster_:CreateTitle()
        --    -- 缓存怪物实例
        --    self.monsterList[monster_.uuid] = monster_
        --    -- 随机选择一个活着的玩家作为目标
        --    local alivePlayers = {}
        --    for _, player in pairs(self.players) do
        --        if not player.isDead then
        --            table.insert(alivePlayers, player)
        --        end
        --    end
        --    if #alivePlayers > 0 then
        --        local randomPlayer = alivePlayers[math.random(1, #alivePlayers)]
        --        monster_:SetTarget(randomPlayer)
        --    end
        --end
        self.LastDay = self.curDay
    end
end
---添加玩家
---@param player Player
function _M:AddPlayer(player)
    -- 玩家数量超了
    if self:GetPlayerCount() >= 5 then
        return false
    end
    -- 如果玩家已在关卡则不重复添加
    if self.players[player.uin] then
        return true
    end
    -- 添加玩家
    self.players[player.uin] = player

    -- 保存玩家原始位置
    if player.actor then
        self.playerOriginalPositions[player.uin] = {
            position = Vector3.New(0, 200, 0),
            euler = Vector3.New(0, 90, 0)
        }
    end
    -- 死亡后显示死亡界面
    player.showDeathHud = true
    -- 获取进入点位置
    local entryPoint = self:FindAvailableEntryPoint()

    -- 传送玩家
    if player.actor and entryPoint then
        -- 玩家传送中
        player.Teleporting = true
        -- 玩家切换场景
        player:ChangeScene(self.scene)
        -- 初始化玩家位置
        player.actor.Position = entryPoint
        -- 调整摄像机位置
        player:SetCameraView(player.actor.Euler)
        -- 当前玩家
        local currentPlayer = player
        -- 当前初始化位置
        local currentEntryPoint = entryPoint
        -- 当前玩家重力
        local oldGrav = player.actor.Gravity
        -- 当前玩家uin
        local currentUin = player.uin
        -- 打开加载界面
        player:SendEvent("showLoadGameUi", { })
        -- 初始化属性属性
        player:revive()
        if oldGrav > 0 then
            player.actor.Gravity = 0
            ServerScheduler.add(function()
                -- 关闭加载界面
                player:SendEvent("closeLoadGameUi", { })
                -- 关卡未活跃退出
                if not self:IsActive() then
                    gg.log("关卡未活跃退出")
                    return
                end
                -- 关卡没有玩家退出
                if not self.players[currentUin] then
                    gg.log("关卡没有玩家退出")
                    return
                end
                if currentPlayer.actor then
                    currentPlayer.actor.Gravity = oldGrav
                    currentPlayer.actor.Position = currentEntryPoint
                end
                player.Teleporting = false
                BattleDataManager.GetPlayerBattleDataByRole(player.job)
                player:initBattleData(BattleDataManager.default_player_role_battle_data)
            end, 12)
        end
    end
    -- 关闭玩家的城镇界面
    player:SendEvent("CloseCityHud", {})
    return true
end

---查找可用的出生点
function _M:FindAvailableEntryPoint()
    -- 随机坐标位置
    local spawnPoints = gg.randomPointOnCirclePerimeter(self.playerSpawnPoints.x, 200, self.playerSpawnPoints.z, 500)
    return spawnPoints
end

return _M