/***
Class       : LatePaymentFeeService
Author      : Dhanraj Poojary
Description : 
TestClass   : LatePaymentFeeBatchTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  Version              Date                Details
1.       V1.0              03/01/25           Initial Version 
****************************************************************************************************************/

public inherited sharing class LatePaymentFeeService {
    
    private static LatePaymentFeeService instance;
    
    private LatePaymentFeeService() {
    }
    
    public static LatePaymentFeeService getInstance() { 
        if(instance == null) {
            instance = new LatePaymentFeeService();
        }
        return instance;
    }
    
    public List<LatePaymentFee__c> insertLatePaymentFeeLists(List<LatePaymentFee__c> latePaymentFeeList){
        if(latePaymentFeeList != NULL && !latePaymentFeeList.isEmpty()){
            insert latePaymentFeeList;
        }
        return latePaymentFeeList;
    }
}