

`include "definitions.sv"

`include "environment.sv"


program automatic test
    //#(parameter int NumRx = 4, parameter int NumTx = 4)
    (
    Utopia.TopReceive   Rx[0:NumRx-1],
    Utopia.TopTransmit  Tx[0:NumTx-1],
    cpu_ifc.Test        mif,
    input logic         rst
    );

    // initial begin
    //     $display("Simulation was run with conditional compilation settings of:");
    //     $display("`define TxPorts %0d", `TxPorts);
    //     $display("`define RxPorts %0d", `RxPorts);
    //     `ifdef FWDALL
    //         $display("`define FWDALL");
    //     `endif
    //     `ifdef SYNTHESIS
    //         $display("`define SYNTHESIS");
    //     `endif
    //     $display("");
    // end
    
    Environment env;

    initial begin
        env = new(Rx, Tx, NumRx, NumTx, mif);
        env.gen_cfg();
        env.build();
        env.run();
        env.wrap_up();
    end //*/

endprogram  // test 