local RPQuickSort = {}

RPQuickSort.UNIQUE_ID = "3542556795" -- unique identifier for this mod, used for saving settings

RPQuickSort.getTranslation = function(keyFragment)
    -- This function is a placeholder for translation logic
    -- In a real mod, you would implement this to return the translated string for the given key
    return getText("UI_" .. RPQuickSort.UNIQUE_ID .. "_" .. keyFragment)
end

RPQuickSort.MENU_ENTRY_QUICK_SORT = RPQuickSort.getTranslation("menu_entry_quick_sort")
RPQuickSort.MENU_ENTRY_QUICK_SORT_ALL = RPQuickSort.getTranslation("menu_entry_quick_sort_all")
RPQuickSort.MENU_ENTRY_QUICK_SORT_CATEGORY = "QUICK_SORT_CATEGORY"

-- Default values for mod settings
RPQuickSort.SORT_RANGE = 7
RPQuickSort.CATEGORY_BASED_TRANSFERS = true
RPQuickSort.STACK_COUNTS_AS_ONE = true
RPQuickSort.CATEGORY_ITEM_COUNT_THRESHOLD = 3
RPQuickSort.IGNORE_ITEM_CATEGORY = false
RPQuickSort.CATEGORY_ITEM_PERCENTAGE_THRESHOLD = 0.51
RPQuickSort.FOOD_OFF_AGE_THRESHOLD = 99999
RPQuickSort.SPECIAL_FOOD_TREATMENT = true
RPQuickSort.PLAYER_SAYS_ERRORS = true

-- Configuration for mod options using the new B42 system
RPQuickSort.initConfig = function()
    -- Create the options object with our mod's unique ID
    local options = PZAPI.ModOptions:create(RPQuickSort.UNIQUE_ID, RPQuickSort.getTranslation("mod_name"))

    -- General Settings
    options:addTitle(RPQuickSort.getTranslation("general_settings_header"))
    RPQuickSort.configSortRange = options:addSlider(
        "SORT_RANGE",
        RPQuickSort.getTranslation("sort_range_name"),
        3, 10, 1,
        RPQuickSort.SORT_RANGE,
        RPQuickSort.getTranslation("sort_range_tooltip")
    )

    RPQuickSort.configPlayerSaysErrors = options:addTickBox(
        "PLAYER_SAYS_ERRORS",
        RPQuickSort.getTranslation("player_says_errors_name"),
        RPQuickSort.PLAYER_SAYS_ERRORS,
        RPQuickSort.getTranslation("player_says_errors_tooltip")
    )

    options:addSeparator()

    -- Category Based Settings
    options:addTitle(RPQuickSort.getTranslation("category_based_settings_header"))

    RPQuickSort.configCategoryBasedTransfers = options:addTickBox(
        "CATEGORY_BASED_TRANSFERS",
        RPQuickSort.getTranslation("category_based_transfers_name"),
        RPQuickSort.CATEGORY_BASED_TRANSFERS,
        RPQuickSort.getTranslation("category_based_transfers_tooltip")
    )

    RPQuickSort.configStackCountsAsOne = options:addTickBox(
        "STACK_COUNTS_AS_ONE",
        RPQuickSort.getTranslation("stack_counts_as_one_name"),
        RPQuickSort.STACK_COUNTS_AS_ONE,
        RPQuickSort.getTranslation("stack_counts_as_one_tooltip")
    )

    RPQuickSort.configCategoryBasedTransfersForItem = options:addTickBox(
        "CATEGORY_BASED_TRANSFERS_FOR_ITEM",
        RPQuickSort.getTranslation("category_transfers_for_item_category_name"),
        false,
        RPQuickSort.getTranslation("category_transfers_for_item_category_tooltip")
    )

    RPQuickSort.configIgnoreItemCategory = options:addTickBox(
        "IGNORE_ITEM_CATEGORY",
        RPQuickSort.getTranslation("ignore_item_category_name"),
        RPQuickSort.IGNORE_ITEM_CATEGORY,
        RPQuickSort.getTranslation("ignore_item_category_tooltip")
    )

    options:addSeparator()

    -- Category Threshold Settings
    options:addTitle(RPQuickSort.getTranslation("category_threshold_settings_header"))

    -- Category Item Count Threshold
    RPQuickSort.configCategoryItemCountThreshold = options:addSlider(
        "CATEGORY_ITEM_COUNT_THRESHOLD",
        RPQuickSort.getTranslation("category_item_count_threshold_name"),
        1, 10, 1,
        RPQuickSort.CATEGORY_ITEM_COUNT_THRESHOLD,
        RPQuickSort.getTranslation("category_item_count_threshold_tooltip")
    )

    -- Category Item Percentage Threshold
    RPQuickSort.configCategoryItemPercentageThreshold = options:addSlider(
        "CATEGORY_ITEM_PERCENTAGE_THRESHOLD",
        RPQuickSort.getTranslation("category_item_percentage_threshold_name"),
        0.01, 1, 0.01,
        RPQuickSort.CATEGORY_ITEM_PERCENTAGE_THRESHOLD,
        RPQuickSort.getTranslation("category_item_percentage_threshold_tooltip")
    )

    options:addSeparator()

    -- Food Settings
    options:addTitle(RPQuickSort.getTranslation("food_settings_header"))

    RPQuickSort.configSpecialFoodTreatment = options:addTickBox(
        "SPECIAL_FOOD_TREATMENT",
        RPQuickSort.getTranslation("special_food_treatment_name"),
        RPQuickSort.SPECIAL_FOOD_TREATMENT,
        RPQuickSort.getTranslation("special_food_treatment_tooltip")
    )

    options.apply = function()
        RPQuickSort.updateSettingsFromModOptions()
    end

    Events.OnMainMenuEnter.Add(function()
        options.apply()
    end)
end

-- Function to update our variables based on the options
RPQuickSort.updateSettingsFromModOptions = function()
    local options = PZAPI.ModOptions:getOptions(RPQuickSort.UNIQUE_ID)
    if not options then return end
    -- Get Sort Range
    RPQuickSort.SORT_RANGE = options:getOption("SORT_RANGE"):getValue()

    -- Get Boolean settings
    RPQuickSort.CATEGORY_BASED_TRANSFERS = options:getOption("CATEGORY_BASED_TRANSFERS"):getValue()
    RPQuickSort.STACK_COUNTS_AS_ONE = options:getOption("STACK_COUNTS_AS_ONE"):getValue()
    RPQuickSort.CATEGORY_BASED_TRANSFERS_FOR_ITEM = options:getOption("CATEGORY_BASED_TRANSFERS_FOR_ITEM"):getValue()
    RPQuickSort.IGNORE_ITEM_CATEGORY = options:getOption("IGNORE_ITEM_CATEGORY"):getValue()
    RPQuickSort.SPECIAL_FOOD_TREATMENT = options:getOption("SPECIAL_FOOD_TREATMENT"):getValue()
    RPQuickSort.PLAYER_SAYS_ERRORS = options:getOption("PLAYER_SAYS_ERRORS"):getValue()

    -- Get Count Threshold
    RPQuickSort.CATEGORY_ITEM_COUNT_THRESHOLD = math.floor(options:getOption("CATEGORY_ITEM_COUNT_THRESHOLD"):getValue())

    -- Get Percentage Threshold
    RPQuickSort.CATEGORY_ITEM_PERCENTAGE_THRESHOLD = options:getOption("CATEGORY_ITEM_PERCENTAGE_THRESHOLD"):getValue()
end

-- Initialize mod options when the game starts
Events.OnGameStart.Add(function()
    RPQuickSort.updateSettingsFromModOptions()
end)

-- Initialize mod options when a save is loaded
Events.OnGameTimeLoaded.Add(function()
    RPQuickSort.updateSettingsFromModOptions()
end)

RPQuickSort.convertArrayList = function(arrayList)
    local itemTable = {}

    for i = 1, arrayList:size() do
        itemTable[i] = arrayList:get(i - 1)
    end

    return itemTable
end

-- credit to Michal Kottman for spairs https://stackoverflow.com/a/15706820
RPQuickSort.spairs = function(mTable, order)
    -- collect the keys
    local keys = {}
    for k in pairs(mTable) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys
    if order then
        table.sort(keys, function(a,b) return order(mTable, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], mTable[keys[i]]
        end
    end
end

RPQuickSort.createInventoryMenu = function(playerIndex, context, items)
    local player = getSpecificPlayer(playerIndex)

    -- return if more than one item is selected.. maybe change this
    if #items > 1 then
        return
    end

    local playerInventory = player:getInventory()

    local item

    -- Iterate through all clicked items
    for _, entry in ipairs(items) do
        local entry2

        if type(entry) == "table" then
            entry2 = entry['items'][1]
        else
            entry2 = entry
        end

        local isInventoryItem = instanceof(entry2, "InventoryItem")
        local isInPlayerInventory = false

        if playerInventory:contains(entry2) then
            isInPlayerInventory = true
        else
            local inventoryContainers = RPQuickSort.convertArrayList(playerInventory:getItemsFromCategory('Container'))

            for __, inventoryContainer in ipairs(inventoryContainers) do
                if inventoryContainer:getInventory():contains(entry2) then
                    isInPlayerInventory = true
                    break
                end
            end
        end

        local isFavorite = entry2:isFavorite()
        local isEquipped = player:isEquipped(entry2)

        if isInventoryItem and isInPlayerInventory and not isFavorite and not isEquipped then
            item = entry2
        end
    end

    if item then
        RPQuickSort.createInventoryObjectMenuEntry(player, playerIndex, context, item)
        return
    end
end

RPQuickSort.findTileAdjacentToContainer = function(player, destinationContainerSquare)
    local adjacentFreeTile = nil
    local currentPlayerSquare = player:getSquare()

    if AdjacentFreeTileFinder.isTileOrAdjacent(destinationContainerSquare, currentPlayerSquare) then
        adjacentFreeTile = currentPlayerSquare
    else
        adjacentFreeTile = AdjacentFreeTileFinder.Find(destinationContainerSquare, player)
    end

    return adjacentFreeTile
end

RPQuickSort.isTransferSetupComplete = function(transferData)
    -- return true or false
    if transferData['remainingToTransfer'] <= 0 then
        return true
    else
        return false
    end
end

RPQuickSort.initializeTransferData = function(player, sourceContainer, quickSortItemMap)
    local transferData = {
        sourceContainer = sourceContainer,
        remainingToTransfer = 0,
        totalToTransfer = 0,
        fullTransferWeight = 0,
        transfers = {},
        quickSortItemMap = quickSortItemMap,
        currentPlayerSquare = player:getCurrentSquare(),
    }

    transferData = RPQuickSort.calculateTransferWeightAndCount(quickSortItemMap, transferData)

    return transferData
end

RPQuickSort.calculateTransferWeightAndCount = function(quickSortItemMap, transferData)
    local fullTransferWeight = 0

    for _, quickSortInventoryItem in ipairs(quickSortItemMap) do
        fullTransferWeight = fullTransferWeight + quickSortInventoryItem['itemWeight']
    end

    transferData['fullTransferWeight'] = fullTransferWeight
    transferData['remainingToTransfer'] = #quickSortItemMap
    transferData['totalToTransfer'] = #quickSortItemMap

    return transferData
end

RPQuickSort.findContainerObjectsInRange = function(player)
    -- search for containers within 10 squares of the player on the same z level
    -- returns container objects
    local xrange = RPQuickSort.SORT_RANGE
    local yrange = RPQuickSort.SORT_RANGE
    local playerPosition = player:getCurrentSquare()
    local playerx = playerPosition:getX()
    local playery = playerPosition:getY()
    local playerz = playerPosition:getZ()
    local worldCell = getWorld():getCell()

    local destinationContainerObjects = {}

    for x=(playerx-xrange), (playerx+xrange) do
        for y=(playery-yrange), (playery+yrange) do
            local containerSearchSquare = worldCell:getGridSquare(x,y,playerz)
            if containerSearchSquare ~= nil then
                local possibleContainerObjects = containerSearchSquare:getObjects()

                for _, possibleContainerObject in ipairs(RPQuickSort.convertArrayList(possibleContainerObjects)) do
                    -- do any filtering of containers desired here, e.g. no zombies
                    if (possibleContainerObject:getContainer() ~= nil) and not possibleContainerObject:isZombie() and possibleContainerObject:getItemContainer():isExplored() then
                        destinationContainerObjects[#destinationContainerObjects + 1] = possibleContainerObject
                    end
                end
            end
        end
    end

    return destinationContainerObjects
end

RPQuickSort.calculateDistanceToContainer = function(player, destinationContainerObject)
    return math.sqrt(((player:getCurrentSquare():getX() - destinationContainerObject:getSquare():getX())^2) + ((player:getCurrentSquare():getY() - destinationContainerObject:getSquare():getY())^2))
end

RPQuickSort.foodItemIsPerishable = function(foodItem)
    local foodOffAgeMax = foodItem:getOffAgeMax()

    if foodItem:isRotten() or foodOffAgeMax > RPQuickSort.FOOD_OFF_AGE_THRESHOLD then
        return false
    else
        return true
    end
end

RPQuickSort.noTransfersToComplete = function(transferData)
    if #transferData['transfers'] == 0 then
        return true
    else
        return false
    end
end

RPQuickSort.createContainerReport = function(player, destinationContainer, destinationContainerObject)
    local contentsWeight = destinationContainer:getContentsWeight()
    local destinationContainerCapacity = destinationContainer:getCapacity()
    local containerItems = RPQuickSort.convertArrayList(destinationContainer:getItems())

    if #containerItems == 0 or contentsWeight == destinationContainerCapacity then
        -- container can't fit anything or has nothing in it, don't create a report for it
        return nil
    end

    local categoryToAmountMap = {}
    local typeToAmountMap = {}
    local categoryPercentageMap = {}
    local destinationContainerSquare = destinationContainerObject:getSquare()

    -- if RPQuickSort.STACK_COUNTS_AS_ONE is false, typeCollapsedItemCountForCategory should == #containerItem
    -- otherwise, it should be a smaller number representing the count of items in each category, but
    -- treats a stack of items with the same type as 1 item of that category. i.e. 200 cigarettes = 1 Food
    local typeCollapsedItemCountForCategory = 0

    -- track the number of categories so we can avoid some operations below if no eligible categories are found
    local numCategories = 0

    for _, containerItem in ipairs(containerItems) do
        local itemCategory = containerItem:getDisplayCategory()
        local itemType = containerItem:getType()
        local firstTimeEncounteringCategory = categoryToAmountMap[itemCategory] == nil
        local firstTimeEncounteringType = typeToAmountMap[itemType] == nil
        local shouldTrackThisCategory = itemCategory ~= "Item" or not RPQuickSort.IGNORE_ITEM_CATEGORY
        local shouldIncrementItemCountForCategory = firstTimeEncounteringType or not RPQuickSort.STACK_COUNTS_AS_ONE

        if shouldTrackThisCategory then
            if firstTimeEncounteringCategory then
                numCategories = numCategories + 1
                categoryToAmountMap[itemCategory] = 0
            end

            if shouldIncrementItemCountForCategory then
                typeCollapsedItemCountForCategory = typeCollapsedItemCountForCategory + 1
                categoryToAmountMap[itemCategory] = categoryToAmountMap[itemCategory] + 1
            end
        end

        if firstTimeEncounteringType then
            typeToAmountMap[itemType] = 0
        end

        typeToAmountMap[itemType] = typeToAmountMap[itemType] + 1
    end

    local eligibleForCategoryTransfer = #containerItems >= RPQuickSort.CATEGORY_ITEM_COUNT_THRESHOLD and numCategories >= 0
    -- skip doing math on the contents if it doesn't have enough items to be considered for category based transfers
    if eligibleForCategoryTransfer then
        for category, amount in pairs(categoryToAmountMap) do
            -- need to not divide by container items if stack counts as one
            -- category amounts should be correct now.. if stack counts as one then
            -- we need to add up all amounts from each category and divide against that
            categoryPercentageMap[category] = amount / typeCollapsedItemCountForCategory
        end
    end

    local containerType = destinationContainer:getType()
    local isFridge = containerType == "fridge"
    local isFreezer = containerType == "freezer"

    -- set a fake temperature depending on if fridge, freezer or neither so we can sort for the coldest container
    -- we do this because fridges and freezers technically have the same temperature right now
    -- if special food treatment is off, make fake temp the same for all containers so it doesn't affect sorting
    local fakeTemperature = 20

    if isFridge and RPQuickSort.SPECIAL_FOOD_TREATMENT then
        fakeTemperature = 0
    end

    if isFreezer and RPQuickSort.SPECIAL_FOOD_TREATMENT then
        fakeTemperature = -20
    end

    local containerReport = {
        isFridge = isFridge,
        isFreezer = isFreezer,
        fakeTemperature = fakeTemperature,
        totalItems = #containerItems,
        contentsWeight = contentsWeight,
        containerCapacity = destinationContainerCapacity,
        categoryPercentageMap = categoryPercentageMap,
        typeToAmountMap = typeToAmountMap,
        container = destinationContainer,
        containerObject = destinationContainerObject,
        containerSquare = destinationContainerSquare,
        distanceToContainer = RPQuickSort.calculateDistanceToContainer(player, destinationContainerObject),
        eligibleForCategoryTransfer = eligibleForCategoryTransfer,
        adjacentTile = nil,
    }

    return containerReport
end

RPQuickSort.createQuickSortItemReports = function(player, quickSortItems)
    local quickSortItemMap = {}
    local itemTypeSet = {}
    local itemCategorySet = {}

    for _, item in ipairs(quickSortItems) do
        local itemType = item:getType()

        if RPQuickSort.itemIsEligibleForQuickSort(player, item, itemType) then
            local itemCategory = item:getDisplayCategory()
            local isFood = item:IsFood() or itemCategory == "Food"

            itemTypeSet[itemType] = true
            itemCategorySet[itemCategory] = true

            local quickSortItemMapEntry = {
                itemType = itemType,
                itemCategory = itemCategory,
                itemWeight = item:getWeight(),
                itemContainer = item:getContainer(),
                isPerishable = isFood and RPQuickSort.foodItemIsPerishable(item),
                isFreezable = isFood and item:canBeFrozen(),
                item = item,
            }

            quickSortItemMap[#quickSortItemMap + 1] = quickSortItemMapEntry
        end
    end

    local quickSortItemReports = {
        quickSortItemMap = quickSortItemMap,
        itemTypeSet = itemTypeSet,
        itemCategorySet = itemCategorySet,
    }

    return quickSortItemReports
end

RPQuickSort.queueTransferActions = function(player, transferData)
    local playerInventory = player:getInventory()

    for _, transfer in RPQuickSort.spairs(transferData['transfers'], RPQuickSort.sortContainersForCategorySorting) do
        local adjacentTile = transfer['adjacentTile']
        local itemToTransfer = transfer['itemToTransfer']

        ISTimedActionQueue.add(ISWalkToTimedAction:new(player, getWorld():getCell():getGridSquare((adjacentTile:getX()), adjacentTile:getY(), adjacentTile:getZ())))

        if luautils.haveToBeTransfered(player, itemToTransfer) then
            ISTimedActionQueue.add(ISInventoryTransferAction:new(player, itemToTransfer, transferData['sourceContainer'], playerInventory))
        end

        ISTimedActionQueue.add(ISInventoryTransferAction:new(player, itemToTransfer, playerInventory, transfer['destinationContainer']))
    end
end

RPQuickSort.createTransfers = function(player, transferData, containerReports, quickSortItemReports)
    local transfers = {}

    for _, itemReport in ipairs(quickSortItemReports['quickSortItemMap']) do
        local eligibleContainers = RPQuickSort.findContainersThatCanReceiveItemsByType(player, itemReport, containerReports)

        -- find matches by type first
        if #eligibleContainers > 0 then
            local closestContainerWithRoom = nil

            for _, container in RPQuickSort.spairs(eligibleContainers, RPQuickSort.sortContainersForCategorySorting) do
                closestContainerWithRoom = container
                break
            end

            -- update the contentsWeight on the containerReport in case it runs out of room before the next transfer
            closestContainerWithRoom['contentsWeight'] = closestContainerWithRoom['contentsWeight'] + itemReport['itemWeight']

            local transfer = {
                destinationContainerObject = closestContainerWithRoom['containerObject'],
                destinationContainer = closestContainerWithRoom['container'],
                distanceToContainer = closestContainerWithRoom['distanceToContainer'],
                adjacentTile = closestContainerWithRoom['adjacentTile'],
                itemToTransfer = itemReport['item'],
            }

            transfers[#transfers + 1] = transfer
        else
            -- no matches by type, try category
            eligibleContainers = RPQuickSort.findContainersThatCanReceiveItemsByCategory(player, itemReport, containerReports)

            if #eligibleContainers > 0 then
                local closestContainerWithRoom = nil

                if itemReport['isFreezable'] then
                    for _, container in RPQuickSort.spairs(eligibleContainers, RPQuickSort.sortContainersForCategorySortingFreezables) do
                        closestContainerWithRoom = container
                        break
                    end
                else
                    for _, container in RPQuickSort.spairs(eligibleContainers, RPQuickSort.sortContainersForCategorySorting) do
                        closestContainerWithRoom = container
                        break
                    end
                end

                -- update the contentsWeight on the containerReport in case it runs out of room before the next transfer
                closestContainerWithRoom['contentsWeight'] = closestContainerWithRoom['contentsWeight'] + itemReport['itemWeight']

                local transfer = {
                    destinationContainerObject = closestContainerWithRoom['containerObject'],
                    destinationContainer = closestContainerWithRoom['container'],
                    distanceToContainer = closestContainerWithRoom['distanceToContainer'],
                    adjacentTile = closestContainerWithRoom['adjacentTile'],
                    itemToTransfer = itemReport['item'],
                }

                transfers[#transfers + 1] = transfer
            end
        end
    end

    transferData['transfers'] = transfers
    return transferData
end

RPQuickSort.sortContainersForCategorySorting = function(t, a, b)
    return t[a]['distanceToContainer'] < t[b]['distanceToContainer']
end

RPQuickSort.sortContainersForCategorySortingFreezables = function(t, a, b)
    return t[a]['fakeTemperature'] < t[b]['fakeTemperature'] or t[a]['distanceToContainer'] < t[b]['distanceToContainer']
end

RPQuickSort.findContainersThatCanReceiveItemsByCategory = function(player, itemReport, containerReports)
    local eligibleContainers = {}

    for _, containerReport in ipairs(containerReports) do
        -- disregard all food related stuff if special food treatment is off
        local isPerishable = RPQuickSort.SPECIAL_FOOD_TREATMENT and itemReport['isPerishable']
        local containerIsFridge =  RPQuickSort.SPECIAL_FOOD_TREATMENT and containerReport['isFridge']
        local containerIsFreezer =  RPQuickSort.SPECIAL_FOOD_TREATMENT and containerReport['isFreezer']

        if (not isPerishable and not containerIsFridge and not containerIsFreezer) or (isPerishable and (containerIsFridge or containerIsFreezer)) then
            local percentageOfCategoryInContainer = containerReport['categoryPercentageMap'][itemReport['itemCategory']]

            if percentageOfCategoryInContainer ~= nil and percentageOfCategoryInContainer >= RPQuickSort.CATEGORY_ITEM_PERCENTAGE_THRESHOLD and
            (RPQuickSort.CATEGORY_BASED_TRANSFERS_FOR_ITEM or itemReport['itemCategory'] ~= "Item") then
                local canFitItem = RPQuickSort.containerCanFitItem(itemReport, containerReport)

                if canFitItem then
                    local adjacentTile = containerReport['adjacentTile']

                    -- only store the adjacent tile for each container once
                    if adjacentTile == nil then
                        adjacentTile = RPQuickSort.findTileAdjacentToContainer(player, containerReport['containerSquare'])
                    end

                    if adjacentTile ~= nil then
                        containerReport['adjacentTile'] = adjacentTile
                        eligibleContainers[#eligibleContainers + 1] = containerReport
                    end
                end
            end
        end
    end

    return eligibleContainers
end

RPQuickSort.findContainersThatCanReceiveItemsByType = function(player, itemReport, containerReports)
    local eligibleContainers = {}

    for _, containerReport in ipairs(containerReports) do
        if containerReport['typeToAmountMap'][itemReport['itemType']] ~= nil then
            -- container has items with same type, check if it has room and can be reached
            local canFitItem = RPQuickSort.containerCanFitItem(itemReport, containerReport)

            if canFitItem then
                local adjacentTile = containerReport['adjacentTile']

                -- only store the adjacent tile for each container once
                if adjacentTile == nil then
                    adjacentTile = RPQuickSort.findTileAdjacentToContainer(player, containerReport['containerSquare'])
                end

                if adjacentTile ~= nil then
                    containerReport['adjacentTile'] = adjacentTile
                    eligibleContainers[#eligibleContainers + 1] = containerReport
                end
            end
        end
    end

    return eligibleContainers
end

RPQuickSort.containerCanFitItem = function(itemReport, containerReport)
    local itemWeight = itemReport['itemWeight']
    local containerContentsWeight = containerReport['contentsWeight']
    local containerCapacity = containerReport['containerCapacity']
    local availableSpace = containerCapacity - containerContentsWeight

    return itemWeight <= availableSpace
end

-- returns true if the itemType was found in the itemTypeSet on the container report
RPQuickSort.filterContainerReport = function(quickSortItemReports, destinationContainer)
    local sameItemFoundByType = false

    for itemType, _ in pairs(quickSortItemReports['itemTypeSet']) do
        local quickSortItemsInContainer = RPQuickSort.convertArrayList(destinationContainer:getItemsFromType(itemType))

        if #quickSortItemsInContainer > 0 then
            sameItemFoundByType = true
        end
    end

    return sameItemFoundByType
end

RPQuickSort.getItemsFromDisplayCategory = function(container, displayCategory)
    local items = container:getItems()
    local filteredItems = {}

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item:getDisplayCategory() == displayCategory then
            filteredItems[#filteredItems + 1] = item
        end
    end

    return filteredItems
end

RPQuickSort.onQuickSort = function(worlditems, player, quickSortItem, sortType)
    local quickSortItems

    if sortType == RPQuickSort.MENU_ENTRY_QUICK_SORT then
        local itemType = quickSortItem:getType()
        quickSortItems = RPQuickSort.convertArrayList(quickSortItem:getContainer():getItemsFromType(itemType))
    elseif sortType == RPQuickSort.MENU_ENTRY_QUICK_SORT_ALL then
        quickSortItems = RPQuickSort.convertArrayList(quickSortItem:getContainer():getItems())
    elseif sortType == RPQuickSort.MENU_ENTRY_QUICK_SORT_CATEGORY then
        quickSortItems = RPQuickSort.getItemsFromDisplayCategory(quickSortItem:getContainer(), quickSortItem:getDisplayCategory())
    end

    local destinationContainerObjects = RPQuickSort.findContainerObjectsInRange(player)

    if destinationContainerObjects == nil or #destinationContainerObjects == 0 then
        RPQuickSort.playerSay(player, RPQuickSort.getTranslation("player_error_no_containers"))
        return
    end

    local quickSortItemReports = RPQuickSort.createQuickSortItemReports(player, quickSortItems)

    if #quickSortItemReports['quickSortItemMap'] == 0 then
        RPQuickSort.playerSay(player, RPQuickSort.getTranslation("player_error_nothing_to_sort"))
        return
    end

    local sourceContainer = quickSortItemReports['quickSortItemMap'][1]['itemContainer']

    -- only items from the same container will be sorted, so grab the container from the first eligible item
    local transferData = RPQuickSort.initializeTransferData(player, sourceContainer, quickSortItemReports['quickSortItemMap'])
    local destinationContainerReports = {}

    -- lets create a map of the containers the same way we create a map of the items
    for _, destinationContainerObject in ipairs(destinationContainerObjects) do
        local destinationContainer = destinationContainerObject:getItemContainer()
        local containerType = destinationContainer:getType()
        local isFridge = containerType == "fridge"
        local freezerContainer = nil

        if isFridge then
            freezerContainer = destinationContainerObject:getContainerByType('freezer')

            if freezerContainer ~= nil then
                local freezerContainerReport = RPQuickSort.createContainerReport(player, freezerContainer, destinationContainerObject)
                local includeFreezerContainer = RPQuickSort.filterContainerReport(quickSortItemReports, freezerContainer)

                if freezerContainerReport ~= nil and (RPQuickSort.CATEGORY_BASED_TRANSFERS or includeFreezerContainer) then
                    destinationContainerReports[#destinationContainerReports + 1] = freezerContainerReport
                end
            end
        end

        local containerReport = RPQuickSort.createContainerReport(player, destinationContainer, destinationContainerObject)
        local sameItemFoundByType = false

        for itemType, _ in pairs(quickSortItemReports['itemTypeSet']) do
            local quickSortItemsInContainer = RPQuickSort.convertArrayList(destinationContainer:getItemsFromType(itemType))

            if #quickSortItemsInContainer > 0 then
                sameItemFoundByType = true
            end
        end

        if containerReport ~= nil and (RPQuickSort.CATEGORY_BASED_TRANSFERS or sameItemFoundByType) then
            destinationContainerReports[#destinationContainerReports + 1] = containerReport
        end
    end

    if #destinationContainerReports == 0 then
        RPQuickSort.playerSay(player, RPQuickSort.getTranslation("player_error_nowhere_to_put"))
        return
    end

    transferData = RPQuickSort.createTransfers(player, transferData, destinationContainerReports, quickSortItemReports)

    if RPQuickSort.noTransfersToComplete(transferData) then
        RPQuickSort.playerSay(player, RPQuickSort.getTranslation("player_error_no_transfers_to_complete"))
        return
    end

    RPQuickSort.queueTransferActions(player, transferData)
end

RPQuickSort.playerSay = function(player, message)
    if RPQuickSort.PLAYER_SAYS_ERRORS then
        player:Say(message)
    end
end

RPQuickSort.itemIsEligibleForQuickSort = function(player, quickSortItem, quickSortItemType)
    if not quickSortItem:isFavorite() and not player:isEquipped(quickSortItem) and quickSortItemType ~= "KeyRing" then
        return true
    end

    return false
end

RPQuickSort.createInventoryObjectMenuEntry = function(player, playerIndex, context, quickSortItem)
    local worlditems = nil

    -- quickSortItem is guaranteed to be a single item here
    local itemDisplayCategory = quickSortItem:getDisplayCategory()

    context:addOption(RPQuickSort.MENU_ENTRY_QUICK_SORT, worlditems, RPQuickSort.onQuickSort, player, quickSortItem, RPQuickSort.MENU_ENTRY_QUICK_SORT)
    context:addOption(RPQuickSort.MENU_ENTRY_QUICK_SORT_ALL, worlditems, RPQuickSort.onQuickSort, player, quickSortItem, RPQuickSort.MENU_ENTRY_QUICK_SORT_ALL)
    context:addOption(RPQuickSort.MENU_ENTRY_QUICK_SORT .. " <" .. itemDisplayCategory .. ">", worlditems, RPQuickSort.onQuickSort, player, quickSortItem, RPQuickSort.MENU_ENTRY_QUICK_SORT_CATEGORY)
end

-- Add context menu for Quick Sort
Events.OnPreFillInventoryObjectContextMenu.Add(RPQuickSort.createInventoryMenu)

RPQuickSort.initConfig()
