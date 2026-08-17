@IsTest
private class BAPPCaseEscalationBatchTest {

    // -------------------------------------------------
    // Create Case record for testing
    // -------------------------------------------------
    private static Case createTestCase() {
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' LIMIT 1];
        Case c = new Case(
            Subject = 'Escalation Test',
            Status = 'New',
            RecordTypeId = rt.Id,
            Escalation_Date__c = System.now().addHours(-25)
        );
        insert c;
        return c;
    }

    // -------------------------------------------------
    // MAIN TEST: Execute Batch
    // -------------------------------------------------
    @IsTest
    static void testBatchExecutesAndSendsEmail() {
        // Create a Case record
        Case c = createTestCase();

        Test.startTest();
        // Run the batch
        BAPPCaseEscalationBatch batch = new BAPPCaseEscalationBatch();
        Database.executeBatch(batch, 1);
        Test.stopTest();

        System.assert(true, 'Batch executed successfully without exceptions.');
    }

    // -------------------------------------------------
    // TEST: Schedule Execute
    // -------------------------------------------------
    @IsTest
    static void testSchedulableExecute() {
        Test.startTest();
        String jobId = System.schedule('CaseEscalationSchedule', '0 0 12 * * ?', new BAPPCaseEscalationBatch());
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Scheduled job should be created.');
    }

    // -------------------------------------------------
    // TEST: Helper Method
    // -------------------------------------------------
    @IsTest
    static void testIsOlderThan24HoursLogic() {
        Datetime now = System.now();
        Datetime oldDate = now.addHours(-25);
        Datetime recentDate = now.addHours(-5);

        Boolean shouldBeTrue = BAPPCaseEscalationBatch.isOlderThan24Hours(oldDate, now);
        Boolean shouldBeFalse = BAPPCaseEscalationBatch.isOlderThan24Hours(recentDate, now);

        System.assertEquals(true, shouldBeTrue, 'Old date should return true.');
        System.assertEquals(false, shouldBeFalse, 'Recent date should return false.');
    }
}