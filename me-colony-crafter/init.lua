local me = peripheral.find("meBridge")
local colony = peripheral.find("colonyIntegrator")
local stash = peripheral.find("minecolonies:stash")

local stash_items = {}

local function translate_item(item, count)
    return {
        name = item.name,
        count = count
    }
end

local tried_craft = {}

local function handle_request(request)
    if request.desc == "Smeltable Ore" then
        return
    end
    local craftable = {}
    local exportable = {}
    local exported = false
    for _, item in ipairs(request.items) do
        if stash_items[item.name] then
            print(item.name .. " still in stash")
            return false
        end
        local me_item = translate_item(item, request.count)
        if me.isItemCrafting(me_item) then
            print(item.name .. " is still crafting")
            tried_craft[me_item] = nil
            return false
        elseif me.getItem(me_item) ~= nil then
            --print(string.format("Found %s in storage", item.name))
            exportable[#exportable + 1] = me_item
        elseif me.isItemCraftable(me_item) then
            craftable[#craftable + 1] = me_item
        end
    end
    if #exportable > 0 then
        local item = exportable[1]
        print(string.format("Found %s in storage", item.name))
        tried_craft[item] = nil
        me.exportItem(item, "UP")
    elseif #craftable > 0 then
        if tried_craft[item] then
            print("Already tried crafting " .. item.name)
        end
        local item = craftable[1]
        print(string.format("%s is craftable, crafting", item.name))
        tried_craft[item] = true
        ok, msg = me.craftItem(item)
        if not ok then
            print(string.format("Failed to craft %s: %s", item.name, msg))
        end
    else
        print("Need " .. request.name .. " for " .. request.target)
    end
end

local seen = {}
local function main_loop()
    stash_items = {}
    for _, item in ipairs(stash.list()) do
        stash_items[item.name] = true
    end
    local requests = colony.getRequests()
    for _, request in ipairs(requests) do
        local first_seen = seen[request.id]
        print(request.desc, first_seen)
        if first_seen == nil then
            seen[request.id] = 0
        elseif first_seen < 10 then
            seen[request.id] = first_seen + 1
        else
            handle_request(request)
        end
    end
end

while true do
    main_loop()
    os.sleep(30)
end
