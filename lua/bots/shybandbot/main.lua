local com = require('component')
local pc = require("computer")
local ev = require('event')
package.loaded.handlers = nil
package.loaded.utils = nil
local utils = require('utils')
local handlers = require('handlers')
local box = com.getPrimary('chat_box')

THRESHOLD_TS = 1
DISABLE_THROTTLING = true
BOX_NAME = 'Bot'
MESSAGE_PREFIX = '%'
IGNORE_GL = true

local function handle_event(etype, addr, params)
  if etype == 'component_added' then
    utils.printf('\x1b[31m[COM] \x1b[32m+ %s\x1b[33m -> \x1b[34m%s\n', addr, params[1])
    if params[1] == 'chat_box' then
      utils.init_box(addr)
    end
    pc.beep(2000, 0.01)
  elseif etype == 'component_removed' then
    utils.printf('\x1b[31m[COM] \x1b[31m- %s\x1b[33m -> \x1b[34m%s\n', addr, params[1])
    pc.beep(1000, 0.01)
  end
  handlers.event(etype, addr, params)
end

local function handle_chat_message(addr, sender, message)
  local box = com.proxy(addr)
  utils.printf('\x1b[31m[MSG] \x1b[35m%s\x1b[33m%%\x1b[32m%s\x1b[33m: \x1b[34m%s\n', addr:sub(0, 8), sender, message)
  local succ, result
  if message:sub(0, 1) == MESSAGE_PREFIX then
    local params = utils.ssplit(message:sub(2), ' ')
    local command = table.remove(params, 1)
    params_s = table.concat(params, ' ')
    utils.printf('\x1b[31m[CMD] \x1b[35m%s\x1b[33m%%\x1b[32m%s\x1b[33m: \x1b[35m%s \x1b[34m%s\n', addr:sub(0, 8), sender, command, params_s)
    succ, result = pcall(handlers.command, addr, sender, command, params)
  else
    succ, result = pcall(handlers.message, addr, sender, message)
  end
  if not succ then
    utils.chat_trace(result)
    utils.traceback(result)
    return
  end
  if not result then return end
  local cbox = com.proxy(addr)
  cbox.setName(BOX_NAME)
  if type(result) ~= 'table' then
    result = { tostring(result) }
  end
  for _, v in ipairs(result) do
    utils.printf('\x1b[31m[REP] \x1b[35m%s \x1b[33m-> \x1b[35m%s\n', addr:sub(0, 8), v)
    cbox.say(v, math.huge)
  end
end

for addr, _ in com.list('chat_box') do
  utils.init_box(addr)
  pc.beep(1500, 0.01)
end
utils.printf('\x1b[31m[INF] \x1b[32mBot init OK\n')
pc.beep(2000, 0.1)
while true do
  local e = table.pack(ev.pull())
  etype = table.remove(e, 1)
  addr = table.remove(e, 1)
  if etype == 'interrupted' then
    break
  elseif etype == 'chat_message' then
    sender = table.remove(e, 1)
    message = table.remove(e, 1)
    if IGNORE_GL and message:sub(0, 1) == '!' then message = message:sub(2) end
    local succ, resp = pcall(handle_chat_message, addr, sender, message)  -- TODO: implement dublicates detection
    if not succ then
      utils.chat_trace(resp)
      utils.traceback(resp)
    end
  else
    local succ, result = pcall(handle_event, etype, addr, e)
    if not succ then
      utils.chat_trace(result)
      utils.traceback(result)
    end
  end
end
pc.beep(1000, 0.1)
utils.printf('\x1b[31m[INF] \x1b[33mBot stopped\n')

