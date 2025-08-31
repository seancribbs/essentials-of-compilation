pub type CFG(v, e)

@external(erlang, "cfg_ffi", "new")
@external(javascript, "../cfg_ffi.mjs", "new_cfg")
pub fn new() -> CFG(v, e)

@external(erlang, "cfg_ffi", "add_vertex")
@external(javascript, "../cfg_ffi.mjs", "add_vertex")
pub fn add_vertex(g: CFG(v, e), vertex: v) -> CFG(v, e)

@external(erlang, "cfg_ffi", "add_edge")
@external(javascript, "../cfg_ffi.mjs", "add_edge")
pub fn add_edge(g: CFG(v, e), v1: v, v2: v) -> CFG(v, e)

@external(erlang, "cfg_ffi", "in_neighbors")
@external(javascript, "../cfg_ffi.mjs", "in_neighbors")
pub fn in_neighbors(g: CFG(v, e), vertex: v) -> List(v)

@external(erlang, "cfg_ffi", "out_neighbors")
@external(javascript, "../cfg_ffi.mjs", "out_neighbors")
pub fn out_neighbors(g: CFG(v, e), vertex: v) -> List(v)
