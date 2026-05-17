return {
	"windwp/nvim-autopairs",
	event = "InsertEnter",
	-- blink.cmp's `completion.accept.auto_brackets` handles the
	-- "add () after a function completion" case natively, so we no
	-- longer need the nvim-cmp confirm-done bridge.
	opts = {},
}
