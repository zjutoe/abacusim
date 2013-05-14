require 'tbit'
require 'icache'
require 'dcache'
require 'mips_register'
require 'dbg'

local B  = tbit.init()

local function decode(inst)
   local op = B.sub_tonum(inst, 31, 26)
   local rs = B.sub_tonum(inst, 25, 21)
   local rt = B.sub_tonum(inst, 20, 16)
   local rd = B.sub_tonum(inst, 15, 11)
   local sa = B.sub_tonum(inst, 10, 6)
   local fun = B.sub_tonum(inst, 5, 0)
   local imm = B.sub_tonum(inst, 15, 0)

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

   local d = B.tonum(B.band(B.tobits(s), B.tobits(t)))
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
   local s, t = B.tobits(s), B.tobits(t)
   local d = B.tonum(B.bor(s, t))
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
   local d = B.sll(B.tobits(s), sa)
   R:set(rd, d)
end



local function do_sllv(inst, R) 
   local op, rs, rt, rd, sa, fun, imm = decode(inst)
   local s, t = R:get(rs), R:get(rt)
   local t = t % 0x20
   local d = B.sll(B.tobits(s), t)
   R:set(rd, d)
end



local function do_sra(inst, R) 
   local op, rs, rt, rd, sa, fun, imm = decode(inst)
   local s = R:get(rs)
   local d = B.sra(B.tobits(s), sa)
   R:set(rd, d)
end



local function do_srl(inst, R) 
   local op, rs, rt, rd, sa, fun, imm = decode(inst)
   local s = R:get(rs)
   local d = B.srl(B.tobits(s), sa)
   R:set(rd, d)
end



local function do_srlv(inst, R) 
   local op, rs, rt, rd, sa, fun, imm = decode(inst)
   local s, t = R:get(rs), R:get(rt)
   local t = t % 0x20
   local d = B.srl(B.tobits(s), t)
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
   local s, t = B.tobits(s), B.tobits(t)
   local d = B.tonum(B.bxor(s, t))
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

local function do_bgez(inst, R)
   local offset = B.sub_tonum_se(inst, 15, 0) * 4
   local rs = B.sub_tonum(inst, 25, 21)
   if R:get(rs) >= 0 then
      local pc = R:get(R.PC) + 4 + offset
      R:set(R.PC, pc)
      return true			-- notify the outer loop that a branch occurs
   end
end

local inst_handle_bz = {
   [0x01] = BZ_BGEZ,	-- fmt=0x01, BGEZ, branch on >= 0
   [0x11] = BZ_BGEZAL,	-- fmt=0x11, BGEZAL, BGEZ and link
   [0x00] = BZ_BLTZ,	-- fmt=0x00, BLTZ, branch on < 0
   [0x10] = BZ_BLTZAL,	-- fmt=0x10, BLTZAL, BLTZ and link
}


local function decode_itype(inst)
   local op = B.sub_tonum(inst, 31, 26)
   local rs = B.sub_tonum(inst, 25, 21)
   local rt = B.sub_tonum(inst, 20, 16)
   local imm = B.sub_tonum_se(inst, 15, 0) -- sign extended

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
   local s = B.tobits(R:get(rs))
   local imm = B.sub(inst, 15, 0)
   local t = B.tonum(B.band(s, imm))
   R:set(rt, t)
end


local function do_ori(inst, dcache, R)
   local op, rs, rt = decode_itype(inst)
   local s = B.tobits(R:get(rs))
   local imm = B.sub(inst, 15, 0)
   local t = B.tonum(B.bor(s, imm))
   R:set(rt, t)
end


local function do_xori(inst, dcache, R)
   local op, rs, rt = decode_itype(inst)
   local s = B.tobits(R:get(rs))
   local imm = B.sub(inst, 15, 0)
   local t = B.tonum(B.bxor(s, imm))
   R:set(rt, t)
end


local function do_slti(inst, dcache, R)
   local op, rs, rt, imm = decode_itype(inst)
   local immu = B.tonum(B.tobits(imm))
   local su   = B.tonum(B.tobits(R:get(rs)))
   local t = su < immu and 1 or 0
   R:set(rt, t)
end


local function do_beq(inst, dcache, R)
   local op, rs, rt, imm = decode_itype(inst)
   local s = R:get(rs)
   local t = R:get(rt)
   if s == t then
      R:set(R.PC, R:get(R.PC) + imm * 4)
      return true
   end
end


local function do_bgtz(inst, dcache, R)
   local op, rs, rt, imm = decode_itype(inst)
   local s = R:get(rs)
   if s > 0 then
      R:set(R.PC, R:get(R.PC) + imm * 4)
      return true
   end
end


local function do_blez(inst, dcache, R)
   local op, rs, rt, imm = decode_itype(inst)
   local s = R:get(rs)
   if s <= 0 then
      R:set(R.PC, R:get(R.PC) + imm * 4)
      return true
   end
end


local function do_blez(inst, dcache, R)
   local op, rs, rt, imm = decode_itype(inst)
   local s = R:get(rs)
   if s <= 0 then
      R:set(R.PC, R:get(R.PC) + imm * 4)
      return true
   end
end


local function do_bne(inst, dcache, R)
   local op, rs, rt, imm = decode_itype(inst)
   local s = R:get(rs)
   local t = R:get(rt)
   if s ~= t then
      R:set(R.PC, R:get(R.PC) + imm * 4)
      return true
   end
end


local function do_j(inst, dcache, R)
   local instr_index = B.sub(inst, 25, 0)
   local pc_head = B.sub(B.tobits(R:get(R.PC)), 31, 28)
   local target = B.tonum(B.concate(pc_head, instr_index)) * 4

   R:set(R.PC, target)
   return true
end


local function do_jal(inst, dcache, R)
   local instr_index = B.sub(inst, 25, 0)
   local pc_head = B.sub(R:get(R.PC), 31, 28)
   local target = B.tonum(B.concate(pc_head, instr_index)) * 4

   R:set(31, R:get(R.PC)+8)	-- save return address
   R:set(R.PC, target)
   return true
end

local function do_lb(inst, dcache, R)
   local op, base, rt, offset = decode_itype(inst)
   local vbase = R:get(base)
   local vaddr = offset + R:get(base)
   -- TODO address translation from virtual addr to physical addr
   local vword = dcache:rd(vaddr)
   -- TODO distinguish big endian and littlen endian, now assuming little endian
   local off = (vaddr % 4) * 8
   local vbyte = B.sub_tonum_se(B.tobits(vword), off+7, off)
   
   R:set(rt, vbyte)
end


local function do_lbu(inst, dcache, R)
   local op, base, rt, offset = decode_itype(inst)
   local vbase = R:get(base)
   local vaddr = offset + R:get(base)
   -- TODO address translation from virtual addr to physical addr
   local vword = dcache:rd(vaddr)
   -- TODO distinguish big endian and littlen endian, now assuming little endian
   local off = (vaddr % 4) * 8
   local vbyte = B.sub_tonum(B.tobits(vword), off+7, off)

   R:set(rt, vbyte)
end


local function do_lh(inst, dcache, R)
   local op, base, rt, offset = decode_itype(inst)
   local vbase = R:get(base)
   local vaddr = offset + R:get(base)
   if vaddr % 2 ~= 0 then
      exception("address_error")
   end
   -- TODO address translation from virtual addr to physical addr
   local vword = dcache:rd(vaddr)
   -- TODO distinguish big endian and littlen endian, now assuming little endian
   local off = (vaddr % 2) * 16
   local vhalfw = B.sub_tonum_se(B.tobits(vword), off+15, off)

   R:set(rt, vhalfw)
end


local function do_lhu(inst, dcache, R)
   local op, base, rt, offset = decode_itype(inst)
   local vbase = R:get(base)
   local vaddr = offset + R:get(base)
   if vaddr % 2 ~= 0 then
      exception("address_error")
   end
   -- TODO address translation from virtual addr to physical addr
   local vword = dcache:rd(vaddr)
   -- TODO distinguish big endian and littlen endian, now assuming little endian
   local off = (vaddr % 2) * 16
   local vhalfw = B.sub_tonum(B.tobits(vword), off+15, off)

   R:set(rt, vhalfw)
end


local function do_lui(inst, dcache, R)
   --local op, base, rt, imm = decode_itype(inst)
   local rt = B.sub_tonum(inst, 20, 26)
   local imm = B.sll(B.sub(inst, 15, 0), 16)
   R:set(rt, imm)
end


local function do_lw(inst, dcache, R)
   local op, base, rt, offset = decode_itype(inst)
   local vbase = R:get(base)
   local vaddr = offset + R:get(base)
   if vaddr % 4 ~= 0 then
      exception("address_error")
   end
   -- TODO address translation from virtual addr to physical addr
   local vword = dcache:rd(vaddr)

   R:set(rt, vword)
end


local function do_sb(inst, dcache, R)
   local op, base, rt, offset = decode_itype(inst)
   local vbase = R:get(base)
   local vaddr = offset + R:get(base)
   -- TODO address translation from virtual addr to physical addr
   local vword = dcache:rd(vaddr)
   -- TODO distinguish big endian and littlen endian, now assuming little endian
   local bytesel = (vaddr % 4) * 8
   local byte_bits = B.sub(B.tobits(R:get(rt)), bytesel+7, bytesel)
   local word_bits = B.tobits(vword)
   local new_word = B.concate(B.concate(
				   B.sub(word_bits, 31, byetsel+8), 
				   byte_bits), 
				B.sub(word_bits, bytesel-1, 0))
   
   dcache:wr(vaddr, B.tonum(new_word))
end


local function do_sh(inst, dcache, R)
   local op, base, rt, offset = decode_itype(inst)
   local vbase = R:get(base)
   local vaddr = offset + R:get(base)
   if vaddr % 2 ~= 0 then 
      exception("address_error")
   end
   -- TODO address translation from virtual addr to physical addr
   local vword = dcache:rd(vaddr)
   -- TODO distinguish big endian and littlen endian, now assuming little endian
   local bytesel = (vaddr % 2) * 16
   local byte_bits = B.sub(B.tobits(R:get(rt)), bytesel+15, bytesel)
   local word_bits = B.tobits(vword)
   local new_word = B.concate(B.concate(
				   B.sub(word_bits, 31, byetsel+16), 
				   byte_bits), 
				B.sub(word_bits, bytesel-1, 0))
   
   dcache:wr(vaddr, B.tonum(new_word))
end


local function do_sw(inst, dcache, R)
   local op, base, rt, offset = decode_itype(inst)
   local vbase = R:get(base)
   local vaddr = offset + R:get(base)
   if vaddr % 4 ~= 0 then 
      exception("address_error")
   end
   
   dcache:wr(vaddr, R:get(rt))
end


local inst_handle = {
   [0x08]  = do_addi,		-- add immediate with overflow  
   [0x09]  = do_addiu,		-- add immediate no overflow  
   [0x0C]  = do_andi,		-- bitwise and immediate  
   [0x0D]  = do_ori,		-- bitwise or immediate  
   [0x0E]  = do_xori,		-- bitwise exclusive or immediate  

   [0x0A]  = do_slti,	      -- set on less than immediate  
   [0x0B]  = do_sltiu,	      -- set on less than immediate unsigned  FIXME WTF?

   [0x04]  = do_beq,		-- branch on equal  

   [0x07]  = do_bgtz,		-- branch if $s > 0  
   [0x06]  = do_blez,		-- branch if $s <= 0  
   [0x05]  = do_bne,		-- branch if $s != $t  
   [0x02]  = do_j,		-- jump  
   [0x03]  = do_jal,		-- jump and link  

   [0x20]  = do_lb,		-- load byte  
   [0x24]  = do_lbu,		-- load byte unsigned  
   [0x21]  = do_lh,		--   
   [0x25]  = do_lhu,		--   
   [0x0F]  = do_lui,		-- load upper immediate  
   [0x23]  = do_lw,		-- load word  
   [0x31]  = do_LWC1,		-- load word  to Float Point TODO ...
   [0x28]  = do_sb,		-- store byte  
   [0x29]  = do_sh,		--   
   [0x2B]  = do_sw,		-- store word  
   [0x39]  = do_SWC1,		-- store word with Float Point TODO ...
}


local function exec_inst(R, inst, icache, dcache)
   local op = B.sub_tonum(inst, 31, 26)
   LOGD('OP = ', op)
   local branch_taken = false
   if op == 0 then
      -- R type
      local func = B.sub_tonum(inst, 5, 0)
      local h = inst_handle_rtype[func]
      branch_taken = h(inst, R)
   elseif op == 1 then
      -- BZ
      local fmt = B.sub_tonum(inst, 20, 16)
      local h = inst_handle_bz[fmt]
      branch_taken = h(inst, R)
   else
      local h = inst_handle[op]
      branch_taken = h(inst, dcache, R)
   end

   return branch_taken

end

local MAX_RUN = 120000

local function loop(R, icache, dcache)
   local run_cnt = 0
   while true do
      LOGD('---------------')
      LOGD('PC =', R:get(R.PC))
      local pc = R:get(R.PC)
      local inst = B.tobits(icache:rd(pc))
      if not inst then break end
      local branch_taken = exec_inst(R, inst, icache, dcache)
      LOGD(string.format("I = 0x%x", icache:rd(pc)), branch_taken and 'B' or '')

      if not branch_taken then
	 pc = pc + 4
	 R:set(R.PC, pc)
      else
	 -- execute the instruction in the branch delay slot
	 LOGD('PC =', R:get(R.PC))
	 local inst = B.tobits(icache:rd( pc + 4 ))
	 exec_inst(R, inst, icache, dcache)
      end

      if run_cnt > MAX_RUN then break end
      run_cnt = run_cnt + 1
   end
end


local init_icache = {
   [0] = 0x20090002,		-- addi $t1, $zero, 2
   0x812A0003,			-- lb   $t2, 3($t1)
   --0x1925FFF8,			-- blez $t1, -8
   0x08000000,			-- j 0
   0x812A0003,			-- lb   $t2, 3($t1)
}

local ic = icache.init(init_icache)
local dc = dcache.init()
local R  = mips_register.init()


local x = os.clock()

loop(R, ic, dc)

print(string.format("elapsed time: %.2f\n", os.clock() - x))

