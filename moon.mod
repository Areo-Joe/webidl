// Learn more about moon.mod configuration:
// https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html
//
// To add a dependency, run this command in your terminal:
//   moon add moonbitlang/x
//
// Or manually declare it in `import`, for example:
// import {
//   "moonbitlang/x@0.4.6",
// }

name = "Areo-Joe/webidl"

version = "0.2.0"

readme = "README.mbt.md"

repository = "https://github.com/Areo-Joe/webidl"

license = "MIT"

keywords = [ "webidl", "parser", "web" ]

preferred_target = "native"

description = "A Web IDL parser for MoonBit"

import {
  "moonbitlang/async@0.20.2",
}
