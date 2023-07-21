#!/usr/bin/luajit

local ucon = require 'uConsole'
local ffi = require 'ffi'
local argparse = require 'lib/argparse'

ffi.cdef [[
    int open(const char*, int flags);
    int close(int fd);
    int read(int fd, void* buf, size_t count);
]]

local O_NONBLOCK = 2048
local TTY = "/dev/tty"

local function key_reader()
    local buffer = ffi.new('uint8_t[?]', 1)
    local fd = ffi.C.open(TTY, O_NONBLOCK)
    return {
        read = function()
            local size = ffi.C.read(fd, buffer, 1)
            if size > 0 then
                return buffer[0]
            else
                return false
            end
        end,
        close = function()
            ffi.C.close(fd)
        end
    }
end

local HEADER = "runtime,clock,temp,throttled,voltage,capacity,current,backlight"
local EOL = "\n"

local function log_line(files, line)
    for _, file in ipairs(files) do
        file:write(line, EOL)
        file:flush()
    end
end

local function sleep(arg)
    os.execute("sleep " .. arg)
end

local function log_stats(interval, stdout, path, runtime)
    local files = {}

    if path then
        files[#files + 1] = assert(io.open(path, 'w'))
    end
    if stdout then
        files[#files + 1] = io.stdout
    end

    local concat = table.concat
    local time = os.time
    local enter = key_reader()
    local start = time()
    local elapsed
    io.stderr:write("uConStat start logging ... press ENTER to stop\n")
    log_line(files, HEADER)
    while true do
        elapsed = os.time() - start

        local stats = ucon.get_stats()
        log_line(files, concat({
            elapsed,
            stats.clock,
            stats.temp,
            stats.throttled,
            stats.voltage,
            stats.capacity,
            stats.current,
            stats.backlight
        }, ","))

        if enter.read() or (runtime and elapsed >= runtime) then
            break
        end

        sleep(interval)
    end
end

local parser = argparse("uConStat", "uConStat - a metrics logger for uConsole"):help_description_margin(30)
parser:option("--stdout", "log to standard output default, additional if output is set"):args("0")
parser:option("--output", "log to file <output>"):args("1")
parser:option("--runtime", "set runtime to <runtime> seconds"):args("1"):convert(tonumber)
parser:option("--interval", "set logging interval in seconds", "1", tonumber):args("1"):default(1):convert(tonumber)
parser:option("--backlight", "set backlight level [0-9]"):args("1"):convert(tonumber)

local args = parser:parse()
if (args.output == nil) then
    args.stdout = true
end

local old_backlight
if args.backlight ~= nil then
    old_backlight = ucon.get_backlight()
    ucon.set_backlight(args.backlight)
end

log_stats(args.interval, args.stdout, args.output, args.runtime)

if args.backlight ~= nil then
    ucon.set_backlight(old_backlight)
end
