///|
fn parse_mixin_member(input : String) -> (@parser.MixinMember, @parser.Tokens)? {
  @parser.MixinMember::parse((try! @lexer.tokenize(input)).exact_view())
}

///|
test "MixinMember parses every alternative" {
  assert_true(
    parse_mixin_member("const long value = 1; tail")
    is Some((@parser.MixinMember::Const(_), [(_, "tail")])),
  )
  assert_true(
    parse_mixin_member("long operation(); tail")
    is Some((@parser.MixinMember::RegularOperation(_), [(_, "tail")])),
  )
  assert_true(
    parse_mixin_member("stringifier; tail")
    is Some((@parser.MixinMember::Stringifier(_), [(_, "tail")])),
  )
  assert_true(
    parse_mixin_member("attribute DOMString name; tail")
    is Some(
      (
        @parser.MixinMember::Attribute(@parser.OptionalReadOnly::None, _),
        [(_, "tail")],
      )
    ),
  )
  assert_true(
    parse_mixin_member("readonly attribute DOMString name; tail")
    is Some(
      (
        @parser.MixinMember::Attribute(@parser.OptionalReadOnly::ReadOnly, _),
        [(_, "tail")],
      )
    ),
  )
}

///|
test "MixinMember rejects unsupported members" {
  assert_true(parse_mixin_member("getter long item();") is None)
  assert_true(parse_mixin_member("inherit attribute DOMString name;") is None)
  assert_true(parse_mixin_member("readonly long operation();") is None)
}
