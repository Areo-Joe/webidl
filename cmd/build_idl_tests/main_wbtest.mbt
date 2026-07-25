///|
fn wpt_file(name : String) -> WptFile {
  WptFile::{ name, }
}

///|
test "generate one independently named test per IDL file" {
  let output = generate_test_source([wpt_file("dom.idl"), wpt_file("html.idl")])
  assert_true(output.contains("async test \"WPT: dom.idl\""))
  assert_true(output.contains("parse_wpt_idl_fixture(\"dom.idl\")"))
  assert_true(output.contains("async test \"WPT: html.idl\""))
  assert_true(output.contains("first unconsumed token"))
}

///|
test "exclude WPT IDL with constructors in partial interfaces" {
  assert_true(exclude_wpt_idl("webrtc-ice.idl"))
  assert_true(exclude_wpt_idl("mediacapture-surface-control.idl"))
  assert_true(!exclude_wpt_idl("dom.idl"))
}

///|
test "generate fixture provenance" {
  let output = generate_readme(2)
  assert_true(output.contains("https://wpt.live/interfaces/"))
  assert_true(output.contains("Files: 2"))
  assert_true(output.contains("constructors in partial interfaces"))
}
