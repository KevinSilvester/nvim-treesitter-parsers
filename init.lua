vim.opt.rtp:append("./nvim-treesitter")
local uv = vim.loop

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

local raw_parsers = require("nvim-treesitter.parsers").list

-- read the json lockfile and store into a table
local lockfile = vim.json.decode(read_file("./nvim-treesitter/lockfile.json"))

local parsers = {}

for lang, parser_info in pairs(raw_parsers) do
   local parser = {
      language = lang,
      url = parser_info.install_info.url,
      files = parser_info.install_info.files,
      location = parser_info.install_info.location,
      revision = lockfile[lang].revision,
   }

   if not parser.location then
      parser.location = vim.NIL
   end
   table.insert(parsers, parser)
end

local data = vim.json.encode(parsers)

write_file("./parsers.min.json", data, "w")
