`ifndef CONFIG__SV
`define CONFIG__SV

`include "definitions.sv"


class Config;
    int       nErrors, nWarnings;
    bit[31:0] numRx, numTx;

    rand bit[31:0] nCells;
    constraint c_nCells_valid 
    { 
        nCells>0; 
    }
    constraint c_nCells_reasonable 
    { 
        nCells<1000; 
    }

    rand bit in_use_Rx[];
    constraint c_in_use_valid 
    { 
        in_use_Rx.sum>0; 
    }

    rand bit[31:0] cells_per_chan[];
    constraint c_sum_ncells_sum
    { 
        cells_per_chan.sum==nCells; 
    }
        
    //
    constraint zero_unused_channels 
    {
        foreach(cells_per_chan[i]) {
            // in_use, solve in_use_Rx first
            solve in_use_Rx[i] before cells_per_chan[i];
            if(in_use_Rx[i])
                cells_per_chan[i] inside {[1:nCells]};
            else cells_per_chan[i]==0;
        }
    }


    extern function new(input bit[31:0] numRx, numTx);
    extern virtual function void display(input string prefix="");

endclass : Config




function Config::new(input bit[31:0] numRx, numTx);

    this.numRx = numRx;
    this.numTx = numTx;
    in_use_Rx       = new[numRx];
    cells_per_chan  = new[numRx];

endfunction : new




function void Config::display(input string prefix="");
    
    $write("%s Config: numRx=%0d, numRx=%0d, nCells=%0d (", prefix, numRx, numRx, nCells);
    
    foreach(cells_per_chan[i]) 
        $write("%0d ", cells_per_chan[i]);
    
    $write(" ), enable Rx: ", prefix);
    
    foreach(in_use_Rx[i])
        if(in_use_Rx[i])  $write(" %0d ", i); 
    $display;

endfunction : display





`endif // CONFIG__SV
