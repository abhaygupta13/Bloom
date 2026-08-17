/***
Class       : PaymentInstallmentTriggerHelper
Author      : Dhanraj Poojary
Description : 
TestClass   : PaymentInstallmentsTriggerHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.       V1.0              20/08/25           Initial Version 
****************************************************************************************************************/

public class PaymentInstallmentTriggerHelper {
    
    
    public static void handleAfterUpdate(List<PaymentInstallments__c> newList, Map<Id, PaymentInstallments__c> oldMap) {
        Set<Id> paymentInstallmentIds = new Set<Id>();
        Map<Id, Date> paymentInstallmentDate = new Map<Id, Date>();
        List<InstallmentLines__c> lstInstallmentLines = new List<InstallmentLines__c>();
        InstallmentLineService objInstallmentLineService = InstallmentLineService.getInstance();
        
        for (PaymentInstallments__c objPayment : newList) {
            if (objPayment.RevisedDate__c != null && objPayment.RevisedDateVerified__c == true && objPayment.RevisedDateVerified__c != oldMap.get(objPayment.Id).RevisedDateVerified__c) {
                paymentInstallmentDate.put(objPayment.Id, objPayment.RevisedDate__c);
            }
        }       
        
        if(!paymentInstallmentDate.isEmpty()){
            lstInstallmentLines = objInstallmentLineService.getActiveInstallmentsByPaymentInstallmentIds(paymentInstallmentDate.keySet());
            if(!lstInstallmentLines.isEmpty()){
                for (InstallmentLines__c objIL : lstInstallmentLines) {
                    objIL.RevisedDate__c = paymentInstallmentDate.get(objIL.PaymentInstallments__c);
                }
            }
        }
        objInstallmentLineService.updateInstallmentLines(lstInstallmentLines);
    }
}