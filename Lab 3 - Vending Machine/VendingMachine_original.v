`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/21/2019 06:50:07 PM
// Design Name: 
// Module Name: VendingMachine
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module VendingMachine(
    input clk,
    input [7:0] Selection,
    output [5:0] Despensing,
    output reg [3:0] Anode_Activate, // anode signals of the 7-segment LED display
    output reg [6:0] LED_out// cathode patterns of the 7-segment LED display
    );
    //...................................
    reg [3:0] LED_BCD;
    reg [27:0] waittime = 0;
    reg [60:0] waittime2 = 0;
    reg [3:0] Seg1;
    reg [3:0] Seg2;
    reg [3:0] Seg3;
    reg [3:0] Seg4;
    reg [7:0] RegSelection = 0;
    reg [5:0] RegDespensing = 0;
    reg [2:0] State;
    //...................................
        
    always @(posedge clk)
    begin
        if(RegSelection != Selection)
        begin
            if(waittime2 ==124990000)
            begin
                RegDespensing[0] = 1;
            end
            else if(waittime2 ==249990000)
            begin
                RegDespensing[1] = 1;
            end
            else if(waittime2 ==374990000)
            begin
                RegDespensing[2] = 1;
            end
            else if(waittime2 ==499990000)
            begin
                RegDespensing[3] = 1;
            end
            else if(waittime2 ==524990000)
            begin
                RegDespensing[4] = 1;
            end
            else if(waittime2 >1000000000)
            begin
                RegSelection = Selection;
                RegDespensing = 6'b000000;
                waittime2 = 0;
            end
            waittime2 = waittime2 + 1;
        end
    end
    
    always @(posedge clk)
    begin
        
        Seg1 = 0;
        Seg2 = 0;
        Seg3 = 10;
        Seg4 = 5;   
        
        if(waittime ==12499)
        begin
            Anode_Activate = 4'b0111; 
            // activate LED1 and Deactivate LED2, LED3, LED4
            LED_BCD = Seg1;
        end
        else if(waittime ==24999)
        begin
            Anode_Activate = 4'b1011; 
            LED_BCD = Seg2;
        end
        else if(waittime ==37499)
        begin
            Anode_Activate = 4'b1101; 
            LED_BCD = Seg3;
            waittime = 0;
        end
        waittime = waittime + 1;
    end
    
    always@(*)
    begin
        case(LED_BCD)
            5'b00000: LED_out  = 7'b0000001; // "0"  
            5'b00001: LED_out  = 7'b1001111; // "1" 
            5'b00010: LED_out  = 7'b0010010; // "2" 
            5'b00011: LED_out  = 7'b0000110; // "3" 
            5'b00100: LED_out  = 7'b1001100; // "4" 
            5'b00101: LED_out  = 7'b0100100; // "5" 
            5'b00110: LED_out  = 7'b0100000; // "6" 
            5'b00111: LED_out  = 7'b0001111; // "7" 
            5'b01000: LED_out  = 7'b0000000; // "8"  
            5'b01001: LED_out  = 7'b0000100; // "9" 
            5'b01010: LED_out  = 7'b0011000; // "P"
            default: LED_out  = 7'b1111111; // "0"
        endcase
    end
    
assign Despensing = RegDespensing;
    
endmodule
