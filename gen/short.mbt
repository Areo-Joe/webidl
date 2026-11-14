///|
/// The short type corresponds to 16-bit signed integers.
/// short constant values in IDL are represented with integer tokens.
fn check_short_constant_value(value : @parser.ConstValue) -> Unit raise {
  let number = integer_constant_value(value)
  assert_true(number >= -32768 && number <= 32767)
}
