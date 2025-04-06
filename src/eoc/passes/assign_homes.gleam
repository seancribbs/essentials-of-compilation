// assign_homes (replaces variables with registers or stack locations)
//    x86var -> x86int
import eoc/langs/x86_base.{Rbp}
import eoc/langs/x86_int as x86
import eoc/langs/x86_var as var
import gleam/dict
import gleam/list

pub fn assign_homes(input: var.X86Program) -> x86.X86Program {
  let blocks =
    dict.map_values(input.body, fn(_, block) {
      let #(instrs, frame_size) = assign_homes_block(block.body)
      x86.Block(instrs, frame_size)
    })
  x86.X86Program(blocks)
}

type Homes {
  Homes(offset: Int, homes: dict.Dict(String, x86.Arg))
}

// movq $42, a
// movq a, b
// movq b, %rax
//
// movq $42, -8(%rbp)
// movq -8(%rbp), -16(%rbp)
// movq -16(%rbp), %rax

fn assign_homes_block(input: List(var.Instr)) -> #(List(x86.Instr), Int) {
  // String => Arg
  let init = #(Homes(0, dict.new()), [])
  let #(homes, instrs) =
    list.fold(input, init, fn(acc, instr) {
      let #(homes, instrs) = acc
      let #(new_homes, new_instr) = assign_homes_instr(homes, instr)
      #(new_homes, [new_instr, ..instrs])
    })
  #(list.reverse(instrs), -homes.offset)
}

fn assign_homes_instr(homes: Homes, instr: var.Instr) -> #(Homes, x86.Instr) {
  case instr {
    var.Addq(a, b) -> {
      let #(homes_a, new_a) = assign_home_for_arg(homes, a)
      let #(homes_b, new_b) = assign_home_for_arg(homes_a, b)
      #(homes_b, x86.Addq(new_a, new_b))
    }
    var.Callq(label, arity) -> #(homes, x86.Callq(label, arity))
    var.Jmp(loc) -> #(homes, x86.Jmp(loc))
    var.Movq(a, b) -> {
      let #(homes_a, new_a) = assign_home_for_arg(homes, a)
      let #(homes_b, new_b) = assign_home_for_arg(homes_a, b)
      #(homes_b, x86.Movq(new_a, new_b))
    }
    var.Negq(a) -> {
      let #(homes_a, new_a) = assign_home_for_arg(homes, a)
      #(homes_a, x86.Negq(new_a))
    }
    var.Popq(a) -> {
      let #(homes_a, new_a) = assign_home_for_arg(homes, a)
      #(homes_a, x86.Popq(new_a))
    }
    var.Pushq(a) -> {
      let #(homes_a, new_a) = assign_home_for_arg(homes, a)
      #(homes_a, x86.Pushq(new_a))
    }
    var.Retq -> #(homes, x86.Retq)
    var.Subq(a, b) -> {
      let #(homes_a, new_a) = assign_home_for_arg(homes, a)
      let #(homes_b, new_b) = assign_home_for_arg(homes_a, b)
      #(homes_b, x86.Subq(new_a, new_b))
    }
  }
}

fn assign_home_for_arg(homes: Homes, arg: var.Arg) -> #(Homes, x86.Arg) {
  case arg {
    // var.Deref(reg, off) -> #(homes, x86.Deref(reg, off))
    var.Imm(i) -> #(homes, x86.Imm(i))
    var.Reg(reg) -> #(homes, x86.Reg(reg))
    var.Var(v) -> assign_home_for_var(homes, v)
  }
}

fn assign_home_for_var(homes: Homes, name: String) -> #(Homes, x86.Arg) {
  case dict.get(homes.homes, name) {
    Error(_) -> {
      let new_offset = homes.offset - 8
      let arg = x86.Deref(Rbp, new_offset)
      #(Homes(new_offset, dict.insert(homes.homes, name, arg)), arg)
    }
    Ok(arg) -> #(homes, arg)
  }
}
