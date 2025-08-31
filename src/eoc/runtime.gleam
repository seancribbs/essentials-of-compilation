@external(erlang, "runtime_ffi", "read_int")
@external(javascript, "../runtime_ffi.mjs", "read_int")
pub fn read_int() -> Int

@external(erlang, "io", "write")
@external(javascript, "../runtime_ffi.mjs", "debug")
pub fn debug(stuff: List(String)) -> Nil
