------------------------------------------------------------------------------------
-- -*- coding: utf-8 -*-
--
-- @作者:         zhenghao
-- @创建日期:      2025-09-05
-- @模块名称:      Player
-- @描述:         玩家类
-- @版本:         v1.0
------------------------------------------------------------------------------------
-- 引入管理对象
local game = game
local MainStorage = game:GetService("MainStorage")
---@type ClassMgr
local ClassMgr = require(MainStorage.code.common.ClassMgr)
---@type Entity
local Entity = require(MainStorage.code.server.entityTypes.Entity)
---@type ServerEventManager
local ServerEventManager = require(MainStorage.code.server.serverEvent.ServerEventManager)
---@type gg
local gg = require(MainStorage.code.common.MGlobal)
---@type common_const
local common_const = require(MainStorage.code.common.Const)
---@type CloudDataMgr
local cloudDataMgr = require(MainStorage.code.server.CloudDataMgr)
---@type BattleMgr
local BattleMgr = require(MainStorage.code.common.battle.BattleMgr)
---@type LevelConfig
local LevelConfig = require(MainStorage.config.LevelConfig)
---@type ItemTypeConfig
local ItemTypeConfig = require(MainStorage.config.ItemConfig)
---@type ServerScheduler
local ServerScheduler = require(MainStorage.code.server.serverEvent.ServerScheduler)
---@type BattleDataManager
local BattleDataManager = require(MainStorage.code.server.serverManager.BattleDataManager)


------------------------------------------------------------------------------------
---@class Player : Class
local _M = ClassMgr.Class('Player', Entity)

-- 初始化实例类
function _M:OnInit(info)
    self.moveSpeedUp = false
    self.uuid = gg.create_uuid('p')
    -- 网络状态
    self.player_net_stat = common_const.PLAYER_NET_STAT.INIT
    -- 昵称
    self.name = info.nickname
    -- 被销毁
    self.isDestroyed = false
    -- 附近的Npc
    self.nearbyNpcs = {}
    -- 当前使用装备序号
    self.curUseEquipIdx = 0
    -- 是否传送中
    self.Teleporting = false
    ---云端数据
    -- 最高存活天数
    self.maxSurvivalDays = 0
    -- 玩家货币
    self.money = { gemNum = 1000 }
    -- 称号
    self.myTitle = ""
    -- 职业
    self.job = ""
    -- 成就
    self.achievementData = {
        ["救治队友"] = { getGift = true },
        ["皮毛大师"] = { getGift = false },
        ["升级工作台"] = { getGift = true },
        ["生存萌新"] = { getGift = false },
        ["团队合作"] = { getGift = true },
    }
    -- 任务
    self.questData = {
        ["收集类"] = {
            ["任务"] = {
                [1] = { ["数量"] = 5 },
                [2] = { ["数量"] = 2 },
                [3] = { ["数量"] = 5 },
            },
            ["是否完成"] = false,
            ["领取奖励"] = false,
        },
        ["战斗类"] = {
            ["任务"] = {
                [1] = { ["数量"] = 10 },
                [2] = { ["数量"] = 10 },
                [3] = { ["数量"] = 5 },
            },
            ["是否完成"] = true,
            ["领取奖励"] = false,
        },
        ["生存类"] = {
            ["任务"] = {
                [1] = { ["数量"] = 30 },
                [2] = { ["数量"] = 50 },
                [3] = { ["数量"] = 99 },
            },
            ["是否完成"] = true,
            ["领取奖励"] = true,
        },
        ["时长类"] = {
            ["任务"] = {
                [1] = { ["数量"] = 0 },
                [2] = { ["数量"] = 0 },
                [3] = { ["数量"] = 5 },
            },
            ["是否完成"] = false,
            ["领取奖励"] = false,
        },
    }
    -- 职业列表
    self.jobData = {
        ["伐木工"] = { ["天赋阶段"] = 2, ["是否拥有"] = true },
    }
    -- 商店职业列表
    self.shopRandomJobData = {
        roleList = { ["伐木工"] = true, ["厨师"] = true, ["医生"] = true },
        Time = os.time()
    }

    -- 初始化基础模板
    self:initBattleData(BattleDataManager.default_player_battle_data)

    --  广告 记录领取次数/时间
    local current_date = os.date("*t")
    self.AdvertisementData = info.AdvertisementData or {
        playCount = 0,
        maxPlayCount = 3,
        target_year = current_date.target_year,
        target_year = current_date.month,
        target_year = current_date.day,
    }

    --    --
    ServerEventManager.Subscribe("cmd_aoe_select_pos", function(evt)
        local data = {
            name = evt.name,
            x = evt.x,
            y = evt.y,
            z = evt.z,
        }
        self:Build(data)
    end)
    -- 测试
    ServerEventManager.Subscribe("testPlayerAnimator", function(evt)
        if self.uin == evt.player.uin then

            if evt.idx == 1 then
                self:SendEvent("handleAoePos",{args_ = {name = "草床"}})
            elseif evt.idx == 2 then
                self:SendEvent("handleAoePos",{args_ = {name = "宝箱"}})

            elseif evt.idx == 3 then
                self:SendHoverText("已离开匹配队列")
            end

            --       self.actor.Animator:CrossFade("Run", 0, fadeTime, 0)
            --if evt.idx == 1 then
            --    print("站立")
            --    self.actor.Animator:Play("Idle", 0, 0)
            --elseif evt.idx == 2 then
            --    print("奔跑")
            --    self.actor.Animator:Play("Run", 0, 0)
            --elseif evt.idx == 3 then
            --    print("Sit")
            --    -- 坐下
            --    self.actor.Animator:Play("Sit", 0, 0)
            --
            --elseif evt.idx == 4 then
            --    print("Swim")
            --    -- 游泳
            --    self.actor.Animator:Play("Swim", 0, 0)
            --elseif evt.idx == 5 then
            --    -- 死亡
            --    print("Death")
            --    self.actor.Animator:Play("Death", 0, 0)
            --elseif evt.idx == 6 then
            --    -- 原地跳
            --    print("Jump")
            --    self.actor.Animator:Play("Jump", 0, 0)
            --elseif evt.idx == 7 then
            --    print("飞行")
            --    self.actor.Animator:Play("fei", 0, 0)
            --elseif evt.idx == 8 then
            --    print("落下")
            --    -- 滚落
            --    self.actor.Animator:Play("luo", 0, 0)
            --end
            --     if evt.idx == 1 then
            --         print("起飞")
            --         self.actor.Animator:Play("qifei", 0, 0)
            --     elseif evt.idx == 2 then
            --         print("爬楼梯")
            --         self.actor.Animator:Play("palouti", 0, 0)
            --     elseif evt.idx == 3 then
            --         print("吃")
            --         self.actor.Animator:Play("chi", 0, 0)
            --     elseif evt.idx == 4 then
            --         print("die")
            --         self.actor.Animator:Play("die", 0, 0)
            --     elseif evt.idx == 5 then
            --
            --       --  self.actor.Animator:Play("pikan", 0, 0)
            --         self.actor.Animator:Play("Run", 0, 0)
            --     elseif evt.idx == 6 then
            --         --self.actor.Animator:SetLayerWeight(0, 3)
            --         --self.actor.Animator:SetLayerWeight(1, 2)
            --         self.actor.Animator:Play("Run", 0, 0)
            --         self.actor.Animator:Play("chi1", 1, 0)
            --         --self.animator:SetLayerWeight(0, 3)
            --         --self.animator:SetLayerWeight(1, 2)
            ----
            ----         self.actor.Animator:SetLayerWeight(1, 1)
            ----         self.actor.Animator:SetLayerWeight(0, 0)
            ------         self.actor.Animator:CrossFade("chi1", 1, 0.5, 0)
            ----
            ----         self.actor.Animator:SetLayerWeight(0, 1)
            ----         self.actor.Animator:SetLayerWeight(1, 0)
            --     elseif evt.idx == 7 then
            --         self.actor.Animator:CrossFade("pikan1", 1, 0.5, 0)
            --     elseif evt.idx == 8 then
            --
            --
            --
            --
            --     end
        end
    end)

    -- 广告
    ServerEventManager.Subscribe("SuccessPlayAdvertisement", function(evt)
        if self.uin == evt.player.uin then
            self:GetPlayAdvertisementGift()
        end
    end)
    -- 切换目标
    ServerEventManager.Subscribe("PlayerSelectTarget", function(evt)
        if self.uin == evt.player.uin then
            self:handlePickActor(evt.monsterName)
            self:PlayerUseItem()
        end
    end)

    -- 上子弹
    ServerEventManager.Subscribe("PlayerSwitchAmmunition", function(evt)
        if self.uin == evt.player.uin then
            self:PlayerSwitchAmmunition()
        end
    end)

    -- 切换物品
    ServerEventManager.Subscribe("switchEquip", function(evt)
        if self.uin == evt.player.uin then
            self:SwitchHandItem(evt.idx)
        end
    end)
    -- 丢弃物品
    ServerEventManager.Subscribe("DisHandItem", function(evt)
        if self.uin == evt.player.uin then
            -- 丢弃手上物品
            self:DropHandItem(evt.idx)
        end
    end)


    ServerEventManager.Subscribe("AttackForward", function(evt)
        if self.uin == evt.player.uin then
            -- 攻击
            self:PlayerUseItem()
        end
    end)
    ServerEventManager.Subscribe("PlayerTpMatch", function(evt)
        if self.uin == evt.player.uin then
            -- 通知客户端改变场景
            self:ChangeScene(evt.scene)
            -- 传送
            self:TeleportPos(evt.spawnPos)
        end
    end)
    ServerEventManager.Subscribe("PlayerJoinGame", function(evt)
        if self.uin == evt.player.uin then
            local levelType = LevelConfig.Get("进入区域_1")
            local suc, reason = levelType:CanJoin(self)
            if not suc then
                return
            end
            levelType:JoinQueue(self)
            -- 通知客户端改变场景
            self:ChangeScene(evt.scene)
            -- 传送
            self:TeleportPos(evt.spawnPos)
        end
    end)
    ServerEventManager.Subscribe("PlayerShiftMove", function(evt)
        if self.uin == evt.player.uin then
            if evt.start then
                self.moveSpeedUp = true
                -- 传送
                self.actor.Movespeed = self.orgMoveSpeed + 200
            else
                self.moveSpeedUp = false
                self.actor.Movespeed = self.orgMoveSpeed
            end
        end
    end)


    --    if fadeTime > 0 then
    --        self.animator:CrossFade(stateName, 0, fadeTime, 0)
    --    else
    --        self.animator:Play(stateName, 0, 0)
    --    end
end

-- 设置玩家拥有的职业信息
function _M:setJobData(jobData)
    self.jobData = jobData
end

-- 随机职业
function _M:RandomJobShop()
    self.shopRandomJobData = {
        roleList = {
            ["伐木工"] = math.random(1,100) >= 50,
            ["猎人"] = math.random(1,100) >= 50,
            ["厨师"] = math.random(1,100) >= 50,
            ["医生"] = math.random(1,100) >= 50,
            ["拾荒者"] = math.random(1,100) >= 50,
            ["农夫"] = math.random(1,100) >= 50,
            ["工程师"] = math.random(1,100) >= 50,
            ["老兵"] = math.random(1,100) >= 50,
            ["探险家"] = math.random(1,100) >= 50,
            ["巨人"] = math.random(1,100) >= 50,
        },
        Time = os.time()
    }
end

---------------------------npc相关----------------------
-- 添加附近的NPC
---@param npc
function _M:AddNearbyNpc(npc)
    if not self.nearbyNpcs[npc.uuid] then
        self.nearbyNpcs[npc.uuid] = npc
        self:UpdateNearbyNpcsToClient()
    end
end

-- 移除附近的NPC
---@param npc
function _M:RemoveNearbyNpc(npc)
    if self.nearbyNpcs[npc.uuid] then
        self.nearbyNpcs[npc.uuid] = nil
        self:UpdateNearbyNpcsToClient()
    end
end

-- 更新附近的NPC列表到客户端
function _M:UpdateNearbyNpcsToClient()
    local interactOptions = {}
    local npcList = {}
    -- 收集NPC信息并计算距离
    for _, npc in pairs(self.nearbyNpcs) do
        local distance = gg.vec.Distance3(npc.actor.LocalPosition, self.actor.LocalPosition)
        table.insert(npcList, {
            npc = npc,
            distance = distance
        })
    end
    -- 按距离排序
    table.sort(npcList, function(a, b)
        return a.distance < b.distance
    end)
    -- 构建排序后的交互选项列表
    for _, data in ipairs(npcList) do
        table.insert(interactOptions, {
            npcName = data.npc:GetName(),
            npcId = data.npc.uuid,
            icon = data.npc.interactIcon,
            interactSpeed = self.interactSpeed,
            npcSceneType = data.npc.scene.sceneType,
            startNum = data.npc.startNum,
            spawnPos = data.npc.spawnPos,


        })
    end
    -- 发送给客户端
    self:SendEvent("NPCInteractionUpdate", { interactOptions = interactOptions })
end

---------------------------玩家与客户端事件相关----------------------
-- 发送消失显示
function _M:SendHoverText(text, ...)
    if ... then
        text = string.format(text, ...)
    end
    self:SendEvent("SendHoverText", { txt = text })
end

-- 发送事件到客户端
function _M:SendEvent(eventName, data, callback)
    if not data then
        data = {}
    end
    if not eventName then
        print("发送事件时未传入事件: " .. debug.traceback())
    end
    data.cmd = eventName
    ServerEventManager.SendToClient(self.uin, eventName, data, callback)
end

---------------------------玩家状态相关----------------------
-- 设置玩家网络状态
function _M:setPlayerNetStat(player_net_stat_)
    self.player_net_stat = player_net_stat_
end

-- 离开游戏
function _M:OnLeaveGame()
    self.isDestroyed = true
    ServerEventManager.Publish("PlayerLeaveGameEvent", { player = self })
    if self.actor then
        _M.node2Entity[self.actor] = nil
        self.actor = nil
    end
    -- 取消订阅指定玩家的事件
    ServerEventManager.UnsubscribeByKey(self.uuid)
end

-- 玩家保存数据
function _M:Save()
    cloudDataMgr.SavePlayerData(self.uin, true)
end

-- 订阅指定玩家的事件
function _M:SubscribeEvent(eventType, listener)
    if not ServerEventManager then
        return
    end
    if not ServerEventManager.SubscribeToPlayer then
        return
    end
    ServerEventManager.SubscribeToPlayer(self, eventType, listener, self.uuid)
end

-- 取消订阅指定玩家的事件
function _M:UnsubscribeEvent(eventType, listener)
    if not ServerEventManager then
        return
    end
    if not ServerEventManager.SubscribeToPlayer then
        return
    end

    ServerEventManager.UnsubscribeFromPlayer(self, eventType, listener, self.uuid)
end

---------------------------广告事件相关----------------------
-- 获取礼包
function _M:GetGift()
    -- 增加物品逻辑
    self.money.gemNum = self.money.gemNum + 1
    -- 同步玩家背包/更新信息
    self:UpdateHud()
end

-- 播放广告奖励
function _M:GetPlayAdvertisementGift()
    local getGift = false
    if self.AdvertisementData.playCount >= self.AdvertisementData.maxPlayCount then
        local current_date = os.date("*t")
        local current_year = current_date.year
        local current_month = current_date.month
        local current_day = current_date.day

        -- 定义指定日期
        local target_year = 2023
        local target_month = 10
        local target_day = 1
        if current_year == target_year and current_month == target_month and current_day == target_day then
            getGift = false
        end
    else
        getGift = true
    end
    if getGift then
        self.AdvertisementData.playCount = self.AdvertisementData.playCount + 1
        -- 增加物品
        self:GetGift()
    end
end

-- 增加钻石
function _M:AddGem(num)
    -- 增加物品逻辑
    self.money.gemNum = self.money.gemNum + num
    -- 同步玩家背包/更新信息
    self:UpdateHud()
end




--玩家切换目标
---@param target_
function _M:changeTarget(target)
    self.target = target
end

--玩家选定一个目标
function _M:handlePickActor(monsterName)
    local target_ = gg.findMonsterByUuid(monsterName)
    if target_ then
        self:changeTarget(target_)
    end
end

function _M:update_player()
    self:UpdateHud()
    -- 在线时间
    self.questData["时长类"]["任务"][1]["数量"] = self.questData["时长类"]["任务"][1]["数量"] + 0.1
end

function _M:UpdateHud()
    Entity.update(self)
    self:CreateTitle()
    -- 同步玩家货币
    self:SendEvent("SynchronizePlayerCurrencies", { GemNum = self.money.gemNum })
    if self.scene and self.scene.sceneType == "战斗场景" then
        --按时间自动回血 减少饥饿
        self:checkHPMP()
        -- 同步玩家背包
        self:SendEvent("PlayerUpFightUi", { bagInfo = self.battle_data.bagInfo })
    end
end

---设置玩家视角
---@param euler
function _M:SetCameraView(euler)
    self:SendEvent("UpdateCameraView", { x = euler.x, y = euler.y, z = euler.z, })
end

---播放音效
---@param soundAssetId string 音效资源ID
---@param boundTo? SandboxNode|Vec3 音效绑定目标(实体或位置)
---@param volume? number 音量大小(0-1)
---@param pitch? number 音调大小(0-2)
---@param range? number 音效范围
---@param key? string
function _M:PlaySound(soundAssetId, boundTo, volume, pitch, range, key)
    local data = {
        soundAssetId = soundAssetId,
        volume = volume or 1.0,
        pitch = pitch or 1.0,
        range = range or 6000,
        key = key
    }

    if not boundTo then
        local pos = self:GetPosition()
        data.position = { pos.x, pos.y, pos.z }
    elseif type(boundTo) == "userdata" then
        if boundTo.IsA and boundTo.Parent then
            ---@cast boundTo SandboxNode
            data.boundTo = gg.GetFullPath(boundTo)
        else
            ---@cast boundTo Vector3
            data.position = { boundTo.x, boundTo.y, boundTo.z }
        end
    elseif type(boundTo) == "table" and boundTo.x then
        -- 如果是Vec3，直接使用位置
        data.position = { boundTo.x, boundTo.y, boundTo.z }
    end

    self:SendEvent("PlaySound", data)
end

--通知客户端玩家的基础属性
--op: 1=初始化同步所有数据   2=只同步exp
function _M:rsyncData(op_)
    local ret_ = {
        level = self.level;
        exp = self.exp;
    }
    if op_ == 1 then
        ret_.battle_data = self.battle_data
    end
    --gg.network_channel:fireClient( self.uin, { cmd="cmd_rsync_player_data",  v=ret_ } )
end

--按时间自动回血 减少饥饿
function _M:checkHPMP()
    -- 每5秒执行一次
    if (self.tick % 167 == 1) then
        if self.battle_data.hp > 0 then
            local change_ = 0
            if self.battle_data.hp < self.battle_data.hp_max then
                self.battle_data.hp = self.battle_data.hp + self.battle_data.hp_add
                change_ = 1
            end
            -- 减少饥饿度
            if self.battle_data.hunger > 0 then
                local addHunger = self.battle_data.hunger_reduced
                -- 加速状态 饱食度减少
                if self.moveSpeedUp then
                    addHunger = addHunger * 2
                end
                self.battle_data.hunger = math.max(0, self.battle_data.hunger - addHunger)
                change_ = 1
            end
            if change_ == 1 then
                -- 同步玩家状态
                self:SendEvent("UpDataPlayerState", {
                    health = self.battle_data.hp,
                    maxHealth = self.battle_data.hp_max,
                    hunger = self.battle_data.hunger,
                    maxHunger = self.battle_data.hunger_max,
                    energy = self.battle_data.energy,
                    maxEnergy = self.battle_data.energy_max,
                    job = self.job,
                })
            end
        end
    end
    -- 每1秒执行一次
    if (self.tick % 30 == 1) then
        -- 同步玩家状态
        self:SendEvent("UpDataPlayerState", {
            health = self.battle_data.hp,
            maxHealth = self.battle_data.hp_max,
            hunger = self.battle_data.hunger,
            maxHunger = self.battle_data.hunger_max,
            energy = self.battle_data.energy,
            maxEnergy = self.battle_data.energy_max,
            job = self.job,
        })
    end
end

---战斗---------------------------------------------------------------
-- 切换手上物品
function _M:SwitchHandItem(idx)
    local equipData = self.battle_data.bagInfo[idx]
    if equipData then
        if self.curUseEquipIdx == idx then
            if equipData.itemType.showCrosshatch then
                -- 消失准星
                self:SendEvent("showCrosshatch", {show = false})
            end
            -- 清空手上物品
            self:equipWeapon("")
            self.curUseEquipIdx = 0
            return
        end
        -- 判断是否显示准星
        if equipData.itemType.showCrosshatch then
            -- 显示准星
            self:SendEvent("showCrosshatch", {show = true})
        else
            -- 消失准星
            self:SendEvent("showCrosshatch", {show = false})
        end
        self:initBattleData(BattleDataManager.GetPlayerBattleDataByEquip(equipData.itemType.attributes))
        self:equipWeapon(equipData.itemType.name)
        self.curUseEquipIdx = idx
    end
end

-- 丢弃手上物品
function _M:DropHandItem(idx)
    local itemData = self.battle_data.bagInfo[idx]
    if itemData then
        if not itemData.notDrop then
            itemData.amount = itemData.amount - 1
            if itemData.amount <= 0 then
                -- 战斗属性
                self:initBattleData(BattleDataManager.GetPlayerBattleDataByEquip())
                -- 清空手上物品
                self:equipWeapon("")
                -- 判断是否显示准星
                if itemData.itemType.showCrosshatch then
                    -- 消失准星
                    self:SendEvent("showCrosshatch", {show = false})
                end
                self.battle_data.bagInfo[idx] = nil
            end
            -- 同步背包
            self:SendEvent("PlayerUpFightUi", { bagInfo = self.battle_data.bagInfo })
            -- 丢弃物品
            self:dropItem(itemData.itemType.name)
        end
    end
end

-- 使用物品
function _M:PlayerUseItem()
    -- 非战斗场景退出
    if self.scene.sceneType ~= "战斗场景" then
        return
    end
    local equipData = self.battle_data.bagInfo[self.curUseEquipIdx]
    -- 没有物品信息
    if not equipData then
        return
    end
    -- 不可手持
    if not equipData.itemType.canHand then
        return
    end
    if equipData.itemType.itemType == "武器" then
        if equipData.itemType.attackType == "近战" then
            BattleMgr.tryAttackSpell(self, "近战")
        elseif equipData.itemType.attackType == "枪械" then
            local needItem = equipData.itemType.attackNeedItem
            local needNum = equipData.itemType.attackNeedItemNum
            gg.log("弹药数量 = ",self.battle_data.ammunitionBagInfo[needItem]["弹药数量"],"弹夹容量 = ",self.battle_data.ammunitionBagInfo[needItem]["弹夹容量"],"备弹 = ",self.battle_data.ammunitionBagInfo[needItem]["备弹"])
            if self.battle_data.ammunitionBagInfo[needItem] and self.battle_data.ammunitionBagInfo[needItem]["弹药数量"] >= needNum then
                BattleMgr.tryAttackSpell(self, "枪械")
                self.battle_data.ammunitionBagInfo[needItem]["弹药数量"] = self.battle_data.ammunitionBagInfo[needItem]["弹药数量"] - needNum
            end
        end
    elseif equipData.itemType.itemType == "食物" then
        local useState =equipData.itemType.useState
        if useState then
            local eatTime = self.modelPlayer:OnEat()
            if eatTime > 0 then
                -- eatTime 秒后加血
                ServerScheduler.add(function ()
                    equipData.amount = equipData.amount - 1
                    -- 增加状态
                    self:spellHealth(useState["血量增加"],useState["饱食度增加"])
                    -- 判断物品数量
                    if equipData.amount <= 0 then
                        -- 清空手上物品
                        self:equipWeapon("")
                        self.battle_data.bagInfo[self.curUseEquipIdx] = nil
                    end
                    -- 同步背包
                    self:SendEvent("PlayerUpFightUi", { bagInfo = self.battle_data.bagInfo })
                end, eatTime)
            end
        end
    elseif equipData.itemType.itemType == "弹药" then
        local eatTime = self.modelPlayer:OnEat()
        if eatTime > 0 then
            -- eatTime 秒后加血
            ServerScheduler.add(function ()
                equipData.amount = equipData.amount - 1
                -- 判断物品数量
                if equipData.amount <= 0 then
                    -- 清空手上物品
                    self:equipWeapon("")
                    self.battle_data.bagInfo[self.curUseEquipIdx] = nil
                end
                -- 同步背包
                self:SendEvent("PlayerUpFightUi", { bagInfo = self.battle_data.bagInfo })
                local ammunitionType = equipData.itemType.ammunitionType
                if self.battle_data.ammunitionBagInfo[ammunitionType] then
                    self.battle_data.ammunitionBagInfo[ammunitionType]["备弹"] = self.battle_data.ammunitionBagInfo[ammunitionType]["备弹"] + equipData.itemType.ammunitionAddNum
                end
            end, eatTime)
        end
    end
end


-- 换子弹
function _M:PlayerSwitchAmmunition()
    -- 非战斗场景退出
    if self.scene.sceneType ~= "战斗场景" then
        return
    end
    local equipData = self.battle_data.bagInfo[self.curUseEquipIdx]
    -- 没有物品信息
    if not equipData then
        return
    end
    -- 不可手持
    if not equipData.itemType.canHand then
        return
    end
    -- 不是武器
    if equipData.itemType.itemType ~= "武器" then
        return
    end
    -- 不是枪械
    if equipData.itemType.attackType ~= "枪械" then
        return
    end
    local needItem = equipData.itemType.attackNeedItem
    -- 没有子弹需求
    if not needItem then
        return
    end
    -- 弹药类型没有子弹背包
    if not self.battle_data.ammunitionBagInfo[needItem] then
        return
    end
    -- 没有备弹
    if self.battle_data.ammunitionBagInfo[needItem]["备弹"] == 0 then
        return
    end
    -- 满弹夹
    if self.battle_data.ammunitionBagInfo[needItem]["弹夹容量"] == self.battle_data.ammunitionBagInfo[needItem]["弹药数量"] then
        return
    end
    -- 需要弹药数量
    local needNum = self.battle_data.ammunitionBagInfo[needItem]["弹夹容量"] - self.battle_data.ammunitionBagInfo[needItem]["弹药数量"]
    if self.battle_data.ammunitionBagInfo[needItem]["备弹"] < needNum then
        needNum = self.battle_data.ammunitionBagInfo[needItem]["备弹"]
    end
    -- 增加弹药
    local eatTime = self.modelPlayer:OnEat()
    if eatTime > 0 then
        -- eatTime 秒后加血
        ServerScheduler.add(function ()
            self.battle_data.ammunitionBagInfo[needItem]["备弹"] = self.battle_data.ammunitionBagInfo[needItem]["备弹"] - needNum

            self.battle_data.ammunitionBagInfo[needItem]["弹药数量"] = self.battle_data.ammunitionBagInfo[needItem]["弹药数量"] + needNum
        end, eatTime)
    end
end


function _M:Die()
    if self.isDead then return end
    -- 发布死亡事件

    -- 停止导航
    self.actor:StopNavigate()

    if self.modelPlayer then
        self.modelPlayer:OnDead()
    end
end

-- 复活
function _M:CompleteRespawn()
    self.isDead = false
    self.target = nil
    if self.modelPlayer then
        self.modelPlayer:OnIdle()
    end
end

return _M