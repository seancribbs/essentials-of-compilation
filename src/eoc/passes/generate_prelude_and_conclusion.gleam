import eoc/langs/x86_base.{Rbp, Rsp}
import eoc/langs/x86_callq
import eoc/langs/x86_def_callq as x86
import gleam/dict
import gleam/list
import gleam/set

pub fn generate_prelude_and_conclusion(
  input: x86.X86Program,
) -> x86_callq.X86Program {
  input.defs
  |> list.fold(dict.new(), fn(acc, def) {
    dict.merge(acc, generate_prelude_and_conclusion_definition(def))
  })
  |> x86_callq.X86Program()
}


pub fn generate_prelude_and_conclusion_definition(
  input: x86.Definition,
) -> dict.Dict(String, x86_callq.Block) {
  let alignment = compute_frame_alignment(input)
  let saved_regs = get_saved_registers(input)
  let prelude =
    generate_prelude(
      alignment,
      saved_regs,
      input.root_stack_size,
      input.label == "main",
    )
  let conclusion_name = input.label <> "_conclusion"
  let conclusion =
    generate_conclusion(alignment, saved_regs, input.root_stack_size)
    |> list.flat_map(translate_instr(_, []))

  input.blocks
  |> dict.map_values(fn(block_name, block) {
    case block_name == input.label {
      False ->
        x86_callq.Block(
          list.flat_map(block.body, translate_instr(_, conclusion)),
          False,
        )
      True ->
        x86_callq.Block(
          list.flat_map(list.append(prelude, block.body), translate_instr(
            _,
            conclusion,
          )),
          True,
        )
    }
  })
  |> maybe_inject_conclusion_block(conclusion, conclusion_name)
}

fn maybe_inject_conclusion_block(
  blocks: dict.Dict(String, x86_callq.Block),
  conclusion: List(x86_callq.Instr),
  conclusion_name: String,
) -> dict.Dict(String, x86_callq.Block) {
  let needs_conclusion =
    dict.fold(blocks, False, fn(acc, _, block) {
      has_jmp_to_conclusion(block, conclusion_name) || acc
    })

  case needs_conclusion {
    True ->
      dict.insert(
        blocks,
        conclusion_name,
        x86_callq.Block(list.append(conclusion, [x86_callq.Retq]), False),
      )
    False -> blocks
  }
}

fn has_jmp_to_conclusion(
  block: x86_callq.Block,
  conclusion_name: String,
) -> Bool {
  list.any(block.body, fn(i) {
    case i {
      x86_callq.Jmp(label) | x86_callq.JmpIf(_, label) -> {
        label == conclusion_name
      }
      _ -> False
    }
  })
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

fn compute_frame_alignment(input: x86.Definition) -> Int {
  // Add one because we always save %rbp!!!
  let saved_regs = set.size(input.used_callee) + 1
  // A= align(8S + 8C) – 8C
  align(8 * input.stack_vars + 8 * saved_regs) - { 8 * saved_regs }
}

fn get_saved_registers(input: x86.Definition) -> List(x86_base.Register) {
  set.to_list(input.used_callee)
}

// Prelude
// - [x] push rbp, move to rsp
// - [x] push callee saved registers
// - [x] move rsp down for alignment
// - [x] "main" does gc initialization before moving r15
// - [x] move root stack pointer r15 up by the size of the root-stack frame for this function
// - [-] jump to the start block (NOT DOING, just prepending the prelude)
fn generate_prelude(
  alignment: Int,
  registers: List(x86_base.Register),
  root_stack_slots: Int,
  init_gc: Bool,
) -> List(x86.Instr) {
  let pushes = list.map([Rbp, ..registers], fn(r) { x86.Pushq(x86.Reg(r)) })
  let aligner = case alignment {
    0 -> []
    _ -> [x86.Subq(x86.Imm(alignment), x86.Reg(Rsp))]
  }

  let initialize = case root_stack_slots {
    0 -> []
    slots ->
      list.append(
        case init_gc {
          True -> [
            x86.Movq(x86.Imm(65_536), x86.Reg(x86_base.Rdi)),
            x86.Movq(x86.Imm(65_536), x86.Reg(x86_base.Rsi)),
            x86.Callq("initialize", 2),
            x86.Movq(x86.Global("rootstack_begin"), x86.Reg(x86_base.R15)),
          ]
          False -> []
        },
        zero_out_rootstack_slots(
          [x86.Addq(x86.Imm({ 8 * slots }), x86.Reg(x86_base.R15))],
          slots,
        ),
      )
  }

  pushes
  |> list.append([x86.Movq(x86.Reg(Rsp), x86.Reg(Rbp))])
  |> list.append(aligner)
  |> list.append(initialize)
}

// Conclusion:
// - [X] Move the root stack pointer back down by the size of the frame
// - [X] Move the stack pointer back up past the regular spills
// - [X] Restore callee-saved registers by popping
// - [X] Restore rbp by popping
// - [-] Return with retq (NOT DOING, happens outside this function, depending on whether the function only tailcalls)
fn generate_conclusion(
  alignment: Int,
  registers: List(x86_base.Register),
  root_stack_slots: Int,
) -> List(x86.Instr) {
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

  root_stack_pop
  |> list.append(aligner)
  |> list.append(pops)
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

fn translate_instr(
  instr: x86.Instr,
  conclusion: List(x86_callq.Instr),
) -> List(x86_callq.Instr) {
  case instr {
    x86.Addq(a:, b:) -> [x86_callq.Addq(translate_arg(a), translate_arg(b))]
    x86.Subq(a:, b:) -> [x86_callq.Subq(translate_arg(a), translate_arg(b))]
    x86.Negq(a:) -> [x86_callq.Negq(translate_arg(a))]
    x86.Movq(a:, b:) -> [x86_callq.Movq(translate_arg(a), translate_arg(b))]
    x86.Pushq(a:) -> [x86_callq.Pushq(translate_arg(a))]
    x86.Popq(a:) -> [x86_callq.Popq(translate_arg(a))]
    x86.Callq(label:, arity: _) -> [x86_callq.Callq(label:)]
    x86.IndirectCallq(a:, arity: _) -> [
      x86_callq.IndirectCallq(translate_arg(a)),
    ]
    x86.TailJmp(label:, arity: _) ->
      list.append(conclusion, [x86_callq.IndirectJmp(translate_arg(label))])
    x86.Leaq(a:, b:) -> [x86_callq.Leaq(translate_arg(a), translate_arg(b))]
    x86.Retq -> [x86_callq.Retq]
    x86.Jmp(label:) -> [x86_callq.Jmp(label:)]
    x86.Xorq(a:, b:) -> [x86_callq.Xorq(translate_arg(a), translate_arg(b))]
    x86.Cmpq(a:, b:) -> [x86_callq.Cmpq(translate_arg(a), translate_arg(b))]
    x86.Set(cmp:, arg:) -> [x86_callq.Set(cmp:, arg:)]
    x86.Movzbq(a:, b:) -> [x86_callq.Movzbq(a, translate_arg(b))]
    x86.JmpIf(cmp:, label:) -> [x86_callq.JmpIf(cmp:, label:)]
    x86.Andq(a:, b:) -> [x86_callq.Andq(translate_arg(a), translate_arg(b))]
    x86.Sarq(a:, b:) -> [x86_callq.Sarq(translate_arg(a), translate_arg(b))]
  }
}

fn translate_arg(a: x86.Arg) -> x86_callq.Arg {
  case a {
    x86.Imm(value:) -> x86_callq.Imm(value)
    x86.Reg(reg:) -> x86_callq.Reg(reg)
    x86.Deref(reg:, offset:) -> x86_callq.Deref(reg, offset)
    x86.Global(label:) -> x86_callq.Global(label)
    x86.Var(name: _) -> panic as "variable was not allocated to register"
  }
}
