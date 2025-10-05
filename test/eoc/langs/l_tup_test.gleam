import eoc/langs/l_tup as l
import eoc/passes/expose_allocation
import eoc/passes/parse
import eoc/passes/remove_complex_operands
import eoc/passes/shrink
import eoc/passes/uncover_get
import eoc/passes/uniquify
import gleeunit/should

fn parsed(input: String) -> l.Program {
  input
  |> parse.tokens()
  |> should.be_ok()
  |> parse.parse()
  |> should.be_ok()
}

pub fn l_tup_vector_ref_pred_test() {
  let p =
    "
(let ([v1 (vector 42 #t)])
  (if (vector-ref v1 1)
    5
    (vector-ref v1 0)))
"
    |> parsed()

  p |> l.interpret() |> should.equal(l.IntValue(5))
}

pub fn l_tup_interp_test() {
  "
    (let ([t1 (vector 3 7)])
      (let ([t2 t1])
        (let ([t3 (vector 3 7)])
          (if (and (eq? t1 t2) (not (eq? t1 t3)))
            42
            0))))
    "
  |> parsed()
  |> l.interpret()
  |> should.equal(l.IntValue(42))
}

pub fn l_tup_alias_interp_test() {
  "
  (let ([t1 (vector 3 7)])
    (let ([t2 t1])
      (let ([_ (vector-set! t2 0 42)])
        (vector-ref t1 0))))
  "
  |> parsed()
  |> l.interpret()
  |> should.equal(l.IntValue(42))
}

pub fn l_tup_lifetime_interp_test() {
  "
  (let ([v (vector (vector 44))])
    (let ([x (let ([w (vector 42)])
              (let ([_ (vector-set! v 0 w)])
                0))])
      (+ x (vector-ref (vector-ref v 0) 0))))
  "
  |> parsed()
  |> l.interpret()
  |> should.equal(l.IntValue(42))
}
