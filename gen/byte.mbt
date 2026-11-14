///|
/// The byte type corresponds to 8-bit signed integers.
/// byte constant values in IDL are represented with integer tokens.
fn check_byte_constant_value(value : @parser.ConstValue) -> Unit raise {
  let number = integer_constant_value(value)
  assert_true(number >= -128 && number <= 127)
}
