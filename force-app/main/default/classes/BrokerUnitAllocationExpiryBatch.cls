/*
* @Author      : Akshay Khairnar
* @Description : Batch class to set Broker Unit Allocations records to In-Active
*                once the End Date Time is reached on the Broker Unit Allocation.
*                (Assignment + Unit updates are now handled by trigger)
* Test Apex: BrokerUnitAllocationExpiryBatchTest           
*****************************************************************************************************/
global class BrokerUnitAllocationExpiryBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        Datetime now = System.now();
        
        return Database.getQueryLocator([SELECT Id, EndDate__c, IsActive__c, Unit__c FROM BrokerUnitAllocations__c WHERE IsActive__c = true AND EndDate__c <= :now]);
    }

    global void execute(Database.BatchableContext bc, List<BrokerUnitAllocations__c> allocations) {
        if (allocations.isEmpty()) return;

        // Only deactivate BrokerUnitAllocations__c
        for (BrokerUnitAllocations__c alloc : allocations) {
            alloc.IsActive__c = false;
        }

        BrokerUnitAllocationService.getInstance().updateBrokerUnitAllocations(allocations);

    }

    global void finish(Database.BatchableContext bc) {
        System.debug('BrokerUnitAllocationExpiryBatch completed successfully.');
    }
}