// =============================================================================
// font-lock.mbt  --  moonbit-mode font-lock verification
//
// ert-font-lock アノテーション形式を使用する。
// treesit-font-lock-level 4 (全フィーチャ有効) を前提とする。
// =============================================================================

// ─────────────────────────────────────────────────────────────────────────────
// Level 1: comment
// ─────────────────────────────────────────────────────────────────────────────

// 行コメント
// <- font-lock-comment-face

/* ブロックコメント */
// <- font-lock-comment-face

// ─────────────────────────────────────────────────────────────────────────────
// Level 1: definition  (定義名のハイライト)
// ─────────────────────────────────────────────────────────────────────────────

fn greet(name : String) -> String {
// <- font-lock-keyword-face
// ^^^^^ font-lock-function-name-face
  "Hello, \{name}!"
}

struct Point {
// <- font-lock-keyword-face
//     ^^^^^ font-lock-type-face
  x : Int
  y : Int
}

enum Direction {
// <- font-lock-keyword-face
//   ^^^^^^^^^ font-lock-type-face
  North
  South
  East
  West
}

trait Printable {
// <- font-lock-keyword-face
//    ^^^^^^^^^ font-lock-type-face
  fn print(Self) -> Unit
}

const MAX_SIZE : Int = 100
//    ^^^^^^^^ font-lock-constant-face

test "addition works" {
//   ^^^^^^^^^^^^^^^^ font-lock-function-name-face
  assert_eq!(1 + 1, 2)
}

// ─────────────────────────────────────────────────────────────────────────────
// Level 2: keyword
// ─────────────────────────────────────────────────────────────────────────────

fn keywords_demo(n : Int) -> Int {
  if n > 0 {
//^^ font-lock-keyword-face
    return n
//  ^^^^^^ font-lock-keyword-face
  } else {
//  ^^^^ font-lock-keyword-face
    0
  }
}

fn match_demo(d : Direction) -> String {
  match d {
//^^^^^ font-lock-keyword-face
    North => "north"
    South => "south"
    _ => "other"
  }
}

fn loop_demo() -> Int {
  let mut i = 0
//^^^ font-lock-keyword-face
  while i < 10 {
//^^^^^ font-lock-keyword-face
    i = i + 1
  }
  for j in [1, 2, 3] {
//^^^ font-lock-keyword-face
//      ^^ font-lock-keyword-face
    i = i + j
  }
  i
}

// ─────────────────────────────────────────────────────────────────────────────
// Level 2: string
// ─────────────────────────────────────────────────────────────────────────────

fn string_demo() -> Unit {
  let s1 = "hello"
//         ^^^^^^^ font-lock-string-face
  let s2 = "line\nbreak"
//              ^^ font-lock-escape-face
  let name = "world"
  let s3 = "hi \{name}"
//         ^^^^^^^^^^^^ font-lock-string-face
  let s4 =
    #|
    multiline string
    |#
  ignore(s1)
  ignore(s2)
  ignore(s3)
  ignore(s4)
}

// ─────────────────────────────────────────────────────────────────────────────
// Level 3: type
// ─────────────────────────────────────────────────────────────────────────────

fn type_demo(x : Int, s : String) -> Bool {
//               ^^^ font-lock-builtin-face
//                        ^^^^^^ font-lock-builtin-face
//                                   ^^^^ font-lock-builtin-face
  x > 0
}

fn generic_demo[T : Show](x : T) -> String {
//              ^ font-lock-type-face
//                  ^^^^ font-lock-builtin-face
  x.to_string()
}

// ─────────────────────────────────────────────────────────────────────────────
// Level 3: constant
// ─────────────────────────────────────────────────────────────────────────────

fn constant_demo() -> Unit {
  let t = true
//        ^^^^ font-lock-constant-face
  let f = false
//        ^^^^^ font-lock-constant-face
  ignore(t)
  ignore(f)
  let d = Direction::North
//                   ^^^^^ font-lock-type-face
}

// ─────────────────────────────────────────────────────────────────────────────
// Level 3: number
// ─────────────────────────────────────────────────────────────────────────────

fn number_demo() -> Unit {
  let a = 42
//        ^^ font-lock-number-face
  let b = 3.14
//        ^^^^ font-lock-number-face
  let c = 0xFF
//        ^^^^ font-lock-number-face
  let d = 0b1010
//        ^^^^^^ font-lock-number-face
  let e = 'A'
//        ^^^ font-lock-string-face
  ignore(a)
  ignore(b)
  ignore(c)
  ignore(d)
  ignore(e)
}

// ─────────────────────────────────────────────────────────────────────────────
// Level 3: attribute
// ─────────────────────────────────────────────────────────────────────────────

#[deprecated("use greet instead")]
// <- font-lock-preprocessor-face
fn old_greet() -> String { "hi" }

// ─────────────────────────────────────────────────────────────────────────────
// Level 3: variable
// ─────────────────────────────────────────────────────────────────────────────

fn variable_demo() -> Unit {
  let count = 0
//    ^^^^^ font-lock-variable-name-face
  let mut total = 0
//        ^^^^^ font-lock-variable-name-face
  for item in [1, 2, 3] {
//    ^^^^ font-lock-variable-name-face
    total = total + item
  }
  ignore(count)
}

fn param_demo(x : Int, name~ : String) -> Unit {
//            ^ font-lock-variable-name-face
//                     ^^^^ font-lock-variable-name-face
  ignore(x)
  ignore(name)
}

struct WithFields {
  label : String
//^^^^^ font-lock-property-name-face
  value : Int
//^^^^^ font-lock-property-name-face
}

fn field_access_demo(w : WithFields) -> String {
  w.label
//  ^^^^^ font-lock-property-use-face
}

// ─────────────────────────────────────────────────────────────────────────────
// Level 4: function
// ─────────────────────────────────────────────────────────────────────────────

fn function_call_demo() -> Unit {
  let v = [1, 2, 3]
  let n = v.length()
//          ^^^^^^ font-lock-function-call-face
  let s = Int::to_string(42)
//             ^^^^^^^^^ font-lock-function-call-face
  ignore(n)
  ignore(s)
}

// ─────────────────────────────────────────────────────────────────────────────
// Level 4: operator
// ─────────────────────────────────────────────────────────────────────────────

fn operator_demo(a : Int, b : Int) -> Bool {
  let _ = a + b
//          ^ font-lock-operator-face
  let _ = a == b
//          ^^ font-lock-operator-face
  a > b
//  ^ font-lock-operator-face
}

// ─────────────────────────────────────────────────────────────────────────────
// Level 4: bracket
// ─────────────────────────────────────────────────────────────────────────────

fn bracket_demo() -> Unit {
  let arr = [1, 2, 3]
//          ^ font-lock-bracket-face
  let tup = (1, "two")
//          ^ font-lock-bracket-face
  let blk = { 42 }
//          ^ font-lock-bracket-face
  ignore(arr)
  ignore(tup)
  ignore(blk)
}

// ─────────────────────────────────────────────────────────────────────────────
// Level 4: delimiter
// ─────────────────────────────────────────────────────────────────────────────

fn delimiter_demo(a : Int, b : Int) -> Unit {
//                       ^ font-lock-delimiter-face
  ignore(a)
  ignore(b)
}
