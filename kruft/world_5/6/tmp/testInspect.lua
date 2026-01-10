local ok, data = turtle.inspectDown()
print(textutils.serialize(data.state.level))
