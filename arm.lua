-- I'm trying to comply with the ARM V5 Architecture Spec, which is DDI_01001

require 'utils'
require 'icache'
require 'dcache'

-- get v[n:m]
local function bits(v, n, m)
   return bit.bits(v, n, m)
end

-- local function subv(t, n, m)
--    return bit.tonum(bit.sub(t, n, m))
-- end

local function rotate_left(v, n)
   return bit.tonum(bit.rleft(v, n))
end

local function rotate_right(v, n)
   return bit.tonum(bit.rright(v, n))
end


function init_regs()
   local R = {}
   for i=0,15 do
      R[i] = 0
   end
   --['PC'] = 0			-- Program Counter
   R['CPSR'] = 0		-- Current Program Status Register
   
   local r_spsr = {}
   r_spsr[0x11] = 0		-- 0b10001, FIQ, fiq
   r_spsr[0x12] = 0		-- 0b10010, IRQ, irq 
   r_spsr[0x13] = 0		-- 0b10011, Supervisor, svc
   r_spsr[0x17] = 0		-- 0b10111, Abort, abt
   r_spsr[0x1B] = 0		-- 0b11011, Undefined, und
   -- User and System modes do not have SPSR
   R['SPSR'] = r_spsr

   function set(self, r, v) 
      if v>=0x100000000 then v = v % 0x100000000 end
      self[r] = v
   end

   function get(self, addr)
      return self[addr]
   end

   function set_spsr(cpu_mode)
      return self['SPSR'][cpu_mode]
   end   

   function get_spsr(cpu_mode)
      return self['SPSR'][cpu_mode]
   end   

   R.set = set
   R.get = get
   R.set_spsr = set_spsr
   R.get_spsr = get_spsr

   return R
end

local R = init_regs()

function dump_regs(R)
   for k, v in pairs(R) do
      print (k, v)
   end
end

--dump_regs(R)

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



function inst_is_dp_imm_shift(inst)
   return inst[27]==0 and inst[26]==0 and inst[25]==0 and inst[4] == 0
end

function inst_is_misc(inst) 
   return inst[27]==0 and inst[26]==0 and inst[25]==0 and
      inst[24]==1 and inst[23]==0 and inst[20]==0 and
      (inst[4] == 0 or inst[4]==1 and inst[7]==1)
end

function inst_is_dp_reg_shift(inst)
   return inst[27]==0 and inst[26]==0 and inst[25]==0 and inst[7]==0 and inst[4] == 1
end

function inst_is_multi_extra_ld_st(inst)
   return inst[27]==0 and inst[26]==0 and inst[25]==0 and inst[7]==1 and inst[4] == 1
end

function inst_is_dp_imm(inst)
   return inst[27]==0 and inst[26]==0 and inst[25]==1
end

function inst_is_undef(inst)
   return inst[27]==0 and inst[26]==0 and inst[25]==1 and inst[24]==1 and inst[23]==0 and inst[21]==0 and inst[20]==0
end

function inst_is_mv_imm_to_status_reg(inst)
   return inst[27]==0 and inst[26]==0 and inst[25]==1 and inst[24]==1 and inst[23]==0 and inst[21]==1 and inst[20]==0
end

function inst_is_ld_st_imm_offset(inst)
   return inst[27]==0 and inst[26]==1 and inst[25]==0
end

function inst_is_ld_st_reg_offset(inst)
   return inst[27]==0 and inst[26]==1 and inst[25]==1 and inst[4]==0
end

function inst_is_media(inst)
   return inst[27]==0 and inst[26]==1 and inst[25]==1 and inst[4]==1
end

function inst_is_arch_undef(inst)
   return inst[27]==0 and inst[26]==1 and inst[25]==1 and inst[24]==1 and inst[23]==1 and inst[22]==1 and
      inst[21]==1 and inst[20]==1 and inst[7]==0 and inst[6]==1 and inst[5]==1 and inst[4]==1 
end

function inst_is_ld_st_mult(inst)
   return inst[27]==1 and inst[26]==0 and inst[25]==0
end

function inst_is_b_bl(inst)
   return inst[27]==1 and inst[26]==0 and inst[25]==1
end

function inst_is_cop_ld_st_double_reg_trans(inst)
   return inst[27]==1 and inst[26]==1 and inst[25]==0
end

function inst_is_cop_dp(inst)
   return inst[27]==1 and inst[26]==1 and inst[25]==1 and inst[24]==0 and inst[4]==0
end

function inst_is_cop_reg_trans(inst)
   return inst[27]==1 and inst[26]==1 and inst[25]==1 and inst[24]==0 and inst[4]==1
end

function inst_is_sw_irq(inst)
   return inst[27]==1 and inst[26]==1 and inst[25]==1 and inst[24]==1
end


local inst_type_checker = {
   inst_is_dp_imm_shift,
   inst_is_misc, 
   inst_is_dp_reg_shift,
   inst_is_multi_extra_ld_st,
   inst_is_dp_imm,
   inst_is_undef,
   inst_is_mv_imm_to_status_reg,
   inst_is_ld_st_imm_offset,
   inst_is_ld_st_reg_offset,
   inst_is_media,
   inst_is_arch_undef,
   inst_is_ld_st_mult,
   inst_is_b_bl,
   inst_is_cop_ld_st_double_reg_trans,
   inst_is_cop_dp,
   inst_is_cop_reg_trans,
   inst_is_sw_irq,
}

local inst_type_name = {
   "dp_imm_shift",
   "misc", 
   "dp_reg_shift",
   "multi_extra_ld_st",
   "dp_imm",
   "undef",
   "mv_imm_to_status_reg",
   "ld_st_imm_offset",
   "ld_st_reg_offset",
   "media",
   "arch_undef",
   "ld_st_mult",
   "b_bl",
   "cop_ld_st_double_reg_trans",
   "cop_dp",
   "cop_reg_trans",
   "sw_irq",
}

require "data_processing"

local inst_handler = {
   do_dp_imm_shift,
   do_misc, 
   do_dp_reg_shift,
   do_multi_extra_ld_st,
   do_dp_imm,
   do_undef,
   do_mv_imm_to_status_reg,
   do_ld_st_imm_offset,
   do_ld_st_reg_offset,
   do_media,
   do_arch_undef,
   do_ld_st_mult,
   do_ld_st_mult,
   do_b_bl,
   do_cop_ld_st_double_reg_trans,
   do_cop_dp,
   do_cop_reg_trans,
   do_sw_irq,
}


function decode(inst)
   local i_handler
   for i, v in ipairs(inst_type_checker) do
      if v(inst) then
	 i_handler = inst_handler[i]
	 break
      end
   end

   return i_handler
end


local function exec_inst(inst, dcache, R)
   if inst == nil then return nil end

   io.write(string.format("%x: ", inst))
   local t_inst = bit.tobits(inst)
   local inst_hand = decode(t_inst)
   if inst_hand then 
      inst_hand(t_inst, dcache, R)
   else
      print("nil handler")
   end

   return true
end 

-- assume the iCache and register file are already initialized
local function loop(inst_cache, data_cache, reg_file)
   
   local pc = reg_file:get(15)
   local inst = inst_cache:rd(pc)
   local inst_1 = inst_cache:rd(pc + 4)
   local inst_2 = inst_cache:rd(pc + 8)
   reg_file:set(15, pc+8)

   ret = exec_inst(inst, data_cache, reg_file)
   while ret do
      -- these are 2 simulated branch delay slot
      inst = inst_1
      inst_1 = inst_2

      pc = reg_file:get(15)
      inst_2 = inst_cache:rd(pc+4)
      reg_file:set(15, pc+4)
      
      -- return false on errors, or return nil on end of exec
      ret = exec_inst(inst, data_cache, reg_file)
   end

end

local ic = icache.init()
local dc = dcache.init()

loop(ic, dc, R)
