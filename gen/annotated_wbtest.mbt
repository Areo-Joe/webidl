///|
fn check_annotated_source(source : String) -> Bool raise {
  let (definitions, rest) = @parser.parse(@lexer.tokenize(source).exact_view())
  assert_true(rest is [])
  try doc(definitions) catch {
    _ => false
  } noraise {
    _ => true
  }
}

///|
fn annotated_attribute_names(
  attributes : Array[@parser.ExtendedAttribute],
) -> Array[String] raise {
  attributes.map(attr => {
    guard attr is NoArgs(attr) else { fail("Expected a no-argument attribute") }
    attr.identifier.to_owned()
  })
}

///|
fn annotated_type_attribute_names(
  source : String,
  typedef_source~ : String = "",
) -> Array[Array[String]] raise {
  let (definitions, rest) = @parser.parse(
    @lexer.tokenize(typedef_source).exact_view(),
  )
  assert_true(rest is [])
  let typedefs = Map([])
  for definition in Definition::from_parser(definitions) {
    if definition is Typedef(typedef_) {
      typedefs.set(strip_underscore(typedef_.identifier), typedef_)
    }
  }
  let (type_, rest) = @parser.TypeWithExtendedAttributes::parse(
    @lexer.tokenize(source).exact_view(),
  ).unwrap()
  assert_true(rest is [])
  iter_types_with_extended_attributes(
    type_.type_,
    type_.extended_attribute_list.iter().collect(),
    typedefs,
  )
  .collect()
  .map(state => annotated_attribute_names(state.1))
}

///|
test "Type attribute applicability is independent of argument form" {
  for
    name in [
      "AllowResizable", "AllowShared", "Clamp", "EnforceRange", "LegacyNullToEmptyString",
    ] {
    for
      suffix in [
        "", "()", "=Create(long value)", "=Value", "=\"value\"", "=1", "=1.5", "=(1, 2)",
        "=(A, B)", "=*",
      ] {
      let (attributes, rest) = @parser.ExtendedAttributeList::parse(
        @lexer.tokenize("[" + name + suffix + "]").exact_view(),
      )
      assert_true(rest is [])
      assert_eq(attributes.iter().count(), 1)
      assert_true(
        attributes.iter().all(is_extended_attribute_applicable_to_types),
      )
    }
  }
  for
    source in [
      "[Exposed=*]", "[Global=Window]", "[SecureContext]", "[CrossOriginIsolated]",
      "[LegacyOverrideBuiltIns]", "[Example]",
    ] {
    let (attributes, rest) = @parser.ExtendedAttributeList::parse(
      @lexer.tokenize(source).exact_view(),
    )
    assert_true(rest is [])
    assert_false(
      attributes.iter().any(is_extended_attribute_applicable_to_types),
    )
  }
}

///|
test "Associated attributes follow union and nullable types in ordered sets" {
  assert_eq(
    annotated_type_attribute_names(
      "[Clamp, Clamp] (long? or [LegacyNullToEmptyString] DOMString)",
    ),
    [["Clamp"], ["Clamp"], ["LegacyNullToEmptyString", "Clamp"]],
  )
  assert_eq(
    annotated_type_attribute_names(
      "[AllowShared] (([Clamp] long or boolean)? or DOMString)",
    ),
    [
      ["AllowShared"],
      ["AllowShared"],
      ["Clamp", "AllowShared"],
      ["AllowShared"],
      ["AllowShared"],
    ],
  )
  assert_eq(
    annotated_type_attribute_names(
      "[AllowShared] Value?",
      typedef_source="typedef [Clamp] (long or [EnforceRange] DOMString) Value;",
    ),
    [
      ["AllowShared", "Clamp"],
      ["AllowShared", "Clamp"],
      ["EnforceRange", "AllowShared", "Clamp"],
    ],
  )
  assert_eq(
    annotated_type_attribute_names(
      "([Clamp, AllowShared] Value or [AllowShared, Clamp] Value)",
      typedef_source="typedef [EnforceRange] (long or DOMString) Value;",
    ),
    [
      [],
      ["Clamp", "AllowShared", "EnforceRange"],
      ["Clamp", "AllowShared", "EnforceRange"],
      ["Clamp", "AllowShared", "EnforceRange"],
      ["AllowShared", "Clamp", "EnforceRange"],
      ["AllowShared", "Clamp", "EnforceRange"],
      ["AllowShared", "Clamp", "EnforceRange"],
    ],
  )
}

///|
test "Parameterized types retain their own annotations and reset inherited attributes" {
  for
    container in [
      "sequence", "async_sequence", "FrozenArray", "ObservableArray",
    ] {
    assert_eq(
      annotated_type_attribute_names(
        "[AllowShared] " + container + "<[Clamp] long?>",
      ),
      [["AllowShared"], ["Clamp"]],
    )
  }
  assert_eq(
    annotated_type_attribute_names(
      "[AllowResizable] record<DOMString, [Clamp] long?>",
    ),
    [["AllowResizable"], [], ["Clamp"]],
  )
  assert_eq(
    annotated_type_attribute_names(
      "[Clamp] Promise<Value>",
      typedef_source="typedef [EnforceRange] long Value;",
    ),
    [["Clamp"], ["EnforceRange"]],
  )
  assert_eq(
    annotated_type_attribute_names(
      "[AllowShared] (sequence<[Clamp] long> or boolean)",
    ),
    [["AllowShared"], ["AllowShared"], ["Clamp"], ["AllowShared"]],
  )
}

///|
test "Argument annotations distinguish required variadic and optional positions" {
  for
    (source, expected) in [
      ("[Clamp, Example] long value", ["Clamp"]),
      ("[Clamp, Example] long... values", ["Clamp"]),
      ("[Clamp, Example] optional long value", []),
      ("[Example] optional [EnforceRange] long value", ["EnforceRange"]),
      ("[Clamp] optional [Example] long value", ["Example"]),
    ] {
    let (argument, rest) = @parser.Argument::parse(
      @lexer.tokenize(source).exact_view(),
    ).unwrap()
    assert_true(rest is [])
    assert_eq(
      annotated_attribute_names(argument_type_extended_attributes(argument)),
      expected,
    )
  }
}

///|
test "Dictionary annotations distinguish required and nonrequired positions" {
  for
    (source, expected) in [
      ("[Clamp, Example] long value;", ["Clamp"]),
      ("[Clamp, Example] long value = 0;", ["Clamp"]),
      ("[Clamp, Example] required long value;", []),
      ("[Example] required [EnforceRange] long value;", ["EnforceRange"]),
      ("[Clamp] required [Example] long value;", ["Example"]),
    ] {
    let (member_, rest) = @parser.DictionaryMember::parse(
      @lexer.tokenize(source).exact_view(),
    ).unwrap()
    assert_true(rest is [])
    assert_eq(
      annotated_attribute_names(
        dictionary_member_type_extended_attributes(
          member_.dictionary_member_rest,
          member_.extended_attribute_list,
        ),
      ),
      expected,
    )
  }
}

///|
test "Annotated type validation covers every type entry" {
  for (prefix, suffix) in nullable_declaration_forms() {
    for
      (type_, valid) in [
        ("Promise<sequence<[SecureContext] long>>", false),
        ("Promise<record<DOMString, [Global=Window] long>>", false),
        ("Promise<([Exposed=*] long or DOMString)>", false),
        ("Promise<Promise<sequence<[Example] long>>>", false),
        ("Promise<sequence<[Clamp] long>>", true),
        ("Promise<([Clamp] long or [LegacyNullToEmptyString] DOMString)>", true),
      ] {
      assert_eq(check_annotated_source(prefix + type_ + suffix), valid)
    }
  }
  for
    (prefix, suffix) in [
      ("typedef ", " Value;"),
      ("[Exposed=*] interface A { attribute ", " value; };"),
      (
        "[Exposed=*] interface A {}; partial interface A { attribute ", " value; };",
      ),
      ("interface mixin M { attribute ", " value; };"),
      (
        "interface mixin M {}; partial interface mixin M { attribute ", " value; };",
      ),
      ("namespace N { readonly attribute ", " value; };"),
      (
        "namespace N {}; partial namespace N { readonly attribute ", " value; };",
      ),
      ("dictionary D { required ", " value; };"),
      ("dictionary D {}; partial dictionary D { required ", " value; };"),
      ("callback F = undefined (optional ", " value);"),
      ("[Exposed=*] interface A { iterable<", ">; };"),
      ("[Exposed=*] interface A { iterable<long, ", ">; };"),
      ("[Exposed=*] interface A { async_iterable<", ">; };"),
      ("[Exposed=*] interface A { async_iterable<long, ", ">; };"),
      ("[Exposed=*] interface A { maplike<", ", long>; };"),
      ("[Exposed=*] interface A { readonly maplike<long, ", ">; };"),
      ("[Exposed=*] interface A { setlike<", ">; };"),
      (
        "[Exposed=*] interface A {}; partial interface A { readonly setlike<", ">; };",
      ),
      (
        "[Exposed=*] interface A { async_iterable<long>(optional ", " value); };",
      ),
      (
        "[Exposed=*, LegacyFactoryFunction=Create(optional ", " value)] interface A {};",
      ),
    ] {
    assert_false(
      check_annotated_source(prefix + "[SecureContext] long" + suffix),
    )
    assert_true(check_annotated_source(prefix + "[Clamp] long" + suffix))
  }
  assert_true(
    check_annotated_source(
      "callback F = undefined ([Example, Clamp] long value, [Example] optional [EnforceRange] long other);",
    ),
  )
  assert_true(
    check_annotated_source(
      "dictionary D { [Example, Clamp] long value; [Example] required [EnforceRange] long other; };",
    ),
  )
}

///|
test "Annotated type checks resolve typedef graphs and terminate on cycles" {
  assert_eq(
    annotated_type_attribute_names(
      "A",
      typedef_source="typedef [Clamp] (A or long) A;",
    ),
    [["Clamp"], ["Clamp"], ["Clamp"]],
  )
  assert_eq(
    annotated_type_attribute_names(
      "A",
      typedef_source="typedef [Clamp] sequence<A> A;",
    ),
    [["Clamp"], ["Clamp"]],
  )
  for
    definitions in [
      "typedef [SecureContext] long Bad;", "typedef sequence<[Global=Window] long> Bad;",
      "typedef (Bad or [Exposed=*] long) Bad;", "typedef sequence<Bad> First; typedef [Example] sequence<First> Bad;",
    ] {
    for
      source in [
        definitions + "callback Use = undefined (Bad value);",
        "callback Use = undefined (Bad value);" + definitions,
      ] {
      assert_false(check_annotated_source(source))
    }
  }
  for
    source in [
      "typedef [Clamp] long Clamped; typedef (Clamped or DOMString) Value;", "typedef [Clamp] (A or long) A;",
      "typedef [Clamp] sequence<A> A;", "typedef [Clamp] (sequence<B> or long) A; typedef [EnforceRange] (sequence<A> or boolean) B;",
    ] {
    assert_true(check_annotated_source(source))
  }
}
