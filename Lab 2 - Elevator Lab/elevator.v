`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 09/30/2019 06:30:57 PM
// Design Name: 
// Module Name: Lab2Elevator
// 
//
// This module simulates the function of an elevator using verilog
// The current floor of the elevator is shown on a 7 segment display
// The elevator has 5 floors
// The outside of the elevator has two buttons on each floor (up/down)
// Inside the elevator just has 5 buttons (one for each floor)
// 
// The elevator will continue moving in the current direction (up/down) until it has hit all the floors that were requested in the direction 
//////////////////////////////////////////////////////////////////////////////////


module Lab2Elevator(
    input clk,
    input [3:0] OutsideSelectedFloor, // The current floor the outside up or down button is pressed at
    input up,
    input down,
    input update,
    input [4:0] InsideDesiredFloor, 
    output [3:0] DirectionState,
    output [6:0]DisplayFloor,
    output reg [3:0] Anode_Activate,
    output [4:0] OutsideLEDDebug,
    output [4:0] InsideLEDDebug);
    //W4 V4 U4 U2 pins for 7segment display
    
    reg [3:0] DirectionStateReg; // Direction where the elevator is heading (up or down)
    reg [6:0] DisplayFloorReg; // Floor which the Elevator is currently at (7segment display)
    reg [1:0] ElevatorOneCurrentMovingState = 2; //Elevator moving state (up, down or stopped)
    reg [1:0] ElevatorTwoCurrentMovingState = 2; //Elevator moving state (up, down or stopped)
    reg [1:0] ElevatorThreeCurrentMovingState = 2; //Elevator moving state (up, down or stopped)
    reg [4:0] CurrentFloorElevatorOneIsAt = 1; //Elevator Floor State (0-4)
    reg [4:0] CurrentFloorElevatorTwoIsAt = 2; //Elevator Floor State (0-4)
    reg [4:0] CurrentFloorElevatorThreeIsAt = 3; //Elevator Floor State (0-4)
    reg [4:0] DesiredoutsideFloorSelectionStates = 0; // 5 bits to keep track of the outside selection for each floor
    reg [4:0] DesiredoutsideDirectionStates = 0; // 5 bits to specify the desired direction up or down on floors with pushed buttons (1 for up, 0 for down)
    reg [4:0] DesiredInsideStates = 0; // 1 means floor is desired, 1 bit for each floor (For buttons inside the elevator)
    reg [4:0] LastInsideButton = 1; //Used to prevent inside the elevaqtor from spamming the same button
    reg [4:0] OutsideLEDDebugReg = 0;//Used to debug the program using LEDs on the actual hardware
    reg [4:0] InsideLEDDebugReg = 0;//Used to debug the program using LEDs on the actual hardware
    reg [1:0] SevenSegmentControl = 0;
    reg [3:0] ElevatorTurnControl = 0;//Only let one elevator move per clk cycle to prevent multiple elevators hitting the same floor
    //................
    
    //These are used to allow the use of the "Desired States" variables in multiple always statements
    reg [4:0] DesiredoutsideFloorSelectionStatesA3 = 0; 
    reg [4:0] DesiredoutsideDirectionStatesA3 = 0; 
    reg [4:0] DesiredInsideStatesA2 = 0; 
    reg [4:0] DesiredoutsideFloorSelectionStatesMonitor = 0; 
    reg [4:0] DesiredoutsideDirectionStatesMonitor = 0; 
    reg [4:0] DesiredInsideStatesMonitor = 0; 
    
    //....................
    reg Boolean;
    reg temp;
    integer GoUpTo = 10;
    integer GoDownTo = 10;
    integer Counter = 10;
    integer waitCounter = 0;
    integer FloorCallingTheElevator = 0;
    integer SelectedFloorsToGoTo = 0;
    integer i;
    integer x;
    integer currentFloor = 0;
    integer setDesiredVariables = 0; //If the Desired states need to be updated, set this to 1
   
    always@(posedge clk) // Controls what the Elevator does and where to go
    begin
        //Check to see if someone requested that the elevator move to them since the last clk cycle
        //if (setDesiredVariables == 1)begin
            //Someone new requested a floor, update variables
            DesiredoutsideDirectionStates = DesiredoutsideDirectionStatesA3;
            DesiredoutsideFloorSelectionStates = DesiredoutsideFloorSelectionStatesA3;
            DesiredInsideStates = DesiredInsideStatesA2;
            OutsideLEDDebugReg = DesiredoutsideFloorSelectionStates;
            InsideLEDDebugReg = DesiredInsideStates;
            //setDesiredVariables = 0;
        //end
        
        //Only give one elevator processor time per clk cycle to prevent multiple elevators hitting the same floor
        if (ElevatorTurnControl < 4'b0100)
        begin
            //Actions based on what direction elevator one is moving
            case (ElevatorOneCurrentMovingState)
            0: // Going Down
                begin            
                
                if(waitCounter == 0) //Only let the elevator move when it is not stopped at a floor (doors are not open letting someone on/off)
                begin
                    //Move the elevator one floor
                    Counter = CurrentFloorElevatorOneIsAt;
                    Counter = Counter - 1;
                    CurrentFloorElevatorOneIsAt = Counter;
                    DirectionStateReg <= 2'b00;
                    $display("Current Floor: %d", CurrentFloorElevatorOneIsAt);
                end
                
                    //Check if the elevator needs to stop at this floor
                    if((DesiredoutsideFloorSelectionStates[Counter] == 1 && 
                        (DesiredoutsideDirectionStates[Counter] == 0 || GoDownTo == Counter )) 
                        || DesiredInsideStates[Counter] == 1)
                    begin
                        //Wait about 1 second so we can physically see the elevator at each floor it stops at
                        if( waitCounter <= 0)//13000000
                            begin
                                waitCounter <= waitCounter + 1;
                            end
                        else
                            begin
                                // Wait completed, remove floor from lists as we no longer need to move to it
                                waitCounter <= 0;
                                DesiredInsideStates[Counter] = 0;
                                DesiredoutsideFloorSelectionStates[Counter] = 0;
                                DesiredoutsideDirectionStates[Counter] = 0;
                                GoDownTo = 10;
    //                            GoDownTo <= 10;
    //                            DesiredInsideStates[Counter] <= 0;
    //                            DesiredoutsideFloorSelectionStates[Counter] <= 0;
    //                            DesiredoutsideDirectionStates[Counter] <= 0;
                                OutsideLEDDebugReg = DesiredoutsideFloorSelectionStates;
                                InsideLEDDebugReg = DesiredInsideStates;
                                
                                //Check for any additional floors the elevator needs to move to
                                Boolean = 0;
                                for(i = 4; i >= 0; i = i - 1)begin
                                    if (i < Counter)begin
                                        if((DesiredoutsideFloorSelectionStates[i] == 1 && (DesiredoutsideDirectionStates[i] == 0 || GoDownTo == Counter )) || DesiredInsideStates[i] == 1)
                                            Boolean = 1; //Found more floors that are in the current path, continue on next clk cycle
                                    end
                                end
                                if(Boolean == 0)
                                begin
                                    //No more floors are requested below the elevator, move to "stopped" state so it can search for the next closest request
                                    ElevatorOneCurrentMovingState = 2;
                                end
                                
                            end
                    end   
                    else
                        begin
                            //Nothing was found directly below the current floor of the elevator,
                            //Check for any additional floors the elevator needs to move to
                            Boolean = 0;
                            for(i = 4; i >= 0; i = i - 1)begin
                                if (i < Counter)begin
                                    if((DesiredoutsideFloorSelectionStates[i] == 1 && (DesiredoutsideDirectionStates[i] == 0 || GoDownTo == Counter )) || DesiredInsideStates[i] == 1)
                                        Boolean = 1; //Found more floors that are in the current path, continue on next clk cycle
                                end         
                            end 
                            if(Boolean == 0)
                                begin
                                //No more floors are requested below the elevator, move to "stopped" state so it can search for the next closest request
                                ElevatorOneCurrentMovingState = 2;
                                end
                        end      
                end
                
            1: // Going Up
                begin
                    if(waitCounter == 0) //Only let the elevator move when it is not stopped at a floor (doors are not open letting someone on/off)
                        begin
                            //Move the elevator one floor
                            Counter = CurrentFloorElevatorOneIsAt;
                            Counter = Counter + 1;
                            CurrentFloorElevatorOneIsAt = Counter;
                            DirectionStateReg <= 2'b01;
                            $display("Current Floor (Up): %d", CurrentFloorElevatorOneIsAt);
                        end
    
                    //Check if the elevator needs to stop at this floor
                    if((DesiredoutsideFloorSelectionStates[Counter] == 1 && 
                        (DesiredoutsideDirectionStates[Counter] == 1 || GoUpTo == Counter )) 
                        || DesiredInsideStates[Counter] == 1)
                        begin
                            //Wait about 1 second so we can physically see the elevator at each floor it stops at
                            if( waitCounter <= 0)
                                begin
                                    waitCounter <= waitCounter + 1;
                                end
                            else
                                begin
                                    // Wait completed, remove floor from lists as we no longer need to move to it
                                    waitCounter <= 0;
                                    DesiredInsideStates[Counter] = 0;
                                    DesiredoutsideFloorSelectionStates[Counter] = 0;
                                    DesiredoutsideDirectionStates[Counter] = 0;
                                    GoUpTo = 10;
    //                                GoUpTo <= 10;
    //                                DesiredInsideStates[Counter] <= 0;
    //                                DesiredoutsideFloorSelectionStates[Counter] <= 0;
    //                                DesiredoutsideDirectionStates[Counter] <= 0;
                                    OutsideLEDDebugReg = DesiredoutsideFloorSelectionStates;
                                    InsideLEDDebugReg = DesiredInsideStates;
                                    
                                    //Check if there are more floors to move to
                                    Boolean = 0;
                                    for(i = 0; i < 5; i = i + 1)begin
                                        if (i > Counter)begin
                                            if((DesiredoutsideFloorSelectionStates[i] == 1 && (DesiredoutsideDirectionStates[i] == 1|| GoUpTo == i )) || DesiredInsideStates[i] == 1)
                                            Boolean = 1; //Found more floors that are in the current path, continue on next clk cycle
                                        end
                                    end 
                                    if(Boolean == 0)
                                    begin
                                        //No more floors are requested above the elevator, move to "stopped" state so it can search for the next closest request
                                        ElevatorOneCurrentMovingState = 2;
                                    end
                                end
                        end   
                        else
                            begin
                                //Nothing was found directly above the current floor of the elevator,
                                //Check for any additional floors the elevator needs to move to
                                Boolean = 0;
                                for(i = 0; i < 5; i = i + 1)begin
                                    if (i > Counter)begin
                                        if((DesiredoutsideFloorSelectionStates[i] == 1 && (DesiredoutsideDirectionStates[i] == 1|| GoUpTo == i )) || DesiredInsideStates[i] == 1)
                                        Boolean = 1; //Found more floors that are in the current path, continue on next clk cycle
                                    end
                                end 
                                if(Boolean == 0)
                                begin
                                    //No more floors are requested above the elevator, move to "stopped" state so it can search for the next closest request
                                    ElevatorOneCurrentMovingState = 2;
                                end
                            end
                end
            2: //Elevator Stopped idle
                begin
                     currentFloor = CurrentFloorElevatorOneIsAt;
                     DirectionStateReg <= 2'b11;
                     //Find the closest floor and go that direction
                     for (x = 1; x < 5; x = x + 1)
                     begin
                     //$display("x in stopped: %d", x);
    //                 $display("DesiredoutsideFloorSelectionStates[currentFloor + x]: %d", DesiredoutsideFloorSelectionStates[currentFloor + x] );
    //                 $display("DesiredInsideStates[currentFloor + x]: %d", DesiredInsideStates[currentFloor + x] );
    //                 $display("DesiredoutsideFloorSelectionStates[currentFloor - x]: %d", DesiredoutsideFloorSelectionStates[currentFloor - x] );
    //                 $display("DesiredInsideStates[currentFloor - x]: %d", DesiredInsideStates[currentFloor - x] );
    //                 $display("currentFloor - x >= 0: %d", currentFloor - x >= 0 );
    //                 $display("currentFloor + x < 5: %d", currentFloor + x < 5 );
                        //If elevator is on the bottom floor
                        if (currentFloor == 0)
                        begin
                            //Find closest floor + make sure one of the other elevators is not already going that direction
                            if ((DesiredoutsideFloorSelectionStates[currentFloor + x] == 1  || DesiredInsideStates[currentFloor + x] == 1) 
                               && (((ElevatorTwoCurrentMovingState != 1  && ((ElevatorTwoCurrentMovingState == 2 && CurrentFloorElevatorTwoIsAt != currentFloor + x)
                                        || ElevatorTwoCurrentMovingState != 2)) 
                                    || (CurrentFloorElevatorTwoIsAt > currentFloor + x && ElevatorTwoCurrentMovingState == 1)) 
                                    && ((ElevatorThreeCurrentMovingState != 1 && ((ElevatorThreeCurrentMovingState == 2 && CurrentFloorElevatorThreeIsAt != currentFloor + x)
                                            || ElevatorThreeCurrentMovingState != 2)) 
                                        || (CurrentFloorElevatorThreeIsAt > currentFloor + x && ElevatorThreeCurrentMovingState == 1 ))))
                            begin
                                ElevatorOneCurrentMovingState = 1;// change state to moving up
                                GoUpTo = currentFloor + x;
                                x <= 5; //End the for loop, we found a floor
                            end
                        end
                        //If the elevator is on the top floor
                        else if (currentFloor == 4)
                        begin
                            //Find clesest floor + make sure one of the other elevators is not already going that direction
                            if ((DesiredoutsideFloorSelectionStates[currentFloor - x] == 1 || DesiredInsideStates[currentFloor - x] == 1) 
                                && (((ElevatorTwoCurrentMovingState != 0 && ((ElevatorTwoCurrentMovingState == 2 && CurrentFloorElevatorTwoIsAt != currentFloor - x)
                                        || ElevatorTwoCurrentMovingState != 2)) 
                                    || (CurrentFloorElevatorTwoIsAt < currentFloor - x && ElevatorTwoCurrentMovingState == 0)) 
                                    && ((ElevatorThreeCurrentMovingState != 0 && ((ElevatorThreeCurrentMovingState == 2 && CurrentFloorElevatorThreeIsAt != currentFloor - x)
                                            || ElevatorThreeCurrentMovingState != 2)) 
                                        || (CurrentFloorElevatorThreeIsAt < currentFloor - x && ElevatorThreeCurrentMovingState == 0 ))))
                            begin
                                ElevatorOneCurrentMovingState = 0;//change state to moving down
                                GoDownTo = currentFloor - x;
                                x <= 5; //End the for loop, we found a floor
                            end
                        end
                        //Otherwise
                        else if ((currentFloor + x < 5 || currentFloor - x >= 0) && (DesiredoutsideFloorSelectionStates[currentFloor - x] == 1 
                        || DesiredoutsideFloorSelectionStates[currentFloor + x] == 1 ||
                            DesiredInsideStates[currentFloor - x] == 1 ||
                            DesiredInsideStates[currentFloor + x] == 1))
                        begin
    //                        $display("Else if confirmed...");
                            //Check for out of bounds errors + make sure one of the other elevators is not already going that direction
                            if (currentFloor - x >= 0 
                                && (((ElevatorTwoCurrentMovingState != 0 && ((ElevatorTwoCurrentMovingState == 2 && CurrentFloorElevatorTwoIsAt != currentFloor - x)
                                        || ElevatorTwoCurrentMovingState != 2)) 
                                    || (CurrentFloorElevatorTwoIsAt < currentFloor - x && ElevatorTwoCurrentMovingState == 0)) 
                                    && ((ElevatorThreeCurrentMovingState != 0 && ((ElevatorThreeCurrentMovingState == 2 && CurrentFloorElevatorThreeIsAt != currentFloor - x)
                                            || ElevatorThreeCurrentMovingState != 2)) 
                                        || (CurrentFloorElevatorThreeIsAt < currentFloor && ElevatorThreeCurrentMovingState == 0 )))) begin
                                 //find the nearest floor below the current floor that needs to be moved to and go that direction
                                if (DesiredoutsideFloorSelectionStates[currentFloor - x] == 1 || DesiredInsideStates[currentFloor - x] == 1)
                                    ElevatorOneCurrentMovingState = 0;//change state to moving down
                                    GoDownTo = currentFloor - x;
                                    x <= 5; //End the for loop, we found a floor
                            end
                            //Check for out of bounds errors + make sure one of the other elevators is not already going that direction
                            if(currentFloor + x < 5 
                                && (((ElevatorTwoCurrentMovingState != 1 && ((ElevatorTwoCurrentMovingState == 2 && CurrentFloorElevatorTwoIsAt != currentFloor + x)
                                        || ElevatorTwoCurrentMovingState != 2)) 
                                    || (CurrentFloorElevatorTwoIsAt > currentFloor + x && ElevatorTwoCurrentMovingState == 1)) 
                                    && ((ElevatorThreeCurrentMovingState != 1 && ((ElevatorThreeCurrentMovingState == 2 && CurrentFloorElevatorThreeIsAt != currentFloor + x)
                                            || ElevatorThreeCurrentMovingState != 2))
                                        || (CurrentFloorElevatorThreeIsAt > currentFloor && ElevatorThreeCurrentMovingState == 1 ))))begin
                                //find the nearest floor above the current floor that needs to be moved to and go that direction
    //                            $display("Less than 5 confirmed...");
                                if (DesiredoutsideFloorSelectionStates[currentFloor + x] == 1 || DesiredInsideStates[currentFloor + x] == 1)
                                    begin
                                        ElevatorOneCurrentMovingState = 1;//change state to moving up
                                        GoUpTo = currentFloor + x;
    //                                    $display("ElevatorCurrentMovingState %d", ElevatorCurrentMovingState);
                                        x <= 5; //End the for loop, we found a floor
                                    end
                            end
                           
                        end
                     end
                end
            endcase
            ElevatorTurnControl = ElevatorTurnControl + 1;
        end
        else if (ElevatorTurnControl < 4'b1000)begin
             //Actions based on what direction elevator two is moving
            case (ElevatorTwoCurrentMovingState)
            0: // Going Down
                begin            
                
                if(waitCounter == 0) //Only let the elevator move when it is not stopped at a floor (doors are not open letting someone on/off)
                begin
                    //Move the elevator one floor
                    Counter = CurrentFloorElevatorTwoIsAt;
                    Counter = Counter - 1;
                    CurrentFloorElevatorTwoIsAt = Counter;
                    DirectionStateReg <= 2'b00;
                    $display("Current Floor: %d", CurrentFloorElevatorTwoIsAt);
                end
                
                    //Check if the elevator needs to stop at this floor
                    if((DesiredoutsideFloorSelectionStates[Counter] == 1 && 
                        (DesiredoutsideDirectionStates[Counter] == 0 || GoDownTo == Counter )) 
                        || DesiredInsideStates[Counter] == 1)
                    begin
                        //Wait about 1 second so we can physically see the elevator at each floor it stops at
                        if( waitCounter <= 0)//13000000
                            begin
                                waitCounter <= waitCounter + 1;
                            end
                        else
                            begin
                                // Wait completed, remove floor from lists as we no longer need to move to it
                                waitCounter <= 0;
                                DesiredInsideStates[Counter] = 0;
                                DesiredoutsideFloorSelectionStates[Counter] = 0;
                                DesiredoutsideDirectionStates[Counter] = 0;
                                GoDownTo = 10;
    //                            GoDownTo <= 10;
    //                            DesiredInsideStates[Counter] <= 0;
    //                            DesiredoutsideFloorSelectionStates[Counter] <= 0;
    //                            DesiredoutsideDirectionStates[Counter] <= 0;
                                OutsideLEDDebugReg = DesiredoutsideFloorSelectionStates;
                                InsideLEDDebugReg = DesiredInsideStates;
                                
                                //Check for any additional floors the elevator needs to move to
                                Boolean = 0;
                                for(i = 4; i >= 0; i = i - 1)begin
                                    if (i < Counter)begin
                                        if((DesiredoutsideFloorSelectionStates[i] == 1 && (DesiredoutsideDirectionStates[i] == 0 || GoDownTo == Counter )) || DesiredInsideStates[i] == 1)
                                            Boolean = 1; //Found more floors that are in the current path, continue on next clk cycle
                                    end
                                end
                                if(Boolean == 0)
                                begin
                                    //No more floors are requested below the elevator, move to "stopped" state so it can search for the next closest request
                                    ElevatorTwoCurrentMovingState = 2;
                                end
                                
                            end
                    end   
                    else
                        begin
                            //Nothing was found directly below the current floor of the elevator,
                            //Check for any additional floors the elevator needs to move to
                            Boolean = 0;
                            for(i = 4; i >= 0; i = i - 1)begin
                                if (i < Counter)begin
                                    if((DesiredoutsideFloorSelectionStates[i] == 1 && (DesiredoutsideDirectionStates[i] == 0 || GoDownTo == Counter )) || DesiredInsideStates[i] == 1)
                                        Boolean = 1; //Found more floors that are in the current path, continue on next clk cycle
                                end         
                            end 
                            if(Boolean == 0)
                                begin
                                //No more floors are requested below the elevator, move to "stopped" state so it can search for the next closest request
                                ElevatorTwoCurrentMovingState = 2;
                                end
                        end      
                end
                
            1: // Going Up
                begin
                    if(waitCounter == 0) //Only let the elevator move when it is not stopped at a floor (doors are not open letting someone on/off)
                        begin
                            //Move the elevator one floor
                            Counter = CurrentFloorElevatorTwoIsAt;
                            Counter = Counter + 1;
                            CurrentFloorElevatorTwoIsAt = Counter;
                            DirectionStateReg <= 2'b01;
                            $display("Current Floor (Up): %d", CurrentFloorElevatorTwoIsAt);
                        end
    
                    //Check if the elevator needs to stop at this floor
                    if((DesiredoutsideFloorSelectionStates[Counter] == 1 && 
                        (DesiredoutsideDirectionStates[Counter] == 1 || GoUpTo == Counter )) 
                        || DesiredInsideStates[Counter] == 1)
                        begin
                            //Wait about 1 second so we can physically see the elevator at each floor it stops at
                            if( waitCounter <= 0)
                                begin
                                    waitCounter <= waitCounter + 1;
                                end
                            else
                                begin
                                    // Wait completed, remove floor from lists as we no longer need to move to it
                                    waitCounter <= 0;
                                    DesiredInsideStates[Counter] = 0;
                                    DesiredoutsideFloorSelectionStates[Counter] = 0;
                                    DesiredoutsideDirectionStates[Counter] = 0;
                                    GoUpTo = 10;
    //                                GoUpTo <= 10;
    //                                DesiredInsideStates[Counter] <= 0;
    //                                DesiredoutsideFloorSelectionStates[Counter] <= 0;
    //                                DesiredoutsideDirectionStates[Counter] <= 0;
                                    OutsideLEDDebugReg = DesiredoutsideFloorSelectionStates;
                                    InsideLEDDebugReg = DesiredInsideStates;
                                    
                                    //Check if there are more floors to move to
                                    Boolean = 0;
                                    for(i = 0; i < 5; i = i + 1)begin
                                        if (i > Counter)begin
                                            if((DesiredoutsideFloorSelectionStates[i] == 1 && (DesiredoutsideDirectionStates[i] == 1|| GoUpTo == i )) || DesiredInsideStates[i] == 1)
                                            Boolean = 1; //Found more floors that are in the current path, continue on next clk cycle
                                        end
                                    end 
                                    if(Boolean == 0)
                                    begin
                                        //No more floors are requested above the elevator, move to "stopped" state so it can search for the next closest request
                                        ElevatorTwoCurrentMovingState = 2;
                                    end
                                end
                        end   
                        else
                            begin
                                //Nothing was found directly above the current floor of the elevator,
                                //Check for any additional floors the elevator needs to move to
                                Boolean = 0;
                                for(i = 0; i < 5; i = i + 1)begin
                                    if (i > Counter)begin
                                        if((DesiredoutsideFloorSelectionStates[i] == 1 && (DesiredoutsideDirectionStates[i] == 1|| GoUpTo == i )) || DesiredInsideStates[i] == 1)
                                        Boolean = 1; //Found more floors that are in the current path, continue on next clk cycle
                                    end
                                end 
                                if(Boolean == 0)
                                begin
                                    //No more floors are requested above the elevator, move to "stopped" state so it can search for the next closest request
                                    ElevatorTwoCurrentMovingState = 2;
                                end
                            end
                end
            2: //Elevator Stopped idle
                begin
                     currentFloor = CurrentFloorElevatorTwoIsAt;
                     DirectionStateReg <= 2'b11;
                     //Find the closest floor and go that direction
                     for (x = 1; x < 5; x = x + 1)
                     begin
                     //$display("x in stopped: %d", x);
    //                 $display("DesiredoutsideFloorSelectionStates[currentFloor + x]: %d", DesiredoutsideFloorSelectionStates[currentFloor + x] );
    //                 $display("DesiredInsideStates[currentFloor + x]: %d", DesiredInsideStates[currentFloor + x] );
    //                 $display("DesiredoutsideFloorSelectionStates[currentFloor - x]: %d", DesiredoutsideFloorSelectionStates[currentFloor - x] );
    //                 $display("DesiredInsideStates[currentFloor - x]: %d", DesiredInsideStates[currentFloor - x] );
    //                 $display("currentFloor - x >= 0: %d", currentFloor - x >= 0 );
    //                 $display("currentFloor + x < 5: %d", currentFloor + x < 5 );
                        //If elevator is on the bottom floor
                        if (currentFloor == 0)
                        begin
                            //Find Closest floor + make sure one of the other elevators is not already going that direction
                            if ((DesiredoutsideFloorSelectionStates[currentFloor + x] == 1  || DesiredInsideStates[currentFloor + x] == 1) 
                                && (((ElevatorOneCurrentMovingState != 1 && ((ElevatorOneCurrentMovingState == 2 && CurrentFloorElevatorOneIsAt != currentFloor + x)
                                        || ElevatorOneCurrentMovingState != 2)) 
                                    || (CurrentFloorElevatorOneIsAt > currentFloor + x && ElevatorOneCurrentMovingState == 1)) 
                                    && ((ElevatorThreeCurrentMovingState != 1 && ((ElevatorThreeCurrentMovingState == 2 && CurrentFloorElevatorThreeIsAt != currentFloor + x)
                                            || ElevatorThreeCurrentMovingState != 2)) 
                                        || (CurrentFloorElevatorThreeIsAt > currentFloor && ElevatorThreeCurrentMovingState == 1 ))))
                            begin
                                ElevatorTwoCurrentMovingState = 1;// change state to moving up
                                GoUpTo = currentFloor + x;
                                x <= 5; //End the for loop, we found a floor
                            end
                        end
                        //If the elevator is on the top floor
                        else if (currentFloor == 4)
                        begin
                            //Find closest floor + make sure one of the other elevators is not already going that direction
                            if ((DesiredoutsideFloorSelectionStates[currentFloor - x] == 1 || DesiredInsideStates[currentFloor - x] == 1) 
                                && (((ElevatorOneCurrentMovingState != 0 && ((ElevatorOneCurrentMovingState == 2 && CurrentFloorElevatorOneIsAt != currentFloor - x)
                                        || ElevatorOneCurrentMovingState != 2)) 
                                    || (CurrentFloorElevatorOneIsAt < currentFloor - x && ElevatorOneCurrentMovingState == 0)) 
                                    && ((ElevatorThreeCurrentMovingState != 0 && ((ElevatorThreeCurrentMovingState == 2 && CurrentFloorElevatorThreeIsAt != currentFloor - x)
                                            || ElevatorThreeCurrentMovingState != 2)) 
                                        || (CurrentFloorElevatorThreeIsAt < currentFloor && ElevatorThreeCurrentMovingState == 0 ))))
                            begin
                                ElevatorTwoCurrentMovingState = 0;//change state to moving down
                                GoDownTo = currentFloor - x;
                                x <= 5; //End the for loop, we found a floor
                            end
                        end
                        //Otherwise
                        else if ((currentFloor + x < 5 || currentFloor - x >= 0) && (DesiredoutsideFloorSelectionStates[currentFloor - x] == 1 
                        || DesiredoutsideFloorSelectionStates[currentFloor + x] == 1 ||
                            DesiredInsideStates[currentFloor - x] == 1 ||
                            DesiredInsideStates[currentFloor + x] == 1))
                        begin
    //                        $display("Else if confirmed...");
                            //Check for out of bounds errors + make sure one of the other elevators is not already going that direction
                            if (currentFloor - x >= 0 
                                && (((ElevatorOneCurrentMovingState != 0 && ((ElevatorOneCurrentMovingState == 2 && CurrentFloorElevatorOneIsAt != currentFloor - x)
                                        || ElevatorOneCurrentMovingState != 2)) 
                                    || (CurrentFloorElevatorOneIsAt < currentFloor - x && ElevatorOneCurrentMovingState == 0)) 
                                    && ((ElevatorThreeCurrentMovingState != 0 && ((ElevatorThreeCurrentMovingState == 2 && CurrentFloorElevatorThreeIsAt != currentFloor - x)
                                            || ElevatorThreeCurrentMovingState != 2)) 
                                        || (CurrentFloorElevatorThreeIsAt < currentFloor && ElevatorThreeCurrentMovingState == 0 )))) begin
                                 //find the nearest floor below the current floor that needs to be moved to and go that direction
                                if (DesiredoutsideFloorSelectionStates[currentFloor - x] == 1 || DesiredInsideStates[currentFloor - x] == 1)
                                    ElevatorTwoCurrentMovingState = 0;//change state to moving down
                                    GoDownTo = currentFloor - x;
                                    x <= 5; //End the for loop, we found a floor
                            end
                            //Check for out of bounds errors + make sure one of the other elevators is not already going that direction
                            if(currentFloor + x < 5 
                                && (((ElevatorOneCurrentMovingState != 1 && ((ElevatorOneCurrentMovingState == 2 && CurrentFloorElevatorOneIsAt != currentFloor + x)
                                        || ElevatorOneCurrentMovingState != 2))
                                    || (CurrentFloorElevatorOneIsAt > currentFloor + x && ElevatorOneCurrentMovingState == 1)) 
                                    && ((ElevatorThreeCurrentMovingState != 1 && ((ElevatorThreeCurrentMovingState == 2 && CurrentFloorElevatorThreeIsAt != currentFloor + x)
                                            || ElevatorThreeCurrentMovingState != 2)) 
                                        || (CurrentFloorElevatorThreeIsAt > currentFloor + x && ElevatorThreeCurrentMovingState == 1 ))))begin
                                //find the nearest floor above the current floor that needs to be moved to and go that direction
    //                            $display("Less than 5 confirmed...");
                                if (DesiredoutsideFloorSelectionStates[currentFloor + x] == 1 || DesiredInsideStates[currentFloor + x] == 1)
                                    begin
                                        ElevatorTwoCurrentMovingState = 1;//change state to moving up
                                        GoUpTo = currentFloor + x;
    //                                    $display("ElevatorCurrentMovingState %d", ElevatorCurrentMovingState);
                                        x <= 5; //End the for loop, we found a floor
                                    end
                            end
                           
                        end
                     end
                end
            endcase
            ElevatorTurnControl = ElevatorTurnControl + 1;
        end
        else if(ElevatorTurnControl < 4'b1111)begin
             //Actions based on what direction elevator three is moving
            case (ElevatorThreeCurrentMovingState)
            0: // Going Down
                begin            
                
                if(waitCounter == 0) //Only let the elevator move when it is not stopped at a floor (doors are not open letting someone on/off)
                begin
                    //Move the elevator one floor
                    Counter = CurrentFloorElevatorThreeIsAt;
                    Counter = Counter - 1;
                    CurrentFloorElevatorThreeIsAt = Counter;
                    DirectionStateReg <= 2'b00;
                    $display("Current Floor: %d", CurrentFloorElevatorThreeIsAt);
                end
                
                    //Check if the elevator needs to stop at this floor
                    if((DesiredoutsideFloorSelectionStates[Counter] == 1 && 
                        (DesiredoutsideDirectionStates[Counter] == 0 || GoDownTo == Counter )) 
                        || DesiredInsideStates[Counter] == 1)
                    begin
                        //Wait about 1 second so we can physically see the elevator at each floor it stops at
                        if( waitCounter <= 0)//13000000
                            begin
                                waitCounter <= waitCounter + 1;
                            end
                        else
                            begin
                                // Wait completed, remove floor from lists as we no longer need to move to it
                                waitCounter <= 0;
                                DesiredInsideStates[Counter] = 0;
                                DesiredoutsideFloorSelectionStates[Counter] = 0;
                                DesiredoutsideDirectionStates[Counter] = 0;
                                GoDownTo = 10;
    //                            GoDownTo <= 10;
    //                            DesiredInsideStates[Counter] <= 0;
    //                            DesiredoutsideFloorSelectionStates[Counter] <= 0;
    //                            DesiredoutsideDirectionStates[Counter] <= 0;
                                OutsideLEDDebugReg = DesiredoutsideFloorSelectionStates;
                                InsideLEDDebugReg = DesiredInsideStates;
                                
                                //Check for any additional floors the elevator needs to move to
                                Boolean = 0;
                                for(i = 4; i >= 0; i = i - 1)begin
                                    if (i < Counter)begin
                                        if((DesiredoutsideFloorSelectionStates[i] == 1 && (DesiredoutsideDirectionStates[i] == 0 || GoDownTo == Counter )) || DesiredInsideStates[i] == 1)
                                            Boolean = 1; //Found more floors that are in the current path, continue on next clk cycle
                                    end
                                end
                                if(Boolean == 0)
                                begin
                                    //No more floors are requested below the elevator, move to "stopped" state so it can search for the next closest request
                                    ElevatorThreeCurrentMovingState = 2;
                                end
                                
                            end
                    end   
                    else
                        begin
                            //Nothing was found directly below the current floor of the elevator,
                            //Check for any additional floors the elevator needs to move to
                            Boolean = 0;
                            for(i = 4; i >= 0; i = i - 1)begin
                                if (i < Counter)begin
                                    if((DesiredoutsideFloorSelectionStates[i] == 1 && (DesiredoutsideDirectionStates[i] == 0 || GoDownTo == Counter )) || DesiredInsideStates[i] == 1)
                                        Boolean = 1; //Found more floors that are in the current path, continue on next clk cycle
                                end         
                            end 
                            if(Boolean == 0)
                                begin
                                //No more floors are requested below the elevator, move to "stopped" state so it can search for the next closest request
                                ElevatorThreeCurrentMovingState = 2;
                                end
                        end      
                end
                
            1: // Going Up
                begin
                    if(waitCounter == 0) //Only let the elevator move when it is not stopped at a floor (doors are not open letting someone on/off)
                        begin
                            //Move the elevator one floor
                            Counter = CurrentFloorElevatorThreeIsAt;
                            Counter = Counter + 1;
                            CurrentFloorElevatorThreeIsAt = Counter;
                            DirectionStateReg <= 2'b01;
                            $display("Current Floor (Up): %d", CurrentFloorElevatorThreeIsAt);
                        end
    
                    //Check if the elevator needs to stop at this floor
                    if((DesiredoutsideFloorSelectionStates[Counter] == 1 && 
                        (DesiredoutsideDirectionStates[Counter] == 1 || GoUpTo == Counter )) 
                        || DesiredInsideStates[Counter] == 1)
                        begin
                            //Wait about 1 second so we can physically see the elevator at each floor it stops at
                            if( waitCounter <= 0)
                                begin
                                    waitCounter <= waitCounter + 1;
                                end
                            else
                                begin
                                    // Wait completed, remove floor from lists as we no longer need to move to it
                                    waitCounter <= 0;
                                    DesiredInsideStates[Counter] = 0;
                                    DesiredoutsideFloorSelectionStates[Counter] = 0;
                                    DesiredoutsideDirectionStates[Counter] = 0;
                                    GoUpTo = 10;
    //                                GoUpTo <= 10;
    //                                DesiredInsideStates[Counter] <= 0;
    //                                DesiredoutsideFloorSelectionStates[Counter] <= 0;
    //                                DesiredoutsideDirectionStates[Counter] <= 0;
                                    OutsideLEDDebugReg = DesiredoutsideFloorSelectionStates;
                                    InsideLEDDebugReg = DesiredInsideStates;
                                    
                                    //Check if there are more floors to move to
                                    Boolean = 0;
                                    for(i = 0; i < 5; i = i + 1)begin
                                        if (i > Counter)begin
                                            if((DesiredoutsideFloorSelectionStates[i] == 1 && (DesiredoutsideDirectionStates[i] == 1|| GoUpTo == i )) || DesiredInsideStates[i] == 1)
                                            Boolean = 1; //Found more floors that are in the current path, continue on next clk cycle
                                        end
                                    end 
                                    if(Boolean == 0)
                                    begin
                                        //No more floors are requested above the elevator, move to "stopped" state so it can search for the next closest request
                                        ElevatorThreeCurrentMovingState = 2;
                                    end
                                end
                        end   
                        else
                            begin
                                //Nothing was found directly above the current floor of the elevator,
                                //Check for any additional floors the elevator needs to move to
                                Boolean = 0;
                                for(i = 0; i < 5; i = i + 1)begin
                                    if (i > Counter)begin
                                        if((DesiredoutsideFloorSelectionStates[i] == 1 && (DesiredoutsideDirectionStates[i] == 1|| GoUpTo == i )) || DesiredInsideStates[i] == 1)
                                        Boolean = 1; //Found more floors that are in the current path, continue on next clk cycle
                                    end
                                end 
                                if(Boolean == 0)
                                begin
                                    //No more floors are requested above the elevator, move to "stopped" state so it can search for the next closest request
                                    ElevatorThreeCurrentMovingState = 2;
                                end
                            end
                end
            2: //Elevator Stopped idle
                begin
                     currentFloor = CurrentFloorElevatorThreeIsAt;
                     DirectionStateReg <= 2'b11;
                     //Find the closest floor and go that direction
                     for (x = 1; x < 5; x = x + 1)
                     begin
                     //$display("x in stopped: %d", x);
    //                 $display("DesiredoutsideFloorSelectionStates[currentFloor + x]: %d", DesiredoutsideFloorSelectionStates[currentFloor + x] );
    //                 $display("DesiredInsideStates[currentFloor + x]: %d", DesiredInsideStates[currentFloor + x] );
    //                 $display("DesiredoutsideFloorSelectionStates[currentFloor - x]: %d", DesiredoutsideFloorSelectionStates[currentFloor - x] );
    //                 $display("DesiredInsideStates[currentFloor - x]: %d", DesiredInsideStates[currentFloor - x] );
    //                 $display("currentFloor - x >= 0: %d", currentFloor - x >= 0 );
    //                 $display("currentFloor + x < 5: %d", currentFloor + x < 5 );
                        //If elevator is on the bottom floor
                        if (currentFloor == 0)
                        begin
                            //Find closest floor + make sure one of the other elevators is not already going that direction
                            if ((DesiredoutsideFloorSelectionStates[currentFloor + x] == 1  || DesiredInsideStates[currentFloor + x] == 1)
                                && (((ElevatorTwoCurrentMovingState != 1  && ((ElevatorTwoCurrentMovingState == 2 && CurrentFloorElevatorTwoIsAt != currentFloor + x)
                                        || ElevatorTwoCurrentMovingState != 2))
                                    || (CurrentFloorElevatorTwoIsAt > currentFloor + x && ElevatorTwoCurrentMovingState == 1)) 
                                    && ((ElevatorOneCurrentMovingState != 1 && ((ElevatorOneCurrentMovingState == 2 && CurrentFloorElevatorOneIsAt != currentFloor + x)
                                            || ElevatorOneCurrentMovingState != 2)) 
                                        || (CurrentFloorElevatorOneIsAt > currentFloor + x && ElevatorOneCurrentMovingState == 1 ))))
                            begin
                                ElevatorThreeCurrentMovingState = 1;// change state to moving up
                                GoUpTo = currentFloor + x;
                                x <= 5; //End the for loop, we found a floor
                            end
                        end
                        //If the elevator is on the top floor
                        else if (currentFloor == 4)
                        begin
                            //Find closest floor + make sure one of the other elevators is not already going that direction
                            if ((DesiredoutsideFloorSelectionStates[currentFloor - x] == 1 || DesiredInsideStates[currentFloor - x] == 1)
                                && (((ElevatorTwoCurrentMovingState != 0 && ((ElevatorTwoCurrentMovingState == 2 && CurrentFloorElevatorTwoIsAt != currentFloor - x)
                                        || ElevatorTwoCurrentMovingState != 2)) 
                                    || (CurrentFloorElevatorTwoIsAt < currentFloor - x && ElevatorTwoCurrentMovingState == 0)) 
                                    && ((ElevatorOneCurrentMovingState != 0 && ((ElevatorOneCurrentMovingState == 2 && CurrentFloorElevatorOneIsAt != currentFloor - x)
                                            || ElevatorOneCurrentMovingState != 2)) 
                                        || (CurrentFloorElevatorOneIsAt < currentFloor - x && ElevatorOneCurrentMovingState == 0 ))))
                            begin
                                ElevatorThreeCurrentMovingState = 0;//change state to moving down
                                GoDownTo = currentFloor - x;
                                x <= 5; //End the for loop, we found a floor
                            end
                        end
                        //Otherwise
                        else if ((currentFloor + x < 5 || currentFloor - x >= 0) && (DesiredoutsideFloorSelectionStates[currentFloor - x] == 1 
                        || DesiredoutsideFloorSelectionStates[currentFloor + x] == 1 ||
                            DesiredInsideStates[currentFloor - x] == 1 ||
                            DesiredInsideStates[currentFloor + x] == 1))
                        begin
    //                        $display("Else if confirmed...");
                            //Check for out of bounds errors + make sure one of the other elevators is not already going that direction
                            if (currentFloor - x >= 0
                                && (((ElevatorTwoCurrentMovingState != 0 && ((ElevatorTwoCurrentMovingState == 2 && CurrentFloorElevatorTwoIsAt != currentFloor - x) 
                                        || ElevatorTwoCurrentMovingState != 2)) 
                                    || (CurrentFloorElevatorTwoIsAt < currentFloor - x && ElevatorTwoCurrentMovingState == 0)) 
                                    && ((ElevatorOneCurrentMovingState != 0 && ((ElevatorOneCurrentMovingState == 2 && CurrentFloorElevatorOneIsAt != currentFloor - x)
                                            || ElevatorOneCurrentMovingState != 2)) 
                                        || (CurrentFloorElevatorOneIsAt < currentFloor - x && ElevatorOneCurrentMovingState == 0 ))))
                            begin
                                 //find the nearest floor below the current floor that needs to be moved to and go that direction
                                if (DesiredoutsideFloorSelectionStates[currentFloor - x] == 1 || DesiredInsideStates[currentFloor - x] == 1)
                                    ElevatorThreeCurrentMovingState = 0;//change state to moving down
                                    GoDownTo = currentFloor - x;
                                    x <= 5; //End the for loop, we found a floor
                            end
                            //Check for out of bounds errors + make sure one of the other elevators is not already going that direction
                            if(currentFloor + x < 5
                                && (((ElevatorTwoCurrentMovingState != 1 && ((ElevatorTwoCurrentMovingState == 2 && CurrentFloorElevatorTwoIsAt != currentFloor + x)
                                        || ElevatorTwoCurrentMovingState != 2)) 
                                    || (CurrentFloorElevatorTwoIsAt > currentFloor + x && ElevatorTwoCurrentMovingState == 1)) 
                                    && ((ElevatorOneCurrentMovingState != 1 && ((ElevatorOneCurrentMovingState == 2 && CurrentFloorElevatorOneIsAt != currentFloor + x)
                                            || ElevatorOneCurrentMovingState != 2)) 
                                        || (CurrentFloorElevatorOneIsAt > currentFloor + x && ElevatorOneCurrentMovingState == 1 ))))
                            begin
                                //find the nearest floor above the current floor that needs to be moved to and go that direction
    //                            $display("Less than 5 confirmed...");
                                if (DesiredoutsideFloorSelectionStates[currentFloor + x] == 1 || DesiredInsideStates[currentFloor + x] == 1)
                                    begin
                                        ElevatorThreeCurrentMovingState = 1;//change state to moving up
                                        GoUpTo = currentFloor + x;
    //                                    $display("ElevatorCurrentMovingState %d", ElevatorCurrentMovingState);
                                        x <= 5; //End the for loop, we found a floor
                                    end
                            end
                           
                        end
                     end
                end
            endcase
            if (ElevatorTurnControl)begin
                ElevatorTurnControl = ElevatorTurnControl + 1;
            end
        end
        else begin
            ElevatorTurnControl = 2'b0000;
        end

    end
    
    
    always @ (update or DesiredoutsideFloorSelectionStates or DesiredInsideStates)begin
 
        if (update)begin
            //if (LastInsideButton != InsideDesiredFloor)begin
            SelectedFloorsToGoTo = InsideDesiredFloor;
            if (InsideDesiredFloor != 0)begin
                //Find the floor the user requested
                LastInsideButton <= InsideDesiredFloor ;
                
                DesiredInsideStatesA2 = DesiredInsideStates;
                DesiredInsideStatesA2[SelectedFloorsToGoTo - 1] = 1;
//                setDesiredVariables = 1;
            end
            
            FloorCallingTheElevator = OutsideSelectedFloor;
            if(up)
                begin
                   DesiredoutsideFloorSelectionStatesA3 = DesiredoutsideFloorSelectionStates;
                   DesiredoutsideFloorSelectionStatesA3[FloorCallingTheElevator] = 1;
                   DesiredoutsideDirectionStatesA3 = DesiredoutsideDirectionStates;
                   DesiredoutsideDirectionStatesA3[FloorCallingTheElevator] = 1;
//                   setDesiredVariables = 1;
               end
            else if(down)
                begin
                    DesiredoutsideFloorSelectionStatesA3 = DesiredoutsideFloorSelectionStates;
                    DesiredoutsideFloorSelectionStatesA3[FloorCallingTheElevator] = 1;
                    DesiredoutsideDirectionStatesA3 = DesiredoutsideDirectionStates;
                    DesiredoutsideDirectionStatesA3[FloorCallingTheElevator] = 0;
//                    setDesiredVariables = 1;
                end   
            
            
        end
        else if(DesiredoutsideDirectionStates != DesiredoutsideDirectionStatesMonitor || DesiredInsideStates != DesiredInsideStatesMonitor) begin
        //The states are out of date, meaning a floor was reached in the clk always statement, update them here so that all the states are correct.
            DesiredoutsideDirectionStatesA3 = DesiredoutsideDirectionStates;
            DesiredoutsideFloorSelectionStatesA3 = DesiredoutsideFloorSelectionStates;
            DesiredInsideStatesA2 = DesiredInsideStates;
            
            //Set the "monitor" variables which tell the program whether the values of the states have changed and need to be updated
            DesiredoutsideDirectionStatesMonitor = DesiredoutsideDirectionStates;
            DesiredoutsideFloorSelectionStatesMonitor = DesiredoutsideFloorSelectionStates;
            DesiredInsideStatesMonitor = DesiredInsideStates;
        end
    end
    
    
    //initialize outputs
    assign DirectionState = DirectionStateReg;
   
    
    // Show the 7segment display for the current floor the elevator is at
    always @(posedge clk)
    begin
        case (SevenSegmentControl)
        2'b00: begin
            Anode_Activate = 4'b0111;//Activate left most digit of display
             case(CurrentFloorElevatorOneIsAt)
             5'b00000: DisplayFloorReg = 7'b0000001; // "0"  
             5'b00001: DisplayFloorReg = 7'b1001111; // "1" 
             5'b00010: DisplayFloorReg = 7'b0010010; // "2" 
             5'b00011: DisplayFloorReg = 7'b0000110; // "3" 
             5'b00100: DisplayFloorReg = 7'b1001100; // "4" 
             5'b00101: DisplayFloorReg = 7'b0100100; // "5" 
             5'b00110: DisplayFloorReg = 7'b0100000; // "6" 
             5'b00111: DisplayFloorReg = 7'b0001111; // "7" 
             5'b01000: DisplayFloorReg = 7'b0000000; // "8"  
             5'b01001: DisplayFloorReg = 7'b0000100; // "9" 
             default: DisplayFloorReg = 7'b0000001; // "0"
             endcase
             SevenSegmentControl = 2'b01;
        end
        2'b01:begin
             Anode_Activate = 4'b1011;//Activate second digit of display
             case(CurrentFloorElevatorTwoIsAt)
             5'b00000: DisplayFloorReg = 7'b0000001; // "0"  
             5'b00001: DisplayFloorReg = 7'b1001111; // "1" 
             5'b00010: DisplayFloorReg = 7'b0010010; // "2" 
             5'b00011: DisplayFloorReg = 7'b0000110; // "3" 
             5'b00100: DisplayFloorReg = 7'b1001100; // "4" 
             5'b00101: DisplayFloorReg = 7'b0100100; // "5" 
             5'b00110: DisplayFloorReg = 7'b0100000; // "6" 
             5'b00111: DisplayFloorReg = 7'b0001111; // "7" 
             5'b01000: DisplayFloorReg = 7'b0000000; // "8"  
             5'b01001: DisplayFloorReg = 7'b0000100; // "9" 
             default: DisplayFloorReg = 7'b0000001; // "0"
             endcase
             SevenSegmentControl = 2'b11;
        end
        2'b11:begin
            Anode_Activate = 4'b1101;//Activate third digit of display
             case(CurrentFloorElevatorThreeIsAt)
             5'b00000: DisplayFloorReg = 7'b0000001; // "0"  
             5'b00001: DisplayFloorReg = 7'b1001111; // "1" 
             5'b00010: DisplayFloorReg = 7'b0010010; // "2" 
             5'b00011: DisplayFloorReg = 7'b0000110; // "3" 
             5'b00100: DisplayFloorReg = 7'b1001100; // "4" 
             5'b00101: DisplayFloorReg = 7'b0100100; // "5" 
             5'b00110: DisplayFloorReg = 7'b0100000; // "6" 
             5'b00111: DisplayFloorReg = 7'b0001111; // "7" 
             5'b01000: DisplayFloorReg = 7'b0000000; // "8"  
             5'b01001: DisplayFloorReg = 7'b0000100; // "9" 
             default: DisplayFloorReg = 7'b0000001; // "0"
             endcase
             SevenSegmentControl = 2'b00;
        end    
        endcase

         //Anode_Activate = 4'b0001;//Activate whole display
    end

     assign DisplayFloor = DisplayFloorReg;
     assign OutsideLEDDebug = OutsideLEDDebugReg;
     assign InsideLEDDebug = InsideLEDDebugReg;
    
endmodule