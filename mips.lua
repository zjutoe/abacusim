require 'bit'
require 'icache'
require 'dcache'


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