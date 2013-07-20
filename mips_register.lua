local pairs = pairs
local string = string

module(...)

local _R = {
   zero = 0,
   v0 = 2,
   v1 = 3,
   a0 = 4,
   a1 = 5,
   a2 = 6,
   a3 = 7,

   gp = 28,
   sp = 29,
   fp = 30,
   ra = 31,

   PC = 32,
   OVERFLOW = 33,
   LO = 34,
   HI = 35,
   MAX = 36,
}

function _R.regname(self, n)
   local name = {
      [0] = "$zero",

      [2] = "$v0", [3] = "$v1",

      [4] = "$a0", [5] = "$a1", [6] = "$a2", [7] = "$a3",
      [8] = "$t0", [9] = "$t1", [10] = "$t2", [11] = "$t3", 
      [12] = "$t4",[13] = "$t5", [14] = "$t6", [15] = "$t7",

      [16] = "$s0", [17] = "$s1", [18] = "$s2", [19] = "$s3",
      [20] = "$s4", [21] = "$s5", [22] = "$s6", [23] = "$s7",

      [24] = "$t8", [25] = "$t9",

      [28] = "$gp", [29] = "$sp", [30] = "$fp", [31] = "$ra",
   }
   
   if name[n] then 
      return name[n]
   else
      return string.format("$%d", n)
   end
end

function _R.dump(self, n)
   return string.format("%s:%x", self:regname(n), self:get(n))
end

function init()
   local R = {}
   for k, v in pairs(_R) do
      R[k] = v
   end

   for i=0, _R.MAX do
      R[i] = 0
   end

   return R
end


function _R.set(self, n, v)
   if n<0 or n>self.MAX then return end
   if v > 0xFFFFFFFF or v < -0xFFFFFFFF then
      v = math.floor(v % 0x100000000)
   end

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

