local MainStorage = game:GetService('MainStorage')
-- 导入全局工具模块
local gg = require(MainStorage.code.common.MGlobal) ---@type gg
local ClassMgr = require(MainStorage.code.common.ClassMgr) ---@type ClassMgr
local CustomUI = require(MainStorage.code.common.customUi.CustomUI)    ---@type CustomUI
local ViewButton = require(MainStorage.code.client.Ui.ViewButton) ---@type ViewButton
---@type ViewComponent
local ViewComponent = require(MainStorage.code.client.Ui.ViewComponent)
---@type ViewList
local ViewList = require(MainStorage.code.client.Ui.ViewList)

---@class QuestGui:CustomUI
local QuestGui = ClassMgr.Class("QuestGui", CustomUI)


-- 初始花UI
function QuestGui:OnInit(data)
    -- 任务信息
    self.questList = {
        ["收集类"] = {
            ["任务"] = {
                [1] = { ["内容"] = "累计收集10个樱桃", ["数量"] = 10, ["物品"] = "樱桃", ["进度"] = 0 },
                [2] = { ["内容"] = "累计收集20个胡萝卜", ["数量"] = 20, ["物品"] = "胡萝卜", ["进度"] = 0 },
                [3] = { ["内容"] = "单局收集5个树木", ["数量"] = 5, ["物品"] = "树木", ["进度"] = 0 },
            },
            ["是否完成"] = false,
            ["奖励钻石"] = 7,
        },
        ["战斗类"] = {
            ["任务"] = {
                [1] = { ["内容"] = "累计击败10只野兔", ["数量"] = 10, ["物品"] = "野兔", ["进度"] = 0 },
                [2] = { ["内容"] = "累计击败10只狼", ["数量"] = 10, ["物品"] = "狼", ["进度"] = 0 },
                [3] = { ["内容"] = "累计击败5只熊", ["数量"] = 5, ["物品"] = "熊", ["进度"] = 0 },
            },
            ["是否完成"] = false,
            ["奖励钻石"] = 8,
        },
        ["生存类"] = {
            ["任务"] = {
                [1] = { ["内容"] = "单局生存20天", ["数量"] = 30, ["物品"] = "天", ["进度"] = 0 },
                [2] = { ["内容"] = "单局生存50天", ["数量"] = 50, ["物品"] = "天", ["进度"] = 0 },
                [3] = { ["内容"] = "累计生存99天", ["数量"] = 99, ["物品"] = "天", ["进度"] = 0 },
            },
            ["是否完成"] = false,
            ["奖励钻石"] = 9,
        },
        ["时长类"] = {
            ["任务"] = {
                [1] = { ["内容"] = "累计在线120分钟", ["数量"] = 60, ["物品"] = "秒", ["进度"] = 0 },
            },
            ["是否完成"] = false,
            ["奖励钻石"] = 10,
        },
    }
    -- 任务类型
    self.questTypeList = { "收集类", "战斗类", "生存类", "时长类" }
end

-- 服务端进入
function QuestGui:S_BuildPacket(player, packet)
    local ret_t = {}
    local playerQuestData = player.questData

    for questType, QuestData in pairs(self.questList) do
        local questList = QuestData["任务"]
        for i = 1, #questList do
            questList[i]["进度"] = playerQuestData[questType]["任务"][i]["数量"]
        end
        QuestData["是否完成"] = playerQuestData[questType]["是否完成"]
        QuestData["是否领取奖励"] = playerQuestData[questType]["领取奖励"]
        ret_t[questType] = QuestData
    end
    packet.questList = ret_t
end

-- 领取任务奖励
function QuestGui:GetQuestGift(player, evt)
    -- 任务类型
    local questType = evt.questType
    -- 判断任务奖励是否领取
    local playerQuestData = player.questData
    if not playerQuestData[questType] then
        return false
    end
    -- 领取过
    if playerQuestData[questType]["领取奖励"] then
        return false
    end
    -- 验证任务是否确定完成
    local playerTask = playerQuestData[questType]["任务"]
    local taskList = self.questList[questType]["任务"]
    for i, v in ipairs(taskList) do
        if playerTask[i]["数量"] < v["数量"] then
            return false
        end
    end
    playerQuestData[questType]["领取奖励"] = true
    -- 增加钻石
    player.money.gemNum = player.money.gemNum + self.questList[questType]["奖励钻石"]
    -- 更新角色显示
    player:UpdateHud()
    -- 重新打开界面刷新显示
    self:S_Open(player)
end

-----------------客户端
-- 客户端进入
function QuestGui:C_BuildUI(packet)
    self.questList = packet.questList
    for i, questType in ipairs(self.questTypeList) do
        local questData = self.questList[questType]
        -- 任务信息
        local taskList = questData["任务"]
        -- 是否完成
        local isOver = questData["是否完成"]
        -- 奖励钻石数量
        local getGemGiftNum = questData["奖励钻石"]
        -- 是否领取奖励
        local getGemGift = questData["是否领取奖励"]
        -- 总进度 为1*任务数量
        local mProgress = 1 * #taskList
        -- 当前进度
        local vProgress = 0
        -- 清空任务信息
        self["Quest" .. i .. "List"]:SetElementSize(0)
        -- 遍历任务列表
        for index, data in ipairs(taskList) do
            local child = self["Quest" .. i .. "List"]:GetChild(index, 1)
            data["进度"] = data["进度"] < data["数量"] and data["进度"] or data["数量"]
            if (data["进度"] / data["数量"]) >= 1 then
                child:Get(self.paths.QuestDesc).node.TitleColor = ColorQuad.New(255, 255, 255, 155)
                child:Get(self.paths.QuestProgress).node.TitleColor = ColorQuad.New(255, 255, 255, 155)
            end
            vProgress = vProgress + (data["进度"] / data["数量"])
            child:Get(self.paths.QuestDesc).node.Title = data["内容"]
            child:Get(self.paths.QuestProgress).node.Title = string.format("%s/%s", data["进度"], data["数量"])
        end
        if (vProgress / mProgress) == 1 then
            isOver = true
        end
        gg.log(questType, "完成进度 - ", (vProgress / mProgress) * 100)
        -- 已完成显示
        self["Quest" .. i .. "Over"].Visible = isOver
        self["Quest" .. i .. "IconMask"].Visible = not isOver
        self["Quest" .. i .. "IconMask"].Size = Vector2.new(self["Quest" .. i .. "IconMask"].Size.x, self["Quest" .. i .. "IconMask"].Size.x * (1 - (vProgress / mProgress)))
        if not isOver then
            -- 不显示奖励
            self["Quest" .. i .. "IconGemBtn"].img.Visible = false
        else
            if getGemGift then
                -- 不显示奖励
                self["Quest" .. i .. "IconGemBtn"].img.Visible = false
            else
                -- 奖励数量
                self["Quest" .. i .. "IconGemNum"].Title = "x" .. tostring(getGemGiftNum)
                -- 显示奖励
                self["Quest" .. i .. "IconGemBtn"].img.Visible = true
                -- 点击事件
                self["Quest" .. i .. "IconGemBtn"].clickCb = function()
                    self:C_SendEvent("GetQuestGift", { questType = questType })
                end
            end
        end
    end
end

-- 初始化Ui
function QuestGui:C_InitUI()
    local QuestUi = self.view
    local QuestPaths = self.paths
    local ui_size = gg.get_ui_size()
    QuestUi:Get("背景").node.Size = Vector2.New(ui_size.x, ui_size.y)
    -- 注册关闭事件
    QuestUi:Get(QuestPaths.CloseButton, ViewButton).clickCb = function(ui, button)
        QuestUi:Close()
    end

    self.Quest1IconGemBtn = QuestUi:Get(QuestPaths.Quest1IconGemBtn, ViewButton)
    self.Quest2IconGemBtn = QuestUi:Get(QuestPaths.Quest2IconGemBtn, ViewButton)
    self.Quest3IconGemBtn = QuestUi:Get(QuestPaths.Quest3IconGemBtn, ViewButton)
    self.Quest4IconGemBtn = QuestUi:Get(QuestPaths.Quest4IconGemBtn, ViewButton)

    self.Quest1IconGemNum = QuestUi:Get(QuestPaths.Quest1IconGemNum).node
    self.Quest2IconGemNum = QuestUi:Get(QuestPaths.Quest2IconGemNum).node
    self.Quest3IconGemNum = QuestUi:Get(QuestPaths.Quest3IconGemNum).node
    self.Quest4IconGemNum = QuestUi:Get(QuestPaths.Quest4IconGemNum).node

    self.Quest1IconMask = QuestUi:Get(QuestPaths.Quest1IconMask).node
    self.Quest2IconMask = QuestUi:Get(QuestPaths.Quest2IconMask).node
    self.Quest3IconMask = QuestUi:Get(QuestPaths.Quest3IconMask).node
    self.Quest4IconMask = QuestUi:Get(QuestPaths.Quest4IconMask).node

    self.Quest1Icon = QuestUi:Get(QuestPaths.Quest1Icon).node
    self.Quest2Icon = QuestUi:Get(QuestPaths.Quest2Icon).node
    self.Quest3Icon = QuestUi:Get(QuestPaths.Quest3Icon).node
    self.Quest4Icon = QuestUi:Get(QuestPaths.Quest4Icon).node

    self.Quest1Over = QuestUi:Get(QuestPaths.Quest1Over).node
    self.Quest2Over = QuestUi:Get(QuestPaths.Quest2Over).node
    self.Quest3Over = QuestUi:Get(QuestPaths.Quest3Over).node
    self.Quest4Over = QuestUi:Get(QuestPaths.Quest4Over).node

    self.Quest1List = QuestUi:Get(QuestPaths.Quest1List, ViewList, function(child, childPath)
        local c = ViewComponent.New(child, QuestUi, childPath)
        return c
    end)
    self.Quest2List = QuestUi:Get(QuestPaths.Quest2List, ViewList, function(child, childPath)
        local c = ViewComponent.New(child, QuestUi, childPath)
        return c
    end)
    self.Quest3List = QuestUi:Get(QuestPaths.Quest3List, ViewList, function(child, childPath)
        local c = ViewComponent.New(child, QuestUi, childPath)
        return c
    end)
    self.Quest4List = QuestUi:Get(QuestPaths.Quest4List, ViewList, function(child, childPath)
        local c = ViewComponent.New(child, QuestUi, childPath)
        return c
    end)
end
return QuestGui