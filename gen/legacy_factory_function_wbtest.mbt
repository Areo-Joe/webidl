///|
fn check_legacy_factory_function_source(source : String) -> Bool raise {
  let (definitions, rest) = @parser.parse(@lexer.tokenize(source).exact_view())
  assert_true(rest is [])
  try doc(definitions) catch {
    _ => false
  } noraise {
    _ => true
  }
}

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
test "LegacyFactoryFunction cannot share an interface with Global" {
  for
    (attributes, expected) in [
      ("LegacyFactoryFunction=Create()", true),
      ("Global=Window, LegacyFactoryFunction=Create()", false),
      ("LegacyFactoryFunction=Create(), Global=(Window,Worker)", false),
      ("Global, LegacyFactoryFunction=Create()", true),
      ("Global=Window, LegacyFactoryFunction", true),
    ] {
    assert_eq(
      check_legacy_factory_function_source(
        "[Exposed=*, " + attributes + "] interface A {};",
      ),
      expected,
    )
  }
}

///|
test "LegacyFactoryFunction rejects normalized reserved identifiers" {
  for
    (name, expected) in [
      ("_constructor", false),
      ("toString", false),
      ("_toString", false),
      ("Create", true),
      ("_Create", true),
      ("prototype", true),
    ] {
    assert_eq(
      check_legacy_factory_function_source(
        "[Exposed=*, LegacyFactoryFunction=" + name + "()] interface A {};",
      ),
      expected,
    )
  }
}

///|
test "LegacyFactoryFunction names can be overloaded on one interface and cannot belong to another" {
  for
    (source, expected) in [
      (
        "[Exposed=*, LegacyFactoryFunction=Create(long value), LegacyFactoryFunction=_Create(DOMString value)] interface A {};",
        true,
      ),
      (
        "[Exposed=*, LegacyFactoryFunction=Create()] interface A {}; [Exposed=*, LegacyFactoryFunction=Create()] interface B {};",
        false,
      ),
      (
        "[Exposed=*, LegacyFactoryFunction=Create(long value)] interface A {}; [Exposed=*, LegacyFactoryFunction=_Create(DOMString value)] interface B {};",
        false,
      ),
      (
        "[Exposed=*, LegacyFactoryFunction=First()] interface A {}; [Exposed=*, LegacyFactoryFunction=Second()] interface B {};",
        true,
      ),
      (
        "[Exposed=*, LegacyFactoryFunction=Create()] interface B {}; [Exposed=*, LegacyFactoryFunction=_Create()] interface A {};",
        false,
      ),
      (
        "[Exposed=*, Global=Window] interface Window {}; [Exposed=*, Global=Worker] interface Worker {}; [Exposed=Window, LegacyFactoryFunction=Create()] interface A {}; [Exposed=Worker, LegacyFactoryFunction=Create()] interface B {};",
        false,
      ),
    ] {
    assert_eq(check_legacy_factory_function_source(source), expected)
  }
}

///|
test "LegacyFactoryFunction names cannot match any interface object name" {
  for
    (source, expected) in [
      ("[Exposed=*, LegacyFactoryFunction=A()] interface A {};", false),
      ("[Exposed=*, LegacyFactoryFunction=_A()] interface A {};", false),
      (
        "[Exposed=*, LegacyFactoryFunction=Other()] interface A {}; [Exposed=*] interface _Other {};",
        false,
      ),
      (
        "[Exposed=*] interface Other {}; [Exposed=*, LegacyFactoryFunction=_Other()] interface A {};",
        false,
      ),
      (
        "[Exposed=*, LegacyNoInterfaceObject, LegacyFactoryFunction=A()] interface A {};",
        true,
      ),
      (
        "[Exposed=*, LegacyNoInterfaceObject] interface Other {}; [Exposed=*, LegacyFactoryFunction=Other()] interface A {};",
        true,
      ),
      (
        "[Exposed=*, LegacyNoInterfaceObject()] interface Other {}; [Exposed=*, LegacyFactoryFunction=Other()] interface A {};",
        false,
      ),
      (
        "[Exposed=*, LegacyNoInterfaceObject=Other] interface Other {}; [Exposed=*, LegacyFactoryFunction=Other()] interface A {};",
        false,
      ),
      (
        "[Exposed=*, LegacyNamespace=NS] interface Other {}; [Exposed=*, LegacyFactoryFunction=Other()] interface A {};",
        false,
      ),
      (
        "dictionary Other {}; [Exposed=*, LegacyFactoryFunction=Other()] interface A {};",
        true,
      ),
    ] {
    assert_eq(check_legacy_factory_function_source(source), expected)
  }
}

///|
test "LegacyFactoryFunction names cannot match same-interface or other-interface window aliases" {
  for
    (source, expected) in [
      (
        "[Exposed=*, LegacyWindowAlias=Create, LegacyFactoryFunction=Create()] interface A {};",
        false,
      ),
      (
        "[Exposed=*, LegacyWindowAlias=(First,_Create), LegacyFactoryFunction=Create()] interface A {};",
        false,
      ),
      (
        "[Exposed=*, LegacyFactoryFunction=_Create()] interface A {}; [Exposed=*, LegacyWindowAlias=Create] interface B {};",
        false,
      ),
      (
        "[Exposed=*, LegacyWindowAlias=(_Create,Other)] interface B {}; [Exposed=*, LegacyFactoryFunction=Create()] interface A {};",
        false,
      ),
      (
        "[Exposed=*, LegacyFactoryFunction=Create()] interface A {}; [Exposed=*, LegacyWindowAlias=Other] interface B {};",
        true,
      ),
      (
        "[Exposed=*, LegacyFactoryFunction=Create()] interface A {}; [Exposed=*, LegacyWindowAlias=Create()] interface B {};",
        true,
      ),
      (
        "[Exposed=*, LegacyFactoryFunction=Create()] interface A {}; [Exposed=*, LegacyWindowAlias] interface B {};",
        true,
      ),
    ] {
    assert_eq(check_legacy_factory_function_source(source), expected)
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
