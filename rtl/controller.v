`include "BusInterface.svh"

    // ControlRegister : Upper 16 Flags
    //                 : Lower 16 Control Bits

    // Control  0       : Start
    //          1       : Stop
    //          2       : Rotation Mode
    //          3       : Rotation System 
    //          4       : Error Interrupt Enable
    //          5       : Result Interrupt Enable
    //          6       : Overflow Stop Enable
    //          7       : Z Overflow stop Enable
    //          12, 8   : Number of Iteration

    // Flags    16      : Ready
    //          17      : Input Error
    //          18      : Overflow Error
    //          19      : X Overflow 
    //          20      : Y Overflow
    //          21      : Z Overflow
    //          26, 22  : Iterations Elapsed
    //          31, 27  : Overflow Iteration

  
module Controller #(
    parameter 	p_WIDTH = 32,
    parameter   p_HALFWORD = 16,
    parameter   p_ANGLE_ADDR_WIDTH = 5
) (
    BusInterface.controller busPort,
    CordicInterface.controller cordicPort,
    lutOffset, lutAngle
);

    localparam IDLE = 2'b00;
    localparam PRE_C = 2'b01;
    localparam CORDIC = 2'b10;
    localparam POST_C = 2'b11;

    localparam CIRCULAR = 1'b1;
    localparam HYPERBOLIC = 1'b0;

    localparam VECTOR = 1'b0;
    localparam ROTATION = 1'b1;

    input [p_WIDTH - 1 : 0 ] lutAngle;
    output wire [p_ANGLE_ADDR_WIDTH - 1:0] lutOffset;

    reg [1:0] controllerState = IDLE;
    reg [1:0] nextState;

    reg cntrlStart;
    reg cntrlStop;
    reg cntrlRotationMode;
    reg cntrlRotationSystem;
    reg cntrlErrorIntEn;
    reg cntrlResultIntEn;
    reg cntrlOverflowStopEn;
    reg cntrlZOverflowStopEn;
    reg [p_ANGLE_ADDR_WIDTH - 1:0] cntrlIterationCount;
    reg [2:0] cntrlPlaceholder;

    reg flagReady;
    reg flagInputError;
    reg flagOverflowError;
    reg flagXOverflow;
    reg flagYOverflow;
    reg flagZOverflow;
    reg [p_ANGLE_ADDR_WIDTH - 1 : 0] flagIterationElapsed;
    reg [p_ANGLE_ADDR_WIDTH - 1 : 0] flagOverflowIteration;

    reg [p_WIDTH - 1 : 0] controlRegister = {
        5'b0, 5'b0, 0, 0, 0, 0, 0, 1, 3'b0, 5'd31, 1, 1, 1, 1, 0, 0, 0, 0
    };

    reg [p_WIDTH - 1 : 0] xResult = 32'h0;
    reg [p_WIDTH - 1 : 0] yResult = 32'h0;
    reg [p_WIDTH - 1 : 0] zResult = 32'h0;
    reg contrlWriteEn = 1'b0;
    reg interrupt = 1'b0;

    reg rotationDir = 0;

    reg [p_WIDTH - 1 : 0] nextX, nextY, nextZ;
    reg nextCntrlWrEn;
    reg nextInt;
    reg nextRotDir;

    wire [p_HALFWORD - 1 : 0] flagUpper;
    wire [p_HALFWORD - 1 : 0] controlLower;

    assign controlLower = { cntrlPlaceholder, cntrlIterationCount, cntrlZOverflowStopEn, 
    cntrlOverflowStopEn, cntrlResultIntEn, cntrlErrorIntEn, cntrlRotationSystem, 
    cntrlRotationMode, cntrlStop, cntrlStart};

    assign flagUpper = { flagOverflowIteration, flagIterationElapsed, flagZOverflow, 
        flagYOverflow, flagXOverflow, flagOverflowError, flagInputError, flagReady};
    
    assign busPort.controlRegisterOutput = controlRegister;

    
    assign busPort.xResult = xResult;
    assign busPort.yResult = yResult;
    assign busPort.zResult = zResult;
    assign busPort.controlRegisterWriteEnable = contrlWriteEn;
    assign busPort.interrupt = interrupt;

    assign lutOffset = flagIterationElapsed;

    assign cordicPort.rotationSystem = cntrlRotationSystem;
    assign cordicPort.rotationAngle = lutAngle;
    assign cordicPort.shiftAmount = flagIterationElapsed;

    assign cordicPort.rotationDir = rotationDir;
    assign cordicPort.xPrev = xResult;
    assign cordicPort.yPrev = yResult;
    assign cordicPort.zPrev = zResult;

    wire clk;
    assign clk = busPort.clk;

    always @ (*) begin

        nextX = xResult;
        nextY = yResult;
        nextZ = zResult;

        cntrlStart = controlRegister[0];
        cntrlStop = controlRegister[1];
        cntrlRotationMode = controlRegister[2];
        cntrlRotationSystem = controlRegister[3];
        cntrlErrorIntEn = controlRegister[4];
        cntrlResultIntEn = controlRegister[5];
        cntrlOverflowStopEn = controlRegister[6];
        cntrlZOverflowStopEn = controlRegister[7];
        cntrlIterationCount = controlRegister[12:8];

        flagReady = controlRegister[16];
        flagInputError = controlRegister[17];
        flagOverflowError = controlRegister[18];
        flagXOverflow = controlRegister[19];
        flagYOverflow = controlRegister[20];
        flagZOverflow = controlRegister[21];
        flagIterationElapsed = controlRegister[26:22];
        flagOverflowIteration = controlRegister[31:27];
                        
        nextCntrlWrEn = contrlWriteEn;
        nextInt = interrupt;

        nextRotDir = rotationDir;

        nextState = controllerState;

        if (busPort.rst) begin
            cntrlStart = 0;
            cntrlStop = 0;
            cntrlRotationMode = 0;
            cntrlRotationSystem = 0;
            cntrlErrorIntEn = 1;
            cntrlResultIntEn = 1;
            cntrlOverflowStopEn = 1;
            cntrlZOverflowStopEn = 1;
            cntrlIterationCount = 5'd31;

            flagReady = 1;
            flagInputError = 0;
            flagOverflowError = 0;
            flagXOverflow = 0;
            flagYOverflow = 0;
            flagZOverflow = 0;
            flagIterationElapsed = 5'b0;
            flagOverflowIteration = 5'b0;

            nextX = 32'h0;
            nextY = 32'h0;
            nextZ = 32'h0;
            nextCntrlWrEn = 1'b1;
            nextInt = 1'b0;

            nextRotDir = 0;

            nextState = IDLE;
        end else begin
            
            case (controllerState)
                IDLE : begin
                    nextCntrlWrEn = 1'b0;
                    nextInt = 1'b0;
                    

                    if (busPort.controlRegisterInput[0]) begin
                        
                        nextX = busPort.xInput;
                        nextY = busPort.yInput;
                        nextZ = busPort.zInput;

                        cntrlStart = 0;

                        
                        cntrlRotationMode = busPort.controlRegisterInput[2];
                        cntrlRotationSystem = busPort.controlRegisterInput[3];
                        cntrlErrorIntEn = busPort.controlRegisterInput[4];
                        cntrlResultIntEn = busPort.controlRegisterInput[5];
                        cntrlOverflowStopEn = busPort.controlRegisterInput[6];
                        cntrlZOverflowStopEn = busPort.controlRegisterInput[7];
                        cntrlIterationCount = busPort.controlRegisterInput[12:8];

                        flagReady = 0;
                        flagInputError = 0;
                        flagOverflowError = 0;
                        flagXOverflow = 0;
                        flagYOverflow = 0;
                        flagZOverflow = 0;
                        flagIterationElapsed = 5'b0;
                        flagOverflowIteration = 5'b0;
                        
                        nextCntrlWrEn = 1;

                        nextRotDir = 0;

                        nextState = IDLE;
                                                
                    end
                end

                PRE_C: begin
                    nextCntrlWrEn = 0;
                    
                end
                default: 
            endcase
            
        end

        

    end

endmodule