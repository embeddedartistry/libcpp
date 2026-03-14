# newlib support headers
# The upstream newlib xlocale.h was removed in LLVM 19 (locale support
# reorganized into __locale_dir/). Use the baremetal xlocale.h which
# provides the necessary locale function stubs.

configure_file(
	input: '../baremetal/xlocale.h',
	output: 'xlocale.h',
	copy: true
)
