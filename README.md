# libcpp
Embedded Systems C++ Library


## Dependencies

### `adr-tools`

This repository uses [Architecture Decision Records](https://embeddedartistry.com/blog/2018/4/5/documenting-architectural-decisions-within-our-repositories). Please install [`adr-tools`](https://github.com/npryce/adr-tools) to contribute to architecture decisions.

If you are using OSX, you can install `adr-tools` through Homebrew:

```
brew install adr-tools
```

If you are using Windows or Linux, please install `adr-tools` via [GitHub](https://github.com/npryce/adr-tools).

## Getting Started

### Building libcpp

You can build in the default configuration by using the `make` command. This will build for the host system using the default options (specified in [`meson_options.txt`](meson_options.txt)). Build output will be placed in the `buildresults` folder.

You can choose your own build output folder with `meson`, but you must build using `ninja` within the build output folder.

```
$ meson my_build_output/
$ cd my_build_output/
$ ninja
```

You can enable cross-compilation using the `--cross-file` arg when creating a new repository. This example uses `arm-none-eabi-c++` to compile `libcxx` and `libcxxabi` with the [Embedded Artistry libc](https://github.com/embeddedartistry/libc).

```
meson buildresults --cross-file build/cross/gcc/arm/gcc_arm_cortex-m4.txt -Dlibcxx-enable-threads=false -Duse-ea-libc=true
```

You can enable threading support with an RTOS using an `__external_threading` header. Supply the include path to your RTOS headers:

```
meson buildresults --cross-file build/cross/gcc/arm/gcc_arm_cortex-m4.txt -Dlibcxx-thread-library=threadx -Duse-ea-libc=true -Dos-header-path=../../os/threadx/include
```

### Using libcpp as a meson subproject

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
