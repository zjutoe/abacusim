-- I'm trying to comply with the ARM V5 Architecture Spec, which is 


--require 'luabit/bit'
require 'utils'

-- get v[n:m]
local function bits(v, n, m)
   return bit.bits(v, n, m)
end

local function subv(t, n, m)
   return bit.tonum(bit.sub(t, n, m))
end

local function rotate_left(v, n)
   return bit.tonum(bit.rleft(v, n))
end

local function rotate_right(v, n)
   return bit.tonum(bit.rright(v, n))
end


function init_regs()
   local R = {}
   for i=0,14 do
      R[i] = 0
   end
   R['PC'] = 0			-- Program Counter
   R['CPSR'] = 0		-- Current Program Status Register

   local function set(r, v) 
      -- TODO special treatment of PC
      if v>=0x100000000 then v = v % 0x100000000 end
      R[r] = v
   end

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

   local c = bits(inst, 31, 28)	-- inst[31:28]
   
   -- to check the CPSR[31:28], i.e. {N, Z, C, V}
   if c == 0 then 
      -- Equal, Z set
      return bits(cpsr, 30, 30) == 1
   elseif c == 1 then
      -- NE: Z clear
      -- Not Equal
      return bits(cpsr, 30, 30) == 0
   elseif c == 2 then
      -- CS/HS: C set
      -- Carry set/unsigned higher or same
      return bits(cpsr, 29, 29) == 1
   elseif c == 3 then
      -- CC/LO: C clear 
      -- Carry clear/unsigned lower
      return bits(cpsr, 29, 29) == 0
   elseif c == 4 then
      -- MI: N set
      -- Minus/negative
      return bits(cpsr, 31, 31) == 1
   elseif c == 5 then
      -- PL: N clear
      -- Plus/positive or zero
      return bits(cpsr, 31, 31) == 0
   elseif c == 6 then
      -- VS: V set
      -- Overflow
      return bits(cpsr, 28, 28) == 1
   elseif c == 7 then
      -- VC: V clear
      -- No overflow
      return bits(cpsr, 28, 28) == 0
   elseif c == 8 then
      -- HI: C set and Z clear
      -- Unsigned higher
      return bits(cpsr, 29, 29) == 1 and bits(cpsr, 30, 30) == 0
   elseif c == 9 then
      -- LS: C clear or Z set
      -- Unsigned lower or same
      return bits(cpsr, 29, 29) == 0 or bits(cpsr, 30, 30) == 1
   elseif c == 10 then
      -- GE: N set and V set, or N clear and V clear (N == V)
      -- Signed greater than or equal
      return bits(cpsr, 31, 31) == bits(cpsr, 28, 28)
   elseif c == 11 then
      -- LT: N set and V clear, or N clear and V set (N != V)
      -- Signed less than
      return bits(cpsr, 31, 31) ~= bits(cpsr, 28, 28)
   elseif c == 12 then
      -- GT: Z clear, and either N set and V set, or N clear and V clear (Z == 0,N == V)
      -- Signed greater than
      return  bits(cpsr, 30, 30) == 0 and bits(cpsr, 31, 31) == bits(cpsr, 28, 28)
   elseif c == 13 then
      -- LE: Z set, or N set and V clear, or N clear and V set (Z == 1 or N != V)
      -- Signed less than or equal
      return  bits(cpsr, 30, 30) == 1 or bits(cpsr, 31, 31) ~= bits(cpsr, 28, 28)
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


-- inst: table of bits of instruction
-- cpsr: table of bits of CPSR
function get_shifter_operand(inst, cpsr)
   local I = inst[25]
   local cflag = cpsr[29]

   local shifter_operand
   local shifter_carry_out

   if I==1 then
      -- A5.1.3 Data-processing operands - Immediate

      -- local rotate_imm = bits(inst, 11, 8)
      -- local immed_8 = bits(inst, 7, 0)
      -- shifter_operand = rotate_right(immed_8, rotate_imm * 2)

      local b_rotate_imm = bit.sub(inst, 11, 8)
      local b_immed_8 = bit.sub(inst, 7, 0)
      local rotate_imm = bit.tonum(b_rotate_imm)
      local b_shifter_operand = bit.ror( b_immed_8, rotate_imm*2 )

      shifter_operand = b.tonum(b_shifter_operand)
      if rotate_imm == 0 then
	 shifter_carry_out = cflag
      else
	 shifter_carry_out = b_shifter_operand[31]
      end

   else
      local Rm = subv(inst, 3, 0)
      local vRm = R[Rm]		-- TODO for PC (R15) it should add 8
      local b_Rm = bit.tobits(vRm)
      local op114 = subv(inst, 11, 4)
      local op64 = subv(inst, 6, 4)
      local op74 = sub(inst, 7, 4)

      if subv(inst, 11, 4) == 0 then
	 -- A5.1.4 Data-processing operands - Register
	 -- FIXME seems this is included in A5.1.5?
	 shifter_operand = vRm
	 shifter_carry_out = cflag

      elseif subv(inst, 6, 4) == 0 then
	 -- A5.1.5 Data-processing operands - Logical shift left by immediate
	 local shift_imm = subv(inst, 11, 7)
	 shifter_operand = bit.sll(vRm, shift_imm)
	 if shift_imm == 0 then
	    shifter_carry_out = cflag
	 else
	    shifter_carry_out = b_Rm[32-shift_imm]
	 end

      elseif subv(inst, 7, 4) == 1 then
	 -- A5.1.6 Data-processing operands - Logical shift left by register
	 local Rs = subv(inst, 11, 8)
	 local shift = R[Rs] % 256 -- vRs[7:0]
	 
	 if shift == 0 then
	    shifter_operand = vRm
	    shifter_carry_out = cflag
	 elseif shift < 32 then
	    shifter_operand = bit.tonum(bit.sll(b_Rm, shift))
	    shifter_carry_out = b_Rm[32-shift]
	 elseif shift == 32 then
	    -- FIXME this is actually included in shift<=32
	    shifter_operand = 0
	    shifter_carry_out = b_Rm[0]
	 else
	    shifter_operand = 0
	    shifter_carry_out = 0
	 end

      elseif subv(inst, 6, 4) == 2 then
	 -- A5.1.7 Data-processing operands - Logical shift right by immediate
	 local shift_imm = subv(inst, 11, 7)

	 if shift_imm == 0 then
	    shifter_operand = 0
	    shifter_carry_out = b_Rm[31]
	 else
	    shifter_operand = bit.tonum(bit.srl(b_Rm, shift_imm))
	    shifter_carry_out = b_Rm[shift_imm-1]
	 end	 

      elseif subv(inst, 7, 4) == 3 then
	 -- A5.1.8 Data-processing operands - Logical shift right by register
	 local Rs = subv(inst, 11, 8)
	 local shift = R[Rs] % 256 -- vRs[7:0]

	 if shift == 0 then
	    shifter_operand = vRm
	    shifter_carry_out = cflag
	 elseif shift < 32 then
	    shifter_operand = bit.tonum(bit.srl(b_Rm, shift))
	    shifter_carry_out = b_Rm[shift-1]
	 elseif shift == 32 then
	    shifter_operand = 0
	    shifter_carry_out = b_Rm[31]
	 else 
	    shifter_operand = 0
	    shifter_carry_out = 0
	 end
	 
      elseif subv(inst, 6, 4) == 4 then
	 -- A5.1.9 Data-processing operands - Arithmetic shift right by immediate
	 local shift_imm = subv(inst, 11, 7)
	 if shift_imm == 0 then
	    if b_Rm[31] == 0 then
	       shifter_operand = 0
	       shifter_carry_out = b_Rm[31]
	    else
	       shifter_operand = 0xFFFFFFFF
	       shifter_carry_out = b_Rm[31]
	    end
	 else			-- shift_imm > 0
	    shifter_operand = bit.tonum(bit.sra(b_Rm, shift_imm))
	    shifter_carry_out = b_Rm[shift_imm - 1]
	 end
	 
      elseif subv(inst, 7, 4) == 5 then
	 -- A5.1.10 Data-processing operands - Arithmetic shift right by register
	 local Rs = subv(inst, 11, 8)
	 local shift = R[Rs] % 256 -- vRs[7:0]
	 
	 if shift == 0 then
	    shifter_operand = vRm
	    shifter_carry_out = cflag
	 elseif shift < 32 then
	    shifter_operand = bit.tonum(bit.sra(b_Rm, shift))
	    shifter_carry_out = b_Rm[shift-1]
	 else 			-- shift >= 32
	    if b_Rm[31] == 0 then
	       shifter_operand = 0
	       shifter_carry_out = b_Rm[31]
	    else		-- b_Rm[31] == 1
	       shifter_operand = 0xFFFFFFFF
	       shifter_carry_out = b_Rm[31]
	    end
	 end

      elseif subv(inst, 6, 4) == 6 then
	 -- A5.1.11 Data-processing operands - Rotate right by immediate
	 local shift_imm = subv(inst, 11, 7)
	 if shift_imm == 0 then
	    -- See “Data-processing operands - Rotate right with
	    -- extend” on page A5-17
	 else
	    shifter_operand = bit.tonum(bit.ror(b_Rm, shift_imm))
	    shifter_carry_out = b_Rm[shift_imm-1]
	 end

      elseif subv(inst, 7, 4) == 7 then
	 -- A5.1.12 Data-processing operands - Rotate right by register
	 local Rs = subv(inst, 11, 8)
	 local shift = R[Rs] % 256 -- vRs[7:0]
	 local shift2 = R[Rs] % 16
	 if shift == 0 then
	    shifter_operand = vRm
	    shifter_carry_out = cflag
	 elseif shift2  == 0 then
	    shifter_operand = vRm
	    shifter_carry_out = b_Rm[31]	    
	 else
	    shifter_operand = bit.tonum( bit.ror(b_Rm, shift2) )
	    shifter_carry_out = b_Rm[shift2 - 1]	    
	 end

      elseif subv(inst, 11, 4) == 6 then
	 -- A5.1.13 Data-processing operands - Rotate right with extend
	 -- (C Flag Logical_Shift_Left 31) OR (Rm Logical_Shift_Right 1)
	 shifter_operand = bit.tonum(bit.concate(bit.sub(bit.tobits(cflag), 0, 0), 
						 bit.sub(b_Rm, 31, 1)))
	 shifter_carry_out = b_Rm[0]
      end
   
      return shifter_operand, shifter_carry_out
end

function set_flags(N, Z, C, V)
   local b_cpsr = bit.tobits(R['CPSR'])
   b_cpsr[31], b_cpsr[30], b_cpsr[29], b_cpsr[28] = N, Z, C, V
   R['CPSR'] = bit.tonum(b_cpsr)
end

-- 2's complement
-- assume 32 bits data width, 2^32 - abs(n) + 1
local function twos_comp(n)
   return (n<0) and (0x100000000 + n) or n
end

local function cflag_by_add(n1, n2)
   n1, n2 = twos_comp(n1), twos_comp(n2)   
   return n1+n2 > 0xFFFFFFFF
end

local function cflag_by_sub(n1, n2)
   n1, n2 = twos_comp(n1), twos_comp(n2)   
   return n1 < n2
end

local function sign_bit_of(n)
   return bit.tobits(n)[31]
end

local function vflag_by_add(n1, n2)
   local s1 = sign_bit_of(n1)
   local s2 = sign_bit_of(n2) 
   local s3 = sign_bit_of(n1+n2)
   return s1==s2 and s1~=s3
end

local function vflag_by_sub(n1, n2)
   local s1 = sign_bit_of(n1)
   local s2 = sign_bit_of(n2)
   local s3 = sign_bit_of(n1-n2)
   return s1~=s2 and s1~=s3
end

-- inst: table of bits of instruction
-- cpsr: table of bits of CPSR
function data_processing_inst(inst, cpsr)

   -- A3.4.1 Instruction encoding
   local op, S, Rn, Rd = subv(inst, 24, 21), inst[20], subv(inst, 19, 16), subv(inst, 15, 12)
   local vRn, vRd = R[Rn], R[Rd]
   -- A5.1 Addressing Mode 1 - Data-processing operands
   local shifter_operand, shifter_carry_out = get_shifter_operand(inst, cpsr)

   -- A3.4 Data-processing instructions
   -- TODO update flags
   if op == 0 then
      -- AND, Logical AND
      local vRd = bit.band(bit.tobits(vRn), bit.tobits(shifter_operand))
      R[Rd] = vRd

   elseif op == 1 then
      -- EOR, Logical Exclusive OR
      local vRd = bit.bxor(bit.tobits(vRn), bit.tobits(shifter_operand))
      R[Rd] = vRd
      
   elseif op == 2 then
      -- SUB, Subtract
      local vRd = vRn - shifter_operand
      R[Rd] = vRd

   elseif op == 3 then
      -- RSB, Reverse Subtract
      local vRd = shifter_operand - vRn
      R[Rd] = vRd

   elseif op == 4 then
      -- ADD, Add
      local vRd = vRn + shifter_operand
      R[Rd] = vRd

   elseif op == 5 then
      -- ADC, Add with Carry
      local cflag = cpsr[29]
      local vRd = vRn + shifter_operand + cflag
      R[Rd] = vRd

      if S == 1 and Rd == 15 then
	 -- if CurrentModeHasSPSR() then
	 --    CPSR = SPSR
	 -- else
	 --    UNPREDICTABLE
	 -- end
      elseif S == 1 then
	 local b_Rd = bit.tobits(vRd)
	 local N = b_Rd[31]
	 local Z = (vRd==0) and 1 or 0
	 local C = cflag_by_add(vRn, shifter_operand+cpsr[29])
	 local V = vflag_by_add(vRn, shifter_operand+cpsr[29])
      end

   elseif op == 6 then
      -- SBC, Subtract with Carry
      local vRd = vRn - shifter_operand - ((cpsr[29]==0) and 1 or 0)
      R[Rd] = vRd

   elseif op == 7 then
      -- RSC, Reverse Subtract with Carry
      local vRd = shifter_operand - vRn - ((cpsr[29]==0) and 1 or 0)
      R[Rd] = vRd

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