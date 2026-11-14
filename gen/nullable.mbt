///|
/// The inner type must not be:
/// * an observable array type,
fn check_nullable_type_no_observable_array(type_ : @parser.Type) -> Unit raise {
  assert_false(
    type_
    .iter_types()
    .any(type_ => {
      type_ is SingleType(DistinguishableType(ObservableArray(_, Some)))
    }),
  )
}

///|
fn check_nullable_argument_types_no_observable_array(
  arguments : @parser.ArgumentList,
) -> Unit raise {
  for argument in arguments.iter() {
    let type_ = match argument.argument_rest {
      Optional(type_with_extended_attributes, _, _) =>
        type_with_extended_attributes.type_
      Ellipsisable(type_, _, _) => type_
    }
    check_nullable_type_no_observable_array(type_)
  }
}
