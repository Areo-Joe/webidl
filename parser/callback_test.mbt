///|
fn callback_tokens(input : String) -> Tokens {
  (try! @lexer.tokenize(input)).view()
}

///|
test "CallbackRest parses empty and populated argument lists" {
  assert_true(
    CallbackRest::parse(callback_tokens("Handler = long(); tail"))
    is Some((_, [(_, "tail")])),
  )
  assert_true(
    CallbackRest::parse(
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
    CallbackInterfaceMember::parse(
      callback_tokens("const long value = 1; tail"),
    )
    is Some((CallbackInterfaceMember::Const(_), [(_, "tail")])),
  )
  assert_true(
    CallbackInterfaceMember::parse(callback_tokens("long invoke(); tail"))
    is Some((CallbackInterfaceMember::RegularOperation(_), [(_, "tail")])),
  )
}

///|
test "CallbackInterfaceMembers parses epsilon without consuming input" {
  assert_true(
    CallbackInterfaceMembers::parse(callback_tokens("tail"))
    is (CallbackInterfaceMembers::None, [(_, "tail")]),
  )
}

///|
test "CallbackRestOrInterface parses callback functions and interfaces" {
  assert_true(
    CallbackRestOrInterface::parse(callback_tokens("Handler = long(); tail"))
    is Some((CallbackRestOrInterface::CallbackRest(_), [(_, "tail")])),
  )
  assert_true(
    CallbackRestOrInterface::parse(
      callback_tokens(
        "interface Handler { [Clamp] const long value = 1; long invoke(); }; tail",
      ),
    )
    is Some((CallbackRestOrInterface::Interface(_, _), [(_, "tail")])),
  )
  assert_true(
    CallbackRestOrInterface::parse(callback_tokens("interface Empty {}; tail"))
    is Some((CallbackRestOrInterface::Interface(_, _), [(_, "tail")])),
  )
}

///|
test "Callback productions reject unsupported and malformed input" {
  assert_true(CallbackRest::parse(callback_tokens("Handler long();")) is None)
  assert_true(CallbackRest::parse(callback_tokens("Handler = long()")) is None)
  assert_true(
    CallbackRestOrInterface::parse(
      callback_tokens("interface Handler { attribute DOMString name; };"),
    )
    is None,
  )
  assert_true(
    CallbackRestOrInterface::parse(
      callback_tokens("interface Handler { getter long item(); };"),
    )
    is None,
  )
}
