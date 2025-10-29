import sys
import platform
import os
import glob
import subprocess

CXX = "g++"
CC = "gcc"

CXX_SRCS = glob.glob('*.cpp') + [
    os.path.join('external', 'utf8', 'lutf8lib.cpp')
]

C_SRCS = [
    os.path.join('external', 'glad', 'src', 'glad.c')
]

BUILD_DIR = "build"
EXTERNAL_DIR = "external"
GLFW_DIR = os.path.join(EXTERNAL_DIR, "glfw")
GLAD_DIR = os.path.join(EXTERNAL_DIR, "glad")
LUAJIT_DIR = os.path.join(EXTERNAL_DIR, "luajit")

COMMON_DEFS = "-DLUAJIT_DISABLE_DLL -DGLFW_STATIC"
CXXFLAGS = f"-std=c++17 -Wall -Wextra -O2 {COMMON_DEFS}"
CFLAGS = f"-Wall -Wextra {COMMON_DEFS}"
INCLUDES = f"-I{os.path.join(GLFW_DIR, 'include')} -I{os.path.join(GLAD_DIR, 'include')} -I{os.path.join(LUAJIT_DIR, 'src')}"
CXXFLAGS += f" -DWINDOW_WIDTH=800 -DWINDOW_HEIGHT=600 {INCLUDES}"
CFLAGS += f" {INCLUDES}"

def generate_ninja_file():
    system = platform.system()
    target, ldflags, libs, rm_cmd, run_prefix = "", "", "", "", ""

    if system == "Windows":
        target = "luvix-desktop.exe"
        ldflags = f"-L{os.path.join(GLFW_DIR, 'lib')} -L{os.path.join(LUAJIT_DIR, 'bin')}"
        libs = "-lglfw3 -lopengl32 -lgdi32 -lluajit"
        rm_cmd = f"cmd.exe /c \"if exist {target} del {target} && if exist {BUILD_DIR} rmdir /s /q {BUILD_DIR}\""
        run_prefix = ""
    elif system == "Linux":
        target = "luvix-desktop"
        
        # GLFW
        glfw_lib = os.path.join(GLFW_DIR, "lib", "libglfw3.a")
        if not os.path.exists(glfw_lib):
            print(f"ОШИБКА: Не найден {glfw_lib}")
            sys.exit(1)
        
        # LuaJIT
        luajit_lib = os.path.join(LUAJIT_DIR, "bin", "libluajit.a")
        if not os.path.exists(luajit_lib):
            print(f"ОШИБКА: Не найден {luajit_lib}")
            print("   cd external/luajit && make && cp src/libluajit.a bin/")
            sys.exit(1)
        
        # Путь
        ldflags = f"-L{os.path.dirname(glfw_lib)} -L{os.path.dirname(luajit_lib)}"
        
        # ВАЖНО: libluajit.a ПОСЛЕДНИМ, и -lm -ldl
        libs = f"{glfw_lib} -lGL -lX11 -lpthread -lXrandr -lXi -ldl -lm {luajit_lib}"
        
        rm_cmd = f"rm -rf {target} {BUILD_DIR}"
        run_prefix = "./"
    elif system == "Darwin": # macOS
        target = "luvix-desktop"
        ldflags = ""
        libs = "-lglfw3 -framework Cocoa -framework OpenGL -framework IOKit"
        rm_cmd = f"rm -rf {target} {BUILD_DIR}"
        run_prefix = "./"
    else:
        print(f"Ошибка: операционная система {system} не поддерживается")
        sys.exit(1)

    cxx_objs = [os.path.join(BUILD_DIR, os.path.basename(s)).replace(".cpp", ".o") for s in CXX_SRCS]
    c_objs = [os.path.join(BUILD_DIR, os.path.basename(s)).replace(".c", ".o") for s in C_SRCS]
    all_objs = cxx_objs + c_objs

    ninja_content = f"""ninja_required_version = 1.5
builddir = {BUILD_DIR}
cxx = {CXX}
cc = {CC}
cxxflags = {CXXFLAGS}
cflags = {CFLAGS}
ldflags = {ldflags}
libs = {libs}

rule cxx
  command = $cxx $cxxflags -c $in -o $out
  description = Компиляция C++: $in

rule cc
  command = $cc $cflags -c $in -o $out
  description = Компиляция C: $in

rule link
  command = $cxx $in $ldflags $libs -o $out
  description = Линковка: $out

rule clean
  command = {rm_cmd}
  description = Очистка проекта
"""

    for src, obj in zip(CXX_SRCS, cxx_objs):
        ninja_content += f"build {obj.replace(os.sep, '/')}: cxx {src.replace(os.sep, '/')}\n"

    for src, obj in zip(C_SRCS, c_objs):
        ninja_content += f"build {obj.replace(os.sep, '/')}: cc {src.replace(os.sep, '/')}\n"

    ninja_content += f"""
build {target}: link {" ".join(all_objs).replace(os.sep, '/')}
default {target}
build clean: clean

build run: phony {target}
  command = {run_prefix}{target}
  pool = console

build run-verbose: phony {target}
  command = {run_prefix}{target} --verbose
  pool = console
"""

    with open("build.ninja", "w", encoding="utf-8") as f:
        f.write(ninja_content)
    
def main():
    if platform.system() == "Windows":
        os.system('chcp 65001 > nul')

    generate_ninja_file()

    ninja_args = sys.argv[1:]
    command = ['ninja'] + ninja_args

    try:
        result = subprocess.run(command)
        
        if result.returncode != 0:
            sys.exit(result.returncode)
    except FileNotFoundError:
        print("Ошибка: ninja не найден")
        print("Пожалуйста установите ninja")
        sys.exit(1)
    except Exception as e:
        print(f"Произошла ошибка: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
