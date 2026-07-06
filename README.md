# nvim-kanban

[![CI](https://github.com/iliailmer/nvim-kanban/actions/workflows/ci.yml/badge.svg)](https://github.com/iliailmer/nvim-kanban/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A per-project kanban board for Neovim, backed by a `.tasklist` file
(tab-separated: id, status, title, description, date). Each card has a short
title (shown on the board) and a full, multi-line description you open by
entering the card.

## Install (lazy.nvim)

```lua
{
  "iliailmer/nvim-kanban",
  cmd = "Kanban",
  config = function()
    require("kanban").setup()
  end,
}
```

## Usage

Run `:Kanban` from within a project. The plugin searches upward from the current
buffer's directory for a `.tasklist` file (like git finds `.git`); if none
exists, it offers to create one in Neovim's current working directory (`:pwd`),
not the buffer's directory.

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
make test
```
