import eoc/langs/l_while as l
import eoc/langs/l_while_get as lg
import eoc/passes/parse.{parse, tokens}
import eoc/passes/uncover_get.{collect_set_bang, uncover_get}
import gleam/set
import gleeunit/should
// fn parsed(input: String) -> l.Program {
//   input
//   |> tokens
//   |> should.be_ok
//   |> parse
//   |> should.be_ok
// }

// pub fn uncover_get_test() {
//   let p =
//     "
//   (let ([x 2])
//     (let ([y 0])
//       (+ y (+ x (begin (set! x 40) x)))))
//   "
//     |> parsed

//   let p2 =
//     lg.Program(lg.Let(
//       "x",
//       lg.Int(2),
//       lg.Let(
//         "y",
//         lg.Int(0),
//         lg.Prim(lg.Plus(
//           lg.Var("y"),
//           lg.Prim(lg.Plus(
//             lg.GetBang("x"),
//             lg.Begin([lg.SetBang("x", lg.Int(40))], lg.GetBang("x")),
//           )),
//         )),
//       ),
//     ))

//   p |> uncover_get |> should.equal(p2)
// }

// pub fn collect_set_bang_test() {
//   let p =
//     "
//   (let ([x 2])
//     (let ([y 0])
//       (+ y (+ x (begin (set! x 40) x)))))
//   "
//     |> parsed

//   p.body
//   |> collect_set_bang
//   |> should.equal(set.from_list(["x"]))

//   let p2 =
//     parsed(
//       "(let ([sum 0])
//       (let ([i 5])
//         (begin
//           (while (> i 0)
//             (begin
//               (set! sum (+ sum i))
//               (set! i (- i 1))))
//           sum)))",
//     )

//   p2.body |> collect_set_bang |> should.equal(set.from_list(["sum", "i"]))
// }
