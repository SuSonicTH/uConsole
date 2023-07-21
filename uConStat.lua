#!/usr/bin/luajit

local ucon = require('uconsole')
local ffi = require 'ffi'

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
    io.stderr:write("uConStat logging ... press ENTER to stop\n")
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

        if enter.read() or (runtime > 1 and elapsed >= runtime) then
            break
        end

        sleep(interval)
    end
end

local function printhelp(error)
    io.stderr:write [[
uConStat v0.1
a metrics logger for uConsole

usage: uconstat.lua [options]

options:
        --output <filename>  output to file named <filename>
        --stdout             print to console
        --time <seconds>     run for <seconds> and exit
        --interval <seconds> logging interval in seconds (defaults to 1)

]]

    if error then
        io.stderr:write("Error: ", error, "\n\n")
        os.exit(1)
    end
    os.exit(0)
end

local output
local stdout = false
local runtime
local i = 1
local interval = 1

while i <= #arg do
    if arg[i] == '--help' then
        printhelp()
    elseif arg[i] == '--stdout' then
        stdout = true
    elseif arg[i] == '--output' then
        if i == #arg or arg[i + 1]:sub(1, 2) == "--" then
            printhelp("argument --output needs a filename as argument")
        end
        output = arg[i + i]
        i = i + 1
    elseif arg[i] == '--time' then
        print("intime")
        if i == #arg or arg[i + 1]:sub(1, 2) == "--" then
            printhelp("argument --time needs seconds as argument")
        end
        print(runtime)
        runtime = tonumber(arg[i + i])
        print(runtime)
        i = i + 1
    elseif arg[i] == '--interval' then
        if i == #arg or arg[i + 1]:sub(1, 2) == "--" then
            printhelp("argument --interval needs seconds as argument")
        end
        interval = tonumber(arg[i + i])
        i = i + 1
    else
        printhelp("unknown argument '" .. arg[i])
    end
    i = i + 1
end

if output == nil and not stdout then
    printhelp("at least one of --output or --stdout has to be given")
end

log_stats(interval, stdout, output, runtime)
