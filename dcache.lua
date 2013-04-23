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

function cache.rd(self, addr)
   return self[math.floor(addr / 4) + 1]
end

function cache.wr(self, addr, v)
   self[math.floor(addr / 4) + 1] = v
end
