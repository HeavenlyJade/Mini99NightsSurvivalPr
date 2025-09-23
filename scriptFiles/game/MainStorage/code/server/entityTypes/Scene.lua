------------------------------------------------------------------------------------
-- -*- coding: utf-8 -*-
--
-- @作者:         zhenghao
-- @创建日期:      2025-09-05
-- @模块名称:      Scene
-- @描述:         场景类
-- @版本:         v1.0
------------------------------------------------------------------------------------
-- 引入管理对象
local game = game
local MainStorage = game:GetService("MainStorage")
---@type ClassMgr
local ClassMgr = require(MainStorage.code.common.ClassMgr)
---@type NpcConfig
local NpcConfig = require(MainStorage.config.NpcConfig)
---@type gg
local gg = require(MainStorage.code.common.MGlobal)
---@type ServerEventManager
local ServerEventManager = require(MainStorage.code.server.serverEvent.ServerEventManager)
---@type NPC
local Npc = require(MainStorage.code.server.entityTypes.NPC)
---@type Entity
local Entity = require(MainStorage.code.server.entityTypes.Entity)
---@type common_const
local common_const = require(MainStorage.code.common.Const)
---@type BagMgr
local BagMgr = require(MainStorage.code.server.serverManager.BagManager)

------------------------------------------------------------------------------------
---@class Scene : Class
local _M = ClassMgr.Class('Scene')
local unusedSlots = {} ---@type table[int, int]
local maxSlotRad = 2


-- 初始化实例类
function _M:OnInit(node)
    -- 场景名称
    self.name = node.Name
    -- SandboxNode
    self.node = node
    -- 实体列表
    self.entities = {} ---@type table<number, Entity[]>
    -- NPC列表
    self.npcs = {}
    --掉落物品列表
    self.dropItem = {}
    -- 玩家列表
    self.players = {}
    -- 怪物列表
    self.monsters = {}

    self.uuid2Entity = {}

    self.sceneZone = self.node["场景区域"]


    -- 场景类型
    self.sceneType = common_const.SCENE_TYPE[self.node["场景类型"].Value]
    -- 总tick值(递增)
    self.tick = 0
    gg.server_scene_list[self.name] = self
    -- 注册进入区域事件
    self:JoinScene()
    -- 初始化npc
    self:initNpcs()
    -- 初始化场景可爬楼梯
    self:initStairs()

    ServerEventManager.Subscribe("checkWorldDropItem", function(evt)
        local player = evt.player
        local item = evt.item
        if self.players[player.uin] then
            self:check_dropItem(player.uin, item)
        end
    end)

    -- 没有掉落物容器
    local item_container = self.node["掉落物容器"]

    if item_container then
        for k, v in pairs(item_container.Children) do
            if v.ClassType == 'Model' then
                local drop_item = {
                    uuid = gg.create_uuid('box'),
                    itemType = common_const.ITEM_TYPE.BOX,
                    name = v.Name,
                    model = v
                }
                self.dropItem[drop_item.uuid] = drop_item
            end
        end
    end
end

-- 注册进入区域事件
function _M:JoinScene()
    if self.sceneZone then
        self.sceneZone.Touched:Connect(function(node)
            if node then
                local entity = Entity.node2Entity[node] ---@type Entity
                if entity then
                    entity:ChangeScene(self)
                end
            end
        end)
    end
end

---初始化场景中的NPC
function _M:initStairs()
    local sceneNode = self.node["交互场景"]
    if not sceneNode then
        return false
    end
    local trigger1 = gg.GetChild(sceneNode, "爬楼梯下")
    if trigger1 then
        trigger1.Touched:Connect(function(node)
            if node and node.UserId then
                local player = gg.getPlayerByUin(node.UserId)
                if player then
                    player.modelPlayer:OnClimb()
                end
            end
        end)
        trigger1.TouchEnded:Connect(function(node)
            if node and node.UserId then
                local player = gg.getPlayerByUin(node.UserId)
                if player then
                    player.modelPlayer:OnIdle()
                end
            end
        end)
    end
    local trigger2 = gg.GetChild(sceneNode, "爬楼梯上")
    if trigger2 then
        trigger2.Touched:Connect(function(node)
            if node and node.UserId then
                local player = gg.getPlayerByUin(node.UserId)
                if player then
                    player.modelPlayer:OnClimb()
                  --  player.actor.Animator:Play('Base Layer.paluoti', 0, 0);    --播放动作
                end
            end
        end)
        trigger2.TouchEnded:Connect(function(node)
            if node and node.UserId then
                local player = gg.getPlayerByUin(node.UserId)
                if player then
                    player.modelPlayer:OnIdle()
                   -- player.actor.Animator:Play('Base Layer.Idle', 0, 0);    --播放动作
                end
            end
        end)
    end


end

---初始化场景中的NPC
function _M:initNpcs()
    local all_npcs = NpcConfig.GetAll()
    for npc_name, npc_data in pairs(all_npcs) do
        if npc_data["场景"] == self.name then
            local sceneNode = self.node["NPC"]
            if not sceneNode then
                gg.log("错误：场景中没有NPC节点容器")
                return false
            end
            local actor = gg.GetChild(sceneNode, npc_data["节点名"])
            if actor then
                local npc = Npc.New(npc_data, actor)
                self.uuid2Entity[actor] = npc
                self.npcs[npc.uuid] = npc
                npc:ChangeScene(self)
            end
        end
    end
end

--增加一个箱子物品
function _M:addDropBox(item_)
    item_.tick = gg.tick        --记录tick
    self.dropItem[item_.uuid] = item_
end



--物品被拾取
function _M:check_dropItem(uin, item)
    if table.is_empty(self.dropItem) then
        return
    end
    local desList = {}
    for item_uuid, item_info in pairs(self.dropItem) do
        if item_info.model.Position == item.Position then
            local val = BagMgr.tryGetItem(uin, item_info)
            if val ~= -1 then
                item_info.model:Destroy()
                table.insert(desList, item_uuid)
            end
        end
    end
    for i = 1, #desList do
        self.dropItem[desList[i]] = nil
    end
end

function _M:OverlapBoxEntity(center, extent, angle, filterGroup, filterFunc)
    if extent == Vector3.New(0,0,0) then
        local retEntities = {}
        for actor, entity in pairs(Entity.node2Entity) do
            local add = false
            if actor.CollideGroupID then
                for i, v in ipairs(filterGroup) do
                    if actor.CollideGroupID  == v then
                        add = true
                        break
                    end
                end
            end
            if add then
                table.insert(retEntities, entity)
            end
        end
        return retEntities
    else
        local nodes = self:OverlapBox(center, extent, angle, filterGroup, filterFunc)
        local retEntities = {}
        for _, node in ipairs(nodes) do
            local entity = Entity.node2Entity[node]
            if entity then
                table.insert(retEntities, entity)
            end
        end
        return retEntities
    end
end

function _M:OverlapBox(center, extent, angle, filterGroup, filterFunc)
    local results = game:GetService('WorldService'):OverlapBox(
            Vector3.New(extent.x, extent.y, extent.z),
            Vector3.New(center.x, center.y, center.z),
            Vector3.New(angle.x, angle.y, angle.z),
            false,
            filterGroup)
    local retActors = {}
    for _, v in ipairs(results) do
        local obj = v.obj
        table.insert(retActors, obj)
        if filterFunc then
            filterFunc(obj)
        end
    end
    return retActors
end

-- 场景更新
---每一帧更新
function _M:update()
    if next(self.players) == nil then
        return -- 场景内没有玩家
    end
    self.tick = self.tick + 1
    -- 更新每一个玩家
    for _, player_ in pairs(self.players) do
        player_:update_player()
    end
    -- 更新每一个怪物
    local num = 0
    for _, monster_ in pairs(self.monsters) do
        num = num + 1
        monster_:update_monster()
    end
end


function _M:PlaySound(soundAssetId, boundTo, volume, pitch, range)
    if soundAssetId == "" then
        return
    end
    for _, player in pairs(self.players) do
        player:PlaySound(soundAssetId, boundTo, volume, pitch, range)
    end
end


---@return Scene
function _M:Clone()
    if #unusedSlots == 0 then
        maxSlotRad = maxSlotRad + 1
        -- 生成新的方形环坐标
        for x = -maxSlotRad, maxSlotRad do
            for y = -maxSlotRad, maxSlotRad do
                -- 只添加方形环上的点（不包括内部点）
                if math.abs(x) == maxSlotRad or math.abs(y) == maxSlotRad then
                    -- 将坐标转换为单个数字（使用位运算）
                    local slot = { x, y }
                    table.insert(unusedSlots, slot)
                end
            end
        end
    end

    if #unusedSlots == 0 then
        error("No available slots for scene cloning")
    end

    local slot = unusedSlots[#unusedSlots]
    unusedSlots[#unusedSlots] = nil
    local node = self.node:Clone()
    node.Position = Vector3.New(100000 * slot[1], 0, 100000 * slot[2])
    if node["副本隐藏"] then
        node["副本隐藏"].Visible = true
        for _, child in ipairs(node["副本隐藏"].Children) do
            child.EnablePhysics = true
        end
    end
    node.Parent = self.node.Parent
    node.Name = self.name .. string.format("_%s_%s", slot[1], slot[2])
    return _M.New(node)
end



-- 当一个怪物目标血量变化的时候，更新所有关注它的生物的目标血条
function _M:updateTargetHPMPBar( uuid_ )
    for uin_, player_ in pairs( self.players ) do
        if  player_.target and player_.target.uuid == uuid_ then
            local tar_ = player_.target.battle_data
            --local info_ = {
            --    cmd = 'cmd_sync_target_info',
            --    show = 1,
            --    hp=tar_.hp,
            --    mp=tar_.mp,
            --    hp_max=tar_.hp_max,
            --    mp_max=tar_.mp_max,
            --}
            --gg.network_channel:fireClient( uin_, info_ )
        end
    end
end

---玩家离开场景
---@param player Player 玩家对象
function _M:player_leave(player)
    if not player or not player.uin then
        return
    end

    if self.players[player.uin] then
        -- 从所有NPC中移除玩家
        for _, npc in pairs(self.npcs) do
            npc.nearbyPlayers[player.uin] = nil
        end
        -- 从场景玩家列表中移除
        self.players[player.uin] = nil
    end

end

return _M