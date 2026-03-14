# Concerns and Next Steps: LLVM 19.1.7 Sync

## What Was Fixed

1. **Removed stale `__debug` header overlay** — LLVM 19 deleted the `__debug` header entirely,
   replacing the debug iterator system with hardening modes. Our overlay referenced it.

2. **Removed deleted upstream source files from `meson.build`** — Several `.cpp` files that
   existed in LLVM 10 were removed or reorganized in LLVM 19
   (`new.cpp`, `debug.cpp`, `thread.cpp`, `string.cpp`, `locale.cpp`, `stdexcept.cpp`, `chrono.cpp`,
   `iostream.cpp`, `random.cpp`). The custom overlays in `src/c++/` already replace these.

3. **Added `_LIBCPP_HARDENING_MODE_DEFAULT`** — LLVM 19 requires this in `__config_site` or
   compilation fails with a hard `#error`. Set to `_LIBCPP_HARDENING_MODE_NONE` (zero overhead,
   appropriate for embedded).

4. **Fixed `atomic_support.h` include paths** — Added `libcxx/src` to both `libcxx_include_directories`
   and `libcxxabi_include_directories` in `meson.build`, matching upstream CMake. Fixed broken
   `../../libcxxabi/src/include/atomic_support.h` path in custom overlay.

5. **Fixed Meson `declare_dependency` for generated headers** — `configure_file` outputs
   (`__config_site`, `__assertion_handler`) were being treated as compilable sources by newer
   Meson versions.

## Remaining Concerns

### High Priority

**Fragile relative include paths in custom overlays.** Several files still use `../../` paths
to reach into upstream source trees:

- `src/c++/new_terminate_badalloc.cpp` → `../../libcxx/src/support/runtime/new_handler_fallback.ipp`
  (file no longer exists in LLVM 19, but the code path is dead when `LIBCXX_BUILDING_LIBCXXABI` is defined)
- `src/c++abi/cxa_handlers.cpp` → `../../libcxxabi/src/cxa_handlers.h`, `cxa_exception.h`, etc.
- `src/c++abi/cxa_personality.cpp` → same pattern
- `src/c++abi/cxa_demangle.cpp` → `../../libcxxabi/src/demangle/ItaniumDemangle.h`

These work today but will break if the directory structure changes. Consider adding
`libcxxabi/src` to the include path and using short includes like upstream does.

**`new_handler_fallback.ipp` is gone.** The file `libcxx/src/support/runtime/new_handler_fallback.ipp`
no longer exists in LLVM 19 (replaced by `libcxx/src/new_handler.cpp`). This is currently safe
because the `#include` is behind `#if defined(_LIBCPP_ABI_MICROSOFT)` and `#elif defined(LIBCXXRT)`
branches that are never taken when `LIBCXX_BUILDING_LIBCXXABI` is defined. If that define is ever
removed, compilation will fail. Consider cleaning up the dead branches.

**GCC version requirement.** LLVM 19's libc++ headers only support GCC 14+. The `__config` uses
Clang-specific builtins (`__has_feature`, `__has_extension`) without GCC guards. This means:
- Cross-compilation requires Clang, or GCC 14+
- `arm-none-eabi-gcc` versions older than 14 will not work
- The `meson.build` currently only checks for GCC >= 9, which is too lenient

### Medium Priority

**Dead source file: `src/c++/debug.cpp`.** This file is excluded from the build but still exists
in the repository. It includes the deleted `__debug` header and implements the removed debug
iterator database. Consider deleting it to avoid confusion.

**`__libcpp_compat.h` may need updates over time.** The compatibility shim currently defines
7 macros (`_LIBCPP_FUNC_VIS`, `_LIBCPP_TYPE_VIS`, `_LIBCPP_INLINE_VISIBILITY`, `_VSTD`,
`_LIBCPP_SAFE_STATIC`, `_LIBCPP_AVAILABILITY_LOCALE_CATEGORY`, `_THROW_BAD_ALLOC`). If custom
overlay files are updated or new ones added, additional compat macros may be needed. Document
which overlays depend on which compat macros.

**ABI version locked to v1.** The project hardcodes ABI version 1 and namespace `__1`.
LLVM 19's default for new installations is ABI v2, which includes optimizations like alternate
string layout. This is fine for a standalone embedded library but means you cannot link against
objects built with an ABI v2 libc++.

### Low Priority

**Include directory ordering is fragile.** The build relies on `-isystem` ordering so that
custom overlay headers (in `include/c++/`) shadow upstream headers (in `libcxx/include/`).
The comment in `meson.build:661` warns about this. Changes to Meson's include path handling
could break this silently.

**`_LIBCPP_HIDE_FROM_ABI_PER_TU_BY_DEFAULT` is in config but never set.** It's listed as a
`#mesondefine` but no code in `meson.build` ever calls `libcxx_conf_data.set()` for it, so it
always becomes `/* #undef ... */`. Either wire it up to a build option or remove it.

## Recommended Next Steps

1. **Test with Clang cross-compiler** — Verify the full build with your actual embedded
   toolchain (e.g., `clang --target=arm-none-eabi`). The GCC 13 failures in this environment
   are expected and not caused by our changes.

2. **Clean up dead code** — Delete `src/c++/debug.cpp` and remove the dead
   `new_handler_fallback.ipp` include branches from `new_terminate_badalloc.cpp`.

3. **Add `libcxxabi/src` to include paths** — Similar to the `libcxx/src` fix, this would
   let you replace the remaining `../../libcxxabi/src/` relative paths with clean includes.

4. **Update GCC version check** — Change the minimum GCC version check in `meson.build:64`
   from 9.0 to 14.0, or add a Clang requirement.

5. **Audit for new LLVM 19 features to adopt** — The hardening mode system (`_FAST`,
   `_EXTENSIVE`, `_DEBUG`) could be exposed as a Meson build option for debug builds, giving
   iterator bounds checking without runtime overhead in release.
