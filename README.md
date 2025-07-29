# C3 JVMS

### Dissasemble classfiles:
run `c3c run main -- resources/Simple.class`

```cpp
fn void main(String[] args)
{
    @pool() {
        read_class(args);
    };
}
```

### REPL
run `./scripts/repl.sh`

### Compiler
> c3c build

> watchexec -e ty ./build/main resources/simple.ty

### Development
compile: `c3c build`

run: `c3c run main`

test: `c3c test` or `watchexec -e c3 c3c test`

compiler: `watchexec -e c3 -e ty c3c run main -- resources/simple.ty`

# Key design principles
- fast compilation (low-latency, simple passes, minimal runtime)
- predicatble memory model (value vs reference control)
- interop with jvm
- no runtime reflection

# Roadmap
1. Finish struct system
    [x] default values in struct
    [x] struct can be partially initialized
    [ ] deep field initializaiton (foo.bar.baz = 1)
    [ ] structs can be passed by value and reference
    [ ] mut?

2. Function & calling
    [ ] inlinable calls

3. Control flow
    [ ] while (...) {...}
    [ ] match
    [ ] compile-time constant folding for conditions

4. Low-level JVM control
    [ ] & reference to structs or variables
    [ ] &mut?

5. JVM codegen
    [ ] how to map from struct to classes
    [ ] fields = private + getter/setter generation?
    [ ] compile-to-bytecode pipeline
    [ ] boxing/unboxing strategy for primitives vs objects

6. Standard library skeleton
    [x] builtins
    [x] collection types (array, map)
    [ ] option/result types

7. Advanced
    [ ] traits
    [x] inline functions/macros
    [ ] pattern matching destructuring structs
    [ ] JVM annotation support (@Test, @JvmStatic) 
    [ ] gradual null-safety (str?, unwrap(), try, etc)
    [ ] unsafe blocks for advanced control

# Features
## Control flow
[x] if/else expressions
[ ] while loops
[ ] for loops
[ ] match
[ ] pattern matching (match x { 1 => "one", _ => "other" })

## Functions
[x] function definitions
[x] function calls
[x] closures

## Types
[x] let bindings (with type annotation)
[ ] type checking
[ ] type aliases (type Point = (i32, i32))

## Modules
[ ] basic module system
[ ] use keyword

## Struct and object extensions
[x] structs with fields and default values
[x] dot access
[ ] nested struct support
[ ] struct methods (impl)
[ ] new constructor function support
[ ] field validation or immutability (readonly or mut)

## Strings
[ ] string interpolation ("Hello $name")
[ ] multiline strings/raw strings

## Arithmetic + std lib
[x] built-ins
[x] basic math operations

## Memory & safety
[x] GC (use jvm)
[ ] Pass by reference

## Ergonomics
[x] REPL
[x] pretty printing structs
[x] better error messages with line/column info
[x] comments //
[x] destructing (let (x, y) = point)

## Advanced
[ ] Enums or sum types (enum Result { Ok, Err} )
[x] macros (not up to date)
[ ] Generics (fn identity<T>(x: T))
[ ] traits
[ ] coroutines

