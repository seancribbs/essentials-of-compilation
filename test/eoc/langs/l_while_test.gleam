import eoc/langs/l_while as l
import eoc/passes/parse
import gleeunit/should
// pub fn l_while_test() {
//   let p =
//     "(let ([sum 0])
//       (let ([i 5])
//         (begin
//           (while (> i 0)
//             (begin
//               (set! sum (+ sum i))
//               (set! i (- i 1))))
//           sum)))"
//     |> parse.tokens
//     |> should.be_ok
//     |> parse.parse
//     |> should.be_ok

//   p
//   |> l.type_check_program()
//   |> should.be_ok
//   |> l.interpret
//   |> should.equal(l.IntValue(15))
// }
