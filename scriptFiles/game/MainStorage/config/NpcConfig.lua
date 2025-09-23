local MainStorage = game:GetService('MainStorage')

--- NPC配置文件
---@class NpcConfig
local NpcConfig = {}
local loaded = false

local function LoadConfig()
    NpcConfig.config ={
        ["充值老板"] = {
            ["场景"] = "MainCity",
            ["节点名"] = "充值老板",
            ["打开UI"] = "充值界面",
        },
        ["职业商人"] = {
            ["场景"] = "MainCity",
            ["节点名"] = "职业商人",
            ["打开UI"] = "职业界面",
        },
        ["怪物猎人"] = {
            ["场景"] = "MainCity",
            ["节点名"] = "怪物猎人",
            ["打开UI"] = "成就界面",
        },
        ["食材商人"] = {
            ["场景"] = "MainCity",
            ["节点名"] = "食材商人",
            ["打开UI"] = "成就界面",
        },
        ["探险家"] = {
            ["场景"] = "MainCity",
            ["节点名"] = "探险家",
            ["打开UI"] = "任务界面",
        },
        ["神秘人"] = {
            ["场景"] = "MainCity",
            ["节点名"] = "神秘人",
            ["打开UI"] = "排行榜界面",
        },
        ["匹配区域中"] = {
            ["场景"] = "MainCity",
            ["节点名"] = "匹配区域中",
            ["打开UI"] = "匹配界面",
            ["匹配区域"] = true,
            ["无人时"] = ColorQuad.New(85, 255, 0, 255), -- 绿色
            ["满人时"] = ColorQuad.New(255, 0, 0, 255), -- 红色
            ["人数未满时"] = ColorQuad.New(255, 255, 0, 255), -- 黄色
        },
        ["匹配区域左"] = {
            ["场景"] = "MainCity",
            ["节点名"] = "匹配区域左",
            ["打开UI"] = "匹配界面",
            ["匹配区域"] = true,
            ["无人时"] = ColorQuad.New(85, 255, 0, 255), -- 绿色
            ["满人时"] = ColorQuad.New(255, 0, 0, 255), -- 红色
            ["人数未满时"] = ColorQuad.New(255, 255, 0, 255), -- 黄色
        },
        ["匹配区域右"] = {
            ["场景"] = "MainCity",
            ["节点名"] = "匹配区域右",
            ["打开UI"] = "匹配界面",
            ["匹配区域"] = true,
            ["无人时"] = ColorQuad.New(85, 255, 0, 255), -- 绿色
            ["满人时"] = ColorQuad.New(255, 0, 0, 255), -- 红色
            ["人数未满时"] = ColorQuad.New(255, 255, 0, 255), -- 黄色
        },
        ["宝箱"] = {
            ["场景"] = "MainCity",
            ["节点名"] = "宝箱",
            ["交互后ModelId"] = "sandboxId://Scene_model/GameScene/金宝箱打开/金宝箱打开.prefab"
        },
    }loaded = true
end

---@param npcName string
---@return Npc
function NpcConfig.Get(npcName)
    if not loaded then
        LoadConfig()
    end
    return NpcConfig.config[npcName]
end

---@return Npc[]
function NpcConfig.GetAll()
    if not loaded then
        LoadConfig()
    end
    return NpcConfig.config
end
return NpcConfig
