all : tthsplit choice.exe tthsplit.exe

choice : choice.c
	gcc -o choice choice.c

choice.exe : choice.c
	mingw -o choice.exe choice.c

tthsplit : tthsplit.c
	gcc -o tthsplit tthsplit.c

tthsplit.exe : tthsplit.c
	mingw -o tthsplit.exe tthsplit.c

clean : 
	rm -f tthsplit tthsplit.exe choice.exe choice
