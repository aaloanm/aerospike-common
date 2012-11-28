ROOT = $(CURDIR)
NAME = $(shell basename $(ROOT))
OS = $(shell uname)
ARCH = $(shell arch)

PROJECT = project

#
# Setup Tools
#

CC = gcc
CFLAGS = -Werror

LD = gcc
LDFLAGS =

AR = ar
ARFLAGS =

#
# Setup Source
#

SOURCE = src
SOURCE_MAIN = $(SOURCE)/main
SOURCE_INCL = $(SOURCE)/include
SOURCE_TEST = $(SOURCE)/test

VPATH = $(SOURCE_MAIN) $(SOURCE_INCL)

LIB_PATH = 
INC_PATH = $(SOURCE_INCL)

#
# Setup Target
#

ifeq ($(shell test -e $(PROJECT)/target.$(OS)-$(ARCH).makefile && echo 1), 1)
PLATFORM = $(OS)-$(ARCH)
include $(PROJECT)/target.$(PLATFORM).makefile
else
ifeq ($(shell test -e project/target.$(OS)-noarch.makefile && echo 1), 1)
PLATFORM = $(OS)-noarch
include $(PROJECT)/target.$(PLATFORM).makefile
else
PLATFORM = $(OS)-$(ARCH)
endif
endif

TARGET = target
TARGET_BASE = $(TARGET)/$(PLATFORM)
TARGET_BIN = $(TARGET_BASE)/bin
TARGET_DOC = $(TARGET_BASE)/doc
TARGET_LIB = $(TARGET_BASE)/lib
TARGET_OBJ = $(TARGET_BASE)/obj

#
# Builds an object, library, archive or executable using the dependencies specified for the target.
# 
# x: [dependencies]
#	 $(call <command>, include_paths, library_paths, libraries, flags)
#
# Commands:
#		build			- Automatically determine build type based on target name.
#	 	object			- Build an object: .o
#		library			- Build a dynamic shared library: .so
#		archive			- Build a static library (archive): .a
#	 	executable		- Build an executable
# 
# Arguments:
#		include_paths	- Space separated list of search paths for include files.
#						  Relative paths are relative to the project root.
#		library_paths	- Space separated list of search paths for libraries.
#						  Relative paths are relative to the project root.
#		libraries		- space separated list of libraries.
#		flags			- space separated list of linking flags.
#
# You can optionally define variables, rather than arguments as:
#
# X_inc_path = [include_paths]
# X_lib_path = [library_paths]
# X_lib = [libraries]
#	 X_flags = [flags]
#
# Where X is the name of the build target.
#

define build
	$(if $(filter .o,$(suffix $@)), 
	$(call object, $(1),$(2),$(3),$(4)),
	$(if $(filter .so,$(suffix $@)), 
		$(call library, $(1),$(2),$(3),$(4)),
		$(if $(filter .a,$(suffix $@)), 
		$(call archive, $(1),$(2),$(3),$(4)),
		$(call executable, $(1),$(2),$(3),$(4))
		)
	)
	)
endef

define executable
	$(strip $(CC) $(addprefix -I, $(INC_PATH)) $(addprefix -I, $($@_inc_path)) $(addprefix -I, $(1)) $(addprefix -L, $(LIB_PATH)) $(addprefix -L, $($@_lib_path)) $(addprefix -L, $(2)) $(addprefix -l, $($@_lib)) $(addprefix -l, $(3)) $(4) $(LDFLAGS) $($@_flags) -o $(TARGET_BIN)/$@ $^ )
endef

define archive
	$(strip $(AR) rcs $(ARFLAGS) $(4) $(TARGET_LIB)/$@ $^ )
endef

define library
	$(strip $(CC) -shared $(addprefix -I, $(INC_PATH)) $(addprefix -I, $($@_inc_path)) $(addprefix -I, $(1)) $(addprefix -L, $(LIB_PATH)) $(addprefix -L, $($@_lib_path)) $(addprefix -L, $(2)) $(addprefix -l, $($@_lib)) $(addprefix -l, $(3)) $(4) $(LDFLAGS) $($@_flags) -fPIC -o $(TARGET_LIB)/$@ $^ )
endef

define object
	$(strip $(CC) $(addprefix -I, $(INC_PATH)) $(addprefix -I, $($@_inc_path)) $(addprefix -I, $(1)) $(addprefix -L, $(LIB_PATH)) $(addprefix -L, $($@_lib_path)) $(addprefix -L, $(2)) $(addprefix -l, $($@_lib)) $(addprefix -l, $(3)) $(4) $(CFLAGS) $($@_flags) -o $@ -c $^ )
endef

#
# Builds the objects specified for use by a build target.
#
# $(call objects, [objects])
#
# Arguments:
#		objects - space separated list of object file names (i.e. x.o)
#

define objects
	$(addprefix $(TARGET_OBJ)/, $(1)) 
endef

# 
# Common Targets
#

$(TARGET):
	mkdir -p $@

$(TARGET_BASE): | $(TARGET)
	mkdir $@

$(TARGET_BIN): | $(TARGET_BASE)
	mkdir $@

$(TARGET_DOC): | $(TARGET_BASE)
	mkdir $@

$(TARGET_LIB): | $(TARGET_BASE)
	mkdir $@

$(TARGET_OBJ): | $(TARGET_BASE)
	mkdir $@

info:
	@echo
	@echo "	NAME:		 " $(NAME) 
	@echo "	OS:			 " $(OS)
	@echo "	ARCH:		 " $(ARCH)
	@echo
	@echo "	PATHS:"
	@echo "			source:		 " $(SOURCE)
	@echo "			target:		 " $(TARGET_BASE)
	@echo "			includes:	 " $(INC_PATH)
	@echo "			libraries:	" $(LIB_PATH)
	@echo
	@echo "	COMPILER:"
	@echo "			compiler:	 " $(CC)
	@echo "			flags:			" $(CFLAGS)
	@echo
	@echo "	LINKER:"
	@echo "			linker:		 " $(LD)
	@echo "			flags:			" $(LDFLAGS)
	@echo

clean: 
	@rm -rf $(TARGET)

$(TARGET_OBJ)/%.o : %.c | $(TARGET_OBJ) 
	$(call object)
