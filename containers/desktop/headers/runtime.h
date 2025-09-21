#pragma once

#include <string>

extern "C" {
    #include <lua.h>
    #include <lauxlib.h>
    #include <lualib.h>
}

struct GLFWwindow;

class LxRuntime {
    public:
        LxRuntime();
        ~LxRuntime();
        
        int boot(const std::string& bootFile, GLFWwindow* window);
        void close();

    private:
        lua_State* m_lua;
        // static int l_addEventListener(lua_State* L);
};