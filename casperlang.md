---
title: Casperlang
---

The Casper programming language
===============================

Properties of *casper*:

* a pure functional language, inspired by [Haskell](https://www.haskell.org/)
* a focus on simplicity, with a minimal number of language concepts
* pattern matching instead of typing
* dynamic dispatch, allowing OOP-style patterns without explicit language support
* whitespace and indentations are significant, allowing very readable nested declarations

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

Note that the `echo` function actually returns an `IO` object, which acts as a list of OS actions.

### 2. Strings

#### Literals

Literal strings are denoted by `"..."` (double quotes). Single quotes and backticks aren't used for literal strings (but are instead available as operators).

Literal strings support expression substitution. Stringable expressions can be inserted into a literal string using `${...}`.

The `\` character is used for escaping:

* newline character `\n`
* tab character     `\t`
* the `\` character itself
* the `$` character
* the `"` character

Note that `\` is generally not available as an operator outside literal strings.

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

`Int` represents an underlying 32-bit signed integer.

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
foldl \(_+_) 0 [1,2,3,4] # sum==10
```

Indexing:
```python
[1,2,3,4].0    # 1
[1,2,3,4].(-1) # 4
```

Map:
```python
map \(_*2) [1,2,3,4] # [2,4,6,8]
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

There is a builtin `ifelse` function. It's first argument is a `Bool` value, it's second argument is a value returned upon a `True` condition, it's last argument is the else condition value. If there are more than 3 arguments, the third argument is the `Bool` value of the first `elif` block, etc.

Because using the `ifelse` function directly can become unreadable, *casper* provides `if`, `elif` and `else` keywords as a special operator with very low precedence:
```python
max a b c = if a>b && a>c  a elif b>c  b else c
#
# alternative formatting:
max a b c =
  if   a>b && a>c
    a
  elif b>c
    b
  else # the else block must always exist
    c
```

This is syntactic sugar for `ifelse (a>b&&a>c) a (b>c) b c`.

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

#### Chained expressions

Multiple indented expressions are chained together using the `;` operator. Semicolons are automatically inserted where newlines are encountered between expressions of the same indent level, except after binary operators.
```python
main =
  # syntactic sugar for (echo "message 1\n"; echo "message 2\n"):
  echo "message 1\n"
  echo "message 2\n" 
```

Note that a semicolon wouldn't have been inserted in the following 2 cases:
```python
main = echo "message 1"
  echo "message 2"
```
```python
main = echo "message 1" echo "message 2"
```

In these 2 cases you would actually be calling `echo String IO`.

#### Assignment expression

Consider the following simple program:
```python
# greeter program
main =
  echo "what is your name?"
  name = read
  echo "hello " + name
```

First the parser inserts semicolons:
```python
# greeter program
main =
  echo "what is your name?";
  name = read;
  echo "hello " + name
```

The `=` symbol is treated as a ternary operator at the same precedence level as the `;` symbol. Both are right-to-left assiociative. So this simple program is actually syntactic sugar for:
```python
# pseudo code!
(echo "what is your name?"); (= (read) \(name = _; echo "hello " + name)) 
```

Note that the `read` function is an asynchronous OS function that calls a callback upon completion. `read`'s callback is everything following the assignment expression.

Now take a look at this example:
```python
calcDistance x0::Float y0::Float x1::Float y1::Float = 
  dx = x1 - x0
  dy = y1 - y0
  sqrt dx*dx + dy*dy
```

There is no IO, but we are using intermediate variables for better readability/DRYness. `calcDistance`'s body is syntactic sugar for:
```python
calcDistance x0::Float y0::Float x1::Float y1::Float =
  # pseudo code!
  (= (x1 - x0) \(dx = _; = (y1 - y0) \(dy = _; sqrt dx*dx+dy*dy))) 
```

The `=` operator here is simply defined as:
```python
= a fn::\1 = fn a
```

#### Anonymous functions

You might've noticed anonymous functions several times above. They are denoted by `\(...)`, and contain `_`'s where arguments are substituted.

An anonymous function that adds two numbers, concatenates two strings/lists, merges two dicts, etc.:
```
\(_ + _)
```

Using an assignment expression and a tuple destructuring pattern, this can look like an anonymous function in a more conventional language:
```
\([a,b] = [_,_]; a+b)
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

If you would like your type to *implement* from multiple *interfaces* then the builtin `&` operator can be used:
```python
MyType = Number & Stringable
```

Values that match `MyType` will also match `Number` and `Stringable`. Think of `&` as a union operator.

### 10. Pattern-matching

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
echo show dot [1,2] [3,4]   # 11
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
  if sb == sa
    if (ib > ia)     b else a
  else
    if (sb == trump) b else a
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
flatten ([] (Pair a b)) = foldl \(_+_) [] (zip a b)
```

The content of tuples, or dicts with known entries, can also be destructured:
```python
mag [a::Float,b::Float] = sqrt a*a + b*b
# the price variable shadows function definitions
price {qty: _, price: price} = price 
```

Note that all lists can be treated as tuples.

### 11. Multiple dispatch

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
mag (Vec2 a b)             = sqrt a*a + b*b 
#
# would match (Vec2 1.0 1.0) with score [1,0,0]
mag [a::Float, b::Float]     = sqrt a*a + b*b 
```

Note that an ambiguity error would be thrown if the first version of `mag` wasn't defined.

### 12. Modules

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

#### Importing external modules

External modules are declared in a `package.json` file in the root of your project:
```json
{
  "dependencies": {
    "std": {
      "version": "1.0.0",
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
  println "number formatting is implemented in the std library"
  printf  "eg: %.02f\n" 1.0
```

Note that there is no namespacing mechanism, and libraries have to be designed carefully to avoid name-conflicts when being imported.

It is also possible to only access sub-modules of external modules:
```python
import "std/css"
#
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

#### Module private functions

Functions and constructors with a `_` prefix are never exported, and are private to a module.
