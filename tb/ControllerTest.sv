`ifndef CONTROLLER_TEST_SV
`define CONTROLLER_TEST_SV

`include "Types.svh"

`include "CordicInterface.svh"
`include "BusInterface.svh"
`include "LutInterface.svh"

`include "ControllerMonitor.svh"

//`include "Cordic.sv"
`include "Controller.sv"
`include "Lut.sv"

// Main testbench
module testbench;
  localparam real p_CIRC_FACTOR = 0.6072529350092496;

  localparam real p_HYP_FACTOR = 1.2051363584457304;

  localparam int p_CORDIC_NUM_ITER = 30;	// Number of CORDIC iterations
  
  localparam bit p_CORDIC_SYSTEM = 0;	    // 1 : Circular,   	0 : Hyperbolic
  localparam bit p_CORDIC_MODE = 1;			  // 1 : Rotation, 	0 : Vectoring
  
  localparam p_INT_BITS = p_CORDIC_SYSTEM ? 0 : 3; // Number of bits for integer part
  
  localparam bit p_LIMIT_INPUTS = 1;      // Should inputs be valid?
  
  localparam bit p_LOG_TESTS = 1;         // Should we log info about each test?
  localparam bit p_LOG_ITER  = 1;         // Should we log info about each CORDIC iteration?
  
  localparam int p_NUM_TESTS = 1;         // Number of tests
  
  localparam bit p_CNTRL_RSLT_INT = 1'b1; // Result interrupt
  localparam bit p_CNTRL_ERR_INT = 1'b1;  // Error interrupt
  localparam bit p_CNTRL_OV_STOP = 1'b1;  // Overflow stop
  localparam bit p_CNTRL_Z_OV_STOP = 1'b0;// Z overflow stop
  localparam bit p_CNTRL_Z_OV_REPORT_EN = 1'b0; // should report z overflow.
  
  typedef Number #(32, p_INT_BITS)  NumType;
  typedef Angle #(32) 	            AngType;
  
  // CORDIC-controller interface
  CordicInterface #(32) cordicIntf();
  BusInterface #(32) busIntf();
  LutInterface #(32) lutIntf();
  
  // Monitor and driver objects
  ControllerMonitor #(32, p_INT_BITS) monitor = new(busIntf.bus);
  
  // The modules
  cordic        #(.p_WIDTH(32)) compute_unit  (cordicIntf.core);
  Controller    dut     (busIntf.controller, cordicIntf.controller, lutIntf.controller);
  lut           lut_inst (lutIntf.lut);

  // Initial values
  NumType xInitNum     = new(0);
  NumType yInitNum     = new(0);
  AngType zInitAngle   = new(0);

  // Expected output values  
  real xExp, yExp, zExp;

  // To story test run history
  int  idxHist[$];                                      // Test index history
  real xInitHist[$],  yInitHist[$],   zInitHist[$];     // Initial values history
  real xExpHist[$],   yExpHist[$],    zExpHist[$];      // Expected values history
  real xErrorHist[$], yErrorHist[$],  zErrorHist[$];    // Error value history
  int  ovIterHist[$];                                   // Overflow iteration count
  bit  xOvHist[$],    yOvHist[$],     zOvHist[$];       // Overflow types

  // Overflow flag
  bit xOverflow = 0;
  bit yOverflow = 0;
  bit zOverflow = 0;
  int overflowIter = 0;

  int iTest, iIter;

  localparam p_WIDTH = 32;

  initial begin
    // Dump to VCD file
    $dumpvars(0, testbench);
    $dumpfile("dump.vcd");
  
    // Display system and mode in log
    if(p_CORDIC_SYSTEM) begin
      if(p_CORDIC_MODE) begin
        $display("Circular rotation test");
      end else begin
        $display("Circular vectoring test");
      end
    end else begin
      if(p_CORDIC_MODE) begin
        $display("Hyperbolic rotation test");
      end else begin
        $display("Hyperbolic vectoring test");
      end
    end
    
    $display("---------------------------------------------");
    $display("Number of tests             : %1d", p_NUM_TESTS);
    $display("Number of CORDIC iterations : %1d", p_CORDIC_NUM_ITER);
    $display("Number format               : q%1d.%1d", p_INT_BITS, 31-p_INT_BITS);

    $display("CORDIC iteration logging    : %s", p_LOG_ITER ? "ON" : "OFF");
    $display("Test logging                : %s", p_LOG_TESTS ? "ON" : "OFF");
    $display("Input constraints           : %s", p_LIMIT_INPUTS ? "ON" : "OFF");
    $display("---------------------------------------------");
    
    busIntf.xInput = 0;
    busIntf.yInput = 0;
    busIntf.zInput = 0;
    busIntf.controlRegisterInput = 0;

    busIntf.rst = 0;
    busIntf.clk = 0;

    // Run the tests
    for(iTest = 0; iTest < p_NUM_TESTS; iTest++) begin
      
      if(p_LOG_TESTS)
        $display(" Test no : %d", iTest);

      xOverflow = 0;
      yOverflow = 0;
      zOverflow = 0;
      overflowIter = -1;
      
      // Randomize x and y values
      xInitNum.randomize();
      yInitNum.randomize();
      
      // Randomize angle for rotation mode and set to zero for vectoring mode  
      if(p_CORDIC_MODE) begin
        zInitAngle.randomize();
      end else begin
        zInitAngle.setDeg(0);
      end

      // Custom values for single iteration
      if(p_NUM_TESTS == 1) begin
        if(p_CORDIC_SYSTEM) begin
          if(p_CORDIC_MODE) begin
            // Circlar rotation
            xInitNum.setReal(0.5);
            yInitNum.setReal(0);
            zInitAngle.setDeg(-45);
          end else begin
            // Circular vectoring
            xInitNum.setReal(-0.1);
            yInitNum.setReal(0.1);
            zInitAngle.setDeg(0);
          end
        end else begin
          if(p_CORDIC_MODE) begin
            // Hyperbolic rotation
            xInitNum.setReal(0);
            yInitNum.setReal(p_HYP_FACTOR);
            zInitAngle.setReal(0.5);      
          end else begin
            // Hyperbolic vectoring
            xInitNum.setReal(1);
            yInitNum.setReal(0.5);
            zInitAngle.setReal(0);
          end
        end
      end
      
      // Display final CORDIC state
      if(p_LOG_TESTS) 
        if(p_CORDIC_SYSTEM)
          $display("Initial  : %10f, %10f, %10f", xInitNum.realVal, yInitNum.realVal, zInitAngle.degVal);
        else
          $display("Initial  : %10f, %10f, %10f", xInitNum.realVal, yInitNum.realVal, zInitAngle.getReal());
      
      // Check validity and find expected values
      if(p_CORDIC_SYSTEM) begin
        if(((xInitNum.realVal ** 2) + (yInitNum.realVal ** 2)) ** 0.5 > 0.61 && p_LIMIT_INPUTS) begin
          if(p_LOG_TESTS) $display("Input vector amplitude < 0.61 for circular");
          iTest--;
          continue;
        end

        if(p_CORDIC_MODE) begin
          // Circular rotation
          xExp = (xInitNum.realVal * $cos(zInitAngle.radVal) - yInitNum.realVal * $sin(zInitAngle.radVal)) / p_CIRC_FACTOR;
          yExp = (yInitNum.realVal * $cos(zInitAngle.radVal) + xInitNum.realVal * $sin(zInitAngle.radVal)) / p_CIRC_FACTOR;
          zExp = 0;
        end else begin
          // Circular vectoring
          xExp = (xInitNum.realVal ** 2 + yInitNum.realVal ** 2) ** 0.5 / p_CIRC_FACTOR;
          yExp = 0;
          zExp = degreeWrap(zInitAngle.degVal + ($atan2(yInitNum.realVal, xInitNum.realVal) * 180 / $acos(-1)));
        end
      end else begin
        if(p_CORDIC_MODE) begin
          // Hyperbolic rotation
          xExp = (xInitNum.realVal * $cosh(zInitAngle.getReal()) + yInitNum.realVal * $sinh(zInitAngle.getReal())) / p_HYP_FACTOR;
          yExp = (yInitNum.realVal * $cosh(zInitAngle.getReal()) + xInitNum.realVal * $sinh(zInitAngle.getReal())) / p_HYP_FACTOR;
          zExp = 0;
        end else begin
          // Hyperbolic vectoring          
          if(xInitNum.realVal < 0 && p_LIMIT_INPUTS) begin
            if(p_LOG_TESTS) $display("x > 0 for hyperbolic vectoring");
            iTest--;
            continue;
          end
          
          if($abs(yInitNum.realVal) > $abs(xInitNum.realVal) && p_LIMIT_INPUTS) begin // y < x for hyperbolic vectoring
            if(p_LOG_TESTS) $display("abs(y) < abs(x) for hyperbolic vectoring");
            iTest--;
            continue;
          end

          // Get expected values
          if($abs(yInitNum.realVal) > $abs(xInitNum.realVal))
            xExp = 0;
          else
            xExp = $sqrt(xInitNum.realVal ** 2 - yInitNum.realVal ** 2) / p_HYP_FACTOR;
          yExp = 0;
          if($abs(yInitNum.realVal) > $abs(xInitNum.realVal))
          	zExp = 0;
          else
            zExp = zInitAngle.getReal() + ($atanh(yInitNum.realVal / xInitNum.realVal));

          if($abs(zExp) > 1 && p_LIMIT_INPUTS) begin                                // Angle < 1 for hyperbolic vectoring
            if(p_LOG_TESTS) $display("abs(ang) < 1 rad for hyperbolic vectoring");
             iTest--;
             continue;
          end
        end     
      end
   
      if((xExp > NumType::maxRealVal || xExp < NumType::minRealVal  || yExp > NumType::maxRealVal || yExp < NumType::minRealVal) && p_LIMIT_INPUTS) begin
        if(p_LOG_TESTS) $display("Expected value will overflow");
        iTest--;
        continue;
      end
      
      busIntf.controlRegisterInput = 0;
      busIntf.controlRegisterInput[p_CNTRL_ROT_MODE]              = p_CORDIC_MODE;
      busIntf.controlRegisterInput[p_CNTRL_ROT_SYS]               = p_CORDIC_SYSTEM;
      busIntf.controlRegisterInput[p_CNTRL_ITER_H:p_CNTRL_ITER_L] = p_CORDIC_NUM_ITER;
      busIntf.controlRegisterInput[p_CNTRL_OV_ST_EN]              = p_CNTRL_OV_STOP;
      busIntf.controlRegisterInput[p_CNTRL_Z_OV_ST_EN]            = p_CNTRL_Z_OV_STOP;
      busIntf.controlRegisterInput[p_CNTRL_Z_OV_EN]               = p_CNTRL_Z_OV_REPORT_EN;
      busIntf.controlRegisterInput[p_CNTRL_ERR_INT_EN]            = p_CNTRL_ERR_INT;
      busIntf.controlRegisterInput[p_CNTRL_RSLT_INT_EN]           = p_CNTRL_RSLT_INT;

      busIntf.xInput = xInitNum.binVal;
      busIntf.yInput = yInitNum.binVal;
      if(p_CORDIC_SYSTEM)
        busIntf.zInput = zInitAngle.getBin;
      else
        busIntf.zInput = zInitAngle.numVal.binVal;

      busIntf.clk = 1;
      #1;
      busIntf.clk = 0;
      #10;
      
      busIntf.controlRegisterInput[p_CNTRL_START]   = 1'b1;

      busIntf.clk = 1;
      #1;
      busIntf.clk = 0;
      #1;
      
      busIntf.controlRegisterInput[p_CNTRL_START]   = 1'b0;

      iIter = 0;

      // Perform CORDIC iterations till ready bit is set
      while(1) begin
        // Stop on interrupt or, stop on ready if interrupt was disabled
        if(busIntf.interrupt) begin
          if(p_LOG_ITER)
            $display("Interrupt");
          break;
        end if(~p_CNTRL_RSLT_INT && busIntf.controlRegisterOutput[p_FLAG_READY]) begin
          if(p_LOG_ITER)
            $display("Ready bit set");
          break;
        end

        busIntf.clk = 1;
        #1;
        busIntf.clk = 0;
        #1;
        iIter++;

        monitor.sample();
        if(p_LOG_TESTS && p_LOG_ITER)
          if(p_CORDIC_SYSTEM)
            $display("%8d : %10f, %10f, %10f (%1d, %6b)", monitor.iterElapsed, monitor.xOutReal, monitor.yOutReal, monitor.zOutDeg, dut.controllerState, {
              monitor.ready, monitor.inpError, monitor.overflowError, monitor.xOverflow, monitor.yOverflow, monitor.zOverflow
            });        
          else
            $display("%8d : %10f, %10f, %10f (%1d, %6b)", monitor.iterElapsed, monitor.xOutReal, monitor.yOutReal, monitor.zOutReal, dut.controllerState, {
              monitor.ready, monitor.inpError, monitor.overflowError, monitor.xOverflow, monitor.yOverflow, monitor.zOverflow
            });        
      end

      // Log test summary
      if(p_LOG_TESTS) begin
        if(p_CORDIC_SYSTEM) begin
          // Circular mode
          $display("Final    : %10f, %10f, %10f", monitor.xOutReal, monitor.yOutReal, monitor.zOutDeg);
          $display("Expected : %10f, %10f, %10f", xExp, yExp, zExp);
          $display("Error    : %e, %e, %f deg", monitor.xOutReal - xExp, monitor.yOutReal - yExp, monitor.zOutDeg - zExp);
        end else begin
          // Hyperbolic mode
          $display("Final    : %10f, %10f, %10f", monitor.xOutReal, monitor.yOutReal, monitor.zOutReal);
          $display("Expected : %10f, %10f, %10f", xExp, yExp, zExp);
          $display("Error    : %e, %e, %f deg", monitor.xOutReal - xExp, monitor.yOutReal - yExp, monitor.zOutReal - zExp);
        end
        $display("Flags    : %1b %1b %1b %1b %1b %1b (Ready, InpErr, OvErr, xOv, yOv, zOv)", monitor.ready, monitor.inpError, monitor.overflowError, monitor.xOverflow, monitor.yOverflow, monitor.zOverflow);
        $display("Iter     : %2d/%2d (overflow/elapsed)", monitor.overflowIter, monitor.iterElapsed);
        $display("---------------------------------------------");
      end

      // Save initial values
      xInitHist.push_back(xInitNum.realVal);
      yInitHist.push_back(yInitNum.realVal);
      if(p_CORDIC_SYSTEM) 
        zInitHist.push_back(zInitAngle.degVal);
      else
        zInitHist.push_back(zInitAngle.getReal());

      // Save expected values      
      xExpHist.push_back(xExp);
      yExpHist.push_back(yExp);
      zExpHist.push_back(zExp);

      // Save output errors
      xErrorHist.push_back($abs(monitor.xOutReal - xExp));
      yErrorHist.push_back($abs(monitor.yOutReal - yExp));
      if(p_CORDIC_SYSTEM)
        zErrorHist.push_back(degreeWrap($abs(monitor.zOutDeg - zExp)));
      else
        zErrorHist.push_back($abs(monitor.zOutReal - zExp));

      // Save overflow information
      if(monitor.inpError)
        ovIterHist.push_back(0);
      else if(~monitor.overflowError)
        ovIterHist.push_back(-1);
      else
        ovIterHist.push_back(monitor.overflowIter);
      xOvHist.push_back(monitor.xOverflow);
      yOvHist.push_back(monitor.yOverflow);
      zOvHist.push_back(monitor.zOverflow);
      idxHist.push_back(iTest);
    end
    $display("---------------------------------------------");
    $display("Test table");
    $display("%2s : %10s, %10s, %10s | %10s, %10s, %11s | %12s, %12s, %12s : %3s, %12s", "No", "init x", "init y", "init ang", "exp x", "exp y", "exp ang", "error x", "error y", "error ang", "overflows (xyz)", "overflow iteration");
    for(int iter3 = 0; iter3 < xErrorHist.size(); iter3++) begin
      $display("%2d : %10f, %10f, %10f | %10f, %10f, %11f | %12e, %12e, %12e : %1b%1b%1b, %2d", idxHist[iter3], xInitHist[iter3] , yInitHist[iter3], zInitHist[iter3], xExpHist[iter3], yExpHist[iter3], zExpHist[iter3], xErrorHist[iter3] , yErrorHist[iter3], zErrorHist[iter3], xOvHist[iter3], yOvHist[iter3], zOvHist[iter3], ovIterHist[iter3]);
    end
    
    $display("---------------------------------------------");
    $display("Test summary");
    $display(" Error of x : %12e to %12e, avg %e", getMin(xErrorHist), getMax(xErrorHist), xErrorHist.sum() / xErrorHist.size());
    $display(" Error of y : %12e to %12e, avg %e", getMin(yErrorHist), getMax(yErrorHist), yErrorHist.sum() / yErrorHist.size());
    $display(" Error of z : %8f deg to %8f deg, avg %f deg", getMin(zErrorHist), getMax(zErrorHist), zErrorHist.sum() / zErrorHist.size());
    
    $display("---------------------------------------------");

    #10 $finish;								// Finish simulation
  end
  
  function real getMin(real inp[$]);
    real temp[$];
    temp = inp.min();
    if(temp.size() == 0)
      return 1.0/0;
    else
      return temp[0];
  endfunction
  
  function real getMax(real inp[$]);
    real temp[$];
    temp = inp.max();
    if(temp.size() == 0)
      return 1.0/0;
    else
      return temp[0];
  endfunction

  // Convert to -180-180 degree range
  function real degreeWrap(real inp);
    if(inp > 180)
      return inp - 360;
    if(inp < -180)
      return inp + 360;
    return inp;
  endfunction
endmodule

`endif
