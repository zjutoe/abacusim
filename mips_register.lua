local pairs = pairs

module(...)

local _R = {
   MAX = 36,
   PC = 32,
   OVERFLOW = 33,
   LO = 34,
   HI = 35,
}

function init()
   local R = {}
   for k, v in pairs(_R) do
      R[k] = v
   end

   for i=0, _R.MAX do
      R[i] = 0
   end

   R['PC']

   return R
end


function _R.set(self, n, v)
   if n<0 or n>self.MAX then return end

   if v < 0 then
      -- two's complement representation
      v = 0x100000000 + v
   elseif v>0xFFFFFFFF then
      -- truncate too big numbers
      v = v % 0xFFFFFFFF
   end
   self[n] = v
end

function _R.get(self, n)
   if n == 0 then return 0 end
   local v = self[n]   
   -- two's complement representation
   return v < 0x80000000 and v or v - 0x100000000
end

-- read as unsigned integer
function _R.getu(self, n)
   if n == 0 then return 0 end
   return self[n]
end

