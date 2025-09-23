------------------------------------------------------------------------------------
-- -*- coding: utf-8 -*-
--
-- @作者:         zhenghao
-- @创建日期:      2025-09-05
-- @模块名称:      Entity
-- @描述:         管理单个场景中的actor实例和有共性的属性，被包含在 player monster boss中
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
---@type common_const
local common_const = require(MainStorage.code.common.Const)
---@type ModelPlay
local ModelPlay = require(MainStorage.code.server.modelAnimation.ModelPlay)
---@type AnimationConfig
local AnimationConfig = require(MainStorage.config.AnimationConfig)
---@type ServerEventManager
local ServerEventManager = require(MainStorage.code.server.serverEvent.ServerEventManager)
---@type ServerScheduler
local ServerScheduler = require(MainStorage.code.server.serverEvent.ServerScheduler)
---@type ItemTypeConfig
local ItemTypeConfig = require(MainStorage.config.ItemConfig)
------------------------------------------------------------------------------------
---@class Entity : Class
---@field health number 血量
---@field maxHealth number 最大血量
---@field isDead boolean 是否死亡
local _M = ClassMgr.Class("Entity")
_M.node2Entity = {}
local BATTLE_STAT_IDLE = common_const.BATTLE_STAT.IDLE
local BATTLE_STAT_FIGHT = common_const.BATTLE_STAT.FIGHT
local BATTLE_STAT_DEAD_WAIT = common_const.BATTLE_STAT.DEAD_WAIT
local BATTLE_STAT_WAIT_SPAWN = common_const.BATTLE_STAT.WAIT_SPAWN
-- 初始化实例类
function _M:OnInit(info)
    -- info
    self.info = info
    -- uin
    self.uin = info.uin or 0
    -- 实例类型
    self.npc_type = info.npc_type or common_const.NPC_TYPE.INIT
    -- 场景
    self.scene = nil
    --场景名字
    self.scene_name = info.scene_name
    -- 游戏实例
    self.actor = nil
    -- 当前目标
    self.target = nil
    --原始速度
    self.orgMoveSpeed = 0
    --武器速度
    self.weapon_speed = 1
    --武器
    self.model_weapon = nil
    --头顶名字和等级
    self.name_title = nil
    --伤害飘字
    self.bb_damage = nil
    -- cd列表
    self.cd_list = {}
    --总tick值(递增)
    self.tick = 0
    --等待状态tick值(递减)（剧情使用）
    self.wait_tick = 0
    --最后一个播放的动作
    self.last_anim = ''
    --战斗状态： 空闲 战斗 死亡 复活
    self.battle_stat = BATTLE_STAT_IDLE -- 默认空闲
    --每个状态下的数据
    self.stat_data = {
        idle = { select = 0, wait = 0 }, --monster
        fight = { wait = 0 }, --monster

        wait_spawn = { wait = 0 },
        dead_wait = { wait = 0 },
    }
    --战斗配置
    self.battle_config = nil
    --战斗数据
    self.battle_data = {
        hp = 100,               -- 当前生命值
        hp_max = 100,           -- 最大生命值
        hp_add = 0.2,           -- 每秒恢复血量速度

        hunger = 100,           -- 饥饿度
        hunger_max = 100,       -- 最大饥饿度
        hunger_reduced = 0.1,   -- 每秒减少饥饿度

        energy = 100,           -- 能量条
        energy_max = 100,       -- 最大能量条
        energy_add = 0.1,       -- 每秒恢复能量条

        attack = 0,             -- 攻击力
        defence = 0,            -- 防御力

        SurvivalDays = 0,       -- 生存天数

        interact_speed = 6,      -- 交互速度
        attack_speed = 500,     -- 攻击速度
        move_speed = 500,       -- 移动速度
        reload_speed = 0,        -- 换弹速度

        -- 背包信息
        bagInfo = {
            [1] = { name = "袋子", num = 1, canDrop = false, Stackable = false },
            [2] = { name = "石斧", num = 1, canDrop = false, Stackable = false },
            [3] = { name = "樱桃", num = 5, canDrop = true, Stackable = true },
        },
        -- 材料背包
        smallBagInfo = {


        },
    }
    --所有装备词缀
    self.eq_attrs = {}
    --玩家状态标志位
    self.stat_flags = {
        --skill_uuid            --当前技能实例uuid( 释法中 )
        --cast_time             --技能施法时间
        --cast_time_max         --技能施法时间最大值
        --cast_pos              --施法开始时候的位置

        --stun = 1              --晕迷
        --stun_tick = 10,       --晕迷时间
        --slow = 1              --减速
        --slow_tick = 10,       --减速时间
        --swim = 1              --游泳中
    }
    -- 产生位置
    self.spawnPos = info.position or Vector3.New(0, 0, 0)
    -- 是否已死亡
    self.isDead = false
end

--是否是一个玩家
function _M:isPlayer()
    return self.npc_type == common_const.NPC_TYPE.PLAYER
end

--是否是一个怪物
function _M:isMonster()
    return self.npc_type == common_const.NPC_TYPE.MONSTER
end

-- 设置游戏场景中使用的actor实例
function _M:setGameActor(actor_)
    self.actor = actor_
    -- 设置玩家初始速度
    if self.orgMoveSpeed == 0 then
        self.orgMoveSpeed = self.actor.Movespeed
    end
    if actor_:IsA("Actor") then
        -- 物理类型
        actor_.PhysXRoleType = Enum.PhysicsRoleType.BOX
        -- 忽略同步流
        actor_.IgnoreStreamSync = false
    end
    _M.node2Entity[actor_] = self
    -- 添加到场景的ColliderGroup实体列表中
    if self.scene and actor_.CollideGroupID then
        local groupId = actor_.CollideGroupID
        if not self.scene.entities[groupId] then
            self.scene.entities[groupId] = {}
        end
        table.insert(self.scene.entities[groupId], self)
    end
end

-- 玩家改变场景
---@param new_scene string|Scene
function _M:ChangeScene(new_scene)
    if type(new_scene) == "string" then
        new_scene = gg.server_scene_list[new_scene]
    end
    -- 在指定场景中
    if self.scene and self.scene == new_scene then
        return
    end

    -- 离开旧场景
    if self.scene then
        -- 从旧场景的注册表中移除
        self.scene.uuid2Entity[self.uuid] = nil
        -- 从ColliderGroup实体列表中移除
        if self.actor and self.actor.CollideGroupID then
            local groupId = self.actor.CollideGroupID
            if self.scene.entities[groupId] then
                for i, entity in ipairs(self.scene.entities[groupId]) do
                    if entity == self then
                        table.remove(self.scene.entities[groupId], i)
                        break
                    end
                end
            end
        end

        -- 如果是怪物，还需要从怪物列表中移除
        if self.npc_type == common_const.NPC_TYPE.PLAYER then
            -- 从玩家列表中移除
            self.scene:player_leave(self)
        elseif self.npc_type == common_const.NPC_TYPE.MONSTER then
            -- 从怪物列表中移除
            self.scene.monsters[self.uuid] = nil
        end
    end

    -- 进入新场景
    self.scene = new_scene
    self.scene.uuid2Entity[self.uuid] = self

    -- 添加到新场景的ColliderGroup实体列表中
    if self.actor and self.actor.CollideGroupID then
        local groupId = self.actor.CollideGroupID
        if not new_scene.entities[groupId] then
            new_scene.entities[groupId] = {}
        end
        table.insert(new_scene.entities[groupId], self)
    end

    -- 如果是玩家，还需要添加到玩家列表中
    if self.npc_type == common_const.NPC_TYPE.PLAYER then
        new_scene.players[self.uin] = self
        self:SendEvent("PlayerSwitchScene", { sceneType = self.scene.sceneType, name = self.scene.name })
        if self.scene.sceneType == "战斗场景" then
            -- 玩家游戏内属性

        elseif self.scene.sceneType == "主场景" then
            -- 初始化属性

        end
    elseif self.npc_type == common_const.NPC_TYPE.MONSTER then
        new_scene.monsters[self.uuid] = self
    end
end

-- 创建标签名字
function _M:CreateTitle()
    if not self.actor then
        return
    end
    -- 判断是否有标签
    local name_title = self.name_title
    if not self.name_title then
        if self._initTitle then
            return
        end
        self._initTitle = true
        local title = MainStorage["模型列表"]["名字标签"]
        if self.npc_type == common_const.NPC_TYPE.PLAYER then
            title = title["player"]
        elseif self.npc_type == common_const.NPC_TYPE.MONSTER then
            title = title["Monster"]
        else
            return
        end
        if title then
            -- 克隆名称
            name_title = title:Clone()
            name_title.Parent = self.actor
            name_title.LocalPosition = title.LocalPosition + Vector3.New(0, self.actor.Size.y + 40 / self.actor.LocalScale.y, 0)
            name_title.Name = "name_title"
            self.name_title = name_title
            self.name_title["名字"].Title = self.name
        end
    end
    if self.name_title then
        if self.npc_type == common_const.NPC_TYPE.PLAYER then
            self.name_title["称号"].Title = self.myTitle
            self.name_title["职业存活列表"]["职业"].Icon = common_const.JOB_ICON[self.job] or ""
            self.name_title["职业存活列表"]["职业名称"].Title = self.job
            self.name_title["职业存活列表"]["生存天数"].Title = tostring(self.maxSurvivalDays)
        elseif self.npc_type == common_const.NPC_TYPE.MONSTER then
            local bar = self.name_title["血条底图"]["血条"]
            bar.FillAmount = 1
            self.hp_bar = bar
        end
    end
end

-- 获取在游戏世界的坐标位置
function _M:GetPosition()
    return self.actor and self.actor.LocalPosition or Vector3.New(0, 0, 0)
end

--装备物品,通过物品列表的名称装备物品
function _M:equipWeapon(itemName)
    -- 物品ModelId
    local model_src_
    if not itemName or itemName == "" then
        -- 不装备
        model_src_ = ""
    else
        local ModelData = gg.GetFromTemplate(itemName)
        -- 装备 模型列表/物品列表 的指定物品
        model_src_ = ModelData and ModelData.ModelId or ""
    end
    if self.model_weapon then
        self.model_weapon.ModelId = model_src_
    else
        if self.actor and self.actor.Hand then
            local model = SandboxNode.new('Model', self.actor.Hand)
            model.Name = 'weapon'
            model.EnablePhysics = false
            model.CanCollide = false
            model.CanTouch = false
            model.ModelId = model_src_     --模型
            model.LocalScale = Vector3.new(2, 2, 2)
            self.model_weapon = model
        end
    end
end

-- 传送到指定位置
function _M:TeleportPos(Position)
    local TeleportService = game:GetService('TeleportService')
    TeleportService:Teleport(self.actor, Position)
end

-- 设置动画
function _M:SetAnimationController(name)
    if self.modelPlay and self.modelPlay.name == name then
        return
    end
    if self.modelPlay then
        -- 注销走路回调
        self.modelPlay.walkingTask:Disconnect()
        -- 注销站立回调
        self.modelPlay.standingTaskId:Disconnect()
        -- 注销 modelPlayer
        self.modelPlay = nil
    end

    if name then
        local animationConfig = AnimationConfig.Get(name)
        local animator = self.actor.Animator

        if animator and animationConfig then
            self.modelPlayer = ModelPlay.New(name, animator, animationConfig)
            -- if self.npc_type ~= common_const.NPC_TYPE.PLAYER then
            self.modelPlayer.walkingTask = self.actor.Walking:Connect(function(isWalking)

                if isWalking then
                    self.modelPlayer:OnWalk()
                end
            end)

            self.modelPlayer.standingTaskId = self.actor.Standing:Connect(function(isStanding)
                if isStanding then
                    self.modelPlayer:OnIdle()
                end
            end)
            self.modelPlayer.standingTaskId = self.actor.Jumping:Connect(function(isJumping)
                if isJumping then
                    self.modelPlayer:OnJump()
                end
            end)



            self.modelPlayer.standingTaskId = self.actor.Flying:Connect(function(isFlying)
                if not isFlying then
                    self.modelPlayer:OnIdle()
                end
            end)
        end
    end
end

-- 获取模型大小
function _M:GetSize()
    if not self.actor then
        print(debug.traceback())
        return Vector3.zero
    end
    local size = self.actor.Size
    local scale = self.actor.LocalScale
    return Vector3.New(size.x * scale.x, size.y * scale.y, size.z * scale.z)
end

--------------
-- 战斗逻辑
-------------
--初始化战斗数值
function _M:initBattleData(config_)
    self.battle_data = config_
    self:resetBattleData(true)
end

--重置所有属性
function _M:resetBattleData(resetHpMp)
    if not self:isPlayer() then
        if self.battle_data.hp_factor then
            self.battle_data.hp_max = self.battle_data.hp_max * self.battle_data.hp_factor
        end
    end

    -- 初始化血量
    if resetHpMp then
        self.battle_data.hp = self.battle_data.hp_max
        self.battle_data.hunger = self.battle_data.hunger_max
        self.battle_data.energy = self.battle_data.energy_max
    end

    --控制血量最大值
    if self.battle_data.hp > self.battle_data.hp_max then
        self.battle_data.hp = self.battle_data.hp_max
    end
    --控制饥饿最大值
    if self.battle_data.hunger > self.battle_data.hunger_max then
        self.battle_data.hunger = self.battle_data.hunger_max
    end
    --控制能量最大值
    if self.battle_data.energy > self.battle_data.energy_max then
        self.battle_data.energy = self.battle_data.energy_max
    end

    self:refreshHpMpBar()
    self:calculateMoveSpeed()
end

-- 设置目标
---@param target Entity|nil
function _M:SetTarget(target)
    self.target = target
end

-- 设置敌对组 3和4相互敌对 其他敌对3和4
function _M:GetEnemyGroup()
    if not self.actor then
        print(debug.traceback())
        return { 1 }
    end
    local groupId = self.actor.CollideGroupID
    if groupId == 3 then
        return { 4 }
    elseif groupId == 4 then
        return { 3 }
    else
        return { 3, 4 }
    end
end

--无法被攻击状态
function _M:canNotBeenAttarked()
    -- 被击败 (等待重生或者清理)
    if self.battle_stat == common_const.BATTLE_STAT.DEAD_WAIT or
            --等待重生
            self.battle_stat == common_const.BATTLE_STAT.WAIT_SPAWN then
        return true
    end
    if self.isDead then
        return true
    end
    return false
end

-- 攻击目标
---@param victim Entity 目标对象
---@param baseDamage number 基础伤害
---@param source string|nil 伤害来源
function _M:Attack(victim, baseDamage, source, castParam)
    victim:Hurt(baseDamage, self)
end

--施法成功后，设置cd并扣除魔法值
function _M:setAttackSpellByConfig(skillType, skill_config)
    if skill_config.speed and skill_config.speed > 0 then
        local currentTime = gg.GetTimeStamp()
        self.cd_list[skillType] = { last = currentTime + (skill_config.speed * 1.1) }
    end
    -- CD 减CD 蓝量减蓝量 物品减物品
end

--检测攻击前置条件： cd时间  mp魔法值 等
function _M:checkAttackSpellConfig(skill_type, skill_config)
    if skill_config.speed and skill_config.speed > 0 then
        local currentTime = gg.GetTimeStamp()
        --攻速
        if not self.cd_list[skill_type] then
            self.cd_list[skill_type] = { last = 0 }
        end
        --获得攻速帧
        local attack_speed = self:getAttackSpeedTick() / 1000
        -- 攻击间隔
        if currentTime + attack_speed < self.cd_list[skill_type].last then
            return 1
        end
    end
    return 0
end

--获得攻速帧
function _M:getAttackSpeedTick()
    --默认攻速都是1.2=12帧   1=10帧
    if not self.battle_data.attack_speed then
        self.battle_data.attack_speed = self.weapon_speed * 10
    end
    return self.battle_data.attack_speed
end


--设置攻击前置时间， 施法前摇，标志位和时间
function _M:setSkillCastTime(battle_uuid, cast_time)
    local stat_flags_ = self.stat_flags
    if not stat_flags_.skill_uuid then
        stat_flags_.skill_uuid = battle_uuid
        stat_flags_.cast_time = cast_time
        stat_flags_.cast_time_max = cast_time

        stat_flags_.cast_pos = self.actor.Position

        gg.network_channel:fireClient(self.uin, { cmd = 'cmd_player_spell', v = stat_flags_.cast_time, max = stat_flags_.cast_time_max })
        return 0
    end
    return 1
end




-- 被击中 被攻击
function _M:Hurt(amount, player)
    -- 血量低于0死亡
    self.battle_data.hp = self.battle_data.hp - amount
    if self.battle_data.hp <= 0 then
        self.battle_data.hp = 0
        if self.hp_bar then
            self.hp_bar.FillAmount = 0
        end
        self:Die()
        return false
    else
        self.modelPlayer:OnHurt()
        self:refreshHpMpBar()
    end
    if self:isPlayer() then
        -- 受伤通知客户端
        self:SendEvent("PlayerShowHurtImg", {})
        if player.isBoss then
            gg.log("被BOSS",player.name,"击中")
            -- 显示抓击
            self:SendEvent("PlayerShowHurtBossImg", {})
        end
    else
        self:SetTarget(player)
        self:calculateMoveSpeed()
    end
end

--加血
function _M:spellHealth(hp_, hunger)
    --额外加成
    local role_add_hp = self.battle_data.role_add_hp or 0
    local role_add_hunger = self.battle_data.role_add_hunger or 0
    if hp_ then
        self.battle_data.hp = self.battle_data.hp + hp_ + role_add_hp
        if self.battle_data.hp > self.battle_data.hp_max then
            self.battle_data.hp = self.battle_data.hp_max
        end
    end
    if hunger then
        self.battle_data.hunger = self.battle_data.hunger + hunger + role_add_hunger
        if self.battle_data.hunger > self.battle_data.hunger_max then
            self.battle_data.hunger = self.battle_data.hunger_max
        end
    end
    self:refreshHpMpBar()
end

-- 刷新蓝/血
function _M:refreshHpMpBar()
    if self.hp_bar then
        local rate_ = self.battle_data.hp / self.battle_data.hp_max
        self.hp_bar.FillAmount = rate_
    end
end

--检查异常状态
--skill_uuid = 1        --释法中 cast_time
--stun = 1              --晕迷
--slow = 1              --减速
--swim = 1              --游泳中
function _M:checkAbnormalStatFlags(tick_)
    local stat_flags_ = self.stat_flags

    --施法中



    --减速中
    if stat_flags_.slow then
        if stat_flags_.slow_tick > 0 then
            stat_flags_.slow_tick = stat_flags_.slow_tick - tick_
        else
            stat_flags_.slow = nil
            stat_flags_.slow_tick = nil
            self:calculateMoveSpeed()
        end
    end

end

--计算行走速度
function _M:calculateMoveSpeed()
    local speed_ = self.orgMoveSpeed
    if not self:isPlayer() then
        --怪物的速度，血量越低越慢
        local rate_ = self.battle_data.hp / self.battle_data.hp_max
        if rate_ < 0.5 then
            rate_ = 0.5
        elseif rate_ > 1 then
            rate_ = 1
        end
        speed_ = speed_ * rate_
    end

    if self.stat_flags.slow then
        speed_ = speed_ * self.stat_flags.slow
    end
    if self.actor then
        self.actor.Movespeed = speed_
    end
end

--被减速
function _M:slowDown(tick_, v_)
    local stat_flags_ = self.stat_flags
    stat_flags_.slow_tick = tick_
    stat_flags_.slow = v_
    self:calculateMoveSpeed()
end

-- 死亡逻辑
function _M:Die()

end

--判断当前目标是否丢失(隐身 复活中)
function _M:checkTargetLost()
    if self.target.battle_stat == BATTLE_STAT_WAIT_SPAWN then
        self.target = nil
    elseif not self.target.actor then
        self.target = nil
    elseif self.target.actor.Visible == false then
        self.target = nil
    elseif self.target.isDead then
        self.target = nil
    end
end

--复活
function _M:revive()
    -- 显示玩家
    self.actor.Visible = true
    --重置所有属性
    self:resetBattleData(true)
    -- 设置目标为空
    if self:isPlayer() then
        self.target = nil         --怪物复活 失去目标
    end
    -- 播放站立动画
    self.modelPlayer:OnIdle()
    -- 复活
    self.isDead = false
end

--展示复活特效
function _M:showReviveEffect(pos_)
    local function thread_wrap()
        --爆炸特效
        local expl = SandboxNode.new('DefaultEffect', self.actor)
        expl.AssetID = 'sandboxSysId://particles/item_137_red.ent' --复活特效
        expl.Position = Vector3.new(pos_.x, pos_.y, pos_.z)
        expl.LocalScale = Vector3.new(3, 3, 3)
        wait(1.5)
        expl:Destroy()
    end
    gg.thread_call(thread_wrap)
end

-- 建筑物
function _M:Build(data)
    local x,y,z = data.x,data.y,data.z
    local name = data.name
    --建立模型
    local buildItem = gg.cloneFromArchitecture(name)     --克隆（速度更快）
    -- 获取掉落物容器
    buildItem.Parent = gg.serverGetContainerArchitecture(self.scene.name)
    -- 节点名称
    buildItem.Name = name
    -- 是否显示
    buildItem.Visible = true

    buildItem.Position = Vector3.new(x,y,z)

end

-- 怪物被击败后掉落物品逻辑
function _M:dropItem(itemName)
    if itemName == "" then
        return
    end
    --建立模型
    local drop_box_ = gg.cloneFromTemplate(itemName)     --克隆（速度更快）
    -- 获取掉落物容器
    drop_box_.Parent = gg.serverGetContainerDropItems(self.scene.name)
    -- 节点名称
    drop_box_.Name = itemName
    -- 是否显示
    drop_box_.Visible = true
    --起始点
    local pos_ = self.actor.Position
    drop_box_.Position = Vector3.new(pos_.x + gg.rand_int(50), pos_.y + 50, pos_.z + gg.rand_int(50))
    -- 设置相对大小？
    drop_box_.LocalScale = Vector3.new(2, 2, 2)
    -- 碰撞影响
    drop_box_.Anchored = false
    -- 重力
    drop_box_.EnableGravity = true
    -- 是否可碰撞
    drop_box_.CanCollide = true
    -- 是否碰撞函数
    drop_box_.CanTouch = false
    -- 碰撞组
    drop_box_.CollideGroupID = common_const.COLLIDE_GROUP.ITEM    --只与地面碰撞
    -- 摩擦力
    drop_box_.Friction = 0.5

    --掉落一个随机品质的箱子
    local drop_item = ItemTypeConfig.Get(drop_box_.Name):ToItem(1)
    drop_item.model = drop_box_

    --drop_item
    -- 场景增加物品
    if self.scene then
        self.scene:addDropBox(drop_item)
    end
end

-- 移除对象
function _M:DestroyObject()
    if not self.isDead then
        self:Die()
    end
    self.isDestroyed = true

    -- 从场景的ColliderGroup实体列表中移除
    if self.scene and self.actor and self.actor.CollideGroupID then
        local groupId = self.actor.CollideGroupID
        if self.scene.entities[groupId] then
            for i, entity in ipairs(self.scene.entities[groupId]) do
                if entity == self then
                    table.remove(self.scene.entities[groupId], i)
                    break
                end
            end
        end
    end

    if self.actor then
        _M.node2Entity[self.actor] = nil
        self.actor:Destroy()
        self.actor = nil
    end
    ServerEventManager.UnsubscribeByKey(self.uuid)
end

--tick刷新
function _M:update()
    self.tick = self.tick + 1

    if self.tick % 2 == 0 then
        if not table.is_empty(self.stat_flags) then
            self:checkAbnormalStatFlags(2)   --检查异常状态
        end

        if self.target then
            self:checkTargetLost()           --检查目标是否丢失
        end
    end
    --更新动画

end

return _M