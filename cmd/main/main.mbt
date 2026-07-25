///|
/// Entry point for the CLI or runnable program in this template.
/// Keep main focused; move logic into the library package.
/// Run with `moon run cmd/main` from the project root.
fn main {
  try
    @lexer.tokenize(
      "//xx adwwadwawadadawd\ninterface ejaodjiaed{const a = 12; readonly attribute joe = 1} {} @",
    )
  // @lexer.tokenize(
  //   "xx", integer_regexp, decimal_regexp, identifier_regexp, string_regexp,
  //   whitespace_regexp, comment_regexp, other_regexp,
  // )
  catch {
    _ => println("damn2")
  } noraise {
    result => {
      @debug.debug("result")
      @debug.debug(result)
    }
  }
}
