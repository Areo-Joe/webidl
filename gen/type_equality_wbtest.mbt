///|
fn check_same_type(
  left : String,
  right : String,
  typedef_source~ : String = "",
) -> Bool raise {
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
  fn parse_type(source : String) -> @parser.TypeWithExtendedAttributes raise {
    let (type_, rest) = @parser.TypeWithExtendedAttributes::parse(
      @lexer.tokenize(source).exact_view(),
    ).unwrap()
    assert_true(rest is [])
    type_
  }
  let left = parse_type(left)
  let right = parse_type(right)
  let left_attributes = left.extended_attribute_list.iter().collect()
  let right_attributes = right.extended_attribute_list.iter().collect()
  let result = same_type(
    left.type_,
    right.type_,
    typedefs,
    left_attributes~,
    right_attributes~,
  )
  assert_eq(
    result,
    same_type(
      right.type_,
      left.type_,
      typedefs,
      left_attributes=right_attributes,
      right_attributes=left_attributes,
    ),
  )
  assert_true(
    same_type(
      left.type_,
      left.type_,
      typedefs,
      left_attributes~,
      right_attributes=left_attributes,
    ),
  )
  result
}

///|
test "Type equality preserves primitive string buffer and named type identities" {
  let types = [
    "any", "boolean", "byte", "octet", "short", "unsigned short", "long", "unsigned long",
    "long long", "unsigned long long", "float", "unrestricted float", "double", "unrestricted double",
    "bigint", "DOMString", "USVString", "ByteString", "object", "symbol", "undefined",
    "ArrayBuffer", "SharedArrayBuffer", "DataView", "Int8Array", "Int16Array", "Int32Array",
    "Uint8Array", "Uint16Array", "Uint32Array", "Uint8ClampedArray", "BigInt64Array",
    "BigUint64Array", "Float16Array", "Float32Array", "Float64Array", "I", "J",
  ]
  for i in 0..<types.length() {
    for j in 0..<types.length() {
      assert_eq(check_same_type(types[i], types[j]), i == j)
    }
  }
  assert_true(check_same_type("I", "_I"))
}

///|
test "Type equality preserves outer nullability and type attributes" {
  for
    (left, right, expected) in [
      ("long", "long?", false),
      ("long?", "long?", true),
      ("DOMString", "DOMString?", false),
      ("I", "_I?", false),
      ("sequence<long>", "sequence<long>?", false),
      ("async_sequence<long>", "async_sequence<long>?", false),
      ("record<DOMString, long>", "record<DOMString, long>?", false),
      ("FrozenArray<long>", "FrozenArray<long>?", false),
      ("Uint8Array", "Uint8Array?", false),
      ("(long or DOMString)", "(long or DOMString)?", false),
      ("(long or DOMString)?", "(DOMString or long)?", true),
      ("long", "[Clamp] long", false),
      ("[Clamp] long", "[Clamp] long", true),
      ("[Clamp, Clamp] long", "[Clamp] long", true),
      ("[Clamp] long?", "[Clamp] long", false),
      ("[Clamp] long", "[EnforceRange] long", false),
      (
        "[AllowShared, AllowResizable] Uint8Array", "[AllowResizable, AllowShared] Uint8Array",
        true,
      ),
      (
        "[AllowShared] Uint8Array", "[AllowShared, AllowResizable] Uint8Array", false,
      ),
    ] {
    assert_eq(check_same_type(left, right), expected)
  }
}

///|
test "Type equality resolves typedef nullability and associated attributes" {
  let definitions = "typedef long _Number; typedef Number? Maybe; typedef [Clamp] long Clamped; typedef [AllowShared] Uint8Array Shared; typedef (long or DOMString) Value; typedef sequence<Maybe> Values;"
  for
    (left, right, expected) in [
      ("Number", "long", true),
      ("_Number", "long?", false),
      ("Maybe", "long?", true),
      ("Maybe", "Number?", true),
      ("Maybe", "long", false),
      ("Clamped", "[Clamp] long", true),
      ("[Clamp] Clamped", "Clamped", true),
      ("Clamped", "long", false),
      ("Clamped?", "[Clamp] long?", true),
      ("Shared", "[AllowShared] Uint8Array", true),
      (
        "[AllowResizable] Shared", "[AllowShared, AllowResizable] Uint8Array", true,
      ),
      ("Value", "(DOMString or long)", true),
      ("Value?", "(DOMString or long)?", true),
      ("Value?", "Value", false),
      ("Values", "sequence<long?>", true),
      ("Promise<Clamped>", "Promise<long>", false),
      ("Promise<Clamped>", "Promise<Clamped>", true),
    ] {
    assert_eq(
      check_same_type(left, right, typedef_source=definitions),
      expected,
    )
  }
}

///|
test "Type equality retains nested nullability attributes and container kinds" {
  for
    (left, right, expected) in [
      ("sequence<long>", "sequence<long?>", false),
      ("sequence<[Clamp] long>", "sequence<long>", false),
      ("sequence<[Clamp] long>", "sequence<[Clamp] long>", true),
      ("sequence<long>", "async_sequence<long>", false),
      ("sequence<long>", "FrozenArray<long>", false),
      ("FrozenArray<long>", "ObservableArray<long>", false),
      ("record<DOMString, long>", "record<USVString, long>", false),
      ("record<DOMString, long>", "record<DOMString, long?>", false),
      ("record<DOMString, [Clamp] long>", "record<DOMString, long>", false),
      ("Promise<long>", "Promise<long?>", false),
      ("Promise<long>", "Promise<DOMString>", false),
      ("(long or DOMString)", "(DOMString or long)", true),
      (
        "(long or (DOMString or boolean))", "(boolean or long or DOMString)", true,
      ),
      ("(long or long)", "(long or long or long)", true),
      ("(long or DOMString)", "(long or boolean)", false),
      ("(long? or DOMString)", "(long or DOMString)", false),
      ("([Clamp] long or DOMString)", "(long or DOMString)", false),
      ("sequence<(long? or DOMString)>", "sequence<(long or DOMString)>", false),
    ] {
    assert_eq(check_same_type(left, right), expected)
  }
}

///|
test "Type equality propagates union attributes before comparing member types" {
  for
    (left, right, expected) in [
      (
        "[AllowShared] (Uint8Array or DataView)", "[AllowShared] ([AllowShared] Uint8Array or DataView)",
        true,
      ),
      (
        "[AllowShared] (Uint8Array or DataView)", "[AllowShared] (Uint8Array or [AllowShared] DataView)",
        true,
      ),
      (
        "[AllowShared] (Uint8Array or DataView)", "[AllowShared] ([AllowResizable] Uint8Array or DataView)",
        false,
      ),
      (
        "sequence<[AllowShared] (Uint8Array or DataView)>", "sequence<[AllowShared] ([AllowShared] Uint8Array or DataView)>",
        true,
      ),
      (
        "[AllowShared] ((Uint8Array or DataView) or Int8Array)", "[AllowShared] (Uint8Array or (DataView or [AllowShared] Int8Array))",
        true,
      ),
    ] {
    assert_eq(check_same_type(left, right), expected)
  }
}

///|
test "Type equality terminates on recursive typedefs without losing nested differences" {
  for
    (definitions, left, right, expected) in [
      ("typedef sequence<A> A; typedef sequence<B> B;", "A", "B", true),
      ("typedef sequence<A> A; typedef sequence<B> B;", "A?", "B", false),
      ("typedef sequence<A> A; typedef sequence<B?> B;", "A", "B", false),
      ("typedef sequence<A> A; typedef sequence<[Clamp] B> B;", "A", "B", false),
      ("typedef (A or long) A; typedef (B or long) B;", "A", "B", true),
      ("typedef (A or long) A; typedef (B or double) B;", "A", "B", false),
      (
        "typedef (sequence<A> or long) A; typedef (sequence<B> or long) B;", "A",
        "B", true,
      ),
      (
        "typedef (sequence<A> or [Clamp] long) A; typedef (sequence<B> or long) B;",
        "A", "B", false,
      ),
      (
        "typedef (sequence<A> or Uint8Array) A; typedef (sequence<B> or [AllowShared] Uint8Array) B;",
        "[AllowShared] A", "[AllowShared] B", false,
      ),
    ] {
    assert_eq(
      check_same_type(left, right, typedef_source=definitions),
      expected,
    )
  }
}

///|
test "Flattened member equality continues to ignore only outer nullability and attributes" {
  let (definitions, rest) = @parser.parse(
    @lexer.tokenize("typedef [Clamp] long Clamped;").exact_view(),
  )
  assert_true(rest is [])
  let typedefs = Map([])
  for definition in Definition::from_parser(definitions) {
    if definition is Typedef(typedef_) {
      typedefs.set(strip_underscore(typedef_.identifier), typedef_)
    }
  }
  for
    (left, right, expected) in [
      ("long", "long?", true),
      ("Clamped", "long", true),
      ("sequence<long>", "sequence<long>?", true),
      ("sequence<long?>", "sequence<long>", false),
      ("sequence<Clamped>", "sequence<long>", false),
    ] {
    assert_eq(
      same_flattened_member_type(
        parse_distinguishable_type(left),
        parse_distinguishable_type(right),
        typedefs,
      ),
      expected,
    )
  }
}
