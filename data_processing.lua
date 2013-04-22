require "utils"
require 'dbg'

local function subv(t, n, m)
   return bit.tonum(bit.sub(t, n, m))
end

-- inst: table of bits of instruction
-- cpsr: table of bits of CPSR
function get_shifter_operand(inst, cpsr, R)
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

      shifter_operand = bit.tonum(b_shifter_operand)
      if rotate_imm == 0 then
	 shifter_carry_out = cflag
      else
	 shifter_carry_out = b_shifter_operand[31]
      end

   else				-- I ~= 1

      local Rm = subv(inst, 3, 0)
      local vRm = R[Rm]		-- TODO for PC (R15) it should add 8
      local b_Rm = bit.tobits(vRm)
      local op114 = subv(inst, 11, 4)
      local op64 = subv(inst, 6, 4)
      local op74 = subv(inst, 7, 4)

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
   
   end				-- I==1

   return shifter_operand, shifter_carry_out
end




function set_flags(R, N, Z, C, V)
   local b_cpsr = bit.tobits(R['CPSR'])
   if N then b_cpsr[31] = N end
   if Z then b_cpsr[30] = Z end
   if C then b_cpsr[29] = C end
   if V then b_cpsr[28] = V end

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

local function decode_inst(inst, cpsr, R)
   -- A3.4.1 Instruction encoding
   local op, S, Rn, Rd = bit.sub_tonum(inst, 24, 21), inst[20], bit.sub_tonum(inst, 19, 16), bit.sub_tonum(inst, 15, 12)
   -- A5.1 Addressing Mode 1 - Data-processing operands
   local shifter_operand, shifter_carry_out = get_shifter_operand(inst, cpsr, R)

   return op, S, Rn, Rd, shifter_operand, shifter_carry_out   
end

local function restore_cpsr(inst)
      local cpu_mode = subv(inst, 4, 0)
      if cpu_mode ~= 0x10 and cpu_mode ~= 0x1F then -- ~= usr and ~= sys
	 R:set_cpsr(R:get_spsr(cpu_mode))
      else
	 -- Error UNPREDICTABLE
      end
end

local function do_and(inst, cpsr)   
   local op, S, Rn, Rd, shifter_operand, shifter_carry_out = decode_inst(inst, cpsr, R)
   local vRn = R[Rn]

   -- assume op == 0

   local vRd = bit.band(bit.tobits(vRn), bit.tobits(shifter_operand))
   R:set(Rd, vRd)		-- R[Rd] = vRd
   
   if S == 1 and Rd == 15 then
      restore_cpsr(inst)
   elseif S == 1 then
      local b_Rd = bit.tobits(vRd)
      local N = b_Rd[31]
      local Z = (vRd==0) and 1 or 0
      local C = shifter_carry_out
      local V = nil
      set_flags(R, N, Z, C, V)
   end
end

local function do_xor(inst, cpsr, R)
   local op, S, Rn, Rd, shifter_operand, shifter_carry_out = decode_inst(inst, cpsr, R)
   local vRn = R[Rn]

   -- EOR, Logical Exclusive OR
   local vRd = bit.bxor(bit.tobits(vRn), bit.tobits(shifter_operand))
   R:set(Rd, vRd)		-- R[Rd] = vRd

end

local function do_sub(inst, cpsr, R)
   local op, S, Rn, Rd, shifter_operand, shifter_carry_out = decode_inst(inst, cpsr, R)
   local vRn = R[Rn]

   -- SUB, Subtract
   local vRd = vRn - shifter_operand
   R:set(Rd, vRd)		-- R[Rd] = vRd   
end

local function do_rsb(inst, cpsr, R)
   local op, S, Rn, Rd, shifter_operand, shifter_carry_out = decode_inst(inst, cpsr, R)
   local vRn = R[Rn]

   -- RSB, Reverse Subtract
   local vRd = shifter_operand - vRn
   R:set(Rd, vRd)		-- R[Rd] = vRd
end

local function do_add(inst, cpsr, R)
   local op, S, Rn, Rd, shifter_operand, shifter_carry_out = decode_inst(inst, cpsr, R)
   local vRn = R[Rn]

   -- ADD, Add
   local vRd = vRn + shifter_operand
   R:set(Rd, vRd)		-- R[Rd] = vRd
   
   if S==1 and Rd==15 then
      restore_cpsr(inst)
   elseif S==1 then
      local b_Rd = bit.tobits(vRd)
      local N = b_Rd[31]
      local Z = (vRd==0) and 1 or 0
      local C = cflag_by_add(vRn, shifter_operand) and 1 or 0
      local V = vflag_by_add(vRn, shifter_operand) and 1 or 0
      set_flags(R, N, Z, C, V)
   end
end

local function do_adc(inst, cpsr, R)
   local op, S, Rn, Rd, shifter_operand, shifter_carry_out = decode_inst(inst, cpsr, R)
   local vRn = R[Rn]

   -- ADC, Add with Carry
   local cflag = cpsr[29]
   local vRd = vRn + shifter_operand + cflag
   R:set(Rd, vRd)		-- R[Rd] = vRd
   
   if S == 1 and Rd == 15 then
      restore_cpsr(inst)
   elseif S == 1 then
      local b_Rd = bit.tobits(vRd)
      local N = b_Rd[31]
      local Z = (vRd==0) and 1 or 0
      local C = cflag_by_add(vRn, shifter_operand+cflag) and 1 or 0
      local V = vflag_by_add(vRn, shifter_operand+cflag) and 1 or 0
      set_flags(R, N, Z, C, V)
   end
end


local function do_sbc(inst, cpsr, R)
   local op, S, Rn, Rd, shifter_operand, shifter_carry_out = decode_inst(inst, cpsr, R)
   local vRn = R[Rn]

   -- SBC, Subtract with Carry
   local cflag = cpsr[29]
   local not_cflag = cflag==0 and 1 or 0
   local vRd = vRn - shifter_operand - not_cflag
   R:set(Rd, vRd)
   
   if S == 1 and Rd == 15 then
      restore_cpsr(inst)
   elseif S == 1 then
      local b_Rd = bit.tobits(vRd)
      local N = b_Rd[31]
      local Z = (vRd==0) and 1 or 0
      local C = cflag_by_sub(vRn, shifter_operand - not_cflag) and 0 or 1
      local V = vflag_by_sub(vRn, shifter_operand - not_cflag) and 1 or 0
      set_flags(R, N, Z, C, V)
   end      
end


local function do_rsc(inst, cpsr, R)
   local op, S, Rn, Rd, shifter_operand, shifter_carry_out = decode_inst(inst, cpsr, R)
   local vRn = R[Rn]

   local cflag = cpsr[29]
   local not_cflag = cflag==0 and 1 or 0

   -- RSC, Reverse Subtract with Carry
   local vRd = shifter_operand - vRn - not_cflag
   R:set(Rd, vRd)

   if S == 1 and Rd == 15 then
      restore_cpsr(inst)
   elseif S == 1 then
      local b_Rd = bit.tobits(vRd)
      local N = b_Rd[31]
      local Z = (vRd==0) and 1 or 0
      local C = cflag_by_sub(vRn, shifter_operand - not_cflag) and 0 or 1
      local V = vflag_by_sub(vRn, shifter_operand - not_cflag) and 1 or 0
      set_flags(R, N, Z, C, V)
   end         
end

local function do_tst(inst, cpsr, R)
   local op, S, Rn, Rd, shifter_operand, shifter_carry_out = decode_inst(inst, cpsr, R)
   local vRn = R[Rn]

   -- TST, Test
   local alu_out = bit.band(Rn, shifter_operand)
   local N = alu_out[31]
   local Z = (bit.tonum(alu_out)==0) and 1 or 0
   local C = shifter_carry_out
   local V = nil
   set_flags(R, N, Z, C, V)   
end

local function do_teq(inst, cpsr, R)
   local op, S, Rn, Rd, shifter_operand, shifter_carry_out = decode_inst(inst, cpsr, R)
   local vRn = R[Rn]

   -- TEQ, Test Equivalence
   local alu_out = bit.bxor(bit.tobits(vRn), bit.tobits(shifter_operand))
   local N = alu_out[31]
   local Z = (bit.tonum(alu_out)==0) and 1 or 0
   local C = shifter_carry_out
   local V = nil
   set_flags(R, N, Z, C, V)   
end

local function do_cmp(inst, cpsr, R)
   local op, S, Rn, Rd, shifter_operand, shifter_carry_out = decode_inst(inst, cpsr, R)
   local vRn = R[Rn]

   -- CMP, Compare
   local alu_out = Rn - shifter_operand
   local N = bit.tobits(alu_out)[31]
   local Z = (alu_out==0) and 1 or 0
   local C = cflag_by_sub(vRn, shifter_operand)
   local V = vflag_by_sub(vRn, shifter_operand)
   set_flags(R, N, Z, C, V)   
end

local function do_cmn(inst, cpsr, R)
   local op, S, Rn, Rd, shifter_operand, shifter_carry_out = decode_inst(inst, cpsr, R)
   local vRn = R[Rn]

   -- CMN, Compare Negated
   local alu_out = Rn + shifter_operand
   local N = bit.tobits(alu_out)[31]
   local Z = (alu_out==0) and 1 or 0
   local C = cflag_by_add(vRn, shifter_operand)
   local V = vflag_by_add(vRn, shifter_operand)
   set_flags(R, N, Z, C, V)   
end

local function do_orr(inst, cpsr, R)
   local op, S, Rn, Rd, shifter_operand, shifter_carry_out = decode_inst(inst, cpsr, R)
   local vRn = R[Rn]

   -- ORR, Logical (inclusive) OR
   local vRd = bit.bor(bit.tobits(vRn), bit.tobits(shifter_operand))
   R:set(Rd, vRd)		-- R[Rd] = vRd
   
   if S == 1 and Rd == 15 then
      restore_cpsr(inst)
   elseif S == 1 then
      local b_Rd = bit.tobits(vRd)
      local N = b_Rd[31]
      local Z = (vRd==0) and 1 or 0
      local C = shifter_carry_out
      local V = nil
      set_flags(R, N, Z, C, V)
   end
end

local function do_mov(inst, cpsr, R)
   local op, S, Rn, Rd, shifter_operand, shifter_carry_out = decode_inst(inst, cpsr, R)

   -- MOV, Move
   local vRd = shifter_operand
   R:set(Rd, vRd)		-- R[Rd] = vRd

   if S == 1 and Rd == 15 then
      restore_cpsr(inst)
   elseif S == 1 then
      local b_Rd = bit.tobits(vRd)
      local N = b_Rd[31]
      local Z = (vRd==0) and 1 or 0
      local C = shifter_carry_out
      local V = nil
      set_flags(R, N, Z, C, V)
   end
end

local function do_bic(inst, cpsr, R)
   local op, S, Rn, Rd, shifter_operand, shifter_carry_out = decode_inst(inst, cpsr, R)
   local vRn = R[Rn]

   -- BIC, Bit Clear
   local vRd = bit.band(bit.tobits(vRn), bit.bnot(bit.tobits(shifter_operand)))
   R:set(Rd, vRd)		-- R[Rd] = vRd

   if S == 1 and Rd == 15 then
      restore_cpsr(inst)
   elseif S == 1 then
      local b_Rd = bit.tobits(vRd)
      local N = b_Rd[31]
      local Z = (vRd==0) and 1 or 0
      local C = shifter_carry_out
      local V = nil
      set_flags(R, N, Z, C, V)
   end

end

local function do_mvn(inst, cpsr, R)
   local op, S, Rn, Rd, shifter_operand, shifter_carry_out = decode_inst(inst, cpsr, R)

   -- MVN, Move Not
   local vRd = bit.bnot(bit.tobits(shifter_operand))
   R:set(Rd, vRd)		-- R[Rd] = vRd

   if S == 1 and Rd == 15 then
      restore_cpsr(inst)
   elseif S == 1 then
      local b_Rd = bit.tobits(vRd)
      local N = b_Rd[31]
      local Z = (vRd==0) and 1 or 0
      local C = shifter_carry_out
      local V = nil
      set_flags(R, N, Z, C, V)
   end
end


local ftable_data_processing = {
   [0] = do_and,
   [1] = do_xor,
   [2] = do_sub,
   [3] = do_rsb,
   [4] = do_add,
   [5] = do_adc,
   [6] = do_sbc,
   [7] = do_rsc,
   [8] = do_tst,
   [9] = do_teq,
   [10] = do_cmp,
   [11] = do_cmn,
   [12] = do_orr,
   [13] = do_mov,
   [14] = do_bic,
   [15] = do_mvn,
}

-- inst: table of bits of instruction
-- cpsr: table of bits of CPSR
function data_processing_inst(inst, R)

   local cpsr = bit.tobits(R:get('CPSR'))
   local op = bit.sub_tonum(inst, 24, 21)

   -- -- A3.4.1 Instruction encoding
   -- local op, S, Rn, Rd = bit.sub_tonum(inst, 24, 21), inst[20], bit.sub_tonum(inst, 19, 16), bit.sub_tonum(inst, 15, 12)
   -- local vRn, vRd = R[Rn], R[Rd]
   -- -- A5.1 Addressing Mode 1 - Data-processing operands
   -- local shifter_operand, shifter_carry_out = get_shifter_operand(inst, cpsr, R)

   ftable_data_processing[op](inst, cpsr, R)
end

-- FIXME we should not have such 3 redundant functions
function do_dp_imm_shift(inst, dcache, R)
   data_processing_inst(inst, R)
end
do_dp_reg_shift = do_dp_imm_shift
do_dp_imm = do_dp_imm_shift

