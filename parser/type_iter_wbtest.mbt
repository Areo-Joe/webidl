///|
test "Union member type iteration preserves direct member order and nullable markers" {
  let (type_, rest) = Type::parse(
    @lexer.tokenize(
      "([Example] long? or (DOMString or boolean)? or sequence<long?>)",
    ).exact_view(),
  ).unwrap()
  assert_true(rest is [])
  guard type_ is UnionType(union_type, None) else {
    fail("Expected a union type")
  }
  let types = union_type.iter_member_types().collect()
  assert_eq(types.length(), 3)
  assert_true(
    types[0] is SingleType(DistinguishableType(PrimitiveType(_, Some))),
  )
  assert_true(types[1] is UnionType(_, Some))
  assert_true(types[2] is SingleType(DistinguishableType(Sequence(_, None))))
}

///|
fn type_iteration_label(type_ : Type) -> String {
  fn nullable_label(label : String, null : Null) -> String {
    match null {
      Some => label + "?"
      None => label
    }
  }

  match type_ {
    UnionType(_, null) => nullable_label("union", null)
    SingleType(Any) => "any"
    SingleType(PromiseType(_)) => "Promise"
    SingleType(DistinguishableType(type_)) =>
      match type_ {
        PrimitiveType(primitive, null) => {
          let label = match primitive {
            Boolean => "boolean"
            Byte => "byte"
            Octet => "octet"
            Bigint => "bigint"
            UnsignedIntegerType(IntegerType(Short)) => "short"
            UnsignedIntegerType(UnsignedIntegerType(Short)) => "unsigned short"
            UnsignedIntegerType(IntegerType(Long(None))) => "long"
            UnsignedIntegerType(UnsignedIntegerType(Long(None))) =>
              "unsigned long"
            UnsignedIntegerType(IntegerType(Long(Long))) => "long long"
            UnsignedIntegerType(UnsignedIntegerType(Long(Long))) =>
              "unsigned long long"
            UnrestrictedFloatType(FloatType(Float)) => "float"
            UnrestrictedFloatType(UnrestrictedFloatType(Float)) =>
              "unrestricted float"
            UnrestrictedFloatType(FloatType(Double)) => "double"
            UnrestrictedFloatType(UnrestrictedFloatType(Double)) =>
              "unrestricted double"
          }
          nullable_label(label, null)
        }
        StringType(string_type, null) =>
          nullable_label(
            match string_type {
              DOMString => "DOMString"
              ByteString => "ByteString"
              USVString => "USVString"
            },
            null,
          )
        Identifier(name, null) => nullable_label(name.to_owned(), null)
        Sequence(_, null) => nullable_label("sequence", null)
        AsyncSequence(_, null) => nullable_label("async_sequence", null)
        FrozenArray(_, null) => nullable_label("FrozenArray", null)
        ObservableArray(_, null) => nullable_label("ObservableArray", null)
        RecordType(_, null) => nullable_label("record", null)
        Object(null) => nullable_label("object", null)
        Symbol(null) => nullable_label("symbol", null)
        BufferRelatedType(_, null) => nullable_label("buffer", null)
        Undefined(null) => nullable_label("undefined", null)
      }
  }
}

///|
test "Type iteration visits nested types in preorder and preserves nullable markers" {
  for
    (source, expected) in [
      ("long", ["long"]),
      ("long?", ["long?"]),
      ("any", ["any"]),
      ("object?", ["object?"]),
      ("symbol", ["symbol"]),
      ("ArrayBuffer?", ["buffer?"]),
      ("undefined", ["undefined"]),
      ("sequence<FrozenArray<long?>>", ["sequence", "FrozenArray", "long?"]),
      (
        "(DOMString or sequence<long>)?",
        ["union?", "DOMString", "sequence", "long"],
      ),
      ("Promise<sequence<DOMString>>", ["Promise", "sequence", "DOMString"]),
      (
        "sequence<ObservableArray<long>?>",
        ["sequence", "ObservableArray?", "long"],
      ),
      ("async_sequence<Promise<byte>>?", ["async_sequence?", "Promise", "byte"]),
      (
        "record<USVString, sequence<octet>>?",
        ["record?", "USVString", "sequence", "octet"],
      ),
      (
        "record<ByteString, record<DOMString, boolean>>",
        ["record", "ByteString", "record", "DOMString", "boolean"],
      ),
      (
        "(sequence<long> or FrozenArray<long>)",
        ["union", "sequence", "long", "FrozenArray", "long"],
      ),
      (
        "((long or DOMString)? or boolean or sequence<byte>)",
        ["union", "union?", "long", "DOMString", "boolean", "sequence", "byte"],
      ),
    ] {
    let tokens = @lexer.tokenize(source)
    let (type_, rest) = Type::parse(tokens.exact_view()).unwrap()
    assert_true(rest is [])
    let actual = type_.iter_types().map(type_iteration_label).collect()
    assert_eq(actual, expected)
  }
}

///|
test "Type iteration stops at identifier references" {
  for
    (source, expected) in [
      ("Alias?", ["Alias?"]),
      ("sequence<Alias>", ["sequence", "Alias"]),
      ("(Alias or _Alias?)", ["union", "Alias", "_Alias?"]),
    ] {
    let tokens = @lexer.tokenize(source)
    let (type_, rest) = Type::parse(tokens.exact_view()).unwrap()
    assert_true(rest is [])
    assert_eq(type_.iter_types().map(type_iteration_label).collect(), expected)
  }
}

///|
test "Type iteration preserves extended attributes on existing type nodes" {
  let tokens = @lexer.tokenize("sequence<[Clamp] long>")
  let (type_, rest) = Type::parse(tokens.exact_view()).unwrap()
  assert_true(rest is [])
  let types = type_.iter_types().collect()
  assert_eq(types.length(), 2)
  assert_true(
    types[0] is SingleType(DistinguishableType(Sequence(inner, None))) &&
    inner.extended_attribute_list.iter().count() > 0,
  )
  assert_true(
    types[1]
    is SingleType(
      DistinguishableType(
        PrimitiveType(UnsignedIntegerType(IntegerType(Long(None))), None)
      )
    ),
  )
}
