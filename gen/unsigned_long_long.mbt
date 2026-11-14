///|
/// The unsigned long long type corresponds to 64-bit unsigned integers.
/// unsigned long long constant values in IDL are represented with integer tokens.
fn check_unsigned_long_long_constant_value(
  value : @parser.ConstValue,
) -> Unit raise {
  let number = unsigned_integer_constant_value(value)
  assert_true(number >= 0 && number <= 18446744073709551615UL)
}
