/***
Class       : OnlinePaymentLogTriggerHandler 
Author      : Biswajeet
Description : 
TestClass   : OnlinePaymentLogTriggerHelperTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date          Author       Details
1.          V1.0              27/04/23                  Initial Version 
****************************************************************************************************************/
public without sharing class OnlinePaymentLogTriggerHelper {
    
    private static final String SUCCESS_STR { get { return 'Success'; } }
    
    
    public static void handleAfterInsert(List<OnlinePaymentLog__c> newList) {
        
        OnlinePaymentLogHandler objOnlinePaymentLogHandler = OnlinePaymentLogHandler.getInstance();
        List<OnlinePaymentLog__c> paymentLogSuccessList = new List<OnlinePaymentLog__c>(); 

        for(OnlinePaymentLog__c paymentlog : newList){
            if(paymentlog.TransactionStatus__c == SUCCESS_STR && String.isNotBlank(paymentLog.JSONData__c) && paymentlog.Contact__c != null){
                paymentLogSuccessList.add(paymentlog);
            }
        }
        //process payment and email to contact
        objOnlinePaymentLogHandler.processPayment(paymentLogSuccessList);
    }
}