#!/do/not/make
# ^^^ help out emacs, so it knows what edit mode i want.
#
# toc makefile snippet to link binaries
########################################################################
#
# Usage:
# define these vars:
#   BIN_PROGRAMS = somename anothername
#   BIN_PROGRAMS_LDADD (optional - list of libs to link to all BIN_PROGRAMS)
#   BIN_PROGRAMS_OBJECTS (optional - list of .o files to link to all BIN_PROGRAMS)
#
# For each FOO in BIN_PROGRAMS, define:
#   FOO_bin_OBJECTS = list of .o files for FOO
#   FOO_bin_LDADD = optional arguments to pass to linker, e.g. -lstdc++
#
# Reminder: when linking binaries which will use dlopen() at some point, you
# should add -rdynamic to the xxx_LDADD flags. Without this, symbols won't be
# visible by dlsym(), and some types of global/ns-scope objects won't get
# initialized.
#
# Then include this file:
#
#   include $(TOC_MAKESDIR)/BIN_PROGRAMS.make
#
# and add 'BIN_PROGRAMS' somewhere in your dependencies, e.g.:
#
#   all: BIN_PROGRAMS
########################################################################

BIN_PROGRAMS_MAKEFILE = $(TOC_MAKESDIR)/BIN_PROGRAMS.make

ifeq (1,$(configure_with_CYGWIN))
BIN_PROGRAMS_LDADD += -lcygwin
endif

# toc_link_binary call()able function:
# $1 = binary file name
# $2 = optional arguments to linker.
# list of objects to link is derived from $($(1)_bin_OBJECTS) and $(BIN_PROGRAMS_OBJECTS)
toc_link_binary = $(CXX) -o $(1) $($(1)_bin_OBJECTS) $(BIN_PROGRAMS_OBJECTS) $(LDFLAGS) $(BIN_PROGRAMS_LDADD) $($(1)_bin_LDADD) $(2)

########################################################################
# Start IF $(BIN_PROGRAMS) block...
ifneq (,$(BIN_PROGRAMS))

ifeq (1,$(configure_with_CYGWIN))
CLEAN_FILES += $(addsuffix .exe,$(BIN_PROGRAMS))
CLEAN_FILES += $(wildcard *.exe.stackdump)
else
CLEAN_FILES += $(wildcard $(BIN_PROGRAMS))
endif

BIN_PROGRAMS_DEPSFILE = .toc.BIN_PROGRAMS.make

BIN_PROGRAMS_RULES_GENERATOR = $(TOC_MAKESDIR)/makerules.BIN_PROGRAMS

BIN_PROGRAMS_COMMON_DEPS += $(TOC_MAKEFILE_NAME) $(BIN_PROGRAMS_MAKEFILE) $(BIN_PROGRAMS_OBJECTS)
$(BIN_PROGRAMS_DEPSFILE): $(TOC_MAKEFILE_NAME) $(BIN_PROGRAMS_RULES_GENERATOR) $(BIN_PROGRAMS_MAKEFILE)
ifeq (1,$(MAKING_CLEAN))
	@echo "$(MAKECMDGOALS): skipping BIN_PROGRAMS rules generation."
else
	@echo "Generating BIN_PROGRAMS rules."; \
	$(call toc_generate_rules,BIN_PROGRAMS,$(BIN_PROGRAMS)) > $@
endif
-include $(BIN_PROGRAMS_DEPSFILE)

deps: $(BIN_PROGRAMS_DEPSFILE)

strip-bins:
	strip $(BIN_PROGRAMS)

clean-bins:
	@test -n "$(BIN_PROGRAMS)" || exit 0; \
	echo "Deleting: $(BIN_PROGRAMS)"; \
	rm $(BIN_PROGRAMS) > /dev/null || true;

########################################################################
# run-bins: runs each BIN_PROGRAMS bin and stops if any return non-0.
run-bins:
	@LD_LIBRARY_PATH="$(BIN_PROGRAMS_LDPATH):.:${LD_LIBRARY_PATH}"; \
		for i in $(BIN_PROGRAMS); do \
			echo "BIN_PROGRAMS: running $$i"; ./$$i || { \
				err=$$?; \
				echo "Bin $$i exited with code $$?"; \
				exit $$err; \
			}; \
		done; \
		echo "BIN_PROGRAMS: all bins returned exit code 0."


bins: BIN_PROGRAMS

endif
# ... end IF $(BIN_PROGRAMS) block.
########################################################################
