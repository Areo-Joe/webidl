///|
/// The unsigned short type corresponds to 16-bit unsigned integers.
/// unsigned short constant values in IDL are represented with integer tokens.
fn check_unsigned_short_constant_value(
  value : @parser.ConstValue,
) -> Unit raise {
  let number = integer_constant_value(value)
  assert_true(number >= 0 && number <= 65535)
}
