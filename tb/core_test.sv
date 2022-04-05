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
  
  localparam bit p_SYSTEM = 0;				// 1 : Circular,   	0 : Hyperbolic
  localparam bit p_MODE = 1;				  // 1 : Rotation, 	0 : Vectoring
  
  localparam p_INT_BITS = p_SYSTEM ? 0 : 3; // Number of bits for integer part

  localparam p_LOG_TESTS = 0;
  localparam p_LOG_ITER  = 0;

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
  bit  validHist[$];                                    // Was the output valid? (false if it overflowed)
  
  // Overflow flag
  bit overflow = 0;
  
  initial begin
    // Dump to VCD file
    $dumpvars(0);
    $dumpfile("dump.vcd");
	
    // Display system and mode in log
    if(p_SYSTEM) begin
      if(p_MODE) begin
        $display("Circular rotation test");
      end else begin
        $display("Circular vectoring test");
      end
    end else begin
      if(p_MODE) begin
        $display("Hyperbolic rotation test");
      end else begin
        $display("Hyperbolic vectoring test");
      end
    end
    
	// Run the tests
    for(int iter1 = 0; iter1 < 2500; iter1++) begin
      
      if(p_LOG_TESTS) begin
        $display("----------------------------------------");
        $display(" Test no : %d", iter1);
      end

      overflow = 0;

      /*
      if(p_SYSTEM) begin
        if(p_MODE) begin
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
        if(p_MODE) begin
          // Hyperbolic rotation
          xInitNum.setReal(p_HYP_FACTOR);
          yInitNum.setReal(0);
          zInitAngle.setDeg(23);      
        end else begin
          // Hyperbolic vectoring
          xInitNum.setReal(1);
          yInitNum.setReal(0.5);
          zInitAngle.setDeg(0);
        end
      end
      */

      // Randomize x and y values
	  xInitNum.randomize();
      yInitNum.randomize();
      
      // Randomize angle for rotation mode and set to zero for vectoring mode  
      if(p_MODE) begin
        zInitAngle.randomize();
        while($abs(zInitAngle.degVal) > 90)
          zInitAngle.randomize();
      end else begin
        zInitAngle.setDeg(0);
      end
      
      // Display final CORDIC state
      if(p_LOG_TESTS) $display("Initial  : %10f, %10f, %10f", xInitNum.realVal, yInitNum.realVal, zInitAngle.degVal);
      
      // Check validity and find expected values
      if(p_SYSTEM) begin
        if(p_MODE) begin
          if($abs(zInitAngle.degVal) > 99) begin
            if(p_LOG_TESTS) $display("abs(ang) < 99 for circular rotation");
            iter1--;
            continue;
          end
          
          // Circular rotation
          xExp = (xInitNum.realVal * $cos(zInitAngle.radVal) - yInitNum.realVal * $sin(zInitAngle.radVal)) / p_CIRC_FACTOR;
          yExp = (yInitNum.realVal * $cos(zInitAngle.radVal) + xInitNum.realVal * $sin(zInitAngle.radVal)) / p_CIRC_FACTOR;
          zExp = 0;
        end else begin
          // Circular vectoring
          xExp = (xInitNum.realVal ** 2 + yInitNum.realVal ** 2) ** 0.5 / p_CIRC_FACTOR;
          yExp = 0;
          zExp = zInitAngle.degVal + ($atan2(yInitNum.realVal, xInitNum.realVal) * 180 / $acos(-1));

          if($abs(zExp) > 99) begin
            if(p_LOG_TESTS) $display("abs(expected ang) < 99 for circular rotation");
            iter1--;
            continue;
          end
		end      
      end else begin
        if(p_MODE) begin
          if($abs(zInitAngle.degVal) > 60) begin
            if(p_LOG_TESTS) $display("abs(ang) < 60 for hyperbolic rotation");
            iter1--;
            continue;
          end
          
          // Hyperbolic rotation
          xExp = (xInitNum.realVal * $cosh(zInitAngle.radVal) + yInitNum.realVal * $sinh(zInitAngle.radVal)) / p_HYP_FACTOR;
          yExp = (yInitNum.realVal * $cosh(zInitAngle.radVal) + xInitNum.realVal * $sinh(zInitAngle.radVal)) / p_HYP_FACTOR;
          zExp = 0;
        end else begin
          // Hyperbolic vectoring
          if($abs(yInitNum.realVal) > $abs(xInitNum.realVal)) begin
            if(p_LOG_TESTS) $display("abs(y) < abs(x) for hyperbolic vectoring");
            iter1--;
            continue;
          end
          
          xExp = $sqrt(xInitNum.realVal ** 2 - yInitNum.realVal ** 2) / p_HYP_FACTOR;
          yExp = 0;
          zExp = zInitAngle.degVal + ($atanh(yInitNum.realVal / xInitNum.realVal) * 180 / $acos(-1));
        end     
      end

	  if(xExp > NumType::maxRealVal || xExp < NumType::minRealVal  || yExp > NumType::maxRealVal || yExp < NumType::minRealVal) begin
        if(p_LOG_TESTS) $display("Expected value will overflow");
        iter1--;
        continue;
      end
      
      sequencer.setRotationSystem(p_SYSTEM);
      sequencer.setControlMode(p_MODE);
      sequencer.reset(xInitNum.realVal, yInitNum.realVal, zInitAngle.degVal);   

      #10;

      // Perform CORDIC iterations (rotation/vectoring)
      for(int iter2 = 0; iter2 < 15; iter2++) begin
        if(p_LOG_ITER) $display("%8d : %10f, %10f, %10f", iter2, sequencer.xNum.realVal, sequencer.yNum.realVal, sequencer.zAng.degVal);
        if(sequencer.iterate()) begin
          if(p_LOG_TESTS) $display("Overflow detected after iteration %2d", iter2);
          overflow = 1;
          // assert(xExp > NumType::maxRealVal || xExp < NumType::minRealVal  || yExp > NumType::maxRealVal || yExp < NumType::minRealVal);
          break;
        end
        #1;
      end

      // Display final CORDIC state
      if(p_LOG_TESTS) $display("Final    : %10f, %10f, %10f", sequencer.xNum.realVal, sequencer.yNum.realVal, sequencer.zAng.degVal);
      
      // Compare with expected results
      if(p_LOG_TESTS) $display("Expected : %10f, %10f, %10f", xExp, yExp, zExp);

      if(p_LOG_TESTS) $display("Error    : %e, %e, %f deg", sequencer.xNum.realVal - xExp, sequencer.yNum.realVal - yExp, sequencer.zAng.degVal - zExp);
            
      xInitHist.push_back(xInitNum.realVal);
      yInitHist.push_back(yInitNum.realVal);
      zInitHist.push_back(zInitAngle.degVal);

      xExpHist.push_back(xExp);
      yExpHist.push_back(yExp);
      zExpHist.push_back(zExp);
            
      xErrorHist.push_back($abs(sequencer.xNum.realVal     - xExp));
      yErrorHist.push_back($abs(sequencer.yNum.realVal     - yExp));
      zErrorHist.push_back($abs(sequencer.zAng.degVal - zExp));

      validHist.push_back(~overflow);
      idxHist.push_back(iter1);
    end
    
    $display("%2s : %10s, %10s, %10s | %10s, %10s, %11s | %12s, %12s, %10s", "No", "init x", "init y", "init ang", "exp x", "exp y", "exp ang", "error x", "error y", "error ang");
    for(int iter3 = 0; iter3 < xErrorHist.size(); iter3++) begin
      $display("%2d : %10f, %10f, %10f | %10f, %10f, %11f | %12e, %12e, %10f : %2s", idxHist[iter3], xInitHist[iter3] , yInitHist[iter3], zInitHist[iter3], xExpHist[iter3], yExpHist[iter3], zExpHist[iter3], xErrorHist[iter3] , yErrorHist[iter3], zErrorHist[iter3], validHist[iter3] ? "OK" : "Overflow");
    end
    
    $display(" Error of x : %12e to %12e, avg %e", getMin(xErrorHist), getMax(xErrorHist), xErrorHist.sum() / xErrorHist.size());
    $display(" Error of y : %12e to %12e, avg %e", getMin(yErrorHist), getMax(yErrorHist), yErrorHist.sum() / yErrorHist.size());
    $display(" Error of z : %8f deg to %8f deg, avg %f deg", getMin(zErrorHist), getMax(zErrorHist), zErrorHist.sum() / zErrorHist.size());
    
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
endmodule

`endif
