---
title: "Go: First Impressions"
date: 2019-04-16T08:16:47+02:00
featuredImage: "thumbnail.jpg"
description: "My first impressions of the Go language"
categories:
  - language
tags:
  - language
draft: true
---


## Imports and Project Structure

Go has a very opinionated way to handle imports. It works like this:

Go expects all code to be in `$HOME/go`, or for the `$GOPATH` evironment variable to point to where the code home path is. 

The top level structure inside is

* bin: Where installed executables go
* pkg: Compiled packages
* src: Where all source packages go

The general expectation is that you'll preface directories under `src` based on where they came from. So a package from github should be placed under `src/github.com/someuser/somepackage`


Upsides:

* There's never any confusion about how to find packages. No classpath hell like in Java.

Downsides:

* It forces you to put everything in a go-specific directory, rather than your own projects dir.
* Since it's sharing namespace with all your github repos, you have to name things "go-xyz", which means that people have to `import "github.com/someuser/go-something"` and then hope that the package inside is actually `something` and not `go-something`.
This conflicts with https://golang.org/doc/code.html#PackageNames

"Go's convention is that the package name is the last element of the import path: the package imported as "crypto/rot13" should be named rot13."

But there's nothing you can do.

Overall, I think this was a bad decision. It's imposing new constraints on outside systems (the file system), which makes things very brittle and hacky. Other languages like Python and Rust handle this a lot more elegantly.


### Building

`go build` is not a build system. It can compile one thing, or it can clumsily compile lots of things. You can use `go build ./...` to blindly build all `.go` files it finds in all subdirs. NEVER call `go build ...` because it will try to build EVERYTHING in `$GOPATH`, including the unbuildable crap in `golang.org`. Because of course you'd want this... Lots of projects end up using makefiles, which is terrible.


### Style

* `{` must be on the same line as the statement leading to it.
* Parentheses not needed in conditional and loop statements.
* Mixed case over underscores.


### Surprising things

* Restrictions on const arrays.
* `goto`, especially since defer solves the main problem goto solves (resource cleanup).
* Strings are immutable
* type conversions must be explicit
* `for` is used for all loop types
* Braces always required for conditionals and loop statements.
* `switch` cases break by default
* No pointer arithmetic


### Annoying things

* unused things are compilation errors. https://github.com/ronelliott/go/commit/fc52f452ee85fcf0661e4a4594bd336b1ae5a144
-- https://github.com/dtnewman/modified_golang_compiler/commit/5cab9a98a4a6780a6c8d042092bedd581c0df97e
-- go run -gcflags '-unused_pkgs' test.go
-- goimports
-- https://golang.org/doc/faq#unused_variables_and_imports
- cyclic imports not allowed

Their reasoning is silly and insultingly paternalist, and their solution is an even worse one. Requiring someone to manually take out a hack before pushing code is just asking for it to be forgotten. Since the go tool is no longer able to catch those errors (because you've put in a hack to circumvent it), it's now on the fallible human to do it right. Far better to have a command line switch that TEMPORARILY disables the problematic behavior, and then when you compile without the switch every place you need to fix is suddenly visible.


### Cool Things

* Multiple return values
* iota
* named return values
* functions are first class objects
* var vs := (short variable declarations)
* defined zero values
* shifts > object size is allowed
* Conditionals with a short statement.
* switch cases don't need to be constants, or integers. They can be expressions.
* switch with no value to switches on `true`, which means the first case that is true gets executed. Basically if/else/else/...
* defer runs code when function returns. They stack LIFO
* break to label

- https://golang.org/doc/effective_go.html#for


### Same Things

* Language is pass-by-value, so arguments are copied.


### Pointers

Uses familiar & and *
Garbage collected
Pointers to structs don't need to be (*p).Field, you can use p.Field. (no explicit dereference)


### Classes

No classes, only structs and interfaces.
You create structs, and define methods, which are objects with receiver arguments.
- can have a receiver for anything in the same package
Pointer recievers can modify the pointed to object.
- methods with pointer receivers automatically imply & when called with a value rather than pointer.
- calling methods with a nil receiver is allowed.

duck typing. If it implements all interface methods, it's enough.

### Arrays

Arrays can't be resized.
Use slices inside of array. A slice is like a reference to a part of an array.
You can of course create slices of slices
for loops support ranges like in python: https://tour.golang.org/moretypes/16


### Maps https://tour.golang.org/moretypes/19

Maps are typed, but you can use `interface{}`.
mutating maps: https://tour.golang.org/moretypes/22

### Functions

Functions are values.
Functions are closures.


empty interface `interface{}` can hold any type.


Tour is nice.

Go playground is cool. https://play.golang.org/


type assertions: https://tour.golang.org/methods/15
- type switches

error values https://tour.golang.org/methods/19

gofmt



### Conventions

Use mixed caps instead of underscore
Semicolons are inferred, and not necessary in most places.
No parenthesis in `if` and `for` statements
early exit over nested code.
redeclaration https://golang.org/doc/effective_go.html#redeclaration
