pub type CFG(v, e)

@external(erlang, "cfg_ffi", "new")
pub fn new() -> CFG(v, e)

@external(erlang, "cfg_ffi", "add_vertex")
pub fn add_vertex(g: CFG(v, e), vertex: v) -> CFG(v, e)

@external(erlang, "cfg_ffi", "add_edge")
pub fn add_edge(g: CFG(v, e), v1: v, v2: v) -> CFG(v, e)

@external(erlang, "cfg_ffi", "topsort")
pub fn topsort(g: CFG(v, e)) -> Result(List(v), Nil)

@external(erlang, "cfg_iff", "in_neighbors")
pub fn in_neighbors(g: CFG(v, e), vertex: v) -> List(v)

@external(erlang, "cfg_iff", "out_neighbors")
pub fn out_neighbors(g: CFG(v, e), vertex: v) -> List(v)
