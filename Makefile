# Makefile for Barrel Bash


GNATMAKE = gnatmake
GNATCLEAN = gnatclean


TARGET = barrel_bash


SRC = barrel_bash.adb


all: $(TARGET)


$(TARGET): $(SRC)
	$(GNATMAKE) $(SRC)


run: $(TARGET)
	./$(TARGET)


clean:
	$(GNATCLEAN) $(TARGET)
	rm -f *.o *.ali


distclean: clean
	rm -f $(TARGET)


rebuild: distclean all

.PHONY: all run clean distclean rebuild
