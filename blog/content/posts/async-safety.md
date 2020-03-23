---
title: "Async Safety"
date: 2020-03-20T20:16:47+02:00
featuredImage: "thumbnail.jpg"
description: "TODO."
categories:
  - async-safety
tags:
  - async-safety
draft: true
---


Async safety is a property of a C function where it is "re-entrant", meaning that it can be called from a context where it was previously interrupted mid-function without ill effect.

There are situations where a function gets interrupted by the OS, and the thread is forced to jump to another function (possibly even the same function), regardless of where it was at the time. Think of it like a global forced GOTO of sorts; the operating system tells the thread "Stop what you're doing, jump to this code, and do whatever it says". Interrupted code becomes problematic if it directly or indirectly uses a global resource (data, pipes, shared memory, open files, mutexes, etc).

Let's have a look at an example in `malloc.c` from GLIBC:

```c
  ...
  if (__malloc_initialized < 0)
    ptmalloc_init ();
  __libc_lock_lock (av->mutex);
  ...
```

This snippet is from the main allocation routine. You'll see a lot of these sprinkled throughout the code to guard the API entry points.

Imagine what would happen if your program had just called `malloc` to allocate some memory, but then got interrupted right after the `__libc_lock_lock()` call, and then your interrupt handler code in turn contained a `malloc()` call, or called some other function that called it. The initial run through `malloc` would lock the mutex, preventing any other call to `malloc` from running until it exits. But if you re-enter the function via your interrupt handler, it'll get up to the lock point and then just wait forever, deadlocked, because it's waiting for the pre-interrupted version of itself to exit the function, which will never happen!

And even if this didn't happen (it would be up to the luck of **when** the program gets interrupted), `malloc` is modifying global data, which means that your initial call to `malloc` may have been partway through modifying that global data when it was interrupted, and now the new call to `malloc` will use that partially overwritten data to decide what it should do! Silent or catastrophic corruption ensues...

We need a way to protect ourselves against this, but when it comes down to it, any guards we could put in place would be tricky and error prone to implement, not to mention expensive. The compromise solution was to simply say that interrupt handlers must be async-safe.


## Async-safe Functions in LIBC

Async safety has been a concern for a long time, and the POSIX standard enforces a minimum list of LIBC functions that MUST be implemented in an async-safe manner ([example Linux manpage here](http://man7.org/linux/man-pages/man7/signal-safety.7.html)). These functions are guaranteed to be safe for use in an interrupted context. Other functions **may** be safe, but this is not guaranteed across implementations and libc versions.


## Signals

The biggest source of interrupts in POSIX based systems is signals, which are used to notify a program of exceptional conditions. The most commonly encountered signal in the real world would be segmentation fault (SIGSEGV), which triggers whenever you attempt to access inaccessible memory (for example dereferencing a bad pointer). There are a number of [standard signals](http://man7.org/linux/man-pages/man7/signal.7.html) that can be raised for various reasons, and even special "user" signals that you can assign special meaning to.


## Signal Handlers

When a program receives a signal, the POSIX standard defines how a program is to respond to it by default. This can include ignoring the signal, dumping the core, and terminating the program. Most of the signals can be passed to custom handlers. For example:

```c
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

void sigint_handler(int signum)
{
    static const char* message = "You pressed CTRL-C! Use CTRL-\\ to actually quit (and dump core)\n";
    // write() and strlen() are async-safe.
    // Note, however, that we're writing to STDOUT, which will interfere with
    // anything else writing to STDOUT (you'll get interleaved text).
    write(STDOUT_FILENO, message, strlen(message));
}

int main(void)
{
    // Note: Use sigaction() rather than signal(), because it is thread-safe
    struct sigaction sa = {0};
    sa.sa_handler = &sigint_handler;
    if (sigaction(SIGINT, &sa, NULL) == -1) {
        perror("sigaction");
        return EXIT_FAILURE;
    }

    printf("Sleeping. Press CTRL-C to interrupt me!\n");
    for(;;)
    {
      sleep(1);
    }

    return EXIT_SUCCESS;
}
```

Compile this in gcc: `gcc -o signal signal.c`

Now when you run it:

```text
$ ./signal 
Sleeping. Press CTRL-C to interrupt me!
^CYou pressed CTRL-C! Use CTRL-\ to actually quit (and dump core)
^CYou pressed CTRL-C! Use CTRL-\ to actually quit (and dump core)
^CYou pressed CTRL-C! Use CTRL-\ to actually quit (and dump core)
^CYou pressed CTRL-C! Use CTRL-\ to actually quit (and dump core)
```

Every time you hit `CTRL-C`, instead of quitting the program, it prints out a message. You'll need to either use the `kill` command from another terminal, or send it SIGQUIT using `CTRL-\`, which will by default terminate the program and dump the core.

```text
^\Quit (core dumped)
```

Catching signals is the easy part. The hard part is making sure your handler function is async-safe, because the compiler won't warn you if it's not, and it's very easy to introduce subtle bugs that may not surface for years. This is why most people recommend that you keep your interrupt handlers as short and simple as possible. For example:

```c
static bool something_happened = false;

void something_happened_handler(int signum)
{
    something_happened = true;
}
```

There's nothing that could break with this handler. You could then have a thread that monitors `something_happened`, and takes appropriate action when it changes.

For post-mortem handlers (SIGSEGV, SIGBUS and such), you usually want to record some data before shutting down the program. In this case, all of your data-saving code **must** run from within the handler, which means that it must **all** be async-safe! Calling `fopen()`, `malloc()`, `printf()`, `fwrite()` and friends is a no-no, and the primitive async-safe functions aren't always very user-friendly or convenient.


## A Dangerous World

I hope this little intro gave you a good overview of the perils of interrupted environments. Most people will never have to deal with this in their careers, but if you ever do, a little preparation and foreknowledge will prevent a world of hurt later!
