///|
test "parse valid Web IDL" {
  let _ = @webidl.parse(
    "[Exposed=Window] interface Example { readonly attribute DOMString name; };",
  )
}

///|
test "parse empty Web IDL" {
  let _ = @webidl.parse("")
}

///|
test "parse rejects malformed Web IDL" {
  let raised = try @webidl.parse("interface Example {}") catch {
    _ => true
  } noraise {
    _ => false
  }
  assert_true(raised)
}

///|
test "parse rejects trailing input" {
  let raised = try @webidl.parse("interface Example {}; trailing") catch {
    _ => true
  } noraise {
    _ => false
  }
  assert_true(raised)
}
