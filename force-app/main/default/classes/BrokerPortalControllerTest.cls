/*****************************************************************************************
Class       : BrokerPortalControllerTest
Author      : Aman Bharti
Description : BrokerPortalControllerTest
Test Class  : 
Created Date: 29 OCT 2025 
*****************************************************************************************/
@isTest
public class BrokerPortalControllerTest {
    @testSetup
    private static void testData() {
        DocumentType__c brokerInvoice = TestDataFactory.createDocumentType('Broker Commission','Broker Shared Invoice');
        insert brokerInvoice;

        Project__c project = TestDataFactory.createProject('Project Test', Date.newinstance(2024, 01, 01), Date.newInstance(2025, 01, 01), Date.newInstance(2025, 01, 15), Date.newInstance(2025, 01, 16), Date.newInstance(2025, 01, 30), Date.newInstance(2025, 02, 01));
        insert project;

        Account acc = TestDataFactory.createBrokerAccount('test', false, '1122334455');
        insert acc;

        Contact con = TestDataFactory.createContact('test', acc.Id, true, 'test@gmail.com');
        insert con;

        Opportunity opp = TestDataFactory.createOpportunity(null, null,null, acc.Id, null, null, null, null);
        insert opp;

        Unit__c unit = TestDataFactory.createUnit(project.Id, 'Test unit', 'Sold');
        insert unit;

        SalesOrder__c salesOrder = TestDataFactory.createSalesOrder(acc.Id, opp.Id, 'Sold', date.newinstance(2025, 01, 10), unit.Id, 18181818);
        insert salesOrder;

        BrokerCommission__c bc = TestDataFactory.createBrokerCommission(null, null, null, null, null, project.Id, salesOrder.Id, acc.Id, con.Id, null);
        bc.Status__c = 'Draft';
        insert bc;

        Document__c document = TestDataFactory.createDocument(bc.Id, brokerInvoice.Id, 'Broker Shared Invoice');
        insert document;
    }


    @isTest
    private static void testUploadBrokerSharedInvoice(){
        Document__c doc = [SELECT Id,Name FROM Document__c LIMIT 1];
        Test.StartTest();
            String fileContent = 'This is a test file content.';
            String base64FileData = EncodingUtil.base64Encode(Blob.valueOf(fileContent));
            String fileName = 'TestFile.txt';
            BrokerPortalController.uploadBrokerSharedInvoice(doc.Id, fileName, base64FileData);
            List<ContentVersion> cvList = [SELECT Id, Title, VersionData, ContentDocumentId FROM ContentVersion WHERE Title = :fileName LIMIT 1];
            List<ContentDocumentLink> cdlinkList = [SELECT Id FROM ContentDocumentLink WHERE ContentDocumentId = :cvList[0].ContentDocumentId];
        Test.StopTest();
        Assert.areEqual(false, cdlinkList.isEmpty(), 'No record found');
    }

    @isTest
    private static void testIsValidInvoiceRecord(){
        Document__c doc = [SELECT Id,Name FROM Document__c LIMIT 1];
        Test.StartTest();
            Boolean isValid  = BrokerPortalController.isValidInvoiceRecord(doc.Id);
        Test.StopTest();
        Assert.areEqual(false, isValid, 'Not a valid record');
    }

}