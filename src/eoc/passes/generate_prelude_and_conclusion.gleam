import eoc/langs/x86_base.{Rbp, Rsp}
import eoc/langs/x86_global as x86
import gleam/dict
import gleam/list
import gleam/set

pub fn generate_prelude_and_conclusion(input: x86.X86Program) -> x86.X86Program {
  let alignment = compute_frame_alignment(input)
  let saved_regs = get_saved_registers(input)
  let main = generate_main(alignment, saved_regs, input.root_stack_size)
  let conclusion =
    generate_conclusion(alignment, saved_regs, input.root_stack_size)

  let body =
    input.body
    |> dict.insert("main", main)
    |> dict.insert("conclusion", conclusion)

  x86.X86Program(..input, body:)
}

// main:
//    pushq %rbp
//    movq  %rsp, %rbp
//    subq  $16, %rsp
//    jmp start
//
// conclusion:
//    addq  $16, %rsp
//    popq  %rbp
//    retq

fn align(bytes: Int) -> Int {
  case bytes % 16 {
    0 -> bytes
    _ -> { bytes / 16 + 1 } * 16
  }
}

fn compute_frame_alignment(input: x86.X86Program) -> Int {
  // Add one because we always save %rbp!!!
  let saved_regs = set.size(input.used_callee) + 1
  // A= align(8S + 8C) – 8C
  align(8 * input.stack_vars + 8 * saved_regs) - { 8 * saved_regs }
}

fn get_saved_registers(input: x86.X86Program) -> List(x86_base.Register) {
  set.to_list(input.used_callee)
}

fn generate_main(
  alignment: Int,
  registers: List(x86_base.Register),
  root_stack_slots: Int,
) -> x86.Block {
  let pushes = list.map([Rbp, ..registers], fn(r) { x86.Pushq(x86.Reg(r)) })
  let aligner = case alignment {
    0 -> []
    _ -> [x86.Subq(x86.Imm(alignment), x86.Reg(Rsp))]
  }

  let initialize = case root_stack_slots {
    0 -> []
    slots ->
      list.append(
        [
          x86.Movq(x86.Imm(65_536), x86.Reg(x86_base.Rdi)),
          x86.Movq(x86.Imm(65_536), x86.Reg(x86_base.Rsi)),
          x86.Callq("initialize", 2),
          x86.Movq(x86.Global("rootstack_begin"), x86.Reg(x86_base.R15)),
        ],
        zero_out_rootstack_slots(
          [x86.Addq(x86.Imm({ 8 * slots }), x86.Reg(x86_base.R15))],
          slots,
        ),
      )
  }

  let instrs =
    pushes
    |> list.append([x86.Movq(x86.Reg(Rsp), x86.Reg(Rbp))])
    |> list.append(aligner)
    |> list.append(initialize)
    |> list.append([x86.Jmp("start")])

  x86.Block(..x86.new_block(), body: instrs)
}

fn generate_conclusion(
  alignment: Int,
  registers: List(x86_base.Register),
  root_stack_slots: Int,
) -> x86.Block {
  let root_stack_pop = case root_stack_slots {
    0 -> []
    count -> [x86.Subq(x86.Imm(count * 8), x86.Reg(x86_base.R15))]
  }

  let pops =
    [Rbp, ..registers]
    |> list.map(fn(r) { x86.Popq(x86.Reg(r)) })
    |> list.reverse()

  let aligner = case alignment {
    0 -> []
    _ -> [x86.Addq(x86.Imm(alignment), x86.Reg(Rsp))]
  }

  let instrs =
    root_stack_pop
    |> list.append(aligner)
    |> list.append(pops)
    |> list.append([x86.Retq])

  x86.Block(..x86.new_block(), body: instrs)
}

fn zero_out_rootstack_slots(acc: List(x86.Instr), count: Int) {
  case count {
    0 -> acc
    _ ->
      zero_out_rootstack_slots(
        [
          x86.Movq(x86.Imm(0), x86.Deref(x86_base.R15, { count - 1 } * 8)),
          ..acc
        ],
        count - 1,
      )
  }
}
