/*
* @Author : Dhanraj Poojary
* @CreatedDate : 4th MAY 2026
* @Description : Payment Installment Service class
*/
/*****************************************************************************************************
* Version       Author      Date             Comment                                                                       
* 1.0           Dhanraj   04MAY2026        Initial draft 
*****************************************************************************************************/
public inherited sharing class PaymentInstallmentService {
    private static PaymentInstallmentService instance;
    
    public PaymentInstallmentService() {}
    
    public static PaymentInstallmentService getInstance() {
        if(instance == null) {
            instance = new PaymentInstallmentService();
        }
        return instance;
    }
    
    public List<PaymentInstallments__c> getPaymentInstallmentsById(Set<Id> paymentPlanId){
        return [SELECT Id,PaymentPlan__c,RevisedDate__c,RevisedDateUpdated__c FROM PaymentInstallments__c WHERE PaymentPlan__c IN: paymentPlanId AND RevisedDateUpdated__c = TRUE];
    }
    
    public List<PaymentInstallments__c> getPaymentInstallmentsByPaymentPlanId(Id paymentPlanId){
        return [SELECT Id,Name,InstallmentNumber__c,InstallmentPercentage__c,InstallmentDate__c,RevisedDate__c,Milestone__c,Description__c,ChequeReplacement__c,DueDate__c,InstallmentType__c FROM PaymentInstallments__c WHERE PaymentPlan__c = :paymentPlanId ORDER BY InstallmentNumber__c];
    }
    
    public List<PaymentInstallments__c> insertPaymentInstallments(List<PaymentInstallments__c> lstPaymentInstallments) {
        if(lstPaymentInstallments != NULL && !lstPaymentInstallments.isEmpty()){
            insert lstPaymentInstallments;
        }
        return lstPaymentInstallments;
    }
    
    public List<PaymentInstallments__c> updatepaymentInstallmentLists(List<PaymentInstallments__c> paymentInstallmentList){
        if(paymentInstallmentList != NULL && !paymentInstallmentList.isEmpty()){
            Database.update(paymentInstallmentList, true);
        }
        return paymentInstallmentList;
    }
    
    public List<PaymentInstallments__c> updatePaymentInstallmentWithoutTrigger(List<PaymentInstallments__c> paymentInstallmentList){
        if(paymentInstallmentList != NULL && !paymentInstallmentList.isEmpty()){
            PaymentInstallmentTriggerHandler.isTriggerDisabled = true;
            update paymentInstallmentList;
            PaymentInstallmentTriggerHandler.isTriggerDisabled = false;
        }
        return paymentInstallmentList;
    } 
}