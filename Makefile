
SUBDIRS := assets src

.PHONY: all $(SUBDIRS) clean

all: $(SUBDIRS)
	cp dist/*.nex ../NEXT-SYNC-ROOT/home/audiotest

$(SUBDIRS):
	$(MAKE) -C $@

clean:
	for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir clean; \
	done