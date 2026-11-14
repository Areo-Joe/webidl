///|
/// The long long type corresponds to 64-bit signed integers.
/// long long constant values in IDL are represented with integer tokens.
fn check_long_long_constant_value(value : @parser.ConstValue) -> Unit raise {
  let number = integer_constant_value(value)
  assert_true(number >= -9223372036854775808L && number <= 9223372036854775807L)
}
