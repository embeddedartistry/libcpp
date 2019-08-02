project('Embedded Artistry libcpp',
	['cpp'],
	default_options : [
		# `build.*` options affect `native: true targets`
		# plain options affect `native: false` targets.
		'cpp_std=c++17', 'build.cpp_std=c++17',
	],
	license: 'MIT',
	meson_version: '>0.51.0')

###############
# Build Setup #
###############

cat = find_program('cat')
cmake_prep = find_program('build/scripts/prepare_cmake.sh')
mkdir = find_program('mkdir')
libthread = dependency('threads', required: false)
libthread_native = dependency('threads', native: true, required: false)

build_type = get_option('buildtype')

subdir('build/ea-stdlib')

host_os = host_machine.system()
build_os = build_machine.system()

native_compiler = meson.get_compiler('cpp', native: true)
target_compiler = meson.get_compiler('cpp')

#########################
# Process Build Options #
#########################

use_external_stdlib = get_option('use-external-stdlibs')
external_stdlib_path = get_option('external-stdlib-path')
disable_rtti = get_option('disable-rtti')
disable_exceptions = get_option('disable-exceptions')
use_compiler_rt = get_option('use-compiler-rt')
enable_werror = get_option('enable-werror')
enable_pedantic_error = get_option('enable-pedantic-error')
always_use_assert = get_option('always-enable-assert')
use_llvm_libunwind = get_option('use-llvm-libunwind')
enable_threads = get_option('enable-threading')
has_external_threading = get_option('libcxx-has-external-thread-api')
build_external_threading = get_option('libcxx-build-external-thread-api')
enable_filesystem = get_option('libcxx-enable-filesystem')
enable_stdinout = get_option('libcxx-enable-stdinout')
default_newdelete = get_option('libcxx-default-newdelete')
enable_monotonic_clock = get_option('libcxx-monotonic-clock')
force_32_bit = get_option('force-32-bit')
enable_chrono = get_option('libcxx-enable-chrono')
thread_library = get_option('libcxx-thread-library')
os_header_path = get_option('os-header-path')

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
	#'-Wunused-function',
	'-Wshadow',
	'-Wsign-compare',
	'-Wsign-conversion',
	'-Wstrict-aliasing=2',
	'-Wstrict-overflow=4',
	'-Wwrite-strings',
	#'-Wunused-parameter',
	'-Wunused-variable',
	'-Wundef',
	'-Wno-long-long',
	'-Werror=return-type',
	'-Wno-old-style-cast',
	# These are disabled because I don't want libc++ warnings when we turn
	# on extra warnings for the framework
	'-Wno-unused-parameter',
	'-Wno-unused-function',
	'-Wno-cast-align',
	'-Wno-switch-enum',
	'-Wno-switch',
	'-Wno-switch-default',
	'-Wno-inline',
	'-Wno-effc++',
	'-Wno-missing-declarations',
]

# These are the args that are used to BUILD libc++, not the args used by consumers
libcxxabi_compile_args = [
	'-fstrict-aliasing',
	'-fvisibility=hidden',
	'-D_LIBCPP_BUILD_STATIC',
	# Prevent libc++abi from having library dependencies on libc++
	'-D_LIBCPP_DISABLE_EXTERN_TEMPLATE',
	'-D_LIBCPP_ENABLE_CXX17_REMOVED_UNEXPECTED_FUNCTIONS',
	'-nodefaultlibs',
	'-D_LIBCXXABI_BUILDING_LIBRARY',
	# STL needs GNU functions to compile/link
	'-D_GNU_SOURCE',
] + libcxxabi_warning_flags

libcxxabi_link_args = [
	'-nodefaultlibs',
]

libcxxabi_cross_args = []
libcxxabi_native_args = []
libcxxabi_cross_link_args = []
libcxxabi_native_dependencies = []
libcxxabi_target_dependencies = []
libcxxabi_include_directories = []
libcxxabi_native_dep_link_args = []
libcxxabi_target_dep_link_args = []

libcxx_warning_flags = [
	'-Wall',
	'-Wextra',
	'-W',
	'-Wwrite-strings',
	'-Wno-unused-parameter',
	'-Wno-long-long',
	'-Werror=return-type',
	# These are disabled because I don't want libc++ warnings when we turn
	# on extra warnings for the framework
	'-Wno-old-style-cast',
	'-Wno-sign-conversion',
	'-Wno-conversion',
	'-Wno-switch-default',
	'-Wno-switch-enum',
	'-Wno-inline',
	'-Wno-effc++',
	'-Wno-cast-align',
	'-Wno-double-promotion',
]

# These are the args that are used to BUILD libc++, not the args used by consumers
libcxx_compile_args = [
	'-fvisibility-inlines-hidden',
	'-fvisibility=hidden',
	'-D_LIBCPP_BUILD_STATIC',
	'-D_LIBCPP_BUILDING_LIBRARY',
	'-D_LIBCPP_HAS_NO_PRAGMA_SYSTEM_HEADER',
	'-DLIBCXX_BUILDING_LIBCXXABI',
	# Define we don't touch libcpp debug settings,
	'-D_LIBCPP_DEBUG=0',
	# STL needs GNU functions to compile/link
	'-D_GNU_SOURCE',
] + libcxx_warning_flags

libcxx_link_args = [
	'-nodefaultlibs',
]

libcxx_cross_args = []
libcxx_native_args = []
libcxx_cross_link_args = []
libcxx_native_dependencies = []
libcxx_target_dependencies = []
libcxx_include_directories = []

libc_target_include_directories = []
libc_native_include_directories = []

###########################
# Check Compiler Settings #
###########################

if target_compiler.has_argument('-Wno-useless-cast')
	libcxxabi_cross_args += '-Wno-useless-cast'
	libcxx_cross_args += '-Wno-useless-cast'
endif

if native_compiler.has_argument('-Wno-useless-cast')
	libcxxabi_native_args += '-Wno-useless-cast'
	libcxx_native_args += '-Wno-useless-cast'
endif

if target_compiler.has_argument('-Wno-weak-vtables')
	libcxxabi_cross_args += '-Wno-weak-vtables'
	libcxx_cross_args += '-Wno-weak-vtables'
endif

if native_compiler.has_argument('-Wno-weak-vtables')
	libcxxabi_native_args += '-Wno-weak-vtables'
	libcxx_native_args += '-Wno-weak-vtables'
endif

if target_compiler.has_argument('-Wno-missing-prototypes') and target_compiler.get_id() != 'gcc'
	libcxxabi_cross_args += '-Wno-missing-prototypes'
	libcxx_cross_args += '-Wno-missing-prototypes'
endif

if native_compiler.has_argument('-Wno-missing-prototypes')  and native_compiler.get_id() != 'gcc'
	libcxxabi_native_args += '-Wno-missing-prototypes'
	libcxx_native_args += '-Wno-missing-prototypes'
endif

if target_compiler.has_argument('-Wno-unused-member-function')
	libcxxabi_cross_args += '-Wno-unused-member-function'
	libcxx_cross_args += '-Wno-unused-member-function'
endif

if native_compiler.has_argument('-Wno-unused-member-function')
	libcxxabi_native_args += '-Wno-unused-member-function'
	libcxx_native_args += '-Wno-unused-member-function'
endif

if target_compiler.has_argument('-Wno-class-varargs')
	libcxxabi_cross_args += '-Wno-class-varargs'
	libcxx_cross_args += '-Wno-class-varargs'
endif

if native_compiler.has_argument('-Wno-class-varargs')
	libcxxabi_native_args += '-Wno-class-varargs'
	libcxx_native_args += '-Wno-class-varargs'
endif

if target_compiler.has_argument('-Wno-unused-template')
	libcxxabi_cross_args += '-Wno-unused-template'
	libcxx_cross_args += '-Wno-unused-template'
endif

if native_compiler.has_argument('-Wno-unused-template')
	libcxxabi_native_args += '-Wno-unused-template'
	libcxx_native_args += '-Wno-unused-template'
endif

if target_compiler.has_argument('-Wno-zero-as-null-pointer-constant')
	libcxxabi_cross_args += '-Wno-zero-as-null-pointer-constant'
	libcxx_cross_args += '-Wno-zero-as-null-pointer-constant'
endif

if native_compiler.has_argument('-Wno-zero-as-null-pointer-constant')
	libcxxabi_native_args += '-Wno-zero-as-null-pointer-constant'
	libcxx_native_args += '-Wno-zero-as-null-pointer-constant'
endif

if target_compiler.has_argument('-Wno-reserved-id-macro')
	libcxxabi_cross_args += '-Wno-reserved-id-macro'
	libcxx_cross_args += '-Wno-reserved-id-macro'
endif

if native_compiler.has_argument('-Wno-reserved-id-macro')
	libcxxabi_native_args += '-Wno-reserved-id-macro'
	libcxx_native_args += '-Wno-reserved-id-macro'
endif

if target_compiler.has_argument('-Wno-deprecated-dynamic-exception-spec')
	libcxxabi_cross_args += '-Wno-deprecated-dynamic-exception-spec'
	libcxx_cross_args += '-Wno-deprecated-dynamic-exception-spec'
endif

if native_compiler.has_argument('-Wno-deprecated-dynamic-exception-spec')
	libcxxabi_native_args += '-Wno-deprecated-dynamic-exception-spec'
	libcxx_native_args += '-Wno-deprecated-dynamic-exception-spec'
endif

if target_compiler.has_argument('-Wno-comma')
	libcxxabi_cross_args += '-Wno-comma'
	libcxx_cross_args += '-Wno-comma'
endif

if native_compiler.has_argument('-Wno-comma')
	libcxxabi_native_args += '-Wno-comma'
	libcxx_native_args += '-Wno-comma'
endif

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
	'libcxxabi/src/cxa_aux_runtime.cpp',
	'libcxxabi/src/cxa_default_handlers.cpp',
	'src/c++abi/cxa_handlers.cpp',
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
	'libcxx/src/exception.cpp',
	'libcxx/src/functional.cpp',
	'libcxx/src/future.cpp',
	'libcxx/src/hash.cpp',
	'libcxx/src/ios.cpp',
	'libcxx/src/memory.cpp',
	'libcxx/src/mutex.cpp',
	'src/c++/new_terminate_badalloc.cpp',
	'libcxx/src/optional.cpp',
	'libcxx/src/regex.cpp',
	'libcxx/src/shared_mutex.cpp',
	'libcxx/src/stdexcept.cpp',
	'libcxx/src/strstream.cpp',
	'libcxx/src/system_error.cpp',
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

if use_external_stdlib == true
	message('Compiling with Embedded Artistry libc')
	message('Looking for libc at location: ' + external_stdlib_path +
		'.  If libc is not found, update the external-stdlib-path configuration option.')
	# TODO: can we check for a file to confirm?

	subdir('build/architecture')
	message('Building C++ for target architecture: ' + target_architecture)
	libc_target_include_directories += [
		include_directories(external_stdlib_path + '/include', is_system: true),
		include_directories(external_stdlib_path + '/printf', is_system: true),
		include_directories(external_stdlib_path + '/openlibm/include', is_system: true),
		include_directories(external_stdlib_path + '/openlibm/src', is_system: true),
		include_directories(external_stdlib_path + '/arch/' + target_architecture + '/include', is_system: true),
		include_directories('embedded-unwind/include', is_system: true)
	]

	message('Building C++ for native architecture: ' + native_architecture)
	libc_native_include_directories += [
		include_directories(external_stdlib_path + '/include', is_system: true),
		include_directories(external_stdlib_path + '/printf', is_system: true),
		include_directories(external_stdlib_path + '/openlibm/include', is_system: true),
		include_directories(external_stdlib_path + '/openlibm/src', is_system: true),
		include_directories(external_stdlib_path + '/arch/' + native_architecture + '/include', is_system: true),
		include_directories('embedded-unwind/include', is_system: true)
	]

	libcxxabi_compile_args += ['-D_POSIX_MEMALIGN_VISIBLE', '-DLIBCXXABI_USE_LLVM_UNWINDER']
	libcxx_compile_args += ['-D_POSIX_MEMALIGN_VISIBLE']
	libcxx_conf_data.set('_BAREMETAL', true)

	libcxxabi_files += files(
		'src/c++abi/abort_message.cpp',
	)

	if disable_rtti == false
		libcxxabi_files += files('src/c++abi/cxa_demangle.cpp')
	endif

	libcpp_core_files += files(
		'src/c++/debug.cpp',
		'src/c++/locale.cpp',
		'src/c++/string.cpp',
		'src/c++/random.cpp',
	)

	# TODO: build Unwind-sjlj_pthread.c
	if target_architecture == 'arm'
		libcxxabi_cross_args += ['-D__USING_SJLJ_EXCEPTIONS__']
		libcxxabi_cross_args += ['-nostdinc', '-fno-builtin']
		libcxx_cross_args += ['-nostdinc', '-fno-builtin']
	endif

	message('iostreams are not supported with EA libc')
	message('locale is not supported with EA libc')
else
	message('Compiling with the compiler or sysroot libc headers')
	libcxxabi_files += files(
		'libcxxabi/src/abort_message.cpp',
	)

	if disable_rtti == false
		libcxxabi_files += files('libcxxabi/src/cxa_demangle.cpp')
	endif

	libcpp_core_files += files(
		'libcxx/src/debug.cpp',
		'libcxx/src/iostream.cpp',
		'libcxx/src/locale.cpp',
		'libcxx/src/random.cpp',
		'libcxx/src/string.cpp',
	)

	libcxx_compile_args += ['-nostdinc++']
	libcxxabi_compile_args += ['-nostdinc++']
endif

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
	message('Exceptions are disabled')
	libcxxabi_compile_args += ['-D_LIBCXXABI_NO_EXCEPTIONS', '-fno-exceptions']
	libcxx_compile_args += ['-fno-exceptions']
	libcxx_conf_data.set('_LIBCPP_NO_EXCEPTIONS', true)
else
	message('Exceptions are enabled')
	libcxxabi_compile_args += ['-funwind-tables']
	libcxxabi_files += files('libcxxabi/src/cxa_exception_storage.cpp',)
endif

if disable_rtti == true
	message('RTTI is Disabled')
	libcxx_compile_args += ['-fno-rtti']
	libcxx_conf_data.set('_LIBCPP_NO_RTTI', true)
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
	libcxxabi_compile_args += '-DNDEBUG'
	libcxx_compile_args += '-DNDEBUG'
endif

if use_llvm_libunwind == true
	libcxxabi_compile_args += '-DLIBCXXABI_USE_LLVM_UNWINDER'
endif

# The default terminate handler attempts to demangle uncaught exceptions, which
# causes extra I/O and demangling code to be pulled in.
if silent_terminate == true
	libcxxabi_compile_args += '-DLIBCXXABI_SILENT_TERMINATE'
else
	assert(disable_rtti == false, 'Loud terminate requires RTTI')
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

	assert(not ((thread_library == '') or (thread_library == 'none')),
		'Supply thread library if enable_threads is used')

	if thread_library == 'pthread'
		if libthread.found()
			libcxx_conf_data.set('_LIBCPP_HAS_THREAD_API_PTHREAD', true)
			libcxxabi_target_dependencies += libthread
			libcxx_target_dependencies += libthread

			libcpp_core_files += files('src/c++/thread.cpp')
			libcxxabi_files += files('libcxxabi/src/cxa_guard.cpp')

			if libthread_native.found()
				libcxxabi_native_dependencies += libthread_native
				libcxx_native_dependencies += libthread_native
			endif
		else
			assert(false, 'pthread library not found')
		endif
	elif thread_library == 'ea-framework'
		# If we aren't using pthreads, use an external header
		message('Building with framework thread library support')
		message('Using include path to core RTOS headers: ' + os_header_path)
		libcxx_conf_data.set('_LIBCPP_HAS_THREAD_API_EXTERNAL', true)

		libcxxabi_include_directories += include_directories(os_header_path, is_system: true)
		libcxx_include_directories += include_directories(os_header_path, is_system: true)

		libcpp_core_files += files('src/c++/thread.cpp')

		# We can't ensure that semaphores and mutexes are safe. We use atomics.
		libcxxabi_files += files('src/lightabi/cxa_guard.cpp')

		message('Enabling pthread support for the native C++ library')
		libcxxabi_native_args += '-D_LIBCPP_FRAMEWORK_FORCE_PTHREAD'
		libcxx_native_args += '-D_LIBCPP_FRAMEWORK_FORCE_PTHREAD'
		native_stdlib_compiler_flags += '-D_LIBCPP_FRAMEWORK_FORCE_PTHREAD'

		if target_architecture == 'x86' or target_architecture == 'x86_64'
			# Then we will also force pthreads
			libcxxabi_cross_args += '-D_LIBCPP_FRAMEWORK_FORCE_PTHREAD'
			libcxx_cross_args += '-D_LIBCPP_FRAMEWORK_FORCE_PTHREAD'
			stdlib_compiler_flags += '-D_LIBCPP_FRAMEWORK_FORCE_PTHREAD'
		endif

	else
		# If we aren't using pthreads or framework, use an external header
		assert(not (has_external_threading == true and build_external_threading == true),
		'Cannot select both has_external_threading and build_external_threading. Pick one.')

		message('Enabling custom external threading support.')

		if has_external_threading == false and build_external_threading == false
			libcxx_conf_data.set('_LIBCPP_HAS_THREAD_API_EXTERNAL', true)
			has_external_threading = true
			libcpp_core_files += files('src/c++/thread.cpp')
		elif has_external_threading == true
			libcxx_conf_data.set('_LIBCPP_HAS_THREAD_API_EXTERNAL', true)
			libcpp_core_files += files('src/c++/thread.cpp')
		elif build_external_threading == true
			libcxx_conf_data.set('_LIBCPP_HAS_THREAD_LIBRARY_EXTERNAL', true)
		endif

		if os_header_path == ''
			message('If the build fails, please set os-header-path so the build can find your includes')
		else
			libcxxabi_include_directories += include_directories(os_header_path, is_system: true)
			libcxx_include_directories += include_directories(os_header_path, is_system: true)
		endif

		libcxxabi_files += files('src/c++abi/cxa_guard.cpp')
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
else
	message('Building without threading support.')
	libcxx_conf_data.set('_LIBCPP_HAS_NO_THREADS', true)
	libcxxabi_compile_args += '-D_LIBCXXABI_HAS_NO_THREADS'
	libcxxabi_files += files('libcxxabi/src/cxa_guard.cpp')
endif

# monotonic clock can only be disabled if there is no threading
if enable_monotonic_clock == false and enable_threads == false
	libcxx_conf_data.set('_LIBCPP_HAS_NO_MONOTONIC_CLOCK', true)
endif

if meson.is_cross_build()
	libcxxabi_cross_args += ['-DLIBCXXABI_BAREMETAL', '-ffreestanding']
	libcxx_cross_args += ['-ffreestanding']
endif

if force_32_bit == true
	libcxx_cross_args += '-m32'
	libcxxabi_cross_args += '-m32'
	libcxx_native_args += '-m32'
	libcxxabi_native_args += '-m32'
endif


if target_compiler.has_function('__cxa_thread_atexit_impl')
	libcxx_cross_args += ['-DHAVE___CXA_THREAD_ATEXIT_IMPL']
elif host_machine.system() == 'darwin'
	# On OS X, clang doesn't handle weak linking the way we expect
	# So we'll work around it by undefining the weak symbol
	libcxxabi_target_dep_link_args += '-Wl,-U,___cxa_thread_atexit_impl'
endif

if native_compiler.has_function('__cxa_thread_atexit_impl')
	libcxx_native_args += ['-DHAVE___CXA_THREAD_ATEXIT_IMPL']
elif build_machine.system() == 'darwin'
	# On OS X, clang doesn't handle weak linking the way we expect
	# So we'll work around it by undefining the weak symbol
	libcxxabi_native_dep_link_args += '-Wl,-U,___cxa_thread_atexit_impl'
endif

###################
# Install Headers #
###################

# This must be after all the config_data is set
subdir('include')

###################
# libcxxabi Build #
###################

# Note that due to the behavior of #include_next and -isystem, you need to ensure that
# the C++ includes are _last_ to be added to a target so that they are first in the search list

libcxxabi_include_directories += [
	include_directories('include/c++abi/', is_system: true),
	include_directories('include/c++/', is_system: true)
]

libcxxabi = static_library('c++abi',
    libcxxabi_files,
    include_directories: libc_target_include_directories + libcxxabi_include_directories,
    cpp_args: libcxxabi_compile_args + libcxxabi_cross_args,
    link_args: libcxxabi_link_args + libcxxabi_cross_link_args + ['-lunwind'],
    dependencies: [libcxxabi_header_deps, install_cpp_headers_dep, libcxxabi_target_dependencies],
    pic: true
)

libcxxabi_native = static_library('c++abi_native',
    libcxxabi_files,
    include_directories: libc_native_include_directories + libcxxabi_include_directories,
    cpp_args: libcxxabi_compile_args + libcxxabi_native_args,
    link_args: libcxxabi_link_args + ['-lunwind'],
    dependencies: [libcxxabi_header_deps, install_cpp_headers_dep, libcxxabi_native_dependencies],
    native: true,
    pic: true
)

libcxxabi_dep = declare_dependency(
	include_directories: include_directories('include/c++abi', is_system: true),
	link_with: libcxxabi,
	compile_args: stdlib_compiler_flags + cpp_stdlib_compiler_flags,
	link_args: stdlib_link_flags + libcxxabi_target_dep_link_args
)

libcxxabi_native_dep = declare_dependency(
	include_directories: include_directories('include/c++abi', is_system: true),
	link_with: libcxxabi_native,
	compile_args: stdlib_compiler_flags + cpp_stdlib_compiler_flags + native_stdlib_compiler_flags,
	link_args: stdlib_link_flags + libcxxabi_native_dep_link_args
)

################
# libcxx Build #
################

# Note that due to the behavior of #include_next and -isystem, you need to ensure that
# the C++ includes are _last_ to be added to a target so that they are first in the search list

libcxx_extensions_include_dir = include_directories('extensions', is_system: true)
libcxx_include_directories += [
	include_directories('include/c++abi', is_system: true),
	include_directories('include/c++', is_system: true),
	libcxx_extensions_include_dir
]

libcpp = static_library('c++',
    libcpp_core_files,
    cpp_args: libcxx_compile_args + libcxx_cross_args,
    include_directories: libc_target_include_directories + libcxx_include_directories,
    link_args: libcxx_link_args + libcxx_cross_link_args,
    dependencies: [
	    libcxxabi_header_deps,
	    install_cpp_headers_dep,
	    libcxx_target_dependencies,
    ],
    pic: true
)

libcpp_experimental = static_library('c++experimental',
    libcpp_experimental_files,
    cpp_args: libcxx_compile_args + libcxx_cross_args,
    include_directories: libc_target_include_directories + libcxx_include_directories,
    link_args: libcxx_link_args + libcxx_cross_link_args,
    dependencies: [libcxxabi_header_deps, install_cpp_headers_dep, libcxx_target_dependencies],
    pic: true
)

libcpp_native = static_library('c++_native',
    libcpp_core_files,
    cpp_args: libcxx_compile_args + libcxx_native_args,
    include_directories: libc_native_include_directories + libcxx_include_directories,
    link_args: libcxx_link_args,
    dependencies: [
    	libcxxabi_header_deps,
    	install_cpp_headers_dep,
    	libcxx_native_dependencies,
    ],
    pic: true,
    native: true
)

libcpp_experimental_native = static_library('c++experimental_native',
    libcpp_experimental_files,
    cpp_args: libcxx_compile_args + libcxx_native_args,
    include_directories: libc_native_include_directories + libcxx_include_directories,
    link_args: libcxx_link_args,
    dependencies: [libcxxabi_header_deps, install_cpp_headers_dep, libcxx_native_dependencies],
    pic: true,
    native: true
)

if enable_filesystem == true
	libcpp_fs = static_library('c++fs',
		libcpp_filesystem_files,
		cpp_args: libcxx_compile_args + libcxx_cross_args,
		include_directories: libc_target_include_directories + libcxx_include_directories,
		link_args: libcxx_link_args + libcxx_cross_link_args,
		dependencies: [libcxxabi_header_deps, install_cpp_headers_dep, libcxx_target_dependencies],
		pic: true
	)

	libcpp_fs_native = static_library('c++fs_native',
		libcpp_filesystem_files,
		cpp_args: libcxx_compile_args + libcxx_native_args,
		include_directories: libc_native_include_directories + libcxx_include_directories,
		link_args: libcxx_link_args,
		dependencies: [libcxxabi_header_deps, install_cpp_headers_dep, libcxx_native_dependencies],
		pic: true,
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
	compile_args: stdlib_compiler_flags + cpp_stdlib_compiler_flags + native_stdlib_compiler_flags,
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
	compile_args: stdlib_compiler_flags + cpp_stdlib_compiler_flags + native_stdlib_compiler_flags,
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

libcxx_native_header_include_dep = declare_dependency(
	include_directories: libcxx_include_directories,
	dependencies: [install_cpp_headers_dep],
	compile_args: stdlib_compiler_flags + cpp_stdlib_compiler_flags + native_stdlib_compiler_flags
)
