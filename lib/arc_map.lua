-- Arcwise mod
-- arc param mapper
-- based on norns pmap

local amap = {
  data = {},
  rev = {}
}

amap.__index = amap

function amap.new(id)
  local a = setmetatable({}, amap)
  a.ring = 1
  a.page = 1
  a.out_lo = 0
  a.out_hi = 1
  a.slide = 0
  a.scale = 1
  amap.data[id] = a
end

function amap.remove(id)
  local a = amap.data[id]
  if a then amap.rev[a.page][a.ring] = nil end
  amap.data[id] = nil
end

function amap.assign(id, page, ring)
  local prev = amap.rev[page][ring]
  if prev and prev ~= id then
    amap.remove(id)
  end
  local a = amap.data[id]
  amap.rev[a.page][a.ring] = nil
  a.page = page
  a.ring = ring
  amap.rev[page][ring] = id
end

function amap.refresh()
  for k, v in pairs(amap.data) do
    amap.rev[v.page][v.ring] = k
  end
end

function amap.clear()
  amap.data = {}
  amap.rev = {}
  for i = 1, 16 do
    amap.rev[i] = {}
  end
end

function amap.write()
  local function quote(s)
    return '"' .. s:gsub('"', '\\"') .. '"'
  end
  local filename = norns.state.data .. norns.state.shortname .. ".amap"
  print(">> saving AMAP " .. filename)
  local fd = io.open(filename, "w+")
  io.output(fd)
  local line = ""
  for k, v in pairs(amap.data) do
    line = string.format('%s:"{', quote(tostring(k)))
    for x, y in pairs(v) do
      line = line .. x .. "=" .. tostring(y) .. ", "
    end
    line = line:sub(1, -3) .. '}"\n'
    io.write(line)
    line = ""
  end
  io.close(fd)
end

function amap.read()
  local function unquote(s)
    return s:gsub('^"', ''):gsub('"$', ''):gsub('\\"', '"')
  end
  local filename = norns.state.data .. norns.state.shortname .. ".amap"
  print(">> reading AMAP " .. filename)
  local fd = io.open(filename, "r")
  if fd then
    io.close(fd)
    for line in io.lines(filename) do
      local name, value = string.match(line, "(\".-\")%s*:%s*(.*)")
      if name and value and tonumber(value) == nil then
        local x = load("return " .. unquote(value))
        amap.data[unquote(name)] = x()
      end
    end
    amap.refresh()
  else
    print("arcwise.read: " .. filename .. " not read, using defaults.")
  end
end

return amap
