@isTest
public class HandoverOnsiteAPITest {

    @TestSetup
    static void setupTestData() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User testUser = new User(
            Username = 'testhoagent@gmail.com', 
            LastName = 'Test',
            Email = 'testuser@example.com',
            Alias = 'test',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id,
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        insert testUser;
        
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // To trigger the Unit update branch: 
        // We set the HO_Agent__c to NULL initially so the code must update it.
        Unit__c unt = new Unit__c(
            Name = 'Unit Test A143',
            HO_Agent__c = null, 
            Status__c = 'Booked',
            SAP_Unit_Number__c = '123'
        );
        insert unt;
        
        SalesOrder__c salesOrd = new SalesOrder__c(
            Name = 'Test SalesOrder',
            Account__c = acc.Id,
            unit__c = unt.id,
            Status__c = 'Sold'
        );
        insert salesOrd;
        
        ServiceCatalog__c servicecatalog = new ServiceCatalog__c(
            ProcessFlowType__c = 'Handover',
            Active__c = true,
            RecordTypeDevName__c = 'Handover'
        );
        insert servicecatalog;
        
        Project__c pr = new Project__c(Name = 'testProject');
        insert pr;

        Schema.RecordTypeInfo rt = Schema.getGlobalDescribe().get('Handover__c').getDescribe().getRecordTypeInfosByDeveloperName().get('Handover');
        Handover__c ho = new Handover__c(
            unit__c = unt.Id,
            Sales_Order__c = salesOrd.Id,
            Project__c = pr.id,
            RecordTypeId = rt.getRecordTypeId(),
            ServiceCatalog__c = servicecatalog.Id
        );
        insert ho;
    }

    /**
     * BRANCH: Unit Update + QA Snagging
     * Covers: unit.HO_Agent__c != HOAgentId branch
     */
    @isTest
    static void testUnitUpdateAndQASnagging() {
        Test.startTest();
        // Since unit.HO_Agent__c is null in setup, this triggers the updateUnitWithoutTrigger call.
        HandoverOnsiteAPI.deSnaggingReport('dGVzdA==', 'f', '.p', 'testuser@example.com', '1', 'QA', 'snagging', '123');
        Test.stopTest();
    }

    /**
     * BRANCH: CHO + Activity Service (Open Tasks)
     * This covers the PHPPHandoverHandler and ActivityService logic.
     */
    @isTest
    static void testCHOWithTaskLogic() {
        Handover__c ho = [SELECT Id FROM Handover__c LIMIT 1];
        insert new Document__c(Handover__c = ho.Id, Document_Name__c = 'CHO Snagging Report');
        insert new Task(WhatId = ho.Id, Status = 'Open', Subject = 'Task 1');

        Test.startTest();
        HandoverOnsiteAPI.deSnaggingReport('dGVzdA==', 'f', '.p', 'testuser@example.com', '1', 'CHO', 'snagging', '123');
        Test.stopTest();
    }

    /**
     * BRANCH: Metadata Service (Blank Inspector)
     * Covers: String.isBlank(inspector) ? getAppSettingTextValue : inspector
     */
    @isTest
    static void testMetadataBranch() {
        Test.startTest();
        // Passing blank inspector to trigger MetadataService lookup.
        // Ensure your system has an App Setting for 'HO_Manager_Email' or it might return null.
        HandoverOnsiteAPI.deSnaggingReport('dGVzdA==', 'f', '.p', '', '1', 'QA', 'snagging', '123');
        Test.stopTest();
    }

    /**
     * BRANCH: New Handover Record Type Creation
     * Covers: if (handOverList.isEmpty()) branch
     */
    @isTest
    static void testNewHandoverCreation() {
        delete [SELECT Id FROM Handover__c]; // Force creation branch
        
        Test.startTest();
        HandoverOnsiteAPI.deSnaggingReport('dGVzdA==', 'f', '.p', 'testuser@example.com', '1', 'QA', 'snagging', '123');
        Test.stopTest();
    }

    /**
     * BRANCH: Catch Block (Exception)
     * Covers: ErrorLogHandler.logError
     */
    @isTest
    static void testExceptionPath() {
        Test.startTest();
        // Passing null for base64Pdf to force a decode exception (EncodingUtil.base64Decode)
        HandoverOnsiteAPI.deSnaggingReport(null, 'file', '.pdf', 'testuser@example.com', '1', 'QA', 'snagging', '123');
        Test.stopTest();
    }

    /**
     * BRANCH: All Early Returns
     */
    @isTest
    static void testEarlyReturns() {
        Test.startTest();
        HandoverOnsiteAPI.deSnaggingReport('', '', '', 'testuser@example.com', '1', 'QA', 'snagging', '123');
        HandoverOnsiteAPI.deSnaggingReport('dGVzdA==', 'f', '.p', 'testuser@example.com', '1', '', 'snagging', '123');
        HandoverOnsiteAPI.deSnaggingReport('dGVzdA==', 'f', '.p', 'testuser@example.com', '1', 'QA', 'snagging', '');
        HandoverOnsiteAPI.deSnaggingReport('dGVzdA==', 'f', '.p', 'invalid@user.com', '1', 'QA', 'snagging', '123');
        Test.stopTest();
    }
}