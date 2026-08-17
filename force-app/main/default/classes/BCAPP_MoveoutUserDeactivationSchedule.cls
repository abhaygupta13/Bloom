//============================ BCAPP_MoveoutUserDeactivationSchedule =============================
/*
* @Author : Eagles  
* @CreatedDate : 04 Sept 2024
* @Name : BCAPP_MoveoutUserDeactivationSchedule
* @Description : Scheduleclass for BCAPP_MoveoutUserDeactivationBatch
*/
/*****************************************************************************************************
* Version       Author                  Date             Comment                                                                       
* 1.0           Eagles               28 OCT 2024        Initial draft 
*****************************************************************************************************/

global class BCAPP_MoveoutUserDeactivationSchedule implements schedulable{

    global void execute(schedulablecontext sc){
        BCAPP_MoveoutUserDeactivationBatch batch = new BCAPP_MoveoutUserDeactivationBatch();
        database.executebatch(batch,1);
    }
}