///|
fn name_of_interface(interface : Interface) -> StringView {
  strip_underscore(interface.identifier)
}

///|
fn interface_object_names(interfaces : Array[Interface]) -> Set[StringView] {
  Set(
    interfaces
    .filter(interface => {
      !interface.extended_attribute_list
      .iter()
      .any(is_valid_legacy_no_interface_object)
    })
    .map(name_of_interface),
  )
}

///|
fn name_of_interface_mixin(interface_mixin : InterfaceMixin) -> StringView {
  strip_underscore(interface_mixin.identifier)
}

///|
fn name_of_partial_interface(
  partial_interface : PartialInterface,
) -> StringView {
  strip_underscore(partial_interface.identifier)
}

///|
fn name_of_definition(definition : Definition) -> StringView? {
  match definition {
    Callback({ identifier: name, .. })
    | CallbackInterface({ identifier: name, .. })
    | Namespace({ identifier: name, .. })
    | PartialInterfaceMixin({ identifier: name, .. })
    | PartialDictionary({ identifier: name, .. })
    | PartialNamespace({ identifier: name, .. })
    | Dictionary({ identifier: name, .. })
    | Enum({ identifier: name, .. })
    | Typedef({ identifier: name, .. }) => Some(strip_underscore(name))
    Interface(interface) => Some(name_of_interface(interface))
    InterfaceMixin(interface_mixin) =>
      Some(name_of_interface_mixin(interface_mixin))
    PartialInterface(partial_interface) =>
      Some(name_of_partial_interface(partial_interface))
    _ => None
  }
}

///|
fn name_of_attribute(attribute : Attribute) -> StringView raise {
  let name = match attribute.name {
    AttributeNameKeyword(Required) => "required"[:]
    Identifier(name) => name
  }

  let name = strip_underscore(name)

  // The identifier of a static attribute must not be "prototype".

  if attribute.tag is (StaticReadOnly | StaticReadWrite) && name is "prototype" {
    fail("The identifier of a static attribute must not be \"prototype\".")
  }

  name
}

///|
fn name_of_dictionary_member(x : @parser.DictionaryMemberRest) -> StringView {
  let name = match x {
    Required(_, name) => name
    Optional(_, name, _) => name
  }

  strip_underscore(name)
}

///|
fn name_of_operation(operation : Operation) -> StringView? raise {
  guard operation.name is Some(name) else { None }

  let name = match name {
    OperationNameKeyword(Includes) => "includes"[:]
    Identifier(name) => name
  }

  let name = strip_underscore(name)

  assert_false(operation.tag is Static && name == "prototype")

  Some(name)
}

///|
fn name_of_primitive_type(type_ : @parser.PrimitiveType) -> StringView {
  match type_ {
    Boolean => "boolean"
    Bigint => "bigint"
    Byte => "byte"
    Octet => "octet"
    UnsignedIntegerType(IntegerType(Short)) => "short"
    UnsignedIntegerType(IntegerType(Long(None))) => "long"
    UnsignedIntegerType(IntegerType(Long(Long))) => "long long"
    UnsignedIntegerType(UnsignedIntegerType(Short)) => "unsigned short"
    UnsignedIntegerType(UnsignedIntegerType(Long(None))) => "unsigned long"
    UnsignedIntegerType(UnsignedIntegerType(Long(Long))) => "unsigned long long"
    UnrestrictedFloatType(FloatType(Float)) => "float"
    UnrestrictedFloatType(FloatType(Double)) => "double"
    UnrestrictedFloatType(UnrestrictedFloatType(Float)) => "unrestricted float"
    UnrestrictedFloatType(UnrestrictedFloatType(Double)) =>
      "unrestricted double"
  }
}

///|
fn name_of_string_type(type_ : @parser.StringType) -> StringView {
  match type_ {
    DOMString => "DOMString"
    ByteString => "ByteString"
    USVString => "USVString"
  }
}

///|
fn name_of_buffer_type(type_ : @parser.BufferRelatedType) -> StringView {
  match type_ {
    ArrayBuffer => "ArrayBuffer"
    SharedArrayBuffer => "SharedArrayBuffer"
    DataView => "DataView"
    Int8Array => "Int8Array"
    Int16Array => "Int16Array"
    Int32Array => "Int32Array"
    Uint8Array => "Uint8Array"
    Uint16Array => "Uint16Array"
    Uint32Array => "Uint32Array"
    Uint8ClampedArray => "Uint8ClampedArray"
    BigInt64Array => "BigInt64Array"
    BigUint64Array => "BigUint64Array"
    Float16Array => "Float16Array"
    Float32Array => "Float32Array"
    Float64Array => "Float64Array"
  }
}
