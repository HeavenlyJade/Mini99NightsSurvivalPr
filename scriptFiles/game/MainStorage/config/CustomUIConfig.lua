local MainStorage = game:GetService('MainStorage')
local CustomUI = require(MainStorage.code.common.customUi.CustomUI)    ---@type CustomUI
local RoleConfig =require(MainStorage.config.RoleConfig) ---@type RoleConfig


--- ConfigSection配置文件
---@class CustomUIConfig
local CustomUIConfig = {}
local loaded = false

local function LoadConfig()
    CustomUIConfig.config ={
        ["排行榜界面"] = CustomUI.Load({
            ["UI名"] = "RankingGui",
            ["ID"] = "排行榜界面"
        }),
        ["图鉴界面"] = CustomUI.Load({
            ["UI名"] = "WikiGui",
            ["ID"] = "图鉴界面"
        }),
        ["职业界面"] = CustomUI.Load({
            ["UI名"] = "RoleGui",
            ["ID"] = "职业界面",
            ["职业配置"] = RoleConfig.GetAll(),
        }),
        ["充值界面"] = CustomUI.Load({
            ["UI名"] = "PayGui",
            ["ID"] = "充值界面"
        }),
        ["匹配界面"] = CustomUI.Load({
            ["UI名"] = "MatchGui",
            ["ID"] = "匹配界面"
        }),
        ["货币钻石"] = CustomUI.Load({
            ["UI名"] = "PayGui",
            ["ID"] = "充值界面"
        }),
        ["成就界面"] = CustomUI.Load({
            ["UI名"] = "AchievementGui",
            ["ID"] = "成就界面"
        }),
        ["任务界面"] = CustomUI.Load({
            ["UI名"] = "QuestGui",
            ["ID"] = "任务界面"
        }),
    }loaded = true
end

---@param name string
---@return CustomUI
function CustomUIConfig.Get(name)
    if not loaded then
        LoadConfig()
    end
    return CustomUIConfig.config[name]
end

---@return CustomUI[]
function CustomUIConfig.GetAll()
    if not loaded then
        LoadConfig()
    end
    return CustomUIConfig.config
end
return CustomUIConfig
