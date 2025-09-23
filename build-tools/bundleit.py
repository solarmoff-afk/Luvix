import os
import argparse

def create_bundle(project_dir, output_file, main_file):
    modules = {}
    main_content = ""

    for root, _, files in os.walk(project_dir):
        for file in files:
            if file.endswith(".lua"):
                file_path = os.path.join(root, file)
                
                module_name = os.path.relpath(file_path, project_dir)
                module_name = module_name.replace(os.path.sep, ".")[:-4]

                with open(file_path, "r", encoding="utf-8") as f:
                    content = f.read()
                    if file == main_file:
                        main_content = content
                    else:
                        modules[module_name] = content

    if not main_content:
        print(f"Ошибка: Файл точка входа {main_file} не найден!")
        return

    bundle_template = f"""
local __bundleit__ = {{
    modules = {{}},
    loaded = {{}},
}}

{format_modules(modules)}

function __bundleit__.require(module_name)
    if __bundleit__.loaded[module_name] then
        return __bundleit__.loaded[module_name]
    end

    if not __bundleit__.modules[module_name] then
        error("Модуль '" .. module_name .. "' не найден в бандле.")
    end

    local module_code = __bundleit__.modules[module_name]
    local func, err = load(module_code, module_name, "t")

    if not func then
        error("error loading module " .. module_name .. ":\\n" .. err)
    end

    local result = func()
    __bundleit__.loaded[module_name] = result or true

    return __bundleit__.loaded[module_name]
end

require = __bundleit__.require

{main_content}
"""

    with open(output_file, "w", encoding="utf-8") as f:
        f.write(bundle_template)
    
    print(f"Проект успешно собран в {output_file}")

def format_modules(modules):
    lua_modules = []
    for name, content in modules.items():
        escaped_content = content.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')
        lua_modules.append(f'["{name}"] = "{escaped_content}",')
    
    return "__bundleit__.modules = {{\n    {}\n}}".format("\n    ".join(lua_modules))

def main():
    parser = argparse.ArgumentParser(description="Объединяет все .lua файлы в один")
    parser.add_argument("project_dir", help="Директория с Lua-проектом")
    parser.add_argument("-o", "--output", default="bundle.lua", help="Имя выходного файла")
    parser.add_argument("-m", "--main", default="main.lua", help="Имя главного файла (точки входа)")
    args = parser.parse_args()

    create_bundle(args.project_dir, args.output, args.main)

if __name__ == "__main__":
    main()