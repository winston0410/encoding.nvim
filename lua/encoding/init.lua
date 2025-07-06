local M = {}

function M.setup()
	_G.encoding = {
		base64_encode_or_decode_operator = M.base64_encode_or_decode_operator,
		uri_encode_or_decode_operator = M.uri_encode_or_decode_operator,
	}
end

---@param mode "visual" | nil
local function select_area_for_operator(mode)
	local start_pos, end_pos

	if mode == "visual" then
		start_pos = vim.fn.getpos(".")
		end_pos = vim.fn.getpos("v")
	else
		start_pos = vim.fn.getpos("'[")
		end_pos = vim.fn.getpos("']")
	end

	local start_row = start_pos[2]
	local start_col = start_pos[3]
	local end_row = end_pos[2]
	local end_col = end_pos[3]

	if end_row > start_row then
		return start_row, start_col, end_row, end_col
	end

	if start_row > end_row then
		return end_row, end_col, start_row, start_col
	end

	if end_col > start_col then
		return start_row, start_col, end_row, end_col
	end
	return end_row, end_col, start_row, start_col
end

---@param str string
local function is_base64_encode(str)
	if #str % 4 ~= 0 then
		return false
	end
	if not str:match("^[A-Za-z0-9+/]+={0,2}$") then
		return false
	end

	return true
end

---@param str string
local function is_uri_encode(str)
	if str:find("%%[0-9A-Fa-f][0-9A-Fa-f]") then
		return true
	end
	return false
end

function M.uri_encode_or_decode()
	local mode = vim.api.nvim_get_mode().mode
	if mode == "v" or mode == "V" or mode == "\22" then
		M.uri_decode_operator("visual")
		return vim.api.nvim_input("<Esc>")
	end
	vim.o.opfunc = "v:lua.encoding.uri_encode_or_decode_operator"
	return vim.api.nvim_input("g@")
end

function M.base64_encode_or_decode()
	local mode = vim.api.nvim_get_mode().mode
	-- \22 represents CTRL-V in ASCII
	if mode == "v" or mode == "V" or mode == "\22" then
		M.base64_encode_operator("visual")
		return vim.api.nvim_input("<Esc>")
	end
	vim.o.opfunc = "v:lua.encoding.base64_encode_or_decode_operator"

	return vim.api.nvim_input("g@")
end

---@param mode "visual"|nil
function M.base64_encode_or_decode_operator(mode)
	local start_row, start_col, end_row, end_col = select_area_for_operator(mode)

	local lines = vim.api.nvim_buf_get_text(0, start_row - 1, start_col - 1, end_row - 1, end_col, {})

	local text = table.concat(lines, "\n")

	---@type string
	local result

	if is_base64_encode(text) then
		result = vim.base64.decode(text)
	else
		result = vim.base64.encode(text)
	end

	vim.api.nvim_buf_set_text(0, start_row - 1, start_col - 1, end_row - 1, end_col, { result })
end

---@param mode "visual"|nil
function M.uri_encode_or_decode_operator(mode)
	local start_row, start_col, end_row, end_col = select_area_for_operator(mode)

	local lines = vim.api.nvim_buf_get_text(0, start_row - 1, start_col - 1, end_row - 1, end_col, {})

	local text = table.concat(lines, "\n")

	---@type string
	local result

	if is_uri_encode(text) then
		result = vim.uri_decode(text)
	else
		result = vim.uri_encode(text)
	end

	vim.api.nvim_buf_set_text(0, start_row - 1, start_col - 1, end_row - 1, end_col, { result })
end

return M
