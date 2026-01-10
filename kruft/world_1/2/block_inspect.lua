local pretty = require("cc.pretty")
local idata = { turtle.inspect() }

textutils.pagedPrint(pretty.render(pretty.pretty(idata), 51))

