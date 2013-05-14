local math = math
local pairs = pairs

module(...)

local cache = {}

function init()
   local c = {}
   for k, v in pairs(cache) do
      c[k] = v
   end
   return c
end

-- NOTE data cache starts from address 0
function cache.rd(self, addr)
   return self[math.floor(addr / 4)] or 0 -- will never return nil
end

function cache.wr(self, addr, v)
   self[math.floor(addr / 4)] = v or 0 -- will never write nil
end
