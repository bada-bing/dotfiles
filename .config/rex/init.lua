-- Migrated from ~/.config/tmux/tmux.conf (prefix ctrl+t) and ~/.config/ghostty/config.

-- Pass the prefix through to programs that use it themselves.
rex.bind("ctrl+t>ctrl+t", "pane.send_key", { key = "ctrl+t" })

-- tmux: window management
rex.bind("ctrl+t>shift+\\", "pane.split", { direction = "right" })
rex.bind("ctrl+t>-", "pane.split", { direction = "down" })

rex.bind("ctrl+t>shift+left", "pane.resize", { amount = 4, direction = "left" })
rex.bind("ctrl+t>shift+right", "pane.resize", { amount = 4, direction = "right" })
rex.bind("ctrl+t>shift+down", "pane.resize", { amount = 4, direction = "down" })
rex.bind("ctrl+t>shift+up", "pane.resize", { amount = 4, direction = "up" })

rex.bind("ctrl+t>c", "client.tab.new")
rex.bind("ctrl+t>b", "pane.move_to_new_tab")

rex.bind("ctrl+left", "client.tab.previous")
rex.bind("ctrl+right", "client.tab.next")

rex.bind("ctrl+t>'", "session.switch")

-- Claude Code reads Esc+Enter as a newline; terminals send Shift+Enter as a plain Enter
rex.bind("shift+enter", "com.superlogical.terminal.write", { data = "\27\r" })
