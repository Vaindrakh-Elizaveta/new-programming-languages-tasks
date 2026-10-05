-- Usage: lua main.lua <input-file>
-- A word is a maximal sequence of non-whitespace characters.
-- The character count includes spaces, punctuation and line-ending characters.
-- UTF-8 code points are counted, not bytes. Lua 5.3 or newer is required.

local path = arg[1] or "input.txt"
local file, open_error = io.open(path, "rb")

if not file then
    io.stderr:write("Cannot open file: " .. tostring(open_error) .. "\n")
    os.exit(1)
end

local content = file:read("*a")
file:close()

local line_count = 0
if #content > 0 then
    local _, newline_count = content:gsub("\n", "")
    line_count = newline_count
    if content:sub(-1) ~= "\n" then
        line_count = line_count + 1
    end
end

local word_count = 0
for _ in content:gmatch("%S+") do
    word_count = word_count + 1
end

local character_count, invalid_position = utf8.len(content)
if not character_count then
    io.stderr:write("The file is not valid UTF-8 near byte " .. invalid_position .. ".\n")
    os.exit(1)
end

print("Lines: " .. line_count)
print("Words: " .. word_count)
print("Characters: " .. character_count)
