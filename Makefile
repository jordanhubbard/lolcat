.PHONY: all clean run test

all: 
	@echo Make sure racket is installed and in your path, then use
	@echo "make run <args>"

run:
	racket lolcat.scm $(ARGS)

test:
	racket lolcat.scm -p 3.0 -F 0.1 example.txt

help:
	racket lolcat.scm --help

clean:
	rm -f *~ *.bak
