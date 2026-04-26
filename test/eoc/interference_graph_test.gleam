import eoc/graf
import eoc/interference_graph.{new}
import eoc/langs/x86_base.{LocReg, Rax}

pub fn interference_graph_new_test() {
  let g = new()
  let assert Ok(_) = graf.get_node(g, LocReg(Rax))
}
