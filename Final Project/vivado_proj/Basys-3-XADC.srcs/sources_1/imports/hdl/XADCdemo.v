`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/12/2015 03:26:51 PM
// Design Name: 
// Module Name: // Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Fixed timing slack (ArtVVB 06/01/17)
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
 

module XADCdemo(
    input CLK100MHZ,
    input vauxp6,
    input vauxn6,
    input vauxp7,
    input vauxn7,
    input vauxp15,
    input vauxn15,
    input vauxp14,
    input vauxn14,
    input vp_in,
    input vn_in,
    input [1:0] sw,
    //input levelBtn,
    input btnC,
    input btnR,
    input btnL,
    input btnU,
    input btnD,
    output reg [15:0] led = 0,
    output reg [3:0] an,
    output dp,
    output reg [6:0] seg
);

    wire enable;  
    wire ready;
    wire [15:0] data;   
    reg [6:0] Address_in;
	
	//secen segment controller signals
    reg [32:0] count;
    localparam S_IDLE = 0;
    localparam S_FRAME_WAIT = 1;
    localparam S_CONVERSION = 2;
    reg [1:0] state = S_IDLE;
    reg [15:0] sseg_data;
	
	//binary to decimal converter signals
    reg b2d_start;
    reg [15:0] b2d_din;
    wire [15:0] b2d_dout;
    wire b2d_done;

    //xadc instantiation connect the eoc_out .den_in to get continuous conversion
    xadc_wiz_0  XLXI_7 (
        .daddr_in(Address_in), //addresses can be found in the artix 7 XADC user guide DRP register space
        .dclk_in(CLK100MHZ), 
        .den_in(enable), 
        .di_in(0), 
        .dwe_in(0), 
        .busy_out(),                    
        .vauxp6(vauxp6),
        .vauxn6(vauxn6),
        .vauxp7(vauxp7),
        .vauxn7(vauxn7),
        .vauxp14(vauxp14),
        .vauxn14(vauxn14),
        .vauxp15(vauxp15),
        .vauxn15(vauxn15),
        .vn_in(vn_in), 
        .vp_in(vp_in), 
        .alarm_out(), 
        .do_out(data), 
        //.reset_in(),
        .eoc_out(enable),
        .channel_out(),
        .drdy_out(ready)
    );
    
    integer multiplyer = 1; //difficulty setting based on potentiometer reading TODO later
    //led visual dmm              
    always @(posedge(CLK100MHZ)) begin            
        if(ready == 1'b1) begin
            case (data[15:12])
            //Get ADC Potentiometer readings
            0:  multiplyer <= 1;
            1:  multiplyer <= 2;
            2:  multiplyer <= 3;
            3:  multiplyer <= 4;
            4:  multiplyer <= 5;
            default: multiplyer <= 1;
//            1:  led <= 16'b11;
//            2:  led <= 16'b111;
//            3:  led <= 16'b1111;
//            4:  led <= 16'b11111;
//            5:  led <= 16'b111111;
//            6:  led <= 16'b1111111; 
//            7:  led <= 16'b11111111;
//            8:  led <= 16'b111111111;
//            9:  led <= 16'b1111111111;
//            10: led <= 16'b11111111111;
//            11: led <= 16'b111111111111;
//            12: led <= 16'b1111111111111;
//            13: led <= 16'b11111111111111;
//            14: led <= 16'b111111111111111;
//            15: led <= 16'b1111111111111111;                        
//            default: led <= 16'b1; 
            endcase      
        end
    end
    
    //binary to decimal conversion
    always @ (posedge(CLK100MHZ)) begin
        case (state)
        S_IDLE: begin
            state <= S_FRAME_WAIT;
            count <= 'b0;
        end
        S_FRAME_WAIT: begin
            if (count >= 10000000) begin
                if (data > 16'hFFD0) begin
                    sseg_data <= 16'h1000;
                    state <= S_IDLE;
                end else begin
                    b2d_start <= 1'b1;
                    b2d_din <= data;
                    state <= S_CONVERSION;
                end
            end else
                count <= count + 1'b1;
        end
        S_CONVERSION: begin
            b2d_start <= 1'b0;
            if (b2d_done == 1'b1) begin
                sseg_data <= b2d_dout;
                state <= S_IDLE;
            end
        end
        endcase
    end
    
    bin2dec m_b2d (
        .clk(CLK100MHZ),
        .start(b2d_start),
        .din(b2d_din),
        .done(b2d_done),
        .dout(b2d_dout)
    );
      
    always @(posedge(CLK100MHZ)) begin
        case(sw)
        0: Address_in <= 8'h16;
        1: Address_in <= 8'h17;
        2: Address_in <= 8'h1e;
        3: Address_in <= 8'h1f;
        endcase
    end
    
//    DigitToSeg segment1(
//        .in1(sseg_data[3:0]),
//        .in2(sseg_data[7:4]),
//        .in3(sseg_data[11:8]),
//        .in4(sseg_data[15:12]),
//        .in5(),
//        .in6(),
//        .in7(),
//        .in8(),
//        .mclk(CLK100MHZ),
//        .an(an),
//        .dp(dp),
//        .seg(seg)
//    );




//////// Start SIMON code //////////
integer level = 0; //number of leds that will blink in the pattern
reg [1:0] previousPattern [255:0];//save the previous pattern in the game (level - 1 pattern) -> saves which LED lit up (0-3) in an array
integer currentLed = 0; //New LED to display after showing the previousPattern
reg displayingPattern = 0; //0 = false
integer timer = 0; //used for displaying the pattern
integer timer2 = 0;
integer counter = 1; //used for keeping track of where the displayed pattern is at

reg [1:0] randomOutput = 0;
wire linearFeedback;
reg [1:0] buttonReleasedR = 0; //1 = true
reg [1:0] buttonReleasedC = 0; //1 = true
reg [1:0] buttonReleasedL = 0; //1 = true
reg [1:0] buttonReleasedU = 0; //1 = true
integer displayCounter = 0;
integer displayDigit = 0;
integer Seg1 = 0;
integer Seg2 = 0;
integer Seg3 = 0;
integer Seg4 = 0;
reg [1:0] lost = 0; //1 = player lost -> indicator for display to show you lost 

integer i;
initial begin
  for (i=0;i<=256;i=i+1)
    previousPattern[i] = 0;
end

always @(posedge(CLK100MHZ)) begin
    //Keep generating random numbers
    case (randomOutput) 
        2'b00: randomOutput = 2'b01;
        2'b01: randomOutput = 2'b10;
        2'b10: randomOutput = 2'b11;
        2'b11: randomOutput = 2'b00;
    endcase

    // Level will be 0 when a user tries to reset the game with a push button
    if (level == 0)begin
        //reset pattern variables
        for (i=0;i<=256;i=i+1)
            previousPattern[i] = 0;
        counter = 1;
        timer = 0;
        if (btnD == 1)begin
            //wait for user to press the down button to start the game
            level = 1;
            displayingPattern = 1; //tell program it needs to move on to next level
            lost = 0;
        end
    end
    else if (displayingPattern == 1)begin
        //Keep displaying LEDs until we finish looping through the pattern array
        if (counter < level)begin
             //every x ms times the multiplyer display next LED in the pattern array 
            if (timer == (50000000 / multiplyer))begin
                led[previousPattern[counter]] = 1; //Retreive the LED data from the array and turn it on
                timer = timer + 1;
            end
            else if (timer < (50000000 / multiplyer))begin
                //In this period LEDs will be off so that the user can differentiate individual LEDs
                timer = timer + 1;
            end
            else if (timer > (50000000 / multiplyer) && timer < (100000000 / multiplyer)) begin
                //Allow the LED to stay on for a period of time
                timer = timer + 1;
            end
            else begin
                //reset the timer for the next LED
                timer = 0;
                counter = counter + 1;
                led[0] = 0; led[1] = 0; led[2] = 0; led[3] = 0; //Turn the LEDs off
            end
        end
        else begin
            //counter == level, display new LED
            if (timer == ((50000000 / multiplyer) - 1))begin //only run this once while the timer is running
                //Generate next entry in pattern
//                currentLed = $urandom%3;
//                currentLed = $urandom_range(3,0);
                currentLed = randomOutput;
                $monitor("random number is: %d",currentLed);
                previousPattern[level] = currentLed[1:0];
                led[currentLed] = 1;
            end
            if (timer < (100000000 / multiplyer))begin
                // give the LED some time to be lit
                timer = timer + 1;
            end
            else begin
                //Pattern finished
                timer = 0;
                led[0] = 0; led[1] = 0; led[2] = 0; led[3] = 0; //Turn the LEDs off
                counter = 1;
                displayingPattern = 0; //pattern is done displaying
            end
           
        end
    end
    else begin
        //Done displaying pattern, wait for user input
        //btnR corresponds to led[0] -> button closest to edge of board = led closest to edge of board
        if (counter <= level)begin
            if (previousPattern[counter] == 0 && btnR == 1) begin
                if (timer < 25000)begin
                    //debounce button
                    timer = timer + 1;
                end
                else begin
                    //finished debouncing, tell program we got a correct choice
                    buttonReleasedR = 1;
                end
            end
            else if (previousPattern[counter] == 0 && (btnL == 1 || btnC == 1 || btnU == 1))begin
                //incorrect button pressed
                level = 0; //end the game
                lost = 1;
            end
            else if (previousPattern[counter] == 1 && btnC == 1)begin
                 if (timer < 25000)begin
                    //debounce button
                    timer = timer + 1;
                end
                else begin
                    //finished debouncing, tell program we got a correct choice
                    buttonReleasedC = 1;
                end
            end
            else if (previousPattern[counter] == 1 && (btnL == 1 || btnR == 1 || btnU == 1))begin
                //incorrect button pressed
                level = 0; //end the game
                lost = 1;
            end
            else if (previousPattern[counter] == 2 && btnL == 1)begin
               if (timer < 25000)begin
                    //debounce button
                    timer = timer + 1;
                end
                else begin
                    //finished debouncing, tell program we got a correct choice
                    buttonReleasedL = 1;
                end
            end
            else if (previousPattern[counter] == 2 && (btnR == 1 || btnC == 1 || btnU == 1))begin
                //incorrect button pressed
                level = 0; //end the game
                lost = 1;
            end
            else if (previousPattern[counter] == 3 && btnU == 1)begin
                if (timer < 25000)begin
                    //debounce button
                    timer = timer + 1;
                end
                else begin
                    //finished debouncing, tell program we got a correct choice
                    buttonReleasedU = 1;
                end
            end
            else if (previousPattern[counter] == 3 && (btnL == 1 || btnR == 1 || btnC == 1))begin
                //incorrect button pressed
                level = 0; //end the game
                lost = 1;
            end
            else
            begin
                timer = 0;
            end
            
            //Wait for user to let go of the button so it doesnt auto lose the game for holding the button down
            if (buttonReleasedR == 1 && btnR == 0)begin
                //correct button pressed
                if (timer2 < 10000000)begin
                    //blink the corresponding LED to confirm the user that they pressed a button
                    led[0] = 1;
                    timer2 = timer2 + 1;
                end
                else begin
                    led[0] = 0;
                    timer2 = 0;
                    buttonReleasedR = 0;
                    timer = 0;
                    counter = counter + 1;
                end
            end
            if (buttonReleasedC == 1 && btnC == 0)begin
                //correct button pressed
                 if (timer2 < 10000000)begin
                    //blink the corresponding LED to confirm the user that they pressed a button
                    led[1] = 1;
                    timer2 = timer2 + 1;
                end
                else begin
                    led[1] = 0;
                    timer2 = 0;
                    buttonReleasedC = 0;
                    timer = 0;
                    counter = counter + 1;
                end
            end
            if (buttonReleasedL == 1 && btnL == 0)begin
                //correct button pressed
                 if (timer2 < 10000000)begin
                    //blink the corresponding LED to confirm the user that they pressed a button
                    led[2] = 1;
                    timer2 = timer2 + 1;
                end
                else begin
                    led[2] = 0;
                    timer2 = 0;
                    buttonReleasedL = 0;
                    timer = 0;
                    counter = counter + 1;
                end
            end
            if (buttonReleasedU == 1 && btnU == 0)begin
                //correct button pressed
                 if (timer2 < 10000000)begin
                    //blink the corresponding LED to confirm the user that they pressed a button
                    led[3] = 1;
                    timer2 = timer2 + 1;
                end
                else begin
                    led[3] = 0;
                    timer2 = 0;
                    buttonReleasedU = 0;
                    timer = 0;
                    counter = counter + 1;
                end 
            end  
        end
        else begin
            //User got all patterns correct move to next level
            if (timer < 10000000)begin
                timer = timer + 1;
                led = 32767;
            end
            else if (timer < 20000000)begin
                timer = timer + 1;
                led = 0;
            end
            else if (timer < 30000000)begin
                timer = timer + 1;
                led = 32767;
            end
            else if (timer < 60000000)begin
                timer = timer + 1;
                led = 0;
            end
            else
            begin
                timer = 0;
                level = level + 1;
                counter = 1;
                displayingPattern = 1; //tell program it needs to move on to next level
            end
        end
        
        
        
        //For testing if the pattern works
//        if (levelBtn == 1)begin
//            level = level + 1;
//            displayingPattern = 1; //tell program it needs to move on to next level
//        end
    end
    
end



always @(posedge(CLK100MHZ)) begin
//    Seg1 = (level / (10 ** 3)) % 10;
    Seg2 = (level / (10 ** 2)) % 10;
    Seg3 = (level / (10 ** 1)) % 10;
    Seg4 = (level / (10 ** 0)) % 10;
    
    if (lost == 1) begin
        //Display failure message for user losing, haha you suck
        an = 4'b0111;
        displayDigit = 10;
    end
    else begin
        if (displayCounter < 12499)begin
            //turn on first segment digit (left most digit)
            an = 4'b0111;
            displayCounter = displayCounter + 1;
            displayDigit = multiplyer;//display the difficulty on this digit permenantly
        end
        else if (displayCounter < 24999)begin
            an = 4'b1011;
            displayCounter = displayCounter + 1;
            displayDigit = Seg2;
        end
        else if (displayCounter < 37499)begin
            an = 4'b1101;
            displayCounter = displayCounter + 1;
            displayDigit = Seg3;
        end
        else if (displayCounter < 49999) begin
            an = 4'b1110;
            displayCounter = displayCounter + 1;
            displayDigit = Seg4; 
        end
        else begin
            displayCounter = 0;
        end
    end
end

always @(*)begin
    //7-Segment Display
    
    case (displayDigit) 
      0: seg = 7'b1000000;
      1: seg = 7'b1111001;
      2: seg = 7'b0100100;
      3: seg = 7'b0110000;
      4: seg = 7'b0011001;
      5: seg = 7'b0010010;
      6: seg = 7'b0000010;
      7: seg = 7'b1111000;
      8: seg = 7'b0000000;
      9: seg = 7'b0011000;
      10: seg = 7'b0001110; //F for failure
      default: seg = 7'b0001110;//F
    endcase
end



endmodule
