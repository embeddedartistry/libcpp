libcxx_include_files = files(
	'refstring.h',
	'atomic_support.h',
)

configure_file(
	input: libcxx_include_files,
	output: 'refstring.h',
	command: [
		cp, '@INPUT@', meson.current_build_dir()
	],
)
