# Embedded Artistry libcpp

This project supplies a C++ standard library and C++ ABI library that can be used for microcontroller-based embedded systems projects.

This project is based on the clang libc++ and libc++abi libraries. Alternative implementations are provided for various files to support embedded systems usage.

The builds are highly configurable, allowing you to create a libc++ and libc++abi set that is tuned specifically to your system's needs.

## Table of Contents

1. [About the Project](#about-the-project)
1. [Project Status](#project-status)
1. [Getting Started](#getting-started)
    1. [Requirements](#Requirements)
    1. [Getting the Source](#getting-the-source)
    1. [Building](#building)
    1. [Usage](#installation)
1. [Configuration Options](#configuration-options)
1. [Versioning](#versioning)
1. [How to Get Help](#how-to-get-help)
1. [Contributing](#contributing)
1. [License](#license)
1. [Authors](#authors)

## About the Project

This project supplies a C++ standard library and C++ ABI library that can be used for microcontroller-based embedded systems projects.

This project is based on the clang libc++ and libc++abi libraries. Alternative implementations are provided for various files to support embedded systems usage.


The builds are highly configurable, allowing you to create a libc++ and libc++abi set that is tuned specifically to your system's needs.

**[Back to top](#table-of-contents)**

## Project Status

This project currently builds libc++ and libc++abi for x86, x86_64, arm, and arm64 processors. All relevant library configuration options have been ported from the CMake builds. See [Configuration Options](#configuration-options) and [meson_options.txt](meson_options.txt) for the list of configurable settings.

**[Back to top](#table-of-contents)**

## Getting Started

### Requirements

* [Meson](#meson-build-system) is the build system
* [`git-lfs`][7] is used to store binary files in this repository
* `make` is needed if you want to use the Makefile shims
* You'll need some kind of compiler for your target system.
    - This repository has been tested with:
        - gcc
        - arm-none-eabi-gcc
        - Apple clang
        - Mainline clang

#### git-lfs

This project stores some files using [`git-lfs`](https://git-lfs.github.com).

To install `git-lfs` on Linux:

```
sudo apt install git-lfs
```

To install `git-lfs` on OS X:

```
brew install git-lfs
```

Additional installation instructions can be found on the [`git-lfs` website](https://git-lfs.github.com).

#### Meson Build System

The [Meson][meson] build system depends on `python3` and `ninja-build`.

To install on Linux:

```
sudo apt-get install python3 python3-pip ninja-build
```

To install on OSX:

```
brew install python3 ninja
```

Meson can be installed through `pip3`:

```
pip3 install meson
```

If you want to install Meson globally on Linux, use:

```
sudo -H pip3 install meson
```

### Getting the Source

This project uses [`git-lfs`](https://git-lfs.github.com), so please install it before cloning. If you cloned prior to installing `git-lfs`, simply run `git lfs pull` after installation.

This project is [hosted on GitHub](https://github.com/embeddedartistry/libcpp). You can clone the project directly using this command:

```
git clone --recursive git@github.com:embeddedartistry/libcpp.git
```

If you don't clone recursively, be sure to run the following command in the repository or your build will fail:

```
git submodule update --init
```

### Building

The library can be built by issuing the following command:

```
make
```

This will build all targets for the host system using the default options (specified in [`meson_options.txt`](meson_options.txt)). Build output will be placed in the `buildresults` folder.

You can clean builds using:

```
make clean
```

You can eliminate the generated `buildresults` folder using:

```
make purify
```

You can also use the `meson` method for compiling.

You can choose your own build output folder with `meson`, but you must build using `ninja` within the build output folder.

```
$ meson my_build_output/
$ cd my_build_output/
$ ninja
```

At this point, `make` would still work.

#### Cross-compiling

You can enable cross-compilation using the `--cross-file` argument when creating a new repository. This example uses `arm-none-eabi-c++` to compile `libcxx` and `libcxxabi` with the [Embedded Artistry libc](https://github.com/embeddedartistry/libc).

```
meson buildresults --cross-file build/cross/gcc/arm/gcc_arm_cortex-m4.txt -Denable-threading=false -Duse-ea-libc=true
```

You can enable threading support with an RTOS using an `__external_threading` header. Supply the include path to your RTOS headers:

```
meson buildresults --cross-file build/cross/gcc/arm/gcc_arm_cortex-m4.txt -Dlibcxx-thread-library=threadx -Duse-ea-libc=true -Dos-header-path=../../os/threadx/include
```

### Usage

If you don't use `meson` for your project, the best method to use this project is to build it separately and copy the headers and library contents into your source tree.

* Copy the `include/` directory contents into your source tree.
* Library artifacts are stored in the `buildresults/` folder
* Copy the desired library to your project and add the library to your link step.

Example linker flags:

```
-Lpath/to/libraries -lc++ -lc++abi
```

You can use libcpp as a subproject inside of another `meson` project. Include this project with the `subproject` command:

```
libcpp = subproject('libcpp')
```

Then make dependencies available to your project:

```
libcxx_full_dep = libcpp.get_variable('libcxx_full_dep')
libcxx_full_native_dep = libcpp.get_variable('libcxx_full_native_dep')
libcxx_headeronly_dep = libcpp.get_variable('libcxx_headeronly_dep')
libcxx_header_include_dep = libcpp.get_variable('libcxx_header_include_dep')
libcxx_extensions_include_dir = libcpp.get_variable('libcxx_extensions_include_dir')

libcxxabi_dep = libcpp.get_variable('libcxxabi_dep')
libcxxabi_native_dep = libcpp.get_variable('libcxxabi_native_dep')
```

You can use these dependencies elsewhere in your project:

```
fwdemo_sim_platform_dep = declare_dependency(
    include_directories: fwdemo_sim_platform_inc,
    dependencies: [
        fwdemo_simulator_hw_platform_dep,
        fwdemo_platform_dep,
        libmemory_native_dep,
        libc_native_dep,
        libcxxabi_native_dep, # <--- here
        libcxx_full_native_dep, # <---- here
    ],
    sources: files('boot.cpp', 'platform.cpp'),
)
```

## Configuration Options

Well, let's be honest: there are way too many options for this project (see [meson_options.txt](meson_options.txt)). But we support a variety of project-specific options as well as the majority of the useful options provided by the libc++ and libc++abi Cmake projects.

Here are the configurable options:

* `enable-werror`: Cause the build to fail if warnings are present
* `enable-pedantic-error`: Turn on `pedantic` warnings and errors
* `force-32-bit`: forces 32-bit compilation instead of 64-bit
* `use-ea-libc`: If true, the build will set flags to prevent usage of the compiler libc so the [Embedded Artistry libc](https://github.com/embeddedartistry/libc) can supply the headers
* `ea-libc-path`: The relative path to the root directory of the [Embedded Artistry libc](https://github.com/embeddedartistry/libc) source tree
* `os-header-path`: Path to the headers for your OS, if using a custom threading solutions
* `disable-rtti`: Build without RTTI support (excludes some C++ features such as name demangling)
* `disable-exceptions`: Build without exception support
* `use-compiler-rt`: Build with compiler-rt support
* `always-enable-assert`: Enable assert even with release builds
* `use-llvm-libunwind`: Tell libc++abi to use the llvm libunwinder (don't change unless you know what you're doing)
* `libcxx-enable-chrono`: Builds with chrono.cpp
* `enable-threading`: Build with threading support
* `libcxx-thread-library`: Select the threading library to use with libc++: none, pthread, or the framework thread shims
* `libcxx-has-external-thread-api`: Tell C++ to look for an __external_threading header with thread function shims
* `libcxx-build-external-thread-api`: ???
* `libcxx-enable-filesystem`: enable filesystem support
* `libcxx-enable-stdinout`: enable stdio support
* `libcxx-default-newdelete`: Enable support for the default new/delete implementations
* `libcxx-silent-terminate`: Enable silent termination. The default terminate handler attempts to demangle uncaught exceptions, which causes extra I/O and demangling code to be pulled in.
* `libcxx-monotonic-clock`: Enable/disable support for the monotonic clock (can only be disabled if threading is disabled)

Options can be specified using `-D` and the option name:

```
meson buildresults -Denable-werror=true
```

The same style works with `meson configure`:

```
cd buildresults
meson configure -Denable-werror=true
```

### Blocking new/delete

You can block the `new` and `delete` operators by setting the `libcxx-default-newdelete` to `false`:

```
meson buildresults -Dlibcxx-default-newdelete=false
```

You can also use `meson configure`:

```
cd buildresults
meson configure -Dlibcxx-default-newdelete=false
```

If you are using libcpp as a subproject, you can specify this setting in the containing project options.

## Versioning

This project itself is unversioned and simply pulls in the latest libc++ and libc++abi commits periodically.

## How to Get Help

Provide any instructions or contact information for users who need to get further help with your project.

## Contributing

Provide details about how people can contribute to your project. If you have a contributing guide, mention it here. e.g.:

We encourage public contributions! Please review [CONTRIBUTING.md](docs/CONTRIBUTING.md) for details on our code of conduct and development process.

**[Back to top](#table-of-contents)**

## License

This container project is licensed under the MIT license.

libc++ and libc++abi (and the llvm project in general) are released under [a modified Apache 2.0 license](libcpp/LICENSE.txt). Source files which have been modified are licensed under those terms.

## Authors

* **[Phillip Johnston](https://github.com/phillipjohnston)** - *Initial work* - [Embedded Artistry](https://github.com/embeddedartistry)

**[Back to top](#table-of-contents)**
