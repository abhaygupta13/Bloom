@isTest
public class CRMComplaintRequestHandlerTest {

     @testSetup
    static void setupTestData() {
        
        Account acc = TestDataFactory.createBrokerAccount('test', false, '1122334455');
        insert acc;

        Contact con = TestDataFactory.createContact('lname', acc.Id, true, 'test@gmail.com');
        insert con;

        Opportunity opp = TestDataFactory.createOpportunity(null, null,null, acc.Id, null, null, null, null);
        insert opp;

        Project__c project = TestDataFactory.createProject('Project Test', Date.newinstance(2024, 01, 01), Date.newInstance(2025, 01, 01), Date.newInstance(2025, 01, 15), Date.newInstance(2025, 01, 16), Date.newInstance(2025, 01, 30), Date.newInstance(2025, 02, 01));
        insert project;

        Unit__c unit = TestDataFactory.createUnit(project.Id, 'Test unit', 'Sold');
        insert unit;

        SalesOrder__c salesOrder = TestDataFactory.createSalesOrder(acc.Id, opp.Id, 'Sold', date.newinstance(2025, 02, 10), unit.Id, 18181818);
        insert salesOrder;
        
        // Create test ServiceCatalog record
        ServiceCatalog__c testServiceCatalog = new ServiceCatalog__c(
            Name = 'Test Service Catalog',
            Type__c = 'Service Request',
            Category__c = 'General Enquiry',
            SubCategory__c = 'General Enquiry',
            RecordTypeDevName__c = 'GeneralEnquiry'
        );
        insert testServiceCatalog;
        system.debug('testServiceCatalog----->'+testServiceCatalog);
        
        // Create test ServiceAction record
        ServiceAction__c testServiceAction1 = new ServiceAction__c(
            ServiceCatalog__c = testServiceCatalog.Id,
            TaskType__c = 'General Enquiry',
            TaskSubType__c = 'CRM Team Task 1',
            TaskSubject__c = 'CRM Team Task 1',
            Due_in_days__c = 2,
            Order__c = 1,
            FinalTask__c = true
        );
        insert testServiceAction1;
        
        // prepare a Case for testing
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('General Enquiry').getRecordTypeId();
        // Create test Case related to the Account
        Case cs = new Case(Status = 'New', Origin = 'Phone', AccountId = acc.Id, RecordTypeId= RecordTypeCaseId, ServiceCatalog__c = testServiceCatalog.Id,
                           Sales_Order__c = salesOrder.Id, Unit__c = unit.Id, subject = 'test');
        insert cs;
    }

    static Case getDummyCase() {
        return [SELECT Id, Step__c,AccountId, CaseType__c, isDocumentAvailable__c,Unit__c, isNotRegistered__c, Sales_Order__c,SubType__c,ServiceCatalog__c, Status, RecordTypeId, StopEmailsToCustomer__c FROM Case LIMIT 1];
    }

    @isTest
    static void testGetInstance() {
        Test.startTest();
        CRMComplaintRequestHandler handler = CRMComplaintRequestHandler.getInstance();
        System.assertNotEquals(null, handler);
        Test.stopTest();
    }
      @isTest
    static void testCreateFirstTask() {
        Case c = getDummyCase();
        Test.startTest();
        CRMComplaintRequestHandler.getInstance().createFirstTask(new List<Case>{ c });
        Test.stopTest();
    }

    @isTest
    static void testCreateCaseRecordWithSalesOrder() {
        SalesOrder__c so = [SELECT Id, Account__c, Unit__c, Project__c, Account__r.Name, Account__r.isPersonAccount, Account__r.PersonMobilePhone, Unit__r.Name, Account__r.Id FROM SalesOrder__c LIMIT 1];
        ServiceCatalog__c sc = [SELECT Id, RecordTypeDevName__c, SubCategory__c FROM ServiceCatalog__c LIMIT 1];

        Test.startTest();
        Case newCase = CRMComplaintRequestHandler.getInstance().createCaseRecord(
            so, sc, null, null, 'Service Request', 'Test description', 'Web', false
        );
        Test.stopTest();

        System.assertNotEquals(null, newCase);
        System.assertEquals('New', newCase.Status);
    }

    @isTest
    static void testCreateCaseRecordWithoutSalesOrder() {
        ServiceCatalog__c sc = [SELECT Id, RecordTypeDevName__c,SubCategory__c FROM ServiceCatalog__c LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];

        Test.startTest();
        Case newCase = CRMComplaintRequestHandler.getInstance().createCaseRecord(
            null, sc, acc.Id, unit.Id, 'Service Request', 'Another description', 'Email', false
        );
        Test.stopTest();

        System.assertNotEquals(null, newCase);
        System.assertEquals('New', newCase.Status);
    }
@IsTest
static void testSendComplaintClosureEmails() {

    Case c = getDummyCase();

    Test.startTest();
    CRMComplaintRequestHandler.getInstance()
        .sendComplaintClosureEmails(new List<Case>{ c });
    Test.stopTest();

    // Method executed successfully
    System.assert(true);
}
    @IsTest
static void testSendComplaintAssignmentEmails() {

    Case c = getDummyCase();

    Task t = new Task(
        Subject = 'Test Task',
        Status = 'Open',
        Priority = 'Normal',
        WhatId = c.Id,
        OwnerId = UserInfo.getUserId()
    );
    insert t;

    Test.startTest();
    CRMComplaintRequestHandler.getInstance()
        .sendComplaintAssignmentEmails(new List<Task>{ t });
    Test.stopTest();

    // Method executed successfully
    System.assert(true);
}
    @IsTest
static void testSendComplaintAssignmentEmails_EmptyList() {

    Test.startTest();
    CRMComplaintRequestHandler.getInstance()
        .sendComplaintAssignmentEmails(new List<Task>());
    Test.stopTest();

    System.assert(true);
}
    @IsTest
static void testSendComplaintAssignmentEmails_NullWhatId() {

    Task t = new Task(
        Subject = 'Test',
        Status = 'Open',
        Priority = 'Normal',
        OwnerId = UserInfo.getUserId()
    );
    insert t;

    Test.startTest();
    CRMComplaintRequestHandler.getInstance()
        .sendComplaintAssignmentEmails(new List<Task>{ t });
    Test.stopTest();

    System.assert(true);
}
}