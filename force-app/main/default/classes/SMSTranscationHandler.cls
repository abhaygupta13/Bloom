public class SMSTranscationHandler {   
    
    public static void sendSMS(list<SMSTransaction__c> trgNew){
        set<id> smsIds = new set<id>();
        for(SMSTransaction__c sms : trgNew){
            if(sms.Send_SMS__c)
                smsIds.add(sms.Id);
        }
        if(smsIds.size()>0 ){
            sendSMSCalloutHandler.sendSMS(smsIds);
        }
    }
     public static void sendRetriedMessage(list<SMSTransaction__c> trgNew,Map<id,SMSTransaction__c> oldMap){
        set<id> smsIds = new set<id>();
        for(SMSTransaction__c sms : trgNew){
            if(sms.Send_SMS__c && sms.Status__c=='Retry' && oldMap.get(sms.id).Status__c != sms.Status__c && oldMap.get(sms.id).Status__c == 'Failed' )
                smsIds.add(sms.Id);
        }
        if(smsIds.size()>0 ){
            sendSMSCalloutHandler.sendSMS(smsIds);
        }
    }
    
}