local MainStorage = game:GetService('MainStorage')
---@type MobTypeConfig
local MobTypeConfig = require(MainStorage.config.MobTypeConfig)
---@type ClassMgr
local ClassMgr = require(MainStorage.code.common.ClassMgr)
---@type WeightedRandomSelector
local WeightedRandomSelector = require(MainStorage.code.common.ConfigTypes.WeightedRandomSelector)
---@type gg
local gg = require(MainStorage.code.common.MGlobal)
---
---@class SpawningMob:Class
---@field mobType MobType
---@field weight number
local SpawningMob = ClassMgr.Class("SpawningMob")


function SpawningMob:OnInit()
    self.mobs = {}
    self.selector = nil
end

---@return MobType
function SpawningMob:GetRandomMobType()
    local selected = self.selector:Next()
    if not selected then
        print("Warning: No mob type selected from selector")
        return nil
    end
    return selected.mobType
end


---尝试生成怪物
---@param spawnedCount number 生成的怪物数量
---@param scene Scene 场景
---@return Monster[] 生成的怪物实例列表
function SpawningMob:TrySpawn(monsterListData,spawnedCount, scene, spawnPoints, r)

    self.mobs = {}
    for _, mobData in ipairs(monsterListData["刷新怪物"] or {}) do
        table.insert(self.mobs, {
            mobType = MobTypeConfig.Get(mobData["怪物类型"]),
            weight = mobData["比重"] or 1
        })
    end

    self.selector = WeightedRandomSelector.New(self.mobs, function(mob)
        return mob.weight
    end)

    -- 生成怪物
    local spawnedMobs = {}
    for i = 1, spawnedCount do
        local mobType = self:GetRandomMobType()
        gg.log("mobType - ",mobType.id)
        if mobType then
            -- 随机选择一个刷怪点
            local spawnLoc = gg.randomPointOnCirclePerimeter(spawnPoints.x, spawnPoints.y, spawnPoints.z, r)

            local mob = mobType:Spawn(spawnLoc, scene)
            if mob then
                table.insert(spawnedMobs, mob)
            end
        end
    end
    -- 返回是否完成生成、生成的怪物列表和更新后的生成数量
    return spawnedMobs
end

return SpawningMob