`ifndef GENERATOR__SV
`define GENERATOR__SV

`include "atm_cell.sv"


class UNI_generator;
    UNI_cell blueprint;
    mailbox gen2drv;
    event   drv2gen;
    int     nCells;
    int     PortID;

    function new(
        input mailbox gen2drv,
        input event   drv2gen,
        input int     nCells, PortID
        );
        this.gen2drv = gen2drv;
        this.drv2gen = drv2gen;
        this.nCells  = nCells;
        this.PortID  = PortID;
        blueprint    = new();
    endfunction : new


    task run();
        UNI_cell cellu;
        repeat(nCells) begin
            assert(blueprint.randomize());
            $cast(cellu, blueprint.copy());
            cellu.display($psprintf("@%0t: Gen %0d : ", $time, PortID));
            gen2drv.put(cellu);
            @drv2gen;
        end
    endtask : run

endclass : UNI_generator


`endif // GENERATOR__SV
