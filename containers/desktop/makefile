SHELL := cmd.exe

CXX = g++
CC = gcc

TARGET = luvix-desktop.exe
BUILD_DIR = build

EXTERNAL_DIR = external
GLFW_DIR = $(EXTERNAL_DIR)/glfw
GLAD_DIR = $(EXTERNAL_DIR)/glad

LUAJIT_DIR = external/luajit
LUAJIT_LIB_FILE = $(LUAJIT_DIR)/bin/libluajit.a

COMMON_DEFS = -DLUAJIT_DISABLE_DLL

CXXFLAGS = -std=c++17 -Wall -Wextra -O2 $(COMMON_DEFS)
CFLAGS = -Wall -Wextra $(COMMON_DEFS)

INCLUDES = -I$(GLFW_DIR)/include \
           -I$(GLAD_DIR)/include \
		   -I$(LUAJIT_DIR)/src

CXXFLAGS += -DWINDOW_WIDTH=800 -DWINDOW_HEIGHT=600
CXXFLAGS += $(INCLUDES)
CFLAGS += $(INCLUDES)

LDFLAGS = -L$(GLFW_DIR)/lib \
			-L$(LUAJIT_DIR)/bin

LIBS = -lglfw3 -lopengl32 -lgdi32 -lluajit

RM_CMD = del
RMDIR_CMD = rmdir /s /q
MKDIR_CMD = mkdir

ifneq ($(OS),Windows_NT)
    ifeq ($(shell uname -s),Linux)
        LIBS = -lglfw3 -lGL -lX11 -lpthread -lXrandr -lXi -ldl
        RM_CMD = rm -f
        RMDIR_CMD = rm -rf
        MKDIR_CMD = mkdir -p
        TARGET = luvix-desktop
    endif

    ifeq ($(shell uname -s),Darwin)
        LIBS = -lglfw3 -framework Cocoa -framework OpenGL -framework IOKit
        RM_CMD = rm -f
        RMDIR_CMD = rm -rf
        MKDIR_CMD = mkdir -p
        TARGET = luvix-desktop
    endif
endif

CXX_SRCS = Main.cpp
C_SRCS = $(GLAD_DIR)/src/glad.c

CXX_OBJS = $(BUILD_DIR)/Main.o
C_OBJS = $(BUILD_DIR)/glad.o
OBJS = $(CXX_OBJS) $(C_OBJS)

all: $(TARGET)

$(TARGET): prepare_dirs $(OBJS)
	@echo Linking $(TARGET)...
	$(CXX) -o $@ $(OBJS) $(LDFLAGS) $(LIBS)

prepare_dirs:
	@if not exist $(BUILD_DIR) $(MKDIR_CMD) $(BUILD_DIR)

$(BUILD_DIR)/Main.o: Main.cpp
	@echo Compiling C++: $<
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(BUILD_DIR)/glad.o: $(GLAD_DIR)/src/glad.c
	@echo Compiling C: $<
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	@echo Cleaning project...
	@if exist $(BUILD_DIR) $(RMDIR_CMD) $(BUILD_DIR)
	@if exist $(TARGET) $(RM_CMD) $(TARGET)
	@echo Clean complete.

run-verbose: $(TARGET)
	@echo Running with verbose flag...
	$(TARGET) --verbose

run: $(TARGET)
	@echo Running application...
	$(TARGET)

.PHONY: all clean run run-verbose prepare_dirs