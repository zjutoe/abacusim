require 'luabit/bit'

function init_regs()
   local R = {}
   for i=0,14 do
      R[i] = 0
   end
   R['PC'] = 0			-- Program Counter
   R['CPSR'] = 0		-- Current Program Status Register

   return R
end

local R = init_regs()

function dump_regs(R)
   for k, v in pairs(R) do
      print (k, v)
   end
end

dump_regs(R)


function cond(inst, cpsr)

   local c = bit.brshift(inst, 28) -- inst[31:28]
   
   if c == 0 then 
      -- Equal
      -- CPSR[31:28] = {N, Z, C, V}
      return bit.band(cpsr, 0x40000000) ~= 0
   elseif c == 1 then
      -- NE: Z clear
      -- Not Equal
       -- CPSR[31:28] = {N, Z, C, V}
      return bit.band(cpsr, 0x40000000) == 0
   elseif c == 2 then
      -- CS/HS: C set
      -- Carry set/unsigned higher or same
      -- CPSR[31:28] = {N, Z, C, V}
      return bit.band(cpsr, 0x20000000) ~= 0
   elseif c == 3 then
      -- CC/LO: C clear 
      -- Carry clear/unsigned lower
       -- CPSR[31:28] = {N, Z, C, V}
      return bit.band(cpsr, 0x20000000) == 0
   elseif c == 4 then
      -- MI: N set
      -- Minus/negative
       -- CPSR[31:28] = {N, Z, C, V}
      return bit.band(cpsr, 0x80000000) ~= 0
   elseif c == 5 then
      -- PL: N clear
      -- Plus/positive or zero
       -- CPSR[31:28] = {N, Z, C, V}
      return bit.band(cpsr, 0x80000000) == 0
   elseif c == 6 then
      -- VS: V set
      -- Overflow
       -- CPSR[31:28] = {N, Z, C, V}
      return bit.band(cpsr, 0x10000000) ~= 0
   elseif c == 7 then
      -- VC: V clear
      -- No overflow
      -- CPSR[31:28] = {N, Z, C, V}
      return bit.band(cpsr, 0x10000000) == 0
   elseif c == 8 then
      -- HI: C set and Z clear
      -- Unsigned higher
      -- CPSR[31:28] = {N, Z, C, V}
      return bit.band(cpsr, 0x20000000) ~= 0 and bit.band(cpsr, 0x40000000) == 0
   elseif c == 9 then
      -- LS: C clear or Z set
      -- Unsigned lower or same
      -- CPSR[31:28] = {N, Z, C, V}
      return bit.band(cpsr, 0x20000000) == 0 and bit.band(cpsr, 0x40000000) ~= 0
   elseif c == 10 then
      -- GE: N set and V set, or N clear and V clear (N == V)
      -- Signed greater than or equal
      -- CPSR[31:28] = {N, Z, C, V}
      return bit.band(cpsr, 0x80000000) == bit.band(cpsr, 0x10000000)
   elseif c == 11 then
      -- LT: N set and V clear, or N clear and V set (N != V)
      -- Signed less than
      -- CPSR[31:28] = {N, Z, C, V}
      return bit.band(cpsr, 0x80000000) ~= bit.band(cpsr, 0x10000000)
   elseif c == 12 then
      -- GT: Z clear, and either N set and V set, or N clear and V clear (Z == 0,N == V)
      -- Signed greater than
      -- CPSR[31:28] = {N, Z, C, V}
      return  bit.band(cpsr, 0x40000000) == 0 and bit.band(cpsr, 0x80000000) == bit.band(cpsr, 0x10000000)
   elseif c == 13 then
      -- LE: Z set, or N set and V clear, or N clear and V set (Z == 1 or N != V)
      -- Signed less than or equal
      -- CPSR[31:28] = {N, Z, C, V}
      return  bit.band(cpsr, 0x40000000) ~= 0 or bit.band(cpsr, 0x80000000) ~= bit.band(cpsr, 0x10000000)
   elseif c == 14 then
      -- AL: 
      -- Always (unconditional)
      return true
   elseif c == 15 then
      -- NV: Illegal instruction prior to v5 (see ARM ARM A3-5).
      
      -- In ARMv5 and above, a condition field of 0b1111 is used to
      -- encode various additional instructions which can only be
      -- executed unconditionally.

      -- All instruction encoding diagrams which show bits[31:28] as
      -- cond only match instructions in which these bits are not
      -- equal to 0b1111.

      return true		-- FIXME verify the instruction opcode      
   end
   
end
function decode(inst)
   
end