project('libcpp',
	'cpp',
	default_options : ['cpp_std=c++17'],)

###############
# Build Setup #
###############

cmake_prep = find_program('build/scripts/prepare_cmake.sh')
mkdir = find_program('mkdir')

libcxxabi_root = meson.current_source_dir() + '/libcxxabi'
libcxxabi_include = libcxxabi_root + '/include'

libcxx_root = meson.current_source_dir() + '/libcxx'
libcxx_include = libcxx_root + '/include'

build_type = get_option('buildtype')

subdir('build/ea-stdlib')

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

# The default terminate handler attempts to demangle uncaught exceptions, which
# causes extra I/O and demangling code to be pulled in.
silent_terminate = get_option('libcxx-silent-terminate')

#############
# libcxxabi #
#############

libcxxabi_output_dir = meson.build_root() + '/libcxxabi'

libcxxabi_disable_shared_args = '-DLIBCXXABI_ENABLE_SHARED=OFF'

libcxxabi_args = [
	'-DLIBCXXABI_LIBCXX_INCLUDES=' + libcxx_include,
	'-DLIBCXXABI_BAREMETAL=ON',
	'-DLIBCXXABI_INSTALL_LIBRARY=OFF'
]

if build_type == 'release'
	libcxxabi_args += '-DCMAKE_BUILD_TYPE=Release'
endif

if enable_werror == true
	libcxxabi_args += '-DLIBCXXABI_ENABLE_WERROR=ON'
else
	libcxxabi_args += '-DLIBCXXABI_ENABLE_WERROR=OFF'
endif

if enable_pedantic_error == true
	libcxxabi_args += '-DLIBCXXABI_ENABLE_PEDANTIC=ON'
else
	libcxxabi_args += '-DLIBCXXABI_ENABLE_PEDANTIC=OFF'
endif

if use_compiler_rt == true
	libcxxabi_args += '-DLIBCXXABI_USE_COMPILER_RT=ON'
else
	libcxxabi_args += '-DLIBCXXABI_USE_COMPILER_RT=OFF'
endif

if always_use_assert == true
	libcxxabi_args += '-DLIBCXXABI_ENABLE_ASSERTIONS=ON'
else
	libcxxabi_args += '-DLIBCXXABI_ENABLE_ASSERTIONS=OFF'
endif

if use_llvm_libunwind == true
	libcxxabi_args += [
		'-DLIBCXXABI_USE_LLVM_UNWINDER=ON',
		'-DLIBCXXABI_ENABLE_STATIC_UNWINDER=ON'
	]
endif

if enable_threads == true
	libcxxabi_args += '-DLIBCXXABI_ENABLE_THREADS=ON'
else
	libcxxabi_args += '-DLIBCXXABI_ENABLE_THREADS=OFF'
endif

if has_external_threading == true
	libcxxabi_args += '-DLIBCXXABI_HAS_EXTERNAL_THREAD_API=ON'
else
	libcxxabi_args += '-DLIBCXXABI_HAS_EXTERNAL_THREAD_API=OFF'
endif

if build_external_threading == true
	libcxxabi_args += '-DLIBCXXABI_BUILD_EXTERNAL_THREAD_API=ON'
else
	libcxxabi_args += '-DLIBCXXABI_BUILD_EXTERNAL_THREAD_API=OFF'
endif

if default_newdelete == true
	libcxxabi_args += '-DLIBCXXABI_ENABLE_NEW_DELETE_DEFINITIONS=ON'
else
	libcxxabi_args += '-DLIBCXXABI_ENABLE_NEW_DELETE_DEFINITIONS=OFF'
endif

if silent_terminate == true
	libcxxabi_args += '-DLIBCXXABI_SILENT_TERMINATE=ON'
else
	libcxxabi_args += '-DLIBCXXABI_SILENT_TERMINATE=OFF'
endif

libcxxabi_cmake = custom_target(
	'libcxxabi_cmake',
	output: ['libcxxabi'],
	command: [cmake_prep, libcxxabi_output_dir, libcxxabi_args, libcxxabi_disable_shared_args, '-B' + libcxxabi_output_dir, '-H' + libcxxabi_root],
)

# TODO: add depend_files
libcxxabi_build = custom_target(
	'libcxxabi',
	input: [libcxxabi_cmake],
	output: ['libc++abi.a'],
	command: ['make', '-C', libcxxabi_output_dir],
)

libcxxabi_dep = declare_dependency(
	include_directories: include_directories('libcxxabi/include', is_system: true),
	compile_args: stdlib_compiler_flags,
	link_args: stdlib_link_flags + ['-L' + libcxxabi_output_dir + '/lib', '-lc++abi'],
)

##########
# libcxx #
##########

libcxx_output_dir = meson.build_root() + '/libcxx'

libcxx_compile_args = []

libcxx_args = [
	#'-DLIBCXX_STANDALONE_BUILD=ON',
	'-DLIBCXX_ENABLE_SHARED=OFF',
	'-DLIBCXX_ENABLE_FILESYSTEM=OFF',
	'-DLIBCXX_INCLUDE_DOCS=OFF',
	'-DLIBCXX_INCLUDE_BENCHMARKS=OFF',
	'-DCMAKE_INSTALL_PREFIX=' + meson.build_root(),

	# Point libcxx to our ABI
	'-DLIBCXX_CXX_ABI=libcxxabi',
	'-DLIBCXX_CXX_ABI_INCLUDE_PATHS=' + libcxx_include,
	'-DLIBCXX_CXX_ABI_LIBRARY_PATH='+	libcxx_output_dir + '/lib',

	# We want to preserve the configuration settings in the __config header
	'-DLIBCXX_NEEDS_SITE_CONFIG=ON',

	# TODO: Only include this in host builds. Need some way of selecting threading library
	'-DLIBCXX_HAS_PTHREAD_API=ON'
]

if use_compiler_rt == true
	libcxx_args += '-DLIBCXX_USE_COMPILER_RT=ON'
endif

if disable_rtti == true
	libcxx_args += '-DLIBCXX_ENABLE_RTTI=OFF'
endif

if disable_exceptions == true
	libcxx_args += '-DLIBCXX_ENABLE_EXCEPTIONS=OFF'
endif

if build_type == 'release'
	libcxx_args += '-DCMAKE_BUILD_TYPE=Release'
	libcxx_compile_args += '-D_LIBCPP_DISABLE_ADDITIONAL_DIAGNOSTICS'
endif

if enable_werror == true
	libcxx_args += '-DLIBCXX_ENABLE_WERROR=ON'
endif

if enable_pedantic_error == true
	libcxx_args += '-DLIBCXX_ENABLE_PEDANTIC=ON'
endif

if always_use_assert == true
	libcxx_args += '-DLIBCXX_ENABLE_ASSERTIONS=ON'
else
	libcxx_args += '-DLIBCXX_ENABLE_ASSERTIONS=OFF'
endif

if use_llvm_libunwind == true
	libcxx_args += [
		'-DLIBCXXABI_USE_LLVM_UNWINDER=ON',
		'-DLIBCXXABI_ENABLE_STATIC_UNWINDER=ON'
	]
endif

if enable_threads == true
	libcxx_args += '-DLIBCXX_ENABLE_THREADS=ON'
else
	libcxx_args += '-DLIBCXX_ENABLE_THREADS=OFF'
endif

if has_external_threading == true
	libcxx_args += '-DLIBCXX_HAS_EXTERNAL_THREAD_API=ON'
else
	libcxx_args += '-DLIBCXX_HAS_EXTERNAL_THREAD_API=OFF'
endif

if build_external_threading == true
	libcxx_args += '-DLIBCXX_BUILD_EXTERNAL_THREAD_LIBRARY=ON'
else
	libcxx_args += '-DLIBCXX_BUILD_EXTERNAL_THREAD_LIBRARY=OFF'
endif

if enable_filesystem == true
	libcxx_args += ['-DLIBCXX_ENABLE_FILESYSTEM=ON', '-DLIBCXX_ENABLE_GLOBAL_FILESYSTEM_NAMESPACE=ON']
else
	libcxx_args += ['-DLIBCXX_ENABLE_FILESYSTEM=OFF', '-DLIBCXX_ENABLE_GLOBAL_FILESYSTEM_NAMESPACE=OFF']
endif

if enable_stdinout == true
	libcxx_args += ['-DLIBCXX_ENABLE_STDIN=ON', '-DLIBCXX_ENABLE_STDOUT=ON']
else
	libcxx_args += ['-DLIBCXX_ENABLE_STDIN=OFF', '-DLIBCXX_ENABLE_STDOUT=OFF']
endif

if default_newdelete == true
	libcxx_args += '-DLIBCXX_ENABLE_NEW_DELETE_DEFINITIONS=ON'
else
	libcxx_args += '-DLIBCXX_ENABLE_NEW_DELETE_DEFINITIONS=OFF'
endif

libcxx_cmake = custom_target(
	'libcxx_cmake',
	output: ['libcxx'],
	command: [cmake_prep, libcxx_output_dir, libcxx_args, '-B' + libcxx_output_dir, '-H' + libcxx_root],
)

libcxx_full_build = custom_target(
	'libcxx',
	input: [libcxxabi_build, libcxx_cmake],
	output: ['libc++.a', 'libc++experimental.a', 'include'],
	command: ['make', '-C', libcxx_output_dir, 'install'],
)

libcxx_include_arg = ['-isystem', meson.build_root() + '/include/c++/v1']

libcxx_full_dep = declare_dependency(
	sources: libcxx_full_build[2],
	compile_args: stdlib_compiler_flags + libcxx_include_arg + libcxx_compile_args,
	link_args: stdlib_link_flags + ['-L' + libcxx_output_dir + '/lib', '-lc++'],
)

libcxx_headeronly_dep = declare_dependency(
	sources: libcxx_full_build[2],
	compile_args: stdlib_compiler_flags + libcxx_include_arg + ['-D_LIBCPP_DISABLE_EXTERN_TEMPLATE'] + libcxx_compile_args,
)
