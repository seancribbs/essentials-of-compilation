// assign_homes (replaces variables with registers or stack locations)
//    x86var -> x86int
import gleam/dict
import gleam/list
import langs/x86_int as x86
import langs/x86_var as var

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
    var.Deref(reg, off) -> #(homes, x86.Deref(translate_reg(reg), off))
    var.Imm(i) -> #(homes, x86.Imm(i))
    var.Reg(reg) -> #(homes, x86.Reg(translate_reg(reg)))
    var.Var(v) -> assign_home_for_var(homes, v)
  }
}

fn translate_reg(input: var.Register) -> x86.Register {
  case input {
    var.R11 -> x86.R11
    var.R10 -> x86.R10
    var.R12 -> x86.R12
    var.R13 -> x86.R13
    var.R14 -> x86.R14
    var.R15 -> x86.R15
    var.R8 -> x86.R8
    var.R9 -> x86.R9
    var.Rax -> x86.Rax
    var.Rbp -> x86.Rbp
    var.Rbx -> x86.Rbx
    var.Rcx -> x86.Rcx
    var.Rdi -> x86.Rdi
    var.Rdx -> x86.Rdx
    var.Rsi -> x86.Rsi
    var.Rsp -> x86.Rsp
  }
}

fn assign_home_for_var(homes: Homes, name: String) -> #(Homes, x86.Arg) {
  case dict.get(homes.homes, name) {
    Error(_) -> {
      let new_offset = homes.offset - 8
      let arg = x86.Deref(x86.Rbp, new_offset)
      #(Homes(new_offset, dict.insert(homes.homes, name, arg)), arg)
    }
    Ok(arg) -> #(homes, arg)
  }
}
