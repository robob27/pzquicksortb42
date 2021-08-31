local Commands = {};
local RPQuickSort = {};

-- sendClientCommand sends a message to the server from the client
-- sendServerCommand sends a message to the client from the server

RPQuickSort.OnClientCommand = function(module, command, player, args)
    if not isServer() then return end
    if module ~= 'RPQuickSortB41' then return end
    if Commands[command] then
        Commands[command](player, args);
    end
end

RPQuickSort.OnServerCommand = function(module, command, args)
    if not isClient() then return end
    if module ~= 'RPQuickSortB41' then return end
    if Commands[command] then
        Commands[command](args);
    end
end

Events.OnServerCommand.Add(RPQuickSort.OnServerCommand);

if isServer() then
    Events.OnClientCommand.Add(RPQuickSort.OnClientCommand);
end
