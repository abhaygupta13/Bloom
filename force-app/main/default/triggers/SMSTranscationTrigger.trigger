trigger SMSTranscationTrigger on SMSTransaction__c (after insert,after update) {
  
    if(trigger.isUpdate && trigger.isAfter){
         SMSTranscationHandler.sendRetriedMessage(trigger.new,trigger.oldMap);
    } 
     if(trigger.isInsert && trigger.isAfter){
         SMSTranscationHandler.sendSMS(trigger.new);
    } 
    
}