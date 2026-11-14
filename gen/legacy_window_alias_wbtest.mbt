///|
test "LegacyWindowAlias recognizes identifier and identifier-list forms" {
  let (attrs, rest) = @parser.ExtendedAttributeList::parse(
    @lexer.tokenize(
      "[LegacyWindowAlias=_First, LegacyWindowAlias=(_First,Second)]",
    ).exact_view(),
  )
  assert_true(rest is [])
  let recognized = attrs
    .iter()
    .filter_map(is_valid_legacy_window_alias)
    .collect()
  assert_eq(recognized.length(), 2)
  assert_true(recognized[0] is Ident("_First"))
  guard recognized[1] is IdentList(names) else {
    fail("expected identifier list")
  }
  assert_eq(names, ["_First", "Second"])
  assert_eq(legacy_window_alias_names(attrs), ["First", "First", "Second"])
}

///|
test "LegacyWindowAlias leaves other forms and other attribute names unrecognized" {
  for
    source in [
      "[LegacyWindowAlias]", "[LegacyWindowAlias()]", "[LegacyWindowAlias=Name()]",
      "[LegacyWindowAlias=*]", "[LegacyWindowAlias=\"Name\"]", "[LegacyWindowAlias=1]",
      "[LegacyWindowAlias=1.5]", "[LegacyWindowAlias=(1,2)]", "[Other=Name]", "[legacyWindowAlias=Name]",
    ] {
    let (attrs, rest) = @parser.ExtendedAttributeList::parse(
      @lexer.tokenize(source).exact_view(),
    )
    assert_true(rest is [])
    assert_eq(attrs.iter().count(), 1)
    assert_true(
      attrs.iter().all(attr => is_valid_legacy_window_alias(attr) is None),
    )
    assert_eq(legacy_window_alias_names(attrs), [])
  }
}
