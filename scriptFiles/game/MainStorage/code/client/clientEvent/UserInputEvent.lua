local game = game
local Enum = Enum
local MainStorage = game:GetService("MainStorage")
local UserInputService = game:GetService("UserInputService")
---@type gg
local gg = require(MainStorage.code.common.MGlobal)
---@type ClientEventManager
local ClientEventManager = require(MainStorage.code.client.clientEvent.ClientEventManager)

---@class UserInputEvent
gg.UserInputService = UserInputService
-- UserInputType 1 鼠标右
-- UserInputType 0 鼠标左·
-- UserInputType 10 键盘
local function inputBegan(inputObj, bGameProcessd)
    -- 键盘
    if inputObj.UserInputType == Enum.UserInputType.Keyboard.Value then
        -- 发送键盘按下
        ClientEventManager.Publish("PressKey", {
            key = inputObj.KeyCode,
            inputObj = inputObj,
            isDown = true
        })


    elseif inputObj.UserInputType == Enum.UserInputType.MouseButton1.Value then
        -- 发送鼠标左键按下
        ClientEventManager.Publish("MouseButton", {
            left = true,
            isDown = true,
            inputObj = inputObj,
        })
    elseif inputObj.UserInputType == Enum.UserInputType.MouseButton2.Value then
        -- 发送鼠标右键按下
        ClientEventManager.Publish("MouseButton", {
            right = true,
            isDown = true,
            inputObj = inputObj,
        })
    end
end

local function inputEnded(inputObj, bGameProcessd)
    -- 键盘
    if inputObj.UserInputType == Enum.UserInputType.Keyboard.Value then
        -- 发送键盘抬起
        ClientEventManager.Publish("PressKey", {
            key = inputObj.KeyCode,
            isDown = false,
            inputObj = inputObj,
        })
    elseif inputObj.UserInputType == Enum.UserInputType.MouseButton1.Value then
        -- 发送鼠标左键抬起
        ClientEventManager.Publish("MouseButton", {
            left = true,
            isDown = false,
            inputObj = inputObj,
        })
    elseif inputObj.UserInputType == Enum.UserInputType.MouseButton2.Value then
        -- 发送鼠标右键抬起
        ClientEventManager.Publish("MouseButton", {
            right = true,
            isDown = false,
            inputObj = inputObj,
        })
    end
end

local function inputChanged(inputObj, bGameProcessd)
    -- 鼠标移动
    if inputObj.UserInputType == Enum.UserInputType.MouseMovement.Value then
        ClientEventManager.Publish("ShowWorldItemData", {inputObj = inputObj})
    end
end

UserInputService.InputBegan:Connect(inputBegan)
UserInputService.InputEnded:Connect(inputEnded)
UserInputService.InputChanged:Connect(inputChanged)


