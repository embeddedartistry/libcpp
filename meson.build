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

#############
# libcxxabi #
#############

libcxxabi_output_dir = meson.build_root() + '/libcxxabi'

libcxxabi_args = [
	'-DLIBCXXABI_LIBCXX_INCLUDES=' + libcxx_include,
	'-DLIBCXXABI_ENABLE_SHARED=OFF',
	#'-DLLVM_LIBRARY_OUTPUT_INTDIR=' + meson.build_root(),
]

if build_type == 'release'
	libcxxabi_args += '-DCMAKE_BUILD_TYPE=Release'
endif

if enable_werror == true
	libcxxabi_args += '-DLIBCXXABI_ENABLE_WERROR=ON'
endif

if enable_pedantic_error == true
	libcxxabi_args += '-DLIBCXXABI_ENABLE_PEDANTIC=ON'
endif

if use_compiler_rt == true
	libcxxabi_args += '-DLIBCXXABI_USE_COMPILER_RT=ON'
endif


libcxxabi_cmake = custom_target(
	'libcxxabi_cmake',
	output: ['libcxxabi'],
	command: [cmake_prep, libcxxabi_output_dir, libcxxabi_args, '-B' + libcxxabi_output_dir, '-H' + libcxxabi_root],
)

# TODO: add depend_files
libcxxabi_build = custom_target(
	'libcxxabi',
	input: [libcxxabi_cmake],
	output: ['libc++abi.a'],
	command: ['make', '-C', libcxxabi_output_dir],
)

libcxxabi_dep = declare_dependency(
	include_directories: include_directories('libcxxabi/include'),
	compile_args: stdlib_compiler_flags,
	link_args: stdlib_link_flags + ['-L' + libcxxabi_output_dir + '/lib', '-lc++abi'],
)

##########
# libcxx #
##########

libcxx_output_dir = meson.build_root() + '/libcxx'

libcxx_args = [
	#'-DLIBCXX_STANDALONE_BUILD=ON',
	'-DLIBCXX_CXX_ABI_INCLUDE_PATHS=' + libcxx_include,
	'-DLIBCXX_ENABLE_SHARED=OFF',
	'-DLIBCXX_ENABLE_FILESYSTEM=OFF',
	'-DLIBCXX_INCLUDE_DOCS=OFF',
	'-DLIBCXX_INCLUDE_BENCHMARKS=OFF',
	'-DCMAKE_INSTALL_PREFIX=' + meson.build_root(),
	#'-DLLVM_LIBRARY_OUTPUT_INTDIR=' + meson.build_root(),
	#'-DLLVM_BINARY_DIR=' + meson.build_root(),
	#'-DLIBCXX_CXX_ABI=none'
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
endif

if enable_werror == true
	libcxx_args += '-DLIBCXX_ENABLE_WERROR=ON'
endif

if enable_pedantic_error == true
	libcxx_args += '-DLIBCXX_ENABLE_PEDANTIC=ON'
endif

libcxx_cmake = custom_target(
	'libcxx_cmake',
	output: ['libcxx'],
	command: [cmake_prep, libcxx_output_dir, libcxx_args, '-B' + libcxx_output_dir, '-H' + libcxx_root],
)

libcxx_build = custom_target(
	'libcxx',
	input: [libcxxabi_build, libcxx_cmake],
	output: ['libc++.a', 'libc++experimental.a', 'include'],
	command: ['make', '-C', libcxx_output_dir, 'install'],
	build_by_default: true
)

libcxx_dep = declare_dependency(
	sources: libcxx_build[2],
	include_directories: include_directories('libcxx/include'),
	compile_args: stdlib_compiler_flags,
	link_args: stdlib_link_flags + ['-L' + libcxx_output_dir + '/lib', '-lc++'],
)
