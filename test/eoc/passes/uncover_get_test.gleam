// import eoc/langs/l_alloc as l
// import eoc/passes/expose_allocation
// import eoc/passes/parse.{parse, tokens}
// import eoc/passes/uncover_get.{collect_set_bang, uncover_get}
// import gleam/set

// fn parsed(input: String) -> l.Program {
//   let assert Ok(value) = input
//   |> tokens
//   |> should.be_ok
//   |> parse
//   value
//   |> expose_allocation.expose_allocation
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
//     l.Program(l.Let(
//       "x",
//       l.Int(2),
//       l.Let(
//         "y",
//         l.Int(0),
//         l.Prim(l.Plus(
//           l.Var("y"),
//           l.Prim(l.Plus(
//             l.GetBang("x"),
//             l.Begin([l.SetBang("x", l.Int(40))], l.GetBang("x")),
//           )),
//         )),
//       ),
//     ))

//   assert uncover_get(p) == p2
// }

// pub fn collect_set_bang_test() {
//   let p =
//     "
//   (let ([x 2])
//     (let ([y 0])
//       (+ y (+ x (begin (set! x 40) x)))))
//   "
//     |> parsed

//   assert collect_set_bang(p.body) == set.from_list(["x"])

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

//   assert collect_set_bang(p2.body) == set.from_list(["sum", "i"])
// }
