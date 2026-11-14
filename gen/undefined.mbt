///|
/// undefined must not be used as the type of an argument in any circumstance
/// (in an operation, callback function, constructor operation, etc), or as the
/// type of a dictionary member, whether directly or in a union.
/// Instead, use an optional argument or a non-required dictionary member.
fn check_type_not_undefined(
  type_ : @parser.Type,
  typedefs : Map[StringView, TypeDef],
) -> Unit raise {
  let pending = [type_]
  let visited : Set[StringView] = Set([])
  while pending.pop() is Some(type_) {
    assert_false(type_ is SingleType(DistinguishableType(Undefined(_))))
    match type_ {
      UnionType(union_type, _) =>
        pending.push_iter(union_type.iter_member_types())
      SingleType(DistinguishableType(Identifier(identifier, _))) => {
        let name = strip_underscore(identifier)
        if !visited.contains(name) && typedefs.get(name) is Some(typedef_) {
          visited.add(name)
          pending.push(typedef_.type_with_extended_attributes.type_)
        }
      }
      _ => ()
    }
  }
}
