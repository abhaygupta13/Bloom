@isTest
private class BatchToProcessCaseGeneralSRTest {

    private static Id gsrRecordTypeId() {
        return Utilities.getRecordTypeId('Case', 'Community General Service Request');
    }

    private static Id otherRecordTypeId() {
        // Try a commonly present record type; if missing, fallback to GSR so test remains stable.
        try {
            return Utilities.getRecordTypeId('Case', 'Resale');
        } catch (Exception e) {
            return gsrRecordTypeId();
        }
    }

    private static Case makeCase(String serviceName, String status, Date permitFrom, Id rtId) {
        // ServiceCatalogName__c is likely a formula; set via Service_Catalog__c
        Service_Catalog__c sc = new Service_Catalog__c(Name = serviceName, Active__c = true);
        insert sc;

        Case c = new Case(
            RecordTypeId = rtId,
            Status = status,
            Service_Catalog__c = sc.Id,
            Permit_From_Date__c = permitFrom
        );
        insert c;
        return c;
    }

    @isTest static void test_batch_updates_amenities_and_guest_requests() {
        Id rtGsr = gsrRecordTypeId();

        // Amenity older than 2 days, Submitted → Cancelled
        Case amenityOld = makeCase('Amenities', 'Submitted', Date.today().addDays(-3), rtGsr);
        // Amenity fresh → unchanged
        Case amenityFresh = makeCase('Amenities', 'Submitted', Date.today().addDays(-1), rtGsr);

        // Guest Management today & Approved → Completed
        Case guestTodayApproved = makeCase('Guest Management', 'Approved', Date.today(), rtGsr);
        // Guest Management other date → unchanged
        Case guestOtherDate = makeCase('Guest Management', 'Approved', Date.today().addDays(-1), rtGsr);

        // Case with other record type should not be picked up
        Case otherRt = makeCase('Amenities', 'Submitted', Date.today().addDays(-5), otherRecordTypeId());

        Test.startTest();
        Database.executeBatch(new BatchToProcessCaseGeneralSR(), 50);
        Test.stopTest();

        Map<Id, Case> fresh = new Map<Id, Case>([
            SELECT Id, Status, ServiceCatalogName__c, RecordTypeId, Permit_From_Date__c
            FROM Case
            WHERE Id IN :new List<Id>{ amenityOld.Id, amenityFresh.Id, guestTodayApproved.Id, guestOtherDate.Id, otherRt.Id }
        ]);

        System.assertEquals('Cancelled', fresh.get(amenityOld.Id).Status, 'Amenity old should be Cancelled');
        System.assertEquals('Submitted', fresh.get(amenityFresh.Id).Status, 'Amenity fresh should remain Submitted');
        System.assertEquals('Completed', fresh.get(guestTodayApproved.Id).Status, 'Guest today/Approved should be Completed');
        System.assertEquals('Approved', fresh.get(guestOtherDate.Id).Status, 'Guest other date should remain Approved');
        System.assertEquals('Submitted', fresh.get(otherRt.Id).Status, 'Other RT should be untouched');
    }
}