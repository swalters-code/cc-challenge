local pretty = require("cc.pretty")
local reader = peripheral.wrap("block_reader_1")
local data = reader.getBlockData()
textutils.pagedPrint(pretty.render(pretty.pretty(data),51))

