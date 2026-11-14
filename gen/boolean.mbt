///|
/// boolean constant values in IDL are represented with the true and false tokens.
fn check_boolean_constant_value(value : @parser.ConstValue) -> Unit raise {
  assert_true(value is BooleanLiteral(_))
}
