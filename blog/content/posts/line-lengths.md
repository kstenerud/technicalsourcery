---
title: "Line Lengths"
date: 2020-05-30T07:15:13+01:00
featuredImage: "thumbnail.jpg"
description: "An examination of line lengths in programming languages."
categories:
  - programming
tags:
  - programming
---

Line lengths, like tab sizes, tabs vs spaces, and brace positioning, are among the most contentious topics in programming. This is to be expected, as predicted by [Sayre's Law](https://en.wikipedia.org/wiki/Sayre%27s_law): "In any dispute, the intensity of feeling is inversely proportional to the value of the issues at stake." Naturally, contentious topics make for popular blog posts, so here we go!

I've been programming for almost 40 years, 25 of those professionally. I've lived through many of the later seismic shifts in programming discipline, have written much code on actual 80x25 CRT terminals, and have participated in many, many contentious-yet-trivial discussions in programming.

Since our contentious trivial topic is line width, I'd be interested to see how my recent projects have held up to the ideal line width. What's the ideal, you ask? That's a secret!

Let's have a look at my projects directory, containing around 150 semi-recent projects from the last 10 years, mostly in C, C++, Go, Java, Python, Objective-C, and Bash.

We'll start in the command line. Here's a quick shell command to print a frequency graph of line lengths for all go files:

```bash
find . -type f \( -name "*.go" \) -exec awk '{print length}' {} \; | \
  sort -n | \
  uniq -c | \
  awk '($2 >= 75) && ($1 >= 20) {printf("%3s: %s\n",$2,$1)}' | \
  awk 'NR==1{scale=$2/30} \
       {printf("%-15s ",$0); \
        for (i = 0; i<($2/scale) ; i++) {printf("=")}; \
        printf("\n")}'
```

I artificially cut off line lengths under 75 (I'm only interested in longer line lengths), and anything with less than 20 occurrences. This keeps the graph small while still providing eyeball-level usefulness. The scaling is clunky (divide by 30), but it's good enough for here.

Legend: `Line-width: count    graph`

```
 75: 327        ==============================
 76: 202        ===================
 77: 486        =============================================
 78: 360        ==================================
 79: 386        ====================================
 80: 221        =====================
 81: 134        =============
 82: 137        =============
 83: 102        ==========
 84: 119        ===========
 85: 121        ============
 86: 131        =============
 87: 98         =========
 88: 85         ========
 89: 53         =====
 90: 55         ======
 91: 77         ========
 92: 117        ===========
 93: 72         =======
 94: 72         =======
 95: 52         =====
 96: 55         ======
 97: 59         ======
 98: 61         ======
 99: 70         =======
100: 48         =====
101: 46         =====
102: 45         =====
103: 27         ===
104: 35         ====
105: 24         ===
106: 39         ====
107: 24         ===
109: 26         ===
110: 21         ==
111: 23         ===
```

Neato! That was fun, but it's better to use the right tool for the job. Enter [Gnuplot](http://www.gnuplot.info/)!

Gnuplot is a graph generator that can be invoked from the command line to generate pretty plots and graphs. It's incredibly useful and powerful, but as a result has a steep learning curve. A good programmer is lazy, so I cheated and copied from [my neighbor](http://gnuplot-surprising.blogspot.com/2011/09/statistic-analysis-and-histogram.html).

**linecounts.gnu:**

```gnuplot
reset

intervals=40
min=70
max=150
width=(max-min)/intervals

hist(x,width)=width*floor(x/width)+width/2.0

set term png
set output "plot.png"
set xrange [min:max]
set yrange [0:]
set style fill solid 1.0
set xlabel "Line Width"
set ylabel "Frequency"

plot "/dev/stdin" u (hist($1,width)):(1.0) smooth freq w boxes lc rgb"#2a9d8f" notitle
```

I'm setting the min to 70 since I'm only interested in the longer lines, and capping at 150 because I probably have code-generated code in there somewhere, and some code generators create lines thousands of characters long.

Aside: I've found in my experience that line lengths greater than 120 or so are harder to scan. Probably this has something to do with how our eyes focus. That said, the odd long line doesn't really bother me if it's done to preserve the structure in an eye-scan friendly way.

To invoke, we generate line count data the same as before, but send it to gnuplot instead:

```bash
find . -type f \( -name "*.go" \) -exec awk '{print length}' {} \; | gnuplot linecounts.gnu
```

This will output a file `plot.png`, containing the line counts of all files in all subdirs ending with `.go`. Change the `\( -name "*.go" \)` section to capture the file types you're interested in.

Tooling finished! Now let's have a look at my line widths for various languages!

**C:**
{{< figure src="linecounts-c.png" >}}

**C++:**
{{< figure src="linecounts-cpp.png" >}}

C++ really pushes the line lengths, but that's to be expected given how verbose templates are.

**Go:**
{{< figure src="linecounts-go.png" >}}

**Java:**
{{< figure src="linecounts-java.png" >}}

Java is slightly higher than C and Go, but overall relatively stable.

**Objective-C:**
{{< figure src="linecounts-objc.png" >}}

**Python:**
{{< figure src="linecounts-python.png" >}}

Honestly, I'd expected Python line lengths to be longer, but I guess I really made an effort to adhere to PEP-8.

**Bash:**
{{< figure src="linecounts-bash.png" >}}


But that's just my code. What about code in my workplace? These are full of vendored directories, so it's not really representative of the company, but it's still interesting to see for comparison.

**C:**
{{< figure src="linecounts-work-c.png" >}}

Wow! That's an odd graph! My first guess would be a code generator.

**Go:**
{{< figure src="linecounts-work-go.png" >}}

More spikey data. Code generators again?

**PHP:**
{{< figure src="linecounts-work-php.png" >}}

PHP is definitely a lot more free-form!

**Python:**
{{< figure src="linecounts-work-python.png" >}}

I guess we aren't so strict about PEP-8 ;-)

So there you have it. Line lengths from myself, my company, and a bunch of random people from the internet.

Line lengths are a contentious issue in programming, so we tend to write rules and standards about it. But I wonder if we might be better served by a [desire path](https://en.wikipedia.org/wiki/Desire_path) approach? If we observe what people are actually doing, we can probably come up with more natural feeling line length conventions.
