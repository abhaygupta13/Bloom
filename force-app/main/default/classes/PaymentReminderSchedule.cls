/***
Class       : PaymentReminderBatch
Author      : Smaartt
Description : 
TestClass   : PaymentReminderBatchTest
Execution   :  new PaymentReminderSchedule().execute(null);
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.        V1.0              29/01/24           Initial Version 
****************************************************************************************************************/

public class PaymentReminderSchedule implements Schedulable {

    public void execute(SchedulableContext SC) {
        Date twentyDaysLater = Date.today().addDays(integer.valueOf(label.paymentReminderSchedule_Days));
        system.debug(twentyDaysLater);
        List<InstallmentLines__c> toBeUpdateInsatllmentList = new List<InstallmentLines__c>();
        
        List<InstallmentLines__c> recordsToUpdate = [
            SELECT Id, Payment_reminder_batches__c,SalesOrder__r.Status__c, InstallmentAmount__c,Milestone__c,PaymentInstallments__r.Milestone__C, RevisedDate__c, InstallmentDate__c, ClearedAmount__c 
            FROM InstallmentLines__c 
            WHERE Payment_reminder_batches__c = null AND SalesOrder__r.Status__c ='Sold'  
            AND ((InstallmentDate__c=:twentyDaysLater AND RevisedDate__c= null) OR (RevisedDate__c != null AND RevisedDate__c=:twentyDaysLater))
            AND PaymentInstallments__r.Milestone__r.Milestone_Status__c='Reached'
            
        ];
        
        
        Set<Id> milestoneIdSet = new Set<Id>();
        List<Payment_reminder_batches__c> PmbList = new List<Payment_reminder_batches__c>();
        List<InstallmentLines__c> toBeUpdateInstallmentList = new List<InstallmentLines__c>();
        if (!recordsToUpdate.isEmpty()) {
            for (InstallmentLines__c instl : recordsToUpdate) {
                
                    milestoneIdSet.add(instl.PaymentInstallments__r.Milestone__C);
                
            }

            for (Id milestoneId : milestoneIdSet) { 
                Payment_reminder_batches__c pmb = new Payment_reminder_batches__c();
                pmb.Status__c = 'Approved';
                pmb.Milestone__c = milestoneId;
                PmbList.add(pmb);   
            }

            if (!PmbList.isEmpty()) {
                insert PmbList;  
            }

            if (!PmbList.isEmpty()) {
                for (InstallmentLines__c instl : recordsToUpdate) {
                    for (Payment_reminder_batches__c pmb : PmbList) {
                        if (instl.PaymentInstallments__r.Milestone__c == pmb.Milestone__c) {
                            instl.Payment_reminder_batches__c = pmb.Id;
                            toBeUpdateInstallmentList.add(instl);
                        }
                    }
                }
            }

            database.update(toBeUpdateInstallmentList, false);
        }
    }
}