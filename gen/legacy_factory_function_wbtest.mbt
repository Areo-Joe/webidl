///|
test "LegacyFactoryFunction recognizes named argument lists and preserves their contents" {
  for
    (source, name, count) in [
      ("[LegacyFactoryFunction=Create()]", "Create", 0),
      ("[LegacyFactoryFunction=_Create(long value)]", "_Create", 1),
      (
        "[LegacyFactoryFunction=Create(optional long value, DOMString... rest)]",
        "Create", 2,
      ),
    ] {
    let (attrs, rest) = @parser.ExtendedAttributeList::parse(
      @lexer.tokenize(source).exact_view(),
    )
    assert_true(rest is [])
    let recognized = attrs
      .iter()
      .filter_map(is_valid_legacy_factory_function)
      .collect()
    assert_eq(recognized.length(), 1)
    assert_eq(recognized[0].value, name)
    assert_eq(recognized[0].argument_list.iter().count(), count)
  }
}

///|
test "LegacyFactoryFunction leaves other forms and other attribute names unrecognized" {
  for
    source in [
      "[LegacyFactoryFunction]", "[LegacyFactoryFunction()]", "[LegacyFactoryFunction=Create]",
      "[LegacyFactoryFunction=(Create,Other)]", "[LegacyFactoryFunction=*]", "[LegacyFactoryFunction=\"Create\"]",
      "[LegacyFactoryFunction=1]", "[LegacyFactoryFunction=1.5]", "[LegacyFactoryFunction=(1,2)]",
      "[Other=Create()]", "[legacyFactoryFunction=Create()]",
    ] {
    let (attrs, rest) = @parser.ExtendedAttributeList::parse(
      @lexer.tokenize(source).exact_view(),
    )
    assert_true(rest is [])
    assert_eq(attrs.iter().count(), 1)
    assert_true(
      attrs.iter().all(attr => is_valid_legacy_factory_function(attr) is None),
    )
  }
}
