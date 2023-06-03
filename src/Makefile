CFLAGS+=-Wall

OBJS=uart.c sendat.c

all = sendat

$(all):
	$(CC) $(CFLAGS) -o sendat $(OBJS)

.PHONY:clean
clean:
	rm -rf *.o *.*~ *~ *.swap $(all)


