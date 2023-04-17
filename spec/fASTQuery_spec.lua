dofile('init.lua')
local Q = fASTQuery
describe("wrapper", function ()
	it("wraps and references make unwrapping not needed", function ()
		local dom = { type = "box", color = "#FFFFFF" }
		print(dom)
		Q(dom).color = "#000000"
		assert.equals(dom.color, "#000000", "color was changed")
	end)
end)
