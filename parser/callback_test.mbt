///|
fn callback_tokens(input : String) -> @parser.Tokens {
  (try! @lexer.tokenize(input)).view()
}

///|
test "CallbackRest parses empty and populated argument lists" {
  assert_true(
    @parser.CallbackRest::parse(callback_tokens("Handler = long(); tail"))
    is Some((_, [(_, "tail")])),
  )
  assert_true(
    @parser.CallbackRest::parse(
      callback_tokens(
        "Handler = long(DOMString value, optional long count); tail",
      ),
    )
    is Some((_, [(_, "tail")])),
  )
}

///|
test "CallbackInterfaceMember parses every alternative" {
  assert_true(
    @parser.CallbackInterfaceMember::parse(
      callback_tokens("const long value = 1; tail"),
    )
    is Some((@parser.CallbackInterfaceMember::Const(_), [(_, "tail")])),
  )
  assert_true(
    @parser.CallbackInterfaceMember::parse(
      callback_tokens("long invoke(); tail"),
    )
    is Some(
      (@parser.CallbackInterfaceMember::RegularOperation(_), [(_, "tail")])
    ),
  )
}

///|
test "CallbackInterfaceMembers parses epsilon without consuming input" {
  assert_true(
    @parser.CallbackInterfaceMembers::parse(callback_tokens("tail"))
    is (@parser.CallbackInterfaceMembers::None, [(_, "tail")]),
  )
}

///|
test "CallbackRestOrInterface parses callback functions and interfaces" {
  assert_true(
    @parser.CallbackRestOrInterface::parse(
      callback_tokens("Handler = long(); tail"),
    )
    is Some((@parser.CallbackRestOrInterface::CallbackRest(_), [(_, "tail")])),
  )
  assert_true(
    @parser.CallbackRestOrInterface::parse(
      callback_tokens(
        "interface Handler { [Clamp] const long value = 1; long invoke(); }; tail",
      ),
    )
    is Some((@parser.CallbackRestOrInterface::Interface(_, _), [(_, "tail")])),
  )
  assert_true(
    @parser.CallbackRestOrInterface::parse(
      callback_tokens("interface Empty {}; tail"),
    )
    is Some((@parser.CallbackRestOrInterface::Interface(_, _), [(_, "tail")])),
  )
}

///|
test "Callback productions reject unsupported and malformed input" {
  assert_true(
    @parser.CallbackRest::parse(callback_tokens("Handler long();")) is None,
  )
  assert_true(
    @parser.CallbackRest::parse(callback_tokens("Handler = long()")) is None,
  )
  assert_true(
    @parser.CallbackRestOrInterface::parse(
      callback_tokens("interface Handler { attribute DOMString name; };"),
    )
    is None,
  )
  assert_true(
    @parser.CallbackRestOrInterface::parse(
      callback_tokens("interface Handler { getter long item(); };"),
    )
    is None,
  )
}
