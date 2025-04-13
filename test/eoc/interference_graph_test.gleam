import eoc/graph
import eoc/interference_graph.{new}
import eoc/langs/x86_base.{LocReg, Rax}
import gleeunit/should

pub fn interference_graph_new_test() {
  let g = new()
  g.graph |> graph.has_node(LocReg(Rax)) |> should.be_true
}
