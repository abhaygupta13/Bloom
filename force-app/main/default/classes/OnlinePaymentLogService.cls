/***
Class       : OnlinePaymentLogService
Author      : Aman Bharti
Description : 
TestClass   : OnlinePaymentLogTriggerHelperTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.       V1.0              04/12/25           Initial Version 
****************************************************************************************************************/
public inherited sharing class OnlinePaymentLogService {
    
    private static OnlinePaymentLogService instance;
    
    private OnlinePaymentLogService() {
    }
    
    public static OnlinePaymentLogService getInstance() { 
        if(instance == null) {
            instance = new OnlinePaymentLogService();
        }
        return instance;
    }

    public List<OnlinePaymentLog__c> updateOnlinePaymentLog(List<OnlinePaymentLog__c > onlinePaymentLogList){
        if(onlinePaymentLogList != NULL && !onlinePaymentLogList.isEmpty()){
            update onlinePaymentLogList;
        }
        return onlinePaymentLogList; 
    } 
}