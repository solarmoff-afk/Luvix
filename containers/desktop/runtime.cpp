/*
    Runtime.cpp - часть десктоп контейнера фреймворка Luvix

    Его цель:
        Загрузить и исполнить биндл фреймворка (engine.bundle.lua)
        Создать интерфейс для работы с событиями
        Передавать актуальную информацию об окне
*/

#include "headers/runtime.h"

static const char* LX_RUNTIME_KEY = "LxRuntimeInstance";

LxRuntime::LxRuntime() {}

LxRuntime::~LxRuntime() {
    close();
}

int LxRuntime::boot(const std::string& bootFile, GLFWwindow* window) {
    /*
        Создаём состояние Lua
    */
    
    m_lua = luaL_newstate();

    if (!m_lua) {
        return -1;
    }

    /*
        Подкоючаем стандартные библиотеки lua, Такие как math.*,
        system.*, os.*, io.* и так далее
    */

    luaL_openlibs(m_lua);

    luaL_dofile(m_lua, bootFile.c_str());

    return 0;
}

void LxRuntime::close() {
    if (m_lua) {
        // m_lua->close();
        lua_close(m_lua);
    }
}