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
		assert.truthy(wrapped_child.all, "child is wrapped")
		wrapped_child.color = "#000000"
		assert.equal(wrapped_child.color, dom[1].color, "child color is still the same")
		assert.same(dom, { type = "container", { type = "box", color = "#000000" } }, "child was modified")
	end)
	it("supports getting number of children for first match using #", function ()
		local dom = {
			type = "container",
			{ type = "box", color = "#FFFFFF"},
			{ type = "box", color = "#FFFFFF"},
			{ type = "box", color = "#FFFFFF"}
		}
		assert.equal(#Q(dom), 3)
	end)
end)
describe("navigation", function ()
	describe("all", function ()
		it("can search by table", function ()
			local dom = { type = "container", { type = "box", color = "#FFFFFF" }, { type = "box", color = "#aFFFFF" } }
			Q(dom):all{ type = "box" }.color = "#000000"
			assert.same(dom, { type = "container", { type = "box", color = "#000000" }, { type = "box", color = "#000000" } })
		end)
		it("returns all if no args provided", function ()
			local dom = { type = "container", { type = "box", color = "#FFFFFF" }, { type = "box", color = "#aFFFFF" } }
			Q(dom):all().k = "v"
			assert.same({
				type = "container",
				k = "v",
				{ type = "box", color = "#FFFFFF", k = "v" },
				{ type = "box", color = "#aFFFFF", k = "v" }
			}, dom)
		end)
		it("can accept a function as the key", function ()
			local dom = { type = "container", { type = "box", color = "#FFFFFF" }, { type = "box", color = "#aFFFFF" } }
			Q(dom):all(function (elm)
				return elm.type == "box"
			end).color = "#000000"
			assert.same(dom, { type = "container", { type = "box", color = "#000000" }, { type = "box", color = "#000000" } })
		end)
	end)
	describe("first", function ()
		it("only finds one element", function ()
			local dom = { type = "container", { type = "box", color = "#FFFFFF" }, { type = "box", color = "#aFFFFF" } }
			Q(dom):first{ type = "box" }.color = "#000000"
			assert.same(dom, { type = "container", { type = "box", color = "#000000" }, { type = "box", color = "#aFFFFF" } })
		end)
		it("gives the first element when no args", function ()
			local dom = { type = "container", { type = "box", color = "#FFFFFF" }, { type = "box", color = "#aFFFFF" } }
			-- Remember, all is slow. This is bad. Don't do this, just do :first(pattern). Reduce first, then pattern
			Q(dom):all{ type = "box" }:first().color = "#000000"
			assert.same(dom, { type = "container", { type = "box", color = "#000000" }, { type = "box", color = "#aFFFFF" } })
		end)
		it("provides a way to tell if none were found", function ()
			local dom = { type = "container", { type = "label", label = "lol" } }
			assert.equal(Q(dom):first{ type = "box" }:count(), 0, "none should be found")
		end)
		it("can accept a function", function ()
			local dom = { type = "container", { type = "box", color = "#FFFFFF" }, { type = "box", color = "#aFFFFF" } }
			Q(dom):first(function (elm)
				return elm.type == "box"
			end).color = "#000000"
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
	describe("each", function ()
		it("is an iterator returning wrapped elements", function ()
			local dom = {
				type = "container",
				{ type = "container", findMe = "pls", { type = "box", color = "#FFFFFF" }, { type = "box", color = "#aFFFFF" } },
				{ type = "box", color = "#bFFFFF" },
				{ type = "container", findMe = "pls", { type = "box", color = "#cFFFFF" }, { type = "box", color = "#dFFFFF" } }
			}
			for elm in Q(dom):all{ findMe = "pls" }:children():each() do
				elm.color = "#000000"
				assert.is.truthy(elm.each, "is wrapped")
			end
			assert.same(dom, {
				type = "container",
				{ type = "container", findMe = "pls", { type = "box", color = "#000000" }, { type = "box", color = "#000000" } },
				{ type = "box", color = "#bFFFFF" },
				{ type = "container", findMe = "pls", { type = "box", color = "#000000" }, { type = "box", color = "#000000" } }
			})
		end)
	end)
	describe("parents", function ()
		it("returns the parents of each element", function ()
			local dom = {
				type = "container",
				{ type = "container", { type = "box", color = "#FFFFFF" } },
				{ type = "container", { type = "box", color = "#FFFFFF" } }
			}
			Q(dom):all{ type = "box" }:parents().type = "vbox"
			assert.same(dom, {
				type = "container",
				{ type = "vbox", { type = "box", color = "#FFFFFF" } },
				{ type = "vbox", { type = "box", color = "#FFFFFF" } }
			})
		end)
		it("does not match duplicates", function ()
			local dom = {
				type = "container",
				{ type = "container", { type = "box", color = "#FFFFFF" }, { type = "box", color = "#FFFFFF" } }
			}
			local count = 0
			for _ in Q(dom):all{ type = "box" }:parents():each() do
				count = count + 1
			end
			assert.equal(1, count)
		end)
	end)
	--TODO slice (or something that performs subsets on _path, by a good name)
end)
describe("manipulation", function ()
	describe("getKey", function ()
		it("gets a key, regardless of if that key is shadowed by this api", function ()
			local dom = { type = "box", getKey = 3 }
			assert.equal(Q(dom):getKey("getKey"), 3)
		end)
		it("only returns the first key", function()
			local dom = {
				type = "container",
				{ type = "box", color = "#FFFFFF" },
				{ type = "box", color = "#aFFFFF" }
			}
			assert.equal(Q(dom):children():getKey("color"), "#FFFFFF")
		end)
		it("is an unalias for just getting the key conventionally", function ()
			local dom = { type = "container", { type = "box", color = "#FFFFFF" }, { type = "box", color = "#aFFFFF" } }
			assert.equal(Q(dom):children().color, "#FFFFFF")
		end)
	end)
	describe("append", function ()
		it("inserts a new DOM element at the end", function ()
			local dom = { type = "container", { type = "label", label = "hi" } }
			Q(dom):append{ type = "box", color = "#FFFFFF" }
			assert.same(dom, {
				type = "container",
				{ type = "label", label = "hi" },
				{ type = "box", color = "#FFFFFF" }
			})
		end)
	end)
	-- insert (take the last two [or one] arguments from table.insert)
	describe("insert", function ()
		it("inserts a new DOM element at a given location", function ()
			local dom = {
				type = "container",
				{ type = "label", label = "hi" },
				{ type = "label", label = "hi1" }
			}
			Q(dom):insert(2, { type = "box", color = "#FFFFFF" })
			assert.same(dom, {
				type = "container",
				{ type = "label", label = "hi" },
				{ type = "box", color = "#FFFFFF" },
				{ type = "label", label = "hi1" }
			})
		end)
		it("falls back to append() if no index", function ()
			local dom = { type = "container", { type = "label", label = "hi" } }
			Q(dom):insert{ type = "box", color = "#FFFFFF" }
			assert.same({
				type = "container",
				{ type = "label", label = "hi" },
				{ type = "box", color = "#FFFFFF" }
			}, dom)
		end)
	end)
	-- TODO remove
	-- TODO replaceWith
	-- TODO wrap
	-- TODO unwrap
	-- TODO before
	-- TODO after
end)
