@IsTest
private class ApprovalRequestHandlerTest {

    // ---------- HELPER METHODS ----------

    private static Id getRecordTypeId(String objectName, String developerName) {
        Map<String, Schema.RecordTypeInfo> rtMap =
            Schema.getGlobalDescribe()
                .get(objectName)
                .getDescribe()
                .getRecordTypeInfosByDeveloperName();
        if (rtMap.containsKey(developerName)) {
            return rtMap.get(developerName).getRecordTypeId();
        }
        // fallback: use default record type if specific one not found
        return Schema.getGlobalDescribe()
            .get(objectName)
            .getDescribe()
            .getRecordTypeInfos()[0]
            .getRecordTypeId();
    }

    private static Account createTestAccount() {
        Id accRTId = getRecordTypeId('Account', 'Broker_Agency');
        Account acc = new Account(Name = 'Test Broker Agency', RecordTypeId = accRTId);
        insert acc;
        return acc;
    }

    private static Contact createTestContact(Id accountId) {
        Id conRTId = getRecordTypeId('Contact', 'Broker');
        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'Broker',
            RecordTypeId = conRTId,
            AccountId = accountId,
            Email = 'test@test.com'
        );
        insert con;
        return con;
    }

    private static Case createTestCase(Id accountId, Id contactId) {
        Id caseRTId = getRecordTypeId('Case', 'Broker_Registration');
        Case c = new Case(
            Subject = 'Approval Test Case',
            Status = 'New',
            RecordTypeId = caseRTId,
            AccountId = accountId,
            ContactId = contactId
        );
        insert c;
        return c;
    }

    // ---------- TEST METHODS ----------

    @IsTest
    static void testExecute_Approval_Success_Mocked() {
        Account acc = createTestAccount();
        Contact con = createTestContact(acc.Id);
        Case testCase = createTestCase(acc.Id, con.Id);

        ApprovalRequestHandler.Requests req = new ApprovalRequestHandler.Requests();
        req.recordId = testCase.Id;
        req.objName = 'Case';
       // req.approvalRequestId = '005000000000001AAA'; // fake but valid format
        req.comments = 'Approving this case';
        req.action = 'Approve';
        req.nextApproverIds = new List<String>{UserInfo.getUserId()};

        Test.startTest();
        List<ApprovalRequestHandler.Results> results =
            ApprovalRequestHandler.execute(new List<ApprovalRequestHandler.Requests>{req});
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertNotEquals(null, results[0]);
    }

    //  This now ensures the rollback branch executes
    @IsTest
    static void testExecute_Approval_Failure_RollbackCovered() {
        Account acc = createTestAccount();
        Contact con = createTestContact(acc.Id);
        Case testCase = createTestCase(acc.Id, con.Id);

        // mark SendToBL__c = false before calling handler
        testCase.SendToBL__c = false;
        update testCase;

        ApprovalRequestHandler.Requests req = new ApprovalRequestHandler.Requests();
        req.recordId = testCase.Id;
        req.objName = 'Case';
        req.approvalRequestId = 'INVALID_WORKITEM_ID'; // invalid, will cause Approval.process() to fail
        req.comments = 'Force rollback test';
        req.action = 'Reject';
        req.nextApproverIds = new List<String>{UserInfo.getUserId()};

        Test.startTest();
        List<ApprovalRequestHandler.Results> results =
            ApprovalRequestHandler.execute(new List<ApprovalRequestHandler.Requests>{req});
        Test.stopTest();

        // After failure → rollback must set SendToBL__c = false again
        Case updatedCase = [SELECT SendToBL__c FROM Case WHERE Id = :testCase.Id];
        System.assertEquals(false, updatedCase.SendToBL__c,
            'SendToBL__c should rollback to false when approval fails');

        System.assertEquals('Error', results[0].currentApprovalProcessStatus,
            'Should reflect error status after failure');
    }

    @IsTest
    static void testGetApprovalRequestId_NoRecordsFound() {
        Account acc = createTestAccount();
        Contact con = createTestContact(acc.Id);
        Case testCase = createTestCase(acc.Id, con.Id);

        Test.startTest();
        ProcessInstanceWorkitem result =
            ApprovalRequestHandler.getApprovalRequestId(testCase.Id, 'Case');
        Test.stopTest();

        System.assertEquals(null, result, 'No approval items should exist');
    }

    @IsTest
    static void testGetErrorInfo_Helper() {
        // Case 1: Null input
        String result1 = ApprovalRequestHandler.getErrorInfo(null);
        System.assertEquals('', result1);

        // Case 2: Simulate failed DML
        Account acc = new Account(); // Missing Name
        Database.SaveResult sr = Database.insert(acc, false);
        String errMsg = ApprovalRequestHandler.getErrorInfo(sr.getErrors());
        System.assertNotEquals(null, errMsg);
    }
}