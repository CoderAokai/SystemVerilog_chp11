all:  compile  simulate

compile:
	vcs              \
	-sverilog        \
	-debug_all       \
	-l complile.log  \
	+v2k             \
	-f rtl.lst

simulate:
	./simv  -l  simulate.log

clean:
	rm  -rf  DVEfiles  *.log  csrc  simv*  ucli.key  *.vpd 
