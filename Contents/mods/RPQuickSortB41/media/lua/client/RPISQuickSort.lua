RPISQuickSort = {};

RPISQuickSort.MENU_ENTRY_QUICK_SORT = "Quick Sort";
RPISQuickSort.MENU_ENTRY_QUICK_SORT_ALL = "Quick Sort All Items";

RPISQuickSort.convertArrayList = function(arrayList)
    local itemTable = {};

    for i = 1, arrayList:size() do
        itemTable[i] = arrayList:get(i - 1);
    end

    return itemTable;
end

RPISQuickSort.createInventoryMenu = function(playerIndex, context, items)
    local player = getSpecificPlayer(playerIndex);

    -- return if more than one item is selected.. maybe change this
    if #items > 1 then
        return;
    end

    local playerInventory = player:getInventory();

    local item;
    local stack;

    -- Iterate through all clicked items
    for _, entry in ipairs(items) do
        local entry2;

        if type(entry) == "table" then
            entry2 = entry['items'][1];
        else
            entry2 = entry
        end

        local isInventoryItem = instanceof(entry2, "InventoryItem");
        local isInPlayerInventory = false;

        if playerInventory:contains(entry2) then
            isInPlayerInventory = true;
        else
            local inventoryContainers = RPISQuickSort.convertArrayList(playerInventory:getItemsFromCategory('Container'));

            for __, v in ipairs(inventoryContainers) do
                local inventoryContainer = v;

                if inventoryContainer:getInventory():contains(entry2) then
                    isInPlayerInventory = true;
                    break;
                end
            end
        end

        local isFavorite = entry2:isFavorite();
        local isEquipped = player:isEquipped(entry2);

        if isInventoryItem and isInPlayerInventory and not isFavorite and not isEquipped then
            item = entry2;
        end
    end

    if item then
        RPISQuickSort.createInventoryObjectMenuEntry(player, playerIndex, context, item);
        return;
    end
end

RPISQuickSort.findTileAdjacentToContainer = function(player, containerObjectSquare, transferData)
    local adjacentFreeTile = nil;

    if AdjacentFreeTileFinder.isTileOrAdjacent(containerObjectSquare, transferData['currentPlayerSquare'])  then
        adjacentFreeTile = transferData['currentPlayerSquare'];
    else
        adjacentFreeTile = AdjacentFreeTileFinder.Find(containerObjectSquare, player);
    end

    return adjacentFreeTile;
end

RPISQuickSort.createTransfer = function(player, transferData, containerObject, itemContainer, quickStackItemWeight)
    -- returns transfer data with the new transfer
    -- also returns true if transfer was created, false otherwise
    local transferCreated = false;
    local containerObjectSquare = containerObject:getSquare();
    local adjacentFreeTile = RPISQuickSort.findTileAdjacentToContainer(player, containerObjectSquare, transferData);

    if adjacentFreeTile ~= nil then
        local capacity = itemContainer:getCapacity();
        local contentsWeight = itemContainer:getContentsWeight();

        local availableSpace = capacity - contentsWeight;
        local numberOfItemsThatCanBeTransferred = math.floor(availableSpace / quickStackItemWeight);

        -- if we have more room than we need, set numberOfItemsThatCanBeTransferred = to the number of remaining items
        -- this could probably use a refactor
        if numberOfItemsThatCanBeTransferred > #transferData['nonFavoriteQuickStackItemsInInventory'] then
            numberOfItemsThatCanBeTransferred = transferData['remainingToTransfer'];
        end

        if numberOfItemsThatCanBeTransferred > 0 then
            local distanceToContainer = RPISQuickSort.calculateDistanceToContainer(player, containerObject);

            local transfer = {
                containerObject=containerObject,
                itemContainer=itemContainer,
                countToTransfer=numberOfItemsThatCanBeTransferred,
                distanceToContainer=distanceToContainer,
                adjacentFreeTile = adjacentFreeTile
            };

            transferData['transfers'][#transferData['transfers'] + 1] = transfer;
            transferData['remainingToTransfer'] = transferData['remainingToTransfer'] - numberOfItemsThatCanBeTransferred;
            transferCreated = true;
        end
    end

    return transferData, transferCreated;
end

RPISQuickSort.isTransferSetupComplete = function(transferData)
    -- return true or false
    if transferData['remainingToTransfer'] <= 0 then
        return true;
    else
        return false;
    end
end

RPISQuickSort.initializeTransferData = function(player, quickStackInventoryItems, quickStackItemType)
    local transferData = {
        remainingToTransfer = 0,
        fullTransferWeight = 0,
        transfers = {},
        nonFavoriteQuickStackItemsInInventory = {},
        quickStackItemType = quickStackItemType,
        currentPlayerSquare = player:getCurrentSquare()
    };

    transferData = RPISQuickSort.calculateTransferWeightAndCount(player, quickStackInventoryItems, transferData);

    return transferData;
end

RPISQuickSort.calculateTransferWeightAndCount = function(player, quickStackInventoryItems, transferData)
    local fullTransferWeight = 0;
    local nonFavoriteQuickStackItemsInInventory = {};

    for _,v in ipairs(quickStackInventoryItems) do
        if not v:isFavorite() and not player:isEquipped(v) then
            fullTransferWeight = fullTransferWeight + v:getWeight();
            nonFavoriteQuickStackItemsInInventory[#nonFavoriteQuickStackItemsInInventory + 1] = v;
        end
    end

    transferData['fullTransferWeight'] = fullTransferWeight;
    transferData['remainingToTransfer'] = #nonFavoriteQuickStackItemsInInventory;
    transferData['nonFavoriteQuickStackItemsInInventory'] = nonFavoriteQuickStackItemsInInventory;

    return transferData;
end

RPISQuickSort.findContainerObjectsInRange = function(player)
    -- search for containers within 10 squares of the player on the same z level
    -- returns container objects
    local xrange = 10;
    local yrange = 10;
    local playerPosition = player:getCurrentSquare();
    local playerx = playerPosition:getX();
    local playery = playerPosition:getY();
    local playerz = playerPosition:getZ();
    local worldCell = getWorld():getCell();

    local containerObjects = {};

    for x=(playerx-xrange), (playerx+xrange) do
        for y=(playery-yrange), (playery+yrange) do
            local containerSearchSquare = worldCell:getGridSquare(x,y,playerz);
            if containerSearchSquare ~= nil then
                local possibleContainerObjects = containerSearchSquare:getObjects();

                for _, possibleContainerObject in ipairs(RPISQuickSort.convertArrayList(possibleContainerObjects)) do
                    -- do any filtering of containers desired here, e.g. no zombies
                    if (possibleContainerObject:getContainer() ~= nil) and not possibleContainerObject:isZombie() and possibleContainerObject:getItemContainer():isExplored() then
                        containerObjects[#containerObjects + 1] = possibleContainerObject;
                    end
                end
            end
        end
    end

    return containerObjects;
end

RPISQuickSort.calculateDistanceToContainer = function(player, containerObject)
    return math.sqrt(((player:getCurrentSquare():getX() - containerObject:getSquare():getX())^2) + ((player:getCurrentSquare():getY() - containerObject:getSquare():getY())^2))
end

RPISQuickSort.containerHasMajorityCategory = function(itemContainer, countOfItemsMatchingCategoryInContainer)
    local totalItemCountInContainer = itemContainer:getItems():size();

    if (countOfItemsMatchingCategoryInContainer / totalItemCountInContainer) >= 0.5 then
        return true;
    else
        return false
    end
end

RPISQuickSort.foodItemIsParishable = function(foodItem)
    local foodOffAgeMax = foodItem:getOffAgeMax();

    if foodOffAgeMax > 99999 then
        return false;
    else
        return true;
    end
end

RPISQuickSort.sortTransfersByDistance = function(transferData)
    local sortedTransfers = table.sort(transferData['transfers'], function(a,b) return a['distanceToContainer'] < b['distanceToContainer'] end);

    transferData['transfers'] = sortedTransfers;

    return transferData;
end

RPISQuickSort.noTransfersToComplete = function(transferData)
    if #transferData['transfers'] == 0 then
        return true;
    else
        return false;
    end
end

RPISQuickSort.onQuickStackAllItems = function(worlditems, player)
    local inventoryItems = RPISQuickSort.convertArrayList(player:getInventory():getItems());
    local sortAllEligibleItems = RPISQuickSort.getInventoryItemsEligibleForSortAll(inventoryItems, player);

    if #sortAllEligibleItems == 0 then
        player:Say("I don't want to sort any of this stuff.");
        return;
    end

    for _, inventoryItem in ipairs(sortAllEligibleItems) do
        RPISQuickSort.onQuickStackThisItem(worlditems, player, inventoryItem);
    end
end

RPISQuickSort.getInventoryItemsEligibleForSortAll = function(inventoryItems, player)
    local sortAllEligibleItems = {};

    for _, inventoryItem in ipairs(inventoryItems) do
        local inventoryItemType = inventoryItem:getType();

        if RPISQuickSort.itemIsEligibleForQuickSortAll(player, inventoryItem, inventoryItemType) then
            sortAllEligibleItems[#sortAllEligibleItems + 1] = inventoryItem;
        end
    end

    return sortAllEligibleItems;
end

RPISQuickSort.onQuickStackThisItem = function(worlditems, player, quickStackItem)
    local containerObjects = RPISQuickSort.findContainerObjectsInRange(player);

    if #containerObjects == 0 then
        player:Say("I don't see any containers around.");
        return;
    end

    local quickStackItemType = quickStackItem:getType();
    local quickStackItemWeight = quickStackItem:getWeight();
    local quickStackItemCategory = quickStackItem:getCategory();


    local quickStackInventoryItems = RPISQuickSort.convertArrayList(quickStackItem:getContainer():getItemsFromType(quickStackItemType));

    local transferData = RPISQuickSort.initializeTransferData(player, quickStackInventoryItems, quickStackItemType);

    for _, containerObject in ipairs(containerObjects) do
        local itemContainer = containerObject:getItemContainer();
        local quickStackItemsInContainer = RPISQuickSort.convertArrayList(itemContainer:getItemsFromType(quickStackItemType));

        if #quickStackItemsInContainer > 0 then
            transferData = RPISQuickSort.createTransfer(player, transferData, containerObject, itemContainer, quickStackItemWeight);
        end

        if RPISQuickSort.isTransferSetupComplete(transferData) then
            break;
        end
    end

    if RPISQuickSort.noTransfersToComplete(transferData) then
        -- was unable to find transfers based on exact type match alone. check for a "theme" in nearby containers based on contents categories
        local isPerishableFood = false;
        local isFreezableFood = false;

        if quickStackItemCategory == "Food" then
            isPerishableFood = RPISQuickSort.foodItemIsParishable(quickStackItem);
            isFreezableFood = quickStackItem:canBeFrozen();
        end

        for _, containerObject in ipairs(containerObjects) do
            local itemContainer = containerObject:getItemContainer();
            local containerType = itemContainer:getType();
            local isFridge = containerType == "fridge";
            local transferCompleted = false;

            -- don't try to store non-parishables in the fridge or parishables in a cupboard with a category based transfer
            if not isPerishableFood then
                if not isFridge then
                    transferData, transferCompleted = RPISQuickSort.handleCategoryTransfer(player, containerObject, itemContainer, transferData, quickStackItemWeight, quickStackItemCategory);

                    if transferCompleted then
                        break;
                    end
                end
            else
                if isFridge then
                    local mainFridgeContainer = containerObject:getContainerByType('fridge');
                    local freezerContainer = containerObject:getContainerByType('freezer');

                    -- if freezable, try freezer first and fridge second. otherwise, try fridge first and freezer second.
                    if isFreezableFood then
                        transferData, transferCompleted = RPISQuickSort.handleCategoryTransfer(player, containerObject, freezerContainer, transferData, quickStackItemWeight, quickStackItemCategory);

                        if transferCompleted then
                            break;
                        end

                        transferData, transferCompleted = RPISQuickSort.handleCategoryTransfer(player, containerObject, mainFridgeContainer, transferData, quickStackItemWeight, quickStackItemCategory);

                        if transferCompleted then
                            break;
                        end
                    else
                        transferData, transferCompleted = RPISQuickSort.handleCategoryTransfer(player, containerObject, mainFridgeContainer, transferData, quickStackItemWeight, quickStackItemCategory);

                        if transferCompleted then
                            break;
                        end

                        transferData, transferCompleted = RPISQuickSort.handleCategoryTransfer(player, containerObject, freezerContainer, transferData, quickStackItemWeight, quickStackItemCategory);

                        if transferCompleted then
                            break;
                        end
                    end
                end
            end
        end
    end

    if RPISQuickSort.noTransfersToComplete(transferData) then
        player:Say("I'm not sure where to put " .. quickStackItem:getDisplayName() .. ".");
        return;
    end

    -- sort transfers so the closest transfers occur first
    transferData = RPISQuickSort.sortTransfersByDistance(transferData);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        

    RPISQuickSort.queueTransferActions(player, transferData);
end

RPISQuickSort.itemIsEligibleForQuickSortAll = function(player, quickStackItem, quickStackItemType)
    if not quickStackItem:isFavorite() and not player:isEquipped(quickStackItem) and quickStackItemType ~= "KeyRing" then
        return true;
    else
        return false;
    end
end

RPISQuickSort.handleCategoryTransfer = function(player, containerObject, containerToCheck, transferData, quickStackItemWeight, quickStackItemCategory)
    local transferComplete = false;

    if containerToCheck ~= nil then
        local countOfItemsMatchingCategoryInContainer = #RPISQuickSort.convertArrayList(containerToCheck:getItemsFromCategory(quickStackItemCategory));

        if countOfItemsMatchingCategoryInContainer > 0 then
            -- items with category match found, check how much the category is present
            if RPISQuickSort.containerHasMajorityCategory(containerToCheck, countOfItemsMatchingCategoryInContainer) then
                -- container has more than 50% items in this category, sort it here if possible
                transferData = RPISQuickSort.createTransfer(player, transferData, containerObject, containerToCheck, quickStackItemWeight);
            end
        end

        if RPISQuickSort.isTransferSetupComplete(transferData) then
            transferComplete = true;
        end
    end

    return transferData, transferComplete;
end

RPISQuickSort.queueTransferActions = function(player, transferData)
    local countOfTransferActionsQueued = 0;
    local indexMod = 1;

    for _, transfer in ipairs(transferData['transfers']) do
        local adjacentFreeTile = transfer['adjacentFreeTile'];

        ISTimedActionQueue.add(ISWalkToTimedAction:new(player, getWorld():getCell():getGridSquare((adjacentFreeTile:getX()), adjacentFreeTile:getY(), adjacentFreeTile:getZ())));

        for itemIndex = indexMod, (transfer['countToTransfer'] + countOfTransferActionsQueued) do
            local itemToTransfer = transferData['nonFavoriteQuickStackItemsInInventory'][itemIndex];

            if luautils.haveToBeTransfered(player, itemToTransfer) then
                ISTimedActionQueue.add(RPQuickSortAction:new(player, itemToTransfer, itemToTransfer:getContainer(), player:getInventory()));
            end

            ISTimedActionQueue.add(RPQuickSortAction:new(player, itemToTransfer, player:getInventory(), transfer['itemContainer']));

            countOfTransferActionsQueued = countOfTransferActionsQueued + 1;
        end

        indexMod = indexMod + transfer['countToTransfer'];
    end
end

RPISQuickSort.createInventoryObjectMenuEntry = function(player, playerIndex, context, quickStackItem)
    local worlditems = nil;

    context:addOption(RPISQuickSort.MENU_ENTRY_QUICK_SORT, worlditems, RPISQuickSort.onQuickStackThisItem, player, quickStackItem);
    context:addOption(RPISQuickSort.MENU_ENTRY_QUICK_SORT_ALL, worlditems, RPISQuickSort.onQuickStackAllItems, player);
end

RPQuickSortAction = ISInventoryTransferAction:derive("RPQuickSortAction");

function RPQuickSortAction:update()
    if self.character ~= nil and self.destContainer ~= nil and instanceof(self.destContainer, "ItemContainer") then
        if self.destContainer:getParent() ~= nil and self.destContainer:getParent():getX() ~= nil then
            self.character:faceLocation(self.destContainer:getParent():getX(), self.destContainer:getParent():getY());
        end
    end

    ISInventoryTransferAction.update(self);
end

Events.OnPreFillInventoryObjectContextMenu.Add(RPISQuickSort.createInventoryMenu);
