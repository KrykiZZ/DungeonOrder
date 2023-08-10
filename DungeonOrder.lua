DungeonOrder = {
    name = "DungeonOrder"
}

function DungeonOrder.RefreshView(self)
    if not self.fragment:IsShowing() then
        return
    end

    local shouldShowLFMPrompt = self:GetLFMPromptInfo()
    if not shouldShowLFMPrompt then
        self:ResetLFMPrompt()
    end

    self.tributeSeasonProgressControl:SetHidden(true)
    self.clubRankObject:Refresh()

    local lockReasonText
    
    self.viewRewardsButton:SetHidden(true)
    self.acceptQuestButton:SetHidden(true)
    self.unlockPermanentlyButton:SetHidden(true)
    self.chapterUpgradeButton:SetHidden(true)

    local selectedData = self.filterComboBox:GetSelectedItemData()
    if selectedData then
        local filterData = selectedData.data
        if filterData.singular then
            ZO_ACTIVITY_FINDER_ROOT_MANAGER:SetLocationSelected(filterData, true)
            self:RefreshRewards(filterData)
            if filterData:IsLocked() then
                lockReasonText = filterData:GetLockReasonText()

                local lockingCollectibleId = filterData:GetFirstLockingCollectible()
                if lockingCollectibleId ~= 0 then
                    local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(lockingCollectibleId)
                    local categoryType = collectibleData:GetCategoryType()
                    if categoryType == COLLECTIBLE_CATEGORY_TYPE_CHAPTER then
                        self.chapterUpgradeButton:SetHidden(false)
                    elseif categoryType == COLLECTIBLE_CATEGORY_TYPE_DLC then
                        self.unlockPermanentlyButton.searchTerm = collectibleData:GetName()
                        self.unlockPermanentlyButton:SetHidden(false)
                    end
                else
                    self.acceptQuestButton.questId = filterData:GetQuestToUnlock()
                    self.acceptQuestButton:SetHidden(self.acceptQuestButton.questId == 0)
                end
            end

            local HIDE_IF_NOT_COMPETITIVE = not filterData.isCompetitive
            self:RefreshTributeSeasonData(HIDE_IF_NOT_COMPETITIVE)

            self.viewRewardsButton:SetHidden(HIDE_IF_NOT_COMPETITIVE)
        else
            self.navigationTree:Reset()

            ZO_ACTIVITY_FINDER_ROOT_MANAGER:RebuildSelections(filterData.activityTypes)

            local modes = self.dataManager:GetFilterModeData()

            local NO_PARENT_NODE = nil
            local NO_OVERRIDE_SOUND = nil
            local HEADER_OPEN = true
            for _, activityType in ipairs(filterData.activityTypes) do
                if ZO_ACTIVITY_FINDER_ROOT_MANAGER:GetNumLocationsByActivity(activityType, modes:GetVisibleEntryTypes()) > 0 then
                    local isLocked = self:GetLevelLockInfoByActivity(activityType)
                    if not isLocked then
                        local locationData = ZO_ACTIVITY_FINDER_ROOT_MANAGER:GetLocationsData(activityType)
                        local headerText = GetString("SI_LFGACTIVITY", activityType)
                        local headerNode = self.navigationTree:AddNode("ZO_ActivityFinderTemplateNavigationHeader_Keyboard", headerText, NO_PARENT_NODE, NO_OVERRIDE_SOUND, HEADER_OPEN)

                        local function sort_alphabetical(a, b)
                            return a.rawName < b.rawName
                        end

                        table.sort(locationData, sort_alphabetical)

                        for _, location in ipairs(locationData) do
                            if modes:IsEntryTypeVisible(location:GetEntryType()) and location:IsActive() and not location:ShouldForceFullPanelKeyboard() then
                                self.navigationTree:AddNode("ZO_ActivityFinderTemplateNavigationEntry_Keyboard", location, headerNode)
                            end
                        end
                    end
                end
            end

            self.navigationTree:Commit()
        end
    end

    local globalLockReasonText = self:GetGlobalLockText()

    if globalLockReasonText then
        lockReasonText = globalLockReasonText
    end

    self.shouldHideLockReason = lockReasonText == nil

    if not self.shouldHideLockReason then
        --if the text is a function, that means there's a timer involved that we want to refresh on update
        if type(lockReasonText) == "function" then
            self.lockReasonTextFunction = lockReasonText
        else
            self.lockReasonLabel:SetText(zo_iconTextFormat("EsoUI/Art/Miscellaneous/locked_disabled.dds", 16, 16, lockReasonText))
            self.lockReasonTextFunction = nil
        end
    end

    self.lockReasonLabel:SetHidden(self.shouldHideLockReason)

    self:RefreshButtons()
end

function DungeonOrder.OnAddOnLoaded(event, addonName)
    if addonName ~= DungeonOrder.name then return end

    ZO_ActivityFinderTemplate_Keyboard.RefreshView = DungeonOrder.RefreshView
    EVENT_MANAGER:UnregisterForEvent(DungeonOrder.name, EVENT_ADD_ON_LOADED)
end

EVENT_MANAGER:RegisterForEvent(DungeonOrder.name, EVENT_ADD_ON_LOADED, DungeonOrder.OnAddOnLoaded)