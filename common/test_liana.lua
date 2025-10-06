local ffi = require("ffi")

ffi.cdef[[
    typedef void* (*GetProcAddress)(const char* procname);
    typedef uint32_t object_id;

    void setupGL(GetProcAddress loader_func);
    void init();
    void setViewport(int32_t width, int32_t height);
    void render(int32_t width, int32_t height);
    
    object_id add_rect(
        float x, float y, float z, 
        float width, float height, 
        float r, float g, float b, float a,
        float r_tl, float r_tr, float r_br, float r_bl
    );
    
    void set_texture(
        object_id id,
        uint32_t texture_id,
        float uv_ox, float uv_oy,
        float uv_sx, float uv_sy,
        float uv_rot
    );

    uint32_t load_texture(const char* filepath);
]]

local ok, liana_lib = pcall(ffi.load, "Liana")
if not ok then
    error("FATAL: Could not load 'liana.dll'\nDetails: " .. tostring(liana_lib), 0)
end

local LianaGL = {}

LianaGL.setup = liana_lib.setupGL
LianaGL.init = liana_lib.init
LianaGL.setViewport = liana_lib.setViewport
LianaGL.render = liana_lib.render
LianaGL.load_texture = liana_lib.load_texture

function LianaGL.add_rect(x, y, z, w, h, color, radii)
    color = color or {r=1, g=1, b=1, a=1}
    radii = radii or {}
    return liana_lib.add_rect(
        x, y, z, w, h,
        color.r, color.g, color.b, color.a,
        radii.tl or 0.0, radii.tr or 0.0,
        radii.br or 0.0, radii.bl or 0.0
    )
end

function LianaGL.set_texture(object_id, texture_id, opts)
    opts = opts or {}
    local offset = opts.offset or {x=0, y=0}
    local scale = opts.scale or {x=1, y=1}
    liana_lib.set_texture(
        object_id,
        texture_id,
        offset.x, offset.y,
        scale.x, scale.y,
        opts.rotation or 0.0
    )
end

return LianaGL