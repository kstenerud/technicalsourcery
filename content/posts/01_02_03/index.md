---
title: "0.1 + 0.2 ≠ 0.3 - Wait... what?"
date: 2021-12-27T10:12:47+02:00
description: "Every software developer gets bitten by floating point calculation issues at some point in their career. It's such a traumatic experience that a common response is to avoid floating point as much as possible out of fear, or to replace it with custom-built fixed point solutions (which often make things worse)."
images:
  - images/thumbnails/01_02_03.jpg
categories:
  - floating-point
tags:
  - floating-point
draft: true
---

Every software developer gets bitten by floating point calculation issues at some point in their career. It's such a traumatic experience that a common response is to avoid floating point as much as possible out of fear, or to replace it with custom-built fixed point solutions (which often make things worse).

It's important to know what's actually going on under the hood with floating point numbers. Otherwise you can never really be sure if you're about to step on a landmine (and there are plenty of them).

What's going on, anyway?
------------------------

The problem lies with the mismatch between the binary and decimal numbering systems when it comes to fractional values.

### A case of primes

In the human world, we work almost exclusively in the base-10 numbering system. Every digit in a number is a value from 0-9, and each digit position represents a value times a power-of-10:

    1234
    ||| \
    || \ 4 × 1
    | \ 3 × 10
     \ 2 × 100
      1 × 1000

This continues into the fractional portion with decimal notation:

    1.234
    | || \
    | | \ 4 ÷ 1000
    |  \ 3 ÷ 100
     \  2 ÷ 10
      1 ÷ 1

But all is not perfect in paradise; there are some problematic values that can't be represented exactly:

    1
    - = 0.3333333333333333333...
    3

    1
    - = 0.6666666666666666666...
    6

    1
    - = 0.1428571428571428571...
    7

    1
    - = 0.1111111111111111111...
    9

Every number base has a set of prime factors that can be exactly represented as fractions. For base 10 those primes are 2 and 5. Any fractional value that can't be reduced to those primes can't be represented perfectly in that base.

**Side Note**: The reason why so many older measures (including time) use base 12 is because base 12 has three prime factors (2, 3, 4), which allows more exact divisions that are useful to daily life: 1/2, 1/3, 1/4, 1/6, 1/8, 1/9, etc.

Base 2 has only one prime factor (2), and so it can only exactly represent fractional values such as 1/2, 1/4, 1/8, etc. Trying to represent 1/5 in binary results in a repeating fraction:

    1   001    100110011001...
    - = --- = -------------------- = 0.100110011001... (which is around 0.2000000029802... in base-10)
    5   101   1000000000000...

### Base conversion and base primes are the crux of the problem

Try to convert a fraction from one base to another and you get two potential sources of rounding error: Possible error from the source base representation, and possible error from the the destination base representation. If you wanted to represent 1/3 in a computer program, you'd have to enter it in decimal as the already inaccurate `0.333333333333`, which the compiler then converts with inaccuracies to the binary float value `0x1.5555555553DE1×2⁻²` (approximately 0.333333333333000025877623784253955818712711334228515625 when converted back to decimal).

Normally this isn't such a big deal since you'll be rounding results anyway (as is done in [scientific notation](https://en.wikipedia.org/wiki/Scientific_notation)). But since every fractional number you input as a human is in decimal and thus suffers from base conversion loss when converted to binary, inaccuracies can creep in at an alarming rate, and can sometimes give surprisingly catastrophic results.

### An illustration

As a quick illustration, consider the following go program (also available as a playground at https://go.dev/play/p/wabAojOkn3v ). We'll use exact decimal values so that there are only two accuracy losses: decimal-to-binary for the starting values we enter, and binary-to-decimal when printing out the results.

```golang
package main

import (
    "fmt"
    "math"
)

func stringfp(v float64) string {
    bits := math.Float64bits(v)
    exponent := int((bits>>52)&2047) - 1023
    mantissa := (bits & 0xFFFFFFFFFFFFF)
    // FP values have an implicit 1 at bit 53 with the rest of the
    // mantissa as a fraction, and have a base-2 exponent.
    // e.g. decimal 0.5 is 0x1.0 × 2^-1, 0.25 is 0x1.0 × 2^-2
    return fmt.Sprintf("0x1.%x × 2^%v (%.54f)", mantissa, exponent, v)
}

func main() {
    a := 0.1
    b := 0.2
    c := 0.3
    r := a + b
    fmt.Printf("a = %v\n", stringfp(a))
    fmt.Printf("b = %v\n", stringfp(b))
    fmt.Printf("c = %v\n", stringfp(c))
    fmt.Printf("r = %v\n", stringfp(r))
    fmt.Printf("%v + %v = %v\n", a, b, r)
    fmt.Printf("%v + %v == %v? %v\n", a, b, c, c == r)
}
```

Values `a`, `b`, and `c` demonstrate the effects of converting from base 10 to base 2, and `r` demonstrates the result of adding those values together. In all cases, the very act of printing as decimal causes more accuracy loss from the binary-to-decimal conversion. All programming language runtimes have [very](https://lists.nongnu.org/archive/html/gcl-devel/2012-10/pdfkieTlklRzN.pdf) [complicated](https://cseweb.ucsd.edu/~lerner/papers/fp-printing-popl16.pdf) [printing](https://www.cs.tufts.edu/~nr/cs257/archive/florian-loitsch/printf.pdf) and [scanning](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.45.4152&rep=rep1&type=pdf) code to account for this, and many PHDs were built off this problem space.

Trying to represent 1/10 in binary results in a repeating fraction (shown here in hexadecimal as 0x1.999999999999A×2⁻⁴), just like 1/3 in decimal notation results in the repeating fraction 0.3333333... The inaccuracies can be seen when printing the resulting binary representations as decimal with full precision:

    a = 0x1.999999999999a × 2^-4 (0.100000000000000005551115123125782702118158340454101562)
    b = 0x1.999999999999a × 2^-3 (0.200000000000000011102230246251565404236316680908203125)
    c = 0x1.3333333333333 × 2^-2 (0.299999999999999988897769753748434595763683319091796875)
    r = 0x1.3333333333334 × 2^-2 (0.300000000000000044408920985006261616945266723632812500)
    0.1 + 0.2 = 0.30000000000000004
    0.1 + 0.2 == 0.3? false

Value `r` (`0x1.3333333333334×2⁻²`. which converts back to `0.30000000000000004`) comes from adding two already inaccurate decimal-to-binary-converted values (`0x1.999999999999A×2⁻⁴` and `0x1.999999999999A×2⁻³`) together, resulting in `0x1.3333333333334×2⁻²` instead of the `0x1.3333333333333×2⁻²` you'd get from a direct decimal `0.3` to binary conversion.

Even if you start with 100% accurate representations, you still run into problems after your calculations because the resulting values can't be accurately represented in base-2. The following modification to the program gives the exact same results and suffers the same problem as before (https://go.dev/play/p/t10mi3T-O1b ):

```golang
    a := 1.0
    b := 1.0
    c := 1.0
    a /= 10
    b /= 5
    c = c * 3 / 10
    r := a + b
```

So what can we do about it?
---------------------------

We've already done something. [IEEE](https://www.ieee.org/) came up with a [revision to ieee754](https://en.wikipedia.org/wiki/IEEE_754-2008_revision) in 2008 that added [decimal floating point types](https://en.wikipedia.org/wiki/Decimal_floating_point), but adoption has been glacial, mainly because so few people understand this problem space and how decimal floats can help by eliminating the implicit decimal-binary conversion losses that keep tripping us up.

The technical problems are already solved. What remains is a very human problem: awareness and activism.
