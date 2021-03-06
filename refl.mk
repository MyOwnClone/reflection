OPENMP = #-fopenmp
TARGETS = librefl.so librefl++.so userefl userefl++
COMPILEFLAGS = -Wall $(OPENMP) -g -O2 -fPIC
CXXPPFLAGS = -DUSE_EXPECT $(CXXINCLUDES)
CXXFLAGS = -std=c++0x $(COMPILEFLAGS) $(CXXPPFLAGS)
CFLAGS = -std=c99 -pedantic $(COMPILEFLAGS)
LDFLAGS = $(OPENMP)

all: $(TARGETS)

userefl: LD = $(CC)
userefl: userefl.o librefl.so cosi.o

userefl++: LD = $(CXX)
userefl++: userefl++.o librefl++.so

refl-method.o: CFLAGS += $(shell pkg-config --cflags libffi)

librefl.a: refl.o refl-error.o refl-module.o refl-type.o refl-obj.o	\
	refl-method.o refl-die.o

librefl.so: LDFLAGS += -shared -ldw $(shell pkg-config --libs libffi) \
	-Wl,--whole-archive,librefl.a,--no-whole-archive
librefl.so: LD = $(CC)
librefl.so: librefl.a

librefl++.so: LDFLAGS += -shared -ldw $(shell pkg-config --libs libffi)
librefl++.so: LD = $(CXX)
librefl++.so: refl++.o librefl.a

%.o: %.cc %.d
	$(CXX) $(CXXFLAGS) -c $< -o $@

%.o: %.c %.d
	$(CC) $(CFLAGS) -c $< -o $@

include $(wildcard *.d)

%.d: %.cc
	$(CXX) $(CXXFLAGS) -MM -MT '$(<F:%.cc=%.o) $@' $< > $@

%.d: %.c
	$(CC) $(CFLAGS) -MM -MT '$(<F:%.c=%.o) $@' $< > $@

test-%: %.o %.cc test.o
	$(CXX) $(CXXFLAGS) $(LDFLAGS) -DSELFTEST $(@:test-%=%.cc) $(filter-out $<,$(filter %.o,$^)) -o $@
	./$@ || (rm -f $@; exit 1)

%:
	$(LD) $(LDFLAGS) $^ -o $@

%.a:
	$(AR) cru $@ $^

clean:
	rm -f *.o *.d *.a $(TARGETS)

distclean: clean
	rm -f Makefile

.PHONY: all clean dist distclean
.PRECIOUS: %.d

Makefile:;
