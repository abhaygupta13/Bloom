@isTest
private class EmailMessageServiceTest {

    @isTest
    static void testGetLatestEmailMessageByRelatedToId_withValidId() {
        
        // Create a dummy Case (or any object that EmailMessage.RelatedToId can point to)
        Case testCase = new Case(Subject = 'Test Case', Status = 'New', Case_Sub_Status__c='In Progress', Type = 'Question');
        insert testCase;
        

        // Create two EmailMessages with different CreatedDates
        EmailMessage olderEmail = new EmailMessage(
            RelatedToId = testCase.Id,
            Subject = 'Older Email',
            TextBody = 'This is the older email',
            FromAddress = 'test@example.com',
            Incoming = true
        );
        insert olderEmail;

        Test.setCreatedDate(olderEmail.Id, DateTime.now().addDays(-1));

        EmailMessage newerEmail = new EmailMessage(
            RelatedToId = testCase.Id,
            Subject = 'Newer Email',
            TextBody = 'This is the newer email',
            FromAddress = 'test@example.com',
            Incoming = true
        );
        insert newerEmail;

        // Test the method
        Test.startTest();
        EmailMessage result = EmailMessageService.getInstance().getLatestEmailMessageByRelatedToId(testCase.Id);
        Test.stopTest();

        // Assert that the latest email is returned
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(newerEmail.Id, result.Id, 'Should return the latest EmailMessage');
    }

    @isTest
    static void testGetLatestEmailMessageByRelatedToId_withNullId() {
        Test.startTest();
        EmailMessage result = EmailMessageService.getInstance().getLatestEmailMessageByRelatedToId(null);
        Test.stopTest();

        System.assertEquals(null, result, 'Result should be null when input is null');
    }

    @isTest
    static void testGetLatestEmailMessageByRelatedToId_withNoMessages() {
        // Create a dummy Case with no EmailMessages
        Case testCase = new Case(Subject = 'Case without Email', Status = 'New', Case_Sub_Status__c='In Progress', Type = 'Question');
        insert testCase;

        Test.startTest();
        EmailMessage result = EmailMessageService.getInstance().getLatestEmailMessageByRelatedToId(testCase.Id);
        Test.stopTest();

        System.assertEquals(null, result, 'Result should be null when no EmailMessages exist');
    }
}