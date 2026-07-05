# nvim-kanban

A per-project kanban board for Neovim, backed by a `board-rs`-compatible
`.tasklist` file (tab-separated: id, status, description, date).

## Install (lazy.nvim)

```lua
{
  dir = "~/projects/lua/nvim-kanban",
  config = function()
    require("kanban").setup()
  end,
}
```

## Usage

Run `:Kanban` from within a project. The plugin searches upward from the
current buffer's directory for a `.tasklist` file (like git finds `.git`);
if none exists, it offers to create one in Neovim's current working
directory (`:pwd`), not the buffer's directory.

Keymaps inside the board:

| Key | Action |
|-----|--------|
| `j`/`k` / arrows | Move focus between cards in a column |
| `h`/`l` | Move focus between columns |
| `H`/`L` | Move the focused card to the adjacent column |
| `n` | Add a new card |
| `r` | Rename the focused card |
| `d` | Delete the focused card (confirms first) |
| `q` / `Esc` | Close the board |

## Testing

```bash
make test
```
