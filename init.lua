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
		return i - 1, self:_resolve_path(value)
	end
end
function Qmt:__index(key)
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
		if type(potentialv) == "table" then
			if not recurseNeedle(potentialv, value) then
				return false
			end
		elseif potentialv ~= value then
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
function Qmt:findAll(needle)
	if type(needle) == "table" then
		needle = convert_query_to_needle(needle)
	end
	local paths = {}
	local function recurse(path, tree)
		for index, elm in ipairs(tree) do
			local new_path = {}
			if path ~= true then
				for i, v in ipairs(path) do
					new_path[i] = v
				end
			end
			new_path[#new_path+1] = index
			if needle(elm) then
				paths[#paths+1] = new_path
			end
			recurse(new_path, elm)
		end
	end
	for index, elm in self:_rawForEach() do
		local path = self._paths[index]
		if needle(elm) then
			paths[#paths+1] = path
		end
		recurse(path, elm)
	end
	return constructor{
		_raw = self._raw,
		_paths = paths
	}
end
