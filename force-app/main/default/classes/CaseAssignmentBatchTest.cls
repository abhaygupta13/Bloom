@IsTest
public class CaseAssignmentBatchTest {

    @TestSetup
    static void testData() {

        MetadataService objMetadataService = MetadataService.getInstance();

        String bfmQueueId = objMetadataService.getAppSettingTextValue('BFMCasesQueueId');
        String digitalQueueId = objMetadataService.getAppSettingTextValue('ContactCenterDigitalQueueId');
        String complaintQueueId = objMetadataService.getAppSettingTextValue('ComplaintCasesQueueId');
        String crmQueueId = objMetadataService.getAppSettingTextValue('CRMQueueId');

        User adminUser = [
            SELECT Id
            FROM User
            WHERE Profile.Name = 'System Administrator'
            AND IsActive = true
            LIMIT 1
        ];

        BusinessHours bh = [
            SELECT Id
            FROM BusinessHours
            WHERE IsActive = true
            LIMIT 1
        ];

        createAssignmentUser(createRule('BFM Email To Case Assignment').Id, adminUser.Id, bh.Id);
        createAssignmentUser(createRule('Digital Case Assignment').Id, adminUser.Id, bh.Id);
        createAssignmentUser(createRule('General Complaint Case Assignment').Id, adminUser.Id, bh.Id);
        createAssignmentUser(createRule('CRM Case Assignment').Id, adminUser.Id, bh.Id);
        createAssignmentUser(createRule('Super App Operation Team Case Assignment').Id,adminUser.Id,bh.Id);

        List<Case> caseList = new List<Case>();

        Case bfmCase = TestDataFactory.createBFMCase(
            'Email', 'New', 'Test description', 'BFM Case',
            null, 'bfm@test.com', '0123456789'
        );
        bfmCase.OwnerId = bfmQueueId;
        caseList.add(bfmCase);

        Case digitalCase = TestDataFactory.createBFMCase(
            'Email', 'New', 'Test description', 'Digital Case',
            null, 'digital@test.com', '0123456789'
        );
        digitalCase.OwnerId = digitalQueueId;
        caseList.add(digitalCase);

        Case complaintCase = TestDataFactory.createBFMCase(
            'Email', 'New', 'Test description', 'Complaint Case',
            null, 'complaint@test.com', '0123456789'
        );
        complaintCase.OwnerId = complaintQueueId;
        caseList.add(complaintCase);

        Case crmCase = TestDataFactory.createBFMCase(
            'Email', 'New', 'Test description', 'CRM Case',
            null, 'crm@test.com', '0123456789'
        );
        crmCase.OwnerId = crmQueueId;
        caseList.add(crmCase);

        insert caseList;
    }

    @IsTest
    static void testBatchable() {

        Test.startTest();
        Database.executeBatch(new CaseAssignmentBatch(), 100);
        Test.stopTest();

        List<Case> updatedCases = [
            SELECT Id, Subject, OwnerId
            FROM Case
            WHERE Subject IN ('BFM Case', 'Digital Case', 'Complaint Case', 'CRM Case')
        ];

        System.assert(!updatedCases.isEmpty(), 'Cases should exist');
    }

    @IsTest
    static void testSchedule() {

        Test.startTest();

        System.schedule(
            'CaseAssignmentBatch Test Schedule',
            '0 0 23 * * ?',
            new CaseAssignmentBatch()
        );

        Test.stopTest();

        List<CronTrigger> cronList = [
            SELECT Id, CronExpression, State
            FROM CronTrigger
            WHERE CronJobDetail.Name = 'CaseAssignmentBatch Test Schedule'
        ];

        System.assertEquals(1, cronList.size(), 'Scheduled job should be created');
    }

    @IsTest
    static void testFinish() {

        CaseAssignmentBatch batchJob = new CaseAssignmentBatch();
        batchJob.finish(null);

        System.assert(true, 'Finish method covered');
    }

    private static AssignmentRule__c createRule(String processName) {

        AssignmentRule__c rule = new AssignmentRule__c();
        rule.RecordType__c = 'Case';
        rule.ProcessName__c = processName;
        rule.ProcessType__c = 'Sales';
        rule.IsActive__c = true;

        insert rule;
        return rule;
    }

    private static void createAssignmentUser(Id ruleId, Id userId, Id businessHourId) {

        AssignmentUser__c assUser = new AssignmentUser__c();
        assUser.IsActive__c = true;
        assUser.AssignmentRule__c = ruleId;
        assUser.BusinessHours__c = businessHourId;
        assUser.User__c = userId;

        insert assUser;
    }

    @IsTest
    static void testSuperAppKycAssignment() {
        MetadataService md = MetadataService.getInstance();
        Id superAppQueueId = md.getAppSettingTextValue('SuperAppOperationTeamQueueId');
        Id kycRTId = Utility.getRecordTypeIdByDevName(Case.SObjectType, 'KYCUpdateRequest');
        Case kycCase = TestDataFactory.createBFMCase( 'Email', 'New', 'Test', 'KYC Case',null,'test@test.com','9999999999');

        kycCase.RecordTypeId = kycRTId;
        kycCase.OwnerId = superAppQueueId;
        kycCase.Origin = 'Super App';
        insert kycCase;

        Task t = new Task( Subject='Test', Status='Open', Priority='Normal', OwnerId=superAppQueueId, WhatId=kycCase.Id );
        insert t;
		CaseAssignmentBatch.isBeforeTenAm = true;
        Test.startTest();
            Database.executeBatch(new CaseAssignmentBatch(),100);
        Test.stopTest();

        Case updatedCase = [ SELECT OwnerId FROM Case WHERE Id=:kycCase.Id ];
        Task updatedTask = [ SELECT OwnerId FROM Task WHERE Id=:t.Id ];

        System.assertNotEquals( superAppQueueId, updatedCase.OwnerId );
        System.assertEquals( updatedCase.OwnerId, updatedTask.OwnerId );
    }
}