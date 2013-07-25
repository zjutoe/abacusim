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



local function exception(error, R, err)
   print ("exception:")
   R:set(R.OVERFLOW, 1)
   if error == "address_error" then
      print(string.format("misaligned address 0x%x", err))
   elseif error == "syscall" then
      print(string.format("syscall 0x%x not supported", err))
   end

   for i=0, R.MAX do
      print(R:dump(i))
   end

   -- print(string.format("v0:0x%x", R:get(R.v0)))
   -- print(string.format("v1:0x%x", R:get(R.v1)))
   -- print(string.format("a0:0x%x", R:get(R.a0)))
   -- print(string.format("a1:0x%x", R:get(R.a1)))
   -- print(string.format("a2:0x%x", R:get(R.a2)))
   -- print(string.format("a3:0x%x", R:get(R.a3)))
   -- print(string.format("gp:0x%x", R:get(R.gp)))
   -- print(string.format("sp:0x%x", R:get(R.sp)))
   -- print(string.format("fp:0x%x", R:get(R.sp)))
   -- print(string.format("ra:0x%x", R:get(R.sp)))
   
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

   LOGD(string.format("ADD s:%s t:%s d:%s", R:dump(rs), R:dump(rt), R:dump(rd)))
end



local function do_addu(inst, R) 
   local op, rs, rt, rd, sa, fun, imm = decode(inst)
   local s, t = R:get(rs), R:get(rt)

   local d = s + t
   R:set(rd, d)

   LOGD(string.format("ADDU s:%s t:%s d:%s", R:dump(rs), R:dump(rt), R:dump(rd)))
   --LOGD(string.format("ADDU $%d:%x $%d:%x $%d:%x", rs, R:get(rs), rt, R:get(rt), rd, R:get(rd)))
end



local function do_and(inst, R)
   local op, rs, rt, rd, sa, fun, imm = decode(inst)
   local s, t = R:get(rs), R:get(rt)

   local d = B.tonum(B.band(B.tobits(s), B.tobits(t)))
   R:set(rd, d)

   LOGD(string.format("AND s:%s t:%s d:%s", R:dump(rs), R:dump(rs), R:dump(rs)))
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

   LOGD(string.format("DIV s:%s t:%s hi:%s lo:%s", R:dump(rs), R:dump(rt), R:dump(R.HI), R:dump(R.LO)))
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

   LOGD(string.format("DIVU s:%s t:%s hi:%s lo:%s", R:dump(rs), R:dump(rt), R:dump(R.HI), R:dump(R.LO)))
end



local function do_mfhi(inst, R) 
   local op, rs, rt, rd, sa, fun, imm = decode(inst)

   local hi = R:get(R.HI)
   R:set(rd, hi)

   LOGD(string.format("MFHI d:%s hi:%s", R:dump(rd), R:dump(R.HI)))
end



local function do_mflo(inst, R) 
   local op, rs, rt, rd, sa, fun, imm = decode(inst)

   local lo = R:get(R.LO)
   R:set(rd, lo)

   LOGD(string.format("MFLO d:%s lo:%s", R:dump(rd), R:dump(R.LO)))
end



local function do_mult(inst, R) 
   local op, rs, rt, rd, sa, fun, imm = decode(inst)
   local s, t = R:get(rs), R:get(rt)
   local d = s * t
   local lo = d % 0x100000000
   local hi = math.floor(d / 0x100000000)
   R:set(R.HI, hi)
   R:set(R.LO, lo)

   LOGD(string.format("MULT s:%s t:%s hi:%s lo:%s", R:dump(rs), R:dump(rt), R:dump(R.HI), R:dump(R.LO)))
end



local function do_multu(inst, R) 
   local op, rs, rt, rd, sa, fun, imm = decode(inst)
   local s, t = R:getu(rs), R:getu(rt)
   local d = s * t
   local lo = d % 0x100000000
   local hi = math.floor(d / 0x100000000)
   R:set(R.HI, hi)
   R:set(R.LO, lo)

   LOGD(string.format("MULTU s:%s t:%s hi:%s lo:%s", R:dump(rs), R:dump(rt), R:dump(R.HI), R:dump(R.LO)))
end


local function do_mul(inst, dcache, R) 
   local op, rs, rt, rd, sa, fun, imm = decode(inst)
   local s, t = R:get(rs), R:get(rt)
   local d = s * t
   local lo = d % 0x100000000
   R:set(rd, lo)

   LOGD(string.format("MUL s:%s t:%s d:%s", R:dump(rs), R:dump(rt), R:dump(rd)))
end


local function do_or(inst, R) 
   local op, rs, rt, rd, sa, fun, imm = decode(inst)
   local s, t = R:get(rs), R:get(rt)
   local s, t = B.tobits(s), B.tobits(t)
   local d = B.tonum(B.bor(s, t))
   R:set(rd, d)

   LOGD(string.format("OR s:%s t:%s d:%s", R:dump(rs), R:dump(rt), R:dump(rd)))
end


local function do_slt(inst, R) 
   local op, rs, rt, rd, sa, fun, imm = decode(inst)
   local s, t = R:get(rs), R:get(rt)
   local d = s < t and 1 or 0
   R:set(rd, d)

   LOGD(string.format("SLT s:%s t:%s d:%s", R:dump(rs), R:dump(rt), R:dump(rd)))
end



local function do_sltu(inst, R) 
   local op, rs, rt, rd, sa, fun, imm = decode(inst)
   local s, t = R:getu(rs), R:getu(rt)
   local d = s < t and 1 or 0
   R:set(rd, d)

   LOGD(string.format("SLTU s:%s t:%s d:%s", R:dump(rs), R:dump(rt), R:dump(rd)))
end



local function do_sll(inst, R) 
   local op, rs, rt, rd, sa, fun, imm = decode(inst)
   local t = R:get(rt)
   local d = B.tonum(B.sll(B.tobits(t), sa))
   R:set(rd, d)

   LOGD(string.format("SLL t:%s sa:%x d:%s", R:dump(rt), sa, R:dump(rd)))
end



local function do_sllv(inst, R) 
   local op, rs, rt, rd, sa, fun, imm = decode(inst)
   local s, t = R:get(rs), R:get(rt)
   local t = t % 0x20
   local d = B.sll(B.tobits(s), t)
   R:set(rd, d)

   LOGD(string.format("SLLV s:%s t:%s d:%s", R:dump(rs), R:dump(rt), R:dump(rd)))
end



local function do_sra(inst, R) 
   local op, rs, rt, rd, sa, fun, imm = decode(inst)
   local s = R:get(rs)
   local d = B.sra(B.tobits(s), sa)
   R:set(rd, d)

   LOGD(string.format("SRA s:%s imm:%x d:%s", R:dump(rs), imm, R:dump(rd)))
end



local function do_srl(inst, R) 
   local op, rs, rt, rd, sa, fun, imm = decode(inst)
   local s = R:get(rs)
   local d = B.srl(B.tobits(s), sa)
   R:set(rd, d)

   LOGD(string.format("SRL s:%s imm:%x d:%s", R:dump(rs), imm, R:dump(rd)))
end



local function do_srlv(inst, R) 
   local op, rs, rt, rd, sa, fun, imm = decode(inst)
   local s, t = R:get(rs), R:get(rt)
   local t = t % 0x20
   local d = B.srl(B.tobits(s), t)
   R:set(rd, d)

   LOGD(string.format("SRLV s:%s t:%s d:%s", R:dump(rs), R:dump(rt), R:dump(rd)))
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
      LOGD(string.format("SUB s:%s t:%s d:%s", R:dump(rs), R:dump(rt), R:dump(rd)))
   end
end



local function do_subu(inst, R) 
   local op, rs, rt, rd, sa, fun, imm = decode(inst)
   local s, t = R:getu(rs), R:getu(rt)

   local d = s - t
   R:set(rd, d)

   LOGD(string.format("SUBU s:%s t:%s d:%s", R:dump(rs), R:dump(rt), R:dump(rd)))
end

require "syscall"
local syscall = syscall.init()

local function do_syscall(inst, R) 
   local res = syscall.do_syscall(R)
   if res == -1 then 
      exception("syscall")
   end
   LOGD(string.format("syscall id:0x%x", R:get(R.v0)))
end


local function do_xor(inst, R) 
   local op, rs, rt, rd, sa, fun, imm = decode(inst)
   local s, t = R:get(rs), R:get(rt)
   local s, t = B.tobits(s), B.tobits(t)
   local d = B.tonum(B.bxor(s, t))
   R:set(rd, d)

   LOGD(string.format("XOR s:%s t:%s d:%s", R:dump(rs), R:dump(rt), R:dump(rd)))
end

local function do_jalr(inst, R)
   local rs = B.sub_tonum(inst, 25, 21)
   local rd = B.sub_tonum(inst, 15, 11)
   local tmp = R:get(rs)
   R:set(rd, R:get(R.PC)+8)
   R:set(R.PC, tmp)
   
   LOGD(string.format("JALR s:%s d:%s PC:%s", R:dump(rs), R:dump(rd), R:dump(R.PC)))
   return true
end

local function do_jr(inst, R)
   local rs = B.sub_tonum(inst, 25, 21)
   local tmp = R:get(rs)
   LOGD(string.format("jr: %x", tmp))
   R:set(R.PC, tmp)
   
   LOGD(string.format("JR s:%s PC:%s", R:dump(rs), R:dump(R.PC)))
   return true
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
   [0x00] = do_sll,	       -- shift left logical  -- [0x00] = do_noop, noop is "SLL $0 $0 0"
   [0x04] = do_sllv,	       -- shift left logical variable 
   [0x03] = do_sra,	       -- shift right arithmetic 
   [0x02] = do_srl,	       -- shift right logic  
   [0x06] = do_srlv,	       -- shift right logical variable 
   [0x22] = do_sub,	       -- sub signed 
   [0x23] = do_subu,	       -- sub unsigned    
   [0x26] = do_xor,	       -- bitwise exclusive or 
   [0x08] = do_jr,	       -- jump register
   [0x09] = do_jalr,	       -- jump and link register
   [0x0C] = do_syscall, -- system call FIXME system call is not R-type in theory?
}

local function do_bgez(inst, R)
   local offset = B.sub_tonum_se(inst, 15, 0) * 4
   local rs = B.sub_tonum(inst, 25, 21)
   if R:get(rs) >= 0 then
      local pc = R:get(R.PC) + 4 + offset
      R:set(R.PC, pc)
      LOGD(string.format("BGEZ s:%s offset:%d PC:%s", R:dump(rs), offset, R:dump(R.PC)))
      return true			-- notify the outer loop that a branch occurs
   end
   LOGD(string.format("BGEZ s:%s offset:%d PC:%s", R:dump(rs), offset, R:dump(R.PC)))
end

local function do_bltz(inst, R)
   local offset = B.sub_tonum_se(inst, 15, 0) * 4
   local rs = B.sub_tonum(inst, 25, 21)
   if R:get(rs) < 0 then
      local pc = R:get(R.PC) + 4 + offset
      R:set(R.PC, pc)
      LOGD(string.format("BLTZ s:%s offset:%d PC:%s", R:dump(rs), offset, R:dump(R.PC)))
      return true			-- notify the outer loop that a branch occurs
   end
   LOGD(string.format("BLTZ s:%s offset:%d PC:%s", R:dump(rs), offset, R:dump(R.PC)))
end


local function do_bgezal(inst, R)
   local offset = B.sub_tonum_se(inst, 15, 0) * 4
   local rs = B.sub_tonum(inst, 25, 21)
   if R:get(rs) >= 0 then
      local pc = R:get(R.PC) + 4 + offset
      R:set(R.PC, pc)
      R:set(R[31], pc+8)	-- TODO: give R[31] a name
      LOGD(string.format("BGEZAL s:%s offset:%d PC:%s", R:dump(rs), offset, R:dump(R.PC)))
      return true
   end
   LOGD(string.format("BGEZAL s:%s offset:%d PC:%s", R:dump(rs), offset, R:dump(R.PC)))
end


local inst_handle_bz = {
   [0x01] = do_bgez,	-- fmt=0x01, BGEZ, branch on >= 0
   [0x11] = do_bgezal,	-- fmt=0x11, BGEZAL, BGEZ and link
   [0x00] = do_bltz,	-- fmt=0x00, BLTZ, branch on < 0
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

   LOGD(string.format("ADDI s:%s t:%s imm:%x", R:dump(rs), R:dump(rt), imm))
end


local function do_addiu(inst, dcache, R)
   local op, rs, rt, imm = decode_itype(inst)
   local s = R:get(rs)
   local t = s + imm
   R:set(rt, t)

   LOGD(string.format("ADDIU s:%s t:%s imm:%x", R:dump(rs), R:dump(rt), imm))
end



local function do_andi(inst, dcache, R)
   local op, rs, rt = decode_itype(inst)
   local s = B.tobits(R:get(rs))
   local imm = B.sub(inst, 15, 0)
   local t = B.tonum(B.band(s, imm))
   R:set(rt, t)

   LOGD(string.format("ANDI s:%s t:%s imm:%x", R:dump(rs), R:dump(rt), imm))
end


local function do_ori(inst, dcache, R)
   local op, rs, rt = decode_itype(inst)
   local s = B.tobits(R:get(rs))
   local imm = B.sub(inst, 15, 0)
   local t = B.tonum(B.bor(s, imm))
   R:set(rt, t)

   LOGD(string.format("ORI s:%s t:%s imm:%x", R:dump(rs), R:dump(rt), imm))
end


local function do_xori(inst, dcache, R)
   local op, rs, rt = decode_itype(inst)
   local s = B.tobits(R:get(rs))
   local imm = B.sub(inst, 15, 0)
   local t = B.tonum(B.bxor(s, imm))
   R:set(rt, t)

   LOGD(string.format("XORI s:%s t:%s imm:%x", R:dump(rs), R:dump(rt), imm))
end


local function do_slti(inst, dcache, R)
   local op, rs, rt, imm = decode_itype(inst)
   local t = R:get(rs) < imm and 1 or 0
   R:set(rt, t)

   LOGD(string.format("SLTI s:%s t:%s imm:%x", R:dump(rs), R:dump(rt), imm))
end

local function do_sltiu(inst, dcache, R)
   local op, rs, rt, imm = decode_itype(inst)
   local immu = B.tonum(B.tobits(imm))
   local su   = B.tonum(B.tobits(R:get(rs)))
   local t = su < immu and 1 or 0
   R:set(rt, t)

   LOGD(string.format("SLTIU s:%s t:%s imm:%x", R:dump(rs), R:dump(rt), immu))
end


local function do_beq(inst, dcache, R)
   local op, rs, rt, imm = decode_itype(inst)
   local s = R:get(rs)
   local t = R:get(rt)
   if s == t then
      R:set(R.PC, R:get(R.PC) + imm * 4)
      LOGD(string.format("BEQ s:%s t:%s %s", R:dump(rs), R:dump(rt), R:dump(R.PC)))
      return true
   end
   LOGD(string.format("BEQ s:%s t:%s %s", R:dump(rs), R:dump(rt), R:dump(R.PC)))
end


local function do_bgtz(inst, dcache, R)
   local op, rs, rt, imm = decode_itype(inst)
   local s = R:get(rs)
   if s > 0 then
      R:set(R.PC, R:get(R.PC) + imm * 4)
      LOGD(string.format("BGTZ s:%s %s", R:dump(rs), R:dump(R.PC)))
      return true
   end
   LOGD(string.format("BGTZ s:%s %s", R:dump(rs), R:dump(R.PC)))
end


local function do_blez(inst, dcache, R)
   local op, rs, rt, imm = decode_itype(inst)
   local s = R:get(rs)
   if s <= 0 then
      R:set(R.PC, R:get(R.PC) + imm * 4)
      LOGD(string.format("BLEZ s:%s %s", R:dump(rs), R:dump(R.PC)))
      return true
   end
   LOGD(string.format("BLEZ s:%s %s", R:dump(rs), R:dump(R.PC)))
end


-- local function do_blez(inst, dcache, R)
--    local op, rs, rt, imm = decode_itype(inst)
--    local s = R:get(rs)
--    if s <= 0 then
--       R:set(R.PC, R:get(R.PC) + imm * 4)
--       LOGD(string.format("BLEZ $%d:%x $%d:%x t:%x imm:%x", rs, R:get(rs), rt, R:get(rt), t, imm))
--       return true
--    end
-- end


local function do_bne(inst, dcache, R)
   local op, rs, rt, imm = decode_itype(inst)
   local s = R:get(rs)
   local t = R:get(rt)
   if s ~= t then
      R:set(R.PC, R:get(R.PC) + imm * 4)
      LOGD(string.format("BEQ s:%s t:%s %s", R:dump(rs), R:dump(rt), R:dump(R.PC)))
      return true
   end
   LOGD(string.format("BEQ s:%s t:%s %s", R:dump(rs), R:dump(rt), R:dump(R.PC)))
end

local function do_ins(inst, dcache, R)
   local op, rs, rt, msb, lsb, fun, imm = decode(inst)
   local s, t = R:get(rs), R:get(rt)
   local bits2 = B.sub(B.tobits(s), msb-lsb, 0)
   local bits = B.tobits(t)
   local bits1 = B.sub(bits, 31, msb+1)
   local bits3 = B.sub(bits, lsb-1, 0)
   LOGD(string.format("INS s:%s t:%s msb:%x lsb:%x bits1:%x, bits2:%x, bits3:%x", 
		      R:dump(rs),
		      R:dump(rt),
		      msb, lsb,
		      B.tonum(bits1),
		      B.tonum(bits2),
		      B.tonum(bits3)))
   -- local tmp = B.concate(bits1, bits2)
   -- LOGD(B.tonum(tmp))
   -- local tmp = B.concate(tmp, bits3)
   -- LOGD(B.tonum(tmp))
   -- local t1 = B.tonum(tmp)
   local t1 = B.tonum( B.concate(B.concate(bits1, bits2), bits3) )

   R:set(rt, t1)
end

local function do_j(inst, dcache, R)
   local instr_index = B.sub(inst, 25, 0)
   local pc_head = B.sub(B.tobits(R:get(R.PC)), 31, 28)
   local target = B.tonum(B.concate(pc_head, instr_index)) * 4

   R:set(R.PC, target)

   LOGD(string.format("J %s", R:dump(R.PC)))
   return true
end


local function do_jal(inst, dcache, R)
   local instr_index = B.sub(inst, 25, 0)
   local pc_head = B.sub(B.tobits(R:get(R.PC)), 31, 28)
   local target = B.tonum(B.concate(pc_head, instr_index)) * 4

   R:set(31, R:get(R.PC)+8)	-- save return address
   R:set(R.PC, target)
   LOGD(string.format("JAL %s", R:dump(R.PC)))
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
   LOGD(string.format("LB addr:%x t:%s", vaddr, R:dump(rt)))
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
   LOGD(string.format("LBU addr:%x t:%s", vaddr, R:dump(rt)))
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
   LOGD(string.format("LH addr:%x t:%s", vaddr, R:dump(rt)))
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
   LOGD(string.format("LHU addr:%x t:%s", vaddr, R:dump(rt)))
end


local function do_lui(inst, dcache, R)
   --local op, base, rt, imm = decode_itype(inst)
   local rt = B.sub_tonum(inst, 20, 16)
   local imm = B.tonum(B.sll(B.sub(inst, 15, 0), 16))
   R:set(rt, imm)
   LOGD(string.format("LUI imm:%x t:%s", imm, R:dump(rt)))
end


local function do_lw(inst, dcache, R)
   local op, base, rt, offset = decode_itype(inst)
   local vbase = R:get(base)
   local vaddr = offset + R:get(base)
   if vaddr % 4 ~= 0 then
      exception("address_error", R, vaddr)
   end
   -- TODO address translation from virtual addr to physical addr
   local vword = dcache:rd(vaddr)

   R:set(rt, vword)
   LOGD(string.format("LW addr:%x t:%s base:%s offset:%x", vaddr, R:dump(rt), 
		      R:dump(base), offset))
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
   LOGD(string.format("SB addr:%x t:%s", vaddr, R:dump(rt)))
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
   LOGD(string.format("SH addr:%x t:%s", vaddr, R:dump(rt)))
end


local function do_sw(inst, dcache, R)
   local op, base, rt, offset = decode_itype(inst)
   local vbase = R:get(base)
   local vaddr = offset + R:get(base)
   if vaddr % 4 ~= 0 then 
      exception("address_error")
   end
   
   dcache:wr(vaddr, R:get(rt))
   LOGD(string.format("SH addr:%x t:%s", vaddr, R:dump(rt)))
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
   [0x1F]  = do_ins,		-- Inset Bit Field
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

   [0x1c]  = do_mul,		-- Multiply word to GPR, NOTE: not MULT
}


local function exec_inst(R, inst, icache, dcache)
   local op = B.sub_tonum(inst, 31, 26)
   local branch_taken = false
   if op == 0 then
      -- R type
      local func = B.sub_tonum(inst, 5, 0)
      -- LOGD("func = ", func)
      local h = inst_handle_rtype[func]
      branch_taken = h(inst, R)
   elseif op == 1 then
      -- BZ
      local fmt = B.sub_tonum(inst, 20, 16)
      LOGD("B:", fmt)
      local h = inst_handle_bz[fmt]
      branch_taken = h(inst, R)
   else
      local h = inst_handle[op]
      branch_taken = h(inst, dcache, R)
   end

   return branch_taken

end

local MAX_RUN = 200000

local function loop(R, icache, dcache)
   local run_cnt = 0
   while true do
      LOGD('---------------')
      local pc = R:get(R.PC)
      local inst = B.tobits(icache:rd(pc))
      if not inst then break end
      LOGD(string.format("%x : %08x", R:get(R.PC), icache:rd(pc)))

      local branch_taken = exec_inst(R, inst, icache, dcache)

      LOGD(branch_taken and 'B' or '')

      if not branch_taken then
	 pc = pc + 4
	 R:set(R.PC, pc)
      else
	 -- execute the instruction in the branch delay slot
	 LOGD(string.format('PC = %08x', R:get(R.PC)))
	 local inst = B.tobits(icache:rd( pc + 4 ))
	 exec_inst(R, inst, icache, dcache)
      end

      -- if run_cnt > MAX_RUN then break end
      run_cnt = run_cnt + 1
   end
end


local init_icache = {
   [0] = 0x20090002,		-- addi $t1, $zero, 2
   0x812A0003,			-- lb   $t2, 3($t1)
   0x812A0003,			-- lb   $t2, 3($t1)
   0x00210820,			-- add $1, $1, $1
   0x00210821, 			-- addu $1, $1, $1
   0x00210824, 			-- and
   0x00210018, 			-- mult
   0x08000000,			-- j 0
   0x812A0003,			-- lb   $t2, 3($t1)
}

local loadelf = require 'luaelf/loadelf'
local elf = loadelf.init()
local mem = elf.load(arg[1])

function mem.rd(self, addr)
   local v0 = self[addr]   or 0
   local v1 = self[addr+1] or 0
   local v2 = self[addr+2] or 0
   local v3 = self[addr+3] or 0
   if addr % 4 == 0 then
      -- TODO use ffi.bit to accelerate
      return v0 * 2^24 + v1 * 2^16 + v2 * 2^8 + v3
   else
      return nil		-- FIXME raise an exception?
   end
end

function mem.wr(self, addr, v)
   local v0 = self[addr]   or 0
   local v1 = self[addr+1] or 0
   local v2 = self[addr+2] or 0
   local v3 = self[addr+3] or 0
   if addr % 4 == 0 then
      -- TODO use ffi.bit to make it terse and fast
      local v3 = v % 0x100
      local r3 = (v - v3) / 0x100
      local v2 = r3 % 0x100
      local r2 = (r3 - v2) / 0x100
      local v1 = r2 % 0x100
      local r1 = (r2 - v1) / 0x100
      local v0 = r1 % 0x100
      self[addr], self[addr+1], self[addr+2], self[addr+3] = v0, v1, v2, v3
   else
      return nil		-- FIXME raise an exception?
   end
end

-- local ic = icache.init(mem)
-- local dc = dcache.init()
local ic = mem
local dc = mem
local R  = mips_register.init()

local ffi = require 'ffi'

-- function get_init_inst(mem)
--    do return 0x4001a4 end
--    for i, s in ipairs(mem.scns) do
--       if ffi.string(s.name) == "_init" then
-- 	 return tonumber(s.sh_addr)
--       end
--    end
-- end

local init_inst = mem.e_entry

if init_inst then
   LOGD(string.format("init: %x", init_inst))
   R:set(R.PC, init_inst)
   R:set(R.sp, 0x40800298)
   R:set(R.fp, 0x40800298)
end

local x = os.clock()

loop(R, ic, dc)

print(string.format("elapsed time: %.2f\n", os.clock() - x))

