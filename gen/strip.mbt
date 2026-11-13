///|
fn strip_underscore(s : StringView) -> StringView {
  match s.get_char(0) {
    Some('_') => s[1:]
    _ => s
  }
}
