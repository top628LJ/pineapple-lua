---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Administrator.
--- DateTime: 2021/2/6 21:55
---

local parser = require "parser"
local table_insert = table.insert

local _M = {}
local variable_map = {}

local function resolve_assignment(statement)
    local variable_name = statement.variable_name;
    if variable_name == nil or variable_name == "\"\"" then
        error("resolve_assignment failed: variable_name is empty")
    end
    variable_map[variable_name] = statement.value
end

local function resolve_print(statement)
    local variable_name = statement.variable_name;
    if variable_name == nil or variable_name == "\"\"" then
        error("resolve_print failed: variable_name is empty")
    end
    if variable_map[variable_name] == nil then
        error("resolve_print failed: " .. variable_name .. " has not defined")
    end
    print(variable_map[variable_name])
end

local function resolve_statement(statement)
    if statement.type == "print" then
        resolve_print(statement)
    elseif statement.type == "assignment" then
        resolve_assignment(statement)
    else
        error("resolve_statement failed: unknown statement")
    end

end

local function resolve_AST(statements)
    for i = 1, #statements do
        resolve_statement(statements[i])
    end
end

function _M.execute(codes)

    local source_code = {}
    for c in string.gmatch(codes, ".", "jo") do
        table_insert(source_code, c)
    end

    local statements = parser.parse(source_code)
    resolve_AST(statements)
end

return _M