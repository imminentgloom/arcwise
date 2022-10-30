-- Arcwise mod
-- arc param menu page
-- based on norns mapping menu

local mod = require("core/mods")
local amap = require(_path.code .. "arcwise/lib/arc_map")
local A = require(_path.code .. "arcwise/lib/arcwise")

local mMAP = 1
local mMAPEDIT = 2

local m = {
  pos = 0,
  group = false,
  groupid = 0,
  mode = mMAP,
  alt = false,
  am = nil,
  ring = 1,
  page = 1,
  mpos = 1
}
local page

m.__index = m

m.mMAP = mMAP
m.mMAPEDIT = mMAPEDIT

function m.init() end
function m.deinit() end

function m.reset()
  page = nil
  m.pos = 0
  m.group = false
  m.mode = mMAP
end

function m.build_page()
  page = {}
  local i = 1
  repeat
    if params:visible(i) then table.insert(page, i) end
    if params:t(i) == params.tGROUP then
      i = i + params:get(i) + 1
    else
      i = i + 1
    end
  until i > params.count
end

function m.build_sub(sub)
  page = {}
  for i = 1, params:get(sub) do
    if params:visible(sub + i) then
      table.insert(page, sub + i)
    end
  end
end

function m.key_hook(...) end
function m.redraw_hook() return false end

function amap.arclearn_callback(p, r)
  m.page = p
  m.ring = r
  local i = page[m.pos + 1]
  local id = params:get_id(i)
  amap.assign(id, m.page, m.ring)
  if mod.menu.selected == mod.this_name then
    mod.menu.redraw()
  end
end

function m.key(n, z)
  if n == 1 and z == 1 then
    m.alt = true
    A.shift = true
    m.key_hook(n, z)
  elseif n == 1 and z == 0 then
    m.alt = false
    A.shift = false
    m.key_hook(n, z)
  elseif m.mode == mMAP then
    local i = page[m.pos + 1]
    local type = params:t(i)
    if n == 2 and z == 1 then
      if m.group == true then
        m.group = false
        m.build_page()
        m.pos = m.oldpos
      else
        mod.menu.exit()
      end
    elseif n == 3 and z == 1 then
      if type == params.tGROUP then
        m.build_sub(i)
        m.group = true
        m.groupid = i
        m.groupname = params:string(i)
        m.oldpos = m.pos
        m.pos = 0
      elseif type == params.tSEPARATOR then
        local k = m.pos + 1
        repeat
          k = k + 1
          if k > #page then k = 1 end
        until params:t(page[k]) == params.tSEPARATOR
        m.pos = k - 1
      elseif type ~= params.tFILE and type ~= params.tTEXT and type ~= params.tTRIGGER then
        if params:get_allow_pmap(i) then
          local id = params:get_id(i)
          local am = amap.data[id]
          if am == nil then
            amap.new(id)
            am = amap.data[id]
            if type == params.tNUMBER or type == params.tOPTION or type == params.tBINARY then
              local r = params:get_range(i)
              am.out_lo = r[1]
              am.out_hi = r[2]
            end
          end
          m.ring = am.ring
          m.page = am.page
          m.am = am
          m.mode = mMAPEDIT
        end
      end
    end
  elseif m.mode == mMAPEDIT then
    local pnum = page[m.pos + 1]
    local id = params:get_id(pnum)
    if n == 2 and z == 1 then
      m.mode = mMAP
      amap.assign(id, m.page, m.ring)
      amap.write()
    elseif n == 3 and z == 1 then
      if m.mpos == 1 then
        A.arclearn = not A.arclearn
      elseif m.mpos == 2 then
        amap.remove(id)
        amap.write()
        m.mode = mMAP
      elseif m.mpos == 5 or m.mpos == 6 then
        m.fine = true
      end
    elseif n == 3 then
      m.fine = false
    end
  end
  mod.menu.redraw()
end

function m.enc(n, d)
  if m.mode == mMAP then
    if n == 2 and m.alt == false then
      m.pos = util.clamp(m.pos + d, 0, #page - 1)
    elseif n == 2 and m.alt == true then
      d = d > 0 and 1 or -1
      local i = m.pos + 1
      repeat
        i = i + d
        if i > #page then i = 1 end
        if i < 1 then i = #page end
      until params:t(page[i]) == params.tSEPARATOR or i == 1
      m.pos = i - 1
    end
  elseif m.mode == mMAPEDIT then
    if n == 2 then
      m.mpos = (m.mpos + d) % 9
    elseif n == 3 then
      local pnum = page[m.pos + 1]
      local id = params:get_id(pnum)
      local type = params:t(pnum)
      local am = amap.data[id]
      if m.mpos == 0 then
        params:delta(pnum, d)
      elseif m.mpos == 3 then
        m.ring = util.clamp(m.ring + d, 1, 4)
      elseif m.mpos == 4 then
        m.page = util.clamp(m.page + d, 1, 16)
      elseif m.mpos == 5 or m.mpos == 6 then
        local param = params:lookup(id)
        local min = 0
        local max = 1
        if type == params.tCONTROL or type == params.tTAPER then
          d = d * param:get_delta()
          if m.fine then
            d = d / 20
          end
        elseif type == params.tNUMBER or type == params.tOPTION or type == params.tBINARY then
          local r = param:get_range()
          min = r[1]
          max = r[2]
        end
        if m.mpos == 5 then
          am.out_lo = util.clamp(am.out_lo + d, min, max)
        elseif m.mpos == 6 then
          am.out_hi = util.clamp(am.out_hi + d, min, max)
        end
      elseif m.mpos == 7 then
        am.scale = util.clamp(am.scale + d * 0.1, 0.1, 1.0)
      elseif m.mpos == 8 then
        am.slide = util.clamp(am.slide + d * 0.1, 0, 4)
      end
    end
  end
  mod.menu.redraw()
end

function m.redraw()
  screen.clear()
  if m.redraw_hook() then return end
  if m.mode == mMAP then
    if m.pos == 0 then
      local title = "PARAMETER MAP"
      if m.group then title = title .. " / " .. m.groupname end
      screen.level(4)
      screen.move(0, 10)
      screen.text(title)
    end
    for i = 1, 6 do
      if (i > 2 - m.pos) and (i < #page - m.pos + 3) then
        if i == 3 then screen.level(15) else screen.level(4) end
        local pnum = page[m.pos + i - 2]
        local type = params:t(pnum)
        local name = params:get_name(pnum)
        local id = params:get_id(pnum)
        if type == params.tSEPARATOR then
          screen.move(0, 10 * i + 2.5)
          screen.line_rel(127, 0)
          screen.stroke()
          screen.move(63, 10 * i)
          screen.text_center(name)
        elseif type == params.tGROUP then
          screen.move(0, 10 * i)
          screen.text(name .. " >")
        else
          screen.move(0, 10 * i)
          screen.text(id)
          screen.move(127, 10 * i)
          if type == params.tNUMBER or
              type == params.tCONTROL or
              type == params.tBINARY or
              type == params.tOPTION or
              type == params.tTAPER then
            local am = amap.data[id]
            if params:get_allow_pmap(pnum) then
              if am then
                screen.text_right(am.page .. ":" .. am.ring)
              else
                screen.text_right("-")
              end
            end
          end
        end
      end
    end
  elseif m.mode == mMAPEDIT then
    local pnum = page[m.pos + 1]
    local id = params:get_id(pnum)
    local type = params:t(pnum)
    local am = amap.data[id]

    local out_lo = am.out_lo
    local out_hi = am.out_hi
    if type == params.tCONTROL or type == params.tTAPER then
      local param = params:lookup_param(id)
      out_lo = util.round(param:map_value(am.out_lo), 0.01)
      out_hi = util.round(param:map_value(am.out_hi), 0.01)
    end

    local function hl(x)
      if m.mpos == x then screen.level(15) else screen.level(4) end
    end

    screen.move(0, 10)
    hl(0)
    screen.text(id)
    screen.move(127, 10)
    screen.text_right(params:string(pnum))
    screen.move(0, 25)
    hl(1)
    if A.arclearn then screen.text("LEARNING") else screen.text("LEARN") end
    screen.move(127, 25)
    hl(2)
    screen.text_right("CLEAR")

    screen.level(4)
    screen.move(0, 40)
    screen.text("ring")
    screen.move(55, 40)
    hl(3)
    screen.text_right(m.ring)
    screen.level(4)
    screen.move(0, 50)
    screen.text("page")
    screen.move(55, 50)
    hl(4)
    screen.text_right(m.page)

    screen.level(4)
    screen.move(63, 40)
    screen.text("out")
    screen.move(103, 40)
    hl(5)
    screen.text_right(out_lo)
    screen.move(127, 40)
    hl(6)
    screen.text_right(out_hi)
    screen.level(4)
    screen.move(63, 50)
    screen.text("scale")
    screen.move(127, 50)
    hl(7)
    screen.text_right(am.scale)
    screen.level(4)
    screen.move(63, 60)
    screen.text("slide")
    screen.move(127, 60)
    hl(8)
    screen.text_right(am.slide)
  end
  screen.update()
end

return m
