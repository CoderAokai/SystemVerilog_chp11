`ifndef CPU_IFC__SV
`define CPU_IFC__SV 


`include "definitions.sv"


interface cpu_ifc;
    logic        BusMode, Sel, Rd_DS, Wr_RW, Rdy_Dtack;
    logic [11:0] Addr;
    CellCfgType  DataIn, DataOut;

    modport Peripheral (
        input  BusMode, Sel, Rd_DS, Wr_RW, Addr, DataIn,
        output DataOut, Rdy_Dtack
        );

    modport Test(
        output  BusMode, Sel, Rd_DS, Wr_RW, Addr, DataIn, 
        input DataOut, Rdy_Dtack
        );

endinterface

typedef virtual cpu_ifc      vCPU;
typedef virtual cpu_ifc.Test vCPU_T;


`endif // CPU_IFC__SV