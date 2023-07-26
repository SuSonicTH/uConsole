#!/usr/bin/luajit

local table_insert = table.insert
local function split(str, sep)
    local ret = {}
    for item in string.gmatch(str, "([^" .. sep .. "]+)") do
        table_insert(ret, item)
    end
    return ret
end

local function readfile(filename)
    local file = assert(io.open(filename, "r"))
    local first = true
    local ret = {}
    local header
    for line in file:lines() do
        if (first) then
            first = false
            header = split(line, ",")
        else
            if line:sub(1, 1) ~= "#" then
                local row = {}
                ret[#ret + 1] = row
                for i, v in ipairs(split(line, ",")) do
                    row[header[i]] = tonumber(v)
                end
                row.watt = row.current / 1000 * row.voltage
            end
        end
    end
    return ret
end

local function sum(data, columns)
    columns = type(columns) == "table" and columns or { columns }
    local ret = {}
    for _, col in ipairs(columns) do
        ret[col] = {
            min = 10000000000,
            max = -10000000000,
            avg = 0,
            sum = 0,
            runtime = 0,
            values = {}
        }
    end
    for r, row in ipairs(data) do
        ret.runtime = row.runtime
        for _, col in ipairs(columns) do
            table.insert(ret[col].values, row[col])
            ret[col].sum = ret[col].sum + row[col]
            ret[col].min = math.min(ret[col].min, row[col])
            ret[col].max = math.max(ret[col].max, row[col])
        end
    end

    for _, col in ipairs(columns) do
        local count = #ret[col].values
        ret[col].avg = ret[col].sum / count
        table.sort(ret[col].values)
        if math.fmod(count, 2) == 0 then
            ret[col].median = (ret[col].values[count / 2] + ret[col].values[count / 2 + 1]) / 2
        else
            ret[col].median = ret[col].values[math.ceil(count / 2)]
        end
    end
    return ret
end

if #arg == 0 then
    io.stderr:write([[
    usage: sum.lua [filename1] [filename2] ... [filenameN]

]])
    os.exit(1)
end

for _, filename in ipairs(arg) do
    local stat = sum(readfile(filename), { 'clock', 'current', 'voltage', 'watt', })

    local data_name = filename:sub(-4, -1) == ".csv" and filename:sub(1, -5) or filename
    print(data_name)
    print(",average,min,max,median")
    for _, name in ipairs { 'clock', 'current', 'voltage', 'watt' } do
        print(table.concat({
            name,
            stat[name].avg, stat[name].min, stat[name].max, stat[name].median
        }, ","))
    end
    print("runtime," .. stat.runtime)
    print ""
end
