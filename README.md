# Scheme lolcat

A Scheme (Racket) implementation of the popular lolcat utility, which displays text with rainbow colors in the terminal.

![](https://github.com/busyloop/lolcat/raw/master/ass/nom.jpg)

## Screenshot

![](https://github.com/busyloop/lolcat/raw/master/ass/screenshot.png)

## Requirements

- Racket 8.0 or higher

## Installation

```bash
# Clone the repository
git clone https://github.com/your-username/lolcat.git
cd lolcat

# Run directly with Racket
racket lolcat.scm [options] [file...]

# Or use the provided Makefile
make run ARGS="[options] [file...]"
```

## Usage

```bash
racket lolcat.scm [options] [file...]
```

### Options

- `-p, --spread <f>`     Rainbow spread (default: 3.0)
- `-F, --freq <f>`       Rainbow frequency (default: 0.1)
- `-S, --seed <i>`       Rainbow seed, 0 = random (default: 0)
- `-a, --animate`        Enable psychedelics
- `-d, --duration <i>`   Animation duration (default: 12)
- `-s, --speed <f>`      Animation speed (default: 20.0)
- `-i, --invert`         Invert fg and bg
- `-f, --force`          Force color even when stdout is not a tty

### Examples

```bash
# Display a file with rainbow colors
racket lolcat.scm file.txt

# Display a file with animation
racket lolcat.scm -a file.txt

# Pipe content to lolcat
cat file.txt | racket lolcat.scm

# Custom rainbow settings
racket lolcat.scm -p 3.0 -F 0.1 -S 42 file.txt
```
