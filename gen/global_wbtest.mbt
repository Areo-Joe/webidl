///|
fn parse_global_attributes(
  source : String,
) -> @parser.ExtendedAttributeList raise {
  let (attrs, rest) = @parser.ExtendedAttributeList::parse(
    @lexer.tokenize(source).exact_view(),
  )
  assert_true(rest is [])
  attrs
}

///|
test "Global recognizes identifier and identifier list forms" {
  let attrs = parse_global_attributes(
    "[Global=_Window, Global=(_Window,Worker)]",
  )
  let recognized = attrs.iter().filter_map(is_valid_global).collect()
  assert_eq(recognized.length(), 2)
  assert_true(recognized[0] is Ident("_Window"))
  guard recognized[1] is IdentList(names) else {
    fail("expected identifier list")
  }
  assert_eq(names, ["_Window", "Worker"])
  assert_eq(global_names(attrs), ["Window", "Window", "Worker"])
}

///|
test "Global leaves other forms and other attribute names unrecognized" {
  for
    source in [
      "[Global]", "[Global()]", "[Global=Window()]", "[Global=*]", "[Global=\"Window\"]",
      "[Global=1]", "[Global=1.5]", "[Global=(1,2)]", "[Exposed=Window]", "[Exposed=(Window,Worker)]",
      "[global=Window]",
    ] {
    let attrs = parse_global_attributes(source)
    assert_eq(attrs.iter().count(), 1)
    assert_true(attrs.iter().all(attr => is_valid_global(attr) is None))
    assert_eq(global_names(attrs), [])
  }
}

///|
test "Global names extraction keeps order and duplicates while ignoring other forms" {
  assert_eq(
    global_names(
      parse_global_attributes(
        "[Exposed=Window, Global=Window, Global, Global=(_Worker,Window), Global=*]",
      ),
    ),
    ["Window", "Worker", "Window"],
  )
  assert_eq(global_names(parse_global_attributes("")), [])
}
