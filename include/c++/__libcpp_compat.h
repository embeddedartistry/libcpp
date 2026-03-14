// -*- C++ -*-
//===----------------------------------------------------------------------===//
//
// Embedded Artistry compatibility macros
//
// Provides backward-compatible definitions for macros that were removed
// or renamed between LLVM 10 and LLVM 19. These are used by custom overlay
// files (src/c++/, src/c++abi/, include/c++/__locale, etc.) that were
// originally written against the older LLVM API.
//
//===----------------------------------------------------------------------===//

#ifndef _LIBCPP_COMPAT_H
#define _LIBCPP_COMPAT_H

#include <__config>

// _LIBCPP_FUNC_VIS and _LIBCPP_TYPE_VIS controlled shared library symbol
// visibility. Since this project builds static libraries, define them empty.
#ifndef _LIBCPP_FUNC_VIS
#  define _LIBCPP_FUNC_VIS
#endif

#ifndef _LIBCPP_TYPE_VIS
#  define _LIBCPP_TYPE_VIS
#endif

// _LIBCPP_INLINE_VISIBILITY was renamed to _LIBCPP_HIDE_FROM_ABI
#ifndef _LIBCPP_INLINE_VISIBILITY
#  define _LIBCPP_INLINE_VISIBILITY _LIBCPP_HIDE_FROM_ABI
#endif

// _VSTD was a namespace alias for std, removed in LLVM 18
#ifndef _VSTD
#  define _VSTD std
#endif

// _LIBCPP_SAFE_STATIC was replaced by _LIBCPP_CONSTINIT
#ifndef _LIBCPP_SAFE_STATIC
#  ifdef _LIBCPP_CONSTINIT
#    define _LIBCPP_SAFE_STATIC _LIBCPP_CONSTINIT
#  else
#    define _LIBCPP_SAFE_STATIC
#  endif
#endif

// _LIBCPP_AVAILABILITY_LOCALE_CATEGORY was an availability annotation
#ifndef _LIBCPP_AVAILABILITY_LOCALE_CATEGORY
#  define _LIBCPP_AVAILABILITY_LOCALE_CATEGORY
#endif

// _THROW_BAD_ALLOC was removed in newer LLVM versions
#ifndef _THROW_BAD_ALLOC
#  ifndef _LIBCPP_NO_EXCEPTIONS
#    define _THROW_BAD_ALLOC
#  else
#    define _THROW_BAD_ALLOC
#  endif
#endif

#endif // _LIBCPP_COMPAT_H
