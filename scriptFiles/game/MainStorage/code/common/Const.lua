------------------------------------------------------------------------------------
-- -*- coding: utf-8 -*-
--
-- @作者:         zhenghao
-- @创建日期:      2025-09-09
-- @模块名称:      Const
-- @描述:         常量
-- @版本:         v1.0
------------------------------------------------------------------------------------
-- 引入管理对象
------------------------------------------------------------------------------------

---@class common_const
local common_const = {
    MOVESPEED = 800, --玩家和人物行走速度

    ---@class NPC_TYPE NPC类型枚举
    ---@field INIT NPC_TYPE 初始化状态
    ---@field PLAYER NPC_TYPE 玩家类型
    ---@field MONSTER NPC_TYPE 怪物类型
    ---@field NPC NPC_TYPE NPC类型
    ---@field AI NPC_TYPE AI机器人类型
    NPC_TYPE = {
        INIT = 0, --初始化
        PLAYER = 1, --玩家
        MONSTER = 2, --怪物
        NPC = 3, --npc
        AI = 4, --AI机器人
    },

    ---@class PLAYER_NET_STAT 玩家网络状态枚举
    ---@field INIT PLAYER_NET_STAT 初始化状态
    ---@field LOGIN_IN PLAYER_NET_STAT 服务器初始化完成
    ---@field CLIENT_OK PLAYER_NET_STAT 客户端连接正常(正常状态)
    ---@field LOGIN_OUT PLAYER_NET_STAT 玩家退出
    PLAYER_NET_STAT = {
        INIT = 0, --初始化
        LOGIN_IN = 1, --服务器初始化完成
        CLIENT_OK = 2, --客户端连接正常  (正常状态)
        LOGIN_OUT = 99, --玩家退出
    },

    ---@class BATTLE_STAT 战斗状态枚举
    ---@field IDLE BATTLE_STAT 空闲状态(脱离战斗)
    ---@field FIGHT BATTLE_STAT 进入战斗状态
    ---@field DEAD_WAIT BATTLE_STAT 被击败状态(等待重生或者清理)
    ---@field WAIT_SPAWN BATTLE_STAT 等待重生状态
    BATTLE_STAT = {
        IDLE = 1, --空闲(脱离战斗)
        FIGHT = 2, --进入战斗
        DEAD_WAIT = 91, --被击败 (等待重生或者清理)
        WAIT_SPAWN = 92, --等待重生
    },

    ---@class ITEM_TYPE 物品类型枚举
    ---@field EQUIPMENT ITEM_TYPE 装备类型
    ---@field BOX ITEM_TYPE 箱子类型
    ---@field MAT ITEM_TYPE 材料类型
    ITEM_TYPE = {
        EQUIPMENT = 1, --装备
        BOX = 2, --箱子
        MAT = 3, --材料
    },

    ---@class JOB_ICON 职业图标
    JOB_ICON = {
        ["伐木工"] = "sandboxId://ui/职业ui/职业头像/3_伐木工.png",
        ["厨师"] = "sandboxId://ui/职业ui/职业头像/2_小厨师.png",
        ["医生"] = "sandboxId://ui/职业ui/职业头像/3_小护士.png",
        ["农夫"] = "sandboxId://ui/职业ui/职业头像/4_农夫.png",
        ["老兵"] = "sandboxId://ui/职业ui/职业头像/3_军官.png",
        ["探险家"] = "sandboxId://ui/职业ui/职业头像/4_探路者.png",


        ["露营者"] = "sandboxId://ui/职业ui/职业头像/1_露营者.png",
        ["生存大师"] = "sandboxId://ui/职业ui/职业头像/5_生存大师.png",

    },
    MODEL = {
        EQUIP = {
            ["剑"] = 'sandboxSysId://itemmods/12012/body.omod',
            ["矛"] = 'sandboxSysId://itemmods/12004/body.omod',
        },
    },

    -- 场景类型
    SCENE_TYPE = {
        [1] = "主场景",
        [2] = "战斗场景"
    },
    BAG_KEYCODE = {
        [Enum.KeyCode.One.Value] = 1,
        [Enum.KeyCode.Two.Value] = 2,
        [Enum.KeyCode.Three.Value] = 3,
        [Enum.KeyCode.Four.Value] = 4,
        [Enum.KeyCode.Five.Value] = 5,
        [Enum.KeyCode.Six.Value] = 6,
        [Enum.KeyCode.Seven.Value] = 7,
        [Enum.KeyCode.Eight.Value] = 8,
    },

    SKILL_DEF = {
        --power威力 dmg_type 物理伤害 need_target 需要目标才能释放 range 释放距离 speed 速度 res 资源文件 cast_time 前置释放时间 cd冷却 mp蓝量
        ["近战"] = {power = 1, dmg_type = 1,range = 260, speed = 1, need_target = 0, res = "BattleTypeMelee" ,cast_time = 0,cd = 0,mp = 0,},

        ["弓箭"] = { power = 1,dmg_type = 1,range = 2000, speed = 1, need_target = 0, res = "BattleTypeBow" ,cast_time = 0,cd = 0,mp = 0,},

        ["枪械"] = {power = 1, dmg_type = 1,range = 2000, speed = 1, need_target = 0, res = "BattleTypeGun" ,cast_time = 0,cd = 0,mp = 0,},

        ["范围"] = { power = 1,dmg_type = 1,range = 2000, speed = 1, need_target = 0, res = "BattleTypeAoe" ,cast_time = 0,cd = 0,mp = 0,},

        ["防御"] = {power = 1, dmg_type = 1,range = 0, speed = 0, need_target = 0, res = "BattleTypeDefensive" ,cast_time = 0,cd = 0,mp = 0,},
    },

    -- 物品框
    SELECT_BOX = {
        ["选中"] = "sandboxId://ui/公共ui/矩形选中.png",
        ["未选中"] = "sandboxId://ui/公共ui/物品栏.png",
    },

    -- 碰撞组
    COLLIDE_GROUP = {
        -- 玩家
        PLAYER = 3,
        -- 怪物类型
        MONSTER = 4,
        -- 物品
        ITEM = 5,
    },
}
return common_const