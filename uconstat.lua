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

local function log_stats(interval, stdout, path)
    local files = {}

    if path then
        files[#files + 1] = assert(io.open(path, 'w'))
    end
    if stdout then
        files[#files + 1] = io.stdout
    end

    local concat = table.concat
    local time = os.time
    local key = key_reader()
    local start = time()
    io.stderr:write("Press ENTER to stop\n")
    log_line(files, HEADER)
    while not key.read() do
        local stats = ucon.get_stats()
        log_line(files, concat({
            os.time() - start,
            stats.clock,
            stats.temp,
            stats.throttled,
            stats.voltage,
            stats.capacity,
            stats.current,
            stats.backlight
        }, ","))
        sleep(interval)
    end
end

log_stats(1, true)
