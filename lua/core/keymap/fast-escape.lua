local api, o, bo, b = vim.api, vim.o, vim.bo, vim.b
local hrtime, keycode = vim.uv.hrtime, vim.keycode
local mapset = vim.fn.mapset
local getcmdpos, getcmdtype = vim.fn.getcmdpos, vim.fn.getcmdtype
local NS = api.nvim_create_namespace("fast_escape")

--- @class FastEscapeOpts
--- @field sequence? string Hai phím ASCII có thể in được. Mặc định `"jk"`.

local MODES = {
	i = {
		rollback = "<BS>",
		exit = "<Esc>",
		clean = "<Cmd>setlocal nomodified<CR>",
		pos = function(n)
			local win = api.nvim_get_current_win()
			local buf = api.nvim_win_get_buf(win)
			local cur = api.nvim_win_get_cursor(win)

			-- Dự đoán vị trí và changedtick sau khi chèn một ký tự ASCII.
			return {
				win,
				buf,
				cur[1],
				cur[2] + n,
				api.nvim_buf_get_changedtick(buf) + n,
			}
		end,
	},
	c = {
		rollback = "<BS>",
		finish = "<C-c>",
		pos = function(n)
			return {
				api.nvim_get_current_win(),
				api.nvim_get_current_buf(),
				getcmdtype(),
				getcmdpos() + n,
			}
		end,
	},
	t = {
		rollback = "<BS>",
		exit = [[<C-\><C-n>]],
		pos = function() return { api.nvim_get_current_win(), api.nvim_get_current_buf() } end,
	},
}

-- Escape các ký tự đặc biệt khi đăng ký LHS.
local KEY_NAMES = {
	[" "] = "<Space>",
	["<"] = "<lt>",
	["\\"] = "<Bslash>",
}

local first, second
local installed, originals, saved = {}, {}, {}
local pending

-- So sánh snapshot để xác nhận ngữ cảnh chỉnh sửa chưa thay đổi.
local function same_pos(a, b)
	if #a ~= #b then return false end

	for i = 1, #a do
		if a[i] ~= b[i] then return false end
	end

	return true
end

-- Chèn phím vào đầu typeahead.
-- remap=true: tiếp tục phân giải mapping.
-- remap=false: giữ nguyên kết quả đã qua mapping.
local function queue(keys, remap)
	if keys and keys ~= "" then api.nvim_feedkeys(keys, remap and "mi" or "ni", false) end
end

-- Hủy timer đang chờ và giải phóng handle.
local function stop_timer(state)
	local timer = state.timer
	state.timer = nil

	if timer then pcall(function()
		if not timer:is_closing() then
			timer:stop()
			timer:close()
		end
	end) end
end

-- Tạo chuỗi thao tác hoàn thành hoặc rollback.
local function action(state, complete)
	local cfg = MODES[state.mode]

	-- Command-line dùng Ctrl-C để hủy toàn bộ command line.
	if complete and cfg.finish then return cfg.finish end

	-- Hoàn thành: Backspace + thoát mode.
	-- Thất bại: chỉ Backspace rồi gọi mapping gốc.
	return cfg.rollback .. (complete and (cfg.exit or "") or "") .. (state.clean and (cfg.clean or "") or "")
end

-- Kiểm tra mode, buffer, window và vị trí hiện tại.
local function valid(state)
	if api.nvim_get_mode().mode:sub(1, 1) ~= state.mode then return false end

	local ok, pos = pcall(MODES[state.mode].pos, 0)
	return ok and same_pos(pos, state.pos)
end

-- Khôi phục mapping gốc rồi xử lý tiếp phím hiện tại.
local function replay(state, next_key, remap)
	if not state.plug or not valid(state) then return false end

	-- 'i' chèn vào đầu typeahead nên enqueue theo thứ tự ngược.
	-- Thứ tự thực thi: rollback -> mapping gốc -> next_key.
	queue(next_key, remap)
	queue(state.plug, true)
	queue(keycode(action(state, false)), false)

	return true
end

-- Bắt đầu theo dõi sau khi phím đầu tiên được nhập ngay lập tức.
local function start(mode, cfg, plug)
	local timeout = o.timeout and o.timeoutlen

	local state = {
		mode = mode,
		plug = plug,
		pos = cfg.pos(1),
		clean = cfg.clean ~= nil and not bo.modified,
		emitting = true,
		deadline = timeout and hrtime() + timeout * 1e6,
	}

	pending = state

	-- Khi hết timeout, khôi phục mapping gốc nếu có.
	if timeout then
		state.timer = vim.defer_fn(function()
			if pending ~= state then return end

			pending = nil

			-- vim.defer_fn tự đóng one-shot timer trước callback.
			state.timer = nil
			replay(state)
		end, timeout)
	end
end

-- Tìm mapping toàn cục, ưu tiên mapping riêng của mode.
local function find_map(maps, mode, lhs)
	local common

	for _, map in ipairs(maps) do
		if map.lhsraw == lhs or map.lhsrawalt == lhs then
			if map.mode == mode then return map end
			if mode ~= "t" and map.mode == "!" then common = map end
		end
	end

	return common
end

-- Lưu tất cả mapping có cùng LHS vì một mapping mới có thể
-- làm thay đổi mode bits của nhiều mapping cùng lúc.
local function remember_maps(maps, lhs)
	for _, map in ipairs(maps) do
		if map.lhsraw == lhs or map.lhsrawalt == lhs then
			local id = map.mode .. "\0" .. (map.lhsraw or map.lhs)

			if not saved[id] then
				saved[id] = true
				originals[#originals + 1] = vim.deepcopy(map)
			end
		end
	end
end

-- Nhân bản mapping gốc sang một Plug riêng cho từng mode.
local function clone_map(mode, lhs, map)
	local copy = vim.deepcopy(map)
	copy.mode = mode
	copy.lhs, copy.lhsraw, copy.lhsrawalt = lhs, keycode(lhs), nil

	mapset(copy)
end

-- Xóa mapping plugin và khôi phục các mapping ban đầu.
local function clear()
	if pending then
		stop_timer(pending)
		pending = nil
	end

	vim.on_key(nil, NS)

	-- Xóa wrapper và Plug trước khi khôi phục mapping gốc.
	for _, m in ipairs(installed) do
		pcall(api.nvim_del_keymap, m.mode, m.key)

		if m.plug then pcall(api.nvim_del_keymap, m.mode, m.plug) end
	end

	-- Khôi phục mapping chung trước.
	-- Sau đó mới khôi phục mapping riêng của từng mode,
	-- tránh việc mapping riêng tiếp tục xóa mode bits của mapping chung.
	for _, map in ipairs(originals) do
		if map.mode == "!" then pcall(mapset, map) end
	end

	for _, map in ipairs(originals) do
		if map.mode ~= "!" then pcall(mapset, map) end
	end

	installed, originals, saved = {}, {}, {}
end

local function install(mode, key, maps)
	local cfg = MODES[mode]
	local lhs = KEY_NAMES[key] or key
	local raw = keycode(lhs)

	-- Lưu toàn bộ mapping bị ảnh hưởng trước khi cài wrapper.
	remember_maps(maps, raw)

	-- Chọn mapping đang có hiệu lực để replay.
	local map = find_map(maps, mode, raw)

	-- Giữ mapping gốc dưới một Plug riêng cho từng mode.
	local plug = map and ("<Plug>(fast-escape-%d-%s-%d)"):format(NS, mode, key:byte())

	if plug then clone_map(mode, plug, map) end

	local plug_key = plug and keycode(plug)

	api.nvim_set_keymap(mode, lhs, "", {
		callback = function()
			local state = pending
			local disabled = b.fast_escape_disabled == true or b.fast_escape_disabled == 1

			if state then
				pending = nil
				stop_timer(state)

				-- Phím thứ hai hoàn thành chuỗi trước deadline.
				if
					not disabled
					and state.mode == mode
					and key == second
					and (not state.deadline or hrtime() < state.deadline)
					and valid(state)
				then
					-- replace_keycodes tự encode kết quả.
					return action(state, true)
				end

				-- Chuỗi không hoàn thành: rollback và xử lý lại phím.
				if replay(state, raw, true) then return "" end
			end

			-- Optimistic input: hiển thị phím đầu tiên ngay lập tức.
			if key == first and not disabled then
				start(mode, cfg, plug_key)
				return lhs
			end

			-- Nếu không bắt đầu chuỗi thì chạy mapping gốc.
			if plug_key then
				queue(plug_key, true)
				return ""
			end

			return lhs
		end,
		expr = true,
		noremap = true,
		replace_keycodes = true,
		silent = map and map.silent == 1 or false,

		-- Phím đầu tiên luôn được xử lý ngay.
		-- Phím thứ hai giữ nguyên nowait của mapping gốc.
		nowait = key == first or (map and map.nowait == 1) or false,
		desc = "Fast escape sequence",
	})

	installed[#installed + 1] = {
		mode = mode,
		key = lhs,
		plug = plug,
	}
end

--- Configure fast escape for Insert, Command-line and Terminal modes.
--- Calling setup() again replaces the previous configuration.
--- @param opts? FastEscapeOpts
local function setup(opts)
	if opts ~= nil and type(opts) ~= "table" then
		return vim.notify("fast_escape: opts must be a table", vim.log.levels.WARN)
	end

	local seq = opts and opts.sequence
	if seq == nil then seq = "jk" end

	if type(seq) ~= "string" or not seq:match("^[ -~][ -~]$") then
		return vim.notify("fast_escape: sequence needs 2 printable ASCII keys", vim.log.levels.WARN)
	end

	clear()
	first, second = seq:sub(1, 1), seq:sub(2, 2)

	-- Theo dõi input sau khi mapping đã được giải quyết.
	vim.on_key(function(key, typed)
		local state = pending
		if not state or typed == "" then return end

		-- Bỏ qua sự kiện của chính ký tự optimistic đầu tiên.
		if state.emitting then
			state.emitting = false
			if typed == first then return end
		end

		-- key đã qua mapping nên replay mà không remap lần nữa.
		pending = nil
		stop_timer(state)

		if replay(state, key, false) then return "" end
	end, NS)

	-- Chụp mapping của tất cả mode trước khi thay đổi bất kỳ mapping nào.
	local maps = {}

	for mode in pairs(MODES) do
		maps[mode] = api.nvim_get_keymap(mode)
	end

	for mode in pairs(MODES) do
		install(mode, first, maps[mode])

		if second ~= first then install(mode, second, maps[mode]) end
	end
end

return { setup = setup }
