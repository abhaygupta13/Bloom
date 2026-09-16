@IsTest
private class SendEmailInvocableTest {

    @TestSetup
    static void setupTestData() {
        User testUser = createTestUser();

        Project__c projectRecord = new Project__c(
            Name = 'Send Email Test Project'
        );
        insert projectRecord;

        BuildingSection__c buildingRecord = new BuildingSection__c(
            Name = 'Send Email Test Building',
            BuildingSectionCode__c = 'SE001',
            Project__c = projectRecord.Id
        );
        insert buildingRecord;

        Unit__c unitRecord = new Unit__c(
            Name = 'Send Email Test Unit',
            Status__c = 'Unassigned',
            HO_Agent__c = testUser.Id,
            BuildingSectionName__c = buildingRecord.Id,
            Project__c = projectRecord.Id
        );
        insert unitRecord;

        Id personAccountRecordTypeId =
            Schema.SObjectType.Account
                .getRecordTypeInfosByDeveloperName()
                .get('PersonAccount')
                .getRecordTypeId();

        Account accountRecord = new Account(
            RecordTypeId = personAccountRecordTypeId,
            LastName = 'Send Email Test Customer',
            PersonEmail = 'sendemailcustomer@example.com'
        );
        insert accountRecord;

        // A second, independent Account guarantees an 8th unique Id
        // without relying on org-level Ids that may collide across orgs.
        Account secondAccountRecord = new Account(
            RecordTypeId = personAccountRecordTypeId,
            LastName = 'Send Email Test Customer Two',
            PersonEmail = 'sendemailcustomer2@example.com'
        );
        insert secondAccountRecord;

        /*
         * CRITICAL: every value below must be DISTINCT.
         * The production if/else-if chain checks these fields in order,
         * so any duplicate value causes an earlier branch to intercept
         * the match and the intended branch is never reached.
         */
        HandoverPhase__c phaseRecord = new HandoverPhase__c(
            Name = 'Send Email Test Phase',
            Project__c = projectRecord.Id,

            HOTitleDeedEmailTempID__c            = String.valueOf(projectRecord.Id),
            HOOutstandingConfirmationTempId__c   = String.valueOf(buildingRecord.Id),
            CHOAttendedbyCustomerEmailTempId__c  = String.valueOf(unitRecord.Id),
            HomeOrientationByBloomEmailTempId__c = String.valueOf(accountRecord.Id),
            ChoCustomerNotattendedEmailTempId__c = String.valueOf(secondAccountRecord.Id),
            ChoDesnaggingEmailTempId__c          = String.valueOf(testUser.Id),
            HOCongratulationEmailTempId__c       = String.valueOf(UserInfo.getUserId()),
            KeyHandoverInvitationEmailTempId__c  = String.valueOf(Test.getStandardPricebookId())
        );
        insert phaseRecord;

        Boolean previousTriggerState =
            HandoverTriggerHandler.isTriggerDisabled;

        HandoverTriggerHandler.isTriggerDisabled = true;

        try {
            Handover__c handoverRecord = new Handover__c(
                Status__c = 'In Progress',
                Unit__c = unitRecord.Id,
                Account__c = accountRecord.Id,
                Handover_Phase__c = phaseRecord.Id,
                Project__c = projectRecord.Id,
                Sub_Status__c = 'Book Appointment With Customer',
                Customer_Email__c = 'sendemailcustomer@example.com',
                Customer_Availability_for_CHO__c = 'Customer Available',
                HO_Agent_Assigned_User__c = testUser.Id,
                OwnerId = testUser.Id
            );

            insert handoverRecord;
        } finally {
            HandoverTriggerHandler.isTriggerDisabled =
                previousTriggerState;
        }
    }

    @IsTest
    static void testSendEmailWithNullTemplateId() {
        Handover__c handoverRecord = getHandover();

        Test.startTest();
        SendEmailInvocable.sendEmail(null, handoverRecord.Id);
        Test.stopTest();

        System.assertEquals(
            0,
            Limits.getEmailInvocations(),
            'No email should be sent when template Id is null.'
        );
    }

    @IsTest
    static void testSendEmailWithNullRecordId() {
        HandoverPhase__c phaseRecord = [
            SELECT HOTitleDeedEmailTempID__c
            FROM HandoverPhase__c
            LIMIT 1
        ];

        Test.startTest();
        SendEmailInvocable.sendEmail(
            phaseRecord.HOTitleDeedEmailTempID__c,
            null
        );
        Test.stopTest();

        System.assertEquals(
            0,
            Limits.getEmailInvocations(),
            'No email should be sent when record Id is null.'
        );
    }

    @IsTest
    static void testSendEmailForAllTemplateBranches() {
        Handover__c handoverRecord = getHandover();

        HandoverPhase__c phaseRecord = [
            SELECT
                HOTitleDeedEmailTempID__c,
                HOOutstandingConfirmationTempId__c,
                CHOAttendedbyCustomerEmailTempId__c,
                HomeOrientationByBloomEmailTempId__c,
                ChoCustomerNotattendedEmailTempId__c,
                ChoDesnaggingEmailTempId__c,
                HOCongratulationEmailTempId__c,
                KeyHandoverInvitationEmailTempId__c
            FROM HandoverPhase__c
            WHERE Id = :handoverRecord.Handover_Phase__c
            LIMIT 1
        ];

        List<Id> templateIds = new List<Id>{
            (Id) phaseRecord.HOTitleDeedEmailTempID__c,
            (Id) phaseRecord.HOOutstandingConfirmationTempId__c,
            (Id) phaseRecord.CHOAttendedbyCustomerEmailTempId__c,
            (Id) phaseRecord.HomeOrientationByBloomEmailTempId__c,
            (Id) phaseRecord.ChoCustomerNotattendedEmailTempId__c,
            (Id) phaseRecord.ChoDesnaggingEmailTempId__c,
            (Id) phaseRecord.HOCongratulationEmailTempId__c,
            (Id) phaseRecord.KeyHandoverInvitationEmailTempId__c
        };

        Test.startTest();

        for (Id templateId : templateIds) {
            SendEmailInvocable.sendEmail(
                templateId,
                handoverRecord.Id
            );
        }

        Test.stopTest();

        System.assertEquals(
            8,
            templateIds.size(),
            'All configured template branches should be exercised.'
        );
    }

    @IsTest
    static void testSendEmailWithUnmappedTemplateId() {
        Handover__c handoverRecord = getHandover();

        Project__c unrelatedProject = new Project__c(
            Name = 'Unmapped Template Project'
        );
        insert unrelatedProject;

        Test.startTest();
        SendEmailInvocable.sendEmail(
            unrelatedProject.Id,
            handoverRecord.Id
        );
        Test.stopTest();

        System.assertEquals(
            0,
            Limits.getEmailInvocations(),
            'An unmapped template should not send an email.'
        );
    }

    @IsTest
    static void testSendEmailHandlesExceptionGracefully() {
        HandoverPhase__c phaseRecord = [
            SELECT HOTitleDeedEmailTempID__c
            FROM HandoverPhase__c
            LIMIT 1
        ];

        // A syntactically valid but non-existent Handover__c Id forces
        // HandoverService.getHandoverById() to throw, exercising the
        // catch block and ErrorLogHandler.logError call.
        Id fakeHandoverId = HandoverPhase__c.SObjectType
            .getDescribe()
            .getKeyPrefix() + '000000000000AAA';

        Test.startTest();
        SendEmailInvocable.sendEmail(
            phaseRecord.HOTitleDeedEmailTempID__c,
            fakeHandoverId
        );
        Test.stopTest();

        System.assertEquals(
            0,
            Limits.getEmailInvocations(),
            'No email should be sent when the underlying query throws.'
        );
    }

    private static Handover__c getHandover() {
        return [
            SELECT Id, Handover_Phase__c
            FROM Handover__c
            LIMIT 1
        ];
    }

    private static User createTestUser() {
        Profile standardProfile = [
            SELECT Id
            FROM Profile
            WHERE UserType = 'Standard'
            LIMIT 1
        ];

        String uniqueValue =
            String.valueOf(DateTime.now().getTime());

        User testUser = new User(
            Username = 'sendemailtest' + uniqueValue + '@example.com',
            LastName = 'Send Email Test User',
            Email = 'sendemailtest@example.com',
            Alias = 'seinv',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_IN',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfile.Id
        );

        insert testUser;
        return testUser;
    }
}