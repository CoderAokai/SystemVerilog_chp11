`ifndef DRIVER__SV
`define DRIVER__SV

`include "atm_cell.sv"
`include "Utopia.sv"



typedef class Driver;


class Driver_cbs;
    virtual task pre_tx(
        input Driver drv,
        input UNI_cell cellu,
        inout bit drop
        );
    endtask : pre_tx

    virtual task post_tx(
        input Driver drv,
        input UNI_cell cellu
        );
   endtask : post_tx

endclass : Driver_cbs




class Driver;
    mailbox    gen2drv;    //
    event      drv2gen;    //
    vUtopiaRx  Rx;         //
    Driver_cbs cbsq[$];    //
    int        PortID;

    extern function new(
        input mailbox   gen2drv,
        input event     drv2gen,
        input vUtopiaRx Rx,
        input int       PortID
        );
    extern task run();
    extern task send(input UNI_cell cellu);

endclass : Driver



//
function Driver::new(
    input mailbox   gen2drv,
    input event     drv2gen,
    input vUtopiaRx Rx,
    input int PortID
    );

    this.gen2drv = gen2drv;
    this.drv2gen = drv2gen;
    this.Rx      = Rx;
    this.PortID  = PortID;
endfunction : new

//
task Driver::run();
    UNI_cell cellu;
    bit drop = 0;

    // initial
    Rx.cbr.data <= 0;
    Rx.cbr.soc  <= 0;
    Rx.cbr.clav <= 0;

    forever begin
        //
        gen2drv.peek(cellu);
        begin : Tx
            //
            foreach(cbsq[i]) begin
                cbsq[i].pre_tx(this, cellu, drop);
                if(drop) disable Tx;    //
            end
            cellu.display($psprintf("@%0t: Drv %0d : ", $time, PortID));
            send(cellu);

            foreach(cbsq[i]) cbsq[i].post_tx(this, cellu);
        end : Tx

        gen2drv.get(cellu);    //

        ->drv2gen;            // ???????????????????

    end // forever

endtask : run


//
task Driver::send(input UNI_cell cellu);
    ATMCellType Pkt;

    cellu.pack(Pkt);
    $write("Sending cellu: ");
    foreach(Pkt.Mem[i])
        $write("%x", Pkt.Mem[i]);    $display;           // ?????????????????

    @(Rx.cbr);
    Rx.cbr.clav <= 1;
    for(int i=0; i<=52; i++) begin
        //
        while(Rx.cbr.en==1'b1) @(Rx.cbr);
        //
        Rx.cbr.soc  <= (i==0);
        Rx.cbr.data <= Pkt.Mem[i];
        @(Rx.cbr);
    end
    Rx.cbr.soc  <= 'z ;
    Rx.cbr.data <= 8'bx ;
    Rx.cbr.clav <= 0;

endtask : send


`endif // DRIVER__SV