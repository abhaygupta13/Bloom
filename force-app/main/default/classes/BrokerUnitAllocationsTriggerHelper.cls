public class BrokerUnitAllocationsTriggerHelper {

    public static void handleAfterUpdate(
        List<BrokerUnitAllocations__c> newList,
        Map<Id, BrokerUnitAllocations__c> newMap,
        List<BrokerUnitAllocations__c> oldList,
        Map<Id, BrokerUnitAllocations__c> oldMap
    ) {

        Datetime now = System.now();

        Set<Id> allocationIdsToDeactivate = new Set<Id>();
        Set<Id> unitIdsToRelease = new Set<Id>();

        // Identify Allocations that became inactive OR whose EndDate__c has passed
        for (BrokerUnitAllocations__c newRec : newList) {
            BrokerUnitAllocations__c oldRec = oldMap.get(newRec.Id);

            Boolean endDateReached = (newRec.EndDate__c != null && newRec.EndDate__c <= now);
            Boolean wasActive = oldRec.IsActive__c == true && newRec.IsActive__c == false;

            if (endDateReached || wasActive) {

                allocationIdsToDeactivate.add(newRec.Id);

                if (newRec.Unit__c != null) {
                    unitIdsToRelease.add(newRec.Unit__c);
                }
            }
        }

        // ----- No relevant allocations -----
        if (allocationIdsToDeactivate.isEmpty() && unitIdsToRelease.isEmpty()) {
            return;
        }


        // 1. Deactivate BrokerUnitAssignment__c
        // 
        List<BrokerUnitAssignment__c> assignments =
            BrokerUnitAssignmentService.getInstance().getBrokerUnitAssignByAllocationIds(allocationIdsToDeactivate);

        for (BrokerUnitAssignment__c a : assignments) {
            a.Active__c = false;
        }

        if (!assignments.isEmpty()) {
            BrokerUnitAssignmentService.getInstance().updateBrokerUnitAssignments(assignments);
        }

        // 2. Release Units (IsExclusive__c = false)
        if (!unitIdsToRelease.isEmpty()) {

            List<Unit__c> units =
                UnitService.getInstance().getUnitsByIds(unitIdsToRelease);

            for (Unit__c u : units) {
                u.IsExclusive__c = false;
            }

            if (!units.isEmpty()) {
                UnitService.getInstance().updateExistingUnits(units);
            }
        }
    }
}