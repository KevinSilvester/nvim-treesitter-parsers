vim.opt.rtp:append("./nvim-treesitter")
local uv = vim.loop

-----------------
-- fs function --
-----------------
local function read_file(path, offset)
	offset = offset == nil and 0 or offset

	local fd = assert(uv.fs_open(path, "r", 438))
	local stat = assert(uv.fs_fstat(fd))
	local data = assert(uv.fs_read(fd, stat.size, offset))
	assert(uv.fs_close(fd))

	if type(data) == "string" then
		return data
	else
		return nil
	end
end

local function write_file(path, txt, flag, offset)
	local data = type(txt) == "string" and txt or vim.inspect(txt)
	uv.fs_open(path, flag, 438, function(open_err, fd)
		assert(not open_err, open_err)
		uv.fs_write(fd, data, offset, function(write_err)
			assert(not write_err, write_err)
			uv.fs_close(fd, function(close_err)
				assert(not close_err, close_err)
			end)
		end)
	end)
end

local function tbl_sort(tbl)
	table.sort(tbl, function(a, b)
		return a < b
	end)
	return tbl
end

------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------

local lockfile = vim.json.decode(read_file("./nvim-treesitter/lockfile.json"))
local current_parsers = vim.json.decode(read_file("./parsers.min.json"))
local new_parsers = {}
local changes = {
	added = {},
	removed = {},
	updated = {},
}

-- set parsers table
for lang, parser_info in pairs(require("nvim-treesitter.parsers").list) do
	new_parsers[lang] = {
		url = parser_info.install_info.url,
		files = parser_info.install_info.files,
		location = parser_info.install_info.location or vim.NIL,
		generate_from_grammar = parser_info.install_info.requires_generate_from_grammar or false,
		revision = lockfile[lang].revision,
	}
end

local new_langs = tbl_sort(vim.tbl_keys(new_parsers))
local current_langs = tbl_sort(vim.tbl_keys(current_parsers))

-- check for changes
changes.added = vim.tbl_filter(function(lang)
	return current_parsers[lang] == nil
end, new_langs)

changes.removed = vim.tbl_filter(function(lang)
	return new_parsers[lang] == nil
end, current_langs)

for _, lang in ipairs(new_langs) do
	if current_parsers[lang] == nil then
		goto continue
	end

	if new_parsers[lang].revision ~= current_parsers[lang].revision then
		table.insert(changes.updated, lang)
	end

	::continue::
end

if not (#changes.added > 0 or #changes.removed > 0 or #changes.updated > 0) then
	print("No changes to parsers")
	return
end

print("Changed detected")
write_file("./changes.json", vim.json.encode(changes), "w")

local data = vim.json.encode(new_parsers)
write_file("./parsers.min.json", data, "w")
