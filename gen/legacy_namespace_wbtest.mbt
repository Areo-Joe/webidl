///|
test "LegacyNamespace recognizes only the identifier form and preserves its value" {
  for
    (source, expected) in [
      ("[LegacyNamespace=NS]", Some("NS")),
      ("[LegacyNamespace=_NS]", Some("_NS")),
      ("[LegacyNamespace]", None),
      ("[LegacyNamespace()]", None),
      ("[LegacyNamespace=NS()]", None),
      ("[LegacyNamespace=(NS,Other)]", None),
      ("[LegacyNamespace=*]", None),
      ("[LegacyNamespace=\"NS\"]", None),
      ("[LegacyNamespace=1]", None),
      ("[LegacyNamespace=1.5]", None),
      ("[LegacyNamespace=(1,2)]", None),
      ("[Other=NS]", None),
      ("[legacyNamespace=NS]", None),
    ] {
    let (attrs, rest) = @parser.ExtendedAttributeList::parse(
      @lexer.tokenize(source).exact_view(),
    )
    assert_true(rest is [])
    assert_eq(attrs.iter().count(), 1)
    let recognized = attrs
      .iter()
      .filter_map(is_valid_legacy_namespace)
      .collect()
    match expected {
      Some(value) => assert_eq(recognized, [value])
      None => assert_true(recognized.is_empty())
    }
  }
}
