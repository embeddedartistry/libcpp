project('Embedded Artistry libcpp',
	['cpp'],
	default_options : [
		'warning_level=3',
		'werror=false',
		# `build.*` options affect `native: true targets`
		# plain options affect `native: false` targets.
		'cpp_std=c++17', 'build.cpp_std=c++17',
		# This project defaults to a release build
		'debug=false',
		'optimization=2',
	],
	license: 'MIT',
	meson_version: '>0.51.0')

#######################
# Read Build Settings #
#######################

use_external_stdlib = get_option('use-external-stdlibs')
external_stdlib_path = get_option('external-stdlib-path')
disable_rtti = get_option('disable-rtti')
disable_exceptions = get_option('disable-exceptions')
use_compiler_rt = get_option('use-compiler-rt')
enable_pedantic_error = get_option('enable-pedantic-error')
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

##################
# Compiler Flags #
##################

host_os = host_machine.system()
build_os = build_machine.system()

libthread = dependency('threads', required: false)
libthread_native = dependency('threads', native: true, required: false)

# Pick up our common compiler variables + desired_*_flags variables
subdir('build/compiler')
subdir('build/compiler/cpp')

if meson.is_cross_build()
	host_cpp_compiler = meson.get_compiler('cpp', native: false)
	if host_cpp_compiler.get_id() == 'gcc' and host_cpp_compiler.version().version_compare('<9.0') and target_architecture == 'arm'
		error('This project requires gcc-arm-none-eabi v9.0 or later. See README.md for more information.')
	endif
endif

if get_option('enable-pedantic')
	desired_common_compile_flags += '-pedantic'
else
	desired_common_compile_flags += '-Wno-pedantic'
endif

if get_option('enable-pedantic-error')
	desired_common_compile_flags += '-pedantic-error'
endif

desired_common_compile_flags += [
	'-W',
	'-Wwrite-strings',
	'-Wno-unused-member-function',
	'-Wno-useless-cast',
	'-Wno-weak-vtables',
	'-Wno-missing-prototypes',
	'-Wno-class-varargs',
	'-Wno-unused-template',
	'-Wno-zero-as-null-pointer-constant',
	'-Wno-reserved-id-macro',
	'-Wno-deprecated-dynamic-exception-spec',
	'-Wno-comma',
	'-Wno-old-style-cast',
	# These are disabled because I don't want libc++ warnings when we turn
	# on extra warnings for the framework
	'-Werror=return-type',
	'-Wno-unused-parameter',
	'-Wno-long-long',
	'-Wno-switch-default',
	'-Wno-switch-enum',
	'-Wno-inline',
	'-Wno-effc++',
	'-Wno-cast-align',
]

libcxxabi_compile_flags = [
	'-Wmismatched-tags',
	'-Wnewline-eof',
	'-Wshorten-64-to-32',
	'-Wconversion',
	'-Wchar-subscripts',
	'-Wmissing-braces',
	'-Wshadow',
	'-Wsign-compare',
	'-Wsign-conversion',
	'-Wstrict-aliasing=2',
	'-Wstrict-overflow=4',
	'-Wunused-variable',
	'-Wundef',
	# These are disabled because I don't want libc++ warnings when we turn
	# on extra warnings for the framework
	'-Wno-switch',
	'-Wno-missing-declarations',
]

libcxx_compile_flags = [
	'-Wno-literal-suffix',
	'-Wno-c++14-compat',
	'-Wno-noexcept-type',
	'-Wno-user-defined-literals',
	'-Wno-covered-switch-default',
	# These are disabled because I don't want libc++ warnings when we turn
	# on extra warnings for the framework
	'-Wno-sign-conversion',
	'-Wno-conversion',
	'-Wno-double-promotion',
]

compile_settings_list = [
	{'lang': 'cpp', 'compiler': host_cpp_compiler, 'flags': desired_cpp_compile_flags, 'isnative': false},
	{'lang': 'cpp', 'compiler': native_cpp_compiler, 'flags': desired_native_cpp_compile_flags, 'isnative': true},
]

# Process the compilation flags
subdir('build/compiler/check-and-apply-flags')
libcxxabi_host_compile_flags = host_cpp_compiler.get_supported_arguments(libcxxabi_compile_flags)
libcxxabi_native_compile_flags = native_cpp_compiler.get_supported_arguments(libcxxabi_compile_flags)
libcxx_host_compile_flags = host_cpp_compiler.get_supported_arguments(libcxx_compile_flags)
libcxx_native_compile_flags = native_cpp_compiler.get_supported_arguments(libcxx_compile_flags)

## Add Additional Flags after processing

# Reset the variables for new common flags
libcxxabi_compile_flags = [
	'-nostdinc++',
	# Let C++ library know we are building libcxxabi
	'-D_LIBCXXABI_BUILDING_LIBRARY',
	# Bring back `std::unexpected`, which is removed in C++17, to support
	# pre-C++17.
	'-D_LIBCPP_ENABLE_CXX17_REMOVED_UNEXPECTED_FUNCTIONS',
]

libcxx_compile_flags = [
	'-nostdinc++',
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
]

if get_option('debug') == true
	libcxx_compile_flags += '-D_DEBUG'
else
	libcxx_compile_flags += '-D_LIBCPP_DISABLE_ADDITIONAL_DIAGNOSTICS'
endif

if host_os == 'darwin'
	libcxx_host_compile_flags += ['-U__STRICT_ANSI__']
endif

if build_os == 'darwin'
	libcxx_native_compile_flags += ['-U__STRICT_ANSI__']
endif

common_link_flags = [
	'-nodefaultlibs',
]

libcxxabi_link_flags = [
	common_link_flags,
	'-lunwind',
]
libcxx_link_flags = [
	common_link_flags,
]

libcxxabi_host_dep_link_args = common_link_flags
libcxxabi_native_dep_link_args = common_link_flags

##########################
# Set Default File Lists #
##########################

libcxxabi_files = [
	files(
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
]
libcxxabi_native_files = []

libcpp_core_files = [
	files(
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
]

if enable_chrono == true
	libcpp_core_files += files('libcxx/src/chrono.cpp')
endif

libcpp_experimental_files = files('libcxx/src/experimental/memory_resource.cpp')

libcpp_filesystem_files = [
	files(
		'libcxx/src/filesystem/directory_iterator.cpp',
		'libcxx/src/filesystem/operations.cpp'
	)
]

libcxxabi_include_directories = [
	include_directories('include/c++abi/', is_system: true),
	include_directories('include/c++/', is_system: true)
]
libcxx_include_directories = []

libcxx_extensions_include_dir = include_directories('extensions', is_system: true)
libcxx_include_directories += [
	include_directories('include/c++abi', is_system: true),
	include_directories('include/c++', is_system: true),
	libcxx_extensions_include_dir
]

# Variables to hold target dependencies that are triggered by build options
libcxxabi_host_dependencies = []
libcxxabi_native_dependencies = []
libcxx_host_dependencies = []
libcxx_native_dependencies = []

#################################
# Initialize Configuration Data #
#################################

libcxx_conf_data = configuration_data()

# ABI version of libc++. Can be either 1 or 2, where 2 is currently not stable. Defaults to 1.
libcxx_conf_data.set('_LIBCPP_ABI_VERSION', '1')

# The inline ABI namespace used by libc++. It defaults to __n where `n` is the current ABI version.
libcxx_conf_data.set('_LIBCPP_ABI_NAMESPACE', '__1')

################################
# Apply Project Option Changes #
################################

if use_external_stdlib == true
	message('Compiling with Embedded Artistry libc')
	message('Looking for libc at location: ' + external_stdlib_path +
		'.  If libc is not found, update the external-stdlib-path configuration option.')
	# TODO: can we check for a file to confirm?

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

	libcxxabi_compile_flags += ['-D_POSIX_MEMALIGN_VISIBLE', '-DLIBCXXABI_USE_LLVM_UNWINDER']
	libcxx_compile_flags += ['-D_POSIX_MEMALIGN_VISIBLE']
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
		libcxx_host_compile_flags += ['-nostdinc', '-fno-builtin']
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
endif

if disable_exceptions == true
	message('Exceptions are disabled')
	libcxxabi_compile_flags += ['-D_LIBCXXABI_NO_EXCEPTIONS', '-fno-exceptions']
	libcxx_compile_flags += ['-fno-exceptions']
	libcxx_conf_data.set('_LIBCPP_NO_EXCEPTIONS', true)
else
	message('Exceptions are enabled')
	libcxxabi_compile_flags += ['-funwind-tables']
	libcxxabi_files += files('libcxxabi/src/cxa_exception_storage.cpp',)
endif

if disable_rtti == true
	message('RTTI is Disabled')
	libcxx_compile_flags += ['-fno-rtti']
	libcxx_conf_data.set('_LIBCPP_NO_RTTI', true)
endif

if enable_stdinout == false
	libcxx_conf_data.set('_LIBCPP_HAS_NO_STDIN', true)
endif

if enable_filesystem == false
	libcxx_conf_data.set('_LIBCPP_HAS_NO_GLOBAL_FILESYSTEM_NAMESPACE', true)
endif

if use_compiler_rt == true
	libcxxabi_link_flags += '-rtlib=compiler-rt'
	libcxx_link_flags += '-rtlib=compiler-rt'
else
	# Filesystem uses __int128_t, which requires a definition of __muloi4 when
	# compiled with UBSAN. This definition is not provided by libgcc_s, but is
	# provided by compiler-rt. So we need to disable it to avoid having multiple
	# definitions. See filesystem/int128_builtins.cpp.
	libcpp_filesystem_files += files('libcxx/src/filesystem/int128_builtins.cpp')
endif

if use_llvm_libunwind == true
	libcxxabi_compile_flags += '-DLIBCXXABI_USE_LLVM_UNWINDER'
endif

# The default terminate handler attempts to demangle uncaught exceptions, which
# causes extra I/O and demangling code to be pulled in.
if silent_terminate == true
	libcxxabi_compile_flags += '-DLIBCXXABI_SILENT_TERMINATE'
else
	assert(disable_rtti == false, 'Loud terminate requires RTTI')
endif

if default_newdelete == true
	libcxxabi_files += files('libcxxabi/src/stdlib_new_delete.cpp')
else
	libcxx_compile_flags += '-D_LIBCPP_DISABLE_NEW_DELETE_DEFINITIONS'
endif

if disable_exceptions == true
	libcxxabi_files += files(
		'libcxxabi/src/cxa_noexception.cpp',
	)
else
	libcxxabi_files += files(
		'libcxxabi/src/cxa_exception.cpp',
		# We always use our CXA Personality because the standard one doesn't support GCC
		'src/c++abi/cxa_personality.cpp',
	)
endif

if enable_threads == true
	assert(not ((thread_library == '') or (thread_library == 'none')),
		'Supply thread library if enable_threads is used')

	if thread_library == 'pthread'
		if libthread.found()
			libcxx_conf_data.set('_LIBCPP_HAS_THREAD_API_PTHREAD', true)
			libcxxabi_host_dependencies += libthread
			libcxx_host_dependencies += libthread

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

		if libthread.found()
			message('Enabling pthread support for the native C++ library')
			libcxxabi_native_args += '-D_LIBCPP_FRAMEWORK_FORCE_PTHREAD'
			libcxx_native_compile_flags += '-D_LIBCPP_FRAMEWORK_FORCE_PTHREAD'
			native_stdlib_compiler_flags += '-D_LIBCPP_FRAMEWORK_FORCE_PTHREAD'
		endif

		if libthread_native.found()
			# Then we will also force pthreads
			libcxxabi_cross_args += '-D_LIBCPP_FRAMEWORK_FORCE_PTHREAD'
			libcxx_host_compile_flags += '-D_LIBCPP_FRAMEWORK_FORCE_PTHREAD'
			stdlib_compiler_flags += '-D_LIBCPP_FRAMEWORK_FORCE_PTHREAD'
		endif
	else
		# If we aren't using pthreads or framework, use an external header
		assert(not (has_external_threading == true and build_external_threading == true),
		'Cannot select both has_external_threading and build_external_threading. Pick one.')

		message('Enabling custom external threading support.')
		if build_external_threading == true
			libcxx_conf_data.set('_LIBCPP_HAS_THREAD_LIBRARY_EXTERNAL', true)
		else
			libcxx_conf_data.set('_LIBCPP_HAS_THREAD_API_EXTERNAL', true)
			libcpp_core_files += files('src/c++/thread.cpp')
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
	libcxxabi_compile_flags += '-D_LIBCXXABI_HAS_NO_THREADS'
	libcxxabi_files += files('libcxxabi/src/cxa_guard.cpp')
endif

# monotonic clock can only be disabled if there is no threading
if enable_monotonic_clock == false and enable_threads == false
	libcxx_conf_data.set('_LIBCPP_HAS_NO_MONOTONIC_CLOCK', true)
endif

if meson.is_cross_build()
	libcxxabi_cross_args += ['-DLIBCXXABI_BAREMETAL', '-ffreestanding']
	libcxx_host_compile_flags += ['-ffreestanding']
endif

if force_32_bit == true
	libcxx_compile_flags += '-m32'
	libcxxabi_compile_flags += '-m32'
endif

if host_cpp_compiler.has_function('__cxa_thread_atexit_impl')
	libcxx_host_compile_flags += ['-DHAVE___CXA_THREAD_ATEXIT_IMPL']
elif host_machine.system() == 'darwin'
	# On OS X, clang doesn't handle weak linking the way we expect
	# So we'll work around it by undefining the weak symbol
	libcxxabi_host_dep_link_args += '-Wl,-U,___cxa_thread_atexit_impl'
endif

if native_cpp_compiler.has_function('__cxa_thread_atexit_impl')
	libcxx_native_compile_flags += ['-DHAVE___CXA_THREAD_ATEXIT_IMPL']
elif build_machine.system() == 'darwin'
	# On OS X, clang doesn't handle weak linking the way we expect
	# So we'll work around it by undefining the weak symbol
	libcxxabi_native_dep_link_args += '-Wl,-U,___cxa_thread_atexit_impl'
endif

###################
# Install Headers #
###################

# This must be after all the config_data is set
# This is the source of install_cpp_headers_dep
subdir('include')

#############################
# libcxxabi Library targets #
#############################

# Note that due to the behavior of #include_next and -isystem, you need to ensure that
# the C++ includes are _last_ to be added to a target so that they are first in the search list

libcxxabi = static_library('c++abi',
    libcxxabi_files,
    include_directories: libcxxabi_include_directories,
    cpp_args: libcxxabi_compile_flags + libcxxabi_host_compile_flags,
    link_args: libcxxabi_link_flags,
    dependencies: [install_cpp_headers_dep, libcxxabi_host_dependencies],
)

libcxxabi_native = static_library('c++abi_native',
    libcxxabi_files + libcxxabi_native_files,
    include_directories: libcxxabi_include_directories,
    cpp_args: libcxxabi_compile_flags + libcxxabi_native_compile_flags,
    link_args: libcxxabi_link_flags,
    dependencies: [install_cpp_headers_dep, libcxxabi_native_dependencies],
    native: true,
)

##########################
# libcxxabi Dependencies #
##########################

libcxxabi_dep = declare_dependency(
	include_directories: include_directories('include/c++abi', is_system: true),
	link_with: libcxxabi,
	link_args: libcxxabi_host_dep_link_args
)

libcxxabi_native_dep = declare_dependency(
	include_directories: include_directories('include/c++abi', is_system: true),
	link_with: libcxxabi_native,
	link_args: libcxxabi_native_dep_link_args
)

##########################
# libcxx Library Targets #
##########################

# Note that due to the behavior of #include_next and -isystem, you need to ensure that
# the C++ includes are _last_ to be added to a target so that they are first in the search list

libcpp = static_library('c++',
    libcpp_core_files,
    cpp_args: libcxx_compile_flags + libcxx_host_compile_flags,
    include_directories: libcxx_include_directories,
    link_args: libcxx_link_flags,
    dependencies: [
	    install_cpp_headers_dep,
	    libcxx_host_dependencies,
    ],
)

libcpp_native = static_library('c++_native',
    libcpp_core_files,
    cpp_args: libcxx_compile_flags + libcxx_native_compile_flags,
    include_directories: libcxx_include_directories,
    link_args: libcxx_link_flags,
    dependencies: [
    	install_cpp_headers_dep,
    	libcxx_native_dependencies,
    ],
    native: true
)

libcpp_experimental = static_library('c++experimental',
    libcpp_experimental_files,
    cpp_args: libcxx_compile_flags + libcxx_host_compile_flags,
    include_directories: libcxx_include_directories,
    link_args: libcxx_link_flags,
    dependencies: [
    	install_cpp_headers_dep,
    	libcxx_host_dependencies
    ],
)

libcpp_experimental_native = static_library('c++experimental_native',
    libcpp_experimental_files,
    cpp_args: libcxx_compile_flags + libcxx_native_compile_flags,
    include_directories: libcxx_include_directories,
    link_args: libcxx_link_flags,
    dependencies: [
    	install_cpp_headers_dep,
    	libcxx_native_dependencies
    ],
    native: true
)

if enable_filesystem == true
	libcpp_fs = static_library('c++fs',
		libcpp_filesystem_files,
		cpp_args: libcxx_compile_flags + libcxx_host_compile_flags,
		include_directories: libcxx_include_directories,
		link_args: libcxx_link_flags,
		dependencies: [
			install_cpp_headers_dep,
			libcxx_host_dependencies
		],
	)

	libcpp_fs_native = static_library('c++fs_native',
		libcpp_filesystem_files,
		cpp_args: libcxx_compile_flags + libcxx_native_compile_flags,
		include_directories: libcxx_include_directories,
		link_args: libcxx_link_flags,
		dependencies: [
			install_cpp_headers_dep,
			libcxx_native_dependencies
		],
		native: true
	)
else
	libcpp_fs = disabler()
	libcpp_fs_native = disabler()
endif
