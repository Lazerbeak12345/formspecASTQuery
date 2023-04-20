local Qmt = {}
local function constructor(self)
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
		return i - 1, self:_resolve_path(value)
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
function Qmt:getAllChildrenAtIndex(index)
	local paths = {}
	for path_index, elm in self:_rawForEach() do
		local path = self._paths[path_index]
		if elm[index] then
			paths[#paths+1] = add_to_path(path, index)
		end
	end
	return constructor{ _raw = self._raw, _paths = paths }
end
function Qmt:__index(key)
	if type(key) == "number" then
		return self:getAllChildrenAtIndex(key)
	end
	return Qmt[key] or self:_resolve_path(self._paths[1])[key]
end
function Qmt:__newindex(key, value)
	if #self._paths == 1 then
		-- Edge case not needed but a bit faster
		self:_resolve_path(self._paths[1])[key] = value
	else
		for _, elm in self:_rawForEach() do
			elm[key] = value
		end
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
function Qmt:allChildren()
	local paths = {}
	for path_index, elm  in self:_rawForEach() do
		for index, _ in ipairs(elm) do
			paths[#paths+1] = add_to_path(self._paths[path_index], index)
		end
	end
	return constructor{
		_raw = self._raw,
		_paths = paths
	}
end
function Qmt:includeFrom(other)
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
-- TODO add a way to get number of _paths in public api
function Qmt:findFirst(needle)
	if type(needle) == "table" then
		needle = convert_query_to_needle(needle)
	end
	for index, _ in self:_rawForEach() do
		local test_elm = constructor{ _raw = self._raw, _paths = { self._paths[index] } }
		if needle(test_elm) then
			return test_elm
		end
	end
	local recurse_result = self:allChildren():findFirst(needle)
	if #recurse_result._paths > 0 then
		return recurse_result
	end
	return constructor{ _raw = self._raw, _paths = {} }
end
function Qmt:findAll(needle)
	if type(needle) == "table" then
		needle = convert_query_to_needle(needle)
	end
	local paths = {}
	for index, _ in self:_rawForEach() do
		local path = self._paths[index]
		local elm = constructor{
			_raw = self._raw,
			_paths = { path }
		}
		if needle(elm) then
			paths[#paths+1] = path
		end
		local children = elm:allChildren()
		if #children._paths > 0 then
			local recurse_result = children:findAll(needle)
			for _, new_path in ipairs(recurse_result._paths) do
				paths[#paths+1] = new_path
			end
		end
	end
	return constructor{ _raw = self._raw, _paths = paths }
end
