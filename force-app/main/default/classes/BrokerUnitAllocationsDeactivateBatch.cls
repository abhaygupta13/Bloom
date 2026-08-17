/*
* @Author : Akshay Khairnar
* @CreatedDate : 17th AUG 2025
* @Description : To deactivate the BrokerUnitAllocations
*****************************************************************************************************/
global class BrokerUnitAllocationsDeactivateBatch implements Database.Batchable<SObject>, Database.Stateful {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        // Query all active BrokerUnitAllocations__c where UnitStatus__c != 'Available'
        return Database.getQueryLocator([
            SELECT Id, UnitStatus__c
            FROM BrokerUnitAllocations__c
            WHERE IsActive__c = true
            AND UnitStatus__c != 'Available'
        ]);
    }

    global void execute(Database.BatchableContext bc, List<BrokerUnitAllocations__c> allocationList) {
        List<BrokerUnitAllocations__c> allocationsToUpdate = new List<BrokerUnitAllocations__c>();
        List<BrokerUnitAssignment__c> assignmentsToUpdate = new List<BrokerUnitAssignment__c>();

        // Collect all allocation Ids to query related BrokerUnitAssignment__c records
        Set<Id> allocationIds = new Set<Id>();
        for (BrokerUnitAllocations__c alloc : allocationList) {
            alloc.IsActive__c = false;
            allocationsToUpdate.add(alloc);
            allocationIds.add(alloc.Id);
        }

        if (!allocationIds.isEmpty()) {
            // Query related BrokerUnitAssignment__c records
            for (BrokerUnitAssignment__c assignment : [
                SELECT Id, Active__c
                FROM BrokerUnitAssignment__c
                WHERE BrokerUnitAllocation__c IN :allocationIds
                AND Active__c = true
            ]) {
                assignment.Active__c = false;
                assignmentsToUpdate.add(assignment);
            }
        }

        // Perform updates
        if (!allocationsToUpdate.isEmpty()) {
            update allocationsToUpdate;
        }
        if (!assignmentsToUpdate.isEmpty()) {
            update assignmentsToUpdate;
        }
    }

    global void finish(Database.BatchableContext bc) {
        // Optionally add logging or notifications
        System.debug('BrokerUnitAllocationDeactivationBatch completed successfully.');
    }
}