-- make a nice ui for selecting items

-- search bar at top with "enter" to show results

local DUMP_CHEST_NAME = "minecraft:chest_2"
local PICKUP_CHEST_NAME = "minecraft:chest_3"

local tArgs = {...}
local width, height = term.getSize()

if #tArgs > 0 then
  shell.run("clear")
  print("type to find items")
  print("press 1-9 to get that item")
  print("press tab to clear pickup/dropoff chests")
  error()
end

-- helper functions --
function all(tbl) 
  local prev_k = nil
  return function()
    local k,v = next(tbl, prev_k)
    prev_k = k
    return v
  end
end

function inc_tbl(tbl, key, val)
  assert(key, "key cannot be false or nil")
  val = val or 1
  if not tbl[key] then
    tbl[key] = 0
  end
  tbl[key] = tbl[key] + val
end

local function beginsWith(string, beginning)
  return string:sub(1,#beginning) == beginning
end

function forEach(tbl, func)
  for val in all(tbl) do
    func(val)
  end
end

function t2f(tbl, filename)
  filename = filename or "output"
  local h = io.open(filename, "w")
  h:write(textutils.serialize(tbl))
  h:close()
  shell.run("edit "..tostring(filename))
end


-- silo singleton code --
local silo = {
  dict = {},
  chest_names = {},
  dump_chest = DUMP_CHEST_NAME,
  pickup_chest = PICKUP_CHEST_NAME,
}

-- scan through all connected chests and add to table
function silo.find_chests()
  silo.chest_names = {}
  for name in all(peripheral.getNames()) do
    if beginsWith(name, "minecraft:chest") and name ~= silo.dump_chest and name ~= silo.pickup_chest then
      table.insert(silo.chest_names, name)
    end
  end
end

-- add the item to the record
function silo.add(item)
  inc_tbl(silo.dict, item.name, item.count)
end

-- scan through all invos and put into dict
function silo.update_all_items()
  for name in all(silo.chest_names) do
    local items = peripheral.call(name, "list")
    forEach(items, function(item) silo.add(item) end)
  end
end

function silo.startup()
  silo.find_chests()
end

function silo.grab(chest_name, slot, stack_size)
  peripheral.call(silo.pickup_chest, "pullItems", chest_name, slot, stack_size)
end

-- go through all items and take the specified item until count rem <= 0
function silo.get_item(item_name, count)
  local rem = count
  item_name = item_name:lower()
  for chest_name in all(silo.chest_names) do
    local items = peripheral.call(chest_name, "list")
    for i,item in pairs(items) do
      if item.name:find(item_name) then
        local amount = math.min(64, rem)
        silo.grab(chest_name, i, amount)
        rem = rem - amount
        if rem <= 0 then
          break
        end
      end
    end
  end
end

-- try to suck the slot of dump chest with storage chests
function silo.try_to_dump(slot, count)
  for chest_name in all(silo.chest_names) do
    local num = peripheral.call(silo.dump_chest, "pushItems", chest_name, slot, count)
    if num >= count then
      return true
    end
  end
end

-- for all storage chest try to suck everythin in the dump chest
function silo.dump()
  local suck_this = peripheral.call(silo.dump_chest, "list")
  for k,v in pairs(suck_this) do
    if not silo.try_to_dump(k,v.count) then
      return false
    end
  end
  return true
end

function silo.search(item_name)
  item_name = item_name:lower()
  for name in all(silo.chest_names) do
    local items = peripheral.call(name, "list")
    forEach(items, function(item) if item.name:find(item_name) then silo.add(item) end end)
  end
end

function silo.get_capacity()
  local total_slots = 0
  local used_slots = 0
  local used_items = 0
  
  for name in all(silo.chest_names) do
    total_slots = total_slots + peripheral.call(name, "size")
    local items = peripheral.call(name, "list")
    used_slots = used_slots + #items
    forEach(items, function(item) used_items = used_items + item.count end)
  end
  
  print("slots used ".. tostring(used_slots) .. "/" .. tostring(total_slots))
  print("items stored "..tostring(used_items) .. "/" .. tostring(total_slots*64))
end

function startup()
  term.clear()
  term.setCursorPos(1,1)
  term.write("Search: ")
  term.setCursorBlink(true)
  
  silo.startup()
  silo.update_all_items()
end

function backspace()
  local x,y = term.getCursorPos()
  if x <= 9 then
    return
  end
  term.setCursorPos(x-1,y)
  term.write(" ")
  term.setCursorPos(x-1,y)
end

function printWord(word)
  local x,y = term.getCursorPos()
  term.setCursorPos(1,y+1)
  term.clearLine()
  term.write("word: "..word)
  term.setCursorPos(x,y)
end

function notify(msg)
  local x,y = term.getCursorPos()
  term.setCursorPos(1,height)
  term.clearLine()
  term.write(msg)
  term.setCursorPos(x,y)
end

function clearUnderSearch()
  local x,y = term.getCursorPos()
  for i=2,height do
    term.setCursorPos(1,i)
    term.clearLine()
  end
  term.setCursorPos(x,y)
end

function listItems(word)
  clearUnderSearch()
  local x,y = term.getCursorPos()
  local line = 1
  local itemChoices = {}
  for item, count in pairs(silo.dict) do
    if item:find(word) then
      if line >= height-2 then
        term.setCursorPos(x,y)
        return itemChoices
      end
      term.setCursorPos(1,y+line)
      term.write(("%i) %ix %s"):format(line, count, item))
      itemChoices[line] = item
      line = line + 1
    end
  end
  term.setCursorPos(x,y)
  return itemChoices
end

function dumpChests(itemChoices)
  notify("dumping...")
  local a = silo.dump(silo.dump_chest)
  local b = silo.dump(silo.pickup_chest)
  if a and b then
    silo.update_all_items()
    itemChoices = listItems(word)
    notify("dump successful")
  else
    notify("dump failed")
  end
end

function grabStack(sel, itemChoices)
  if sel > #itemChoices then
    notify(("%i is not an option"):format(sel),0)
    return
  end
  local item = itemChoices[sel]
  local count = silo.dict[item]
  if count and count > 64 then
    count = 64
  end
  silo.get_item(item, count)
  silo.dict[item] = silo.dict[item] - count
  if silo.dict[item] <= 0 then
    silo.dict[item] = nil
  end
  itemChoices = listItems(word)
  notify(("grabbed %ix %s"):format(count,item))
end

function main()
  startup()

  local word = ""
  local itemChoices = listItems(word)
  while true do
    local event,keyCode,isHeld = os.pullEvent("key")
    local key = keys.getName(keyCode)
    
    if #key == 1 then
      word = word .. key
      term.write(key)
      itemChoices = listItems(word) 
    elseif key == "space" then
      word = word .. " "
      term.write(" ")
      itemChoices = listItems(word)
    elseif key == "backspace" then
      word = word:sub(1,#word-1)
      backspace()
      itemChoices = listItems(word)
    elseif key == "semicolon" then
      word = word .. ":"
      term.write(":")
      itemChoices = listItems(word)
    elseif key == "tab" then
      dumpChests(itemChoices)
    elseif 49 <= keyCode and keyCode <= 57 then
      local sel = keyCode - 48
      grabStack(sel, itemChoices)
    end
  end
end

main()