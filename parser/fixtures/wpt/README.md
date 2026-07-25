# WPT Web IDL fixtures

These files are copied byte-for-byte from interfaces/*.idl in the
web-platform-tests/wpt repository:
https://github.com/web-platform-tests/wpt

- Source: https://wpt.live/interfaces/
- Files: 333, including *.tentative.idl

Run moon run cmd/build_idl_tests to replace the fixtures from WPT Live
and regenerate parser/wpt_generated_test.mbt.

Do not edit the IDL fixtures locally.