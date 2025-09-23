local game = game
local MainStorage = game:GetService('MainStorage')
---@type gg
local gg = require(MainStorage.code.common.MGlobal)
---@type common_const
local common_const = require(MainStorage.code.common.Const)
---@type BattleUtils
local BattleUtils = require(MainStorage.code.common.battle.BattleUtils)

---@class BattleMgr
local BattleMgr = {
    skill_instance_list = {
        -- skill_1, skill_1, skill_2   --存放每一个技能实例( 特效，投掷物，弹道等 )
    }
}
local CONST_Battle_module = {

}

function BattleMgr.InitBattleConfig()
    for skillType, skillData in pairs( common_const.SKILL_DEF ) do
        local name_ = MainStorage.code.common.battle[ skillData.res]
        CONST_Battle_module[ skillType ] = require( name_ )
    end
end


--玩家选定一个目标
function BattleMgr.handlePickActor(uin_, args1_)
    local player_ = gg.server_players_list[uin_]
    if player_ then
        local target_ = gg.findMonsterByUuid(args1_.v)
        if target_ then
            player_:changeTarget(target_)
        end
    end
end



--尝试发起一次攻击或者技能释放
function BattleMgr.tryAttackSpell(attacker, skill_type)
    -- 获取技能配置
    local skill_config = common_const.SKILL_DEF[skill_type]
    --检查攻击者和目标是否都存活
    if skill_config then
        if BattleUtils.checkAlive(attacker, skill_config) > 0 then
            return 1
        end
        --需要判断目标距离
        if skill_config.need_target == 1 and attacker.target then
            if skill_config.range and skill_config.range > 0 then
                --检查距离
                if gg.out_distance(attacker:getPosition(), attacker.target:getPosition(), skill_config.range) then
                    -- 太远不攻击
                    return 1
                end
            end
            --改变朝向
            gg.actorLookAtActorY0(attacker.actor, attacker.target.actor)
        end
        --检查前置条件(speed cd mp)
        local ret_ = attacker:checkAttackSpellConfig(skill_type, skill_config)   --player or monster
        if ret_ > 0 then
            --失败
            return ret_
        end
        -- 获取模块
        local Battle_module = CONST_Battle_module[skill_type]
        if not Battle_module.New then
            -- 无法初始化技能
            return 1
        end
        local info_ = { from = attacker, skillType = skill_type }

        local battle = Battle_module.New(info_)

        BattleMgr.skill_instance_list[battle.uuid] = battle

        if skill_config.cast_time and skill_config.cast_time > 0 then
            --有前置施法时间
            if attacker:setSkillCastTime(battle.uuid, skill_config.cast_time) == 0 then
                battle:castTimePre()
            end
        else
            battle:castSpell()            --没有前置时间，直接攻击或者施法
        end
    end

    return 0    --成功
end


-- 一次攻击计算
---@param attacker_ CPlayer | CMonster
---@param target_ CPlayer | CMonster
function BattleMgr.calculate_attack( attacker, target, skill_config )

    local effect_ = {}   --特性：暴击 躲闪 流血效果等

    if  target:canNotBeenAttarked() then
        return 0, effect_    --无法击中
    end

    local att_ = attacker.battle_data
    local tar_ = target.battle_data

    local dmg_type = skill_config.dmg_type

    --是否闪避
    if  tar_.dod and tar_.dod > 0 then
        if  math.random() < tar_.dod - att_.a_dod then
            return 0, { dodge=1 }    --闪避
        end
    end


    --基础伤害
    local base_dmg = 0
    att_.attack = att_.attack or 1
    att_.attack2 = att_.attack2 or 1
    if  dmg_type == 1 then
        base_dmg = gg.rand_int_between( att_.attack, att_.attack2 )  --物理伤害
    else
        base_dmg = gg.rand_int_between( att_.spell,  att_.spell2 )   --元素伤害 火冰电
    end

    -- { power }  --伤害放大系数
    base_dmg = base_dmg * (skill_config.power or 1)

    --是否暴击
    if  att_.cr and att_.crd then
        if  math.random() < att_.cr then
            base_dmg = base_dmg * (1 + att_.crd)
            effect_.cr = 1
        end
    end

    local damages =  { 0, 0, 0, 0 }   --1=物理伤害 2=火  3=冰  4=电
    damages[ dmg_type ] = base_dmg


    local defence = 0
    if  dmg_type == 1 and tar_.defence and tar_.defence2then then
        defence = gg.rand_int_between( tar_.defence, tar_.defence2 )    --物理

        if att_.rd1  then defence = defence - att_.rd1 end            --减少防御值
        if att_.rd1p then defence = defence * ( 1-att_.rd1p ) end     --百分比减少防御

        --defence = 0 --元素 按各系抗性计算伤害
        --防御减伤开根号，可避免值过高   --defence = math.ceil( math.sqrt( defence ) )
        if  defence < 0 then  defence = 0 end
    end


    --物理伤害
    damages[1] = damages[1] - defence

    --计算元素伤害
    for i=2, 4 do
        local res_ = 0
        if  att_[ 's'  .. i ]  then damages[i] = damages[i]       + att_[ 's'  .. i ] end        --附加火伤 s2
        if  att_[ 'sp' .. i ]  then damages[i] = damages[i] * ( 1 + att_[ 'sp' .. i ] ) end      --百分比火伤 sp2

        if  tar_[ 'r'  .. i ]  then res_ =        tar_[ 'r'  .. i ] end        --火炕 r2
        if  att_[ 'rd' .. i ]  then res_ = res_ - att_[ 'rd' .. i ] end        --降火炕 rd2

        damages[i] = damages[i] * ( 1 - res_ )   --针对抗性降低伤害
    end




    --物理减伤
    if  tar_.rd_melee then damages[1] = damages[1] - tar_.rd_melee end
    if  damages[1] < 0 then damages[1] = 0 end


    --元素减伤
    local  element_dmg_ = damages[2] + damages[3] + damages[4]
    if  tar_.rd_spell then element_dmg_ = element_dmg_ - tar_.rd_spell end
    if  element_dmg_ < 0 then element_dmg_ = 0 end


    --合并所有伤害
    local damage_ = math.ceil( damages[1] + element_dmg_ )
    if  damage_ < 1 then damage_ = math.random(1,9) end      --最小伤害



    return damage_, effect_
end

-- 玩家改动装备，重算一个玩家的属性和词条
function BattleMgr.refreshPlayerAttr( uin_ )
    local player_data_ = gg.server_player_bag_data[uin_]

    local all_attr = {
        wspeed       = 1,   --武器速度
        attack       = 0,   --最小伤害
        attack2      = 0,   --最大伤害
        spell        = 0,   --最小技能伤害
        spell2       = 0,   --最大技能伤害
        defence      = 0,   --最小防御
        defence2     = 0,   --最大防御
    }

    --计算所有的已经装备的物品
    for i=1, 8 do
        local pos_ = 1000+i
        if  player_data_.bag_index[ pos_ ]  then
            local uuid_ = player_data_.bag_index[ pos_ ].uuid
            if  uuid_ then
                local item_ = player_data_.bag_items[ uuid_ ]

                --词缀
                if  item_ and item_.attrs then
                    --eq_10014={quality=4 uuid=eq_10014 defence=4 defence2=32 attrs={1={k=rd3 v=32} 2={k=agile v=20}
                    --3={k=r2 v=16} 4={k=s2 v=16} 5={k=ed v=8} 6={k=s1 v=20}}
                    --asset=sandboxSysId://items/icon12318.png pos=1002}
                    for seq_, attr in pairs( item_.attrs ) do
                        if  all_attr[ attr.k ]  then
                            all_attr[ attr.k ].v = all_attr[ attr.k ].v + attr.v
                        else
                            all_attr[ attr.k ] = { v=attr.v }
                        end
                    end
                end

                --攻防
                if  pos_ == 1001 then
                    --如果是武器，计算速度
                    if  all_attr.wspeed then all_attr.wspeed = item_.wspeed end
                end

                --基础攻防
                if  item_.attack   then all_attr.attack   = all_attr.attack   + item_.attack   end
                if  item_.attack2  then all_attr.attack2  = all_attr.attack2  + item_.attack2  end

                if  item_.spell    then all_attr.spell    = all_attr.spell    + item_.spell    end
                if  item_.spell2   then all_attr.spell2   = all_attr.spell2   + item_.spell2   end

                if  item_.defence  then all_attr.defence  = all_attr.defence  + item_.defence  end
                if  item_.defence2 then all_attr.defence2 = all_attr.defence2 + item_.defence2 end

            end
        end
    end



    --修改属性数据
    local player_ = gg.getPlayerByUin( uin_ )
    if  player_ then
        player_.eq_attrs = all_attr       --设置玩家的装备词缀，装备改动后
        player_:resetBattleData( false )
    end
end

return BattleMgr