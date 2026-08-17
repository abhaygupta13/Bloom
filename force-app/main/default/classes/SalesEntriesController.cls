public with sharing class SalesEntriesController {

    @AuraEnabled
public static SalesEntriesWrapper getSalesEntries(Id leasingOrderId) {

    SalesEntriesWrapper wrapper = new SalesEntriesWrapper();

    LeasingOrder__c order = [
        SELECT MasterLeasingOrder__c
        FROM LeasingOrder__c
        WHERE Id = :leasingOrderId
    ];

    // Current Leasing Order Sales Entries
    wrapper.currentSalesEntries = [
        SELECT Id,
               Name,
               Year__c,
               Month__c,
               ActualSales__c,
               AuditedSales__c,
               ActualSalesLock__c,
               AuditedSalesLock__c
        FROM SalesEntrie__c
        WHERE LeasingOrder__c = :leasingOrderId
        ORDER BY Year__c, Month__c
    ];

    // Master Leasing Order Sales Entries
    wrapper.masterSalesEntries = new List<SalesEntrie__c>();

    if(order.MasterLeasingOrder__c != null){

        wrapper.masterSalesEntries = [
            SELECT Id,
                   Name,
                   Year__c,
                   Month__c,
                   ActualSales__c,
                   AuditedSales__c,
                   ActualSalesLock__c,
                   AuditedSalesLock__c
            FROM SalesEntrie__c
            WHERE LeasingOrder__c = :order.MasterLeasingOrder__c
            ORDER BY Year__c, Month__c
        ];
    }

    return wrapper;
}

    @AuraEnabled
public static void saveSalesEntries(List<SalesEntrie__c> salesEntries) {

    if (salesEntries == null || salesEntries.isEmpty()) {
        return;
    }

    Map<Id, SalesEntrie__c> existingRecords = new Map<Id, SalesEntrie__c>(
        [
            SELECT Id,
                   ActualSalesLock__c,
                   AuditedSalesLock__c
            FROM SalesEntrie__c
            WHERE Id IN :salesEntries
        ]
    );

    List<SalesEntrie__c> recordsToUpdate = new List<SalesEntrie__c>();

    for (SalesEntrie__c entry : salesEntries) {

        SalesEntrie__c existing = existingRecords.get(entry.Id);

        if (existing == null) {
            continue;
        }

        SalesEntrie__c updateRecord = new SalesEntrie__c(
            Id = entry.Id
        );

        // ==========================
        // Actual Sales
        // ==========================

        if (!existing.ActualSalesLock__c) {

            updateRecord.ActualSales__c = entry.ActualSales__c;

            if (entry.ActualSalesLock__c &&
                entry.ActualSales__c == null) {

                throw new AuraHandledException(
                    'Actual Sales must be entered before locking Actual Sales.'
                );
            }

            updateRecord.ActualSalesLock__c = entry.ActualSalesLock__c;
        }

        // ==========================
        // Audited Sales
        // ==========================

        if (!existing.AuditedSalesLock__c) {

            updateRecord.AuditedSales__c = entry.AuditedSales__c;

            if (entry.AuditedSalesLock__c &&
                entry.AuditedSales__c == null) {

                throw new AuraHandledException(
                    'Audited Sales must be entered before locking Audited Sales.'
                );
            }

            updateRecord.AuditedSalesLock__c = entry.AuditedSalesLock__c;
        }

        recordsToUpdate.add(updateRecord);
    }

    if (recordsToUpdate.isEmpty()) {
        return;
    }

    Database.SaveResult[] results = Database.update(recordsToUpdate, false);

    for (Database.SaveResult sr : results) {

        if (!sr.isSuccess()) {
            throw new AuraHandledException(sr.getErrors()[0].getMessage());
        }
    }
}
}