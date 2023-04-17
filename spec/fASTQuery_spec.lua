dofile('init.lua')
local Q = fASTQuery
describe("wrapper", function ()
	it("wraps and references make unwrapping not needed", function ()
		local dom = { type = "box", color = "#FFFFFF" }
		Q(dom).color = "#000000"
		assert.equals(dom.color, "#000000", "color was changed")
	end)
	it("works with multiple nodes too!", function ()
		local dom = {
			type = "container",
			{ type = "box", color = "#FFFFFF" },
			{ type = "label", label = "asdf" },
			{ type = "box", color = "#aFFFFF" },
		}
		Q(dom)
			:find({ type = "box" })
			.color = "#000000"
		assert.same(dom, {
			type = "container",
			{ type = "box", color = "#000000" },
			{ type = "label", label = "asdf" },
			{ type = "box", color = "#000000" },
		}, "modified only the colors")
	end)
end)
