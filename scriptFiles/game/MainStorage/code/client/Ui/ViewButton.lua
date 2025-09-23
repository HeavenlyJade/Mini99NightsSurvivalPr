local MainStorage = game:GetService("MainStorage")
local ClassMgr = require(MainStorage.code.common.ClassMgr) ---@type ClassMgr
local ViewComponent = require(MainStorage.code.client.Ui.ViewComponent) ---@type ViewComponent
local ClientEventManager = require(MainStorage.code.client.clientEvent.ClientEventManager) ---@type ClientEventManager
local gg = require(MainStorage.code.common.MGlobal) ---@type gg
---@class ViewButton:ViewComponent
---@field New fun(node: SandboxNode, ui: ViewBase, path?: string, realButtonPath?: string): ViewButton
local ViewButton = ClassMgr.Class("ViewButton", ViewComponent)

---@param path2Child string
---@param icon string
---@param hoverIcon? string
function ViewButton:SetChildIcon(path2Child, icon, hoverIcon)
    hoverIcon = hoverIcon or icon
    local c = self:Get(path2Child)
    if c then
        local childNode = self:Get(path2Child).node
        local clickImg = self.childClickImgs[path2Child]
        if clickImg then
            clickImg.normalImg = icon
            clickImg.hoverImg = hoverIcon
            clickImg.clickImg = hoverIcon
        end
        childNode.Icon = icon
    end
end

-- 设置灰度
function ViewButton:SetGray(isGray)
    if isGray then
        -- 按钮取消
        self.img.enabled = false
        -- 设置灰度
        self.img.Grayed = true
    else
        -- 按钮启用
        self.img.enabled = true
        -- 取消灰度
        self.img.Grayed = false
    end
end

-- 点击结束
function ViewButton:OnTouchOut()
    local currentTime = gg.GetTimeStamp()
    if currentTime - self.lastTouchOutTime < 0.1 then
        return
    end
    self.lastTouchOutTime = currentTime

    self.isPressed = false
    if self.isHover then
        if self.hoverImg and self.hoverImg ~= "" then
            self.img.Icon = self.hoverImg
        end
        if self.hoverColor then
            self.img.FillColor = self.hoverColor
        end
    else
        self.img.Icon = self.normalImg
        self.img.FillColor = self.normalColor
    end
    if not self.enabled then
        return
    end
    if self.soundRelease then
        ClientEventManager.Publish("PlaySound", {
            soundAssetId = self.soundRelease
        })
    end

    -- Handle child images
    for _, props in pairs(self.childClickImgs) do
        local child = props.node
        if self.isHover then
            if props.hoverImg then
                child.Icon = props.hoverImg
            end
            if props.hoverColor then
                child.FillColor = props.hoverColor
            end
        else
            child.Icon = props.normalImg
            child.FillColor = props.normalColor
        end
    end

    if self.touchEndCb then
        self.touchEndCb(self.ui, self)
    end
end

-- 点击开始
function ViewButton:OnTouchIn(vector2)
    local currentTime = gg.GetTimeStamp()
    if currentTime - self.lastTouchInTime < 0.1 then
        return
    end
    self.lastTouchInTime = currentTime

    if not self.enabled then
        return
    end
    self.isPressed = true
    if self.clickImg and self.clickImg ~= "" then
        self.img.Icon = self.clickImg
    end
    if self.clickColor then
        self.img.FillColor = self.clickColor
    end
    if self.soundPress then
        ClientEventManager.Publish("PlaySound", {
            soundAssetId = self.soundPress
        })
    end
    -- Handle child images
    for _, props in pairs(self.childClickImgs) do
        local child = props.node
        if props.clickImg then
            child.Icon = props.clickImg
        end
        if props.clickColor then
            child.FillColor = props.clickColor
        end
    end
    if self.enabled then
        ClientEventManager.Publish("ButtonTouchIn", {
            button = self
        })
    end
    if self.touchBeginCb then
        self.touchBeginCb(self.ui, self, vector2)
    end
end

-- 点击事件
function ViewButton:OnClick(vector2)
    if not self.enabled then
        return
    end
    if self.clickCb then
        self.clickCb(self.ui, self)
    end
end

-- 触摸移动事件
function ViewButton:OnTouchMove(node, isTouchMove, vector2, int)
    if not self.enabled then
        return
    end
    if self.touchMoveCb then
        self.touchMoveCb(self.ui, self, vector2)
    end
end

-- 鼠标进入UI范围事件
function ViewButton:OnHoverIn(vector2)
    if self.isPressed then
        return
    end
    if not self.enabled then
        return
    end

    self.isHover = true
    if self.hoverImg and self.hoverImg ~= "" then
        self.img.Icon = self.hoverImg
    end
    if self.hoverColor then
        self.img.FillColor = self.hoverColor
    end
    if self.soundHover then
        ClientEventManager.Publish("PlaySound", {
            soundAssetId = self.soundPress
        })
    end
    for _, props in pairs(self.childClickImgs) do
        local child = props.node
        if props.hoverImg then
            child.Icon = props.hoverImg
        end
        if props.hoverColor then
            child.FillColor = props.hoverColor
        end
    end
end

-- 鼠标超出UI范围事件
function ViewButton:OnHoverOut()
    if self.isPressed then
        return
    end

    self.isHover = false
    self.img.Icon = self.normalImg
    self.img.FillColor = self.normalColor
    for _, props in pairs(self.childClickImgs) do
        local child = props.node
        child.Icon = props.normalImg
        child.FillColor = props.normalColor
    end
end

function ViewButton:SetNormalImg(Img)
    self.normalImg = Img
end

-- 初始化按钮基本属性
---@param img UIImage 按钮图片组件
function ViewButton:InitButtonProperties(img)
    img.ClickPass = false

    self.clickCb = nil ---@type fun(ui:ViewBase, button:ViewButton):boolean|nil
    self.touchBeginCb = nil ---@type fun(ui:ViewBase, button:ViewButton, pos:Vector2)
    self.touchMoveCb = nil ---@type fun(ui:ViewBase, button:ViewButton, pos:Vector2)
    self.touchEndCb = nil ---@type fun(ui:ViewBase, button:ViewButton, pos:Vector2)
    -- 获取 图片-点击 属性
    self.clickImg = img:GetAttribute("图片-点击") ---@type string
    -- 获取 图片-悬浮 属性
    self.hoverImg = img:GetAttribute("图片-悬浮") ---@type string
    -- 如果没有悬浮属性 悬浮属性设置为点击
    if self.hoverImg == "" then
        self.hoverImg = self.clickImg
    end
    -- 展示图标
    self.normalImg = img.Icon
    -- 悬浮颜色
    self.hoverColor = img:GetAttribute("悬浮颜色") ---@type ColorQuad
    -- 点击颜色
    self.clickColor = img:GetAttribute("点击颜色") ---@type ColorQuad
    -- UI节点填充颜色设置
    self.normalColor = img.FillColor
    -- 音效-点击
    self.soundPress = img:GetAttribute("音效-点击") ---@type string
    if self.soundPress == "" then
        self.soundPress = nil
    end
    -- 音效-悬浮
    self.soundHover = img:GetAttribute("音效-悬浮") ---@type string
    if self.soundHover == "" then
        self.soundHover = nil
    end
    -- 音效-抬起
    self.soundRelease = img:GetAttribute("音效-抬起") ---@type string
    if self.soundRelease == "" then
        self.soundRelease = nil
    end
    -- 鼠标进入UI范围事件
    img.RollOver:Connect(function(node, isOver, vector2)
        self:OnHoverIn(vector2)
    end)
    -- 鼠标超出UI范围事件
    img.RollOut:Connect(function(node, isOver, vector2)
        self:OnHoverOut()
    end)

    self:_BindNodeAndChild(img, false, true)
end

function ViewButton:_BindNodeAndChild(child, isDeep, bindEvents)
    if child:IsA("UIImage") then
        if isDeep then
            local clickImg = child:GetAttribute("图片-点击")---@type string|nil
            local hoverImg = child:GetAttribute("图片-悬浮") ---@type string|nil
            if clickImg == "" then
                clickImg = nil
            end
            if hoverImg == "" then
                hoverImg = clickImg
            end

            self.childClickImgs[child.Name] = {
                node = child,
                normalImg = child.Icon, ---@type string
                clickImg = clickImg,
                hoverImg = hoverImg,

                hoverColor = child:GetAttribute("悬浮颜色"), ---@type ColorQuad
                clickColor = child:GetAttribute("点击颜色"), ---@type ColorQuad
                normalColor = child.FillColor,
            }
        end
        if bindEvents then
            child.TouchBegin:Connect(function(node, isTouchBegin, vector2, number)
                self:OnTouchIn(vector2)
            end)
            child.TouchEnd:Connect(function(node, isTouchEnd, vector2, number)
                self:OnTouchOut()
            end)
            child.TouchMove:Connect(function(node, isTouchMove, vector2, number)
                self:OnTouchMove(node, isTouchMove, vector2, number)
            end)
            child.Click:Connect(function(node, isClick, vector2, number)
                self:OnClick(vector2)
            end)
        end
    end
    for _, c in ipairs(child.Children) do
        ---@type UIComponent
        if c:GetAttribute("继承按钮") then
            self:_BindNodeAndChild(c, true, true)
        end
    end
end

function ViewButton:OnInit(node, ui, path, realButtonPath)
    self.childClickImgs = {} ---@type table<string, table>
    self.enabled = true
    self.lastTouchInTime = 0  -- 防抖：记录上次TouchIn时间
    self.lastTouchOutTime = 0 -- 防抖：记录上次TouchOut时间
    self.isPressed = false
    self.img = node ---@type UIImage
    if realButtonPath then
        self.img = self.img[realButtonPath]
    end
    local img = self.img

    self:InitButtonProperties(img)

    if img["pc_hint"] then
        img["pc_hint"].Visible = game.RunService:IsPC()
    end
    self.isHover = false
end

-- === 新增：销毁按钮，清理所有引用和事件绑定 ===
function ViewButton:Destroy()

    -- === 关键：销毁UI节点，自动清理所有事件绑定和子节点 ===
    if self.node then
        self.node:Destroy()
    end

    -- 清理回调函数引用
    self.clickCb = nil
    self.touchBeginCb = nil
    self.touchMoveCb = nil
    self.touchEndCb = nil

    -- 清理图像引用
    self.img = nil
    self.normalImg = nil
    self.hoverImg = nil
    self.clickImg = nil

    -- 清理颜色引用
    self.normalColor = nil
    self.hoverColor = nil
    self.clickColor = nil

    -- 清理子图像字典
    if self.childClickImgs then
        for child, _ in pairs(self.childClickImgs) do
            self.childClickImgs[child.Name] = nil
        end
        self.childClickImgs = {}
    end

    -- 清理ViewComponent的基础属性
    self.node = nil
    self.ui = nil
    self.path = nil
    self.extraParams = nil
    self.enabled = nil
    self.isHover = nil
end

return ViewButton
