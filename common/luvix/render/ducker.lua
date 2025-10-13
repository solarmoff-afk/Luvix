local ffi = require("ffi")

ffi.cdef[[
    typedef unsigned int uint32_t;
    typedef void* GLADloadproc;

    typedef struct {
        float opacity;
        float yOffset;
        float blurRadius;
        float spread;
    } ShadowLayer;

    typedef struct {
        float x, y;
    } Vec2;

    typedef struct {
        float x, y, z;
    } Vec3;

    typedef struct {
        float x, y, z, w;
    } Vec4;

    typedef struct {
        float x, y, w, h;
    } RectF;

    typedef enum {
        Straight,
        Curved
    } LineMode;

    typedef enum {
        UNIFORM_FLOAT,
        UNIFORM_VEC2,
        UNIFORM_VEC3,
        UNIFORM_VEC4,
        UNIFORM_INT
    } UniformType;

    void DuckerNative_SetupGlad(GLADloadproc loader);
    void DuckerNative_Initialize(int screenWidth, int screenHeight);
    void DuckerNative_Shutdown();
    void DuckerNative_Clear();
    void DuckerNative_SetScreenSize(int screenWidth, int screenHeight);
    void DuckerNative_Render(float r, float g, float b);

    uint32_t DuckerNative_AddRect(RectF bounds, Vec4 color, int zIndex, uint32_t textureId, RectF uvRect, float borderWidth, Vec4 borderColor);
    uint32_t DuckerNative_AddRoundedRect(RectF bounds, Vec2 shapeSize, Vec4 color, float cornerRadius, float blur, bool inset, int zIndex, uint32_t textureId, RectF uvRect, float borderWidth, Vec4 borderColor);
    uint32_t DuckerNative_AddCircle(RectF bounds, Vec4 color, float radius, float blur, bool inset, int zIndex, uint32_t textureId, float borderWidth, Vec4 borderColor);
    uint32_t DuckerNative_AddLine(Vec2 start, Vec2 end, Vec4 color, float width, LineMode mode, const Vec2* controls, int numControls, int zIndex);
    void DuckerNative_DrawText(uint32_t fontId, const char* text, Vec2 position, Vec4 color, int zIndex, float rotation, Vec2 origin);
    void DuckerNative_RemoveObject(uint32_t objectId);

    void DuckerNative_SetObjectVisible(uint32_t objectId, bool visible);
    void DuckerNative_SetObjectBounds(uint32_t objectId, RectF bounds);
    void DuckerNative_SetObjectColor(uint32_t objectId, Vec4 color);
    void DuckerNative_SetObjectZIndex(uint32_t objectId, int zIndex);
    void DuckerNative_SetObjectTexture(uint32_t objectId, uint32_t textureId, RectF uvRect);
    void DuckerNative_SetObjectShapeSize(uint32_t objectId, Vec2 shapeSize);
    void DuckerNative_SetObjectRadius(uint32_t objectId, float radius);
    void DuckerNative_SetObjectBlur(uint32_t objectId, float blur);
    void DuckerNative_SetObjectInset(uint32_t objectId, bool inset);
    void DuckerNative_SetObjectCornerRadius(uint32_t objectId, float radius);
    void DuckerNative_SetObjectShadowColor(uint32_t objectId, Vec4 color);
    void DuckerNative_SetObjectRotation(uint32_t objectId, float rotation);
    void DuckerNative_SetObjectRotationOrigin(uint32_t objectId, Vec2 origin);
    void DuckerNative_SetObjectRotationAndOrigin(uint32_t objectId, float rotation, Vec2 origin);
    void DuckerNative_SetObjectElevation(uint32_t objectId, int elevation);
    void DuckerNative_SetObjectShader(uint32_t objectId, uint32_t shaderId);
    void DuckerNative_SetObjectUniform(uint32_t objectId, const char* name, UniformType type, const void* data);
    void DuckerNative_SetObjectBorder(uint32_t objectId, float borderWidth, Vec4 borderColor);
    void DuckerNative_DefineShadowPreset(int elevation, const ShadowLayer* layers, int numLayers);

    uint32_t DuckerNative_LoadFont(const char* filepath, float size);
    Vec2 DuckerNative_GetTextSize(uint32_t fontId, const char* text);
    void DuckerNative_DeleteFont(uint32_t fontId);
    uint32_t DuckerNative_LoadTexture(const char* filepath, int* outWidth, int* outHeight);
    void DuckerNative_DeleteTexture(uint32_t textureId);
    uint32_t DuckerNative_CreateShader(const char* fragmentShaderSource);
    void DuckerNative_DeleteShader(uint32_t shaderId);

    void DuckerNative_BeginContainer(RectF bounds);
    void DuckerNative_EndContainer();
]]

local DuckerLib = ffi.load("DuckerNative")
local Ducker = {}

Ducker.LineMode = { Straight = 0, Curved = 1 }
Ducker.UniformType = { Float = 0, Vec2 = 1, Vec3 = 2, Vec4 = 3, Int = 4 }

local function vec2(x, y) return ffi.new("Vec2", x, y) end
local function vec3(x, y, z) return ffi.new("Vec3", x, y, z) end
local function vec4(x, y, z, w) return ffi.new("Vec4", x, y, z, w) end
local function rect(x, y, w, h) return ffi.new("RectF", x, y, w, h) end

Ducker.SetupGlad = DuckerLib.DuckerNative_SetupGlad
Ducker.Initialize = DuckerLib.DuckerNative_Initialize
Ducker.Shutdown = DuckerLib.DuckerNative_Shutdown
Ducker.Clear = DuckerLib.DuckerNative_Clear
Ducker.SetScreenSize = DuckerLib.DuckerNative_SetScreenSize
Ducker.Render = DuckerLib.DuckerNative_Render
Ducker.RemoveObject = DuckerLib.DuckerNative_RemoveObject
Ducker.DeleteFont = DuckerLib.DuckerNative_DeleteFont
Ducker.DeleteTexture = DuckerLib.DuckerNative_DeleteTexture
Ducker.DeleteShader = DuckerLib.DuckerNative_DeleteShader
Ducker.EndContainer = DuckerLib.DuckerNative_EndContainer
Ducker.LoadFont = DuckerLib.DuckerNative_LoadFont
Ducker.CreateShader = DuckerLib.DuckerNative_CreateShader

function Ducker.AddRect(bounds, color, zIndex, textureId, uvRect, borderWidth, borderColor)
    return DuckerLib.DuckerNative_AddRect(
        rect(bounds.x, bounds.y, bounds.w, bounds.h),
        vec4(color.x, color.y, color.z, color.w),
        zIndex or 0,
        textureId or 0,
        uvRect and rect(uvRect.x, uvRect.y, uvRect.w, uvRect.h) or rect(0, 0, 1, 1),
        borderWidth or 0.0,
        borderColor and vec4(borderColor.x, borderColor.y, borderColor.z, borderColor.w) or vec4(0,0,0,0)
    )
end

function Ducker.AddRoundedRect(bounds, shapeSize, color, cornerRadius, blur, inset, zIndex, textureId, uvRect, borderWidth, borderColor)
    return DuckerLib.DuckerNative_AddRoundedRect(
        rect(bounds.x, bounds.y, bounds.w, bounds.h),
        vec2(shapeSize.x, shapeSize.y),
        vec4(color.x, color.y, color.z, color.w),
        cornerRadius or 0.0,
        blur or 0.0,
        inset or false,
        zIndex or 0,
        textureId or 0,
        uvRect and rect(uvRect.x, uvRect.y, uvRect.w, uvRect.h) or rect(0, 0, 1, 1),
        borderWidth or 0.0,
        borderColor and vec4(borderColor.x, borderColor.y, borderColor.z, borderColor.w) or vec4(0,0,0,0)
    )
end

function Ducker.AddCircle(bounds, color, radius, blur, inset, zIndex, textureId, borderWidth, borderColor)
     return DuckerLib.DuckerNative_AddCircle(
        rect(bounds.x, bounds.y, bounds.w, bounds.h),
        vec4(color.x, color.y, color.z, color.w),
        radius or 0.0,
        blur or 0.0,
        inset or false,
        zIndex or 0,
        textureId or 0,
        borderWidth or 0.0,
        borderColor and vec4(borderColor.x, borderColor.y, borderColor.z, borderColor.w) or vec4(0,0,0,0)
    )
end

function Ducker.AddLine(startPos, endPos, color, width, mode, controls, zIndex)
    local numControls = (controls and #controls) or 0
    local controlPoints = nil
    if numControls > 0 then
        controlPoints = ffi.new("Vec2[?]", numControls)
        for i = 1, numControls do
            controlPoints[i-1].x = controls[i].x
            controlPoints[i-1].y = controls[i].y
        end
    end
    return DuckerLib.DuckerNative_AddLine(
        vec2(startPos.x, startPos.y),
        vec2(endPos.x, endPos.y),
        vec4(color.x, color.y, color.z, color.w),
        width or 1.0,
        mode or Ducker.LineMode.Straight,
        controlPoints,
        numControls,
        zIndex or 0
    )
end

function Ducker.DrawText(fontId, text, position, color, zIndex, rotation, origin)
    DuckerLib.DuckerNative_DrawText(
        fontId,
        text,
        vec2(position.x, position.y),
        vec4(color.x, color.y, color.z, color.w),
        zIndex or 0,
        rotation or 0.0,
        origin and vec2(origin.x, origin.y) or vec2(0.0, 0.0)
    )
end

Ducker.SetObjectVisible = DuckerLib.DuckerNative_SetObjectVisible
Ducker.SetObjectZIndex = DuckerLib.DuckerNative_SetObjectZIndex
Ducker.SetObjectElevation = DuckerLib.DuckerNative_SetObjectElevation
Ducker.SetObjectShader = DuckerLib.DuckerNative_SetObjectShader
Ducker.SetObjectCornerRadius = DuckerLib.DuckerNative_SetObjectCornerRadius
Ducker.SetObjectRotation = DuckerLib.DuckerNative_SetObjectRotation
Ducker.SetObjectRadius = DuckerLib.DuckerNative_SetObjectRadius
Ducker.SetObjectBlur = DuckerLib.DuckerNative_SetObjectBlur
Ducker.SetObjectInset = DuckerLib.DuckerNative_SetObjectInset

function Ducker.SetObjectBounds(objectId, bounds)
    DuckerLib.DuckerNative_SetObjectBounds(objectId, rect(bounds.x, bounds.y, bounds.w, bounds.h))
end

function Ducker.SetObjectColor(objectId, color)
    DuckerLib.DuckerNative_SetObjectColor(objectId, vec4(color.x, color.y, color.z, color.w))
end

function Ducker.SetObjectTexture(objectId, textureId, uvRect)
    uvRect = uvRect or {x=0, y=0, w=1, h=1}
    DuckerLib.DuckerNative_SetObjectTexture(objectId, textureId, rect(uvRect.x, uvRect.y, uvRect.w, uvRect.h))
end

function Ducker.SetObjectShapeSize(objectId, shapeSize)
    DuckerLib.DuckerNative_SetObjectShapeSize(objectId, vec2(shapeSize.x, shapeSize.y))
end

function Ducker.SetObjectShadowColor(objectId, color)
    DuckerLib.DuckerNative_SetObjectShadowColor(objectId, vec4(color.x, color.y, color.z, color.w))
end

function Ducker.SetObjectRotationOrigin(objectId, origin)
    DuckerLib.DuckerNative_SetObjectRotationOrigin(objectId, vec2(origin.x, origin.y))
end

function Ducker.SetObjectRotationAndOrigin(objectId, rotation, origin)
    DuckerLib.DuckerNative_SetObjectRotationAndOrigin(objectId, rotation, vec2(origin.x, origin.y))
end

function Ducker.SetObjectUniform(objectId, name, uniformType, value)
    local cdata
    if uniformType == Ducker.UniformType.Float then
        cdata = ffi.new("float[1]", value)
    elseif uniformType == Ducker.UniformType.Vec2 then
        cdata = vec2(value.x, value.y)
    elseif uniformType == Ducker.UniformType.Vec3 then
        cdata = vec3(value.x, value.y, value.z)
    elseif uniformType == Ducker.UniformType.Vec4 then
        cdata = vec4(value.x, value.y, value.z, value.w)
    elseif uniformType == Ducker.UniformType.Int then
        cdata = ffi.new("int[1]", value)
    else
        error("Invalid uniform type")
    end
    DuckerLib.DuckerNative_SetObjectUniform(objectId, name, uniformType, cdata)
end

function Ducker.SetObjectBorder(objectId, borderWidth, borderColor)
    DuckerLib.DuckerNative_SetObjectBorder(objectId, borderWidth, vec4(borderColor.x, borderColor.y, borderColor.z, borderColor.w))
end

function Ducker.DefineShadowPreset(elevation, layers)
    local numLayers = #layers
    if numLayers == 0 then
        DuckerLib.DuckerNative_DefineShadowPreset(elevation, nil, 0)
        return
    end
    
    local cLayers = ffi.new("ShadowLayer[?]", numLayers)
    for i = 1, numLayers do
        cLayers[i-1].opacity = layers[i].opacity
        cLayers[i-1].yOffset = layers[i].yOffset
        cLayers[i-1].blurRadius = layers[i].blurRadius
        cLayers[i-1].spread = layers[i].spread
    end
    DuckerLib.DuckerNative_DefineShadowPreset(elevation, cLayers, numLayers)
end

function Ducker.GetTextSize(fontId, text)
    local sizeVec = DuckerLib.DuckerNative_GetTextSize(fontId, text)
    return {x = sizeVec.x, y = sizeVec.y}
end

function Ducker.LoadTexture(filepath)
    local width = ffi.new("int[1]")
    local height = ffi.new("int[1]")
    local textureId = DuckerLib.DuckerNative_LoadTexture(filepath, width, height)
    if textureId == 0 then
        return nil, "Failed to load texture"
    end
    return textureId, width[0], height[0]
end

function Ducker.BeginContainer(bounds)
    DuckerLib.DuckerNative_BeginContainer(rect(bounds.x, bounds.y, bounds.w, bounds.h))
end

return Ducker