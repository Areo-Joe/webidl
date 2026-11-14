///|
test "LegacyNoInterfaceObject recognizes only the no-arguments form" {
  for
    (source, expected) in [
      ("[LegacyNoInterfaceObject]", true),
      ("[LegacyNoInterfaceObject()]", false),
      ("[LegacyNoInterfaceObject=Name]", false),
      ("[LegacyNoInterfaceObject=(First,Second)]", false),
      ("[LegacyNoInterfaceObject=Name()]", false),
      ("[LegacyNoInterfaceObject=*]", false),
      ("[LegacyNoInterfaceObject=\"Name\"]", false),
      ("[LegacyNoInterfaceObject=1]", false),
      ("[LegacyNoInterfaceObject=1.5]", false),
      ("[LegacyNoInterfaceObject=(1,2)]", false),
      ("[Other]", false),
      ("[legacyNoInterfaceObject]", false),
    ] {
    let (attrs, rest) = @parser.ExtendedAttributeList::parse(
      @lexer.tokenize(source).exact_view(),
    )
    assert_true(rest is [])
    assert_eq(attrs.iter().count(), 1)
    assert_eq(attrs.iter().any(is_valid_legacy_no_interface_object), expected)
  }
}
