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
        "[" + attributes + "] interface A {};",
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
        "[LegacyFactoryFunction=" + name + "()] interface A {};",
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
        "[LegacyFactoryFunction=Create(long value), LegacyFactoryFunction=_Create(DOMString value)] interface A {};",
        true,
      ),
      (
        "[LegacyFactoryFunction=Create()] interface A {}; [LegacyFactoryFunction=Create()] interface B {};",
        false,
      ),
      (
        "[LegacyFactoryFunction=Create(long value)] interface A {}; [LegacyFactoryFunction=_Create(DOMString value)] interface B {};",
        false,
      ),
      (
        "[LegacyFactoryFunction=First()] interface A {}; [LegacyFactoryFunction=Second()] interface B {};",
        true,
      ),
      (
        "[LegacyFactoryFunction=Create()] interface B {}; [LegacyFactoryFunction=_Create()] interface A {};",
        false,
      ),
      (
        "[Global=Window] interface Window {}; [Global=Worker] interface Worker {}; [Exposed=Window, LegacyFactoryFunction=Create()] interface A {}; [Exposed=Worker, LegacyFactoryFunction=Create()] interface B {};",
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
      ("[LegacyFactoryFunction=A()] interface A {};", false),
      ("[LegacyFactoryFunction=_A()] interface A {};", false),
      (
        "[LegacyFactoryFunction=Other()] interface A {}; interface _Other {};", false,
      ),
      (
        "interface Other {}; [LegacyFactoryFunction=_Other()] interface A {};", false,
      ),
      (
        "[LegacyNoInterfaceObject, LegacyFactoryFunction=A()] interface A {};", true,
      ),
      (
        "[LegacyNoInterfaceObject] interface Other {}; [LegacyFactoryFunction=Other()] interface A {};",
        true,
      ),
      (
        "[LegacyNoInterfaceObject()] interface Other {}; [LegacyFactoryFunction=Other()] interface A {};",
        false,
      ),
      (
        "[LegacyNoInterfaceObject=Other] interface Other {}; [LegacyFactoryFunction=Other()] interface A {};",
        false,
      ),
      (
        "[LegacyNamespace=NS] interface Other {}; [LegacyFactoryFunction=Other()] interface A {};",
        false,
      ),
      (
        "dictionary Other {}; [LegacyFactoryFunction=Other()] interface A {};", true,
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
        "[LegacyWindowAlias=Create, LegacyFactoryFunction=Create()] interface A {};",
        false,
      ),
      (
        "[LegacyWindowAlias=(First,_Create), LegacyFactoryFunction=Create()] interface A {};",
        false,
      ),
      (
        "[LegacyFactoryFunction=_Create()] interface A {}; [LegacyWindowAlias=Create] interface B {};",
        false,
      ),
      (
        "[LegacyWindowAlias=(_Create,Other)] interface B {}; [LegacyFactoryFunction=Create()] interface A {};",
        false,
      ),
      (
        "[LegacyFactoryFunction=Create()] interface A {}; [LegacyWindowAlias=Other] interface B {};",
        true,
      ),
      (
        "[LegacyFactoryFunction=Create()] interface A {}; [LegacyWindowAlias=Create()] interface B {};",
        true,
      ),
      (
        "[LegacyFactoryFunction=Create()] interface A {}; [LegacyWindowAlias] interface B {};",
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
