# Fetch the WebIDL specification and regenerate lexer literal tables.
generate-literals:
  moon run cmd/build && moon fmt

# Fetch WPT IDL fixtures and generate one test per file.
generate-idl-tests:
  moon run cmd/build_idl_tests && moon fmt
