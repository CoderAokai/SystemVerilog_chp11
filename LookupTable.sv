`ifndef LOOKUP_TABLE__SV
`define LOOKUP_TABLE__SV


`include "definitions.sv"


//typedef bit dType;


interface LookupTable;
	parameter int Asize  = 8;
	parameter int Arange = 1<<Asize;
	parameter type dType = bit;

	dType Mem [0:Arange-1];

	//
	function void write(
		input [Asize-1:0] addr,
		input dType       data  
		);
		Mem[addr] = data;
	endfunction : write

	//
	function dType read(
		input bit [Asize-1:0] addr
		);
		return (Mem[addr]);	
	endfunction : read


endinterface


`endif // LOOKUP_TABLE__SV