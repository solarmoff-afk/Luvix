/*
    Runtime.cpp - часть десктоп контейнера фреймворка Luvix,
    инициализирует Lua окружение и управляет им

    Отвечает за:
        Загрузить и исполнить биндл фреймворка (engine.bundle.lua)
        Создать интерфейс для работы с событиями
        Передавать актуальную информацию об окне
*/

#include <cmath>

#include "headers/runtime.h"

#define GLFW_INCLUDE_NONE
#include <GLFW/glfw3.h>

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

LxRuntime::LxRuntime() {
    m_enterFrameEventRef = LUA_NOREF;
    m_resizeEventRef = LUA_NOREF;
}

/*
    Деструктор который закрывает состояние Lua после смерти объекта
    класса рантайма
*/

LxRuntime::~LxRuntime() {
    close();
}

/*
    Загружает lua файл фреймворка, принимает путь к файлу. Этот файл
    (чаще всего бандл фреймворка, то есть все .lua файлы фреймворка
    собранные в один для удобства запуска)
*/

int LxRuntime::boot(const std::string& bootFile) {
    /*
        Создаём состояние Lua
    */
    
    m_lua = luaL_newstate();

    if (!m_lua) {
        return -1;
    }

    /*
        Подключаем базовые библиотеки lua, Такие как math.*,
        system.*, os.*, io.* и так далее. В Lua эти библиотеки
        не включены из коробки и их необходимо подключить. Это
        можно сделать вручную, но это не является гибким подходом.
        Куда лучше использовать функцию luaL_openlibs из API lua,
        она подключит все базовые библиотеки из версии Lua
        которая используется
    */

    luaL_openlibs(m_lua);

    /*
        Добавляем аддоны. Аддон в данном случае это библиотека,
        которой нет в составе LuaJIT или оригинального lua. Они
        являются только частью Luvix либо более поздних версий lua
    */

    /*
        Этот аддон - официальный utf8 который является частью
        lua 5.3, но отсутствует в LuaJIT. Требуется для работы
        с символами, которые не поддерживает стандартный lua.
        (Например, русский язык)
    */

    luaopen_utf8(m_lua);
    lua_setglobal(m_lua, "utf8");

    /*
        Создаём рефы на таблицы. Мы не можем себе позволить создавать новую таблицу
        каждый раз когда вызывается ивент, так как это приведёт к нагрузке на
        сборщик мусора lua и снижению производительности 
    */

    lua_newtable(m_lua);
    m_enterFrameEventRef = luaL_ref(m_lua, LUA_REGISTRYINDEX);

    lua_newtable(m_lua);
    m_resizeEventRef = luaL_ref(m_lua, LUA_REGISTRYINDEX);

    /*
        Сохраняем указатель на текущий экземпляр LxRuntime в реестр,
        чтобы статические C функции могли к нему обратиться
    */

    lua_pushlightuserdata(m_lua, this);
    lua_setfield(m_lua, LUA_REGISTRYINDEX, LX_RUNTIME_KEY);

    /*
        Добавление функций библиотеки Luvix runtime.*
        Глобальная таблица для функций, которые управляют временем
        выполнения приложения. Т.е. : Добавляют и отключают слушатели,
        возвращают актуальную информацию о окне/системе  
    */

    registerGlobalTable("runtime", m_lua);
    addFunctionToTable("runtime", "addEventListener", LxRuntime::l_addEventListener, m_lua);
    addFunctionToTable("runtime", "removeEventListener", LxRuntime::l_removeEventListener, m_lua);
    addFunctionToTable("runtime", "getProcAddress", l_get_proc_address, m_lua);
    addFunctionToTable("runtime", "getScreenInfo", l_getScreenInfo, m_lua);

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
       
        if (lua_isnil(L, -1) || !event.isValid()) {
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
    Вызывает все зарегистрированные события обновления (Смены кадра)
    Вызов безопасный через метод safeCallListeners который
    позволяет избежать падение из-за неактуальности ссылки на функцию
    или рантайм ошибки во время выполнения самой функции (pcall)
*/

void LxRuntime::callEnterFrameEvents(double time, int width, int height) {
    safeCallListeners(m_enterFrameEvents, "enterFrame", [&](lua_State* L) {
        lua_rawgeti(L, LUA_REGISTRYINDEX, m_enterFrameEventRef);
        
        lua_pushstring(L, "time"); lua_pushnumber(L, time); lua_settable(L, -3);
        lua_pushstring(L, "width"); lua_pushnumber(L, width); lua_settable(L, -3);
        lua_pushstring(L, "height"); lua_pushnumber(L, height); lua_settable(L, -3);
    });
}

/*
    При изменении размеров окна вызываем соответствующие слушатели
*/

void LxRuntime::callResizeWindowEvents(int width, int height) {
    safeCallListeners(m_resizeWindowEvents, "resizeWindow", [&](lua_State* L) {
        lua_rawgeti(L, LUA_REGISTRYINDEX, m_resizeEventRef);
        lua_pushstring(L, "width"); lua_pushnumber(L, width); lua_settable(L, -3);
        lua_pushstring(L, "height"); lua_pushnumber(L, height); lua_settable(L, -3);
    });
}

/*
    Закрывает состояние Lua
*/

void LxRuntime::close() {
    if (m_lua) {
        luaL_unref(m_lua, LUA_REGISTRYINDEX, m_enterFrameEventRef);
        luaL_unref(m_lua, LUA_REGISTRYINDEX, m_resizeEventRef);

        lua_close(m_lua);
        m_lua = nullptr;
    }
}

/*
    Приватный метод который подписывает рантайм на какой-либо слушатель

    1 аргумент - какой именно слушатель, в нашем случае поддерживаются
        enterFrame

    2 аргумент - функция с аргументом event которая будет вызываться

    Всегда возвращает 1 (1 значение Lua)
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
    } else if (strcmp(eventName, "resizeWindow") == 0) {
        type = EventType::ResizeWindow;
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

        case EventType::ResizeWindow:
            runtime->m_resizeWindowEvents.push_back(newEvent);
            break;
    }

    lua_pushinteger(L, newEvent.id);

    return 1;
}

/*
    Статичная функция хелпер для поиска и пометки элемента в векторе
    как невалидного по его id
*/

static void removeFromVector(std::vector<LxEvent>* vector, int id) {
    for (size_t i = 0; i < vector->size(); ++i) {
        if ((*vector)[i].id == id) {
            (*vector)[i].makeInvalid();
            
            return;
        }
    }
}

/*
    Метод для отписки от события
*/

int LxRuntime::l_removeEventListener(lua_State* L) {    
    lua_getfield(L, LUA_REGISTRYINDEX, LX_RUNTIME_KEY);
    LxRuntime* runtime = static_cast<LxRuntime*>(lua_touserdata(L, -1));
    lua_pop(L, 1);

    if (!runtime) {
        return luaL_error(L, "Could not find LxRuntime instance.");
    }
    
    const char* eventName = luaL_checkstring(L, 1);
    int id = luaL_checkinteger(L, 2);

    if (strcmp(eventName, "enterFrame") == 0) {
        removeFromVector(&(runtime->m_enterFrameEvents), id);
    } else if (strcmp(eventName, "resizeWindow") == 0) {
        removeFromVector(&(runtime->m_resizeWindowEvents), id);
    } else {
        return luaL_error(L, "Unknown event type: %s", eventName);
    }

    return 0;
}

int LxRuntime::l_getScreenInfo(lua_State* L) {
    GLFWmonitor* monitor = glfwGetPrimaryMonitor();
    if (!monitor) {
        lua_pushnil(L);
        return 1;
    }

    const GLFWvidmode* mode = glfwGetVideoMode(monitor);
    int widthMM, heightMM;
    glfwGetMonitorPhysicalSize(monitor, &widthMM, &heightMM);

    double dpi = 96.0;

    if (widthMM > 0 && heightMM > 0 && mode) {
        double widthInches = static_cast<double>(widthMM) / 25.4;
        double heightInches = static_cast<double>(heightMM) / 25.4;
        double diagonalInches = std::sqrt(widthInches * widthInches + heightInches * heightInches);
        double diagonalPixels = std::sqrt(mode->width * mode->width + mode->height * mode->height);

        if (diagonalInches > 0) {
            dpi = diagonalPixels / diagonalInches;
        }
    } else {
        float xscale, yscale;
        glfwGetMonitorContentScale(monitor, &xscale, &yscale);
        dpi = 96.0 * xscale;
    }
    
    lua_newtable(L);
    lua_pushstring(L, "dpi");
    lua_pushnumber(L, dpi);
    lua_settable(L, -3);

    return 1;
}

static int l_get_proc_address(lua_State* L) {
    void* proc_address = (void*)glfwGetProcAddress;
    lua_pushlightuserdata(L, proc_address);
    return 1;
}