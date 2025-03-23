// patch_instructions (fix outstanding problems)
//    x86int -> x86int

// (let ([a 42])
//   (let ([b a])
//     b))
//
// start:
// movq $42, -8(%rbp)
// movq -8(%rbp), -16(%rbp)
// movq -16(%rbp), %rax
// jmp conclusion
//
// start:
// movq $42, -8(%rbp)
// movq -8(%rbp), %rax
// movq %rax, -16(%rbp)
// movq -16(%rbp), %rax
// jmp conclusion

import gleam/dict
import gleam/list
import langs/x86_int as x86

pub fn patch_instructions(input: x86.X86Program) -> x86.X86Program {
  input.body
  |> dict.map_values(fn(_, block) {
    block.body
    |> patch_instructions_block
    |> x86.Block
  })
  |> x86.X86Program
}

fn patch_instructions_block(instrs: List(x86.Instr)) -> List(x86.Instr) {
  list.flat_map(instrs, patch_instruction)
}

fn patch_instruction(instr: x86.Instr) -> List(x86.Instr) {
  case instr {
    // NOTE: this will not work if the register being dereferenced is RAX
    x86.Movq(x86.Deref(_, _) as a, x86.Deref(_, _) as b) -> [
      x86.Movq(a, x86.Reg(x86.Rax)),
      x86.Movq(x86.Reg(x86.Rax), b),
    ]
    other -> [other]
  }
}
