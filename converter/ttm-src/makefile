EXECS=ttm ttmsplit ps2gif ps2png latex2gif
INSTALLDIR=/usr/local/bin

all : ttm ttmsplit

% : %.c
	cc -o $* $*.c

install : $(EXECS)
	for file in $(EXECS); do cp $$file $(INSTALLDIR) ; done	

clean : 
	rm ttmsplit
	rm ttm

uninstall : .
	for file in $(EXECS); do rm $(INSTALLDIR)/$$file ; done
