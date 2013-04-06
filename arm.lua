require 'luabit/bit'

function init_regs()
   local R = {}
   for i=0,14 do
      R[i] = 0
   end
   R['PC'] = 0
   R['CPSR'] = 0

   return R
end

local R = init_regs()

function dump_regs(R)
   for k, v in pairs(R) do
      print (k, v)
   end
end

dump_regs(R)

