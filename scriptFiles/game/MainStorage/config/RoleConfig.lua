local MainStorage = game:GetService('MainStorage')

--- 职业配置文件
---@class RoleConfig
local RoleConfig = {}
local loaded = false

local function LoadConfig()
    RoleConfig.config = {
        ["价格表"] = {
            ["刷新天赋价格"] = 30,
            ["刷新商店价格"] = 30,
            ["解锁天赋等级价格"] = 90,
            ["解锁天赋价格"] = 60,
        },
        ["职业列表"] = {
            ["伐木工"] = {
                -- 图标
                Icon = "sandboxId://ui/职业ui/职业头像/1_露营者.png",
                ["名称"] = "伐木工",
                ["功能性"] = "资源类",
                ["星级"] = 4,
                ["价格"] = 200,
                ["开局工具"] = {
                    [1] = {
                        name = "二级斧头", -- 名称
                        Icon = "sandboxId://ui/职业界面ui/厨师.png", -- 图标
                        num = 1                                     -- 数量
                    },

                },
                ["属性"] = {
                    hp = 100, -- 当前生命值
                    hp_max = 100, -- 最大生命值
                    hp_add = 0.2, -- 每秒恢复血量速度

                    hunger = 240, -- 饥饿度
                    hunger_max = 240, -- 最大饥饿度
                    hunger_reduced = 1, -- 每秒减少饥饿度

                    energy = 100, -- 能量条
                    energy_max = 100, -- 最大能量条
                    energy_add = 0.1, -- 每秒恢复能量条

                    defence = 0, -- 防御力

                    SurvivalDays = 0, -- 生存天数

                    interact_speed = 6, -- 交互速度
                    attack_speed = 0.5, -- 攻击速度
                    move_speed = 5, -- 移动速度
                    reload_speed = 0, -- 换弹速度
                },
                ["级别属性"] = {
                    [1] = { { desc = "+20%砍伐效率" } },
                    [2] = { { desc = "伐木时,+20%概率+1木头" } },
                    [3] = { { desc = "伐木时,+20%概率+1种子" } },
                },
                ["需求"] = {
                    [1] = {
                        { name = "砍伐普通树木", val = 50 },
                        { name = "种植树木", val = 10 },
                    },
                    [2] = {
                        { name = "砍伐高级树木", val = 50 },
                        { name = "种植树木", val = 70 },
                    },
                },
                ["可随机天赋"] = {

                },
            },

            ["猎人"] = {
                -- 图标
                Icon = "sandboxId://ui/职业ui/职业头像/1_露营者.png",
                ["名称"] = "猎人",
                ["功能性"] = "资源类",
                ["星级"] = 2,
                ["价格"] = 100,
                ["开局工具"] = {
                    [1] = {
                        name = "1级长矛", -- 名称
                        Icon = "sandboxId://ui/职业界面ui/厨师.png", -- 图标
                        num = 1                                     -- 数量
                    },

                },
                ["属性"] = {
                    hp = 100, -- 当前生命值
                    hp_max = 100, -- 最大生命值
                    hp_add = 0.2, -- 每秒恢复血量速度

                    defence = 0, -- 防御力

                    hunger = 240, -- 饥饿度
                    hunger_max = 240, -- 最大饥饿度
                    hunger_reduced = 1, -- 每秒减少饥饿度

                    energy = 100, -- 能量条
                    energy_max = 100, -- 最大能量条
                    energy_add = 0.1, -- 每秒恢复能量条



                    SurvivalDays = 0, -- 生存天数

                    interact_speed = 6, -- 交互速度
                    attack_speed = 0.5, -- 攻击速度
                    move_speed = 5, -- 移动速度
                    reload_speed = 0, -- 换弹速度
                },
                ["级别属性"] = {
                    [1] = { { desc = "+20%对动物伤害" } },
                    [2] = { { desc = "击杀动物后,+20%概率获得肉+1" } },
                    [3] = { { desc = "击杀动物后,+20%战利品掉落率" } },
                },
                ["需求"] = {
                    [1] = {
                        { name = "击杀兔子", val = 20 },
                        { name = "获取兔皮", val = 5 },
                    },
                    [2] = {
                        { name = "击杀野狼", val = 100 },
                        { name = "获取狼皮", val = 30 },
                    },
                },
                ["可随机天赋"] = {

                },
            },

            ["厨师"] = {
                -- 图标
                Icon = "sandboxId://ui/职业ui/职业头像/1_露营者.png",
                ["名称"] = "厨师",
                ["功能性"] = "资源类",
                ["星级"] = 2,
                ["价格"] = 100,
                ["开局工具"] = {
                    [1] = {
                        name = "调料瓶", -- 名称
                        Icon = "sandboxId://ui/职业界面ui/厨师.png", -- 图标
                        num = 1                                     -- 数量
                    },

                },
                ["属性"] = {
                    hp = 100, -- 当前生命值
                    hp_max = 100, -- 最大生命值
                    hp_add = 0.2, -- 每秒恢复血量速度

                    defence = 0, -- 防御力

                    hunger = 240, -- 饥饿度
                    hunger_max = 240, -- 最大饥饿度
                    hunger_reduced = 1, -- 每秒减少饥饿度

                    energy = 100, -- 能量条
                    energy_max = 100, -- 最大能量条
                    energy_add = 0.1, -- 每秒恢复能量条



                    SurvivalDays = 0, -- 生存天数

                    interact_speed = 6, -- 交互速度
                    attack_speed = 0.5, -- 攻击速度
                    move_speed = 5, -- 移动速度
                    reload_speed = 0, -- 换弹速度
                },
                ["级别属性"] = {
                    [1] = { { desc = "+30%烹饪速度" } },
                    [2] = { { desc = "+10%制作食物恢复饱食度" } },
                    [3] = { { desc = "使用灶台制作时，+20%概率产出“蹦蹦跳跳一锅香”" } },
                },
                ["需求"] = {
                    [1] = {
                        { name = "制作食物", val = 25 },
                        { name = "击杀兔子", val = 20 },
                    },
                    [2] = {
                        { name = "制作高级菜品", val = 200 },
                        { name = "击杀野狼", val = 50 },
                    },
                },
                ["可随机天赋"] = {

                },
            },

            ["医生"] = {
                -- 图标
                Icon = "sandboxId://ui/职业ui/职业头像/1_露营者.png",
                ["名称"] = "医生",
                ["功能性"] = "援助类",
                ["星级"] = 2,
                ["价格"] = 100,
                ["开局工具"] = {
                    [1] = {
                        name = "绷带", -- 名称
                        Icon = "sandboxId://ui/职业界面ui/厨师.png", -- 图标
                        num = 2                                     -- 数量
                    },

                },
                ["属性"] = {
                    hp = 100, -- 当前生命值
                    hp_max = 100, -- 最大生命值
                    hp_add = 0.2, -- 每秒恢复血量速度

                    defence = 0, -- 防御力

                    hunger = 240, -- 饥饿度
                    hunger_max = 240, -- 最大饥饿度
                    hunger_reduced = 1, -- 每秒减少饥饿度

                    energy = 100, -- 能量条
                    energy_max = 100, -- 最大能量条
                    energy_add = 0.1, -- 每秒恢复能量条



                    SurvivalDays = 0, -- 生存天数

                    interact_speed = 6, -- 交互速度
                    attack_speed = 0.5, -- 攻击速度
                    move_speed = 5, -- 移动速度
                    reload_speed = 0, -- 换弹速度
                },
                ["级别属性"] = {
                    [1] = { { desc = "+30%治疗量" } },
                    [2] = { { desc = "+50%治疗速度" } },
                    [3] = { { desc = "初始物品变为医疗箱*2" }, { desc = "+20%朝向倒地队员奔跑速度" } },

                },
                ["需求"] = {
                    [1] = {
                        { name = "复活队友", val = 3 },
                        { name = "施加治疗量", val = 150 },
                    },
                    [2] = {
                        { name = "复活队友", val = 25 },
                        { name = "施加治疗量", val = 1250 },
                    },
                },
                ["可随机天赋"] = {

                },
            },

            ["拾荒者"] = {
                -- 图标
                Icon = "sandboxId://ui/职业ui/职业头像/1_露营者.png",
                ["名称"] = "拾荒者",
                ["功能性"] = "探图类",
                ["星级"] = 1,
                ["价格"] = 50,
                ["开局工具"] = {
                    [1] = {
                        name = "手电筒", -- 名称
                        Icon = "sandboxId://ui/职业界面ui/厨师.png", -- 图标
                        num = 1                                     -- 数量
                    },

                },
                ["属性"] = {
                    hp = 100, -- 当前生命值
                    hp_max = 100, -- 最大生命值
                    hp_add = 0.2, -- 每秒恢复血量速度

                    defence = 0, -- 防御力

                    hunger = 240, -- 饥饿度
                    hunger_max = 240, -- 最大饥饿度
                    hunger_reduced = 1, -- 每秒减少饥饿度

                    energy = 100, -- 能量条
                    energy_max = 100, -- 最大能量条
                    energy_add = 0.1, -- 每秒恢复能量条



                    SurvivalDays = 0, -- 生存天数

                    interact_speed = 6, -- 交互速度
                    attack_speed = 0.5, -- 攻击速度
                    move_speed = 5, -- 移动速度
                    reload_speed = 0, -- 换弹速度
                },
                ["级别属性"] = {
                    [1] = { { desc = "-20%饥饿下降速度" }, { desc = "+20%奔跑速度" } },
                    [2] = { { desc = "+2背包空间" } },
                    [3] = { { desc = "+10%开箱速度" } }, },

                ["需求"] = {
                    [1] = {
                        { name = "收集野外资源数", val = 20 },
                        { name = "收集零件数", val = 20 },
                    },
                    [2] = {
                        { name = "收集野外植物数", val = 500 },
                        { name = "收集零件数", val = 250 },
                    },
                },
                ["可随机天赋"] = {

                },

            },


            ["农夫"] = {
                -- 图标
                Icon = "sandboxId://ui/职业ui/职业头像/1_露营者.png",
                ["名称"] = "农夫",
                ["功能性"] = "资源类",
                ["星级"] = 2,
                ["价格"] = 100,
                ["开局工具"] = {
                    [1] = {
                        name = "水壶", -- 名称
                        Icon = "sandboxId://ui/职业界面ui/厨师.png", -- 图标
                        num = 1                                     -- 数量
                    },

                },
                ["属性"] = {
                    hp = 100, -- 当前生命值
                    hp_max = 100, -- 最大生命值
                    hp_add = 0.2, -- 每秒恢复血量速度

                    defence = 0, -- 防御力

                    hunger = 240, -- 饥饿度
                    hunger_max = 240, -- 最大饥饿度
                    hunger_reduced = 1, -- 每秒减少饥饿度

                    energy = 100, -- 能量条
                    energy_max = 100, -- 最大能量条
                    energy_add = 0.1, -- 每秒恢复能量条



                    SurvivalDays = 0, -- 生存天数

                    interact_speed = 6, -- 交互速度
                    attack_speed = 0.5, -- 攻击速度
                    move_speed = 5, -- 移动速度
                    reload_speed = 0, -- 换弹速度
                },
                ["级别属性"] = {
                    [1] = { { desc = "+20%浇水后园圃中植物生长速度" } },
                    [2] = { { desc = "+2园圃收获量" } },
                    [3] = { { desc = "+20%概率,园圃产出蛋糕" } },
                },
                ["需求"] = {
                    [1] = {
                        { name = "园圃收获数", val = 20 },
                        { name = "砍伐普通树木", val = 50 },
                    },
                    [2] = {
                        { name = "园圃收获数", val = 700 },
                        { name = "砍伐普通树木", val = 120 },
                    },
                },
                ["可随机天赋"] = {

                },
            },

            ["工程师"] = {
                -- 图标
                Icon = "sandboxId://ui/职业ui/职业头像/1_露营者.png",
                ["名称"] = "工程师",
                ["功能性"] = "资源类",
                ["星级"] = 2,
                ["价格"] = 100,
                ["开局工具"] = {
                    [1] = {
                        name = "2级斧头", -- 名称
                        Icon = "sandboxId://ui/职业界面ui/厨师.png", -- 图标
                        num = 1                                     -- 数量
                    },

                },
                ["属性"] = {
                    hp = 100, -- 当前生命值
                    hp_max = 100, -- 最大生命值
                    hp_add = 0.2, -- 每秒恢复血量速度

                    defence = 0, -- 防御力

                    hunger = 240, -- 饥饿度
                    hunger_max = 240, -- 最大饥饿度
                    hunger_reduced = 1, -- 每秒减少饥饿度

                    energy = 100, -- 能量条
                    energy_max = 100, -- 最大能量条
                    energy_add = 0.1, -- 每秒恢复能量条



                    SurvivalDays = 0, -- 生存天数

                    interact_speed = 6, -- 交互速度
                    attack_speed = 0.5, -- 攻击速度
                    move_speed = 5, -- 移动速度
                    reload_speed = 0, -- 换弹速度
                },
                ["级别属性"] = {
                    [1] = { { desc = "-10%制作台制作物品所需材料" } },
                    [2] = { { desc = "*2开局获得陷阱" } },
                    [3] = { { desc = "-10%制作台制作物品所需材料" } },
                },
                ["需求"] = {
                    [1] = {
                        { name = "制作物品数", val = 5 },
                        { name = "消耗树木数", val = 40 },
                    },
                    [2] = {
                        { name = "制作物品数", val = 140 },
                        { name = "消耗零件数", val = 1000 },
                    },
                },
                ["可随机天赋"] = {

                },
            },

            ["老兵"] = {
                -- 图标
                Icon = "sandboxId://ui/职业ui/职业头像/1_露营者.png",
                ["名称"] = "老兵",
                ["功能性"] = "战斗类",
                ["星级"] = 3,
                ["价格"] = 150,
                ["开局工具"] = {
                    [1] = {
                        name = "左轮手枪", -- 名称
                        Icon = "sandboxId://ui/职业界面ui/厨师.png", -- 图标
                        num = 1                                     -- 数量
                    },
                    [2] = {
                        name = "左轮手枪子弹", -- 名称
                        Icon = "sandboxId://ui/职业界面ui/厨师.png", -- 图标
                        num = 12                                     -- 数量
                    },

                },
                ["属性"] = {
                    hp = 100, -- 当前生命值
                    hp_max = 100, -- 最大生命值
                    hp_add = 0.2, -- 每秒恢复血量速度

                    defence = 0, -- 防御力

                    hunger = 240, -- 饥饿度
                    hunger_max = 240, -- 最大饥饿度
                    hunger_reduced = 1, -- 每秒减少饥饿度

                    energy = 100, -- 能量条
                    energy_max = 100, -- 最大能量条
                    energy_add = 0.1, -- 每秒恢复能量条



                    SurvivalDays = 0, -- 生存天数

                    interact_speed = 6, -- 交互速度
                    attack_speed = 0.5, -- 攻击速度
                    move_speed = 5, -- 移动速度
                    reload_speed = 0, -- 换弹速度
                },
                ["级别属性"] = {
                    [1] = { { desc = "-15%换弹与轮转时间" } },
                    [2] = { { desc = "+12初始左轮手枪子弹" } },
                    [3] = { { desc = "+12初始左轮手枪子弹" }, { desc = "-15%换弹与轮转时间" } },
                },
                ["需求"] = {
                    [1] = {
                        { name = "击杀敌人数", val = 30 },
                        { name = "消耗子弹数", val = 20 },
                    },
                    [2] = {
                        { name = "击杀敌人数", val = 350 },
                        { name = "消耗子弹数", val = 800 },
                    },
                },
                ["可随机天赋"] = {

                },

            },

            ["探险家"] = {
                -- 图标
                Icon = "sandboxId://ui/职业ui/职业头像/1_露营者.png",
                ["名称"] = "探险家",
                ["功能性"] = "探图类",
                ["星级"] = 4,
                ["价格"] = 200,
                ["开局工具"] = {
                    [1] = {
                        name = "绷带", -- 名称
                        Icon = "sandboxId://ui/职业界面ui/厨师.png", -- 图标
                        num = 1                                     -- 数量
                    },

                },
                ["属性"] = {
                    hp = 100, -- 当前生命值
                    hp_max = 100, -- 最大生命值
                    hp_add = 0.2, -- 每秒恢复血量速度

                    defence = 0, -- 防御力

                    hunger = 240, -- 饥饿度
                    hunger_max = 240, -- 最大饥饿度
                    hunger_reduced = 1, -- 每秒减少饥饿度

                    energy = 100, -- 能量条
                    energy_max = 100, -- 最大能量条
                    energy_add = 0.1, -- 每秒恢复能量条



                    SurvivalDays = 0, -- 生存天数

                    interact_speed = 6, -- 交互速度
                    attack_speed = 0.5, -- 攻击速度
                    move_speed = 5, -- 移动速度
                    reload_speed = 0, -- 换弹速度
                },
                ["级别属性"] = {
                    [1] = { { desc = "+2背包空间" } },
                    [2] = { { desc = "-20%冲刺耗费能量" } },
                    [3] = { { desc = "开局获得太阳表盘+地图（被动）" } },
                },
                ["需求"] = {
                    [1] = {
                        { name = "收集野外资源数", val = 20 },
                        { name = "开启宝箱数", val = 5 },
                    },
                    [2] = {
                        { name = "收集野外资源数", val = 500 },
                        { name = "开启宝箱数", val = 140 },
                    },
                },
                ["可随机天赋"] = {

                },
            },

            ["巨人"] = {
                -- 图标
                Icon = "sandboxId://ui/职业ui/职业头像/1_露营者.png",
                ["名称"] = "巨人",
                ["功能性"] = "战斗类",
                ["星级"] = 5,
                ["价格"] = 250,
                ["开局工具"] = {
                    [1] = {
                        name = "1级护甲", -- 名称
                        Icon = "sandboxId://ui/职业界面ui/厨师.png", -- 图标
                        num = 1                                     -- 数量
                    },

                },
                ["属性"] = {
                    hp = 100, -- 当前生命值
                    hp_max = 100, -- 最大生命值
                    hp_add = 0.2, -- 每秒恢复血量速度

                    defence = 0, -- 防御力

                    hunger = 240, -- 饥饿度
                    hunger_max = 240, -- 最大饥饿度
                    hunger_reduced = 1, -- 每秒减少饥饿度

                    energy = 100, -- 能量条
                    energy_max = 100, -- 最大能量条
                    energy_add = 0.1, -- 每秒恢复能量条



                    SurvivalDays = 0, -- 生存天数

                    interact_speed = 6, -- 交互速度
                    attack_speed = 0.5, -- 攻击速度
                    move_speed = 5, -- 移动速度
                    reload_speed = 0, -- 换弹速度
                },
                ["级别属性"] = {

                    [1] = { { desc = "无法使用远程武器" }, { desc = "+25%近战武器伤害" } },
                    [2] = { { desc = "+10%获得治疗量" }, { desc = "+15生命值" } },
                    [3] = { { desc = "有5%概率免疫伤害" }, { desc = "+15生命值" } },
                },
                ["需求"] = {
                    [1] = {
                        { name = "击败敌人数", val = 30 },
                        { name = "砍伐普通树木", val = 50 },
                    },
                    [2] = {
                        { name = "击败敌人数", val = 350 },
                        { name = "砍伐高级树木", val = 50 },
                    },
                },
                ["可随机天赋"] = {

                },
            },
        },

    }
        loaded = true
end

---@param npcName string
---@return Role
function RoleConfig.Get(RoleName)
    if not loaded then
        LoadConfig()
    end
    return RoleConfig.config["职业列表"][RoleName]
end

---@return Role[]
function RoleConfig.GetAll()
    if not loaded then
        LoadConfig()
    end
    return RoleConfig.config
end

return RoleConfig
