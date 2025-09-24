/*
    Main.cpp часть desktop контейнера фреймворка Luvix
    Зависит от: GLFW3, GLAD
*/

#include <filesystem>
#include <string>
#include <iostream>
#include <vector>

#include "headers/runtime.h"

#define GLFW_INCLUDE_NONE
#include <GLFW/glfw3.h>

/*
    Эта функция нужна для получения имени файла из аргумента. Это
    нужно чтобы дать окну такой заголовок, который соотвествует
    запускаемому файлу. Допустим:
        Clicker.exe -> Заголвлок окна Clicker.exe
*/

std::string getWindowTitleFromExecutable(char* argv0) {
    std::filesystem::path executablePath(argv0);   
    std::string filename = executablePath.filename().string();
    
    return filename;
}

/*
    Переменные для хранения актуальных размеров окна
*/
    
int widthScreen = WINDOW_WIDTH;
int heightScreen = WINDOW_HEIGHT;

/*
    Глобальная переменная для хранения объекта класса рантайма
*/

LxRuntime runtime;

/*
    Функция, которая вызывает при изменении размера окна
    и при старте для установки размеров вьюпорта.
*/

void windowResize(int x, int y) {
    /*
        Проверка что окно не свернули, иначе приложение
        вылетит.
    */

    if (x < 1 || y < 1) { 
        return;
    }
}

/*
    Функция, которую GLFW автоматически вызывает при изменении размеров
    окна.
*/

void framebufferSizeCallback(GLFWwindow* window, int width, int height) {
    widthScreen = width;
    heightScreen = height;

    /*
        Вызываем слушатели изменения окна
        (Если в луа коде была подписка на них)
    */

    runtime.callResizeWindowEvents(width, height);
    
    windowResize(width, height);
}

/*
    Эта переменная хранит в себе информацию, активирован ли режим
    подробной отладки приложения
*/

bool verbose = false;

/*
    Эта функция нужна для гибкости. В случае, если в сообщение
    нужно будет добавить больше информации - изменение нужно будет
    внести в эту функцию, а не во все места вывода.
*/

void logDebug(const std::string& msg) {
    if (verbose) {
        std::cout << msg << std::endl;
    }
}

int main(int argc, char* argv[]) {   
    std::vector<std::string> args(argv + 1, argv + argc);
    
    /*
        Ищем флаг --verbose в команде запуска, если он есть -
        активируем подробную отладку.
    */

    for (const auto& arg : args) {
        if (arg == "--verbose") {
            verbose = true;
        }
    }
    
    /*
        Пытаемся инициализировать GLFW для кроссплатформенной работы
        с окном. Если инициализация не удалась: Нам нужно отправить
        сообщение пользователю.
    */

    if (!glfwInit()) {
        logDebug("[FATAL] GLFW can't create window, exit...");
        logDebug("[INFO] Check you GPU driver");
        logDebug("[INFO] On linux try install xorg-dev or libgl-dev");

        /*
            Возвращаем -1 чтобы приложение не выполнялось дальше,
            ведь без окна приложение бесполезно.
        */

        return -1;
    }

    /*
        Устанавливаем OpenGL 3.1, Так как это версия OpenGL
        для которой был создан Ducker. Мы НЕ выбираем профиль,
        так как на старых ноутбуках или компьютерах это может
        быть проблемой и приложение не запустится. Оставляем
        выбор за операционной системой.
    */
    
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 1);
    
    /*
        Для Мак ОС
    */

    #ifdef __APPLE__
        glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, true);
    #endif

    /*
        Устанавливаем такой же заговолок окна как и имя
        запускаемого файла
    */

    std::string windowTitle = getWindowTitleFromExecutable(argv[0]);

    GLFWwindow* window = glfwCreateWindow(WINDOW_WIDTH, WINDOW_HEIGHT, windowTitle.c_str(), NULL, NULL);
    if (!window) {
        logDebug("[FATAL] GLFW can't create window, exit...");
        logDebug("[INFO] Check you GPU driver");

        glfwTerminate();
        return -1;
    }

    /*
        Даём окну контекст OpenGL чтобы Ducker мог рисовать
        на нашем окне.
    */

    glfwMakeContextCurrent(window);

    /*
        Включает вертикальную синхронизацию, она не позволяет
        FPS подниматься выше, чем герцовка монитора.
    */

    glfwSwapInterval(1);

    /*
        Привязываем событие изменения окна к функции
    */

    glfwSetFramebufferSizeCallback(window, framebufferSizeCallback);
    windowResize(WINDOW_WIDTH, WINDOW_HEIGHT);

    /*
        Создаём рантайм и исполняем бандл
    */

    int result = runtime.boot("engine.bundle.lua");

    if (result == -1) {    
        logDebug("[INFO] Can't create LuaState");

        glfwDestroyWindow(window);
        glfwTerminate();
        return -1;
    }

    while (!glfwWindowShouldClose(window)) {
        runtime.callEnterFrameEvents(glfwGetTime(), widthScreen, heightScreen);
        
        glfwPollEvents();
        glfwSwapBuffers(window);
    }

    logDebug("[INFO] Window close");

    glfwDestroyWindow(window);
    glfwTerminate();

    return 0;
}