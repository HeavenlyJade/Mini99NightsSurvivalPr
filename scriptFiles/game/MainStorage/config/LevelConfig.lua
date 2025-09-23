
local MainStorage = game:GetService('MainStorage')
---@type gg
local gg                = require(MainStorage.code.common.MGlobal)



---@class LevelConfig
local LevelConfig = {}
local loaded = false

local function LoadConfig()
    ---@type SceneType
    local SceneType = require(MainStorage.code.server.gameScene.SceneType)
    LevelConfig.config ={

        ["匹配区域中"] = SceneType.New({
            ["关卡ID"] = "匹配区域中",
            ["增加额外玩家时间"] = 1,
            ["每个玩家增加数量倍率"] = 0,
            ["场景"] = "GameScene",
            ["匹配时间"] = 10,
            ["玩家进入位置"] = Vector3.New(-1342, 200, 0),
        }),
        ["匹配区域左"] = SceneType.New({
            ["关卡ID"] = "匹配区域左",
            ["增加额外玩家时间"] = 1,
            ["每个玩家增加数量倍率"] = 0,
            ["场景"] = "GameScene",
            ["匹配时间"] = 10,
            ["玩家进入位置"] = Vector3.New(-1336, 200, -500),
        }),
        ["匹配区域右"] = SceneType.New({
            ["关卡ID"] = "匹配区域右",
            ["增加额外玩家时间"] = 1,
            ["每个玩家增加数量倍率"] = 0,
            ["场景"] = "GameScene",
            ["匹配时间"] = 10,
            ["玩家进入位置"] = Vector3.New(-1336, 200, 500),
        }),
    }loaded = true
end

---@param level string
---@return LevelType
function LevelConfig.Get(level)
    if not loaded then
        LoadConfig()
    end
    return LevelConfig.config[level]
end

---@return table<string, LevelType>
function LevelConfig.GetAll()
    if not loaded then
        LoadConfig()
    end
    return LevelConfig.config
end

-- 获取最近的关卡
function LevelConfig.GetNearLevel(player)
    local levelType
    local distanceSq_ = 0
    for i, v in pairs(LevelConfig.GetAll()) do
        if v.entryPoints then
            local distanceSq = gg.vec.DistanceSq3(v.entryPoints, player:GetPosition())
            if distanceSq_ == 0 or distanceSq_ > distanceSq then
                levelType = v
                distanceSq_ = distanceSq
            end
        end
    end
    return levelType
end
return LevelConfig