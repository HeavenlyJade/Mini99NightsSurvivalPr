------------------------------------------------------------------------------------
-- -*- coding: utf-8 -*-
--
-- @作者:         zhenghao
-- @创建日期:      2025-09-05
-- @模块名称:      ServerMain
-- @描述:         服务端入口
-- @版本:         v1.0
-----------------------------------------------------------------------------------
-- 引入管理对象
local game = game
local Vector3 = Vector3
local MainStorage     = game:GetService("MainStorage")

local players = game:GetService("Players")
---@type CloudDataMgr
local cloudDataMgr  = require(MainStorage.code.server.CloudDataMgr)
---@type ClassMgr
local ClassMgr    = require(MainStorage.code.common.ClassMgr)
---@type ServerEventManager
local ServerEventManager = require(MainStorage.code.server.serverEvent.ServerEventManager)
---@type ServerScheduler
local ServerScheduler = require(MainStorage.code.server.serverEvent.ServerScheduler)
---@type gg
local gg                = require(MainStorage.code.common.MGlobal)
---@type common_const
local common_const = require(MainStorage.code.common.Const)
---@type Scene
local Scene      = require(MainStorage.code.server.entityTypes.Scene)
---@type MiniShopManager
local MiniShopManager = require(MainStorage.code.server.serverEvent.MiniShopManager)
---@type BattleMgr
local BattleMgr = require(MainStorage.code.common.battle.BattleMgr)
------------------------------------------------------------------------------------
---@class ServerMain
local ServerMain = ClassMgr.Class("ServerMain")
-- 初始化完成
local initFinished = false
-- 存储等待初始化的玩家
local waitingPlayers = {}

-- 入口函数
function ServerMain.startServer()
    -- 随机种子
    math.randomseed(os.time() + gg.GetTimeStamp())

    --玩家进出游戏
    ServerMain.register_player_in_out()

    -- 初始化场景
    for _, node in  pairs(game.WorkSpace.Scene.Children) do
        Scene.New( node )
    end

    game:GetService("PhysXService"):SetCollideInfo(common_const.COLLIDE_GROUP.PLAYER, common_const.COLLIDE_GROUP.PLAYER, false)
    game:GetService("PhysXService"):SetCollideInfo(common_const.COLLIDE_GROUP.MONSTER, common_const.COLLIDE_GROUP.MONSTER, false)
    game:GetService("PhysXService"):SetCollideInfo(common_const.COLLIDE_GROUP.ITEM, common_const.COLLIDE_GROUP.ITEM, false)
    game:GetService("PhysXService"):SetCollideInfo(common_const.COLLIDE_GROUP.ITEM, common_const.COLLIDE_GROUP.MONSTER, false)
    game:GetService("PhysXService"):SetCollideInfo(common_const.COLLIDE_GROUP.ITEM, common_const.COLLIDE_GROUP.PLAYER, false)
    game:GetService("PhysXService"):SetCollideInfo(6, common_const.COLLIDE_GROUP.PLAYER, false)

    -- 建立网络通道
    ServerMain.createNetworkChannel()

    --云服务器启动配置文件下载和解析繁忙，稍微等待
    wait(1)

    BattleMgr.InitBattleConfig()

    ServerMain.bind_update_tick()         --开始tick

    initFinished = true
    for _, player in ipairs(waitingPlayers) do
        ServerMain.player_enter_game(player)
    end

    ServerEventManager.Subscribe("ClickMenu", function (evt)
        if evt.PageName then
            local CustomUIConfig = require(MainStorage.config.CustomUIConfig) ---@type CustomUIConfig
            local customUI = CustomUIConfig.Get(evt.PageName)
            customUI:S_Open(evt.player)
        end
    end)

    -- 标记服务器初始化完成，发布所有待发布的事件
    ServerEventManager.SetServerInitialized()
end

function ServerMain.register_player_in_out()
    players.PlayerAdded:Connect(function(player)

        if initFinished then
            gg.log("PlayerAdded Connect")
            ServerMain.player_enter_game(player)
        else
            table.insert(waitingPlayers, player)
        end
    end)
    players.PlayerRemoving:Connect(function(player)
        -- 如果玩家在等待列表中，需要移除
        for i, waitingPlayer in ipairs(waitingPlayers) do
            if waitingPlayer.UserId == player.UserId then
                table.remove(waitingPlayers, i)
                break
            end
        end
        --玩家离开游戏
        ServerMain.player_leave_game(player)
    end)
end


--玩家进入游戏，数据加载
function ServerMain.player_enter_game(player)
    player.DefaultDie = false   --取消默认死亡
    local uin_ = player.UserId
    --强制离开游戏
    if gg.server_players_list[uin_] then
        gg.server_players_list[uin_]:OnLeaveGame()
    end

    --加载玩家历史数据
    local ret1_, cloud_player_data_ = cloudDataMgr.ReadPlayerData(uin_)
    if ret1_ == 0 then
        gg.network_channel:fireClient(uin_, { cmd="SendHoverText", txt='加载玩家等级数据成功' })     --飘字
    else
        gg.network_channel:fireClient(uin_, { cmd="SendHoverText", txt='加载玩家等级数据失败，请退出游戏后重试' })    --飘字
        gg.log("加载数据网络层失败")
        return   --加载数据网络层失败
    end
    local actor_ = player.Character
    -- 碰撞组
    actor_.CollideGroupID = common_const.COLLIDE_GROUP.PLAYER
    -- 移动速度
    actor_.Movespeed = 350
    --碰撞盒子的大小
    actor_.Size = Vector3.New(80, 160, 80)
    --盒子中心位置
    actor_.Center = Vector3.New(0, 80, 0)
    ---@type Player
    local Player       = require(MainStorage.code.server.entityTypes.Player)
    -- 玩家信息初始化
    local player_ = Player.New({
        -- 玩家坐标
        position = Vector3.New(600, 400, -3400),
        -- 玩家uin
        uin=uin_,
        -- 玩家昵称
        nickname=player.Nickname,
        -- 类型
        npc_type= common_const.NPC_TYPE.PLAYER,
        -- 玩家当前职业
        job = cloud_player_data_.job,
        -- 玩家货币
        money = cloud_player_data_.money,
        -- 称号
        myTitle = cloud_player_data_.myTitle,
        -- 最高存活天数
        maxSurvivalDays = cloud_player_data_.maxSurvivalDays,
        -- 职业列表
        jobData = cloud_player_data_.jobData
    })
    -- 加入玩家信息
    gg.server_players_list[uin_] = player_
    -- 加入玩家名称列表
    gg.server_players_name_list[player.Nickname] = player_
    -- 设置actor
    player_:setGameActor(actor_)
    -- 设置网络状态
    player_:setPlayerNetStat(common_const.PLAYER_NET_STAT.LOGIN_IN)    --player_net_stat login ok
    -- 设置状态机
    player_:SetAnimationController("玩家")
    -- 复活刷新属性
    player_:revive()
    -- 同步玩家头标记
    player_:CreateTitle()
    -- 同步玩家信息
    player_:UpdateHud()
end

--玩家离开游戏
function ServerMain.player_leave_game(player)
    local uin_ = player.UserId
    if gg.server_players_list[uin_] then
        -- 离开游戏
        gg.server_players_list[uin_]:OnLeaveGame()
        -- 保存数据
        gg.server_players_list[uin_]:Save()
    end
    gg.server_players_name_list[player.Name] = nil
    gg.server_players_list[uin_] = nil
end

--建立网络通道
function ServerMain.createNetworkChannel()
    gg.network_channel = MainStorage:WaitForChild("NetworkChannel")
    gg.network_channel.OnServerNotify:Connect(ServerMain.OnServerNotify)
end

--消息回调 (优化版本，使用命令表和错误处理)
function ServerMain.OnServerNotify(uin_, args)
    if type(args) ~= 'table' then return end
    if not args.cmd then return end
    local player_ = gg.getPlayerByUin(uin_)
    if not player_ then
        return
    end
    args.player = player_
    if args.__cb then
        args.Return = function(returnData)
            game:GetService("NetworkChannel"):fireClient({
                cmd = args.__cb .. "_Return",
                data = returnData
            })
        end
    end
    -- 自动判断：如果玩家有该事件的本地订阅，则作为本地事件发布，否则作为全局事件广播
    if ServerEventManager.HasLocalSubscription(player_, args.cmd) then
        ServerEventManager.PublishToPlayer(player_, args.cmd, args)
    else
        ServerEventManager.Publish(args.cmd, args)
    end
end


--开启update
function ServerMain.bind_update_tick()
    -- 一个定时器, 实现tick update
    local timer = SandboxNode.New("Timer", game.WorkSpace)
    timer.LocalSyncFlag = Enum.NodeSyncLocalFlag.DISABLE

    timer.Name = 'timer_server'
    timer.Delay = 0.1      -- 延迟多少秒开始
    timer.Loop = true      -- 是否循环
    timer.Interval = 0.03   -- 循环间隔多少秒 (1秒=20帧)
    timer.Callback = ServerMain.update
    timer:Start()     -- 启动定时器
    gg.timer = timer;
end

--定时器update
function ServerMain.update()
    gg.tick = gg.tick + 1
    --更新场景
    for _, scene_ in pairs(gg.server_scene_list) do
        scene_:update()
    end

    ServerScheduler.tick = gg.tick  -- 对于服务器端
    ServerScheduler.update()  -- 对于服务器端
end

return ServerMain