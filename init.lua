local formspec_ast = formspec_ast
local Qmt = {}
local function constructor(self)
	setmetatable(self, Qmt)
	return self
end
local function Q(input)
	return constructor{
		_raw = input,
		-- A list of paths, where a path is either true (to represent the root) or a list of numbers/keys (representing the
		-- path from the root to the node)
		_paths = {
			true
		}
	}
end
fASTQuery = Q
function Qmt:_resolve_path(path)
	-- Truthy isn't enough, it _must_ be true
	if path == true then
		return self._raw
	end
	assert(path, "Path must not be null")
	local node = self._raw
	for _, value in ipairs(path) do
		node = node[value]
	end
	return node
end
function Qmt:_rawForEach()
	local p = self._paths
	local i = 1
	return function ()
		local value = p[i]
		if not value then return end
		i = i + 1
		return i, self:_resolve_path(value)
	end
end
function Qmt:__index(key)
	return Qmt[key] or self:_resolve_path(self._paths[1])[key]
end
function Qmt:__newindex(key, value)
	if #self._paths then
		-- Edge case not needed but a bit faster
		self:_resolve_path(self._paths[1])[key] = value
	else
		for _, elm in self:_rawForEach() do
			elm[key] = value
		end
	end
end
