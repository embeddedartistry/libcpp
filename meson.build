project('libcpp',
	'cpp',
	default_options : ['cpp_std=c++17'],)

cmake_prep = find_program('build/scripts/prepare_cmake.sh')
mkdir = find_program('mkdir')

#############
# libcxxabi #
#############

libcxx_root = meson.current_source_dir() + '/libcxxabi'
libcxx_include = meson.current_source_dir() + '/libcxx/include'
libcxxabi_output_dir = meson.build_root() + '/libcxxabi'

libcxxabi_args = [
	'-DCMAKE_BUILD_TYPE=Release',
	'-DLIBCXXABI_LIBCXX_INCLUDES=' + libcxx_include,
	'-DLIBCXXABI_ENABLE_SHARED=OFF'
]

libcxxabi_cmake_dep = custom_target(
	'libcxxabi_cmake',
	output: ['libcxxabi_cmake'],
	command: [cmake_prep, libcxxabi_output_dir, libcxxabi_args, '-B' + libcxxabi_output_dir, '-H' + libcxx_root],
)

# TODO: Remove build by default
libcxxabi = custom_target(
	'libcxxabi',
	output: ['libc++abi.a'],
	command: ['make', '-C', libcxxabi_output_dir],
	depends: libcxxabi_cmake_dep,
	build_by_default: true
)

##########
# libcpp #
##########
