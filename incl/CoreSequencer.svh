`ifndef CORE_SEQUENCER_SVH
`define CORE_SEQUENCER_SVH

`include "Types.svh"
`include "CordicInterface.svh"
`include "CoreDriver.svh"
`include "CoreMonitor.svh"

class CoreSequencer #(parameter width =  32, parameter int_width = 0);  
  typedef Number #(width, int_width)  NumType;      // qn.m fixed point notation, n is integer width and m = width - int_width - 1
  typedef Angle #(width) 	            AngType;      // Angle in q.m representation, m = width, with 1 representing 180 degrees, -1 representing -180 degrees 
  
  CoreMonitor #(32, 0) monitor;
  
  // CORDIC data inputs
  NumType xNum;			// x value
  NumType yNum;			// y value
  AngType zAng;			// angle value

  bit[width-1:0] r_xBin;
  bit[width-1:0] r_yBin;
  bit[width-1:0] r_zBin;
  
  // CORDIC control inputs
  bit rotationSystem;				// 1 for circular, 0 for hyperbolic
  bit controlMode;					// 1 for rotation, 0 for vectoring
  
  // Lookup tables
  AngType arctanLUT[$];
  AngType arctanhLUT[$];
  
  virtual CordicInterface.controller intf;
  
  static real arctanLUT_real[] = {
    45.0,
    26.56505117707799,
    14.036243467926477,
    7.125016348901798,
    3.5763343749973515,
    1.7899106082460694,
    0.8951737102110744,
    0.44761417086055305,
    0.22381050036853808,
    0.1119056770662069,
    0.05595289189380367,
    0.027976452617003676,
    0.013988227142265016,
    0.006994113675352918,
    0.0034970568507040113,
    0.0017485284269804495,
    0.0008742642136937803,
    0.00043713210687233457,
    0.00021856605343934784,
    0.0001092830267200715,
    5.464151336008544e-05,
    2.7320756680048934e-05,
    1.3660378340025243e-05,
    6.830189170012719e-06,
    3.4150945850063712e-06,
    1.7075472925031871e-06,
    8.537736462515938e-07,
    4.2688682312579694e-07,
    2.1344341156289847e-07,
    1.0672170578144923e-07,
    5.336085289072462e-08,
    2.668042644536231e-08,		// Zero in binary
    1.3340213222681154e-08,
    6.670106611340577e-09,
    3.3350533056702886e-09,
    1.6675266528351443e-09,
    8.337633264175721e-10,
    4.1688166320878607e-10,
    2.0844083160439303e-10,
    1.0422041580219652e-10,
    5.211020790109826e-11,
    2.605510395054913e-11,
    1.3027551975274565e-11,
    6.513775987637282e-12,
    3.256887993818641e-12,
    1.6284439969093206e-12,
    8.142219984546603e-13,
    4.0711099922733015e-13,
    2.0355549961366507e-13,
    1.0177774980683254e-13
  };
  
  static real arctanhLUT_real[] = {
    0,
    0.5493061443340548,
    0.25541281188299536,
    0.12565721414045303,
    0.06258157147700301,
    0.03126017849066699,
    0.01562627175205221,
    0.007812658951540421,
    0.003906269868396826,
    0.0019531274835325498,
    0.000976562810441036,
    0.0004882812888051128,
    0.0002441406298506386,
    0.00012207031310632982,
    6.103515632579122e-05,
    3.05175781344739e-05,
    1.5258789063684237e-05,
    7.62939453139803e-06,
    3.8146972656435034e-06,
    1.907348632814813e-06,
    9.53674316406539e-07,
    4.768371582031611e-07,
    2.38418579101567e-07,
    1.192092895507818e-07,
    5.960464477539069e-08,
    2.980232238769532e-08,
    1.4901161193847656e-08,
    7.450580596923828e-09,
    3.725290298461914e-09,
    1.862645149230957e-09,
    9.313225746154785e-10,
    4.656612873077393e-10,
    2.3283064365386963e-10,
    1.1641532182693481e-10,
    5.820766091346741e-11,
    2.9103830456733704e-11,
    1.4551915228366852e-11,
    7.275957614183426e-12,
    3.637978807091713e-12,
    1.8189894035458565e-12,
    9.094947017729282e-13,
    4.547473508864641e-13,
    2.2737367544323206e-13,
    1.1368683772161603e-13,
    5.684341886080802e-14,
    2.842170943040401e-14,
    1.4210854715202004e-14,
    7.105427357601002e-15,
    3.552713678800501e-15,
    1.7763568394002505e-15
  };
    
  AngType temp;

  function new(virtual CordicInterface.controller inpIntf);
    // Initialize internal variables
    xNum = new(0);
    yNum = new(0);
    zAng = new(0);
  
    r_xBin   = 0;
    r_yBin   = 0;
    r_zBin   = 0;
    
	  rotationSystem  = 0;
    controlMode     = 0;

    intf  = inpIntf;   

    intf.rotationSystem = rotationSystem;
    
    monitor = new(intf);
    
    for(int i = 0; i < arctanLUT_real.size(); i++) begin
      temp = new(arctanLUT_real[i]);
      arctanLUT.push_back(temp);
      temp = new(0);
      temp.setReal(arctanhLUT_real[i]);
      arctanhLUT.push_back(temp);
    end
  endfunction
  
  function void reset(real xInp, real yInp, real zInp);
  	// Set internal variables
    xNum.setReal(xInp);
    yNum.setReal(yInp);
    zAng.setDeg(zInp);
    
    intf.xPrev = xNum.binVal;
    intf.yPrev = yNum.binVal;
    intf.zPrev = zAng.getBin();
    
    if(controlMode)
      intf.rotationDir        = ~intf.zPrev[width-1];
    else
      intf.rotationDir        = intf.yPrev[width-1];

    if(rotationSystem) begin
      intf.shiftAmount   = 0;
      intf.rotationAngle = arctanLUT[intf.shiftAmount].getBin();
    end else begin
      intf.shiftAmount   = 1;
      intf.rotationAngle = arctanhLUT[intf.shiftAmount].getBin();
    end
    
    intf.rotationSystem  = rotationSystem;
  endfunction
  
  function void setRotationSystem(bit inp);
  	rotationSystem = inp;
  endfunction
  
  function void setControlMode(bit inp);
  	controlMode = inp;
  endfunction
  
  function bit iterate();
    intf.xPrev = intf.xResult;
    intf.yPrev = intf.yResult;
    intf.zPrev = intf.zResult;
  	
    xNum.setBin(intf.xPrev);
    yNum.setBin(intf.yPrev);
    zAng.setBin(intf.zPrev);
    
    intf.shiftAmount = intf.shiftAmount + 1;
  
    if(controlMode)
      intf.rotationDir        = ~intf.zPrev[width-1];
    else
      intf.rotationDir        = intf.yPrev[width-1];
      
    if(rotationSystem)
      intf.rotationAngle      = arctanLUT[intf.shiftAmount].getBin();
    else
      intf.rotationAngle      = arctanhLUT[intf.shiftAmount].getBin();
    
    return monitor.sample();
  endfunction
endclass

`endif
