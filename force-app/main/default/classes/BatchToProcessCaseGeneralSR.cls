/**
 * Class: BatchToProcessCaseGeneralSR
 * Purpose: the batch require to run daily to check Amenities and Guest requests status
 *
 * Created By: Eaglesdev Dev
 * Created On: 2025-09-02
 *
 * 
 * 
 */
global class BatchToProcessCaseGeneralSR implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Get RecordTypeId for 'General Service Request'
        Id recordTypeId = Utilities.getRecordTypeId('Case', 'Community General Service Request');

        return Database.getQueryLocator([
            SELECT Subject, ServiceCatalogName__c,Status,Permit_From_Date__c
            FROM Case
            WHERE RecordTypeId = :recordTypeId
            AND IsClosed = FALSE
        ]);
    }

    global void execute(Database.BatchableContext BC, List<Case> scope) {
        List<Case> filteredCases = new List<Case>();

        for (Case c : scope) {
            if (c.ServiceCatalogName__c == 'Amenities' && c.Status == 'Submitted' && c.Permit_From_Date__c < Date.today().addDays(-2)) {
               c.status = 'Cancelled';
               filteredCases.add(c);
            }
            else if(c.ServiceCatalogName__c == 'Guest Management' && c.Permit_From_Date__c == Date.today() && c.status=='Approved'){
                c.status = 'Completed';
                filteredCases.add(c);
            }
        }

        if (!filteredCases.isEmpty()) {
            update filteredCases;
        }
    }

    global void finish(Database.BatchableContext BC) {
    }
}