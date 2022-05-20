`ifndef CORE_TEST_SV
`define CORE_TEST_SV

`include "types.svh"
`include "cordic_if.svh"
`include "core_monitor.svh"
`include "core_driver.svh"
`include "core_sequencer.svh"

// Main testbench
module testbench;
  localparam real p_CIRC_FACTOR = 0.6072529350092496;

  localparam real p_HYP_FACTOR = 1.2051363584457304;

  localparam int p_CORDIC_NUM_ITER = 30;	// Number of CORDIC iterations
  
  localparam bit p_CORDIC_SYSTEM = 1;	    // 1 : Circular,   	0 : Hyperbolic
  localparam bit p_CORDIC_MODE = 0;				// 1 : Rotation, 	0 : Vectoring
  
  localparam p_INT_BITS = p_CORDIC_SYSTEM ? 0 : 3; // Number of bits for integer part

  localparam bit p_LIMIT_INPUTS = 1;      // Should inputs be valid?

  localparam bit p_LOG_TESTS = 0;         // Should we log info about each test?
  localparam bit p_LOG_ITER  = 0;         // Should we log info about each CORDIC iteration?

  localparam int p_NUM_TESTS = 2500;         // Number of tests

  typedef Number #(32, p_INT_BITS)  NumType;
  typedef Angle #(32) 	            AngType;

  // CORDIC-controller interface
  CordicInterface #(32) intf();
  
  CoreMonitor   #(32, p_INT_BITS) monitor 	  = new(intf.controller);  
  CoreSequencer #(32, p_INT_BITS) sequencer	  = new(intf.controller);
    
  // Initializing the CORDIC core
  cordic        #(.p_WIDTH(32)) dut           (intf.core);

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
  
  initial begin
    // Dump to VCD file
    $dumpvars(0);
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
            xInitNum.setReal(p_CIRC_FACTOR);
            yInitNum.setReal(0);
            zInitAngle.setDeg(45);
          end else begin
            // Circular vectoring
            xInitNum.setReal(0);
            yInitNum.setReal(0.1);
            zInitAngle.setDeg(0);
          end
        end else begin
          if(p_CORDIC_MODE) begin
            // Hyperbolic rotation
            xInitNum.setReal(p_HYP_FACTOR);
            yInitNum.setReal(0);
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

          if($abs(zInitAngle.degVal) > 100 && p_LIMIT_INPUTS) begin                     // Input angle < 100 degrees
            if(p_LOG_TESTS) $display("abs(ang) < 100 for circular rotation");
            iTest--;
            continue;
          end
        end else begin
          // Circular vectoring
          xExp = (xInitNum.realVal ** 2 + yInitNum.realVal ** 2) ** 0.5 / p_CIRC_FACTOR;
          yExp = 0;
          zExp = degreeWrap(zInitAngle.degVal + ($atan2(yInitNum.realVal, xInitNum.realVal) * 180 / $acos(-1)));

          if($abs($atan2(yInitNum.realVal, xInitNum.realVal) * 180 / $acos(-1)) > 100 && p_LIMIT_INPUTS) begin                                  // Expected angle < 100 degrees
            if(p_LOG_TESTS) $display("abs(expected ang) < 100 for circular vectoring");
            iTest--;
            continue;
          end
        end
      end else begin
        if(((xInitNum.realVal ** 2) + (yInitNum.realVal ** 2)) ** 0.5 > 1.2 && p_LIMIT_INPUTS) begin
           if(p_LOG_TESTS) $display("Input vector amplitude < 1.2 for hyperbolic");
          iTest--;
          continue;
        end
        
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
      
      // if((xExp > NumType::maxRealVal || xExp < NumType::minRealVal  || yExp > NumType::maxRealVal || yExp < NumType::minRealVal) && p_LIMIT_INPUTS) begin
      //   if(p_LOG_TESTS) $display("Expected value will overflow");
      //   iTest--;
      //   continue;
      // end
      
      sequencer.setRotationSystem(p_CORDIC_SYSTEM);
      sequencer.setControlMode(p_CORDIC_MODE);
      sequencer.reset(xInitNum.realVal, yInitNum.realVal, zInitAngle.degVal);   
      #10;

      // Perform CORDIC iterations (rotation/vectoring)
      for(iIter = 0; iIter < p_CORDIC_NUM_ITER; iIter++) begin
        if(p_LOG_TESTS && p_LOG_ITER) 
          if(p_CORDIC_SYSTEM)
          	$display("%8d : %10f, %10f, %10f", iIter, sequencer.xNum.realVal, sequencer.yNum.realVal, sequencer.zAng.degVal);
          else
          	$display("%8d : %10f, %10f, %10f", iIter, sequencer.xNum.realVal, sequencer.yNum.realVal, sequencer.zAng.getReal());
        if(sequencer.iterate()) begin
          if(p_LOG_TESTS) $display("Overflow detected after iteration %2d", iIter);

          if(sequencer.monitor.xOverflow) xOverflow = 1;
          if(sequencer.monitor.yOverflow) yOverflow = 1;
          if(sequencer.monitor.zOverflow) zOverflow = 1;
          overflowIter = iIter;
        end
        #1;
      end
      
      // Log summary
      if(p_LOG_TESTS) if(p_CORDIC_SYSTEM) begin
        // Circular mode
        $display("Final    : %10f, %10f, %10f", sequencer.xNum.realVal, sequencer.yNum.realVal, sequencer.zAng.degVal);
        $display("Expected : %10f, %10f, %10f", xExp, yExp, zExp);
        $display("Error    : %e, %e, %f deg", sequencer.xNum.realVal - xExp, sequencer.yNum.realVal - yExp, sequencer.zAng.degVal - zExp);
        $display("---------------------------------------------");
      end else begin
        // Hyperbolic mode
        $display("Final    : %10f, %10f, %10f", sequencer.xNum.realVal, sequencer.yNum.realVal, sequencer.zAng.getReal());
        $display("Expected : %10f, %10f, %10f", xExp, yExp, zExp);
        $display("Error    : %e, %e, %f rad", sequencer.xNum.realVal - xExp, sequencer.yNum.realVal - yExp, sequencer.zAng.getReal() - zExp);
        $display("---------------------------------------------");
      end
      
      xInitHist.push_back(xInitNum.realVal);
      yInitHist.push_back(yInitNum.realVal);
      if(p_CORDIC_SYSTEM) 
        zInitHist.push_back(zInitAngle.degVal);
      else
        zInitHist.push_back(zInitAngle.getReal());
      
      xExpHist.push_back(xExp);
      yExpHist.push_back(yExp);
      zExpHist.push_back(zExp);
      
      xErrorHist.push_back($abs(sequencer.xNum.realVal - xExp));
      yErrorHist.push_back($abs(sequencer.yNum.realVal - yExp));
      if(p_CORDIC_SYSTEM)
        zErrorHist.push_back(degreeWrap($abs(sequencer.zAng.degVal - zExp)));
      else
        zErrorHist.push_back($abs(sequencer.zAng.getReal() - zExp));

      ovIterHist.push_back(overflowIter);
      xOvHist.push_back(xOverflow);
      yOvHist.push_back(yOverflow);
      zOvHist.push_back(zOverflow);
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
