require 'bit'
require 'icache'
require 'dcache'
require 'mips_register'
require 'dbg'

local function decode(inst)
   local op = bit.sub_tonum(inst, 31, 26)
   local rs = bit.sub_tonum(inst, 25, 21)
   local rt = bit.sub_tonum(inst, 20, 16)
   local rd = bit.sub_tonum(inst, 15, 11)
   local sa = bit.sub_tonum(inst, 10, 6)
   local fun = bit.sub_tonum(inst, 5, 0)
   local imm = bit.sub_tonum(inst, 15, 0)

   return op, rs, rt, rd, sa, fun, imm
end



local function exception(error, R)
   R:set(R.OVERFLOW, 1)
end



local function do_add(inst, R) 
   local op, rs, rt, rd, sa, fun, imm = decode(inst)
   local s, t = R:get(rs), R:get(rt)

   local d = s + t
   if s > 0 and t > 0 and d > 0x80000000 or
      s < 0 and t < 0 and d < -0x80000000 then
      -- overflow
      exception("integer_overflow")
   else
      R:set(rd, d)
   end
end



local function do_addu(inst, R) 
   local op, rs, rt, rd, sa, fun, imm = decode(inst)
   local s, t = R:get(rs), R:get(rt)

   local d = s + t
   R:set(rd, d)
end



local function do_and(inst, R)
   local op, rs, rt, rd, sa, fun, imm = decode(inst)
   local s, t = R:get(rs), R:get(rt)

   local d = bit.tonum(bit.band(bit.tobits(s), bit.tobits(t)))
   R:set(rd, d)
end



local function do_div(inst, R) 
   local op, rs, rt, rd, sa, fun, imm = decode(inst)
   local s, t = R:get(rs), R:get(rt)

   if t ~= 0 then
      local hi = math.floor(s / t)
      local lo = s - hi*t
   else
      -- TODO the SPEC says UNPREDICTABLE
      local hi, lo = 0, 0
   end
   R:set(R.HI, hi)
   R:set(R.LO, lo)
end



local function do_divu(inst, R) 
   local op, rs, rt, rd, sa, fun, imm = decode(inst)
   local s, t = R:getu(rs), R:getu(rt)

   if t ~= 0 then
      local hi = math.floor(s / t)
      local lo = s - hi*t	-- no pun meant here:-)
   else
      -- TODO the SPEC says UNPREDICTABLE
      local hi, lo = 0, 0
   end
   R:set(R.HI, hi)
   R:set(R.LO, lo)
end



local function do_mfhi(inst, R) 
   local op, rs, rt, rd, sa, fun, imm = decode(inst)

   local hi = R:get(R.HI)
   R:set(rd, hi)
end



local function do_mflo(inst, R) 
   local op, rs, rt, rd, sa, fun, imm = decode(inst)

   local lo = R:get(R.LO)
   R:set(rd, lo)
end



local function do_mult(inst, R) 
   local op, rs, rt, rd, sa, fun, imm = decode(inst)
   local s, t = R:get(rs), R:get(rt)
   local d = s * t
   local lo = d % 0x100000000
   local hi = math.floor(d / 0x100000000)
   R:set(R.HI, hi)
   R:set(R.LO, lo)
end



local function do_multu(inst, R) 
   local op, rs, rt, rd, sa, fun, imm = decode(inst)
   local s, t = R:getu(rs), R:getu(rt)
   local d = s * t
   local lo = d % 0x100000000
   local hi = math.floor(d / 0x100000000)
   R:set(R.HI, hi)
   R:set(R.LO, lo)
end



local function do_noop(inst, R) 
   return nil
end



local function do_or(inst, R) 
   local op, rs, rt, rd, sa, fun, imm = decode(inst)
   local s, t = R:get(rs), R:get(rt)
   local s, t = bit.tobits(s), bit.tobits(t)
   local d = bit.tonum(bit.bor(s, t))
   R:set(rd, d)
end



local function do_slt(inst, R) 
   local op, rs, rt, rd, sa, fun, imm = decode(inst)
   local s, t = R:get(rs), R:get(rt)
   local d = s < t and 1 or 0
   R:set(rd, d)
end



local function do_sltu(inst, R) 
   local op, rs, rt, rd, sa, fun, imm = decode(inst)
   local s, t = R:getu(rs), R:getu(rt)
   local d = s < t and 1 or 0
   R:set(rd, d)
end



local function do_sll(inst, R) 
   local op, rs, rt, rd, sa, fun, imm = decode(inst)
   local s = R:get(rs)
   local d = bit.sll(bit.tobits(s), sa)
   R:set(rd, d)
end



local function do_sllv(inst, R) 
   local op, rs, rt, rd, sa, fun, imm = decode(inst)
   local s, t = R:get(rs), R:get(rt)
   local t = t % 0x20
   local d = bit.sll(bit.tobits(s), t)
   R:set(rd, d)
end



local function do_sra(inst, R) 
   local op, rs, rt, rd, sa, fun, imm = decode(inst)
   local s = R:get(rs)
   local d = bit.sra(bit.tobits(s), sa)
   R:set(rd, d)
end



local function do_srl(inst, R) 
   local op, rs, rt, rd, sa, fun, imm = decode(inst)
   local s = R:get(rs)
   local d = bit.srl(bit.tobits(s), sa)
   R:set(rd, d)
end



local function do_srlv(inst, R) 
   local op, rs, rt, rd, sa, fun, imm = decode(inst)
   local s, t = R:get(rs), R:get(rt)
   local t = t % 0x20
   local d = bit.srl(bit.tobits(s), t)
   R:set(rd, d)
end



local function do_sub(inst, R)
   local op, rs, rt, rd, sa, fun, imm = decode(inst)
   local s, t = R:get(rs), R:get(rt)

   local d = s - t
   if s > 0 and t < 0 and d > 0x80000000 or
      s < 0 and t > 0 and d < -0x80000000 then
      -- overflow
      exception("integer_overflow")
   else
      R:set(rd, d)
   end
end



local function do_subu(inst, R) 
   local op, rs, rt, rd, sa, fun, imm = decode(inst)
   local s, t = R:getu(rs), R:getu(rt)

   local d = s - t
   R:set(rd, d)
end



local function do_syscall(inst, R) 
   
end


local function do_xor(inst, R) 
   local op, rs, rt, rd, sa, fun, imm = decode(inst)
   local s, t = R:get(rs), R:get(rt)
   local s, t = bit.tobits(s), bit.tobits(t)
   local d = bit.tonum(bit.bxor(s, t))
   R:set(rd, d)
end



local inst_handle_rtype = {
   [0x20] = do_add,	       -- add signed (with overflow) 
   [0x21] = do_addu,	       -- add unsigned 
   [0x24] = do_and,	       -- bitwise and 
   [0x1A] = do_div,	       -- divide signed 
   [0x1B] = do_divu,	       -- divide unsigned 
   [0x10] = do_mfhi,	       -- move from HI 
   [0x12] = do_mflo,	       -- move from LO 
   [0x18] = do_mult,	       -- multiply signed 
   [0x19] = do_multu,	       -- multiply unsigned 
   [0x25] = do_or,	       -- bitwise or 
   [0x2A] = do_slt,	       -- set on less than (signed) 
   [0x2B] = do_sltu,	       -- set on less than immediate (signed) 
   [0x00] = do_sll,	       -- shift left logical 
   [0x00] = do_noop,	       -- no-op is SLL $0 $0 0 
   [0x04] = do_sllv,	       -- shift left logical variable 
   [0x03] = do_sra,	       -- shift right arithmetic 
   [0x02] = do_srl,	       -- shift right logic  
   [0x06] = do_srlv,	       -- shift right logical variable 
   [0x22] = do_sub,	       -- sub signed 
   [0x23] = do_subu,	       -- sub unsigned    
   [0x26] = do_xor,	       -- bitwise exclusive or 
   [0x0C] = do_syscall, -- system call FIXME system call is not R-type in theory?
}

local inst_handle_bz = {
   [0x01] = BZ_BGEZ,	-- fmt=0x01, BGEZ, branch on >= 0
   [0x11] = BZ_BGEZAL,	-- fmt=0x11, BGEZAL, BGEZ and link
   [0x00] = BZ_BLTZ,	-- fmt=0x00, BLTZ, branch on < 0
   [0x10] = BZ_BLTZAL,	-- fmt=0x10, BLTZAL, BLTZ and link
}


local function decode_itype(inst)
   local op = bit.sub_tonum(inst, 31, 26)
   local rs = bit.sub_tonum(inst, 25, 21)
   local rt = bit.sub_tonum(inst, 20, 16)
   local imm = bit.sub_tonum_se(inst, 15, 0) -- sign extended

   return op, rs, rt, imm
end


local function do_addi(inst, dcache, R)
   local op, rs, rt, imm = decode_itype(inst)
   local s = R:get(rs)
   local t = s + imm
   if s>0 and imm>0 and t > 0x80000000 or
      s<0 and imm<0 and t < -0x80000000 then
      exception("integer_overflow")
   else
      R:set(rt, t)
   end
end


local function do_addiu(inst, dcache, R)
   local op, rs, rt, imm = decode_itype(inst)
   local s = R:get(rs)
   local t = s + imm
   R:set(rt, t)
end



local function do_andi(inst, dcache, R)
   local op, rs, rt = decode_itype(inst)
   local s = bit.tobits(R:get(rs))
   local imm = bit.sub(inst, 15, 0)
   local t = bit.tonum(bit.band(s, imm))
   R:set(rt, t)
end


local function do_ori(inst, dcache, R)
   local op, rs, rt = decode_itype(inst)
   local s = bit.tobits(R:get(rs))
   local imm = bit.sub(inst, 15, 0)
   local t = bit.tonum(bit.bor(s, imm))
   R:set(rt, t)
end


local function do_xori(inst, dcache, R)
   local op, rs, rt = decode_itype(inst)
   local s = bit.tobits(R:get(rs))
   local imm = bit.sub(inst, 15, 0)
   local t = bit.tonum(bit.bxor(s, imm))
   R:set(rt, t)
end


local function do_slti(inst, dcache, R)
   local op, rs, rt, imm = decode_itype(inst)
   local s = R:get(rs)
   local t = s < imm and 1 or 0
   R:set(rt, t)
end





local inst_handle = {
   [0x08]  = do_addi,		-- add immediate with overflow  
   [0x09]  = do_addiu,		-- add immediate no overflow  
   [0x0C]  = do_andi,		-- bitwise and immediate  
   [0x0D]  = do_ori,		-- bitwise or immediate  
   [0x0E]  = do_xori,		-- bitwise exclusive or immediate  

   [0x0A]  = do_slti,	      -- set on less than immediate  
   [0x0B]  = do_SLTIU,	      -- set on less than immediate unsigned  FIXME WTF?

   [0x04]  = do_BEQ,		-- branch on equal  

   [0x07]  = do_BGTZ,		-- branch if $s > 0  
   [0x06]  = do_BLEZ,		-- branch if $s <= 0  
   [0x05]  = do_BNE,		-- branch if $s != $t  
   [0x02]  = do_J,		-- jump  
   [0x03]  = do_JAL,		-- jump and link  

   [0x20]  = do_LB,		-- load byte  
   [0x24]  = do_LBU,		-- load byte unsigned  
   [0x21]  = do_LH,		--   
   [0x25]  = do_LHU,		--   
   [0x0F]  = do_LUI,		-- load upper immediate  
   [0x23]  = do_LW,		-- load word  
   [0x31]  = do_LWCL,		-- load word  
   [0x28]  = do_SB,		-- store byte  
   [0x29]  = do_SH,		--   
   [0x2B]  = do_SW,		-- store word  
   [0x39]  = do_SWCL,
}


local function loop(R, icache, dcache)
   while true do
      local pc = R:get(R.PC)
      local inst_d = icache:rd(pc)
      local inst = bit.tobits(icache:rd(pc))
      if not inst then break end
      local op = bit.sub_tonum(inst, 31, 26)
      LOGD(op)
      if op == 0 then
	 -- R type
	 local func = bit.sub_tonum(inst, 5, 0)
	 local h = inst_handle_rtype[func]
	 h(inst, R)
      elseif op == 1 then
	 -- BZ
	 local fmt = bit.sub_tonum(inst, 20, 16)
	 local h = inst_handle_bz[fmt]
	 h(inst, R)
      else
	 local h = inst_handle[op]
	 h(inst, R, icache, dcache)
      end
      pc = pc + 4
      R:set(R.PC, pc)
   end
end


local init_icache = {
   [0] = 0x20090002,		-- addi $t1, $zero, 2
   0x812A0003,			-- lb   $t2, 3($t1)
}

local ic = icache.init(init_icache)
local dc = dcache.init()
local R = mips_register.init()

loop(R, ic, dc)

