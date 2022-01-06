---
title: "Giving QR codes superpowers"
date: 2022-01-06T13:10:21+02:00
description: "QR codes have replaced bar codes in many places because they can store so much more information, but this advantage limited because they can only store textual data and have no inherent structure. In this post, Here's how to overcome these problems and give QR codes superpowers!"
images:
  - images/thumbnails/qr-superpowers.png
categories:
  - encoding
tags:
  - encoding
  - qr-code
---

[QR codes](https://en.wikipedia.org/wiki/QR_code) have replaced bar codes in many places because they can store a lot more information, but this advantage is limited by the fact that they can only store textual data and have no inherent structure. In this post, I'll demonstrate how to overcome these limitations and give QR codes superpowers!

## QR Codes and Their Limitations

QR codes were invented by the Japanese company Denso Wave in the mid-90s as a way to get higher information density into machine-readable optical labels. They support a number of encoding methods including numeric digits, alphanumerics, kanji, and raw text. Although the QR format does have an encoding called "byte mode", each byte in this mode represents an ISO 8859-1 character, not binary data. So there's no way to directly encode binary data into a QR code.

... Or is there? With a little creative thinking and some algorithmic tweaks, it's possible to work around this limitation to encode binary data into a QR code.

To see how, let's take a look at the "byte mode" encoding format: **ISO 8859-1**.


|    | x0   | x1 | x2 | x3 | x4 | x5 | x6 | x7 | x8 | x9 | xA | xB | xC | xD  | xE | xF|
| -- | ---- | -- | -- | -- | -- | -- | -- | -- | -- | -- | -- | -- | -- | --- | -- | --|
| 0x |      |    |    |    |    |    |    |    |    |    |    |    |    |     |    |   |
| 1x |      |    |    |    |    |    |    |    |    |    |    |    |    |     |    |   |
| 2x | SP   |  ! |  " |  # |  $ |  % |  & |  ' |  ( |  ) |  * |  + |  , | -   |  . |  /|
| 3x | 0    |  1 |  2 |  3 |  4 |  5 |  6 |  7 |  8 |  9 |  : |  ; |  < | =   |  > |  ?|
| 4x | @    |  A |  B |  C |  D |  E |  F |  G |  H |  I |  J |  K |  L | M   |  N |  O|
| 5x | P    |  Q |  R |  S |  T |  U |  V |  W |  X |  Y |  Z |  [ |  \ | ]   |  ^ |  _|
| 6x | `    |  a |  b |  c |  d |  e |  f |  g |  h |  i |  j |  k |  l | m   |  n |  o|
| 7x | p    |  q |  r |  s |  t |  u |  v |  w |  x |  y |  z |  { |  | | }   |  ~ |   |
| 8x |      |    |    |    |    |    |    |    |    |    |    |    |    |     |    |   |
| 9x |      |    |    |    |    |    |    |    |    |    |    |    |    |     |    |   |
| Ax | NBSP |  ¡ |  ¢ |  £ |  ¤ |  ¥ |  ¦ |  § |  ¨ |  © |  ª |  « |  ¬ | SHY |  ® |  ¯|
| Bx | °    |  ± |  ² |  ³ |  ´ |  µ |  ¶ |  · |  ¸ |  ¹ |  º |  » |  ¼ | ½   |  ¾ |  ¿|
| Cx | À    |  Á |  Â |  Ã |  Ä |  Å |  Æ |  Ç |  È |  É |  Ê |  Ë |  Ì | Í   |  Î |  Ï|
| Dx | Ð    |  Ñ |  Ò |  Ó |  Ô |  Õ |  Ö |  × |  Ø |  Ù |  Ú |  Û |  Ü | Ý   |  Þ |  ß|
| Ex | à    |  á |  â |  ã |  ä |  å |  æ |  ç |  è |  é |  ê |  ë |  ì | í   |  î |  ï|
| Fx | ð    |  ñ |  ò |  ó |  ô |  õ |  ö |  ÷ |  ø |  ù |  ú |  û |  ü | ý   |  þ |  ÿ|

Notice how the codes **00-1f** and **7f-9f** are unassigned (many text formats do this for legacy reasons). This means that any data containing these values is invalid because it can't be decoded as ISO 8859-1. Not all QR decoders actually validate this, though, which is why you sometimes get strange results after decoding a QR code that was mistakenly encoded in UTF-8 format.

So even though there's no technical limitation against using them, unassigned characters are considered invalid, which means that any valid QR code will not contain them.

Or to put it another way: **these characters are completely up for grabs!**

What we could do is re-purpose one of these unassigned characters and use it as a sentinel to indicate the presence of special, non-ISO-8859-1 data. Any scanner that knows how to handle the sentinel character and special data format can decode the data, without negatively affecting existing implementations!

## Encoding ad-hoc binary data into QR codes

[Concise Encoding](https://concise-encoding.org) is an ad-hoc data format with a text and a binary encoding form. The [binary format](https://github.com/kstenerud/concise-encoding/blob/master/cbe-specification.md) begins all documents with the sentinel byte [0x83](https://github.com/kstenerud/concise-encoding/blob/master/cbe-specification.md#version-specifier) specifically because such a value is an invalid starting byte in most popular text formats. We'll leverage this to encode a binary document into a QR code.

I've adapted https://github.com/kstenerud/enctool to support QR codes and initiate special processing when the first byte of the QR data is `0x83`. You can follow along by [installing go on your system](https://go.dev/doc/install) and then installing `enctool` like so:
```
go install github.com/kstenerud/enctool@latest
```

This will install `enctool` into `$GOPATH/bin` (usually `go/bin` in your home directory).

We'll be using enctool's `convert` functionality. You can see the available options by typing:

```
enctool convert -h
```

### Example

As an example, let's assume that we're coming up with a new international shipping and storage requirements QR code format. We have an example document that we want to encode into a QR code. I'm writing it here in the text format ([CTE](https://github.com/kstenerud/concise-encoding/blob/master/cte-specification.md)) for convenience - the actual data will be written in the binary format ([CBE](https://github.com/kstenerud/concise-encoding/blob/master/cbe-specification.md)).

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
ls -l with-text.cbe
-rw-rw-r-- 1 karl karl 105 Jan  6 17:15 with-text.cbe
```

The resulting `with-text.cbe` file is 105 bytes long due to the many text fields. We could encode it as-is, but that would produce a pretty big QR code!

What if instead we came up with a schema that replaces all well-known text keys and values with integer enumerations? For completeness we'll also include a "fourCC" style identifier so that any reader can identify which schema the data was encoded with (we'll assume that all documents use key 0 to specify the schema).

Fictional Schema:
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

Document (CTE):
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

Because integers from -100 to 100 encode into a single byte in CBE, you can achieve tremendous space savings using them as enumerated types. Let's try it with our modifications (saving this document as `with-enums.cte`):

```
enctool convert -s with-enums.cte -sf cte -df cbe -d with-enums.cbe
ls -l with-enums.cbe 
-rw-rw-r-- 1 karl karl 28 Jan  6 17:22 with-enums.cbe
```

From our original 105 bytes to 28 bytes! Much better!

Now let's try encoding this data into a QR code:

```
enctool convert -s with-enums.cte -sf cte -df qr -d qr.png -b 1 -is 400
```

`qr.png` is a newly created PNG file containing the QR code:

{{< figure src="qr.png" >}}

Now let's read the data back (I'm omitting the destination file so that it prints to stdout, in CTE for convenience):

```
enctool convert -s qr.png -sf qr -df cte
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

Now that we can get the document back, we can do schema processing to get the true meaning of the data.

So there you have it! Supercharged QR codes that can hold arbitrary data!
