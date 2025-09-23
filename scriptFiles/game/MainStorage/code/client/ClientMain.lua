------------------------------------------------------------------------------------
-- -*- coding: utf-8 -*-
--
-- @作者:         zhenghao
-- @创建日期:      2025-09-05
-- @模块名称:      ClientMain
-- @描述:         客户端入口
-- @版本:         v1.0
------------------------------------------------------------------------------------
-- 引入管理对象
local game = game
local MainStorage     = game:GetService("MainStorage")
local TweenService 		 = game:GetService('TweenService')
---@type ClassMgr
local ClassMgr    = require(MainStorage.code.common.ClassMgr)
---@type gg
local gg              = require(MainStorage.code.common.MGlobal)
---@type ClientEventManager
local ClientEventManager = require(MainStorage.code.client.clientEvent.ClientEventManager)
------------------------------------------------------------------------------------
---@class ClientMain
local ClientMain = ClassMgr.Class("ClientMain")

-- 入口函数
function ClientMain.startClient()

    -- 创建网络渠道
    ClientMain.createNetworkChannel()
    -- 创建广告渠道
    ClientMain.createAdvert()
    -- 获取用户按键输入
    ---@type UserInputEvent
    require(MainStorage.code.client.clientEvent.UserInputEvent)


    -- 监听服务端发送的悬浮文本事件
    ClientEventManager.Subscribe("SendHoverText", function(evt)
        ClientMain.ShowMsg(evt)
    end)
    require(MainStorage.code.client.clientEvent.MiniShopManagerClient) -- 文件不存在，已注释
    require(MainStorage.code.client.clientEvent.PlaySoundEvent) -- 音乐播放
    local actor = game.Players.LocalPlayer
    if game.RunService:IsPC() then
        actor.TouchMovementMode = Enum.DevTouchMovementMode.Scriptable
        actor.PlayerGui.TouchUIMain.Visible = false
    else
        actor.TouchMovementMode = Enum.DevTouchMovementMode.Thumbstick
        actor.PlayerGui.TouchUIMain.Visible = true
    end
end


-- TweenService 飘字
-- 参数 pps
--  txt   = 内容
--  t     = 展示时间秒
--  color = 颜色
--  FontSize  = 文字大小
function ClientMain.ShowMsg(pps_)

    local ui_root = gg.create_ui_root()
    local ui_size = gg.get_ui_size()

    local txt_msg_ = gg.createTextLabel(ui_root, pps_.txt)
    txt_msg_.Name = 'msg'
    txt_msg_.RenderIndex = 9999
    -- 颜色
    txt_msg_.TitleColor =  ColorQuad.New(255,255,255,255)
    -- 字体大小
    txt_msg_.FontSize = pps_.FontSize or 30

    txt_msg_.Scale = Vector2.New(1,1)

    -- 开启阴影
    txt_msg_.ShadowEnable = true
    txt_msg_.ShadowOffset = Vector2.new(1, -1)
    txt_msg_.ShadowColor = ColorQuad.new(0, 0, 0, 255)

    local txt_msg_weenInfo = TweenInfo.new((2), Enum.EasingStyle.Linear, nil, 0, 0)
    txt_msg_.Position = Vector2.new(ui_size.x * 0.5, ui_size.y * 0.4)
    local goal = {}
    goal.Position = Vector2.new(ui_size.x * 0.5, ui_size.y * 0.3)
    local tween = TweenService:Create(txt_msg_, txt_msg_weenInfo, goal)
    tween:Play()
    -- 监听动画完成事件
    tween.Completed:Connect(function()
        txt_msg_.Visible = false
        txt_msg_:Destroy()
    end)
end

-- 创建网络渠道
function ClientMain.createNetworkChannel()
    gg.network_channel = MainStorage:WaitForChild("NetworkChannel")
    gg.network_channel.OnClientNotify:Connect(ClientMain.OnClientNotify)
    gg.network_channel:FireServer({ cmd = 'cmd_heartbeat', msg = 'new_client_join' })
end

-- 创建广告渠道
function ClientMain.createAdvert()
    gg.Advertisement = game:GetService("AdvertisementService")
    gg.Advertisement:PlayAdvertisingCallback(ClientMain.OnClientAdvert)
end

-- 广告回调
function ClientMain.OnClientAdvert(msg)
    if string.find(msg,"true") then
        -- 发送交互请求到服务器
        gg.network_channel:FireServer({
            cmd = "SuccessPlayAdvertisement",
        })
        ClientEventManager.Publish("SendHoverText", {txt ="观看成功！" .. msg })
    else
        ClientEventManager.Publish("SendHoverText", {txt ="观看失败！" .. msg })
    end
end

function ClientMain.OnClientNotify(args)
    if type(args) ~= 'table' then return end
    if not args.cmd then return end
    if args.__cb then
        args.Return = function(returnData)
            gg.network_channel:FireServer({
                cmd = args.__cb .. "_Return",
                data = returnData
            })
        end
    end
    ClientEventManager.Publish(args.cmd, args)
end


return ClientMain