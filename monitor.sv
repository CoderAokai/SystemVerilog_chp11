
`ifndef MONITOR__SV
`define MONITOR__SV


`include "atm_cell.sv"
`include "Utopia.sv"


typedef class Monitor;


class Monitor_cbs;
    virtual task post_rx(
        input Monitor  mon,
        input NNI_cell celln
        );
    endtask
endclass : Monitor_cbs 



class Monitor;
    vUtopiaTx   Tx;
    Monitor_cbs cbsq[$];
    bit[1:0]    PortID;

    extern function new(input vUtopiaTx Tx, input int PortID);
    extern task run();
    extern task receive(output NNI_cell celln);
endclass : Monitor


// 
function Monitor::new(input vUtopiaTx Tx, input int PortID);
    this.Tx     = Tx;
    this.PortID = PortID;
endfunction : new


//
task Monitor::run();
    NNI_cell c;
    forever begin
        receive(c);
        foreach(cbsq[i])
            cbsq[i].post_rx(this, c);
    end // forever
endtask : run


//
task Monitor::receive(output NNI_cell celln);
    ATMCellType Pkt;

    Tx.cbt.clav <= 1;
    while(Tx.cbt.soc !== 1'b1 && Tx.cbt.en !== 1'b0)  @(Tx.cbt);
    for(int i=0; i<52; i++) begin
        //
        while(Tx.cbt.en !== 1'b0)  @(Tx.cbt);
        Pkt.Mem[i] = Tx.cbt.data;
        @(Tx.cbt);
    end 

    Tx.cbt.clav <= 0;

    celln = new();
    celln.unpack(Pkt);
    celln.display($sformatf("@%0t: Mon%0d: ", $time, PortID));

endtask : receive





`endif // MONITOR__SV