-- Qt frontend schema protocol, version 1. GPL-2.0-or-later.
-- Export the same definitions and dependency decisions used by the Lua engine.
local function array(t) return setmetatable(t or {}, { json_array = true }) end
local function encode(value)
  local kind = type(value)
  if kind == "nil" then return "null" end
  if kind == "boolean" then return value and "true" or "false" end
  if kind == "number" then
    assert(value == value and value ~= math.huge and value ~= -math.huge)
    return tostring(value)
  end
  if kind == "string" then
    return '"' .. value:gsub('[%z\1-\31\\"]', function(c)
      return string.format('\\u%04x', string.byte(c))
    end) .. '"'
  end
  assert(kind == "table", "unsupported schema type")
  local parts = {}
  if getmetatable(value) and getmetatable(value).json_array then
    for _, item in ipairs(value) do table.insert(parts, encode(item)) end
    return '[' .. table.concat(parts, ',') .. ']'
  end
  for _, key in ipairs(table.keys_sorted(value)) do
    table.insert(parts, encode(key) .. ':' .. encode(value[key]))
  end
  return '{' .. table.concat(parts, ',') .. '}'
end
local function ordered(defs)
  local list = {}
  for _, def in pairs(defs) do table.insert(list, def) end
  table.sort(list, function(a,b)
    if (a.priority or 50) ~= (b.priority or 50) then return (a.priority or 50) > (b.priority or 50) end
    return (a.label or a.name) < (b.label or b.name)
  end)
  return list
end
local function choices(defs, filter)
  local result = array()
  for _, def in ipairs(ordered(defs)) do
    if not filter or ob_match_conf(def) then
      table.insert(result, {id=def.name, text=def.label})
    end
  end
  return result
end
local function export(path)
  local result = { protocol=1, config={}, choices={}, modules=array(), format=ob_game_format() }
  for _, key in ipairs({"engine","game","port","length","theme"}) do
    result.config[key] = tostring(OB_CONFIG[key] or "")
  end
  result.choices.engine = choices(OB_ENGINES, false)
  result.choices.game = choices(OB_GAMES, true)
  result.choices.port = choices(OB_PORTS, true)
  result.choices.theme = choices(OB_THEMES, true)
  result.choices.length = array({{id="single",text=_("Single Level")}, {id="few",text=_("A Few Maps")},
    {id="episode",text=_("One Episode")}, {id="game",text=_("Full Game")}})
  for _, mod in ipairs(ordered(OB_MODULES)) do
    local is_ui = ob_check_ui_module(mod)
    local entry = { id=mod.name, text=mod.label, tooltip=mod.tooltip or "",
      isUi=is_ui, available=not not mod.shown, enabled=is_ui or not not mod.enabled,
      group=is_ui and (mod.side == "left" and "world" or "gameplay") or "modules", options=array() }
    for _, opt in ipairs(ordered(mod.options or {})) do
      local value = opt.value or opt.default or ""
      if is_ui then value = OB_CONFIG[opt.name] or value end
      local item = { id=opt.name, text=opt.label, tooltip=opt.longtip or opt.tooltip or "",
        value=tostring(value), default=tostring(opt.default or ""), choices=array(), nan=array() }
      if string.match(opt.name, "^header_") then item.kind = "header"
      elseif opt.valuator == "slider" then
        item.kind = "slider"; item.min=opt.min; item.max=opt.max; item.step=opt.increment or 1
        item.units=opt.units or ""
        for token in (opt.nan or ""):gmatch('[^,]+') do table.insert(item.nan, token) end
      elseif opt.valuator == "button" then item.kind = "boolean"
      else
        item.kind = "choice"
        for i=1,#(opt.choices or {}),2 do
          table.insert(item.choices, {id=tostring(opt.choices[i]), text=opt.choices[i+1]})
        end
      end
      table.insert(entry.options, item)
    end
    table.insert(result.modules, entry)
  end
  local file, err = io.open(path, 'wb'); assert(file, err)
  assert(file:write(encode(result))); assert(file:close())
end
return export
