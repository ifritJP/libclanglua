NDIR=$(shell pwd)

INST_DIR=/usr/local/bin

PROXY=

SWIG=swig

####### customize Lua environment ######

# LUA_COMMAND=lua5.1
# LUA_INC=/usr/include/lua5.1
# LUA_LDFLAGS=
# LUA_SO=-llua5.1

LUA_COMMAND=lua5.3
LUA_INC=/usr/include/lua5.3
LUA_LDFLAGS=
LUA_SO=-llua5.3

# LUA_COMMAND=luajit
# LUA_INC=/usr/include/luajit-2.0
# LUA_LDFLAGS=
# LUA_SO=-lluajit-5.1

# LUA_COMMAND=./clanglua
# LUA_CFLAGS=-fPIC -DLUA_COMPAT_5_1 -DLUA_COMPAT_5_2 -I$(NDIR)/$(LUA_DIR)
# LUA_DIR=../external/lua/lua-5.3.4/src
# LUA_INC=$(NDIR)/$(LUA_DIR)
# LUA_LIB=$(LUA_DIR)/liblua.a
# LUA_INST_DIR=/usr/local/bin
# LUA_LIB_DIR=/usr/local/lib/lua/5.3
# LUA_LDFLAGS=-lncursesw

TEST_LUA_DIR=../external/lua/lua-5.3.4/src

####### customize libclang environment ######

CLANG_VER=3.8
LIBCLANG_INC=/usr/lib/llvm-$(CLANG_VER)/include
LIBCLANG_LIB=/usr/lib/llvm-$(CLANG_VER)/lib
LIBCLANG_STD_INC=$(shell find /usr/lib/llvm-$(CLANG_VER)/lib/clang/ -maxdepth 1 -mindepth 1 | head -n 1)

# LIBCLANG_DIR=/proj/next/clang/r34-final
# LIBCLANG_INC=../external/clang/r390/llvm/tools/clang/include
# LIBCLANG_STD_INC=../external/clang/r390/build/lib/clang/3.9.0/include
# LIBCLANG_LIB=/usr/lib/llvm-$(CLANG_VER)/lib

# LIBCLANG_SO=-lclang

LIBCLANG_SO=-lclang

####### make rules ######

LUA_LIB_DIR=$(shell $(LUA_COMMAND) -e $(LUA_DIR_LIB))
LUA_MOD_DIR=$(shell $(LUA_COMMAND) -e $(LUA_DIR_SCRIPT))

JOBS=3

LUA_LIB:=$(addprefix $(NDIR)/,$(LUA_LIB))

#OPT_OP = -O3

IF_LUA = libclanglua/if.lua
IFC_LUA = libclanglua/ifc.lua
COREBASE_SO = libclanglua/coreBase.so
CORE_SO = libclanglua/core.so

LUA_DIR_SCRIPT='for path in string.gmatch( package.path, "[^;]+" ) do if path:find( ".*lua.*%?%.lua" ) then print( (path:gsub( "/%?%.lua", "" )) ); break end end'
LUA_DIR_LIB='for path in string.gmatch( package.cpath, "[^;]+" ) do if path:find( ".*lua.*%?%.so" ) then print( (path:gsub( "/%?%.so", "" )) ); break end end'


ifneq ($(LUA_DIR),)
TARGET_LUA = $(LUA_COMMAND)
endif

all:
	@echo make build
	@echo make build_for_apt [PROXY=http://proxy.hoge:port/]
	@echo make test
	@echo make install
	@echo make clean

build: $(IF_LUA) $(TARGET_LUA) $(CORE_SO) 

clean:
ifneq ($(LUA_DIR),)
	$(MAKE) -C $(LUA_DIR) clean
endif
	rm -f $(COREBASE_SO) $(CORE_SO)
	rm -f $(IF_LUA) $(IFC_LUA)
	rm -f swig/libClangLua_wrap.* swig/libClangLuaBase_wrap.*
	rm -f clanglua

$(LUA_LIB):
	$(MAKE) -C $(LUA_DIR) linux ALL=liblua.a MYCFLAGS="$(LUA_CFLAGS)" MYLDFLAGS="$(LUA_LDFLAGS)"

$(IF_LUA): $(TARGET_LUA) mkwrap.lua _base.lua $(CORE_SO) 
	$(LUA_COMMAND) mkwrap.lua core $(LIBCLANG_STD_INC) $(LIBCLANG_INC) $(LUA_INC) >  mkwrap.log

$(TARGET_LUA): $(LUA_LIB)
ifneq ($(LUA_DIR),)
	$(MAKE) -C $(LUA_DIR) linux ALL=lua.o MYCFLAGS="$(LUA_CFLAGS)" MYLDFLAGS="$(LUA_LDFLAGS)"
	$(MAKE) -C $(LUA_DIR) linux LUA_T=$(NDIR)/clanglua ALL=$(NDIR)/clanglua MYLDFLAGS="$(LUA_LDFLAGS)"
endif


swig/libClangLuaBase_wrap.c: swig/libClangLuaBase.i 
	$(SWIG) -I$(LIBCLANG_INC) -o swig/libClangLuaBase_wrap.c -lua swig/libClangLuaBase.i

swig/libClangLuaBase_wrap.o: swig/libClangLuaBase_wrap.c
	gcc $(OPT_OP) -std=c99 -fPIC -c swig/libClangLuaBase_wrap.c -o swig/libClangLuaBase_wrap.o -I$(LIBCLANG_INC) -I$(LUA_INC) -L$(LIBCLANG_LIB) $(LIBCLANG_SO)


swig/libClangLua.i : $(TARGET_LUA) mkwrap.lua _base.lua $(COREBASE_SO) 
	$(LUA_COMMAND) mkwrap.lua base $(LIBCLANG_STD_INC) $(LIBCLANG_INC) $(LUA_INC) >  mkwrap.log

swig/libClangLua_wrap.c: swig/libClangLua.i 
	$(SWIG) -I$(LIBCLANG_INC) -o swig/libClangLua_wrap.c -lua swig/libClangLua.i 

swig/libClangLua_wrap.o: swig/libClangLua_wrap.c
	gcc $(OPT_OP) -std=c99 -fPIC -c swig/libClangLua_wrap.c -o swig/libClangLua_wrap.o -I$(LUA_INC) -I$(LIBCLANG_INC) -I$(LUA_INC) -L$(LIBCLANG_LIB) $(LIBCLANG_SO)



$(COREBASE_SO): swig/libClangLuaBase_wrap.o $(LUA_LIB)
	@gcc $(OPT_OP)  -fPIC -shared -Wl,-soname,$(COREBASE_SO) -o $(COREBASE_SO) -lrt -ldl -lpthread -lm swig/libClangLuaBase_wrap.o $(LUA_LIB) -L$(LIBCLANG_LIB) $(LIBCLANG_SO) $(LUA_SO)

$(CORE_SO): swig/libClangLua_wrap.o $(LUA_LIB)
	@gcc $(OPT_OP) -fPIC -shared -Wl,-soname,$(CORE_SO) -o $(CORE_SO) -lrt -ldl -lpthread -lm swig/libClangLua_wrap.o $(LUA_LIB) -L$(LIBCLANG_LIB) $(LIBCLANG_SO) $(LUA_SO)



test: build
	$(LUA_COMMAND) test.lua | grep -v -e '0\.' -e ': 0x' > test-result
	diff test-result test-result.expect

install: build
	$(MAKE) install-lib

uninstall:
	$(MAKE) uninstall-lib

install-lib:
	mkdir -p $(LUA_LIB_DIR)
	mkdir -p $(LUA_LIB_DIR)/libclanglua
	mkdir -p $(LUA_MOD_DIR)
	mkdir -p $(LUA_MOD_DIR)/libclanglua
	cp $(CORE_SO) $(LUA_LIB_DIR)/libclanglua
	cp $(IF_LUA) $(IFC_LUA) $(LUA_MOD_DIR)/libclanglua
ifneq ($(LUA_INST_DIR),)
	cp $(LUA_COMMAND) $(LUA_INST_DIR)
endif

uninstall-lib:
ifeq ($(LUA_LIB_DIR),$(shell pwd))
	echo LUA_LIB_DIR is this directrory.

else
	-rm -f $(LUA_LIB_DIR)/libclanglua/*
	-rmdir $(LUA_LIB_DIR)/libclanglua
	-rm -f $(LUA_MOD_DIR)/libclanglua/*
	-rmdir $(LUA_MOD_DIR)/libclanglua
endif
ifneq ($(LUA_INST_DIR),)
	rm $(LUA_INST_DIR)/$(LUA_COMMAND)
endif

# check command and install command
ifdef APT_TGT_CMD
check-apt:
	@echo check $(APT_TGT_CMD) ...
ifeq ($(shell bash -c "which $(APT_TGT_CMD)"),)
	@echo install $(APT_TGT_CMD)
	sudo apt-get -o Acquire::http::proxy="$(PROXY)" install $(APT_TGT_PKG)
else
	@echo ready $(APT_TGT_CMD)
endif
endif

build_for_apt:
#	-sudo apt-get -o Acquire::http::proxy="$(PROXY)" update

	@echo check clang-dev ...
ifeq ($(wildcard /usr/lib/llvm-*/clang-c),)
	sudo apt-get -o Acquire::http::proxy="$(PROXY)" install libclang-$(CLANG_VER)-dev
endif

	$(MAKE) APT_TGT_CMD=lua5.3 APT_TGT_PKG=lua5.3 check-apt 

	@echo check lua-dev ...
ifeq ($(wildcard $(LUA_INC)),)
	sudo apt-get -o Acquire::http::proxy="$(PROXY)" install liblua5.3-dev
endif

	$(MAKE) APT_TGT_CMD=swig APT_TGT_PKG=swig3.0 check-apt 

	$(MAKE) build SWIG=swig3.0
	$(MAKE) test
