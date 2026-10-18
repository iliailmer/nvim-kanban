# nvim-kanban

[![CI](https://github.com/iliailmer/nvim-kanban/actions/workflows/ci.yml/badge.svg)](https://github.com/iliailmer/nvim-kanban/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A per-project kanban board for Neovim, backed by
[`tsk`](https://github.com/iliailmer/taskboard). Each card has a short title
(shown on the board) and a full, multi-line description you open by entering
the card.

The plugin reads and changes tasks only through the `tsk` command, so the board
and the command line always agree, and `tsk`'s file locking and corrupt-file
checks apply to every change.

## Requirements

- Neovim 0.10 or newer
- `tsk` 0.3.0 or newer: `cargo install taskboard`, or a binary from the
  [releases page](https://github.com/iliailmer/taskboard/releases)

## Install (lazy.nvim)

```lua
{
  "iliailmer/nvim-kanban",
  cmd = "Kanban",
  config = function()
    -- tsk = "/path/to/tsk" if tsk is not on your PATH
    require("kanban").setup()
  end,
}
```

## Usage

Run `:Kanban` from within a project. The plugin uses the same tasklist as
`tsk`: the nearest `.tasklist` in the current buffer's directory or above it,
stopping at the git repository root. If none exists, it offers to create one
at the repository root, or in Neovim's current working directory (`:pwd`)
outside a repository.

Keymaps inside the board:

| Key              | Action                                       |
| ---------------- | -------------------------------------------- |
| `j`/`k` / arrows | Move focus between cards in a column         |
| `h`/`l`          | Move focus between columns                   |
| `H`/`L`          | Move the focused card to the adjacent column |
| `n`              | Add a new card (prompts for a title)         |
| `r`              | Rename the focused card's title              |
| `<CR>`           | Open the focused card's detail view          |
| `d`              | Delete the focused card (confirms first)     |
| `q` / `Esc`      | Close the board                              |

Inside a card's detail view (opened with `<CR>`):

| Key         | Action                                           |
| ----------- | ------------------------------------------------ |
| `r`         | Rename the title                                 |
| `e`         | Edit the description in a full multi-line editor |
| `q` / `Esc` | Close the detail view and return to the board    |

The description editor is a real scratch buffer — edit it like any other Neovim
buffer, then `<C-s>` to save and return, or `q`/`Esc` to discard changes.

## Testing

```bash
make test                          # uses tsk on PATH
TSK_BIN=/path/to/tsk make test     # or a specific build
```
