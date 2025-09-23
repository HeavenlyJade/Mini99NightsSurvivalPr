local MainStorage = game:GetService('MainStorage')
-- 导入全局工具模块
local gg = require(MainStorage.code.common.MGlobal) ---@type gg
local ClassMgr = require(MainStorage.code.common.ClassMgr) ---@type ClassMgr
local CustomUI = require(MainStorage.code.common.customUi.CustomUI)    ---@type CustomUI
local ViewButton = require(MainStorage.code.client.Ui.ViewButton) ---@type ViewButton
local store = game:GetService("DeveloperStoreService")

---@class PayGui:CustomUI
local PayGui = ClassMgr.Class("PayGui", CustomUI)


-- 初始花UI
function PayGui:OnInit(data)

end

-- 服务端进入
function PayGui:S_BuildPacket(player, packet)

end

-- 购买迷你币
function PayGui:buyGem(player, evt)
    if evt.money then
        if evt.money == 99 then
            store:MiniCoinRecharge()
        end
        player.money.gemNum = player.money.gemNum + evt.money
        player:UpdateHud()
    end
end

-----------------客户端
-- 客户端进入
function PayGui:C_BuildUI(packet)
    gg.log("打开 充值 界面")

end

-- 初始化Ui
function PayGui:C_InitUI()
    local PayUi = self.view
    local PayPaths = self.paths
    local ui_size = gg.get_ui_size()
    PayUi:Get("背景").node.Size = Vector2.New(ui_size.x, ui_size.y)
    -- 注册关闭事件
    PayUi:Get(PayPaths.CloseButton, ViewButton).clickCb = function(ui, button)
        PayUi:Close()
    end
    -- 购买 钻石按钮
    local buy_btn = {
        [PayPaths.Pay_99] = 99,
        [PayPaths.Pay_400] = 400,
        [PayPaths.Pay_900] = 900,
        [PayPaths.Pay_2500] = 2500,
    }
    for path, val in pairs(buy_btn) do
        PayUi:Get(path, ViewButton).clickCb = function(ui, button)
            self:C_SendEvent("buyGem", { money = val, })
        end
    end
    -- 直充迷你比按钮
    PayUi:Get(PayPaths.Pay_Mini_Money, ViewButton).clickCb = function(ui, button)
        gg.log("打开充值")
        store:MiniCoinRecharge()
    end
end

return PayGui