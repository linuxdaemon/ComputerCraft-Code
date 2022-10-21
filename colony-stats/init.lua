local colony = peripheral.find("colonyIntegrator")
local screen = peripheral.find("monitor")

local function tbl_append(tbl, item)
    tbl[#tbl + 1] = item
end

local function tbl_filter(tbl, filter)
    local t = {}
    for _, item in ipairs(tbl) do
        if filter(item) then
            tbl_append(t, item)
        end
    end
    return t
end

local function tbl_keys(tbl)
    local out = {}
    for k, _ in pairs(tbl) do
        tbl_append(out, k)
    end
    return out
end

local function tbl_map(tbl, func)
    local out = {}
    for i, v in pairs(tbl) do
        out[i] = func(v)
    end
    return out
end

local function tbl_sum(tbl)
    local n = 0
    for _, v in pairs(tbl) do
        n = n + v
    end
    return n
end

local function tbl_any(tbl, func)
    if func == nil then
        func = function(v) return v end
    end
    for _, v in ipairs(tbl) do
        if func(v) then
            return true
        end
    end
    return false
end

local function write_line(s, ...)
    screen.write(string.format(s, ...))
    local x, y = screen.getCursorPos()
    screen.setCursorPos(1, y + 1)
end

local function print_stats()
    local people = colony.getCitizens()
    table.sort(people, function(a, b) return a.happiness > b.happiness end)
    local buildings = colony.getBuildings()
    local ignore_types = {
        stash=true,
        postbox=true
    }
    local filtered_buildings = tbl_filter(buildings, function(b) return not ignore_types[b.type] end)
    screen.clear()
    screen.setCursorPos(1, 1)
    write_line("People: %d", #people)
    write_line("Buildings: %d", #filtered_buildings)
    local housing_total = 0
    local housing_used = 0
    local by_type = {}
    local guarded_buildings = 0

    for _, b in ipairs(filtered_buildings) do
        if b.guarded then
            guarded_buildings = guarded_buildings + 1
        end
        local bs = by_type[b.type]
        if bs == nil then
            bs = {}
            by_type[b.type] = bs
        end
        tbl_append(bs, b)
        if b.type == "citizen" then
            housing_total = housing_total + b.level
            housing_used = housing_used + #b.citizens
        end
    end

    write_line("Housing: %d/%d", housing_used, housing_total)
    write_line("Guarded buildings: %d", guarded_buildings)
    local guards = 0
    local no_job = 0
    local children = 0
    local is_child = false
    for _, p in ipairs(people) do
        if p.age ~= "adult" then
            children = children + 1
            is_child = true
        else
            is_child = false
        end
        local job
        if p.work ~= nil then
            job = p.work.type
        else
            job = nil
            if not is_child then
                no_job = no_job + 1
            end
        end
        if job == "guardtower" then
            guards = guards + 1
        end
    end
    write_line("Guards: %d", guards)
    write_line("Children: %d Unemployed: %d", children, no_job)
    local happiest = people[1]
    table.sort(people, function(a, b) return a.happiness < b.happiness end)
    local unhappiest = people[1]

    write_line("Unhappiest: %s (%.2f)", unhappiest.name, unhappiest.happiness)
    write_line("Happiest: %s (%.2f)", happiest.name, happiest.happiness)
    write_line("Levels:")
    local keys = tbl_keys(by_type)
    table.sort(keys)
    for _, k in ipairs(keys) do
        local bs = by_type[k]
        local in_progress = tbl_any(bs, function(v) return v.isWorkingOn end)
        local levels = tbl_map(bs, function(building) return building.level end)
        local n = tbl_sum(levels)
        local min_level = math.min(table.unpack(levels))
        local s
        if in_progress then
            s = "*"
        else
            s = ""
        end
        write_line("- %s%s = %d (min: %d)", s, k, n, min_level)
    end
end

while true do
    print_stats()
    os.sleep(5)
end
