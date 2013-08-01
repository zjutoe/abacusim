local pairs = pairs
local string = string
local print = print

module(...)

local _R = {
   zero = 0,
   v0 = 2,
   v1 = 3,
   a0 = 4,
   a1 = 5,
   a2 = 6,
   a3 = 7,

   t0 = 8,
   t1 = 9,
   t2 = 10,
   t3 = 11,

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

function _R.info(self)
   print("          zero       at       v0       v1       a0       a1       a2       a3")
   print(string.format(" R0   %08x %08x %08x %08x %08x %08x %08x %08x ", 
		       self[0], self[1], self[2], self[3], self[4], self[5], self[6], self[7]))

   print("            t0       t1       t2       t3       t4       t5       t6       t7")
   print(string.format(" R8   %08x %08x %08x %08x %08x %08x %08x %08x ", 
		       self[8], self[9], self[10], self[11], self[12], self[13], self[14], self[15]))

   print("            s0       s1       s2       s3       s4       s5       s6       s7")
   print(string.format(" R16  %08x %08x %08x %08x %08x %08x %08x %08x ", 
		       self[16], self[17], self[18], self[19], self[20], self[21], self[22], self[23]))


   print("            t8       t9       k0       k1       gp       sp       s8       ra")
   print(string.format(" R24  %08x %08x %08x %08x %08x %08x %08x %08x ", 
		       self[24], self[25], self[26], self[27], self[28], self[29], self[30], self[31]))


   print("            sr       lo       hi      bad    cause       pc")
   print(string.format("      %08x %08x %08x %08x %08x %08x ", 
		       self[0], self[34], self[35], self[0], self[0], self[32]))


   print("           fsr      fir")
   print(string.format("      %08x %08x ", 
		       self[0], self[0]))

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

