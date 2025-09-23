------------------------------------------------------------------------------------
-- -*- coding: utf-8 -*-
--
-- @作者:         zhenghao
-- @创建日期:      2025-09-05
-- @模块名称:      Monster
-- @描述:         怪物类
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
---@type ServerScheduler
local ServerScheduler = require(MainStorage.code.server.serverEvent.ServerScheduler)
---@type common_const
local common_const = require(MainStorage.code.common.Const)
---@type IdleBehavior
local IdleBehavior = require(MainStorage.code.server.modelAnimation.IdleBehavior) -- 战立
---@type WanderBehavior
local WanderBehavior = require(MainStorage.code.server.modelAnimation.WanderBehavior) -- 随机移动
---@type MeleeBehavior
local MeleeBehavior = require(MainStorage.code.server.modelAnimation.MeleeBehavior) -- 近战
---@type ServerEventManager
local ServerEventManager = require(MainStorage.code.server.serverEvent.ServerEventManager)
------------------------------------------------------------------------------------

local BehaviorType = {
    ["站立"] = IdleBehavior.New(),
    ["随机移动"] = WanderBehavior.New(),
    ["近战攻击"] = MeleeBehavior.New(),
}

---@class Monster : Class
local _M = ClassMgr.Class('Monster', Entity)

-- 初始化实例类
function _M:OnInit(info)
    self.uuid = gg.create_uuid('p')
    self.mobType = info.mobType
    self.isBoss = self.mobType.data["是首领"]

    self.showHealthBar = self.mobType.data["显示血条"]
    -- 行为
    self.monsterBehavior = info.mobType.data["行为"]

    -- 僵直时间
    self.freezeEndTime = nil
    -- 初始战斗状态
    self.attackTimer = 0
    self.isAttacking = false
    self.skillCheckCounter = 0 -- 初始化技能检查计数器
    -- 是否暴怒状态
    self.isFury = false


    self.name = info.mobType.data["显示名"]

    self.spawnPos = info.position or Vector3.New(-800, 200, 0)
    self.target = nil
    -- 初始化伤害记录
    self.damageRecords = {} ---@type table<string, number> 记录每个玩家造成的伤害

    -- 当前行为配置
    self.currentBehavior = nil
    self.behaviorUpdateTick = 0
end

-- 发布怪物死亡事件
function _M:Die()
    if self.isDead then
        return
    end
    self.isDead = true

    if gg.rand_int(100) < 90 then
        self:dropItem("樱桃")             --掉落物品
    end
    -- 发布怪物死亡事件，包含伤害记录
    ServerEventManager.Publish("MobDeadEvent", {
        mob = self,
        damageRecords = self.damageRecords
    })
    self.actor:NavigateTo(self:GetPosition())
    -- 停止导航
    self.actor:StopNavigate()

    local deathTime = 0
    if self.modelPlayer then
        deathTime = self.modelPlayer:OnDead()
    end
    -- 发布死亡事件
    local evt = {
        entity = self,
        deathTime = deathTime
    }
    ServerEventManager.Publish("EntityDeadEvent", evt)

    if not self:isPlayer() then
        if evt.deathTime > 0 then
            ServerScheduler.add(function()
                self:DestroyObject()
            end, evt.deathTime, nil, "destroy_" .. self.uuid)
        else
            self:DestroyObject()
        end
    end

    -- Entity.Die(self)

end

-- 设置狂暴
function _M:SetFuryType(FuryType)
    self.isFury = FuryType
    if FuryType then
        self:SetAnimationController("狂暴小鹿")
    else
        self:SetAnimationController("正常小鹿")
    end

end

-- 创建怪物模型
function _M:CreateModel(scene,modId)

    -- 创建Actor
    -- 创建路径
    local container = game.WorkSpace["Scene"][scene.name]["怪物容器"]
    -- 克隆节点
    local actor_monster = gg.GetChild(MainStorage["模型列表"]["怪物模型"], self.name)
    -- 克隆
    actor_monster = actor_monster:Clone()
    -- 设置路径
    actor_monster:SetParent(container)
    actor_monster.Enabled = true
    actor_monster.Visible = true
    actor_monster.SyncMode = Enum.NodeSyncMode.NORMAL
    actor_monster.CollideGroupID = common_const.COLLIDE_GROUP.MONSTER
    actor_monster.Name = self.uuid
    if modId then
        actor_monster.ModelId = modId
    end
    -- 设置初始位置
    if self.spawnPos then
        actor_monster.LocalPosition = self.spawnPos
    end

    -- 关联到对象
    self:setGameActor(actor_monster)
    -- 关联状态机
    if self.mobType.data["状态机"] then
        self:SetAnimationController(self.mobType.data["状态机"])
    end

    ServerScheduler.add(function(ret)
        if self.isDestroyed then
            return
        end
        if self.showHealthBar then
            self:CreateTitle()
            gg.log("创建头部")
        else
            gg.log("创建头部失败")
        end
    end, 0.5)

end

---获取玩家造成的伤害
---@param player Player 玩家对象
---@return number 玩家造成的总伤害
function _M:GetPlayerDamage(player)
    if not player or not player.uin then
        return 0
    end
    return self.damageRecords[player.uin] or 0
end

---获取所有玩家的伤害记录
---@return table<string, number> 玩家伤害记录表
function _M:GetAllDamageRecords()
    return self.damageRecords
end

function _M:AddHatred(amount, player)
    local uin = player.uin
    local newHatred = (self.damageRecords[uin] or 0) + amount
    self.damageRecords[uin] = newHatred
    if not self.target then
        self:SetTarget(player)
    end
end

---@override
function _M:Hurt(amount, player)
    if self.mobType.data["被攻击逃跑"] then
        for _, behavior in ipairs(self.monsterBehavior) do
            local behaviorType = behavior["类型"]
            if BehaviorType[behaviorType] and behaviorType == "随机移动" then
                -- 进入新行为
                self.currentBehavior = behavior
                BehaviorType[self.currentBehavior["类型"]]:OnEnter(self)
                break
            end
        end
    end
    -- 记录玩家造成的伤害
    self:AddHatred(amount, player)
    -- 收到攻击
    -- 血量低于0死亡
    Entity.Hurt(self, amount, player)
end

-- 检查怪物是否距离刷新点太远
function _M:checkTooFarFromPos()
    if not self.spawnPos then
        return
    end
    local currentPos = self:GetPosition()

    -- 出生位置 self.spawnPos
    -- 当前位置 currentPos
end

-- 在指定范围内随机刷新位置
function _M:spawnRandomPos(rangeX, rangeY, rangeZ)
    local randomOffset = {
        x = gg.rand_int_both(rangeX),
        y = gg.rand_int(rangeY),
        z = gg.rand_int_both(rangeZ)
    }

    -- 设置新位置
    self.actor.Position = Vector3.New(self.spawnPos.x + randomOffset.x, self.spawnPos.y + randomOffset.y,
            self.spawnPos.z + randomOffset.z)
end


-- 主更新函数
function _M:update_monster()
    -- 调用父类更新
    self:update()
    -- 每1秒更新一次行为状态
    self.behaviorUpdateTick = self.behaviorUpdateTick + 1
    if self.behaviorUpdateTick >= 10 then
        -- 10帧 = 1秒
        self.behaviorUpdateTick = 0
        self:UpdateBehavior()
    end
    -- 每帧更新当前行为
    self:UpdateCurrentBehavior()
end

function _M:update()
    Entity.update(self)
end


-- 更新行为状态
function _M:UpdateBehavior()
    -- 死亡不更新 僵直不更新
    if self.isDead or self:IsFrozen() then
        return
    end
    -- 当前行为类型
    local currentBehaviorType = self.currentBehavior and self.currentBehavior["类型"]
    -- 新的行为类型
    local newBehavior = nil
    -- 是否可切换行为
    local canSwitchBehavior = false
    if not canSwitchBehavior and not self.currentBehavior then
        canSwitchBehavior = true
    end
    if not canSwitchBehavior and currentBehaviorType and BehaviorType[currentBehaviorType] and BehaviorType[currentBehaviorType]:CanExit(self) then
        canSwitchBehavior = true
    end
    if not self.monsterBehavior then
        canSwitchBehavior = false
    end
    if canSwitchBehavior then
        for _, behavior in ipairs(self.monsterBehavior) do
            local behaviorType = behavior["类型"]
            if BehaviorType[behaviorType] and BehaviorType[behaviorType]:CanEnter(self, behavior) then
                newBehavior = behavior
                break
            end
        end
    end
    -- 只有当新行为与当前行为不同时才执行切换
    if newBehavior and (not currentBehaviorType or newBehavior["类型"] ~= currentBehaviorType) then
        -- 退出当前行为
        if currentBehaviorType and BehaviorType[currentBehaviorType] then
            BehaviorType[currentBehaviorType]:OnExit(self)
        end
        -- 进入新行为
        self.currentBehavior = newBehavior
        BehaviorType[newBehavior["类型"]]:OnEnter(self)
    end
end

-- 更新当前行为
function _M:UpdateCurrentBehavior()
    if self:IsFrozen() then
        return
    end
    local currentBehaviorType = self.currentBehavior and self.currentBehavior["类型"]
    if currentBehaviorType and BehaviorType[currentBehaviorType] then
        BehaviorType[currentBehaviorType]:Update(self)
    end
end

function _M:TryFindTarget(detectRange)
    detectRange = detectRange or 0
    -- 获取敌对组
    local enemyGroup = self:GetEnemyGroup()
    local detectRangeSq = detectRange * detectRange
    -- 获取当前位置
    local currentPos = self:GetPosition()
    -- 在场景中检测范围内的敌人
    local enemies = self.scene:OverlapBoxEntity(
            currentPos,
            Vector3.New(detectRange, detectRange, detectRange),
            Vector3.New(0, 0, 0),
            enemyGroup)
    -- 找到最近的有效目标
    local nearestTarget = nil
    local minDistanceSq = detectRangeSq

    for _, entity in ipairs(enemies) do
        -- 检查是否是敌对单位
        if entity.npc_type and not entity.isDead then
            local distanceSq = gg.vec.DistanceSq3(currentPos, entity:GetPosition())
            -- 如果距离更近且目标有效
            if minDistanceSq == 0 or distanceSq < minDistanceSq then
                nearestTarget = entity
                minDistanceSq = distanceSq
            end
        end
    end
    -- 如果找到目标，设置为目标
    if nearestTarget then
        self:SetTarget(nearestTarget)
        return true
    end
    return false
end

-- 获取当前行为配置
function _M:GetCurrentBehavior()
    return self.currentBehavior
end

-- 设置当前行为配置
function _M:SetCurrentBehavior(behavior)
    self.currentBehavior = behavior
end

function _M:IsFrozen()
    if not self.freezeEndTime then
        return false
    end

    local currentTime = os.time()
    if currentTime >= self.freezeEndTime then
        self.freezeEndTime = nil
        return false
    end

    return true
end

function _M:GetAttackDuration()
    return 2
end

---@param duration  number 持续时间，0则为取消冻结
function _M:Freeze(duration)
    if duration == 0 then
        self.freezeEndTime = nil
        return
    end

    local currentTime = os.time()
    local newEndTime = currentTime + duration

    -- 如果已经有冻结时间，取较大的那个
    if self.freezeEndTime then
        self.freezeEndTime = math.max(self.freezeEndTime, newEndTime)
    else
        self.freezeEndTime = newEndTime
    end
end

function _M:DestroyObject()
    if not self.isDead then
        self:Die()
    end
    self.isDestroyed = true
    if self.scene then
        self.scene.monsters[self.uuid] = nil
    end
    if self.actor then
        _M.node2Entity[self.actor] = nil
        self.actor:Destroy()
        self.actor = nil
    end
    ServerEventManager.UnsubscribeByKey(self.uuid)
end

return _M