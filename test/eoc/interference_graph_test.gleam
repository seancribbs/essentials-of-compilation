import eoc/graph
import eoc/interference_graph.{new}
import eoc/langs/x86_base.{LocReg, Rax}

pub fn interference_graph_new_test() {
  let g = new()
  assert graph.has_node(g.graph, LocReg(Rax))
}
