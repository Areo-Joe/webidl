///|
fn check_distinguishable_types(
  left : String,
  right : String,
  typedef_source~ : String = "",
) -> Bool raise {
  let source = "[Exposed=*] interface I {}; [Exposed=*] interface J : I {}; [Exposed=*] interface K {}; dictionary D {}; dictionary E {}; callback F = undefined (); [LegacyTreatNonObjectAsNull] callback Loose = undefined (); callback interface Listener { undefined call(); }; enum Choice { \"a\" };" +
    typedef_source
  let (parsed_definitions, rest) = @parser.parse(
    @lexer.tokenize(source).exact_view(),
  )
  assert_true(rest is [])
  let definitions = Map([])
  let typedefs = Map([])
  for definition in Definition::from_parser(parsed_definitions) {
    if name_of_definition(definition) is Some(name) {
      definitions.set(name, definition)
    }
    if definition is Typedef(typedef_) {
      typedefs.set(strip_underscore(typedef_.identifier), typedef_)
    }
  }
  fn parse_type(source : String) -> @parser.Type raise {
    let (type_, rest) = @parser.TypeWithExtendedAttributes::parse(
      @lexer.tokenize(source).exact_view(),
    ).unwrap()
    assert_true(rest is [])
    type_.type_
  }
  let left = parse_type(left)
  let right = parse_type(right)
  let result = are_types_distinguishable(left, right, typedefs, definitions)
  assert_eq(
    result,
    are_types_distinguishable(right, left, typedefs, definitions),
  )
  result
}

///|
test "Complete type distinguishability covers nullable conflicts and the specification examples" {
  for
    (left, right, expected) in [
      ("double?", "D", false),
      ("(I or long)?", "(K or DOMString)?", false),
      ("(I or long?)", "(K or DOMString)?", false),
      ("(I or long?)", "(K or DOMString?)", false),
      ("(D or long)", "(I or DOMString)?", false),
      ("(D or long)", "(I or DOMString?)", false),
      ("long?", "DOMString?", false),
      ("long?", "DOMString", true),
      ("long", "DOMString?", true),
      ("long?", "D?", false),
      ("long?", "(D or DOMString)", false),
      ("long?", "((D or I) or DOMString)", false),
      ("long?", "record<DOMString, long>", true),
      ("long?", "Listener", true),
      ("long?", "(Listener or DOMString)", true),
      ("long?", "record<DOMString, long>?", false),
      ("long?", "Listener?", false),
      ("D", "DOMString?", false),
      ("D", "DOMString", true),
    ] {
    assert_eq(check_distinguishable_types(left, right), expected)
  }
}

///|
test "Complete type distinguishability compares every union member pair" {
  for
    (left, right, expected) in [
      ("(long or DOMString)", "boolean", true),
      ("(long or DOMString)", "double", false),
      ("(DOMString or long)", "double", false),
      ("(long or DOMString)", "(boolean or symbol)", true),
      ("(long or DOMString)", "(boolean or double)", false),
      ("((long or DOMString) or boolean)", "symbol", true),
      ("((long or DOMString) or boolean)", "(symbol or double)", false),
      ("(long? or DOMString)", "boolean", true),
      ("(long or DOMString)?", "boolean", true),
      ("(long or DOMString)?", "boolean?", false),
      ("(sequence<long> or DOMString)", "(boolean or bigint)", true),
      ("(sequence<long> or DOMString)", "async_sequence<long>", false),
      ("(I or DOMString)", "K", true),
      ("(I or DOMString)", "J", false),
      ("(I or DOMString)", "ArrayBuffer", true),
      ("(D or DOMString)", "F", true),
      ("(D or DOMString)", "Loose", false),
      ("(long or DOMString)", "Promise<long>", false),
      ("(long or DOMString)", "any", false),
      ("long", "bigint", true),
    ] {
    assert_eq(check_distinguishable_types(left, right), expected)
  }
}

///|
test "Complete type distinguishability stops at container types" {
  for
    (left, right, expected) in [
      ("sequence<long?>", "DOMString?", true),
      ("sequence<D>", "DOMString?", true),
      ("sequence<(long? or DOMString)>", "boolean?", true),
      ("FrozenArray<long?>", "DOMString?", true),
      ("FrozenArray<D>", "DOMString?", true),
      ("record<DOMString, long?>", "DOMString?", true),
      ("record<DOMString, D>", "DOMString?", true),
      ("async_sequence<D?>", "boolean?", true),
      ("(sequence<D> or long)", "DOMString?", true),
      ("sequence<long>?", "DOMString?", false),
      ("(sequence<long>? or long)", "DOMString?", false),
      ("Promise<long?>", "DOMString?", false),
      ("ObservableArray<long>", "DOMString", false),
      ("sequence<long>", "sequence<DOMString>", false),
    ] {
    assert_eq(check_distinguishable_types(left, right), expected)
  }
}

///|
test "Complete type distinguishability resolves typedefs and ignores outer type annotations" {
  let definitions = "typedef long _Number; typedef Number? MaybeNumber; typedef DOMString Text; typedef D Config; typedef (Config or long) ConfigOrNumber; typedef (long? or DOMString) MaybeUnion; typedef (long or DOMString) ValueUnion; typedef sequence<D?> Nested; typedef [Clamp] long Clamped; typedef Promise<long> Pending;"
  for
    (left, right, expected) in [
      ("_Number", "Text", true),
      ("MaybeNumber", "Text?", false),
      ("MaybeNumber", "Config", false),
      ("ConfigOrNumber", "Text?", false),
      ("MaybeUnion", "boolean?", false),
      ("MaybeUnion", "boolean", true),
      ("ValueUnion?", "boolean", true),
      ("ValueUnion?", "boolean?", false),
      ("Nested", "Text?", true),
      ("(Nested or long)", "Text?", true),
      ("Clamped", "Text", true),
      ("Clamped?", "Text?", false),
      ("[Clamp] long", "[LegacyNullToEmptyString] DOMString", true),
      ("[Clamp] (long or DOMString)?", "boolean?", false),
      ("([Clamp] long or DOMString)", "boolean", true),
      ("Pending", "long", false),
      ("[Clamp] long", "long", false),
      ("Choice", "DOMString", false),
      ("Missing", "DOMString", false),
    ] {
    assert_eq(
      check_distinguishable_types(left, right, typedef_source=definitions),
      expected,
    )
  }
}

///|
test "Complete type distinguishability terminates on cycles and retains nullable and dictionary branches" {
  for
    (definitions, left, right, expected) in [
      ("typedef (Value or long) Value;", "Value", "DOMString", true),
      ("typedef (Value or long) Value;", "Value", "double", false),
      (
        "typedef (Other or long) Value; typedef (Value or DOMString) Other;", "Value",
        "boolean", true,
      ),
      (
        "typedef (Other or long) Value; typedef (Value or DOMString) Other;", "Value",
        "DOMString", false,
      ),
      ("typedef (Value or long?) Value;", "Value", "DOMString?", false),
      ("typedef (long? or Value) Value;", "Value", "D", false),
      (
        "typedef (Other or long) Value; typedef (Value or D) Other;", "Value", "DOMString?",
        false,
      ),
      (
        "typedef (Other or long) Value; typedef (D or Value) Other;", "Value", "DOMString?",
        false,
      ),
      ("typedef sequence<Value> Value;", "Value", "DOMString?", true),
      (
        "typedef (sequence<Other> or long) Value; typedef (Value or D?) Other;",
        "Value", "DOMString?", true,
      ),
      (
        "typedef (Value or long) Value; typedef (Other or boolean) Other;", "Value",
        "Other", true,
      ),
      (
        "typedef (Value or long?) Value; typedef (Other or boolean?) Other;", "Value",
        "Other", false,
      ),
    ] {
    assert_eq(
      check_distinguishable_types(left, right, typedef_source=definitions),
      expected,
    )
  }
}
