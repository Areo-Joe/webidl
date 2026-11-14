///|
/// The bigint type is an arbitrary integer type, unrestricted in range.
/// bigint constant values in IDL are represented with integer tokens.
fn check_bigint_constant_value(value : @parser.ConstValue) -> Unit raise {
  assert_true(value is Integer(_))
}
