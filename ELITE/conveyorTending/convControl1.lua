-- State Machine n#
-- 2024/08/22

-- Variable Setup -------------------------------------------------------------------------------
-- io list
-- input signals
local bufferOut="I4"  -- sensor in the buffer out gate
local workIn="I6" -- sensor in the robot working position
local otherBufferIn="I9" -- sensor in the entry of the next section bufer
-- output
local bufferStop="O0" -- locking actuater of buffer output
local workStop="O2" -- locking actuator of work position output

-- global variables
readyToWork="B001" -- internal variable seting if the work position is ready for the robot to work
robotDone="B002" -- internal variable to get if robot finished work

-- Inetialization ----------------------------------------------------------------------------------
-- Script Variables
local stateValue=0 -- value of state
local startDelay = 3 -- Delay value for the start
local notWorkDelay = 1 -- Delay value for the start
local stateMachNum = 1 -- number for the conveyor secttion 


while(1)do
    
    elite_print("Ready")
    stateValue=0
    -- Initialization of variables
    set_global_variable (readyToWork,0)
    set_global_variable (robotDone,0)
    set_robot_io_status (workStop,0)
    set_robot_io_status (bufferStop,0)

    while get_robot_io_status("M550")==1 and get_robot_io_status("M417")==1 do
        elite_print("Running")
        if stateValue==0 then
            elite_print("in State ", stateValue," on section: ", stateMachNum)



            -- wait 3 seconds
            sleep (startDelay)

            if get_robot_io_status (workIn)==0 then 
                -- set variable for the robot to start
                set_robot_io_status (bufferStop,1)
            end
			
			sleep (notWorkDelay)
            set_robot_io_status (bufferStop,0)
			-- set next case
			stateValue=1



        elseif stateValue==1 then
            elite_print("in State ", stateValue," on section: ", stateMachNum)
            -- if work area has part
            if get_robot_io_status (workIn)==1 then 
                -- set variable for the robot to start
                set_global_variable (readyToWork,1)
            end

            -- if robot as finished the pick
            if get_global_variable (robotDone)==1 then
                -- go to new case
                stateValue=2
            end

        elseif stateValue==2 then
            elite_print("in State ", stateValue," on section: ", stateMachNum)
            
            -- reinitializa robotdone variable
            set_global_variable (robotDone,0)
			
            -- if work area has part
            if ((get_robot_io_status (workIn)==1) ) then
                -- if the next section bufer is not full
                if  (get_robot_io_status (otherBufferIn) == 0) then
                    -- open the work position locker
                    set_robot_io_status (workStop,1)
                    -- initializa the ready to work variable
                    set_global_variable (readyToWork,0)
                end
            end

            -- if the is no  part in the work position
            if get_robot_io_status (workIn)==0 then
                -- close the locker
                set_robot_io_status (workStop,0)
                -- set new state
                stateValue=3
            end
            
        elseif stateValue==3 then
            elite_print("in State ", stateValue," on section: ", stateMachNum)

            -- if there is a part in the buffer
            if get_robot_io_status (bufferOut)==1 then
                -- open bufer locker
                set_robot_io_status (bufferStop,1)
                --set new state
                stateValue=4
            end


        elseif stateValue==4 then
            elite_print("in State ", stateValue," on section: ", stateMachNum)
            -- if there is no part in the bufer
            if get_robot_io_status (bufferOut)==0 then
                -- close the buffer
                set_robot_io_status (bufferStop,0)
                -- go back to initial state
                stateValue=1
            end

        else
            -- unknown state reached
            elite_print("Read error")
            stateValue=0
        
        end

        sleep (0.1) 
    end
    -- clocking delay
    sleep (1)  

end