///|
#derive(Eq, Debug)
priv enum Optionality {
  Required
  Optional
  Variadic
}

///|
priv struct OverloadType {
  type_ : @parser.Type
  extended_attributes : Array[@parser.ExtendedAttribute]
}

///|
priv struct EffectiveOverload[T] {
  callable : T
  types : Array[OverloadType]
  optionality : Array[Optionality]
}

///|
fn[T] compute_effective_overload_set(
  callables : Array[(T, @parser.ArgumentList)],
  argument_count : Int32,
) -> Array[EffectiveOverload[T]] {
  let arguments = callables.map(callable => callable.1.iter().collect())
  let mut maxarg = 0
  for arguments in arguments {
    maxarg = Int32::max(maxarg, arguments.length())
  }
  let max = Int32::max(maxarg, argument_count)
  let result : Array[EffectiveOverload[T]] = []
  for index in 0..<callables.length() {
    let callable = callables[index].0
    if result.any(item => physical_equal(item.callable, callable)) {
      continue
    }
    let arguments = arguments[index]
    let n = arguments.length()
    let types = []
    let optionality = []
    for i in 0..<n {
      let argument = arguments[i]
      let (type_, value) = match argument.argument_rest {
        Optional(type_, _, _) => (type_.type_, Optionality::Optional)
        Ellipsisable(type_, ellipsis, _) =>
          (
            type_,
            if i == n - 1 && ellipsis is Some {
              Variadic
            } else {
              Required
            },
          )
      }
      types.push(OverloadType::{
        type_,
        extended_attributes: argument_type_extended_attributes(argument),
      })
      optionality.push(value)
    }
    result.push({ callable, types, optionality, })
    if n > 0 && optionality[n - 1] == Variadic {
      for i in n..<max {
        let t = types.copy()
        let o = optionality.copy()
        for _ in n..<=i {
          t.push(types[n - 1])
          o.push(Variadic)
        }
        result.push({ callable, types: t, optionality: o, })
      }
    }
    let mut i = n - 1
    while i >= 0 {
      if optionality[i] == Required {
        break
      }
      result.push({
        callable,
        types: types[:i].to_owned(),
        optionality: optionality[:i].to_owned(),
      })
      i -= 1
    }
  }
  result
}

///|
fn[T] distinguishing_argument_index(
  overloads : Array[EffectiveOverload[T]],
  typedefs : Map[StringView, TypeDef],
  definitions : Map[StringView, Definition],
) -> Int32? {
  guard overloads.length() > 1 else { return None }
  for i in 0..<overloads[0].types.length() {
    let mut distinguishable = true
    for j in 0..<overloads.length() {
      for k in (j + 1)..<overloads.length() {
        if !are_types_distinguishable(
            overloads[j].types[i].type_,
            overloads[k].types[i].type_,
            typedefs,
            definitions,
          ) {
          distinguishable = false
          break
        }
      }
      if !distinguishable {
        break
      }
    }
    if distinguishable {
      return Some(i)
    }
  }
  None
}

///|
fn[T] check_effective_overload_set(
  overloads : Array[EffectiveOverload[T]],
  typedefs : Map[StringView, TypeDef],
  definitions : Map[StringView, Definition],
) -> Unit raise {
  let sizes = Set([])
  for overload in overloads {
    sizes.add(overload.types.length())
  }
  for size in sizes {
    let items = overloads.filter(overload => overload.types.length() == size)
    if items.length() <= 1 {
      continue
    }
    let index = distinguishing_argument_index(items, typedefs, definitions)
    assert_true(index is Some(_))
    guard index is Some(index) else { continue }
    let mut has_bigint = false
    let mut has_numeric = false
    for item in items {
      let (type_, _, _) = resolve_type_with_extended_attributes(
        item.types[index].type_,
        [],
        typedefs,
      )
      match type_category(type_, definitions) {
        Some(Bigint) => has_bigint = true
        Some(Numeric) => has_numeric = true
        _ => ()
      }
      for j in 0..<index {
        let left = items[0].types[j]
        let right = item.types[j]
        assert_true(
          same_type(
            left.type_,
            right.type_,
            typedefs,
            left_attributes=left.extended_attributes,
            right_attributes=right.extended_attributes,
          ),
        )
        assert_eq(items[0].optionality[j], item.optionality[j])
      }
    }
    assert_false(has_bigint && has_numeric)
  }
}
