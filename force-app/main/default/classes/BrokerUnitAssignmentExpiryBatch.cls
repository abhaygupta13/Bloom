global class BrokerUnitAssignmentExpiryBatch implements Database.Batchable<SObject>, Database.Stateful {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        // Fetch only active assignments that have expired
        return Database.getQueryLocator([
            SELECT Id, ExpiryDate__c, Active__c,
                   BrokerUnitAllocation__c,
                   BrokerUnitAllocation__r.Unit__c
            FROM BrokerUnitAssignment__c
            WHERE Active__c = true
              AND ExpiryDate__c <= :Date.today()
              AND BrokerUnitAllocation__r.Unit__c != null
        ]);
    }

    global void execute(Database.BatchableContext bc, List<BrokerUnitAssignment__c> scope) {
        List<BrokerUnitAssignment__c> assignmentsToUpdate = new List<BrokerUnitAssignment__c>();
        Set<Id> unitIdsToUpdate = new Set<Id>();

        for (BrokerUnitAssignment__c bua : scope) {
            bua.Active__c = false;
            assignmentsToUpdate.add(bua);

            if (bua.BrokerUnitAllocation__r.Unit__c != null) {
                unitIdsToUpdate.add(bua.BrokerUnitAllocation__r.Unit__c);
            }
        }

        if (!assignmentsToUpdate.isEmpty()) {
            update assignmentsToUpdate;
        }

        if (!unitIdsToUpdate.isEmpty()) {
            List<Unit__c> unitsToUpdate = [
                SELECT Id, IsExclusive__c
                FROM Unit__c
                WHERE Id IN :unitIdsToUpdate
            ];
            for (Unit__c unit : unitsToUpdate) {
                unit.IsExclusive__c = false;
            }
            update unitsToUpdate;
        }
    }

    global void finish(Database.BatchableContext bc) {
        // Optional: Send email / log job status
    }
}