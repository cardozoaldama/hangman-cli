# Hangman CLI

An interactive command-line Hangman game built with Ruby 3.4.13. Secret words are selected from the bundled [`words.txt`](words.txt) word list, and game sessions can be saved to and resumed from disk.

## Features

- Random 5-to-12-letter secret word selection from [`words.txt`](words.txt)
- Progressive ASCII gallows display with 6 allowed wrong guesses
- Interactive main menu to start a new game or resume a saved game
- Save and load support using human-readable JSON files in `saves/`
- Built with the Ruby standard library (zero runtime gem dependencies)

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

- `1` (or `new`): Start a new Hangman game with a random word
- `2` (or `load`): List saved games and resume one by number or slot name
- `3` (or `quit`): Exit the program

### In-Game Commands

- Enter a single letter (`a`–`z`) to guess a letter
- Enter `save` to save your current progress to a named slot
- Enter `quit` (or `exit`) to return to the main menu

## Saved Games

Saved sessions are written as JSON files under `saves/<slot_name>.json`. Slot names allow letters, digits, hyphens, and underscores. The `saves/` directory is ignored by Git.

## Development

Run RuboCop and YARD documentation checks:

```bash
bundle exec rubocop
bundle exec yard stats --list-undoc --no-save --fail-on-warning
bundle exec yard doc
```

## License

This project is licensed under the **GNU General Public License v3.0 (GPLv3)**. See the [`LICENSE`](LICENSE) file for the full license text.
