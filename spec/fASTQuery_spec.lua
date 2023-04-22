dofile('init.lua')
local Q, describe, it = fASTQuery, describe, it
describe("wrapper", function ()
	it("wraps and references make unwrapping not needed", function ()
		local dom = { type = "box", color = "#FFFFFF" }
		Q(dom).color = "#000000"
		assert.same(dom, { type = "box", color = "#000000" }, "color was changed")
	end)
	it("works with multiple nodes too!", function ()
		local dom = {
			type = "container",
			{ type = "box", color = "#FFFFFF" },
			{ type = "label", label = "asdf" },
			{ type = "box", color = "#aFFFFF" }
		}
		Q(dom):all{ type = "box" }.color = "#000000"
		assert.same(dom, {
			type = "container",
			{ type = "box", color = "#000000" },
			{ type = "label", label = "asdf" },
			{ type = "box", color = "#000000" }
		}, "modified only the colors")
	end)
	it("supports getting children, and children are also wrapped", function ()
		local dom = { type = "container", { type = "box", color = "#FFFFFF" } }
		local wrapped_child = Q(dom)[1]
		assert.truthy(wrapped_child, "child found")
		assert.equal(wrapped_child.type, dom[1].type, "child type is the same")
		assert.equal(wrapped_child.color, dom[1].color, "child color is the same")
		assert.equal(#wrapped_child, #dom[1], "child length is the same")
		assert.truthy(wrapped_child.all, "child is wrapped")
		wrapped_child.color = "#000000"
		assert.equal(wrapped_child.color, dom[1].color, "child color is still the same")
		assert.same(dom, { type = "container", { type = "box", color = "#000000" } }, "child was modified")
	end)
	-- TODO it supports counting children using the length operator
end)
describe("all", function ()
	it("can search by table", function ()
		local dom = { type = "container", { type = "box", color = "#FFFFFF" }, { type = "box", color = "#aFFFFF" } }
		Q(dom):all{ type = "box" }.color = "#000000"
		assert.same(dom, { type = "container", { type = "box", color = "#000000" }, { type = "box", color = "#000000" } })
	end)
end)
describe("first", function ()
	it("only finds one element", function ()
		local dom = { type = "container", { type = "box", color = "#FFFFFF" }, { type = "box", color = "#aFFFFF" } }
		Q(dom):first{ type = "box" }.color = "#000000"
		assert.same(dom, { type = "container", { type = "box", color = "#000000" }, { type = "box", color = "#aFFFFF" } })
	end)
end)
describe("children", function ()
	it("finds all children of all selected elements", function ()
		local dom = {
			type = "container",
			{ type = "container", findMe = "pls", { type = "box", color = "#FFFFFF" }, { type = "box", color = "#aFFFFF" } },
			{ type = "box", color = "#bFFFFF" },
			{ type = "container", findMe = "pls", { type = "box", color = "#cFFFFF" }, { type = "box", color = "#dFFFFF" } }
		}
		Q(dom):all{ findMe = "pls" }:children().color = "#000000"
		assert.same(dom, {
			type = "container",
			{ type = "container", findMe = "pls", { type = "box", color = "#000000" }, { type = "box", color = "#000000" } },
			{ type = "box", color = "#bFFFFF" },
			{ type = "container", findMe = "pls", { type = "box", color = "#000000" }, { type = "box", color = "#000000" } }
		})
	end)
end)
describe("include", function ()
	it("adds elements found in a different search into this search", function ()
		local dom = {
			type = "container",
			{ type = "box", color = "#FFFFFF" },
			{ type = "box", color = "#cFFFFF" },
			{ type = "container", { type = "box", color = "#aFFFFF" }, { type = "box", color = "#bFFFFF" } }
		}
		local first = Q(dom):first{ type = "box" }
		Q(dom)[3]:all{ type = "box" }:include(first).color = "#000000"
		assert.same(dom, {
			type = "container",
			{ type = "box", color = "#000000" },
			{ type = "box", color = "#cFFFFF" },
			{ type = "container", { type = "box", color = "#000000" }, { type = "box", color = "#000000" } }
		})
	end)
end)
-- TODO inconsistant with jQuery rename to something else
describe("get", function ()
	it("gets a key, regardless of if that key is shadowed by this api", function ()
		local dom = { type = "box", get = 3 }
		assert.equal(Q(dom):get("get"), 3)
	end)
end)
describe("count", function ()
	it("counts the number of matches made", function ()
		local dom = {
			type = "container",
			{ type = "box", color = "#FFFFFF" },
			{ type = "label", label = "hi"},
			{ type = "box", color = "#FFFFFF" },
			{ type = "box", color = "#FFFFFF" }
		}
		local container = Q(dom)
		assert.equal(container:all{ type = "box" }:count(), 3, "there are three matches")
		assert.equal(container:first{ type = "box" }:count(), 1, "first found only just the one")
	end)
end)
