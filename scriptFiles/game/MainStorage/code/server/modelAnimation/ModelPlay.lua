------------------------------------------------------------------------------------
-- -*- coding: utf-8 -*-
--
-- @作者:         zhenghao
-- @创建日期:      2025-09-11
-- @模块名称:      ModelPlay
-- @描述:         模型动画
-- @版本:         v1.0
------------------------------------------------------------------------------------
-- 引入管理对象
local game = game
local MainStorage = game:GetService("MainStorage")
---@type ClassMgr
local ClassMgr = require(MainStorage.code.common.ClassMgr)
---@type gg
local gg = require(MainStorage.code.common.MGlobal)
---@type ServerScheduler
local ServerScheduler = require(MainStorage.code.server.serverEvent.ServerScheduler)
---@type MobBehavior
local MobBehavior = require(MainStorage.code.server.modelAnimation.MobBehavior)
------------------------------------------------------------------------------------
---@class ModelPlay
local ModelPlay = ClassMgr.Class("ModelPlay")

---@param animator Animator
function ModelPlay:OnInit(name,animator,stateConfig)
    -- 名称
    self.name = name
    -- 动画
    self.animator = animator
    -- 是否移动中
    self.isMoving = false
    -- 当前状态
    self.currentState = nil
    -- 完成任务
    self.finishTask = nil
    -- 状态配置
    self.stateConfig = stateConfig
    -- 播放完成
    self.animationFinished = true
    -- 初始化状态
    self:SwitchState(self.stateConfig["初始状态"])
    -- 动画控制器资源
    self.animName = animator.ControllerAsset

end

--被攻击时
function ModelPlay:OnHurt()
    return self:PlayTransition("被攻击时","被攻击")
end

-- 攀爬
function ModelPlay:OnClimb()
    return self:PlayTransition("爬楼梯时","爬楼梯")
end

-- 吃东西动画
function ModelPlay:OnEat()
    return self:PlayTransition("吃东西时","吃东西")
end

-- 战立动画
function ModelPlay:OnIdle()
    self.isMoving = false
    self.isJump = false
    return self:PlayTransition("无","战立")
end

-- 跳跃动画
function ModelPlay:OnJump()
    self.isJump = true
    self.isMoving = false
    return self:PlayTransition("无","跳跃")
end

-- 行走动画
function ModelPlay:OnWalk()
    self.isMoving = true
    self.isJump = false
    return self:PlayTransition("无","行走")
end

-- 攻击动画
function ModelPlay:OnAttack()
    return self:PlayTransition("攻击时","攻击")
end

-- 死亡动画
function ModelPlay:OnDead()
    return self:PlayTransition("死亡时","死亡")
end

-- 播放过度
function ModelPlay:PlayTransition(key,playType)

    local transitions = self:GetTransition()
    if not transitions then
        --gg.log(self.name,"播放[",playType,"]失败 原因:无 transitions")
        return 0
    end

    local validAnimList = {}
    for animName, transition in pairs(transitions) do
        -- 定位是否可切换
        local canSwitch = true
        if canSwitch and transition["时机"] ~= key then
            canSwitch = false
        end
        -- 是否可交换
        if canSwitch and not self:CanTransitTo(transition) then
            canSwitch = false
        end
        if canSwitch then
            table.insert(validAnimList, animName)
        end
    end

    if #validAnimList > 0 then
        local randomAnim = validAnimList[math.random(1, #validAnimList)]
        --gg.log(self.name,"播放[",playType,"]成功 ",randomAnim)
        return self:SwitchState(randomAnim)
    end
    --gg.log(self.name,"播放[",playType,"]失败 原因:无 validAnimList")
    return 0
end

---@private
function ModelPlay:CanTransitTo(transition)
    if transition["播放完成切换"] and not self.animationFinished then
        return false
    elseif transition["移动中"] and not self.isMoving then
        return false
    elseif transition["静止中"] and self.isMoving then
        return false
    elseif transition["跳跃中"] and not self.isJump then
        return false
    end
    return true
end

-- 获取过度
function ModelPlay:GetTransition()
    if not self.currentState then
        return
    end
    local transitions = self.currentState["切换"]
    if not transitions then
        return
    end
    return transitions
end

-- 切换状态
function ModelPlay:SwitchState(stateName, speed)
    -- 先取消上一个状态的特效
    if self.finishTask then
        self.finishTask = ServerScheduler.cancel(self.finishTask)
    end
    speed = speed or 1

    -- 获取状态信息
    local state = self.stateConfig["状态"][stateName]
    if not state then
        return 0
    end
    -- 消失时间
    local fadeTime = 0
    -- 当前状态
    if self.currentState then
        if self.currentState["切换"] then
            local transition = self.currentState["切换"][stateName]
            fadeTime = transition and transition["混合时间"] or 0
        end
    end

    -- 单次/循环播放
    local playMode = state["播放模式"]
    -- 设置未播放完成
    self.animationFinished = false
    -- 播放速度
    self.animator.Speed = speed
    -- 如果消失时间大于0
    if fadeTime > 0 then
        self.animator:CrossFade(stateName, 0, fadeTime, 0)
    else
        self.animator:Play(stateName, 0, 0)
    end

    local playTime = state["播放时间"]
    if playMode == "单次" then
        if playTime and playTime > 0 then
            --gg.log(self.name,"播放[",stateName,"] playTime = ",playTime - 0.1)
            self.finishTask = ServerScheduler.add(function ()
                self.animationFinished = true
                -- 切换其他的状态动画
                self:PlayTransition("无","切换其他的状态动画")
            end, playTime - 0.1)
        end
        if state["触发效果时间"] then
            playTime = state["触发效果时间"]
        end
    end
    state["id"] = stateName
    -- 当前状态
    self.currentState = state

    return playTime
end

return ModelPlay