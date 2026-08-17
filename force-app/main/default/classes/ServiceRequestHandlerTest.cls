@IsTest
public with sharing class ServiceRequestHandlerTest {
    @TestSetup
    static void setupTestData() {
        // Create a Contact to attach to a Case
        Contact con = new Contact(
            LastName = 'Test Contact',
            Email = 'contact@example.com'
        );
        insert con;

        String RecordTypeCaseIdONE = Schema.SObjectType.Case.getRecordTypeInfosByName().get('LPF Waiver Request').getRecordTypeId();
        // Create Case with ContactId
        Case caseWithContact = new Case(
            Subject = 'Case With Contact',
            Origin = 'Phone',
            ContactId = con.Id,
            RecordTypeId= RecordTypeCaseIdONE
        );
        insert caseWithContact;

        String RecordTypeCaseIdTWO = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Payment Due Date Update').getRecordTypeId();
        // Create Case with SuppliedEmail only
        Case caseWithSuppliedEmail = new Case(
            Subject = 'Case With Supplied Email',
            Origin = 'Web',
            SuppliedEmail = 'supplied@example.com',
            RecordTypeId= RecordTypeCaseIdTWO
        );
        insert caseWithSuppliedEmail;
        
        String RecordTypeCaseIdTHREE = Schema.SObjectType.Case.getRecordTypeInfosByName().get('SOA Request').getRecordTypeId();
        Case c = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Origin = 'Phone',
            RecordTypeId= RecordTypeCaseIdTHREE,
            CaseType__c = 'Service Request'
            //Case_Sub_Status__c = 'In Progress'
        );
        insert c;
        SMSTemplate__c smsTemp = new SMSTemplate__c(Name = 'BFM SR Create Notification',SenderNumber__c = '1234567890',Body__c = 'Hello {0}');
        insert smsTemp;
        SMSTemplate__c smsClosureTemp = new SMSTemplate__c(Name = 'BFM SR Closure Notification',SenderNumber__c = '1234567890',Body__c = 'Hello {0}');
        insert smsClosureTemp;
    }
    
    @IsTest
    static void testServiceRequestAcknowledgementEmailNotification() {

        // Query cases created in TestSetup
        List<Case> cases = [SELECT Id, ContactId,StopEmailsToCustomer__c,RecordTypeId, SuppliedEmail FROM Case];

        // START TEST
        Test.startTest();

        // Call method
        ServiceRequestHandler.getInstance().serviceRequestAcknowledgementEmailNotification(cases);

        Test.stopTest();

        // ASSERTIONS

        // 1. Verify emails are queued to send
        // You cannot check Messaging.sendEmail() directly, 
        // but you can check limits usage:
        System.assertEquals(2, Limits.getEmailInvocations(), 
            'Two email messages should have been sent');

        // 2. (Optional) Confirm no exceptions
        System.assert(true, 'The method executed without exceptions');
    }
    
    @IsTest
    static void testServiceRequestAssignmentEmailNotification() {

        List<Case> cases = [SELECT Id, ContactId,StopEmailsToCustomer__c,RecordTypeId, SuppliedEmail FROM Case];

        Test.startTest();
        ServiceRequestHandler.getInstance().serviceRequestAssignmentEmailNotification(new Set<Id>{cases[0].Id});
        Test.stopTest();
        System.assertEquals(2, Limits.getEmailInvocations(), 'Two email messages should have been sent');
        System.assert(true, 'The method executed without exceptions');
    }
    
     @IsTest
    static void testserviceRequestClosureEmailNotification() {

        List<Case> cases = [SELECT Id, Status,RequesterEmail__c,CaseNumber,RequesterName__c,RequesterContactNumber__c,ContactId,StopEmailsToCustomer__c,RecordTypeId, SuppliedEmail FROM Case];

        Test.startTest();
        ServiceRequestHandler.getInstance().serviceRequestClosureEmailNotification(cases);
        Test.stopTest();
        System.assertEquals(2, Limits.getEmailInvocations(), 'Two email messages should have been sent');
        System.assert(true, 'The method executed without exceptions');
    }
}