///|
fn wpt_file(name : String) -> WptFile {
  WptFile::{ name, }
}

///|
test "generate one independently named test per IDL file" {
  let output = generate_test_source([
    wpt_file("dom.idl"),
    wpt_file("webrtc-ice.idl"),
  ])
  assert_true(output.contains("async test \"WPT: dom.idl\""))
  assert_true(output.contains("parse_wpt_idl_fixture(\"dom.idl\")"))
  assert_true(output.contains("async test \"WPT: webrtc-ice.idl\""))
  assert_true(output.contains("first unconsumed token"))
}

///|
test "generate fixture provenance" {
  let output = generate_readme(2)
  assert_true(output.contains("https://wpt.live/interfaces/"))
  assert_true(output.contains("Files: 2"))
}
