local vec = {}

vec.M_EPSILON = 0.000001
vec.M_PI = 3.14159265358979323846
vec.M_DEGTORAD = vec.M_PI / 180.0
vec.M_DEGTORAD_2 = vec.M_PI / 360.0
vec.M_RADTODEG = 1.0 / vec.M_DEGTORAD
vec.Rad2Deg = 180.0 / vec.M_PI
vec.Deg2Rad = vec.M_PI / 180.0


-- 计算两点的xz
---@param v Vector2 要标准化的向量
---@return Vector2 标准化后的向量
function vec.calculateDistance(v1, v2)
    -- 计算两点间距离的函数
    local dx = v2.x - v1.x
    local dy = v2.z - v1.z
    return math.sqrt(dx^2 + dy^2)
end


-- Vector2 specific functions
---@param v Vector2 要标准化的向量
---@return Vector2 标准化后的向量
function vec.Normalize2(v)
    return Vector2.Normalize(v)
end

---@param v1 Vector2 第一个向量
---@param v2 Vector2 第二个向量
---@return number 两个向量之间的距离
function vec.Distance2(v1, v2)
    return math.sqrt(vec.DistanceSq2(v1, v2))
end

---@param v1 Vector2 第一个向量
---@param v2 Vector2 第二个向量
---@return number 两个向量之间距离的平方
function vec.DistanceSq2(v1, v2)
    local dx = v1.x - v2.x
    local dy = v1.y - v2.y
    return dx * dx + dy * dy
end

---@param v1 Vector2 第一个向量
---@param v2 Vector2 第二个向量
---@return number 两个向量的点积
function vec.Dot2(v1, v2)
    return Vector2.Dot(v1, v2)
end


---@param target Vector3|Entity|Vec3
---@return Vector3
function vec.ToVector3(target)
    if type(target) == "userdata" then
        return target
    else
        if type(target) == "table" and target.Is and target:Is("Entity") then
            return target:GetPosition():ToVector3()
        else
            return target:ToVector3()
        end
    end
end

---@param v1 Vector2 起始向量
---@param v2 Vector2 目标向量
---@param percent number 插值比例(0-1)
---@return Vector2 插值后的向量
function vec.Lerp2(v1, v2, percent)
    return Vector2.Lerp(v1, v2, percent)
end

---@param v1 Vector2 向量
---@param x number x坐标
---@param y number y坐标
---@return Vector2 相加后的向量
function vec.Add2(v1, x, y)
    return Vector2.New(v1.x + x, v1.y + y)
end

function vec.ToDirection(v1)
    -- Convert angles to radians
    local pitch = v1.x * vec.M_DEGTORAD
    local yaw = v1.y * vec.M_DEGTORAD

    -- Calculate direction vector components
    local x = math.sin(yaw) * math.cos(pitch)
    local y = -math.sin(pitch)
    local z = math.cos(yaw) * math.cos(pitch)

    -- Return normalized direction vector
    return Vector3.New(x, y, z)
end

---@param v Vector2 向量
---@param scalar_or_vec number|Vector2 标量值或向量
---@return Vector2 相乘后的向量
function vec.Multiply2(v, scalar_or_vec)
    if type(scalar_or_vec) == "number" then
        return Vector2.New(v.x * scalar_or_vec, v.y * scalar_or_vec)
    else
        return Vector2.New(v.x * scalar_or_vec.x, v.y * scalar_or_vec.y)
    end
end

-- Vector3 specific functions
---@param v Vector3 要标准化的向量
---@return Vector3 标准化后的向量
function vec.Normalize3(v)
    return Vector3.Normalize(v)
end

---@param v1 Vector3 第一个向量
---@param v2 Vector3 第二个向量
---@return number 两个向量之间的距离
function vec.Distance3(v1, v2)
    return math.sqrt(vec.DistanceSq3(v1, v2))
end

---@param v1 Vector3 第一个向量
---@return number 向量长度
function vec.Length3(v1)
    return math.sqrt(v1.x * v1.x + v1.y * v1.y + v1.z * v1.z)
end

---@param v1 Vector3 第一个向量
---@param v2 Vector3 第二个向量
---@return number 两个向量之间距离的平方
function vec.DistanceSq3(v1, v2)
    local dx = v1.x - v2.x
    local dy = v1.y - v2.y
    local dz = v1.z - v2.z
    return dx * dx + dy * dy + dz * dz
end

---@param v1 Vector3 第一个向量
---@param v2 Vector3 第二个向量
---@return number 两个向量的点积
function vec.Dot3(v1, v2)
    return Vector3.Dot(v1, v2)
end

---@param v1 Vector3 起始向量
---@param v2 Vector3 目标向量
---@param percent number 插值比例(0-1)
---@return Vector3 插值后的向量
function vec.Lerp3(v1, v2, percent)
    return Vector3.Lerp(v1, v2, percent)
end

---@param v1 Vector3 第一个向量
---@param v2 Vector3 第二个向量
---@return Vector3 两个向量的叉积
function vec.Cross3(v1, v2)
    return Vector3.Cross(v1, v2)
end

---@param v1 Vector3 向量
---@param x number x坐标
---@param y number y坐标
---@param z number z坐标
---@return Vector3 相加后的向量
function vec.Add3(v1, x, y, z)
    return Vector3.New(v1.x + x, v1.y + y, v1.z + z)
end

---@param v Vector3 向量
---@param scalar_or_vec number|Vector3 标量值或向量
---@return Vector3 相乘后的向量
function vec.Multiply3(v, scalar_or_vec)
    if type(scalar_or_vec) == "number" then
        return Vector3.New(v.x * scalar_or_vec, v.y * scalar_or_vec, v.z * scalar_or_vec)
    else
        return Vector3.New(v.x * scalar_or_vec.x, v.y * scalar_or_vec.y, v.z * scalar_or_vec.z)
    end
end

-- Vector4 specific functions
---@param v Vector4 要标准化的向量
---@return Vector4 标准化后的向量
function vec.Normalize4(v)
    return Vector4.Normalize(v)
end

---@param v1 Vector4 第一个向量
---@param v2 Vector4 第二个向量
---@return number 两个向量之间的距离
function vec.Distance4(v1, v2)
    return math.sqrt(vec.DistanceSq4(v1, v2))
end

---@param v1 Vector4 第一个向量
---@param v2 Vector4 第二个向量
---@return number 两个向量之间距离的平方
function vec.DistanceSq4(v1, v2)
    local dx = v1.x - v2.x
    local dy = v1.y - v2.y
    local dz = v1.z - v2.z
    local dw = v1.w - v2.w
    return dx * dx + dy * dy + dz * dz + dw * dw
end

---@param v1 Vector4 第一个向量
---@param v2 Vector4 第二个向量
---@return number 两个向量的点积
function vec.Dot4(v1, v2)
    return Vector4.Dot(v1, v2)
end

---@param v1 Vector4 起始向量
---@param v2 Vector4 目标向量
---@param percent number 插值比例(0-1)
---@return Vector4 插值后的向量
function vec.Lerp4(v1, v2, percent)
    return Vector4.Lerp(v1, v2, percent)
end

---@param v1 Vector4 向量
---@param x number x坐标
---@param y number y坐标
---@param z number z坐标
---@param w number w坐标
---@return Vector4 相加后的向量
function vec.Add4(v1, x, y, z, w)
    return Vector4.New(v1.x + x, v1.y + y, v1.z + z, v1.w + w)
end

---@param v Vector4 向量
---@param scalar_or_vec number|Vector4 标量值或向量
---@return Vector4 相乘后的向量
function vec.Multiply4(v, scalar_or_vec)
    if type(scalar_or_vec) == "number" then
        return Vector4.New(v.x * scalar_or_vec, v.y * scalar_or_vec, v.z * scalar_or_vec, v.w * scalar_or_vec)
    else
        return Vector4.New(v.x * scalar_or_vec.x, v.y * scalar_or_vec.y, v.z * scalar_or_vec.z, v.w * scalar_or_vec.w)
    end
end

return vec