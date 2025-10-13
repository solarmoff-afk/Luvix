local ffi = require("ffi")
local liana_ffi = ffi.load("liana")

ffi.cdef[[
    typedef struct LianaState LianaState;
    typedef uint64_t FontId;

    LianaState* liana_init(void* get_proc_address); 
    void liana_shutdown(LianaState* state_ptr);

    void liana_set_viewport(LianaState* state_ptr, float width, float height);
    void liana_render_frame(LianaState* state_ptr, float r, float g, float b, float a);

    uint32_t liana_new_rect(LianaState* state_ptr);
    uint32_t liana_new_text(LianaState* state_ptr);

    void liana_config_position(LianaState* state_ptr, uint32_t id, float x, float y);
    void liana_config_size(LianaState* state_ptr, uint32_t id, float width, float height);
    void liana_config_rotation(LianaState* state_ptr, uint32_t id, float angle_degrees);
    void liana_config_color(LianaState* state_ptr, uint32_t id, float r, float g, float b, float a);
    void liana_config_z_index(LianaState* state_ptr, uint32_t id, float z);
    void liana_config_text(LianaState* state_ptr, uint32_t id, const char* text_ptr);

    void liana_delete_object(LianaState* state_ptr, uint32_t id);
    void liana_clear_all(LianaState* state_ptr);

    uint32_t liana_compile_shader(LianaState* state_ptr, const char* vs_src_ptr, const char* fs_src_ptr);
    void liana_set_object_shader(LianaState* state_ptr, uint32_t object_id, uint32_t shader_id);

    FontId liana_load_font(LianaState* state_ptr, const char* path, float size);
    void liana_clear_font(LianaState* state_ptr, FontId font_id);
    void liana_config_font(LianaState* state_ptr, uint32_t object_id, FontId font_id);

    void liana_set_uniform_int(LianaState* state_ptr, uint32_t id, const char* name, int val);
    void liana_set_uniform_float(LianaState* state_ptr, uint32_t id, const char* name, float val);
    void liana_set_uniform_vec2(LianaState* state_ptr, uint32_t id, const char* name, float x, float y);
    void liana_set_uniform_vec3(LianaState* state_ptr, uint32_t id, const char* name, float x, float y, float z);
    void liana_set_uniform_vec4(LianaState* state_ptr, uint32_t id, const char* name, float x, float y, float z, float w);
    void liana_set_uniform_mat4(LianaState* state_ptr, uint32_t id, const char* name, const float* mat_ptr);
    void liana_set_uniform_bool(LianaState* state_ptr, uint32_t id, const char* name, bool val);

    void liana_set_rounded(LianaState* state_ptr, uint32_t object_id, float tl, float tr, float br, float bl);
]]

local state_ptr = nil
local M = {}

function M.setup(get_proc_address)
    if state_ptr then 
        return
    end

    state_ptr = liana_ffi.liana_init(get_proc_address)
    
    if state_ptr == nil then
        error("Failed to initialize Liana.")
    end
end

function M.new_rect(params)
    if not state_ptr then error("Liana is not initialized. Call setup() first.") end

    local id = liana_ffi.liana_new_rect(state_ptr)
    if id == 0 then
        return nil
    end
    
    if params.x and params.y then M.config_position(id, params.x, params.y) end
    if params.w and params.h then M.config_size(id, params.w, params.h) end
    if params.color then
        local c = params.color
        M.config_color(id, c.r or 1, c.g or 1, c.b or 1, c.a or 1)
    end
    if params.z then M.config_z_index(id, params.z) end
    if params.rotation then M.config_rotation(id, params.rotation) end

    return id
end

function M.new_text(params)
    if not state_ptr then error("Liana is not initialized. Call setup() first.") end

    local id = liana_ffi.liana_new_text(state_ptr)
    if id == 0 then
        return nil
    end
    
    if params.x and params.y then M.config_position(id, params.x, params.y) end
    if params.w and params.h then M.config_size(id, params.w, params.h) end
    if params.color then
        local c = params.color
        M.config_color(id, c.r or 1, c.g or 1, c.b or 1, c.a or 1)
    end
    if params.z then M.config_z_index(id, params.z) end
    if params.font then M.config_font(id, params.font) end
    if params.text then M.config_text(id, params.text) end

    return id
end

function M.config_position(id, x, y)
    if state_ptr then liana_ffi.liana_config_position(state_ptr, id, x, y) end
end

function M.config_size(id, width, height)
    if state_ptr then liana_ffi.liana_config_size(state_ptr, id, width, height) end
end

function M.config_rotation(id, angle)
    if state_ptr then liana_ffi.liana_config_rotation(state_ptr, id, angle) end
end

function M.config_color(id, r, g, b, a)
    if state_ptr then liana_ffi.liana_config_color(state_ptr, id, r or 1, g or 1, b or 1, a or 1) end
end

function M.config_z_index(id, z)
    if state_ptr then liana_ffi.liana_config_z_index(state_ptr, id, z) end
end

function M.config_text(id, text)
    if state_ptr then liana_ffi.liana_config_text(state_ptr, id, text) end
end

function M.delete_object(id)
    if state_ptr then liana_ffi.liana_delete_object(state_ptr, id) end
end

function M.clear_all()
    if state_ptr then liana_ffi.liana_clear_all(state_ptr) end
end

function M.compile_shader(vs_src, fs_src)
    if not state_ptr then error("Liana is not initialized. Call setup() first.") end
    local shader_id = liana_ffi.liana_compile_shader(state_ptr, vs_src, fs_src)
    return shader_id > 0 and shader_id or nil
end

function M.set_object_shader(object_id, shader_id)
    if state_ptr then liana_ffi.liana_set_object_shader(state_ptr, object_id, shader_id) end
end

function M.liana_load_font(path, size)
    if not state_ptr then error("Liana is not initialized. Call setup() first.") end
    local font_id = liana_ffi.liana_load_font(state_ptr, path, size)
    return font_id > 0 and font_id or nil
end

function M.liana_clear_font(font_id)
    if state_ptr and font_id then liana_ffi.liana_clear_font(state_ptr, font_id) end
end

function M.config_font(object_id, font_id)
    if state_ptr and font_id then liana_ffi.liana_config_font(state_ptr, object_id, font_id) end
end

function M.set_uniform_int(id, name, val)
    if state_ptr then liana_ffi.liana_set_uniform_int(state_ptr, id, name, val) end
end

function M.set_uniform_float(id, name, val)
    if state_ptr then liana_ffi.liana_set_uniform_float(state_ptr, id, name, val) end
end

function M.set_uniform_vec2(id, name, x, y)
    if state_ptr then liana_ffi.liana_set_uniform_vec2(state_ptr, id, name, x, y) end
end

function M.set_uniform_vec3(id, name, x, y, z)
    if state_ptr then liana_ffi.liana_set_uniform_vec3(state_ptr, id, name, x, y, z) end
end

function M.set_uniform_vec4(id, name, x, y, z, w)
    if state_ptr then liana_ffi.liana_set_uniform_vec4(state_ptr, id, name, x, y, z, w) end
end

function M.set_uniform_mat4(id, name, mat_ptr)
    if state_ptr then liana_ffi.liana_set_uniform_mat4(state_ptr, id, name, mat_ptr) end
end

function M.set_uniform_bool(id, name, val)
    if state_ptr then liana_ffi.liana_set_uniform_bool(state_ptr, id, name, val) end
end

function M.set_rounded(object_id, tl, tr, br, bl)
    if state_ptr then
        liana_ffi.liana_set_rounded(state_ptr, object_id, tl or 0, tr or 0, br or 0, bl or 0)
    end
end

function M.render(r, g, b, a)
    if not state_ptr then return end
    liana_ffi.liana_render_frame(state_ptr, r, g, b, a)
end

function M.set_viewport(width, height)
    if state_ptr then
        liana_ffi.liana_set_viewport(state_ptr, width, height)
    end
end

function M.shutdown()
    if state_ptr then
        liana_ffi.liana_shutdown(state_ptr)
        state_ptr = nil
    end
end

return M