require 'luabit/bit'

-- get v[n:m]
local function bits(v, n, m)
   if n<m or n>31 or m<0 then
      return nil
   end
   --return bit.blogic_rshift(bit.blshift(v, 31-n), 31-n+m)
   return bit.brshift(bit.blshift(v, 31-n), 31-n+m)
end

local function rotate_left(v, n)
   return bit.bor(bit.blshift(v, n), bit.brshift(v, 32-n))
end

local function rotate_right(v, n)
   return bit.bor(bit.brshift(v, n), bit.blshift(v, 32-n))
end


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


function opcode(inst, cpsr)
   
   --local op = bit.brshift(bit.blshift(inst, 7), 21) -- inst[24:21] is opcode
   local op = bits(inst, 24, 21)
   local I = bits(inst, 25, 25)
   local cflag = bits(cpsr, 29, 29)

   local shifter_operand
   local shifter_carry_out

   if I==1 then
      -- A5.1.3 Data-processing operands - Immediate
      local rotate_imm = bits(inst, 11, 8)
      local immed_8 = bits(inst, 7, 0)
      shifter_operand = rotate_right(immed_8, rotate_imm * 2)
      if rotate_imm == 0 then
	 shifter_carry_out = cflag
      else
	 shifter_carry_out = bits(shifter_operand, 31, 31)
      end
   else
      if bits(inst, 11, 4) == 0 then
	 -- A5.1.4 Data-processing operands - Register	 FIXME seems this is included in A5.1.5?
	 local Rm = bits(inst, 3, 0)
	 shifter_operand = R[Rm]
	 shifter_carry_out = cflag
      elseif bits(inst, 6, 4) == 0 then
	 -- A5.1.5 Data-processing operands - Logical shift left by immediate
	 local shift_imm = bits(inst, 11, 7)
	 local Rm = bits(inst, 3, 0)
	 shifter_operand = rotate_left(R[Rm], shift_imm) -- FIXME should be Logical_Shift_Left
	 if shift_imm == 0 then
	    shifter_carry_out = cflag
	 else
	    shifter_carry_out = bits(R[Rm], 32-shift_imm, 32-shift_imm)
	 end
      elseif bits(inst, 7, 4) == 1 then
	 -- A5.1.6 Data-processing operands - Logical shift left by register
	 
      end
      
      if bits(inst, 4, 4) == 0 then
	 local shift_imm = bits(inst, 11, 7)
	 local shift = bits(inst, 6, 5)
	 local Rm = bits(inst, 3, 0)
	 shifter = 
      elseif bits(inst, 7, 7) == 0 then
	 local Rs = bits(inst, 11, 8)
	 local shift = bits(inst, 6, 5)
	 local Rm = bits(inst, 3, 0)
      else
	 -- inst[25]==0, inst[4]==1, inst[7]==1, this is not a data
	 -- processing inst
	 
      end
   end

   if op == 0 then
      -- AND, Logical AND
      
   elseif op == 1 then
      -- EOR, Logical Exclusive OR
   elseif op == 2 then
      -- SUB, Subtract
   elseif op == 3 then
      -- RSB, Reverse Subtract
   elseif op == 4 then
      -- ADD, Add
   elseif op == 5 then
      -- ADC, Add with Carry
   elseif op == 6 then
      -- SBC, Subtract with Carry
   elseif op == 7 then
      -- RSC, Reverse Subtract with Carry
   elseif op == 8 then
      -- TST, Test
   elseif op == 9 then
      -- TEQ, Test Equivalence
   elseif op == 10 then
      -- CMP, Compare
   elseif op == 11 then
      -- CMN, Compare Negated
   elseif op == 12 then
      -- ORR, Logical (inclusive) OR
   elseif op == 13 then
      -- MOV, Move
   elseif op == 14 then
      -- BIC, Bit Clear
   elseif op == 15 then
      -- MVN, Move Not
   end
   
end


function decode(inst)

   local c = cond(inst)
   
   if c == true then
      local op = opcode(inst)
      
   else
      
   end
   
end