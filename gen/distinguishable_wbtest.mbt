///|
fn parse_distinguishable_type(source : String) -> @parser.Type raise {
  let (type_, rest) = @parser.Type::parse(@lexer.tokenize(source).exact_view()).unwrap()
  assert_true(rest is [])
  type_
}

///|
fn distinguishable_test_definitions() -> Map[StringView, Definition] raise {
  let (definitions, rest) = @parser.parse(
    @lexer.tokenize(
      "[Exposed=*] interface A {}; dictionary D {}; callback F = undefined ();",
    ).exact_view(),
  )
  assert_true(rest is [])
  let index = Map([])
  for definition in Definition::from_parser(definitions) {
    if name_of_definition(definition) is Some(name) {
      index.set(name, definition)
    }
  }
  index
}

///|
test "Distinguishable types follow every cell of the symmetric category table" {
  let definitions = distinguishable_test_definitions()
  let types = [
    "undefined", "boolean", "long", "bigint", "DOMString", "object", "symbol", "A",
    "F", "D", "async_sequence<long>", "sequence<long>",
  ].map(parse_distinguishable_type)
  let expected = [
    [false, true, true, true, true, true, true, true, true, false, true, true],
    [true, false, true, true, true, true, true, true, true, true, true, true],
    [true, true, false, true, true, true, true, true, true, true, true, true],
    [true, true, true, false, true, true, true, true, true, true, true, true],
    [true, true, true, true, false, true, true, true, true, true, true, true],
    [
      true, true, true, true, true, false, true, false, false, false, false, false,
    ],
    [true, true, true, true, true, true, false, true, true, true, true, true],
    [true, true, true, true, true, false, true, false, true, true, true, true],
    [true, true, true, true, true, false, true, true, false, true, true, true],
    [false, true, true, true, true, false, true, true, true, false, true, true],
    [true, true, true, true, true, false, true, true, true, true, false, false],
    [true, true, true, true, true, false, true, true, true, true, false, false],
  ]
  for i in 0..<types.length() {
    for j in 0..<types.length() {
      assert_eq(
        are_flattened_member_types_distinguishable(
          types[i],
          types[j],
          definitions,
        ),
        expected[i][j],
      )
    }
  }
}

///|
test "Union distinguishability resolves named categories and special conditions" {
  let definitions = "[Exposed=*] interface A {}; [Exposed=*] interface B : A {}; [Exposed=*] interface C : B {}; [Exposed=*] interface Sibling : A {}; [Exposed=*] interface Other {}; interface mixin M {}; A includes M; Other includes M; dictionary D {}; dictionary E {}; enum Choice { \"a\" }; enum OtherChoice { \"b\" }; callback F = undefined (); callback G = undefined (); [LegacyTreatNonObjectAsNull] callback Loose = undefined (); callback interface Listener { undefined call(); }; callback interface OtherListener { undefined call(); };"
  for
    (type_, valid) in [
      ("(long or double)", false),
      ("(float or unrestricted float)", false),
      ("(DOMString or USVString)", false),
      ("(Choice or DOMString)", false),
      ("(Choice or OtherChoice)", false),
      ("(Choice or long)", true),
      ("(D or E)", false),
      ("(D or Listener)", false),
      ("(Listener or OtherListener)", false),
      ("(record<DOMString, long> or D)", false),
      ("(undefined or D)", false),
      ("(undefined or Listener)", false),
      ("(undefined or record<DOMString, long>)", false),
      ("(A or B)", false),
      ("(A or C)", false),
      ("(B or A)", false),
      ("(B or Other)", true),
      ("(B or Sibling)", true),
      ("(_A or C)", false),
      ("(A or Other)", true),
      ("(A or ArrayBuffer)", true),
      ("(F or G)", false),
      ("(F or D)", true),
      ("(Loose or D)", false),
      ("(D or Loose)", false),
      ("(Loose or Listener)", false),
      ("(record<DOMString, long> or Loose)", false),
      ("(Loose or A)", true),
      ("(Loose or sequence<long>)", true),
      ("(Loose or DOMString)", true),
      ("(sequence<long> or FrozenArray<DOMString>)", false),
      ("(sequence<long> or sequence<DOMString>)", false),
      ("(async_sequence<long> or FrozenArray<long>)", false),
      ("(async_sequence<long> or async_sequence<DOMString>)", false),
      ("(async_sequence<long> or DOMString)", true),
      ("(long or bigint)", true),
      ("(object or A)", false),
      ("(object or F)", false),
      ("(object or D)", false),
      ("(object or sequence<long>)", false),
      ("(object or symbol)", true),
      ("(object or boolean)", true),
      ("(ObservableArray<long> or DOMString)", false),
      ("(Missing or DOMString)", false),
    ] {
    for
      source in [
        definitions + "typedef " + type_ + " Value;",
        "typedef " + type_ + " Value;" + definitions,
      ] {
      assert_eq(check_union_source(source), valid)
    }
  }
}

///|
test "Buffer source types are distinguishable exactly when different" {
  let definitions = Map([])
  let types = [
    "ArrayBuffer", "SharedArrayBuffer", "DataView", "Int8Array", "Int16Array", "Int32Array",
    "Uint8Array", "Uint16Array", "Uint32Array", "Uint8ClampedArray", "BigInt64Array",
    "BigUint64Array", "Float16Array", "Float32Array", "Float64Array",
  ].map(parse_distinguishable_type)
  for i in 0..<types.length() {
    for j in 0..<types.length() {
      assert_eq(
        are_flattened_member_types_distinguishable(
          types[i],
          types[j],
          definitions,
        ),
        i != j,
      )
    }
  }
  assert_true(
    check_union_source(
      "typedef (ArrayBuffer or DataView or Int8Array or Float16Array) Buffers;",
    ),
  )
}

///|
test "Union distinguishability covers every declaration entry and typedef order" {
  for (prefix, suffix) in nullable_declaration_forms() {
    for
      (definitions, type_, valid) in [
        ("", "(long or double)", false),
        ("typedef double Number;", "(long or Number)", false),
        ("typedef (long or boolean) Value;", "(Value or double)", false),
        ("typedef (long or boolean) _Value;", "(_Value or double)", false),
        ("", "(long or DOMString)", true),
        ("typedef DOMString Text;", "(long or Text)", true),
        ("typedef Promise<long> Pending;", "(Pending or long)", false),
        ("", "sequence<(long or double)>", false),
        ("", "Promise<(long or double)>", false),
        ("", "record<DOMString, (long or double)>", false),
        ("", "(sequence<long> or boolean)", true),
        ("", "((long or DOMString) or double)", false),
      ] {
      let declaration = prefix + "FrozenArray<" + type_ + ">" + suffix
      for source in [definitions + declaration, declaration + definitions] {
        assert_eq(check_union_source(source), valid)
      }
    }
  }
}

///|
test "Numeric and string types retain their identities within shared categories" {
  let definitions = Map([])
  let typedefs = Map([])
  for
    names in [
      [
        "byte", "octet", "short", "unsigned short", "long", "unsigned long", "long long",
        "unsigned long long", "float", "unrestricted float", "double", "unrestricted double",
      ],
      ["DOMString", "ByteString", "USVString"],
    ] {
    let types = names.map(parse_distinguishable_type)
    for i in 0..<types.length() {
      for j in 0..<types.length() {
        assert_false(
          are_flattened_member_types_distinguishable(
            types[i],
            types[j],
            definitions,
          ),
        )
        assert_eq(
          same_flattened_member_type(types[i], types[j], typedefs),
          i == j,
        )
      }
    }
  }
}

///|
test "Flattened member sets deduplicate types independently of nullable occurrence counts" {
  for
    source in [
      "typedef (long or long) Value;", "typedef long Number; typedef (long or Number) Value;",
      "typedef (long or DOMString) Inner; typedef (Inner or Inner) Value;", "typedef (long? or long) Value;",
      "typedef (sequence<long> or sequence<long>) Value;", "typedef (sequence<(long or (boolean or DOMString))> or sequence<(DOMString or long or boolean)>) Value;",
      "typedef long Number; typedef (sequence<Number> or sequence<long>) Value;",
      "typedef (FrozenArray<(long or DOMString)> or FrozenArray<(DOMString or long)>) Value;",
      "typedef ([Clamp] long or long) Value;", "typedef (A or long) A;", "typedef (B or long) A; typedef (A or DOMString) B;",
      "typedef sequence<A> A; typedef sequence<B> B; typedef (A or B) Value;", "typedef (A or sequence<long>) A;",
    ] {
    assert_true(check_union_source(source))
  }
  for
    source in [
      "typedef (long? or long?) Value;", "typedef (sequence<long> or sequence<long?>) Value;",
      "typedef (sequence<[Clamp] long> or sequence<long>) Value;", "typedef [Clamp] long Clamped; typedef (sequence<Clamped> or sequence<long>) Value;",
      "typedef (A or long or double) A;", "typedef (sequence<A> or sequence<long>) A;",
    ] {
    assert_false(check_union_source(source))
  }
  assert_true(
    check_union_source(
      "typedef [Clamp] long Clamped; typedef (sequence<Clamped> or sequence<[Clamp] long>) Value;",
    ),
  )
}

///|
test "Container type identity preserves annotations on nested union members" {
  for
    source in [
      "typedef (sequence<([Clamp] long or DOMString)> or sequence<(long or DOMString)>) Value;",
      "typedef [Clamp] long Clamped; typedef (sequence<(Clamped or DOMString)> or sequence<(long or DOMString)>) Value;",
    ] {
    assert_false(check_union_source(source))
  }
  for
    (prefix, suffix) in [
      ("sequence<", ">"),
      ("async_sequence<", ">"),
      ("FrozenArray<", ">"),
      ("record<DOMString, ", ">"),
      ("Promise<", ">"),
    ] {
    for
      (definitions, left, right, same) in [
        ("", "([Clamp] long or DOMString)", "(long or DOMString)", false),
        (
          "", "([Clamp] long or DOMString)", "([EnforceRange] long or DOMString)",
          false,
        ),
        ("", "([Clamp] long or DOMString)", "(DOMString or [Clamp] long)", true),
        (
          "typedef [Clamp] long Clamped;", "(Clamped or DOMString)", "(long or DOMString)",
          false,
        ),
        (
          "typedef [Clamp] long Clamped;", "(Clamped or DOMString)", "(DOMString or [Clamp] long)",
          true,
        ),
        (
          "", "(([Clamp] long or boolean) or DOMString)", "(boolean or long or DOMString)",
          false,
        ),
        (
          "", "(([Clamp] long or boolean) or DOMString)", "(boolean or [Clamp] long or DOMString)",
          true,
        ),
        (
          "", "([AllowShared] Uint8Array or DOMString)", "(Uint8Array or DOMString)",
          false,
        ),
      ] {
      assert_eq(
        check_union_source(
          definitions +
          "typedef " +
          prefix +
          left +
          suffix +
          " Left; typedef " +
          prefix +
          right +
          suffix +
          " Right; typedef (Left or Right) Value;",
        ),
        same,
      )
    }
  }
  for
    (definitions, same) in [
      (
        "typedef (sequence<A> or [Clamp] long) A; typedef (sequence<B> or long) B;",
        false,
      ),
      (
        "typedef (sequence<A> or [Clamp] long) A; typedef (sequence<B> or [Clamp] long) B;",
        true,
      ),
    ] {
    assert_eq(
      check_union_source(
        definitions + "typedef (sequence<A> or sequence<B>) Value;",
      ),
      same,
    )
  }
}
