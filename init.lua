local function path_is__(a, b)
	-- 1 is gt, 0 is same, -1 is lt
	if a == b then return 0 end
	-- true is the shortest possible path
	if a == true then return -1 end
	if b == true then return 1 end
	-- This means that [] < [1] < [2] < [1,1] < [2,1], but it's consistant and fast, so I'm keeping it for now.
	if #a > #b then return 1 end
	if #b > #a then return -1 end
	for i, av in ipairs(a) do
		if av > b[i] then return 1 end
		if av < b[i] then return -1 end
	end
	return 0
end
-- global table, indexed by raw tables, containing paths in the table. Used for things like wrap and etc.
local global_paths_by_table = {}
local function binary_search_global_paths(global_paths, needle, low, high)
	if not low then
		low = 1
	end
	if not high then
		high = #global_paths
	end
	if high >= low then
		local mid = math.floor((high + low) / 2)
		local mid_item = global_paths[mid]
		local rel = path_is__(needle, mid_item)
		if rel == 0 then -- eq
			return mid
		elseif rel == 1 then -- gt
			return binary_search_global_paths(global_paths, needle, mid + 1, high)
		else -- lt
			return binary_search_global_paths(global_paths, needle, high, mid - 1)
		end
	end
	return nil, low, high -- not found. Return nearest two
end
local function ensure_paths_in_global_paths(raw, paths)
	if not global_paths_by_table[raw] then
		global_paths_by_table[raw] = {}
	end
	local global_paths = global_paths_by_table[raw]
	for passed_path_index, path in ipairs(paths) do
		local index, new_index = binary_search_global_paths(global_paths, path)
		if not index and new_index then -- not found
			table.insert(global_paths, new_index, path)
		elseif global_paths[index] ~= path then
			-- if the paths are the same, but not same table reference, ensure linking by changing that
			paths[passed_path_index] = global_paths[index]
		end
	end
end
local function replace_last_node_in_path(path, new_index)
	if path ~= true then
		local new_path = {}
		for i, v in ipairs(path) do
			new_path[i] = v
		end
		new_path[#new_path] = new_index
		return new_path
	else
		return { new_index }
	end
end
local Qmt = {}
local function constructor(self)
	assert(type(self._raw) == "table", "Input must be a table")
	assert(type(self._paths) == "table", "Paths must be a list")
	ensure_paths_in_global_paths(self._raw, self._paths)
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
local function remove_from_path(path)
	local new_path = {}
	for i, v in ipairs(path) do
		if i ~= #path then
			new_path[i] = v
		end
	end
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
	local tn = type(needle)
	if tn == "table" then
		needle = convert_query_to_needle(needle)
	elseif tn == "nil" then
		needle = function ()
			return true
		end
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
function Qmt:parents()
	local paths = {}
	local unique = {}
	for path, _ in self:_rawForEach() do
		local new_path = remove_from_path(path)
		local raw_elm = self:_resolve_path(new_path)
		-- Tables are always a reference. Indexing by table reference is like indexing by number.
		if not unique[raw_elm] then
			paths[#paths+1] = new_path
			unique[raw_elm] = true
		end
	end
	return constructor{ _raw = self._raw, _paths = paths }
end
function Qmt:append(child)
	local paths = {}
	for path, elm in self:_rawForEach() do
		local new_index = #elm+1
		elm[new_index] = child
		paths[#paths+1] = replace_last_node_in_path(path, new_index)
	end
	ensure_paths_in_global_paths(self._raw, paths)
end
function Qmt:insert(index, value)
	if not value then return self:append(index) end -- Index is the value in this case
	local global_paths = global_paths_by_table[self._raw]
	for parent_path, elm in self:_rawForEach() do
		table.insert(elm, index, value)
		local new_path = add_to_path(parent_path, index)
		local found_gindex, new_gindex = binary_search_global_paths(global_paths, new_path)
		-- found_gindex will be nil if not found. even if it's found, it needs increased.
		local starting_gindex = found_gindex or new_gindex or -1
		assert(starting_gindex ~= -1, "impossible binary search failure")
		for gindex=starting_gindex,#global_paths do
			-- If the path is
			-- - A sibling after the new item
			-- - A child of a sibling of the new item
			-- Siblings (and children of siblings) share the same first path parts as their common ansestor
			local gpath = global_paths[gindex]
			local match = true
			for i, v in ipairs(parent_path) do
				if gpath[i] ~= v then
					match = false
				end
			end
			if match then
				gpath[#parent_path] = gpath[#parent_path] + 1
			end
		end
		-- This is a new path -- we know it can'tve been present already, since this is a new node.
		table.insert(global_paths, starting_gindex, new_path)
	end
end
