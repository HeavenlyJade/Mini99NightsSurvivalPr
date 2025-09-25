local MainStorage = game:GetService('MainStorage')
--- 物品类型配置文件
---@class ItemTypeConfig
---@field Get fun(itemTypeId: string):ItemType 获取物品类型
---@field GetAll fun():ItemType[] 获取所有物品类型
local ItemTypeConfig = {}
local loaded = false
local function LoadConfig()
    ---@type ItemType
    local ItemType = require(MainStorage.code.common.ConfigTypes.ItemType)
    ItemTypeConfig.config ={
        ["石斧"] = ItemType.New({
            ["名字"] = "石斧",
            ["描述"] = "最基本的工具,可以砍树和防身。",
            ["详细属性"] = {},
            ["图标"] = "",
            ["品级"] = "普通",
            ["额外战力"] = 0,
            ["强化等级"] = 0,
            ["最大强化等级"] = 0,
            ["属性"] = {

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
            },
            ["颜色"] = {255,255,255,255}, --白色
            ["耐久度"] = 30,
            ["最大耐久度"] = 30,
            ["需求职业"] = "无",
            ["最大叠加数量"] = 1,
            ["类型"] = "武器",
            ["攻击类型"] = "近战",
            ["可手持"] = true,
            ["使用状态增益"] = {
                ["血量增加"] = 0,
                ["饱食度增加"] = 0,
                ["能量增加"] = 0,
                ["温度增加"] = 0,
                ["天数增加"] = 0,
            },
        }),
-------------------------------------------------------------------
    }loaded = true
end

---@param itemType string
---@return ItemType
function ItemTypeConfig.Get(itemType)
    if not loaded then
        LoadConfig()
    end
    if not itemType then
        return nil
    end
    return ItemTypeConfig.config[itemType]
end

---@return ItemType[]
function ItemTypeConfig.GetAll()
    if not loaded then
        LoadConfig()
    end
    return ItemTypeConfig.config
end

return ItemTypeConfig
