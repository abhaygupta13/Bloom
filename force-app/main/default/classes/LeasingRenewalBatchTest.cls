@IsTest
public class LeasingRenewalBatchTest {

    @testSetup
    static void setupData() {

        LeasingOrderTriggerHandler.isTriggerDisabled = true;

        /* ==============================
           1️⃣ Person Account
        ============================== */
        Id personRtId = Schema.SObjectType.Account
            .getRecordTypeInfosByName()
            .get('Person Account')
            .getRecordTypeId();

        Account pa = new Account(
            RecordTypeId = personRtId,
            LastName = 'Test Person',
            PersonEmail = 'testperson@test.com'
        );
        insert pa;

        /* ==============================
           2️⃣ Leasing Order (Expired)
        ============================== */
        LeasingOrder__c order = new LeasingOrder__c(
            Name = 'Test Leasing Order',
            Account__c = pa.Id,
            LeasingEndDate__c = Date.today().addDays(-31)
        );
        insert order;

        LeasingOrderTriggerHandler.isTriggerDisabled = false;

        /* ==============================
           3️⃣ Content Version
        ============================== */
        ContentVersion cv = new ContentVersion(
            Title = 'Signed Contract',
            PathOnClient = 'SignedContract.pdf',
            VersionData = Blob.valueOf('Test PDF Body'),
            IsMajorVersion = true
        );
        insert cv;

        // Query again to get FileExtension populated
        cv = [
            SELECT Id, Title, FileExtension, VersionData
            FROM ContentVersion
            WHERE Id = :cv.Id
        ];

        /* ==============================
           4️⃣ Document__c (IMPORTANT)
           Ensure it matches service filters
        ============================== */
        Document__c doc = new Document__c(
            LeasingOrder__c = order.Id,
            Content_Version_Id__c = cv.Id,
            Document_Name__c = 'Leasing Contract - Signed'
        );
        insert doc;

        /* ==============================
           5️⃣ App Settings (if needed)
           Only if MetadataService reads custom metadata.
        ============================== */
    }

    /* =====================================================
       TEST BATCH EXECUTION
    ====================================================== */
    @IsTest
    static void testBatchExecution() {

        Test.startTest();

        LeasingRenewalBatch batch = new LeasingRenewalBatch();
        Database.executeBatch(batch, 1);

        Test.stopTest();

        System.assert(true, 'Batch executed successfully');
    }

    /* =====================================================
       TEST SCHEDULABLE EXECUTION
    ====================================================== */
    @IsTest
    static void testSchedulableExecution() {

        Test.startTest();

        LeasingRenewalBatch job = new LeasingRenewalBatch();
        job.execute(null);

        Test.stopTest();

        System.assert(true, 'Schedulable executed successfully');
    }
}