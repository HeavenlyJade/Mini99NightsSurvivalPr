--BattleUtils
local game = game
local MainStorage = game:GetService('MainStorage')
local gg = require(MainStorage.code.common.MGlobal) ---@type gg
---@type common_const
local common_const = require(MainStorage.code.common.Const)

---@class BattleUtils
local BattleUtils = {}

--检查攻击者和目标是否都存活
function BattleUtils.checkAlive( attacker, skill_config )
    --是否攻击者无法攻击
    if  attacker:canNotBeenAttarked() then
        return 1        --攻击者死亡
    end
    --技能是否需要有目标
    if  skill_config.need_target == 1 then
        --是否有目标
        if  attacker.target then
            -- 判断是否不可攻击的目标
            if  attacker.target:canNotBeenAttarked() then
                if  attacker:isPlayer() then
                    -- 玩家
                else
                    attacker.target = nil     --怪物失去目标
                end
                return 1  --目标死亡
            end
        else
            --没有目标
            return 1
        end
    end
    return 0   --成功
end

return BattleUtils