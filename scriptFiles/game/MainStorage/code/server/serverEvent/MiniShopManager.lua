local store = game:GetService("DeveloperStoreService")
local MainStorage = game:GetService("MainStorage")
local ClassMgr = require(MainStorage.code.common.ClassMgr) ---@type ClassMgr
local gg = require(MainStorage.code.common.MGlobal) ---@type gg

---@class MiniShopManager
local MiniShopManager = ClassMgr.Class("MiniShopManager")
MiniShopManager.miniId2ShopGood = {
    [1] = { goodId = 1, desc = "获得99钻石", amount = 99 },
    [2] = { goodId = 1, desc = "获得400钻石", amount = 400 },
    [3] = { goodId = 1, desc = "获得900钻石", amount = 900 },
    [4] = { goodId = 1, desc = "获得2500钻石", amount = 2500 },
}

store.RemoteBuyGoodsCallBack:Connect(function(uin, goodsid, code, msg, num)
    if code ~= 0 then
        local player = gg.getPlayerByUin(uin)
        if player then
            player:SendHoverText("code" .. tostring(code))
        end

        print("迷你商品兑换失败！错误: ", code, msg)
        --0-购买成功
        --1001-地图未上传
        --1002-用户取消购买
        --1003-此商品查询失败
        --1004-请求失败
        --1005-迷你币不足
        --
        --710-商品不存在
        --711-商品状态异常
        --712-不能购买自己的商品
        --713-已购买该商品，不能重复购买
        --714-购买失败，购买数量已达上限
        --
        return
    end
    local player = gg.getPlayerByUin(uin)
    if not player then
        print("迷你商品兑换失败！不存在的玩家UIN：", uin)
        return
    end
    if not MiniShopManager.miniId2ShopGood[goodsid] then
        print("迷你商品兑换失败！未配置于Unity的商品ID：", goodsid)
        return
    end

    --code=0 购买成功
    print("Goods purchase Success.")
    print("RemoteBuyGoodsCallBack - uin : ", uin)
    print("RemoteBuyGoodsCallBack - goodsid: ", goodsid)
    print("RemoteBuyGoodsCallBack - num: ", num)

    player:AddGem(num)
end)

-- 服务器：获取某个玩家已购买的商品列表
function MiniShopManager.GetPlayerPurchasedList(playerid)
    local buyList = store:ServiceGetPlayerDeveloperProducts(playerid)
    print("cloud store buy list = ", buyList)
    local buyListLength = #buyList
    if buyListLength > 0 then
        -- 遍历每个商品信息
        local buyItem = {}
        for _, value in pairs(buyList) do
            print("cloud buy list key = ", _)
            for key, info in pairs(value) do
                buyItem[key] = info
                print("cloud buy list key = ", key)
                print("cloud buy list info = ", info)
            end
        end
    end
    return buyList
end

return MiniShopManager