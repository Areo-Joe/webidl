///|
test "extract grammar terminals" {
  let html =
    #|<pre class="grammar">
    #|  <emu-t>interface</emu-t>
    #|  <emu-t>A</emu-t>
    #|  <emu-t>&lt;</emu-t>
    #|  <emu-t>&gt;</emu-t>
    #|  <emu-t>...</emu-t>
    #|  <emu-t>byte</emu-t>
    #|  <emu-t class="regex">identifier</emu-t>
    #|</pre>
  let (keywords, punctuation) = extract_terminals(html)
  punctuation.sort()
  keywords.sort()
  assert_eq(keywords, ["A", "byte", "interface"])
  assert_eq(punctuation, ["<", ">", "..."])
}

///|
test "sort terminals by descending length" {
  let terminals = ["b", "...", "aa", "a"]
  sort_by_length_desc(terminals)
  assert_eq(terminals, ["...", "aa", "a", "b"])
}

///|
test "generate lexer source with private helpers" {
  let output = generate_output(["long"], ["..."])
  assert_true(output.contains("fn is_keyword"))
  assert_true(output.contains("fn match_punctuation"))
  assert_true(output.contains("text.has_prefix(p[:])"))
}

///|
test "escape generated literals and render empty arrays" {
  assert_eq(escape_str("\"\\text"), "\\\"\\\\text")
  let output = generate_output([], [])
  assert_true(output.contains("let keywords : Array[String] = ["))
  assert_true(output.contains("let punctuation : Array[String] = ["))
}
