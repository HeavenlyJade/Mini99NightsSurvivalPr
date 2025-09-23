------------------------------------------------------------------------------------
-- -*- coding: utf-8 -*-
--
-- @作者:         zhenghao
-- @创建日期:      2025-09-05
-- @模块名称:      MGlobal
-- @描述:         全局函数
-- @版本:         v1.0
------------------------------------------------------------------------------------
-- 引入管理对象
local game = game
local inputService = game:GetService("UserInputService")
local Players = game:GetService('Players')
local MainStorage = game:GetService("MainStorage")
local Vec = require(MainStorage.code.common.math.vec)
local Vec2 = require(MainStorage.code.common.math.vec2)
local Vec3 = require(MainStorage.code.common.math.vec3)
local Vec4 = require(MainStorage.code.common.math.vec4)
local Quat = require(MainStorage.code.common.math.Quat)
local Math = require(MainStorage.code.common.math.Math)
------------------------------------------------------------------------------------

-- 判断空表
table.is_empty = function(tab)
    if type(tab) ~= 'table' or not next(tab) then
        return true
    end
    return false
end

---@class gg
local gg = {
    vec = Vec,
    Vec2 = Vec2, ---@type Vec2
    Vec3 = Vec3, ---@type Vec3
    Vec4 = Vec4, ---@type Vec4
    Quat = Quat, ---@type Quat
    math = Math, ---@type Math
    -- 玩家列表
    server_players_list = {}, ---@type table<number, Player>
    -- 玩家名称列表
    server_players_name_list = {}, ---@type table<string, Player>
    -- 场景列表
    server_scene_list = {}, ---@type table<string, Scene>
    -- uuid 起始标记
    uuid_start = math.random(100000, 999999),
    -- 网络通道
    network_channel = nil, ---@type NetworkChannel
    -- 广告渠道
    Advertisement = nil,
    -- server_main的tick
    tick = 0,
    -- 当前客户端场景
    client_scene_name = "MainCity",
    -- 当前客户端场景
    client_scene_Type = "主场景",
    -- 拾取物品距离
    client_pick_dist = 500,

    client_aoe_cylinder = nil, -- aoe技能碰撞控件

    thread_call = coroutine.work,
}

-- 获得player实例
---@param uin_ number 玩家ID
---@return Player|nil 玩家实例
function gg.getPlayerByUin(uin_)
    if gg.server_players_list[uin_] then
        return gg.server_players_list[uin_];
    end
    return nil
end

-- 建立一个uuid
---@param pre_ string 前缀
---@return string 生成的UUID
function gg.create_uuid(pre_)
    gg.uuid_start = gg.uuid_start + 1
    return pre_ .. gg.uuid_start .. '_' .. (gg.GetTimeStamp() * 1000 + math.random(1, 1000)) % 1000 .. '_' ..
            math.random(10000, 99999)
end

function gg.GetTimeStamp()
    return game.RunService:CurrentSteadyTimeStampMS() / 1000
end

---@param node SandboxNode
---@param path string
---@return SandboxNode|nil
function gg.GetChild(node, path)
    local root = node
    local cacheKey = path
    local fullPath = ""
    local lastPart = ""
    for part in path:gmatch("[^/]+") do
        -- 用/分割字符串
        if part ~= "" then
            lastPart = part
            if not node then
                gg.log(string.format("[%s]获取路径[%s]失败: 在[%s]处节点不存在。%s", root.Name, path,
                        fullPath, debug.traceback()))
                return nil
            end
            node = node[part]
            if fullPath == "" then
                fullPath = part
            else
                fullPath = fullPath .. "/" .. part
            end
        end
    end

    if not node then
        gg.log(string.format("[%s]获取路径[%s]失败: 最终节点[%s]不存在。%s", root.Name, path, lastPart, debug.traceback()))
        return nil
    end
    return node
end

-- lua-table 转字符串（打印日志使用）
---@param tbl table 要转换的表
---@param level_? number 递归层级
---@param visited? table 已访问的表
---@return string 转换后的字符串
function gg.table2str(tbl, level_, visited)
    if type(tbl) ~= "table" then
        return tostring(tbl)
    end
    level_ = level_ or 0
    if level_ >= 20 then
        gg.log('ERROR table2str level>=10')
        return '' -- 层数保护
    end
    visited = visited or {} -- 防止两个table互相引用，互相循环
    local tab = { '{' }
    for k, v in pairs(tbl) do
        if type(v) == 'table' then
            if visited[v] then
                if v.uuid then
                    tab[#tab + 1] = 'VISITED uuid=' .. v.uuid
                else
                    tab[#tab + 1] = 'VISITED ' .. tostring(v)
                end
            else
                visited[v] = true -- table作为key等同于tostring(v)
                if v.ToString then
                    tab[#tab + 1] = tostring(k) .. '=' .. v:ToString()
                else
                    tab[#tab + 1] = tostring(k) .. gg.table2str(v, level_ + 1, visited)
                end
            end
        elseif type(v) == 'function' or type(v) == 'userdata' or type(v) == 'thread' then
            -- 忽略不打印
        else
            tab[#tab + 1] = tostring(k) .. '=' .. tostring(v)
        end
    end

    tab[#tab + 1] = '}'
    return table.concat(tab, ' ')
end

-- 打印日志使用
---@param ... any 要打印的内容
function gg.format(...)
    local tab = {}
    local n = select('#', ...)
    for i = 1, n do
        local v = select(i, ...)
        if v == nil then
            tab[i] = "nil"
        elseif type(v) == 'table' then
            if v.ToString then
                tab[i] = v:ToString()
            else
                tab[i] = tostring(gg.table2str(v))
            end
        else
            tab[i] = tostring(v)
        end
    end
    if type(tab[1]) == "string" and string.find(tab[1], "%%s") then
        local fmt_args = {}
        for i = 2, n do
            fmt_args[#fmt_args + 1] = tab[i]
        end
        tab[1] = string.format(tab[1], unpack(fmt_args))
        for i = 2, #tab do
            tab[i] = nil
        end
    end
    local s = table.concat(tab, ' ')
    return s
end

-- 打印日志使用
---@param ... any 要打印的内容
function gg.log(...)
    local s = gg.format(...)
    print(s)
    return s
end

-- 获取当前玩家使用的2d控件使用的ui_root，不存在则建立  (只有client会使用)
---@return SandboxNode UI根节点
function gg.create_ui_root()
    local player_ = game.Players.LocalPlayer
    if player_ and player_.PlayerGui then
        if player_.PlayerGui.ui_root then
            return player_.PlayerGui.ui_root
        else
            local ui_root = SandboxNode.New('UIRoot')
            ui_root.LocalSyncFlag = Enum.NodeSyncLocalFlag.DISABLE
            ui_root.Name = 'ui_root'
            ui_root.Parent = player_.PlayerGui
            return ui_root;
        end
    end
end

-- 获取屏幕大小
---@return Vector2 屏幕尺寸
function gg.get_ui_size()
    if not gg.ui_size then
        wait(1)
        gg.ui_size = game:GetService('WorldService'):GetUISize()
    end
    return gg.ui_size
end

-- 文字框
---@param root_ SandboxNode 父节点
---@param title_ string 标题文本
---@return UITextLabel 创建的文本标签
function gg.createTextLabel(root_, title_)
    local textLabel_ = SandboxNode.new('UITextLabel', root_)
    textLabel_.Size = Vector2.New(3000, 800)
    textLabel_.Pivot = Vector2.New(0.5, 0.5)

    textLabel_.FontSize = 30
    textLabel_.Scale = Vector2.New(5, 5)

    textLabel_.TitleColor = ColorQuad.New(255, 255, 255, 255)
    textLabel_.FillColor = ColorQuad.New(0, 0, 0, 0)

    textLabel_.TextVAlignment = Enum.TextVAlignment.Center -- Top  Bottom
    textLabel_.TextHAlignment = Enum.TextHAlignment.Center -- Left Right

    -- textLabel_.Position   = Vector2.New( 0,  0 )
    textLabel_.Title = title_

    return textLabel_
end

-- 数字格式化函数
function gg.FormatLargeNumber(num)
    if num < 10000 then
        return tostring(num)
    end

    local units = { "", "万", "亿", "兆", "京" }
    local unitIndex = 1
    local result = num

    while result >= 10000 and unitIndex < #units do
        result = result / 10000
        unitIndex = unitIndex + 1
    end

    -- 保留一位小数
    result = math.floor(result * 10) / 10

    -- 如果是整数，去掉小数点
    if result == math.floor(result) then
        return tostring(math.floor(result)) .. units[unitIndex]
    else
        -- 检查小数点前的数字位数
        local wholePart = math.floor(result)
        if wholePart >= 1000 and wholePart < 10000 then
            -- 如果是4位数，去掉小数部分
            return tostring(wholePart) .. units[unitIndex]
        else
            return tostring(result) .. units[unitIndex]
        end
    end
end

-- 获得当前玩家（客户端侧）
---@return Character 当前玩家角色
function gg.getClientLocalPlayer()
    return Players.LocalPlayer.Character
end


--克隆一个物体
function gg.cloneFromArchitecture(name_)
    if MainStorage["模型列表"]["建筑物"][name_] then
        return MainStorage["模型列表"]["建筑物"][name_]:Clone()
    end
end

--克隆一个物体
function gg.GetFromArchitecture(name_)
    if MainStorage["模型列表"]["建筑物"][name_] then
        return MainStorage["模型列表"]["建筑物"][name_]
    end
end

--克隆一个物体
function gg.cloneFromTemplate(name_)
    if MainStorage["模型列表"]["物品列表"][name_] then
        return MainStorage["模型列表"]["物品列表"][name_]:Clone()
    end
end

--克隆一个物体
function gg.GetFromTemplate(name_)
    if MainStorage["模型列表"]["物品列表"][name_] then
        return MainStorage["模型列表"]["物品列表"][name_]
    end
end

--服务器获得建筑物容器
function gg.serverGetContainerArchitecture(scene_name_)
    return game.WorkSpace.Scene[scene_name_]["建筑物容器"]
end

--服务器获得怪物容器
function gg.serverGetContainerDropItems(scene_name_)
    return game.WorkSpace.Scene[scene_name_]["掉落物容器"]
end



-- input 100 return  0 to 100
---@param int32 number 上限值
---@return number 随机数
function gg.rand_int(int32)
    -- return math.floor( math.random() * int32 + 0.5 )
    return math.random(int32 + 1) - 1
end

-- input 100 return  -100 to 100 (可以为负数)
function gg.rand_int_both(int32)
    --local ret_ = math.floor( math.random() * int32 + 0.5 )
    --if  math.random() < 0.5 then
    --ret_ = 0 - ret_
    --end
    --return  ret_
    return math.random(0 - int32, int32)
end



--获得两个整数之间的一个随机值
function gg.rand_int_between(int1_, int2_)
    if int1_ > int2_ then
        return math.random(int2_, int1_)
    else
        return math.random(int1_, int2_)
    end
end


-- 快速判断两个点是否超距离(length)
---@param pos1 Vector3 位置1
---@param pos2 Vector3 位置2
---@param len number 距离
---@return boolean 是否超出距离
function gg.out_distance(pos1, pos2, len)
    local dis_ = (pos1 - pos2).length
    return dis_ > len
end

-- 客户端获得掉落物容器
function gg.clientGetContainerItem()
    return game.WorkSpace["Scene"][gg.client_scene_name]["掉落物容器"]
end

-- 客户端获得掉落物容器
function gg.clientGetContainerMonster()
    return game.WorkSpace["Scene"][gg.client_scene_name]["怪物容器"]
end


-- 客户端获得玩家信息
function gg.clientGetLocalPlayer()
    return Players.LocalPlayer.Character
end

-- 以xyz为中心 r为半径在 在圆的周长上取点 y坐标不变
function gg.randomPointOnCirclePerimeter(x, y, z, r)
    -- 生成0到2π之间的随机角度（均匀分布）
    local angle = math.random() * 2 * math.pi

    -- 利用圆的参数方程计算偏移量
    -- 此时x和z方向的偏移量确保了点到中心的距离恒为r
    local dx = r * math.cos(angle)  -- x方向偏移
    local dz = r * math.sin(angle)  -- z方向偏移

    -- 计算最终坐标（y坐标与中心点相同）
    return Vector3.New(x + dx, y, z + dz)
end

---@param node SandboxNode
function gg.GetFullPath(node)
    local path = node.Name
    local parent = node.Parent

    if parent.Name ~= "WorkSpace" then
        while parent do
            path = parent.Name .. "/" .. path
            parent = parent.Parent
            if not parent or parent.Name == "WorkSpace" then
                break
            end
        end
    end

    return path
end

--使用uuid查找一个怪物 m10002 m20003
function gg.findMonsterByUuid(uuid_)
    for scene_name, scene in pairs(gg.server_scene_list) do
        if not table.is_empty(scene.players) then
            --场景内有玩家
            if scene.monsters[uuid_] then
                return scene.monsters[uuid_]
            end
        end
    end
    return nil   --查找失败
end


--图片
function gg.createImage(root_, icon_)
    local image_ = SandboxNode.new("UIImage")
    image_.LocalSyncFlag = Enum.NodeSyncLocalFlag.DISABLE
    image_.Parent = root_
    if icon_ then
        image_.Icon = icon_
    end
    return image_
end

--获得两个位置的角度euler值( Y轴不变保持水平 )
function gg.getEulerByPositonY0( pos1_, pos2_ )
    local dir_ = pos1_ - pos2_
    local dir_y0_ = Vector3.new( dir_.x, 0, dir_.z )
    Vector3.Normalize( dir_y0_ )

    local _, rot = Quaternion.LookAt(dir_y0_, gg.VECUP)
    return Vector3.FromQuaternion(rot)
end


--actor1朝向某个目标actor2 ( Y轴不变保持水平 )
function gg.actorLookAtActorY0( actor1_, actor2_ )
    actor1_.Euler = gg.getEulerByPositonY0( actor1_.Position, actor2_.Position )
end

--获得物体朝向的vector3向量
function gg.getDirVector3( obj_ )
    local vec3 = obj_.Rotation:LookDir()
    return vec3    --normalized dir
end

return gg