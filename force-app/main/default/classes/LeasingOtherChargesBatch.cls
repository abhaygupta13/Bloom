/*****************************************************************************************
Class       : LeasingOtherChargesBatch
Author      : Kalpana
Description : Batch to update SendToSAP__c = true for PaymentPlanSchedule__c records 
where DueDate__c = Today.
Created Date: 
*****************************************************************************************/
public without sharing class LeasingOtherChargesBatch implements Database.Batchable<SObject>,Schedulable {
    private static final Integer BATCH_SIZE = 20;
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query =
            'SELECT Id, Name, DueDate__c, SendToSAP__c, PaymentStatus__c, LeasingOrder__r.IntegrationStatus__c, LeasingOrder__r.IntegrationMessage__c  ' +
            'FROM LeasingOrdersOtherCharges__c ' +
            'WHERE DueDate__c = TODAY ' +
            'AND PaymentStatus__c = \'Not Invoiced\' ' +
            'AND LeasingOrder__r.IntegrationStatus__c NOT IN (\'In Progress\', \'Failed\')';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<LeasingOrdersOtherCharges__c> scope) {
        if (scope == null || scope.isEmpty()) {
            return; 
        }
        for (LeasingOrdersOtherCharges__c rec : scope) {
            if(rec.LeasingOrder__r.IntegrationMessage__c != null)
                rec.SendToSAP__c = true;
        }
        
        LeasingOtherChargesService.getInstance().updateLeasingOtherCharges(scope);
    }
    
    public void finish(Database.BatchableContext bc) {
    }
    
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new LeasingOtherChargesBatch(), BATCH_SIZE);
    }
}