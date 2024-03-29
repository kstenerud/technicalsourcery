---
title: "Giving QR Codes Superpowers"
date: 2022-01-06T13:10:21+02:00
description: "Harness the power of Concise Encoding to store ad-hoc binary data in QR codes!"
images:
  - images/thumbnails/qr-superpowers.png
categories:
  - encoding
tags:
  - encoding
  - qr-code
  - binary
  - structured-data
  - concise-encoding
---

[QR codes](https://en.wikipedia.org/wiki/QR_code) are popular because they can store more information than bar codes, but they can't store binary data and have no inherent structure. In this post, I'll show how to overcome these limitations and give QR codes superpowers!

## QR Codes and Their Limitations

QR codes were invented by the Japanese company Denso Wave in the mid-90s as a way to get higher information density in machine-readable optical labels. They support a number of encoding methods including numeric digits, alphanumerics, kanji, and raw text. Although the QR format does have an encoding called "byte mode", each byte in this mode represents an ISO 8859-1 character, not binary data.

[ECI](https://symbology.dev/docs/encoding.html#extended-channel-interpolation-eci) escape sequences allow encoding of nonstandard text encodings, but each escape code bloats the message with out-of-band data (they have to be long in order to minimize the chance of misinterpreting data as escapes), and still binary data is not supported 😞

If you did try to write binary data, it would either be rejected (if the decoder is conformant), or just end up garbled once a reader tries to interpret it as text (some decoders apply heuristics to guess at the intended format, complicating things even further). So there's no reliable way to directly encode binary data into a QR code, let alone ad-hoc structured binary data.

However, with a little creative thinking, some minor algorithmic tweaks and the [Concise Encoding format](https://concise-encoding.org), it's possible to work around this limitation to reliably read and write binary ad-hoc structured data in QR codes for slightly modified decoders!

To see how, let's take a look at the text encoding used for "byte mode": **ISO 8859-1**.


|    | x0   | x1 | x2 | x3 | x4 | x5 | x6 | x7 | x8 | x9 | xA | xB | xC | xD  | xE | xF|
| -- | ---- | -- | -- | -- | -- | -- | -- | -- | -- | -- | -- | -- | -- | --- | -- | --|
| 0x |      |    |    |    |    |    |    |    |    |    |    |    |    |     |    |   |
| 1x |      |    |    |    |    |    |    |    |    |    |    |    |    |     |    |   |
| 2x | sp   |  ! |  " |  # |  $ |  % |  & |  ' |  ( |  ) |  * |  + |  , | -   |  . |  /|
| 3x | 0    |  1 |  2 |  3 |  4 |  5 |  6 |  7 |  8 |  9 |  : |  ; |  < | =   |  > |  ?|
| 4x | @    |  A |  B |  C |  D |  E |  F |  G |  H |  I |  J |  K |  L | M   |  N |  O|
| 5x | P    |  Q |  R |  S |  T |  U |  V |  W |  X |  Y |  Z |  [ |  \ | ]   |  ^ |  _|
| 6x | `    |  a |  b |  c |  d |  e |  f |  g |  h |  i |  j |  k |  l | m   |  n |  o|
| 7x | p    |  q |  r |  s |  t |  u |  v |  w |  x |  y |  z |  { | \| | }   |  ~ |   |
| 8x |      |    |    |    |    |    |    |    |    |    |    |    |    |     |    |   |
| 9x |      |    |    |    |    |    |    |    |    |    |    |    |    |     |    |   |
| Ax | nbsp |  ¡ |  ¢ |  £ |  ¤ |  ¥ |  ¦ |  § |  ¨ |  © |  ª |  « |  ¬ | shy |  ® |  ¯|
| Bx | °    |  ± |  ² |  ³ |  ´ |  µ |  ¶ |  · |  ¸ |  ¹ |  º |  » |  ¼ | ½   |  ¾ |  ¿|
| Cx | À    |  Á |  Â |  Ã |  Ä |  Å |  Æ |  Ç |  È |  É |  Ê |  Ë |  Ì | Í   |  Î |  Ï|
| Dx | Ð    |  Ñ |  Ò |  Ó |  Ô |  Õ |  Ö |  × |  Ø |  Ù |  Ú |  Û |  Ü | Ý   |  Þ |  ß|
| Ex | à    |  á |  â |  ã |  ä |  å |  æ |  ç |  è |  é |  ê |  ë |  ì | í   |  î |  ï|
| Fx | ð    |  ñ |  ò |  ó |  ô |  õ |  ö |  ÷ |  ø |  ù |  ú |  û |  ü | ý   |  þ |  ÿ|

Notice how the codes **7f-9f** are unassigned (many text formats do this for [legacy reasons](https://en.wikipedia.org/wiki/ISO/IEC_2022)). This means that any non-ECI data containing these values is invalid because it can't be decoded as ISO 8859-1 text.

**Side Note**: Non-conformant QR decoders might not actually validate this, which is why you sometimes get strange garbled results after decoding a QR code that was mistakenly encoded in UTF-8 without an ECI header (by a non-conformant encoder).

So even though there are no technical limitations against using them, unassigned characters are considered invalid, which means that any valid QR code will not contain them.

So, what we could do is re-purpose one of these unassigned characters and use it as a sentinel to indicate the presence of special, non-textual data. When a scanner that knows about the sentinel byte encounters it as the first byte of the payload, it can switch decoding modes reliably.

Existing standards-compliant QR decoders will still function correctly because they'll rightly reject the code due to the (technically invalid) sentinel byte. They won't be able to decode the binary data, but they also won't malfunction and give incorrect results.

## Encoding ad-hoc binary data into QR codes

[Concise Encoding](https://concise-encoding.org) is an ad-hoc data format with a text and a binary encoding form. In the [binary format (CBE)](https://github.com/kstenerud/concise-encoding/blob/master/cbe-specification.md), all documents begin with the sentinel byte [0x81](https://github.com/kstenerud/concise-encoding/blob/master/cbe-specification.md#document-version-specifier) (specifically chosen because it's an invalid starting byte in most popular text formats, including ISO 8859 and UTF-8). We'll leverage this to encode a CBE document into a QR code.

I've adapted https://github.com/kstenerud/enctool to support QR codes and initiate special processing when the first byte of the QR data is `0x81`. You can follow along by [installing the go language on your system](https://go.dev/doc/install) and then installing `enctool` like so:
```
go install github.com/kstenerud/enctool@latest
```

This will install `enctool` into `$GOPATH/bin` (usually `go/bin` in your home directory).

We'll be using enctool's `convert` functionality. You can see the available options by typing:

```
enctool convert -h
```

### Example

As an example, let's say that we're developing a new "international shipping and storage requirements" QR code format.

Here's a sample document that we want to encode into a QR code. I'm writing it here in the text format ([CTE](https://github.com/kstenerud/concise-encoding/blob/master/cte-specification.md)) for convenience, but the actual data will be written in the binary format ([CBE](https://github.com/kstenerud/concise-encoding/blob/master/cbe-specification.md)).

```cte
c1 {
    "temperature range" = [-20 5]
    "hazards" = [
        "pressurized"
        "flammable"
        "fragile"
    ]
    "max tilt degrees" = 15
    "perishes after" = 2022-12-05
}
```

Save this document as `with-text.cte`, and then convert to CBE like so:

```
enctool convert -s with-text.cte -sf cte -df cbe -d with-text.cbe
```

How big is it?

```
ls -l with-text.cbe
-rw-rw-r-- 1 karl karl 105 Jan  6 17:15 with-text.cbe
```

A whopping 105 bytes (mainly due to the many text fields the data contains). We could encode it as-is, but that would produce a pretty big QR code.

What if instead we came up with a schema that replaces all well-known text keys and values with integer enumerations? That should really shrink things!

**Note**: For completeness sake we'll also include a [fourCC](https://en.wikipedia.org/wiki/FourCC) style identifier so that any reader can identify which schema and version the data was encoded with (let's say that key 0 is always used to specify the schema).

**Fictional Schema**:
* 0 = schema ID and version adherence: **(fourCC-style integer: "TSS" + version)**
* 1 = temperature range: **(list of two integers)**
* 2 = hazards: **(list of enumerated integers)**:
  - 0 = corrosive
  - 1 = photoreactive
  - ...
  - 4 = pressurized
  - ...
  - 6 = flammable
  - ...
  - 19 = fragile
* ...
* 4 = max tilt degrees: **(integer)**
* ...
* 9 = perishes after: **(date)**

**Document (CTE)**:
```cte
c1 {
    0 = 0x54535301 // Transport and Storage Schema version 1 ("TSS" + 1)
    1 = [-20 5]    // Temperature range from -20 to 5
    2 = [          // Hazards:
        4             // Pressurized
        6             // Flammable
        19            // Fragile
    ]
    4 = 15         // Max 15 degrees tilt
    9 = 2022-12-05 // Perishes after Dec 5, 2022
}
```

Because [integers from -100 to 100 are their own type codes in CBE](https://github.com/kstenerud/concise-encoding/blob/master/cbe-specification.md#type-field) (thereby  encoding into a single byte), you can achieve tremendous space savings by using them as enumerated types.

Let's see how our modifications do (save this document as `with-enums.cte`):

```
enctool convert -s with-enums.cte -sf cte -df cbe -d with-enums.cbe
```

Now how big is it?

```
ls -l with-enums.cbe 
-rw-rw-r-- 1 karl karl 28 Jan  6 17:22 with-enums.cbe
```

We've shrunk down our payload from 105 bytes to 28 bytes! Much better!

Here are the byte contents of the CBE document. Note the first byte 0x81, which is an unassigned character in ISO 8859-1:

```
81 00 99 00 6c 01 53 53 54 01 9a ec 05 9b 02 9a 04 06 13 9b 04 0f 09 7a 85 59 00 9b
```

Now let's encode this data into a QR code (border size 1, 400x400 pixels):

```
enctool convert -s with-enums.cte -df qr -d qr.png -b 1 -is 400
```

This creates `qr.png`, which contains our QR code:

{{< figure src="qr.png" >}}

Now let's read the data back. I'll convert it to CTE for convenience, printing to stdout:

```
enctool convert -s qr.png -sf qr -df cte
```

Output:

```cte
c0
{
    0 = 1414746881
    1 = [
        -20
        5
    ]
    2 = [
        4
        6
        19
    ]
    4 = 15
    9 = 2022-12-05
}
```

Once we've got our document, we can process it through the schema to recover the true meaning of the data.

So there you have it: Supercharged QR codes that can hold arbitrary structured data! Neat!
