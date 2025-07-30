> [!IMPORTANT]
> At the moment I'm writing this, Zig is still not even 1.0.0 and going through a lot of changes, so expect things to break.
> 
> If you find that this is broken, please feel free to open a pull request with a fix. I'll definitively try to check it as soon as possible.
> If you can't fix it by yourself, you **can** open an issue, but I don't have a lot of time, so it might take a while for me to fix it.

# Zig as a C++ cross compiler

This is my template for new C++ projects using Zig as the project's toolchain.

One of the most underrated aspects of the Zig programming language, is its ability to compile C and C++ code. 
Alongside Zig, there is not only a recent version of the Clang compiler, but also a fez different Libc implementations, such as GNU LIbc and the Musl libc.

By bundling these, Zig eliminates not only the hassle of finding a compiler, but also a Libc implementation 
(this is the first time I've managed to build a program and link it to Musl libc to a program of mine).

## Motivation

For a recent project of mine I had to develop an application targetting an Aarch64 based processor running a really old version of Linux that did not have a package manager and I could not update.
Since I prefer to develop in my own computer, instead of using that outdated and outrageously slow piece of garbage, I needed to cross compile my program targetting that platform.

I also really appreciate some of C++20 and 23 features, such as the Ranges v3 utilities, `std::format` and **especially** `std::print`. 
So, motivated to use these utilities, I also needed my compiler to be recent enough to support them.

As I've always used the GCC compiler, that was my first choice.
So I popped up a terminal and installed the latest version of `aarch64-linux-gnu-gcc` from the [AUR](https://archlinux.org/packages/extra/x86_64/aarch64-linux-gnu-gcc/).

I created a simple CMake script (please note that a **""simple""** CMake script is relative), which I configured to link all of my dependencies statically and used it com compile the first version of my program.

### But of course that didn't work 😃

GNU libc was never meant to be statically linked, so it straight up refuses to be.

But that's a simple fix, I just had to link my program to Musl, which was intended to be both modular and easily embedded in a static executable. 
But once again, **""simple""** is relative, getting a compiler that links to Musl was much more complicated than the previous compiler. 
Every version I could find in the AUR was either outdated or just would not compile.

I **could** get the source code of the compiler I want, compile it myself and use it, but I just don't want all that work. 
For every update I'd have to manually download the new source, compile it again, install it again, etc, etc...

I **also could** publish a package to the AUR and just update the source code there and use my package manager to handle the rest, but that's even more work.
That's actually **A LOT** of work. So yeah, not going to do that.

But then I stumbled across [this awesome text from Andrew Kelley](https://andrewkelley.me/post/zig-cc-powerful-drop-in-replacement-gcc-clang.html).
In the text, he explained that Zig not only can be used to compile C and C++ for a lot of different acrchitectures, 
but it also brings the Musl Libc along, and linking to it instead of GNU libc is as easy as passing a different flag to the compiler.

And that settled it, even though I couldn't port all of my project to Zig _(which I would prefer btw)_, I could use it to compile my C++ code.

## First idea
In his example, Andrew simply took a project with an existing Makefile and swapped the compiler with the *CC* environment variable.
So I started by taking a similar approach, but with an important difference: my project uses a CMake script.

In case I haven't been clear, I don't like CMake. It is super complicated, there is a million ways to do the same thing and the documentation is super confusing in my opinion.
**However**, I give credit where credit is due and CMake does some nice things and my project is really dependent on one of them: **automatic fetch and compiling of external libraries**.

My project uses a bunch of different external libraries and handling all of them manually would be crazy.
So, I let CMake handle them using [FetchContent](https://cmake.org/cmake/help/latest/module/FetchContent.html).
Even though the setup for this was outrageously difficult, it worked and my project grew to depend on it.

So I needed to adapt my script to use the `zig c++` command as its C++ compiler.
After a bit of lookup I found [this project](https://github.com/mrexodia/zig-cross), which does exactly that.

### But of course that also didn't work 😃

Most of the libraries handled by FetchContent were not very happy to link statically against Musl.
So it took an obscene ammount of workarounds to make this approach work, but eventually it did!

That deserves its own repository, as it's still kind of useful for projects that have FetchContent based dependencies, so I'll add a link to it here if I ever create it.

## This solution
While it did work, the existing solution didn't use the zig build system to its fullest, which led me to this.
Now, the C++ code is compiled using only Zig as both the toolchain and build system.

To compile your code using this, simply run `zig build` and the build system will generate the executables for each of the targets in the array in the `build.zig` file.
To add or remove targets, simply change that array accordingly, it should be pretty intuitive if you're using the [Zig Language Server](https://github.com/zigtools/zls), as it will suggest the options available for each field.

Of course, there are combinations that are not supported, so maybe check the available ones using the `zig targets` command.
But, if you don't want to go through all of that (honestly it's a **very** big list), you can also just add the target you want and try to run `zig build`.
If your target is not supported it will just fail pretty fast and it'll even suggest a supported target similar to what you wanted.

I won't dive much deeper into this explanation since the code is pretty intuitive for anyone who has ever used Zig before.
The `build.zig` is very self-explanatory, just reading through it should be enough to understand its functioning.

## Requirements
- [Zig ⚡](https://github.com/ziglang/zig)  _(obviously)_
  
  And that's it. 
  
  This really is all you need.

## If you're using an LSP
If you use Clangd, Intellisense or any other LSP, it probably needs you build system to output a file called `compile_commands.json`.
This is not something that the Zig build system does by itself, but there are ways to do it.

> [!WARNING]
> The project that I'll suggest is not maintained by me.
> I have no intention of helping maintain it, neither should I be held accountable for its functioning _(or lack thereof)_.

I found [this project](https://github.com/the-argus/zig-compile-commands) that generates this file automatically when given a set of targets.
I've let a few lines commented out that use it to generate this file based on all your targets.

If you wish to use it, follow the instructions on that project's README for adding it as a dependency to your `build.zig.zon`.
Then, just uncomment all the lines in this project's `build.zig` file and it should just work.
