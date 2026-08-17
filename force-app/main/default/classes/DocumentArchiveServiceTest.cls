/*****************************************************************************************
Class       : DocumentArchiveServiceTest
Author      : Ranjan
Description : Test class for DocumentArchiveService
Created Date: 29 Apr 2026
------------------------------------------------------------------------------------------
-- History --
------------------------------------------------------------------------------------------
Sr.No.  Version         Date            Details
1.      V1.0            29 Apr 2026     Initial Version
*****************************************************************************************/
@isTest
public class DocumentArchiveServiceTest {

    @TestSetup
    static void setupData() {
        // Create a DocumentType
        DocumentType__c documentType = TestDataFactory.createDocumentType('Account', 'Emirates ID');
        insert documentType;

        // Create a parent Document__c
        Document__c document = TestDataFactory.createDocument(null, documentType.Id, 'test');
        insert document;

        // Create DocumentArchive__c records linked to the document
        List<DocumentArchive__c> archiveList = new List<DocumentArchive__c>();
        for (Integer i = 0; i < 3; i++) {
            DocumentArchive__c archive = new DocumentArchive__c();
            archive.Document__c = document.Id;
            archive.ContentDocumentId__c = 'DEMO_CONTENT_ID_' + i; // adjust field type/value as needed
            archiveList.add(archive);
        }
        insert archiveList;
    }

    @isTest
    static void testGetInstance() {
        Test.startTest();
        DocumentArchiveService instance1 = DocumentArchiveService.getInstance();
        DocumentArchiveService instance2 = DocumentArchiveService.getInstance();
        Test.stopTest();

        // Singleton: both calls should return the same instance
        System.assertNotEquals(null, instance1, 'Instance should not be null');
        System.assertEquals(instance1, instance2, 'getInstance should return the same singleton instance');
    }

    @isTest
    static void testInsertDocumentArchives_WithRecords() {
        Document__c doc = [SELECT Id FROM Document__c LIMIT 1];

        List<DocumentArchive__c> newArchives = new List<DocumentArchive__c>();
        for (Integer i = 0; i < 2; i++) {
            DocumentArchive__c archive = new DocumentArchive__c();
            archive.Document__c = doc.Id;
            archive.ContentDocumentId__c = 'NEW_CONTENT_ID_' + i;
            newArchives.add(archive);
        }

        Test.startTest();
        List<DocumentArchive__c> result = DocumentArchiveService.getInstance().insertdocumentArchives(newArchives);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(2, result.size(), 'Should have inserted 2 archive records');
        for (DocumentArchive__c archive : result) {
            System.assertNotEquals(null, archive.Id, 'Inserted record should have an Id');
        }
    }

    @isTest
    static void testInsertDocumentArchives_WithNullList() {
        Test.startTest();
        List<DocumentArchive__c> result = DocumentArchiveService.getInstance().insertdocumentArchives(null);
        Test.stopTest();

        System.assertEquals(null, result, 'Result should be null when null is passed');
    }

    @isTest
    static void testInsertDocumentArchives_WithEmptyList() {
        Test.startTest();
        List<DocumentArchive__c> result = DocumentArchiveService.getInstance().insertdocumentArchives(new List<DocumentArchive__c>());
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Result should be an empty list');
    }

    @isTest
    static void testGetDocumentArchiveByDocumentId_WithResults() {
        Document__c doc = [SELECT Id FROM Document__c LIMIT 1];

        Test.startTest();
        List<DocumentArchive__c> archiveList = DocumentArchiveService.getInstance().getDocumentArchiveByDocumentId(doc.Id);
        Test.stopTest();

        System.assertNotEquals(null, archiveList, 'Archive list should not be null');
        System.assertEquals(3, archiveList.size(), 'Should return 3 archive records for the document');
        for (DocumentArchive__c archive : archiveList) {
            System.assertEquals(doc.Id, archive.Document__c, 'Each archive should be linked to the correct document');
        }
    }

    @isTest
    static void testGetDocumentArchiveByDocumentId_WithNoResults() {
        // Create a new document with no archives
        DocumentType__c documentType = [SELECT Id FROM DocumentType__c LIMIT 1];
        Document__c emptyDoc = TestDataFactory.createDocument(null, documentType.Id, 'empty-doc');
        insert emptyDoc;

        Test.startTest();
        List<DocumentArchive__c> archiveList = DocumentArchiveService.getInstance().getDocumentArchiveByDocumentId(emptyDoc.Id);
        Test.stopTest();

        System.assertNotEquals(null, archiveList, 'Archive list should not be null');
        System.assertEquals(0, archiveList.size(), 'Should return 0 archives for a document with no archives');
    }
}