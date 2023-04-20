dofile('init.lua')
local Q = fASTQuery
describe("wrapper", function ()
	it("wraps and references make unwrapping not needed", function ()
		local dom = { type = "box", color = "#FFFFFF" }
		Q(dom).color = "#000000"
		assert.same(dom, {
			type = "box",
			color = "#000000"
		}, "color was changed")
	end)
	it("works with multiple nodes too!", function ()
		local dom = {
			type = "container",
			{ type = "box", color = "#FFFFFF" },
			{ type = "label", label = "asdf" },
			{ type = "box", color = "#aFFFFF" },
		}
		Q(dom)
			:findAll{ type = "box" }
			.color = "#000000"
		assert.same(dom, {
			type = "container",
			{ type = "box", color = "#000000" },
			{ type = "label", label = "asdf" },
			{ type = "box", color = "#000000" },
		}, "modified only the colors")
	end)
	it("supports getting children, and children are also wrapped", function ()
		local dom = {
			type = "container",
			{ type = "box", color = "#FFFFFF" }
		}
		local wrapped_child = Q(dom)[1]
		assert.truthy(wrapped_child, "child found")
		assert.equal(wrapped_child.type, dom[1].type, "child type is the same")
		assert.equal(wrapped_child.color, dom[1].color, "child color is the same")
		assert.equal(#wrapped_child, #dom[1], "child length is the same")
		assert.truthy(wrapped_child.findAll, "child is wrapped")
		wrapped_child.color = "#000000"
		assert.equal(wrapped_child.color, dom[1].color, "child color is still the same")
		assert.same(dom, {
			type = "container",
			{ type = "box", color = "#000000" }
		}, "child was modified")
	end)
end)
describe("findAll", function ()
	it("can search by table", function ()
		local dom = {
			type = "container",
			{ type = "box", color = "#FFFFFF" },
			{ type = "box", color = "#aFFFFF" }
		}
		Q(dom):findAll({ type = "box" }).color = "#000000"
		assert.same(dom, {
			type = "container",
			{ type = "box", color = "#000000" },
			{ type = "box", color = "#000000" }
		})
	end)
end)
