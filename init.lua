local Qmt = {}
-- TODO global table, indexed by raw tables, containing paths in the table. Used for things like wrap and etc.
local function constructor(self)
	assert(type(self._raw) == "table", "Input must be a table")
	assert(type(self._paths) == "table", "Paths must be a list")
	setmetatable(self, Qmt)
	return self
end
local function Q(input)
	-- _paths is A list of paths, where a path is either true (to represent the root) or a list of numbers/keys
	-- (representing the path from the root to the node)
	return constructor{ _raw = input, _paths = { true } }
end
fASTQuery = Q
function Qmt:_resolve_path(path)
	-- Truthy isn't enough, it _must_ be true
	if path == true then
		return self._raw
	end
	assert(path, "Path must not be nil")
	local node = self._raw
	for _, value in ipairs(path) do
		node = node[value]
	end
	return node
end
function Qmt:_rawForEach()
	local paths = self._paths
	local i = 1
	return function ()
		local path = paths[i]
		if not path then return end
		i = i + 1
		return path, self:_resolve_path(path)
	end
end
function Qmt:each()
	local paths = self._paths
	local i = 1
	return function ()
		local path = paths[i]
		if not path then return end
		i = i + 1
		return constructor{ _raw = self._raw, _paths = { path } }
	end
end
local function add_to_path(path, index)
	if path == true then
		return { index }
	end
	local new_path = {}
	for i, v in ipairs(path) do
		new_path[i] = v
	end
	new_path[#new_path+1] = index
	return new_path
end
function Qmt:_childrenAt(index)
	local paths = {}
	for path, elm in self:_rawForEach() do
		if elm[index] then
			paths[#paths+1] = add_to_path(path, index)
		end
	end
	return constructor{ _raw = self._raw, _paths = paths }
end
function Qmt:getKey(key)
	assert(key, "key argument not provided")
	local tk = type(key)
	assert(tk == "number" or tk == "string", "key must be string or number")
	return self:_resolve_path(self._paths[1])[key]
end
function Qmt:__index(key)
	if type(key) == "number" then
		return self:_childrenAt(key)
	end
	return Qmt[key] or self:getKey(key)
end
function Qmt:count()
	return #self._paths
end
function Qmt:__len()
	return #self:_resolve_path(self._paths[1])
end
function Qmt:__newindex(key, value)
	for _, elm in self:_rawForEach() do
		elm[key] = value
	end
end
local function recurseNeedle(potential, query)
	for key, value in pairs(query) do
		local potentialv = potential[key]
		if type(potentialv) == "table" and (not recurseNeedle(potentialv, value)) or potentialv ~= value then
			return false
		end
	end
	return true
end
local function convert_query_to_needle(oldneedle)
	return function (potential)
		return recurseNeedle(potential, oldneedle)
	end
end
function Qmt:children()
	local paths = {}
	for path, elm  in self:_rawForEach() do
		for index, _ in ipairs(elm) do
			paths[#paths+1] = add_to_path(path, index)
		end
	end
	return constructor{
		_raw = self._raw,
		_paths = paths
	}
end
function Qmt:include(other)
	assert(self._raw == other._raw, "can only include elements from same tree")
	local paths = {}
	for _, new_path in ipairs(self._paths) do
		paths[#paths+1] = new_path
	end
	for _, new_path in ipairs(other._paths) do
		paths[#paths+1] = new_path
	end
	return constructor{
		_raw = self._raw,
		_paths = paths
	}
end
function Qmt:first(needle)
	if not needle then
		return constructor{ _raw = self._raw, _paths = { self._paths[1] } }
	end
	if type(needle) == "table" then
		needle = convert_query_to_needle(needle)
	end
	for test_elm in self:each() do
		if needle(test_elm) then
			return test_elm
		end
	end
	local children = self:children()
	if children:count() > 0 then
		return children:first(needle)
	end
	return constructor{ _raw = self._raw, _paths = {} }
end
function Qmt:all(needle)
	if type(needle) == "table" then
		needle = convert_query_to_needle(needle)
	end
	local paths = {}
	for path, _ in self:_rawForEach() do
		local elm = constructor{ _raw = self._raw, _paths = { path } }
		if needle(elm) then
			paths[#paths+1] = path
		end
		local children = elm:children()
		if children:count() > 0 then
			local recurse_result = children:all(needle)
			for _, new_path in ipairs(recurse_result._paths) do
				paths[#paths+1] = new_path
			end
		end
	end
	return constructor{ _raw = self._raw, _paths = paths }
end
