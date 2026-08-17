/*****************************************************************************************
Class       : BrokerCommissionController Test
Author      : Vikas Baliyan
Description : Commission Controller Test
Test Class  : 
Created Date: 19 DEC 2024 
*****************************************************************************************/
@isTest
public class BrokerCommissionControllerTest {

    @TestSetup
    static void testData(){
        Account acc = TestDataFactory.createBrokerAccount('test', false, '1122334455');
        insert acc;

        Contact con = TestDataFactory.createContact('test', acc.Id, true, 'test@gmail.com');
        insert con;

        DocumentType__c docTypeGeneratedInvoice = TestDataFactory.createDocumentType('Broker Commission','Generated Invoice');
        insert docTypeGeneratedInvoice;
        DocumentType__c docTypeBrokerInvoice = TestDataFactory.createDocumentType('Broker Commission','Broker Shared Invoice');
        insert docTypeBrokerInvoice;
        DocumentType__c docTypeBrokerMergeDoc = TestDataFactory.createDocumentType('Broker Commission','Broker Invoice Combined Document');
        insert docTypeBrokerMergeDoc;

        Project__c project = new Project__c();
        project.Name = 'TEST';
        project.ProjectRegistrationDate__c = Date.today() - 1;
        insert project;

        List<Unit__c> unitLst = new List<Unit__c>();
        for (Integer i = 0; i < 1; i++) {
            Unit__c u = TestDataFactory.createUnit(project.Id, 'A1-G01' + i, 'Unassigned');
            u.RegistrationDate__c = Date.today();
            unitLst.add(u);
        }
        insert unitLst;

        SalesOrder__c salesOrder = new SalesOrder__c();
        salesOrder.Unit__c = unitLst[0].Id;
        salesOrder.Account__c = acc.Id;
        salesOrder.DocumentUploadedDate__c = Date.today() - 1;
        insert salesOrder;

        unitLst[0].Active_Sales_Order__c = salesOrder.Id;
        update unitLst;    
        
        // Create Document
        Document__c document = TestDataFactory.createDocument(null, docTypeGeneratedInvoice.Id, 'test');
        insert document;
        

        List<CommissionSchedule__c> comSchList = new List<CommissionSchedule__c>();
        CommissionSchedule__c comSchedule1 = TestDataFactory.createCommissionSchedule(project.Id, 6, 0, 500000);
        CommissionSchedule__c comSchedule2 = TestDataFactory.createCommissionSchedule(project.Id, 6,500001, 999999999);
        comSchList.add(comSchedule1); comSchList.add(comSchedule2);
        insert comSchList;

        List<BrokerCommission__c> brokerCommissionList = new List<BrokerCommission__c>();
        BrokerCommission__c bc = TestDataFactory.createBrokerCommission(null, null, null, null, null, project.Id, salesOrder.Id, acc.Id, con.Id, comSchedule1.Id);
        bc.Status__c = 'Draft';
        brokerCommissionList.add(bc);
        BrokerCommission__c bc2 = TestDataFactory.createBrokerCommission(null, null, null, null, null, project.Id, salesOrder.Id, acc.Id, con.Id, comSchedule2.Id);
        bc2.Status__c = 'Shared';
        brokerCommissionList.add(bc2);
        insert brokerCommissionList;

        ContentVersion cv = TestDataFactory.createContentVersion('test data', 'Invoice', 'Invoice');
        insert cv;

        Document__c mergeDocument = TestDataFactory.createDocument(null, docTypeBrokerMergeDoc.Id, 'test');
        insert mergeDocument;

        List<DocumentType__c> docTypeList = new List<DocumentType__c>();
        DocumentType__c dc1 = TestDataFactory.createDocumentType('Broker Commission', 'Generated Invoice');
        DocumentType__c dc2 = TestDataFactory.createDocumentType('Account' , 'Rera Certificate');
        DocumentType__c dc3 = TestDataFactory.createDocumentType('Account', 'Trade License');  
        DocumentType__c dc4 = TestDataFactory.createDocumentType('Account', 'Other');
        DocumentType__c dc5 = TestDataFactory.createDocumentType('Broker Commission', 'Broker Invoice Combined Document');
        docTypeList.add(dc1); docTypeList.add(dc2); docTypeList.add(dc3); docTypeList.add(dc4); docTypeList.add(dc5);
        insert docTypeList;

        List<Document__c> docList = new List<Document__c>();
        Document__c doc1 = TestDataFactory.createDoc(dc1.Id, bc.Id, null, null, null, null);
        Document__c doc2 = TestDataFactory.createDoc(dc2.Id, null, acc.Id, null, null, null);
        Document__c doc3 = TestDataFactory.createDoc(dc3.Id, null, acc.Id, null, null, null);
        Document__c doc4 = TestDataFactory.createDoc(dc4.Id, null, acc.Id, null, null, null);
        Document__c doc5 = TestDataFactory.createDoc(dc5.Id, bc.Id, null, null, null, null);
        docList.add(doc1); docList.add(doc2); docList.add(doc3); docList.add(doc4); docList.add(doc5);
        insert docList;
    }

    @IsTest
    static void testGetRelatedContacts(){
        List<BrokerCommission__c> invoiceList = [SELECT Id FROM BrokerCommission__c LIMIT 1];
        Test.startTest();
        List<Contact> contactList = BrokerCommissionController.getRelatedContacts(invoiceList[0].Id);
        Test.stopTest();
        Assert.areEqual(1, contactList.size(), 'There should be 1 contact record');
    }

    @IsTest
    static void testShareCommissionInvoice(){
        ContentVersion cv = [SELECT Id,ContentDocumentId FROM ContentVersion LIMIT 1];
        Contact con = [SELECT Id,Email FROM Contact LIMIT 1];
        List<BrokerCommission__c> invoiceList = [SELECT Id FROM BrokerCommission__c LIMIT 1];
        List<DocumentType__c> docType = [SELECT Id FROM DocumentType__c WHERE Type__c = 'Generated Invoice'];
        List<Document__c> docList = [SELECT Id FROM Document__c WHERE BrokerCommission__c =: invoiceList[0].Id AND DocumentType__c = : docType[0].Id];
        
        ContentDocumentLink cdlink = TestDataFactory.createContentDocumentLink(cv.ContentDocumentId, docList[0].Id, null, null);
        insert cdlink;
        
        Test.startTest();
        // Fetching Commission Invoice
        BrokerCommission__c invoice = [SELECT Id, Status__c From BrokerCommission__c LIMIT 1];
        // Calling Share Commission Invoice
        String isSuccess = BrokerCommissionController.shareCommissionInvoice(invoice.Id, con.Id);
        Test.stopTest();
        Assert.areEqual('true', isSuccess, 'Send invoice failed');
    }


    @IsTest
    static void testGetBrokerCommissionDocuments(){
        ContentVersion cv = [SELECT Id,ContentDocumentId FROM ContentVersion LIMIT 1];
        List<BrokerCommission__c> bc = [SELECT Id FROM BrokerCommission__c WHERE Status__c = 'Draft' LIMIT 1];
        System.debug('broker-->>'+bc);
        Test.startTest();
            List<Document__c> documents = [SELECT Id, Document_Name__c, ContentDocumentId__c FROM Document__c 
                                        WHERE BrokerCommission__c =: bc[0].Id AND Document_Name__c = 'Generated Invoice'];
            documents[0].ContentDocumentId__c = cv.ContentDocumentId;
            UPDATE documents;
            String result = JSON.serialize(BrokerCommissionController.getBrokerCommissionDocuments(bc[0].Id));
        Test.stopTest();
        Assert.areNotEqual(null, result, 'Document should be retrieved');
    }

    @IsTest
    static void testAttachCombinedDocument(){
        List<BrokerCommission__c> bc = [SELECT Id FROM BrokerCommission__c WHERE Status__c = 'Draft' LIMIT 1];
        ContentVersion cv = [SELECT Id,ContentDocumentId FROM ContentVersion LIMIT 1];
        Test.startTest();
            List<Document__c> documents = [SELECT Id, Document_Name__c, ContentDocumentId__c FROM Document__c 
                                        WHERE BrokerCommission__c =: bc[0].Id AND Document_Name__c = 'Broker Invoice Combined Document'];
            documents[0].ContentDocumentId__c = cv.ContentDocumentId;
            UPDATE documents;
            
            String result = BrokerCommissionController.attachCombinedDocument('merged test data',bc[0].Id);
        Test.stopTest();
        Assert.areEqual('Combined document generated successfully!', result, 'Error while document merging');
    }
}