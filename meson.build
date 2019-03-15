project('libcpp',
	'cpp',
	default_options : ['cpp_std=c++17'],)

###############
# Build Setup #
###############

#TODO: find libunwind?
# TODO: force link libunwind (-lunwind)?
# TODO: find required libraries
# -rtlib=compiler-rt
# find_compiler_rt_library(builtins LIBCXX_BUILTINS_LIBRARY)
#  check_library_exists(rt clock_gettime "" LIBCXX_HAS_RT_LIB) <---- will we supply something like this?

cat = find_program('cat')
cmake_prep = find_program('build/scripts/prepare_cmake.sh')
mkdir = find_program('mkdir')
libthread = dependency('threads')

build_type = get_option('buildtype')

subdir('build/ea-stdlib')

host_os = host_machine.system()
build_os = build_machine.system()

native_compiler = meson.get_compiler('cpp', native: true)
target_compiler = meson.get_compiler('cpp')

#########################
# Process Build Options #
#########################

disable_rtti = get_option('disable-rtti')
disable_exceptions = get_option('disable-exceptions')
use_compiler_rt = get_option('use-compiler-rt')
enable_werror = get_option('enable-werror')
enable_pedantic_error = get_option('enable-pedantic-error')
always_use_assert = get_option('always-enable-assert')
use_llvm_libunwind = get_option('use-llvm-libunwind')
enable_threads = get_option('libcxx-enable-threads')
has_external_threading = get_option('libcxx-has-external-thread-api')
build_external_threading = get_option('libcxx-build-external-thread-api')
enable_filesystem = get_option('libcxx-enable-filesystem')
enable_stdinout = get_option('libcxx-enable-stdinout')
default_newdelete = get_option('libcxx-default-newdelete')
enable_monotonic_clock = get_option('libcxx-monotonic-clock')
force_32_bit = get_option('force-32-bit')
enable_chrono = get_option('libcxx-enable-chrono')

# The default terminate handler attempts to demangle uncaught exceptions, which
# causes extra I/O and demangling code to be pulled in.
silent_terminate = get_option('libcxx-silent-terminate')

#################################
# Initialize Configuration Data #
#################################

libcxx_conf_data = configuration_data()

# ABI version of libc++. Can be either 1 or 2, where 2 is currently not stable. Defaults to 1.
libcxx_conf_data.set('_LIBCPP_ABI_VERSION', '1')

# The inline ABI namespace used by libc++. It defaults to __n where `n` is the current ABI version.
libcxx_conf_data.set('_LIBCPP_ABI_NAMESPACE', '__1')

##############################
# Set Default Compiler Flags #
##############################

libcxxabi_warning_flags = [
	'-Wall',
	'-Wextra',
	'-W',
	'-Wconversion',
	'-Wchar-subscripts',
	'-Wmissing-braces',
	'-Wunused-function',
	'-Wshadow',
	'-Wsign-compare',
	'-Wsign-conversion',
	'-Wstrict-aliasing=2',
	'-Wstrict-overflow=4',
	'-Wwrite-strings',
    '-Wunused-parameter',
    '-Wunused-variable',
    '-Wundef',
    '-Wno-long-long',
   	'-Werror=return-type',
]

# These are the args that are used to BUILD libc++, not the args used by consumers
libcxxabi_compile_args = [
	'-fstrict-aliasing',
	'-D_LIBCPP_BUILD_STATIC',
	# Prevent libc++abi from having library dependencies on libc++
	'-D_LIBCPP_DISABLE_EXTERN_TEMPLATE',
	'-D_LIBCPP_ENABLE_CXX17_REMOVED_UNEXPECTED_FUNCTIONS',
	'-nodefaultlibs',
	'-nostdinc++',
	'-D_LIBCXXABI_BUILDING_LIBRARY'
] + libcxxabi_warning_flags

libcxxabi_link_args = [
	'-nodefaultlibs',
]

libcxxabi_cross_args = []
libcxxabi_native_args = []
libcxxabi_cross_link_args = []

libcxx_warning_flags = [
	'-Wall',
	'-Wextra',
	'-W',
	'-Wwrite-strings',
    '-Wno-unused-parameter',
    '-Wno-long-long',
    '-Werror=return-type',
    '-Wextra-semi',
]

# These are the args that are used to BUILD libc++, not the args used by consumers
libcxx_compile_args = [
	'-nostdinc++',
	'-fvisibility-inlines-hidden',
	'-D_LIBCPP_BUILD_STATIC',
	'-D_LIBCPP_BUILDING_LIBRARY',
	'-D_LIBCPP_HAS_NO_PRAGMA_SYSTEM_HEADER',
	'-DLIBCXX_BUILDING_LIBCXXABI',
] + libcxx_warning_flags

libcxx_link_args = [
	'-nodefaultlibs',
]

libcxx_cross_args = []
libcxx_native_args = []
libcxx_cross_link_args = []

###########################
# Check Compiler Settings #
###########################

if target_compiler.has_argument('-Wmismatched-tags')
	libcxxabi_cross_args += '-Wmismatched-tags'
endif

if native_compiler.has_argument('-Wmismatched-tags')
	libcxxabi_native_args += '-Wmismatched-tags'
endif

if target_compiler.has_argument('-Wnewline-eof')
	libcxxabi_cross_args += '-Wnewline-eof'
endif

if native_compiler.has_argument('-Wnewline-eof')
	libcxxabi_native_args += '-Wnewline-eof'
endif

if target_compiler.has_argument('-Wshorten-64-to-32')
	libcxxabi_cross_args += '-Wshorten-64-to-32'
endif

if native_compiler.has_argument('-Wshorten-64-to-32')
	libcxxabi_native_args += '-Wshorten-64-to-32'
endif

if target_compiler.get_id() == 'clang'
	libcxx_cross_args += ['-Wno-user-defined-literals', '-Wno-covered-switch-default']

	if host_os == 'darwin'
		libcxx_cross_args += ['-U__STRICT_ANSI__']
	endif
endif

if native_compiler.get_id() == 'clang'
	libcxx_native_args += ['-Wno-user-defined-literals', '-Wno-covered-switch-default']

	if build_os == 'darwin'
		libcxx_native_args += ['-U__STRICT_ANSI__']
	endif
endif

if target_compiler.get_id() == 'gcc'
	libcxx_cross_args += ['-Wno-literal-suffix', '-Wno-c++14-compat', '-Wno-noexcept-type']
endif

if native_compiler.get_id() == 'gcc'
	libcxx_native_args += ['-Wno-literal-suffix', '-Wno-c++14-compat', '-Wno-noexcept-type']
endif

##########################
# Set Default File Lists #
##########################

libcxxabi_files = []
libcxxabi_native_files = []

libcxxabi_files += files(
	'libcxxabi/src/abort_message.cpp',
	'libcxxabi/src/cxa_aux_runtime.cpp',
	'libcxxabi/src/cxa_default_handlers.cpp',
	'libcxxabi/src/cxa_demangle.cpp',
	'libcxxabi/src/cxa_exception_storage.cpp',
	'libcxxabi/src/cxa_guard.cpp',
	'libcxxabi/src/cxa_handlers.cpp',
	'libcxxabi/src/cxa_unexpected.cpp',
	'libcxxabi/src/cxa_vector.cpp',
	'libcxxabi/src/cxa_virtual.cpp',
	'libcxxabi/src/fallback_malloc.cpp',
	'libcxxabi/src/private_typeinfo.cpp',
	'libcxxabi/src/stdlib_exception.cpp',
	'libcxxabi/src/stdlib_stdexcept.cpp',
	'libcxxabi/src/stdlib_typeinfo.cpp',
)

libcpp_core_files = []

libcpp_core_files += files(
	'libcxx/src/algorithm.cpp',
	'libcxx/src/any.cpp',
	'libcxx/src/bind.cpp',
	'libcxx/src/charconv.cpp',
	'libcxx/src/condition_variable.cpp',
	'libcxx/src/debug.cpp',
	'libcxx/src/exception.cpp',
	'libcxx/src/functional.cpp',
	'libcxx/src/future.cpp',
	'libcxx/src/hash.cpp',
	'libcxx/src/ios.cpp',
	'libcxx/src/iostream.cpp',
	'libcxx/src/locale.cpp',
	'libcxx/src/memory.cpp',
	'libcxx/src/mutex.cpp',
	'libcxx/src/new.cpp',
	'libcxx/src/optional.cpp',
	'libcxx/src/random.cpp',
	'libcxx/src/regex.cpp',
	'libcxx/src/shared_mutex.cpp',
	'libcxx/src/stdexcept.cpp',
	'libcxx/src/string.cpp',
	'libcxx/src/strstream.cpp',
	'libcxx/src/system_error.cpp',
	'libcxx/src/thread.cpp',
	'libcxx/src/typeinfo.cpp',
	'libcxx/src/utility.cpp',
	'libcxx/src/valarray.cpp',
	'libcxx/src/variant.cpp',
	'libcxx/src/vector.cpp',
)

if enable_chrono == true
	libcpp_core_files += files('libcxx/src/chrono.cpp')
endif

libcpp_experimental_files = files('libcxx/src/experimental/memory_resource.cpp')

libcpp_filesystem_files = []

libcpp_filesystem_files += files(
	'libcxx/src/filesystem/directory_iterator.cpp',
	'libcxx/src/filesystem/operations.cpp'
)

################################
# Apply Project Option Changes #
################################

if build_type == 'release'
	libcxx_compile_args += '-D_LIBCPP_DISABLE_ADDITIONAL_DIAGNOSTICS'
elif build_type == 'debug'
	libcxx_compile_args += '-D_DEBUG'
endif

if enable_werror == true
	libcxxabi_compile_args += '-Werror'
	libcxx_compile_args += '-Werror'
else
	libcxxabi_compile_args += '-Wno-error'
	libcxx_compile_args += '-Wno-error'
endif

if enable_pedantic_error == true
	libcxxabi_compile_args += '-pedantic'
	libcxx_compile_args += '-pedantic'
endif

if disable_exceptions == true
	libcxxabi_compile_args += ['-D_LIBCXXABI_NO_EXCEPTIONS', '-fno-exceptions']
	libcxx_compile_args += ['-D_LIBCPP_NO_EXCEPTIONS', '-fno-exceptions']
else
	libcxxabi_compile_args += ['-funwind-tables']
endif

if disable_rtti == true
	libcxx_compile_args += ['-D_LIBCPP_NO_RTTI', '-fno-rtti']
endif

if enable_stdinout == false
	libcxx_conf_data.set('_LIBCPP_HAS_NO_STDIN', true)
	libcxx_conf_data.set('_LIBCPP_HAS_NO_STDIN', true)
endif

if enable_filesystem == true
	libcxx_conf_data.set('_LIBCPP_HAS_NO_GLOBAL_FILESYSTEM_NAMESPACE', true)
endif

if use_compiler_rt == true
	libcxxabi_link_args += '-rtlib=compiler-rt'
	libcxx_link_args += '-rtlib=compiler-rt'
else
	# Filesystem uses __int128_t, which requires a definition of __muloi4 when
	# compiled with UBSAN. This definition is not provided by libgcc_s, but is
	# provided by compiler-rt. So we need to disable it to avoid having multiple
	# definitions. See filesystem/int128_builtins.cpp.
	libcpp_filesystem_files += files('libcxx/src/filesystem/int128_builtins.cpp')
endif

if always_use_assert == true
	libcxxabi_compile_args += '-UNDEBUG'
	libcxx_compile_args += '-UNDEBUG'
else
	# TODO: Should we just match the libcpp behavior and not define this? The macro is different for libcxxabi...
	libcxxabi_compile_args += '-DNDEBUG'
	libcxx_compile_args += '-D_LIBCPP_DEBUG=0'
endif

if use_llvm_libunwind == true
	libcxxabi_compile_args += '-DLIBCXXABI_USE_LLVM_UNWINDER'
endif

# The default terminate handler attempts to demangle uncaught exceptions, which
# causes extra I/O and demangling code to be pulled in.
if silent_terminate == true
	libcxxabi_compile_args += '-DLIBCXXABI_SILENT_TERMINATE'
endif

if default_newdelete == true
	libcxxabi_files += files('libcxxabi/src/stdlib_new_delete.cpp')
else
	libcxx_compile_args += '-D_LIBCPP_DISABLE_NEW_DELETE_DEFINITIONS'
endif

if disable_exceptions == true
	libcxxabi_files += files(
		'libcxxabi/src/cxa_noexception.cpp',
	)
else
	libcxxabi_files += files(
		'libcxxabi/src/cxa_exception.cpp',
		# We use our CXA Personality because the standard one doesn't support GCC
		'src/c++abi/cxa_personality.cpp',
	)
endif

if enable_threads == true

	if libthread.found()
		libcxx_conf_data.set('_LIBCPP_HAS_THREAD_API_PTHREAD', true)
	endif

	if host_os != 'darwin' and host_os != 'windows'
		message('enabling threads')
		libcxxabi_files += files(
			'libcxxabi/src/cxa_thread_atexit.cpp',
		)
	endif

	if build_os != 'darwin' and build_os != 'windows'
		libcxxabi_native_files += files(
			'libcxxabi/src/cxa_thread_atexit.cpp',
		)
	endif

	assert(not (has_external_threading == true and build_external_threading == true),
		'Cannot select both has_esxternal_threading and build_external_threading. Pick one.')

	if has_external_threading == true
		libcxx_conf_data.set('_LIBCPP_HAS_THREAD_API_EXTERNAL', true)
	endif

	if build_external_threading == true
		libcxx_conf_data.set('_LIBCPP_HAS_THREAD_LIBRARY_EXTERNAL', true)
	endif

	if enable_threads and not has_external_threading and not build_external_threading and not libthread.found()
		message('Enabling external threading header because threading is enabled and pthreads is not present.')
		libcxx_conf_data.set('_LIBCPP_HAS_THREAD_API_EXTERNAL', true)
	endif
else
	message('Building without threading support.')
	libcxx_conf_data.set('_LIBCPP_HAS_NO_THREADS', true)
	libcxxabi_compile_args += '-D_LIBCXXABI_HAS_NO_THREADS'
endif

# monotonic clock can only be disabled if there is no threading
if enable_monotonic_clock == false and enable_threads == false
	libcxx_conf_data.set('_LIBCPP_HAS_NO_MONOTONIC_CLOCK', true)
endif

if meson.is_cross_build()
	libcxx_cross_args += '-D_BAREMETAL'
	libcxxabi_cross_args += '-DLIBCXXABI_BAREMETAL'
endif

if force_32_bit == true
	libcxx_cross_args += '-m32'
	libcxxabi_cross_args += '-m32'
	libcxx_native_args += '-m32'
	libcxxabi_native_args += '-m32'
endif

if target_compiler.has_function('__cxa_thread_atexit_impl')
	libcxx_cross_args += ['-DHAVE___CXA_THREAD_ATEXIT_IMPL']
endif

if native_compiler.has_function('__cxa_thread_atexit_impl')
	libcxx_native_args += ['-DHAVE___CXA_THREAD_ATEXIT_IMPL']
endif

###################
# Install Headers #
###################

# This must be after all the config_data is set
subdir('include')

###################
# libcxxabi Build #
###################

# gcc-arm-none-eabi blows up if you use is_system: true to include C++ files
if meson.is_cross_build() and target_compiler.get_id() == 'gcc'
	libcxxabi_includes = [
		include_directories('include/c++abi/'),
		include_directories('include/c++/')
	]
else
	libcxxabi_includes = [
		include_directories('include/c++abi/', is_system: true),
		include_directories('include/c++/', is_system: true)
	]
endif

libcxxabi = static_library('c++abi',
    libcxxabi_files,
    include_directories: libcxxabi_includes,
    cpp_args: libcxxabi_compile_args + libcxxabi_cross_args,
    link_args: libcxxabi_link_args + libcxxabi_cross_link_args + ['-lunwind'],
    dependencies: [libcxxabi_header_deps, install_cpp_headers_dep],
    pic: true
)

libcxxabi_native = static_library('c++abi_native',
    libcxxabi_files,
    include_directories: libcxxabi_includes,
    cpp_args: libcxxabi_compile_args + libcxxabi_native_args,
    link_args: libcxxabi_link_args + ['-lunwind'],
    dependencies: [libcxxabi_header_deps, install_cpp_headers_dep],
    native: true,
    pic: true
)

libcxxabi_dep = declare_dependency(
	include_directories: include_directories('include/c++abi', is_system: true),
	link_with: libcxxabi,
	compile_args: stdlib_compiler_flags + cpp_stdlib_compiler_flags,
	link_args: stdlib_link_flags
)

libcxxabi_native_dep = declare_dependency(
	include_directories: include_directories('include/c++abi', is_system: true),
	link_with: libcxxabi_native,
	compile_args: stdlib_compiler_flags + cpp_stdlib_compiler_flags,
	link_args: stdlib_link_flags
)

################
# libcxx Build #
################

# gcc-arm-none-eabi blows up if you use is_system: true to include C++ files
if meson.is_cross_build() and target_compiler.get_id() == 'gcc'
	libcxx_extensions_include_dir = include_directories('extensions')
	libcxx_include_directories = [
		include_directories('include/c++abi'),
		include_directories('include/c++'),
		libcxx_extensions_include_dir
	]
else
	libcxx_extensions_include_dir = include_directories('extensions', is_system: true)
	libcxx_include_directories = [
		include_directories('include/c++abi', is_system: true),
		include_directories('include/c++', is_system: true),
		libcxx_extensions_include_dir
	]
endif

libcpp = static_library('c++',
    libcpp_core_files,
    cpp_args: libcxx_compile_args + libcxx_cross_args,
    include_directories: libcxx_include_directories,
    link_args: libcxx_link_args + libcxx_cross_link_args,
    dependencies: [libcxxabi_header_deps, install_cpp_headers_dep],
)

libcpp_experimental = static_library('c++experimental',
    libcpp_experimental_files,
    cpp_args: libcxx_compile_args + libcxx_cross_args,
    include_directories: libcxx_include_directories,
    link_args: libcxx_link_args + libcxx_cross_link_args,
    dependencies: [libcxxabi_header_deps, install_cpp_headers_dep],
)

libcpp_native = static_library('c++_native',
    libcpp_core_files,
    cpp_args: libcxx_compile_args + libcxx_native_args,
    include_directories: libcxx_include_directories,
    link_args: libcxx_link_args,
    dependencies: [libcxxabi_header_deps, install_cpp_headers_dep],
    native: true
)

libcpp_experimental_native = static_library('c++experimental_native',
    libcpp_experimental_files,
    cpp_args: libcxx_compile_args + libcxx_native_args,
    include_directories: libcxx_include_directories,
    link_args: libcxx_link_args,
    dependencies: [libcxxabi_header_deps, install_cpp_headers_dep],
    native: true
)

if enable_filesystem == true
	libcpp_fs = static_library('c++fs',
	    libcpp_filesystem_files,
	    cpp_args: libcxx_compile_args + libcxx_cross_args,
    	include_directories: libcxx_include_directories,
	    link_args: libcxx_link_args + libcxx_cross_link_args,
	    dependencies: [libcxxabi_header_deps, install_cpp_headers_dep],
	)

	libcpp_fs_native = static_library('c++fs_native',
	    libcpp_filesystem_files,
	    cpp_args: libcxx_compile_args + libcxx_native_args,
    	include_directories: libcxx_include_directories,
	    link_args: libcxx_link_args,
	    dependencies: [libcxxabi_header_deps, install_cpp_headers_dep],
	    native: true
	)
else
	libcpp_fs = disabler()
	libcpp_fs_native = disabler()
endif

libcxx_full_dep = declare_dependency(
	include_directories: libcxx_include_directories,
	link_with: [libcpp, libcpp_experimental],
	dependencies: [install_cpp_headers_dep],
	compile_args: stdlib_compiler_flags + cpp_stdlib_compiler_flags,
	link_args: stdlib_link_flags
)

libcxx_filesystem_dep = declare_dependency(
	include_directories: libcxx_include_directories,
	link_with: libcpp_fs,
	dependencies: [install_cpp_headers_dep],
	compile_args: stdlib_compiler_flags + cpp_stdlib_compiler_flags,
	link_args: stdlib_link_flags
)

libcxx_filesystem_native_dep = declare_dependency(
	include_directories: libcxx_include_directories,
	link_with: libcpp_fs_native,
	dependencies: [install_cpp_headers_dep],
	compile_args: stdlib_compiler_flags + cpp_stdlib_compiler_flags,
	link_args: stdlib_link_flags
)

libcxx_full_dep = declare_dependency(
	include_directories: libcxx_include_directories,
	link_with: [libcpp, libcpp_experimental],
	dependencies: [install_cpp_headers_dep],
	compile_args: stdlib_compiler_flags + cpp_stdlib_compiler_flags,
	link_args: stdlib_link_flags
)

libcxx_full_native_dep = declare_dependency(
	include_directories: libcxx_include_directories,
	link_with: [libcpp_native, libcpp_experimental_native],
	dependencies: [install_cpp_headers_dep],
	compile_args: stdlib_compiler_flags + cpp_stdlib_compiler_flags,
	link_args: stdlib_link_flags
)

libcxx_headeronly_dep = declare_dependency(
	include_directories: libcxx_include_directories,
	dependencies: [install_cpp_headers_dep],
	compile_args: stdlib_compiler_flags + cpp_stdlib_compiler_flags  + ['-D_LIBCPP_DISABLE_EXTERN_TEMPLATE']
)

libcxx_header_include_dep = declare_dependency(
	include_directories: libcxx_include_directories,
	dependencies: [install_cpp_headers_dep],
	compile_args: stdlib_compiler_flags + cpp_stdlib_compiler_flags
)
