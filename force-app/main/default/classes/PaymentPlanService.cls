/*
* @Author : Biswajeet Samal
* @CreatedDate : 7th AUG 2024
* @Description : Payment Plan Service class
* TestClass   : PaymentPlanServiceTest
*/
/*****************************************************************************************************
* Version       Author      Date             Comment                                                                       
* 1.0           Biswajeet   07AUG2024        Initial draft 
*****************************************************************************************************/
public inherited sharing class PaymentPlanService {
    
    private static PaymentPlanService instance;
    
    public PaymentPlanService() {}
    
    public static PaymentPlanService getInstance() {
        if(instance == null) {
            instance = new PaymentPlanService();
        }
        return instance;
    }
    
    //Get Payment Plans by project id
    public List<PaymentPlan__c> getPaymentPlansByProjectId(Id projectId){
        return [SELECT Id, Name FROM PaymentPlan__c WHERE Project__c = :projectId];
    }
    
    //Get Payment Plans by project id & customer type
    public List<PaymentPlan__c> getPaymentPlans(Id projectId, String customerType){
        return [SELECT Id, Name FROM PaymentPlan__c WHERE Project__c = :projectId AND CustomerSubType__c = :customerType AND IsActive__c = 'Yes'];
    }
    
    //Get Payment Plans by Ids
    public List<PaymentPlan__c> getPaymentPlansByIds(Set<Id> paymentPlanIds){
        return [SELECT Id, Name, Project__r.Name,Unit__r.Project__r.Name, OwnerId FROM PaymentPlan__c WHERE Id IN :paymentPlanIds];
    }
    
    //Get Payment Plans by Project Id
    public List<PaymentPlan__c> getClassificationFromPaymentPlan(Id projectId){
        return [SELECT Classification__c FROM PaymentPlan__c WHERE Project__c = :projectId AND Classification__c != NULL];
    }
    
    //Get Payment Plans by project id & classification
    public List<PaymentPlan__c> getPaymentPlansClassification(Id projectId, String classification){
        return [SELECT Id, Name, CreatedDate, IsActive__c FROM PaymentPlan__c WHERE Project__c = :projectId AND Classification__c = :classification];
    }
    
    public PaymentPlan__c insertPaymentPlan(PaymentPlan__c objPaymentPlan){
        if(objPaymentPlan != NULL){
            insert objPaymentPlan;
        }
        return objPaymentPlan;
    }
    
    public PaymentPlan__c updatePaymentPlan(PaymentPlan__c objPaymentPlan){
        if(objPaymentPlan != NULL){
            update objPaymentPlan;
        }
        return objPaymentPlan;
    }
}