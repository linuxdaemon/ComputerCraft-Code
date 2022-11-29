local me = peripheral.find("meBridge")
local colony = peripheral.find("colonyIntegrator")
local stash = peripheral.find("minecolonies:stash")

local stash_items = {}

local function load_allowed_items()
    local out = {}
    local fname = "allowed_items.cfg"
    if not fs.exists(fname) then
        local f = io.open(fname, "w")
        f:write("")
        f:close()
    end
    local f = io.open(fname, "r")
    for line in f:lines() do
        if line and #line > 0 then
            out[line] = true
        end
    end
    return out
end

local allowed = load_allowed_items()

local function add_maybe_allow(item)
    if allowed[item] or allowed['# ' .. item] then
        return
    end
    local f = io.open("allowed_items.cfg", "a+")
    f:write("# " .. item .. "\n")
    f:close()
end

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
        if not allowed[item.name] then
            add_maybe_allow(item.name)
            print(item.name, " not allowed")
            return false
        end
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
        return true
    elseif #craftable > 0 then
        if tried_craft[item] then
            print("Already tried crafting " .. item.name)
        end
        local item = craftable[1]
        print(string.format("%s is craftable, crafting", item.name))
        tried_craft[item] = true
        local ok, msg = me.craftItem(item)
        if not ok then
            print(string.format("Failed to craft %s: %s", item.name, msg))
        end
        return false
    else
        print("Need " .. request.name .. " for " .. request.target)
        return false
    end
end

local seen = {}
local function main_loop()
    stash_items = {}
    allowed = load_allowed_items()
    for _, item in ipairs(stash.list()) do
        stash_items[item.name] = true
    end
    local requests = colony.getRequests()
    for _, request in ipairs(requests) do
        local first_seen = seen[request.id]
        -- print(request.desc, first_seen)
        -- if first_seen == nil then
        --     seen[request.id] = 0
        -- elseif first_seen < 5 then
        --     seen[request.id] = first_seen + 1
        -- else
            if handle_request(request) then
                seen[request.id] = nil
            end
        -- end
    end
end

while true do
    main_loop()
    os.sleep(30)
end
