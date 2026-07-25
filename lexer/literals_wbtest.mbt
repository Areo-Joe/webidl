///|
test "tokenize every generated keyword terminal" {
  for keyword in keywords {
    match (try! tokenize(keyword)) {
      [(Keyword, text)] => assert_eq(text, keyword[:])
      _ => fail("keyword was not tokenized as a keyword")
    }
  }
}

///|
test "tokenize every generated punctuation terminal" {
  for punctuation in punctuation {
    match (try! tokenize(punctuation)) {
      [(Punctuation, text)] => assert_eq(text, punctuation[:])
      _ => fail("punctuation was not tokenized as punctuation")
    }
  }
}
