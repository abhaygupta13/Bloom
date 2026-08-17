/***
Class       : TaskUtilityHandler
Author      : Smaartt
Description : 
TestClass   : TaskUtilityHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              27/04/23           Initial Version 
****************************************************************************************************************/
public class TaskUtilityHandler {
    Public Static TaskWrapper getTaskConfigDetails(String status,Integer orderNo){
        Task_Configure_Details__mdt tcd = [select id,Label,Call_Order__c,Day__c,Status__c,Time_hr__c From Task_Configure_Details__mdt where Call_Order__c =: orderNo And Status__c =:status];
        datetime localTime = system.now();
        Long sla = decimal.valueOf(integer.valueof(tcd.Time_hr__c)).longValue();
        sla = sla * 60 *60000;
        TaskWrapper tw = new TaskWrapper();
        tw.taskSubject = String.valueof(tcd.Label);
        tw.slaTime = BusinessHours.add(CustomLabelUtility.BusinessHoursID, localTime, sla);
        return tw;
        
    }
    public class TaskWrapper{
       public String taskSubject;
       public  Datetime slaTime;
         
    
    
}
}