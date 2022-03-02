---
title: Casperlang
---

The Casper programming language
===============================

Properties of *casper*:

* a pure functional language, inspired by [Haskell](https://www.haskell.org/)
* a focus on simplicity, with a minimal number of language concepts
* `;` and `=` are operators
* pattern matching instead of traditional typing
* dynamic dispatch, allowing OOP-style patterns without explicit language support
* indents are only significant for statements (function defintions and `import`)
* JSON is valid syntax

This page acts as a reference document for the concrete compiler implementation (wip).

### 1. Getting started

#### REPL

In the REPL you can type:
```python
echo "Hello world"
```

`echo` is a low-level builtin function and takes a single `String` value as an argument. 

Functions are called without parentheses. The arguments are separated by whitespace.

#### Script

An example of a hello world script:
```python
# main.cas (comments start with the # symbol)
main = echo "Hello world"
```

Here `main` is a function which takes no arguments.

Note that the `echo` function actually returns an `IO` object, which acts as an OS action.

### 2. Strings

#### Literals

Literal strings are denoted by `"..."` (double quotes). Single quotes and backticks aren't used for literal strings (and could be made available as operators).

Literal strings support expression substitution. Stringable expressions can be inserted into a literal string using `${...}`.

The `\` character is used for escaping:

* newline character `\n`
* tab character     `\t`
* the `\` character itself
* the `$` character
* the `"` character

#### String operations

Contrary to many other languages, a `String` in *casper* isn't treated as a list of char-like integers. Strings are treated as primitives in their own right.

*casper* has some builtin functions to be able to manipulate strings.

Length:
```python
len "hello world" # 11
```

Concatenation: 
```haskell
"hello " + "world"
```

Getting a character:
```python
echo "hello world".0 # "h"
echo "hello world".0. 0 # also "h"
# without the whitespace we would be calling . "hello world" Float
```

Convert to a list of integers:
```python
toInts "hello world" # [104,101,108,108,111,32,119,111,114,108,100]
```

Convert a list of integers to a string:
```python
toString [104,101,108,108,111,32,119,111,114,108,100] # "hello world"
```

### 3. Numbers

*casper* has builtin support for integers and floating-point numbers (`Int` and `Float` respectively). 

#### Integers

`Int` represents an underlying 64-bit signed integer.

Literal integers can be written as follows:
```python
1
0b1  # binary
0x01 # hex
0o1  # octal
```

#### Floating-point numbers

`Float` represents an underlying 64-bit double precision floating-point number.

Literal floats can be written as follows:
```python
1.0
1e0
0.1e1
0.01e+2
10.0e-1
1e-0
```

The `.` by itself is used as an operator, and for convenience the floating part of literal floats can't start or end with a `.` (in those cases the `.` would be interpreted as an operator symbol, and the number part would end up as an `Int`).

The scientific notation exponent uses an `e` but **not** an `E` (nowadays `E` seems to be less common anyway).

Many core mathematical functions are available as builtin functions (`+`, `-`, `*`, `/`, `sqrt`, `pow`, `exp`, `log` etc.)

### 4. Bool

A `Bool` value in *casper* is a builtin enum-like type. A `Bool` value can be instantiated using the `True` or `False` constructor functions.

`Bool` values are returned by comparison functions `>`, `>=`, `<`, `<=`, `==`, `!=`. The `&&` operator should be used for logical *and*, the `||` operator should be used for logical *or*.

### 5. Lists

Literal lists are denoted by `[...]`. The list items are comma separated expressions.

Due to immutability a list can also be handled as a tuple (useful in pattern-matching).

#### List operations

Length:
```python
len [1,2,3,4] # 4
```

Concatenation:
```python
[1,2] + [3,4]
```

Reduction:
```python
fold \($+$) 0 [1,2,3,4] # sum==10
```

Indexing:
```python
[1,2,3,4].0    # 1
[1,2,3,4].(-1) # 4
```

Map:
```python
map \($*2) [1,2,3,4] # [2,4,6,8]
```

Sorting:
```python
sort \($<$) [3,2,4,1] # [1,2,3,4]
```

### 6. Dicts

Literal dicts are denoted by `{...}`. The dict items are comma separated `key:value` pairs. 

Keys can be words or literal strings, and always end up as strings. Keys can't be expressions. 
Dict values can be arbitrary expressions.

The colon, separating key from value, is parsed as a context specific symbol, and not an operator, so dict values can contain other colons as actual operators.

Dicts in *casper* preserve the order of their entries.

#### Dict operations

Length:
```python
len {qty: 100, price: 0.9} # 2
```

Merging:
```python
{qty: 100} + {price: 0.9}
```

### 7. Branching

There is a builtin `if` function. It's first argument is a `Bool` value, it's second argument is a value returned upon a `True` condition, it's last argument is the else condition value:
```python
max a b = if (a>b) a b
```

### 8. Functions

Functions can be defined at file scope with function statements.

The most basic function is a function that doesn't take any arguments:
```python
greeting = "hello world"
```

*casper* isn't really a typed language and you can't specify the return type of a function. Function arguments support pattern-matching though:
```python
# no pattern-matching on argument
greeting name         = "hello " + name 
#
# constructor pattern-matching on argument
greeting name::String = "hello " + name 
```

Pattern-matching can be nameless:
```python
# convert a Bool into a String
show True  = "true"
show False = "false"
```

The function definition body is always a single expression. This expression doesn't necessarily need to appear on the same line as the `=` symbol though. It can appear indented on the next line:
```python
# returns an IO object
main =
  echo "hello world"
```

The function defintion body ends when all groups are matched and the indent-level of the next line is the same as the indent-level of the function header.

#### Chained expressions

Multiple indented expressions are chained together using the `;` operator:
```python
main =
  # syntactic sugar for (echo "message 1\n"; echo "message 2\n"):
  echo "message 1\n";
  echo "message 2\n";  # final semicolon is optional (ignored by compiler)
```

Note there is no [automatic semicolon insertion](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Lexical_grammar#automatic_semicolon_insertion) in *casper* ([read more](#whitespace-discussion))

#### Assignment expression

Consider the following simple program:
```python
# greeter program
main =
  echo "what is your name?";
  name = readLine;
  echo "hello " + name
```

The `=` symbol is treated as a ternary operator at the same precedence level as the `;` symbol. Both are right-to-left assiociative. So this simple program is actually syntactic sugar for:
```python
# pseudo code!
(echo "what is your name?"); (= (readLine) \(name = $; echo "hello " + name)) 
```

Note that the `readLine` function is an asynchronous OS function that calls a callback upon completion. `readLine`'s callback is everything following the assignment expression.

Now take a look at this example:
```python
calcDistance x0::Float y0::Float x1::Float y1::Float = 
  dx = x1 - x0;
  dy = y1 - y0;
  sqrt dx*dx + dy*dy
```

There is no IO, but we are using intermediate variables for better readability/DRYness. `calcDistance`'s body is syntactic sugar for:
```python
calcDistance x0::Float y0::Float x1::Float y1::Float =
  # pseudo code!
  (= (x1 - x0) \(dx = $; = (y1 - y0) \(dy = $; sqrt dx*dx+dy*dy))) 
```

The `=` operator here is simply defined as:
```python
= a fn::\1 = fn a
```

#### Anonymous functions

You might've noticed anonymous functions several times above. They are denoted by `\(...)`, and contain `$`'s where arguments are substituted.

An anonymous function that adds two numbers, concatenates two strings/lists, merges two dicts, etc.:
```
\($ + $)
```

The arguments can be numbered:
```
\($1+$2) # all (or none) must be numbered
```

Because the types of the arguments of an anonymous function are unknown, nested pattern-matching of an anonymous function's arguments isn't possible. We can only pattern-match the number of arguments. `\1` matches an anonymous function that takes 1 argument, `\2` matches 2 arguments, etc. There is no `\0` anonymous function and there is no pattern for an arbitrary number of arguments.

An anonymous function can reference external variables (i.e. can be a closure).

### 9. Constructors

Functions that start with capital letters are constructors. Each constructor can only be defined once (i.e. constructors can't be overloaded).

Constructors add tags to their return values, and values can have a hierarchy of attached tags depending on how constructor calls are nested. Constructor tags can be used for pattern-matching.

#### Primitive tags

There are some primitive tags that don't have an associated constructor:

* `Int`
* `Float`
* `String`
* `[]`
* `{}`

In order to construct a value with any of these primitive tags you must use literals or builtin readers/converters.

`Any` is a special builtin constructor. All values have `Any` as a top-level tag. 

The builtin definition of `Bool` might look like:
```python
# Note it is legal but nonsensical to call Bool directly
Bool  = Any  
True  = Bool
False = Bool
```

Constructor arguments can be used in pattern-matching:
```python
# the arguments don't need to be used in the rhs
Pair Any Any = Any 
#
# stringify a Pair
show (Pair a b) = (show a) + " " + (show b)
```

#### Interfaces

*casper* doesn't have support for interfaces or type classes. But something analogous can be achieved by defining panicking methods dispatched on a base type:
```python
Number = Any
== Number Number = panic "not yet implemented"
+  Number Number = panic "not yet implemented"
-  Number Number = panic "not yet implemented"
-  Number        = panic "not yet implemented"
*  Number Number = panic "not yet implemented"
```
```python
Stringable = Any
show Stringable = panic "not yet implemented"
```

*Implementing* multiple interfaces isn't (yet) possible as the needed type-union operator could be abused and result in unclear function dispatching (see [diamond problem](https://en.wikipedia.org/wiki/Multiple_inheritance)).

### 10. IO

`IO` actions are usually client-server style queries, which might be performed asynchronously. The result of an `IO` function call is unwrapped using the `=` operator. The result can be an `Error`, `Ok`, void, or some non-error data.

`File` and `Dir`, both inheriting from `Path`, are wrappers for `String` that dispatch filesystem-specific functions.

Overview of builtin `IO` functions:

* `echo`, print to stdout, returns `IO <void>`
* `readLine`, read a single line from the terminal stdin, returns `IO String`
* `readArgs`, returns a list of command-line arguments, including the name of the script (but not the name of the parser), returns `IO ([] String)`
* `read File`, returns `IO (Error String)` or `IO String`
* `write File`, returns `IO (Error String)` or `IO Ok`
* `send (HttpReq method::String url::String payload::String)`, performs an http request, returns `IO (Error String)` if the status isn't 200 or timeout etc., or `IO data::String`

### 11. Pattern-matching

Pattern-matching is a powerful alternative to overloading functions based on argument types.

#### Named pattern-matching

The most basic pattern creates some named arguments. Argument variable names must start with lowercase letters:
```python
add a b = a + b
```

Named pattern-matching can be nested (which is called *destructuring*):
```python
# [a,b] and [c,d] are destructured tuples
dot [a,b] [c,d] = a*c + b*d 
#
echo (show (dot [1,2] [3,4]))   # 11
#
# with piping
dot [1,2] [3,4] | show | echo   # 11
```

The `_` name acts as sink and doesn't create a variable:
```python
first  [a,_] = a
second [_,b] = b
```

Note that instead of `_` you could also use `Any`:
```python
first [a,Any] = a
# or
first [a,_::Any] = a
# or
first [a::Any,_::Any] = a
```

#### Tag pattern-matching

Tags can be matched without creating a variable, as shown in this example:
```python
# card suit enum
Suit    = Any
Club    = Suit
Heart   = Suit
Spade   = Suit
Diamond = Suit

# eq
== Club    Club    = True
== Heart   Heart   = True
== Spade   Spade   = True
== Diamond Diamond = True
== Suit    Suit    = False
```

#### Named tags pattern-matching

Sometimes we might want to match a tag **and** create a variable. The `::` operator is used for that:
```python
# card constructor
Card Int Suit = Any

# return the winning card
max trump::Suit a::(Card ia sa) b::(Card ib sb) =
  if (sb == sa) (
    if (ib > ia) b a
  ) ( # else
    if (sb == trump) b a
  )
```

#### Container pattern-matching

There are 2 container types:

* `[]` (i.e. lists)
* `{}` (i.e. dicts)

We can match lists and dicts with arbitrary content by using the empty brackets or braces:
```python
isList []  = True
isList Any = False
isDict {}  = True
isDict Any = False
```

The empty brackets or braces can be given a parameter, in order to match specific content:
```python
isStringList ([] String) = True
isStringList ([] Any)    = False

isStringListDict ({} ([] String)) = True
isStringListDict ({} Any)         = False
```
Note that the parentheses can only be used for argument/parameter matching and can't be used to arbitrarily nest pattern-matching expressions.

Destructuring can be used inside list or dict pattern-matches:
```python
# the pattern-matching turns a and b into lists
flatten ([] (Pair a b)) = fold \($+$) [] (zip a b)
```

The content of tuples, or dicts with known entries, can also be destructured:
```python
mag [a::Float,b::Float] = sqrt a*a + b*b
# the price variable shadows function definitions
price {qty: _, price: price} = price 
```

Note that all lists can be treated as tuples.

### 12. Multiple dispatch

Non-constructor functions can be defined multiple times with different arguments. The function that is eventually dispatched depends on the following:

1. first the functions are filtered that have the correct number of arguments
2. then (nested) pattern-matching generates vectors of scores, the lower the score the better the match
3. the function with the longest score vector is selected
4. if there is a tie, then the function with the best score for every score component is selected
5. remaining ambiguity throws an error

Each score component corresponds to a single tag match. For example a value constructed with `True` matches the `True` tag pattern with a score of `0`, the `Bool` tag pattern with a score of `1`, and the `Any` tag pattern with a score of `2`.

Another example:
```python
Vec2 a::Float b::Float = [a,b]
#
# would match (Vec2 1.0 1.0) with score [0,0,0]
mag (Vec2 a::Float b::Float) = sqrt a*a + b*b 
#
# would match (Vec2 1.0 1.0) with score [0,2,2]
mag (Vec2 a b)               = sqrt a*a + b*b 
#
# would match (Vec2 1.0 1.0) with score [1,0,0]
mag [a::Float, b::Float]     = sqrt a*a + b*b 
```

Note that an ambiguity error would be thrown if the first version of `mag` wasn't defined.

### 13. Modules

All source files in the same directory are part of the same module.

Functions defined in any file of a given module can be called from any other file in the same module, without the need for an `import` statement.

Non-constructor functions are attached to locally defined constructor tags, or to the module scope in case those tags were defined outside that module.

#### Importing local modules

Import statements must appear first in source files:

```python
import "./<sub-module-relative-to-current-dir>"
import "/<sub-module-relative-to-project-root>"
```

Errors are thrown when modules try to import themselves, or when circular module dependencies are encountered.

#### Module private functions

Functions and constructors with a `_` prefix are never exported, and are private to a module.

#### Importing external modules

External modules are declared in a `package.json` file in the project root:
```json
{
  "dependencies": {
    "std": {
      "version": "0.1.2",
      "url"    : "github.com/openengineer/casperlang-stdlib"
    }
  }
}
``` 
In this example the *casper* standard library can be imported as follows:
```python
#main.cas
import "std"
#
main = 
  println "the std library contains many basic functions"
```

Note that there is no namespacing mechanism, and libraries have to be designed carefully to avoid name-conflicts when being imported.

It is also possible to only access sub-modules of external modules:
```python
import "std/css"
#
genStyleSheet = (
  h = 4:rem;
  CSS (
    body (
      nav (
        flex "hsc";
        h1 (lineHeight h; fontWeight "normal");

        id "app-links" (
          height h; flex "hsc";
          a (
            cursor "pointer";
            hasAttr "active" (fontWeight "bold"; color "black"; hover (color "black"))
          )
        )
      )
    )
  )
)
```

### A. Discussion: significant whitespace inside expressions {#whitespace-discussion}

Significant whitespace inside expressions could be implemented as *ASI* and automatic parenthesis insertion.

This might allow getting rid of some ugly parentheses, but inlining chained expressions would be less apparent. And in some fringe cases it would be hard for the user to guess where semicolons and parentheses would be inserted.

Significant whitespace doesn't seem to provide an overwhelming advantage for expressions, so that's why I've decided to make *casper* a mostly non-significant-whitespace language (indents are only significant for `import` statements and function bodies).

For comparison I've written a version of the css example using significant whitespace inside expressions:
```python
import "std/css"
# example with automatic semicolon and parentheses insertion
genStyleSheet = 
  h = 4:rem
  CSS
    body
      nav
        flex "hsc"

        h1
          lineHeight h
          fontWeight "normal"

        id "app-links"
          height h
          flex "hsc"

          a
            cursor "pointer"

            hasAttr "active"
              fontWeight "bold"
              color "black"

              hover
                color "black"
```
