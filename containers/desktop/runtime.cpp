/*
    Runtime.cpp - часть десктоп контейнера фреймворка Luvix,
    инициализирует Lua окружение и управляет им

    Отвечает за:
        Загрузить и исполнить биндл фреймворка (engine.bundle.lua)
        Создать интерфейс для работы с событиями
        Передавать актуальную информацию об окне
*/

#include "headers/runtime.h"

/*
    Ключ для сохранения указателя в реестр
*/

static const char* LX_RUNTIME_KEY = "LxRuntimeInstance";

/*
    Статичная функция для создания глобальной таблицы в состоянии
    lua
*/

static void registerGlobalTable(const char* name, lua_State* L) {
    lua_newtable(L);
    lua_setglobal(L, name);
}

/*
    Статичная функция для добавления функции в таблицу, которую можно
    создать через void registerGlobalTable
*/

static void addFunctionToTable(const char* tableName, const char* funcName, lua_CFunction func, lua_State* L) {
    lua_getglobal(L, tableName);
    
    if (lua_istable(L, -1)) {
        lua_pushcfunction(L, func);
        lua_setfield(L, -2, funcName);
    }

    lua_pop(L, 1);
}

/*
    Конструктор по умолчанию
*/

LxRuntime::LxRuntime() {}

/*
    Деструктор который закрывает состояние Lua после смерти объекта
    класса рантайма
*/

LxRuntime::~LxRuntime() {
    close();
}

/*
    Загружает lua файл фреймворка, принимает путь к файлу и указатель
    на GLFW окно для передачи информации о его размерах и так далее
*/

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

    /*
        Сохраняем указатель на текущий экземпляр LxRuntime в реестр,
        чтобы статические C функции могли к нему обратиться
    */

    lua_pushlightuserdata(m_lua, this);
    lua_setfield(m_lua, LUA_REGISTRYINDEX, LX_RUNTIME_KEY);

    /*
        Добавляем функции библиотеки Luvix runtime.*
    */

    registerGlobalTable("runtime", m_lua);
    addFunctionToTable("runtime", "addEventListener", LxRuntime::l_addEventListener, m_lua);

    luaL_dofile(m_lua, bootFile.c_str());

    return 0;
}

/*
    Метод для безопасного вызова обработчика событий, проверяя
    валидность функции (В случае, если рефа больше нет - падения
    не будет), а также ловит ошибки и выводит лог в консоль
*/

void LxRuntime::safeCallListeners(std::vector<LxEvent>& listeners, const char* eventName, std::function<void(lua_State*)> pushArgs) {
    for (int i = listeners.size() - 1; i >= 0; --i) {
        LxEvent& event = listeners[i];
        lua_State* L = event.L;
        
        if (!L) {
            continue;
        }

        /*
            Получаем ссылку на функцию из реестра
        */
        
        lua_rawgeti(L, LUA_REGISTRYINDEX, event.ref);
        
        if (lua_isnil(L, -1)) {
            /*
                Очищаем ссылку, если она больше неактуальная 
                (Помогает избежать падения во время выполнения)
            */
            
            lua_pop(L, 1);
            luaL_unref(L, LUA_REGISTRYINDEX, event.ref);
            listeners.erase(listeners.begin() + i);
            
            continue;
        }

        pushArgs(L);

        if (lua_pcall(L, 1, 0, 0) != 0) {
            std::cerr << "Lua Error (" << eventName << "): " << lua_tostring(L, -1) << std::endl;
            lua_pop(L, 1);
        }
    }
}

/*
    Вызывает все зарегестрированные события обновления (Смены кадра)
    Вызов безопасный через метод safeCallListeners который
    позволяет избежать падение из-за неактуальности ссылки на функцию
    или рантайм ошибки во время выполнения самой функции (pcall)
*/

void LxRuntime::callEnterFrameEvents(double time, int width, int height) {
    safeCallListeners(m_enterFrameEvents, "enterFrame", [&](lua_State* L) {
        lua_newtable(L);
        lua_pushstring(L, "time"); lua_pushnumber(L, time); lua_settable(L, -3);
        lua_pushstring(L, "width"); lua_pushnumber(L, width); lua_settable(L, -3);
        lua_pushstring(L, "height"); lua_pushnumber(L, height); lua_settable(L, -3);
    });
}

/*
    Закрывает состояние Lua
*/

void LxRuntime::close() {
    if (m_lua) {
        lua_close(m_lua);
    }
}

/*
    Приватный метод который подписывает рантайм на какой-либо слушатель

    1 аргумент - какой именно слушатель, в нашем случае поддерживаются
        enterFrame

    2 аргумент - функция с аргументом event которая будет вызываться

    Всегда возвращает 0 (0 аргументов Lua)
*/

int LxRuntime::l_addEventListener(lua_State* L) {
    lua_getfield(L, LUA_REGISTRYINDEX, LX_RUNTIME_KEY);
    LxRuntime* runtime = static_cast<LxRuntime*>(lua_touserdata(L, -1));
    lua_pop(L, 1);

    if (!runtime) {
        return luaL_error(L, "Could not find LxRuntime instance.");
    }
    
    static int nextId = 1;

    const char* eventName = luaL_checkstring(L, 1);
    luaL_checktype(L, 2, LUA_TFUNCTION);

    EventType type;
    if (strcmp(eventName, "enterFrame") == 0) {
        type = EventType::EnterFrame;
    } else {
        return luaL_error(L, "Unknown event type: %s", eventName);
    }

    /*
        Сохраняем функцию в реестр
    */

    lua_pushvalue(L, 2);
    int ref = luaL_ref(L, LUA_REGISTRYINDEX);
    
    LxEvent newEvent;
    newEvent.L = L;
    newEvent.ref = ref;
    newEvent.id = nextId++;

    switch (type) {
        case EventType::EnterFrame:
            runtime->m_enterFrameEvents.push_back(newEvent);
            break;
    }

    return 0;
}