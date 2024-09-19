-- State Machine n#
-- 2024/08/22

-- Variable Setup -------------------------------------------------------------------------------
-- io list
-- input signals
local bufferOut="I7"  -- sensor in the buffer out gate
local workIn="I5" -- sensor in the robot working position
local otherBufferIn="I8" -- sensor in the entry of the next section bufer

local bufferSend="I20"
local counterMax="D010"
-- output
local bufferStop="O3" -- locking actuater of buffer output
local workStop="O1" -- locking actuator of work position output

-- second robot setup
-- global variables
readyToWork="M561" -- inout to set if the work position is ready for the robot to work
robotDone="M562" -- input to get if robot finished work

hasRobot ="M530" -- if this variable is on, there is a second robot

-- Inetialization ----------------------------------------------------------------------------------
-- Script Variables
 stateValue=-1-- value of state
 startDelay = 10 -- Delay value for the start
 lockDelay = 1 -- Delay value for the start
stateMachNum = 2 -- number for the conveyor secttion 

systemOn="M550"
jobRunning="M427"

while(1)do
    
    stateValue=-1
    -- Initialization of variables
    set_robot_io_status (readyToWork,0)
    set_robot_io_status (robotDone,0)
    set_robot_io_status (workStop,0)
    set_robot_io_status (bufferStop,0)

    -- if job runing and system is on (button has been pressed to start)
    while get_robot_io_status(systemOn)==1 and get_robot_io_status(jobRunning)==1 do
        
        if stateValue==-1 then
            sleep (startDelay)
            if get_robot_io_status (workIn)==0 then 
                -- set variable for the robot to start
                set_robot_io_status(bufferStop,1)
				sleep (lockDelay)
            end
			
            set_robot_io_status (bufferStop,0)
			-- set next case
			stateValue=0

        elseif stateValue==0 then
            -- if cart has not arrived to the work location way more time
            if (get_robot_io_status (workIn)==0) then
				sleep (startDelay)
			
			end
            if get_robot_io_status (workIn)==0 then
                stateValue=-1 
            else
                stateValue=1 
            end

        elseif stateValue==1 then
          
            -- if work area has part
            if get_robot_io_status (workIn)==1 then 
                -- set variable for the robot to start
                set_robot_io_status (readyToWork,1)
            end

            -- if robot as finished the pick
            if get_robot_io_status (robotDone)==1 or (get_robot_io_status (hasRobot)==0 and (get_robot_io_status (workIn)==1) ) then
                -- go to new case
                stateValue=2
            end

        elseif stateValue==2 then
           
            -- reinitializa robotdone variable
            set_robot_io_status (robotDone,0)
			
            -- if work area has part
            if ((get_robot_io_status (workIn)==1) ) then
                -- if the next section bufer is not full
                if  (get_robot_io_status (otherBufferIn) == 0) then
                    -- open the work position locker
                    set_robot_io_status (workStop,1)
                    -- initializa the ready to work variable
                    set_robot_io_status (readyToWork,0)
                    stateValue=3
                end
            end

        elseif stateValue==3 then 
		
            -- if the is no  part in the work position
            if get_robot_io_status (workIn)==0 then
                -- close the locker
                sleep (lockDelay)
                set_robot_io_status (workStop,0)
                -- set new state
                stateValue=4
            end
            
        elseif stateValue==4 then

            countHoldButton=0
            while get_robot_io_status (bufferSend)==0 and countHoldButton<get_global_variable (counterMax) do
                sleep(1)
                countHoldButton=countHoldButton+1
            end
            
            -- if there is a part in the buffer
            if get_robot_io_status (bufferOut)==1 then
                -- open bufer locker
                set_robot_io_status (bufferStop,1)

                --set new state
                stateValue=5
            end

        elseif stateValue==5 then
            -- if there is no part in the bufer
            if get_robot_io_status (bufferOut)==0 then
            --    -- close the buffer
				sleep (lockDelay)
                set_robot_io_status (bufferStop,0)
            --    -- go back to initial state
				stateValue=1
            end

        else
            --- unknown state reached
            elite_print("Read error")
            stateValue=-1
       
        end

        sleep (0.1) 
    end
    -- clocking delay
    sleep (1)  

end