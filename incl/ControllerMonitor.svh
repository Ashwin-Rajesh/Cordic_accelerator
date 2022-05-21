`ifndef BUS_MONITOR_SVH
`define BUS_MONITOR_SVH

`include "Types.svh"
`include "BusInterface.svh"

class ControllerMonitor #(parameter width =  32, parameter int_width = 0);
  typedef Number #(width, int_width)  NumType;    // qn.m fixed point notation, n is integer width and m = width - int_width - 1
  typedef Angle #(width) 	            AngType;    // Angle in q.m representation, m = width, with 1 representing 180 degrees, -1 representing -180 degrees 
  
  // CORDIC data inputs
  NumType  xOut;			// x output value
  NumType  yOut;			// y output value
  AngType  zOut;			// angle output value

  NumType  xInp;        // x input value
  NumType  yInp;        // y input value
  AngType  zInp;        // angle input value
  
  bit start;
  bit stop;
  bit rotationMode;
  bit rotationSystem;
  bit errorIntEn;
  bit resultIntEn;
  bit overflowStopEn;
  bit zOverflowStopEn;
  int iterCount;

  bit ready;
  bit inpError;
  bit overflowError;
  bit xOverflow;
  bit yOverflow;
  bit zOverflow;

  int iterElapsed;
  int overflowIter;

  virtual BusInterface.bus intf;
  
  function new(virtual BusInterface.bus inpIntf);
    // Initialize internal variables
    xOut = new(0);
    yOut = new(0);
    zOut = new(0);

    xInp = new(0);
    yInp = new(0);
    zInp = new(0);

    this.intf = inpIntf;
  endfunction
  
  function bit sample();
    xOut.setBin(intf.xResult);
    yOut.setBin(intf.yResult);
    zOut.setBin(intf.zResult);
    
    xInp.setBin(intf.xInput);
    yInp.setBin(intf.yInput);
    zInp.setBin(intf.zInput);

    start           = intf.controlRegisterInput[p_CNTRL_START];
    stop            = intf.controlRegisterInput[p_CNTRL_STOP];
    rotationMode    = intf.controlRegisterInput[p_CNTRL_ROT_MODE];
    rotationSystem  = intf.controlRegisterInput[p_CNTRL_ROT_SYS];
    errorIntEn      = intf.controlRegisterInput[p_CNTRL_ERR_INT_EN];
    resultIntEn     = intf.controlRegisterInput[p_CNTRL_RSLT_INT_EN];
    overflowStopEn  = intf.controlRegisterInput[p_CNTRL_OV_ST_EN];
    zOverflowStopEn = intf.controlRegisterInput[p_CNTRL_Z_OV_ST_EN];
    
    iterCount       = intf.controlRegisterInput[p_CNTRL_ITER_H:p_CNTRL_ITER_L];

    ready           = intf.controlRegisterOutput[p_FLAG_READY];
    inpError        = intf.controlRegisterOutput[p_FLAG_INP_ERR];
    overflowError   = intf.controlRegisterOutput[p_FLAG_OV_ERR];
    xOverflow       = intf.controlRegisterOutput[p_FLAG_X_OV_ERR];
    yOverflow       = intf.controlRegisterOutput[p_FLAG_Y_OV_ERR];
    zOverflow       = intf.controlRegisterOutput[p_FLAG_Z_OV_ERR];
    
    iterElapsed     = intf.controlRegisterOutput[p_FLAG_ELAPS_ITER_H:p_FLAG_ELAPS_ITER_L];
    overflowIter    = intf.controlRegisterOutput[p_FLAG_OV_ITER_H:p_FLAG_OV_ITER_L];
  endfunction

  function real xInpReal();
    return xInp.realVal;
  endfunction

  function real yInpReal();
    return yInp.realVal;
  endfunction

  function real zInpDeg();
    return zInp.degVal;
  endfunction

  function real zInpReal();
    return zInp.numVal.realVal;
  endfunction

  function real xOutReal();
    return xOut.realVal;
  endfunction

  function real yOutReal();
    return yOut.realVal;
  endfunction

  function real zOutDeg();
    return zOut.degVal;
  endfunction

  function real zOutReal();
    return zOut.numVal.realVal;
  endfunction
endclass

`endif
