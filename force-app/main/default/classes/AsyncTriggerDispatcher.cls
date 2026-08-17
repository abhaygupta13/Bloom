/*
* @Author : Biswajeet Samal
* @CreatedDate : 7th AUG 2024
* @Description : Async Trigger framework dispatcher
*/
/*****************************************************************************************************
* Version       Author      Date             Comment                                                                       
* 1.0           Biswajeet   07AUG2024        Initial draft 
*****************************************************************************************************/
public class AsyncTriggerDispatcher {
    
    //Use this variable to disable all async triggers from transaction
    public static Boolean isAllAsyncTriggersDisabled = false;
    
    public static void disableAllAsyncTriggers() {
        isAllAsyncTriggersDisabled = true;
    }
    
    public static void enableAllAsyncTriggers() {
        isAllAsyncTriggersDisabled = false;
    }
    
    /*                                                  
* @description: It will invoke the appropriate methods on the handler depending on the trigger context
* @param: ITriggerHandler handler                                                       
* @return: void null
*/
    public static void run(IAsyncTriggerHandler handler){
        
        //Get the trigger bypass custom permission
        Boolean bypassAsyncTrigger = FeatureManagement.checkPermission('BypassAsyncTrigger');
        
        //Check if the trigger is disabled for the current user
        if (bypassAsyncTrigger){
            return;
        }
        
        //Check if the trigger is disabled
        if (handler.IsDisabled()){
            return;
        }
        
        //Check if the all triggers are disabled from the transaction
        if (isAllAsyncTriggersDisabled){
            return;
        }
        handler.changeEventCapture(Trigger.new);
        
        //Check trigger context from trigger operation type
        /*switch on header.changeType {
            when 'CREATE' {
                //Invoke before insert trigger handler
                handler.changeTypeCreate(header);
            }
            when 'UPDATE' {
                //Invoke after insert trigger handler
                handler.changeTypeUpdate(header);
            }
            when 'DELETE' {
                //Invoke before update trigger handler
                handler.changeTypeDelete(header);
            }
            when 'UNDELETE' {
                //Invoke after update trigger handler
                handler.changeTypeUndelete(header);
            }
        }*/
    }
}