local function capture(cmd)
  local proc = assert(io.popen(cmd, 'r'))
  local str = assert(proc:read('*a'))
  proc:close()
  return str
end

local function read(path)
  local file = assert(io.open(path, 'r'))
  local str = assert(file:read('*l'))
  file:close()
  return str
end

local function write(path, arg)
  local file = assert(io.open(path, 'w'))
  assert(file:write(arg))
  file:close()
end

local function sleep(arg)
  os.execute("sleep " .. arg)
end

local function get_clock()
  local _, _, value = capture("vcgencmd measure_clock arm"):find(".+=(%d+)")
  return value / 1000000
end

local function get_temp()
  local _, _, value = capture("vcgencmd measure_temp"):find(".+=(%d+%.?%d*)")
  return value
end

local function get_throttled()
  local _, _, value = capture("vcgencmd get_throttled"):find(".+=(%d+%.?%d*)")
  value = tonumber(value, 16)
  return value
end

local function get_voltage()
  return tonumber(read("/sys/class/power_supply/axp20x-battery/voltage_now")) / 1000000
end

local function get_capacity()
  return tonumber(read("/sys/class/power_supply/axp20x-battery/capacity"))
end

local function get_current()
  return tonumber(read("/sys/class/power_supply/axp20x-battery/current_now")) / 1000
end

local function get_backlight()
  return tonumber(read("/sys/class/backlight/backlight@0/brightness"))
end

local function set_backlight(arg)
  assert(type(arg) == "number")
  return write("/sys/class/backlight/backlight@0/brightness", arg)
end

local function get_stats()
  return {
    clock = get_clock(),
    temp = get_temp(),
    throttled = get_throttled(),
    voltage = get_voltage(),
    capacity = get_capacity(),
    current = get_current(),
    backlight = get_backlight(),
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

local function log_stats(interval, stdout, path)
  local files = {}

  if path then
    files[#files + 1] = assert(io.open(path, 'w'))
  end
  if stdout then
    files[#files + 1] = io.stdout
  end
  log_line(files, HEADER)

  local concat = table.concat
  local time = os.time

  local start = time()
  while true do
    log_line(files, concat({
      os.time() - start,
      get_clock(),
      get_temp(),
      get_throttled(),
      get_voltage(),
      get_capacity(),
      get_current(),
      get_backlight()
    }, ","))
    sleep(interval)
  end
end
log_stats(5, true, "tst1.txt")

return {
  capture = capture,
  read = read,
  sleep = sleep,
  get_clock = get_clock,
  get_temp = get_temp,
  get_throttled = get_throttled,
  get_voltage = get_voltage,
  get_capacity = get_capacity,
  get_current = get_current,
  get_backlight = get_backlight,
  set_backlight = set_backlight,
  get_stats = get_stats,
  log_stats = log_stats,
}
