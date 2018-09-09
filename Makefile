# you can set this to 1 to see all commands that are being run
export VERBOSE := 0

ifeq ($(VERBOSE),1)
export Q :=
export VERBOSE := 1
else
export Q := @
export VERBOSE := 0
endif

ENFORCESIZE = @(FILESIZE=`stat -f '%z' $1` ; \
	if [ $2 -gt 0 ]; then \
		if [ $$FILESIZE -gt $2 ] ; then \
			echo "ERROR: File $1 exceeds size limit ($$FILESIZE > $2)" ; \
			exit 1 ; \
		fi ; \
	fi )

BUILDRESULTS?=buildresults

all: buildall

.PHONY: groundwork
groundwork:
	$(Q)if [ -d "$(BUILDRESULTS)" ]; then mkdir -p $(BUILDRESULTS); fi
	$(Q)if [ ! -e "$(BUILDRESULTS)/build.ninja" ]; then meson --buildtype plain $(BUILDRESULTS); fi

.PHONY: buildall
buildall: groundwork
	$(Q)cd $(BUILDRESULTS); ninja

.PHONY: docs
docs: groundwork
	$(Q)cd $(BUILDRESULTS); ninja docs

.PHONY: format
format:
	$(Q)tools/format/clang-format-all.sh

.PHONY : format-diff
format-diff :
	$(Q)tools/format/clang-format-git-diff.sh

.PHONY : format-check
format-check :
	$(Q)tools/format/clang-format-patch.sh

.PHONY: analyze
analyze: groundwork
	$(Q) cd $(BUILDRESULTS); ninja scan-build

.PHONY: clean
clean:
	$(Q)echo Cleaning Build Output
	$(Q)rm -rf $(BUILDRESULTS)/

