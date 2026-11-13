///|
struct Operation {
  type_ : @parser.Type
  name : @parser.OperationName?
  argument_list : @parser.ArgumentList
  tag : OperationTag
}

///|
enum OperationTag {
  Regular
  Static
  Getter
  Setter
  Deleter
}

///|
fn Operation::from_interface_member(
  interface_member : InterfaceMember,
) -> Operation? {
  match interface_member.body {
    PartialInterfaceMember(x) => Operation::from_partial_interface_member(x)
    _ => None
  }
}

///|
fn Operation::from_partial_interface_member(
  partial_interface_member : @parser.PartialInterfaceMember,
) -> Operation? {
  match partial_interface_member {
    Operation(
      RegularOperation(
        { type_, operation_rest: { optional_operation_name, argument_list, }, }
      )
    ) =>
      Some(Operation::{
        type_,
        name: match optional_operation_name {
          Some(name) => Some(name)
          None => None
        },
        argument_list,
        tag: Regular,
      })
    Operation(
      SpecialOperation(
        {
          regular_operation: {
            type_,
            operation_rest: { optional_operation_name, argument_list, },
          },
          special,
        }
      )
    ) =>
      Some(Operation::{
        type_,
        name: match optional_operation_name {
          Some(name) => Some(name)
          None => None
        },
        argument_list,
        tag: match special {
          Getter => Getter
          Setter => Setter
          Deleter => Deleter
        },
      })
    StaticMember(
      {
        static_member_rest: RegularOperation(
          {
            type_,
            operation_rest: { optional_operation_name, argument_list, },
          }
        ),
      }
    ) =>
      Some(Operation::{
        type_,
        name: match optional_operation_name {
          Some(name) => Some(name)
          None => None
        },
        argument_list,
        tag: Static,
      })
    _ => None
  }
}

///|
fn Operation::from_interface_mixin_member(
  interface_mixin_member : @parser.MixinMember,
) -> Operation? {
  match interface_mixin_member {
    RegularOperation(
      { type_, operation_rest: { optional_operation_name, argument_list, }, }
    ) =>
      Some(Operation::{
        type_,
        name: match optional_operation_name {
          Some(name) => Some(name)
          None => None
        },
        argument_list,
        tag: Regular,
      })
    _ => None
  }
}

///|
fn Operation::from_namespace_member(
  namespace_member : @parser.NamespaceMember,
) -> Operation? {
  match namespace_member {
    RegularOperation(
      { type_, operation_rest: { optional_operation_name, argument_list, }, }
    ) =>
      Some(Operation::{
        type_,
        name: match optional_operation_name {
          Some(name) => Some(name)
          None => None
        },
        argument_list,
        tag: Regular,
      })
    _ => None
  }
}

///|
fn Operation::from_callback_interface_member(
  callback_interface_member : @parser.CallbackInterfaceMember,
) -> Operation? {
  match callback_interface_member {
    RegularOperation(
      { type_, operation_rest: { optional_operation_name, argument_list, }, }
    ) =>
      Some(Operation::{
        type_,
        name: match optional_operation_name {
          Some(name) => Some(name)
          None => None
        },
        argument_list,
        tag: Regular,
      })
    _ => None
  }
}
