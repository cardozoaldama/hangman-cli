# Hangman CLI

An interactive command-line Hangman game built with Ruby 3.4.13. Secret words are selected from the bundled [`words.txt`](words.txt) word list, difficulty presets are configured via YAML, and game sessions can be saved to and resumed from JSON or YAML files.

## Features

- **Three difficulty tiers** defined in [`config/difficulties.yml`](config/difficulties.yml):
  - **Easy**: 5–7 letter words, 8 wrong attempts, 2 hints
  - **Normal**: 5–10 letter words, 6 wrong attempts, 1 hint
  - **Hard**: 9–15 letter words, 4 wrong attempts, 0 hints
- **Interactive board**: progressive ASCII gallows scaled to difficulty, 2-row A–Z letter tracker, and automatic ANSI color highlights in TTY terminals (respects `NO_COLOR`)
- **Flexible guessing & hints**: guess single letters (`a`–`z`), try full-word guesses, or use `hint` and `help` commands
- **Session flow**: play-again prompt after each round and live win/loss/streak scoreboard
- **Dual-format persistence**: save, list, load, and delete games in **JSON (`.json`)** or **YAML (`.yml`)** under `saves/`
- **Zero runtime gem dependencies**: built purely with the Ruby standard library

## Requirements & Setup

- Ruby `3.4.13` (pinned via `.ruby-version` for `rbenv`)
- Bundler (optional, for development linting and documentation tools)

```bash
rbenv local 3.4.13
bundle install
```

## Usage

Start the interactive CLI from the repository root:

```bash
./bin/hangman
```

Or invoke it directly with Ruby:

```bash
ruby bin/hangman
```

### Main Menu

- `1` (or `new`): Choose a difficulty (`Easy`, `Normal`, `Hard`) and start a new game
- `2` (or `load`): List saved games (`.json` and `.yml`) and resume one by number or slot name
- `3` (or `delete`): Delete a saved game slot with confirmation
- `4` (or `quit`): Exit the program

### In-Game Commands

- Enter a single letter (`a`–`z`) to guess a letter
- Enter a full word (`2+` letters) to guess the secret word directly (costs 1 attempt if wrong)
- Enter `hint` to reveal an unguessed letter (when hints remain)
- Enter `save` to save your current progress to a named `.json` or `.yml` slot
- Enter `help` to show the command summary
- Enter `quit` (or `exit`) to return to the main menu

## Saved Games

Saved sessions are written as JSON (`saves/<slot_name>.json`) or YAML (`saves/<slot_name>.yml`) files. Slot names allow letters, digits, hyphens, and underscores. The `saves/` directory is ignored by Git.

## Development

Run RuboCop and YARD documentation checks:

```bash
bundle exec rubocop
bundle exec yard stats --list-undoc --no-save --fail-on-warning
bundle exec yard doc
```

## License

This project is licensed under the **GNU General Public License v3.0 (GPLv3)**. See the [`LICENSE`](LICENSE) file for the full license text.
