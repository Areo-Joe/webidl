///|
/// The unsigned long type corresponds to 32-bit unsigned integers.
/// unsigned long constant values in IDL are represented with integer tokens.
fn check_unsigned_long_constant_value(value : @parser.ConstValue) -> Unit raise {
  let number = integer_constant_value(value)
  assert_true(number >= 0 && number <= 4294967295L)
}
