
native_require = require

local __bundleit__ = {
    modules = {},
    loaded = {},
}

__bundleit__.modules = {
    ["ducker"] = "local ffi = require(\"ffi\")\n\nffi.cdef[[\n    typedef unsigned int uint32_t;\n    typedef void* GLADloadproc;\n\n    typedef struct {\n        float x, y;\n    } Vec2;\n\n    typedef struct {\n        float x, y, z;\n    } Vec3;\n\n    typedef struct {\n        float x, y, z, w;\n    } Vec4;\n\n    typedef struct {\n        float x, y, w, h;\n    } RectF;\n\n    typedef enum {\n        Straight,\n        Curved\n    } LineMode;\n\n    typedef enum {\n        UNIFORM_FLOAT,\n        UNIFORM_VEC2,\n        UNIFORM_VEC3,\n        UNIFORM_VEC4,\n        UNIFORM_INT\n    } UniformType;\n\n    void DuckerNative_SetupGlad(GLADloadproc loader);\n    void DuckerNative_Initialize(int screenWidth, int screenHeight);\n    void DuckerNative_Shutdown();\n    void DuckerNative_Clear();\n    void DuckerNative_SetScreenSize(int screenWidth, int screenHeight);\n    void DuckerNative_Render();\n\n    uint32_t DuckerNative_AddRect(RectF bounds, Vec4 color, int zIndex, uint32_t textureId, RectF uvRect, float borderWidth, Vec4 borderColor);\n    uint32_t DuckerNative_AddRoundedRect(RectF bounds, Vec2 shapeSize, Vec4 color, float cornerRadius, float blur, bool inset, int zIndex, uint32_t textureId, RectF uvRect, float borderWidth, Vec4 borderColor);\n    uint32_t DuckerNative_AddCircle(RectF bounds, Vec4 color, float radius, float blur, bool inset, int zIndex, uint32_t textureId, float borderWidth, Vec4 borderColor);\n    uint32_t DuckerNative_AddLine(Vec2 start, Vec2 end, Vec4 color, float width, LineMode mode, const Vec2* controls, int numControls, int zIndex);\n    void DuckerNative_DrawText(uint32_t fontId, const char* text, Vec2 position, Vec4 color, int zIndex, float rotation, Vec2 origin);\n\n    void DuckerNative_RemoveObject(uint32_t objectId);\n    void DuckerNative_SetObjectCornerRadius(uint32_t objectId, float radius);\n    void DuckerNative_SetObjectShadowColor(uint32_t objectId, Vec4 color);\n    void DuckerNative_SetObjectRotation(uint32_t objectId, float rotation);\n    void DuckerNative_SetObjectRotationOrigin(uint32_t objectId, Vec2 origin);\n    void DuckerNative_SetObjectRotationAndOrigin(uint32_t objectId, float rotation, Vec2 origin);\n    void DuckerNative_SetObjectElevation(uint32_t objectId, int elevation);\n    void DuckerNative_SetObjectShader(uint32_t objectId, uint32_t shaderId);\n    void DuckerNative_SetObjectUniform(uint32_t objectId, const char* name, UniformType type, const void* data);\n    void DuckerNative_SetObjectBorder(uint32_t objectId, float borderWidth, Vec4 borderColor);\n\n    uint32_t DuckerNative_LoadFont(const char* filepath, float size);\n    Vec2 DuckerNative_GetTextSize(uint32_t fontId, const char* text);\n    void DuckerNative_DeleteFont(uint32_t fontId);\n\n    uint32_t DuckerNative_LoadTexture(const char* filepath, int* outWidth, int* outHeight);\n    void DuckerNative_DeleteTexture(uint32_t textureId);\n    uint32_t DuckerNative_CreateShader(const char* fragmentShaderSource);\n    void DuckerNative_DeleteShader(uint32_t shaderId);\n\n    void DuckerNative_BeginContainer(RectF bounds);\n    void DuckerNative_EndContainer();\n]]\n\nlocal DuckerLib = ffi.load(\"DuckerNative\")\n\nlocal Ducker = {}\n\nDucker.LineMode = {\n    Straight = 0,\n    Curved = 1\n}\n\nDucker.UniformType = {\n    Float = 0,\n    Vec2 = 1,\n    Vec3 = 2,\n    Vec4 = 3,\n    Int = 4\n}\n\nlocal function vec2(x, y) return ffi.new(\"Vec2\", x, y) end\nlocal function vec4(x, y, z, w) return ffi.new(\"Vec4\", x, y, z, w) end\nlocal function rect(x, y, w, h) return ffi.new(\"RectF\", x, y, w, h) end\n\nDucker.SetupGlad = DuckerLib.DuckerNative_SetupGlad\nDucker.Initialize = DuckerLib.DuckerNative_Initialize\nDucker.Shutdown = DuckerLib.DuckerNative_Shutdown\nDucker.Clear = DuckerLib.DuckerNative_Clear\nDucker.SetScreenSize = DuckerLib.DuckerNative_SetScreenSize\nDucker.Render = DuckerLib.DuckerNative_Render\nDucker.RemoveObject = DuckerLib.DuckerNative_RemoveObject\nDucker.DeleteFont = DuckerLib.DuckerNative_DeleteFont\nDucker.DeleteTexture = DuckerLib.DuckerNative_DeleteTexture\nDucker.DeleteShader = DuckerLib.DuckerNative_DeleteShader\nDucker.EndContainer = DuckerLib.DuckerNative_EndContainer\n\nfunction Ducker.AddRect(bounds, color, zIndex, textureId, uvRect, borderWidth, borderColor)\n    return DuckerLib.DuckerNative_AddRect(\n        rect(bounds.x, bounds.y, bounds.w, bounds.h),\n        vec4(color.x, color.y, color.z, color.w),\n        zIndex or 0,\n        textureId or 0,\n        uvRect and rect(uvRect.x, uvRect.y, uvRect.w, uvRect.h) or rect(0, 0, 1, 1),\n        borderWidth or 0.0,\n        borderColor and vec4(borderColor.x, borderColor.y, borderColor.z, borderColor.w) or vec4(0,0,0,0)\n    )\nend\n\nfunction Ducker.AddRoundedRect(bounds, shapeSize, color, cornerRadius, blur, inset, zIndex, textureId, uvRect, borderWidth, borderColor)\n    return DuckerLib.DuckerNative_AddRoundedRect(\n        rect(bounds.x, bounds.y, bounds.w, bounds.h),\n        vec2(shapeSize.x, shapeSize.y),\n        vec4(color.x, color.y, color.z, color.w),\n        cornerRadius or 0.0,\n        blur or 0.0,\n        inset or false,\n        zIndex or 0,\n        textureId or 0,\n        uvRect and rect(uvRect.x, uvRect.y, uvRect.w, uvRect.h) or rect(0, 0, 1, 1),\n        borderWidth or 0.0,\n        borderColor and vec4(borderColor.x, borderColor.y, borderColor.z, borderColor.w) or vec4(0,0,0,0)\n    )\nend\n\nfunction Ducker.AddCircle(bounds, color, radius, blur, inset, zIndex, textureId, borderWidth, borderColor)\n     return DuckerLib.DuckerNative_AddCircle(\n        rect(bounds.x, bounds.y, bounds.w, bounds.h),\n        vec4(color.x, color.y, color.z, color.w),\n        radius or 0.0,\n        blur or 0.0,\n        inset or false,\n        zIndex or 0,\n        textureId or 0,\n        borderWidth or 0.0,\n        borderColor and vec4(borderColor.x, borderColor.y, borderColor.z, borderColor.w) or vec4(0,0,0,0)\n    )\nend\n\nfunction Ducker.AddLine(startPos, endPos, color, width, mode, controls, zIndex)\n    local numControls = (controls and #controls) or 0\n    local controlPoints = nil\n\n    if numControls > 0 then\n        controlPoints = ffi.new(\"Vec2[?]\", numControls)\n        for i = 1, numControls do\n            controlPoints[i-1].x = controls[i].x\n            controlPoints[i-1].y = controls[i].y\n        end\n    end\n\n    return DuckerLib.DuckerNative_AddLine(\n        vec2(startPos.x, startPos.y),\n        vec2(endPos.x, endPos.y),\n        vec4(color.x, color.y, color.z, color.w),\n        width or 1.0,\n        mode or Ducker.LineMode.Straight,\n        controlPoints,\n        numControls,\n        zIndex or 0\n    )\nend\n\nfunction Ducker.DrawText(fontId, text, position, color, zIndex, rotation, origin)\n    DuckerLib.DuckerNative_DrawText(\n        fontId,\n        text,\n        vec2(position.x, position.y),\n        vec4(color.x, color.y, color.z, color.w),\n        zIndex or 0,\n        rotation or 0.0,\n        origin and vec2(origin.x, origin.y) or vec2(0.0, 0.0)\n    )\nend\n\nDucker.SetObjectCornerRadius = DuckerLib.DuckerNative_SetObjectCornerRadius\nDucker.SetObjectRotation = DuckerLib.DuckerNative_SetObjectRotation\nDucker.SetObjectElevation = DuckerLib.DuckerNative_SetObjectElevation\nDucker.SetObjectShader = DuckerLib.DuckerNative_SetObjectShader\n\nfunction Ducker.SetObjectShadowColor(objectId, color)\n    DuckerLib.DuckerNative_SetObjectShadowColor(objectId, vec4(color.x, color.y, color.z, color.w))\nend\n\nfunction Ducker.SetObjectRotationOrigin(objectId, origin)\n    DuckerLib.DuckerNative_SetObjectRotationOrigin(objectId, vec2(origin.x, origin.y))\nend\n\nfunction Ducker.SetObjectRotationAndOrigin(objectId, rotation, origin)\n    DuckerLib.DuckerNative_SetObjectRotationAndOrigin(objectId, rotation, vec2(origin.x, origin.y))\nend\n\nfunction Ducker.SetObjectUniform(objectId, name, uniformType, value)\n    local cdata\n    \n    if uniformType == Ducker.UniformType.Float then\n        cdata = ffi.new(\"float[1]\", value)\n    elseif uniformType == Ducker.UniformType.Vec2 then\n        cdata = ffi.new(\"Vec2\", value.x, value.y)\n    elseif uniformType == Ducker.UniformType.Vec3 then\n        cdata = ffi.new(\"Vec3\", value.x, value.y, value.z)\n    elseif uniformType == Ducker.UniformType.Vec4 then\n        cdata = ffi.new(\"Vec4\", value.x, value.y, value.z, value.w)\n    elseif uniformType == Ducker.UniformType.Int then\n        cdata = ffi.new(\"int[1]\", value)\n    else\n        error(\"Invalid uniform type\")\n    end\n\n    DuckerLib.DuckerNative_SetObjectUniform(objectId, name, uniformType, cdata)\nend\n\nfunction Ducker.SetObjectBorder(objectId, borderWidth, borderColor)\n    DuckerLib.DuckerNative_SetObjectBorder(objectId, borderWidth, vec4(borderColor.x, borderColor.y, borderColor.z, borderColor.w))\nend\n\nDucker.LoadFont = DuckerLib.DuckerNative_LoadFont\nDucker.CreateShader = DuckerLib.DuckerNative_CreateShader\n\nfunction Ducker.GetTextSize(fontId, text)\n    local sizeVec = DuckerLib.DuckerNative_GetTextSize(fontId, text)\n    return {x = sizeVec.x, y = sizeVec.y}\nend\n\nfunction Ducker.LoadTexture(filepath)\n    local width = ffi.new(\"int[1]\")\n    local height = ffi.new(\"int[1]\")\n    local textureId = DuckerLib.DuckerNative_LoadTexture(filepath, width, height)\n\n    if textureId == 0 then\n        return nil, \"Failed to load texture\"\n    end\n\n    return textureId, width[0], height[0]\nend\n\nfunction Ducker.BeginContainer(bounds)\n    DuckerLib.DuckerNative_BeginContainer(rect(bounds.x, bounds.y, bounds.w, bounds.h))\nend\n\nreturn Ducker",
}

function __bundleit__.require(module_name)
    if __bundleit__.loaded[module_name] then
        return __bundleit__.loaded[module_name]
    end

    if __bundleit__.modules[module_name] then
        local module_code = __bundleit__.modules[module_name]
        local func, err = load(module_code, module_name, "t")

        if not func then
            error("error loading module " .. module_name .. ":\n" .. err)
        end

        local result = func()
        __bundleit__.loaded[module_name] = result or true
        return __bundleit__.loaded[module_name]
    end

    print("not found in bundle")

    local result = native_require(module_name)
    __bundleit__.loaded[module_name] = result
    return result
end

require = __bundleit__.require

-- Тестовый код просто

local ducker = require("ducker")

local loader = runtime.getProcAddress()

ducker.SetupGlad(loader)

local initialWidth = 800
local initialHeight = 600

ducker.Initialize(initialWidth, initialHeight)

print("Ducker initialized successfully.")

local rectWidth = 250
local rectHeight = 150
local rectColor = {
    x = 1.0,
    y = 0.2,
    z = 0.2,
    w = 1.0
}

local function onEnterFrame(event)
    ducker.Clear()

    local rectX = (event.width - rectWidth) / 2
    local rectY = (event.height - rectHeight) / 2
    local rectBounds = {
        x = rectX,
        y = rectY,
        w = rectWidth,
        h = rectHeight
    }

    ducker.AddRect(
        rectBounds,
        rectColor,
        0
    )
    
    ducker.Render()
end

local function onResize(event)
    ducker.SetScreenSize(event.width, event.height)
end

runtime.addEventListener("enterFrame", onEnterFrame)
runtime.addEventListener("resizeWindow", onResize)
