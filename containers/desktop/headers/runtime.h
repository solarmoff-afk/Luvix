#pragma once

#include <vector>
#include <string>
#include <functional>
#include <cstring>
#include <iostream>

extern "C" {
    #include <lua.h>
    #include <lauxlib.h>
    #include <lualib.h>
}

struct GLFWwindow;

enum class EventType {
    EnterFrame,
    ResizeWindow
};

typedef struct {
    int ref;
    int id;    
    lua_State* L;

    bool isValid() const {
        return L != nullptr && id >= 0 && ref != LUA_REFNIL && ref != LUA_NOREF;
    }
} LxEvent;

class LxRuntime {
    public:
        LxRuntime();
        ~LxRuntime();
        
        int boot(const std::string& bootFile);
        void close();
  
        void callEnterFrameEvents(double time, int width, int height);
        void callResizeWindowEvents(int width, int height);

    private:
        lua_State* m_lua;
        
        static int l_addEventListener(lua_State* L);

        void safeCallListeners(std::vector<LxEvent>& listeners, const char* eventName, std::function<void(lua_State*)> pushArgs);

        std::vector<LxEvent> m_enterFrameEvents;
        std::vector<LxEvent> m_resizeWindowEvents;
};