---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Administrator.
--- DateTime: 2021/2/6 20:13
---

local table_remove = table.remove
local table_concat = table.concat

local TOKEN_TYPE = require "token_type"
local KEYWORDS_MAP = {
    ["print"] = TOKEN_TYPE.PRINT
}

local _M = {
}
local mt = { __index = _M }

local function is_letter(var)
    return (var >= 'a' and var <= 'z') or (var >= 'A' and var <= 'Z')
end

local function is_number(var)
    return var >= "0" and var <= "9"
end

local function is_newline(var)
    return var == "\r" or var == "\n"
end

local function is_white_space(var)
    return var == "\t" or var == "\n" or var == "\v" or var == "\f" or var == "\r" or var == " ";
end

local function skip_source_code(self, num)
    while num > 0 do
        table_remove(self.source_code, 1)
        num = num - 1
    end
end
_M.skip_source_code = skip_source_code

local function scan_name(self)
    local st, ed = 1, -1
    for i = 1, #self.source_code do
        local var = self.source_code[i]
        if (is_letter(var) or var == "_" or is_number(var)) == false then
            ed = i - 1
            break
        end
    end
    if ed <= 0 then
        error("scan_name failed, name is empty")
    end
    return table_concat(self.source_code, "", st, ed)
end
_M.scan_name = scan_name

local function scan_before_token(self)
    local st, ed = 1, -1
    for i = 1, #self.source_code do
        if self.source_code[i] == "\"" then
            ed = i - 1
            break
        end
    end
    if ed <= 0 then
        error("scan_before_token failed, name is empty")
    end
    local str = table_concat(self.source_code, "", st, ed)
    self:skip_source_code(ed - st + 1)
    return str
end
_M.scan_before_token = scan_before_token

local function is_ignored(self)
    local ignored = false
    while #self.source_code > 0 do
        local var = self.source_code[1];
        if #self.source_code > 1 and ((var == "\r" and self.source_code[2] == "\n") or
                (var == "\n" and self.source_code[2] == "\r")) then
            self.line_num = self.line_num + 1
            skip_source_code(self, 2)
            ignored = true
        elseif is_newline(var) then
            self.line_num = self.line_num + 1
            skip_source_code(self, 1)
            ignored = true
        elseif is_white_space(var) then
            skip_source_code(self, 1)
            ignored = true
        else
            break
        end
    end
    return ignored
end
_M.is_ignored = is_ignored

local function match_token(self)
    local var = self.source_code[1];

    -- match ignored token
    if is_ignored(self) then
        return self.line_num, TOKEN_TYPE.EOF, "EOF"
    end

    -- it is end of source_code
    if #self.source_code <= 0 then
        return self.line_num, TOKEN_TYPE.EOF, "EOF"
    end

    -- match single token
    if var == "$" then
        self:skip_source_code(1)
        return self.line_num, TOKEN_TYPE.VAR_PREFIX, var
    elseif var == "(" then
        self:skip_source_code(1)
        return self.line_num, TOKEN_TYPE.LEFT_PAREN, var
    elseif var == ")" then
        self:skip_source_code(1)
        return self.line_num, TOKEN_TYPE.RIGHT_PAREN, var
    elseif var == "=" then
        self:skip_source_code(1)
        return self.line_num, TOKEN_TYPE.EQUAL, var
    elseif var == "\"" then
        if self.source_code[2] == "\"" then
            self:skip_source_code(2)
            return self.line_num, TOKEN_TYPE.DOU_QUOTE, "\"\""
        else
            self:skip_source_code(1)
            return self.line_num, TOKEN_TYPE.QUOTE, "\""
        end
    end

    -- match multi token
    if var == "_" or is_letter(var) then
        local name = self:scan_name()
        self:skip_source_code(#name)
        if KEYWORDS_MAP[name] ~= nil then
            return self.line_num, KEYWORDS_MAP[name], name
        end
        return self.line_num, TOKEN_TYPE.NAME, name
    end
    error("match_token failed: unexpected symbol " .. var)
end
_M.match_token = match_token

local function get_next_token(self)
    if self.next_token_line_num > 0 then
        local next_token = self.next_token
        local next_token_type = self.next_token_type
        local next_token_line_num = self.next_token_line_num
        self.line_num = self.next_token_line_num
        self.next_token = ""
        self.next_token_type = 0
        self.next_token_line_num = 0
        return next_token_line_num, next_token_type, next_token
    end
    return match_token(self)
end
_M.get_next_token = get_next_token

local function next_token_is(self, token_type)
    local next_token_line_num, next_token_type, next_token = get_next_token(self)
    if next_token_type ~= token_type then
        error("next_token_is failed: expected token: {%s} but got {%s}.", token_type, next_token_type)
    end
    return next_token_line_num, next_token
end
_M.next_token_is = next_token_is

local function look_ahead(self)
    if self.next_token_line_num > 0 then
        return self.next_token_type
    end
    local line_num = self.line_num
    local next_token_line_num, next_token_type, next_token = get_next_token(self)
    self.line_num = line_num
    self.next_token_line_num = next_token_line_num
    self.next_token_type = next_token_type
    self.next_token = next_token
    return next_token_type
end
_M.look_ahead = look_ahead


local function look_ahead_and_skip(self, token_type)
    local line_num = self.line_num
    local next_token_line_num, next_token_type, next_token = get_next_token(self)
    if next_token_type ~= token_type then
        self.line_num = line_num
        self.next_token_line_num = next_token_line_num
        self.next_token_type = next_token_type
        self.next_token = next_token
    end
end
_M.look_ahead_and_skip = look_ahead_and_skip

function _M.new(source_code)
    source_code = source_code or {}
    local t = {
        source_code = source_code,
        line_num = 1,
        next_token = "",
        next_token_type = 0,
        next_token_line_num = 0
    }
    return setmetatable(t, mt)
end

return _M