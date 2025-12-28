
SUBDIRS := assets src
#DIST_DIR := dist
DIST_DIR := ../NEXT-SYNC-ROOT/home/audiotest

.PHONY: all $(SUBDIRS) clean dist

all: $(SUBDIRS)

dist: all
	mkdir -p $(DIST_DIR)
	cd build && find . -type f ! -name '*.bin' ! -name '*.map' ! -name '*.lis' | cpio -pdm ../$(DIST_DIR)

$(SUBDIRS):
	$(MAKE) -C $@

clean:
	for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir clean; \
	done
	rm -rf build
	rm -rf $(DIST_DIR)