import eoc/langs/l_tup as l
import eoc/passes/parse
import gleeunit/should

fn parsed(input: String) -> l.Program {
  input
  |> parse.tokens()
  |> should.be_ok()
  |> parse.parse()
  |> should.be_ok()
}

fn l_tup_interp_test() {
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

fn l_tup_alias_interp_test() {
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

fn l_tup_lifetime_interp_test() {
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
