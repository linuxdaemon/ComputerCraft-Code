local selene = require("selene")
local args = {...}
local file = args[1]
local f = io.open(file)
local body = f:read("*a")
f:close()

print(selene.parse(body, false))
