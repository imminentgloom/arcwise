-- Arcwise
-- arc ring control

local amap = require(_path.code .. "arcwise/lib/arc_map")
local A = {
  shift = false,
  page = 1,
  ring = 1,
  arclearn = false,
  data = {}
}

function A.init()
  A.timer = metro.init()
  A.timer.event = function()
    for id, datum in pairs(A.data) do
      local x = params:get(id)
      local d = datum.d
      local am = amap.data[id]
      if am then
        datum.flag = false
        datum.slide = am.slide
      else
        datum.flag = true
      end
      local a = math.exp(-1/(15 * datum.slide))
      local out = x + (1 - a) * d
      datum.d = a * d
      if datum.flag and util.round(datum.d, 0.001) == 0 then
        A.data[id] = nil
      end
      params:set(id, out)
    end
    A:redraw()
  end
  A.timer:start(1/15)
end

function A.deinit()
  if A.timer then
    A.timer:stop()
    A.timer = nil
  end
end

function A:delta(n, d)
  if self.shift then
    if n == 1 then
      -- change page
      self.page = util.clamp(self.page + d, 1, 16)
    elseif n == 2 then
      -- change selected
      self.ring = util.clamp(self.ring + d, 1, 4)
    elseif n == 3 then
      local am = amap.data[amap.rev[self.page][self.ring]]
      if am then
        am.scale = util.clamp(am.scale + d * 0.1, 0.1, 1)
      end
    elseif n == 4 then
      local am = amap.data[amap.rev[self.page][self.ring]]
      if am then
        am.slide = util.clamp(am.slide + d * 0.1, 0, 4)
      end
    end
  else
    if A.arclearn then
      A.arclearn = false
      amap.arclearn_callback(self.page, n)
    end
    local id = amap.rev[self.page][n]
    if id then
      d = d * amap.data[id].scale
      if not self.data[id] then
        self.data[id] = {}
        self.data[id].d = 0
        self.data[id].flag = false
      end
      self.data[id].d = self.data[id].d + d
    end
  end
end

function A:redraw()
  self.arc:all(0)
  if self.shift then
    local i = self.page - 1
    local r = self.ring - 1
    for j = 1, 64 do
      self.arc:led(1, j, (j - 1) // 4 == i and 15 or 4)
      self.arc:led(2, j, (j - 1) // 16 == r and 15 or 4)
    end
    local am = amap.data[amap.rev[self.page][self.ring]]
    if am then
      local val1 = util.linlin(0.1, 1, .2*math.pi, 1.8*math.pi, am.scale)
      local val2 = util.linlin(0, 4, .2*math.pi, 1.8*math.pi, am.slide)
      self.arc:segment(3, val1 - .1 + math.pi, val1 + .1 + math.pi, 15)
      self.arc:segment(4, val2 - .1 + math.pi, val2 + .1 + math.pi, 15)
    end
  else
    for n = 1, 4 do
      local id = amap.rev[self.page][n]
      if id then
        local type = params:t(id)
        local minval
        local maxval
        if type == params.tNUMBER or type == params.tOPTION or type == params.tBINARY then
          local r = params:get_range(id)
          minval = r[1]
          maxval = r[2]
        else
          local param = params:lookup_param(id)
          minval = param:map_value(0)
          maxval = param:map_value(1)
        end
        local val = util.linlin(minval, maxval, .2*math.pi, 1.8*math.pi, params:get(id))
        self.arc:segment(n, val - .1 + math.pi, val + .1 * math.pi, 15)
      end
    end
  end
end

return A
