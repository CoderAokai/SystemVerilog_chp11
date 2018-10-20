//`include "definitions.sv"

`ifndef ENVIRONMENT__SV
`define ENVIRONMENT__SV



`include "config.sv"
`include "generator.sv"  // -->`include "atm_cell.sv"  -->`include "definitions.sv"
`include "scoreboard.sv" // -->`include "atm_cell.sv"  -->`include "definitions.sv"
`include "coverage.sv"

`include "monitor.sv"    // -->`include "atm_cell.sv"  -->`include "definitions.sv"
`include "driver.sv"     // -->`include "atm_cell.sv"  -->`include "definitions.sv"
`include "cpu_ifc.sv"

`include "cpu_driver.sv"






class Scb_Driver_cbs extends Driver_cbs;
    Scoreboard scb;

    function new(input Scoreboard scb);
        this.scb = scb;
    endfunction

    // send cell to scoreboard
    virtual task post_tx(
        input Driver   drv,
        input UNI_cell cellu
        );
        scb.save_expected(cellu);
    endtask : post_tx

endclass : Scb_Driver_cbs



class Scb_Monitor_cbs extends Monitor_cbs;
    Scoreboard scb;

    function new(input Scoreboard scb);
        this.scb = scb;    
    endfunction

    // send cell to Scoreboard
    virtual task post_rx(
        input Monitor  mon,
        input NNI_cell celln
        );
        scb.check_actual(celln, mon.PortID);
    endtask : post_rx

endclass : Scb_Monitor_cbs



class Cov_Monitor_cbs extends Monitor_cbs;
    Coverage cov;

    function new(input Coverage cov);
        this.cov = cov;
    endfunction : new

    // 
    virtual task post_rx(
        input Monitor  mon,
        input NNI_cell celln
        );
        CellCfgType CellCfg = top.squat.lut.read(celln.VPI);
        cov.sample(mon.PortID, CellCfg.FWD);
    endtask : post_rx

endclass : Cov_Monitor_cbs



class Environment;
    UNI_generator        gen[];
    mailbox              gen2drv[];
    event                drv2gen[];
    Driver               drv[];
    Monitor              mon[];
    Config               cfg;
    Scoreboard           scb;
    Coverage             cov;
    virtual Utopia.TB_Rx Rx[];
    virtual Utopia.TB_Tx Tx[];
    int                  numRx, numTx;
    vCPU_T               mif;
    CPU_driver           cpu;

    extern function new(
        input vUtopiaRx Rx[],
        input vUtopiaTx Tx[],
        input int       numRx, numTx,
        input vCPU_T    mif
        );
    extern virtual function void gen_cfg();
    extern virtual function void build();
    extern virtual function void wrap_up();
    extern virtual task run();
    
endclass : Environment


//-------------------------------------------------------------
//  Construct an environment instance
function Environment::new(
    input vUtopiaRx Rx[],
    input vUtopiaTx Tx[],
    input int       numRx, numTx,
    input vCPU_T    mif
    );

    this.Rx = new[Rx.size()];
    foreach(Rx[i]) begin
        this.Rx[i] = Rx[i];
    end

    this.Tx = new[Tx.size()];
    foreach(Tx[i]) begin 
        this.Tx[i] = Tx[i];
    end

    this.numRx = numRx;
    this.numTx = numTx;
    this.mif   = mif;
    cfg = new(numRx, numTx);

    if($test$plusargs("ntb_random_seed")) begin
        int seed;
        $value$plusargs("ntb_random_seed=%d", seed);
        $display("Simulation run with random seed=%d", seed);
    end
    else 
        $display("Simulation run with default random seed");
endfunction : new

//------------------------------------------------------------
//  Randomize the configuration descriptor
function void Environment::gen_cfg();
    assert(cfg.randomize());
    cfg.display();
endfunction : gen_cfg

//------------------------------------------------------------
//  Build the environment objects for this test
function void Environment::build();
    cpu     = new(mif, cfg);
    gen     = new[numRx];
    drv     = new[numTx];
    gen2drv = new[numRx];
    drv2gen = new[numTx];
    scb     = new(cfg);
    cov     = new();

    //  Build generators
    foreach(gen[i]) begin
        gen2drv[i] = new();
        gen[i]     = new(gen2drv[i], drv2gen[i], cfg.cells_per_chan[i], i);
        drv[i]     = new(gen2drv[i], drv2gen[i], Rx[i], i);
    end

    //  Bulid monitor
    mon = new[numTx];
    foreach(mon[i])
        mon[i] = new(Tx[i], i);
    
    //  Connect scoreboard to driver & monitors with callbacks
    begin
        Scb_Driver_cbs  sdc = new(scb);
        Scb_Monitor_cbs sms = new(scb);
        foreach(drv[i])  drv[i].cbsq.push_back(sdc);
        foreach(mon[i])  mon[i].cbsq.push_back(sms);
    end

    // Connect coverage to monitor with callbacks
    begin
        Cov_Monitor_cbs smc = new(cov);
        foreach(mon[i]) mon[i].cbsq.push_back(smc);
    end

endfunction : build

//--------------------------------------------------------------------
// Start the transactors: generators, drivers, monitor
task Environment::run();
    int num_gen_running;

    cpu.run();

    num_gen_running = numRx;

    // for each inpt Rx channel, start generator and driver
    foreach(gen[i]) begin
        int j =i;
        fork 
            begin
                if(cfg.in_use_Rx[j])
                    gen[j].run();
                num_gen_running-- ;
            end // fork
            if(cfg.in_use_Rx[j]) drv[j].run();
        join_none
    end

    // for each output TX channel, start monitor
    foreach(mon[i]) begin
        int j =i;
        fork
            mon[j].run();
        join_none
    end

    // wait for all generators to finish , or time-out
    fork : timeout_block
        wait(num_gen_running == 0);
        begin 
            repeat(1_000_000) @(Rx[0].cbr);
            $display("@%0d: %m ERROR: Generate timeout ", $time);
            cfg.nErrors++;
        end
    join_any
    disable timeout_block;

    // wait for the data to flow through switch , into monitors ans scoreboards
    repeat(1_000) @(Rx[0].cbr);

endtask : run

//-----------------------------------------------------------------------------
// Post-run cleanup / reporting
function void Environment::wrap_up();
    $display("@%0t End of sim, %0t errors, %0d warnings, ", $time, cfg.nErrors, cfg.nWarnings);
    scb.wrap_up;
endfunction : wrap_up





`endif // ENVIRONMENT__SV
