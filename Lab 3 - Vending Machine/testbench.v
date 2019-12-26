`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/24/2019 05:47:35 PM
// Design Name: 
// Module Name: testbench
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


module testbench;
    reg clk;
    reg [7:0] Selection;
    reg quarterBtn;
    reg dollarBtn;
    reg cardBtn;
    wire [5:0] Despensing;
    wire [3:0] Anode_Activate; // anode signals of the 7-segment LED display
    wire [6:0] LED_out;// cathode patterns of the 7-segment LED display
    
    
    
    
    VendingMachine uut (
        .clk(clk),
        .Selection(Selection),
        .quarterBtn(quarterBtn),
        .dollarBtn(dollarBtn),
        .cardBtn(cardBtn),
        .Despensing(Despensing),
        .Anode_Activate(Anode_Activate),
        .LED_out(LED_out)
    );
    always begin
     //Simulate the clock
     #10 clk = 1;
     #10 clk = 0;
     end
    
    initial begin
        Selection = 0;
        quarterBtn = 0;
        dollarBtn = 0;
        cardBtn = 0;
        
        quarterBtn = 1;
        #2000000000
        quarterBtn = 0;
        dollarBtn = 1;
        #2000000000
        dollarBtn = 0;
        #20 Selection = 1;
        
        
    end
    
endmodule
