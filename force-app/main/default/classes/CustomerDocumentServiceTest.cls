@istest
public class CustomerDocumentServiceTest {
    @testSetup static void setup() {
        
        
        Account accountRecord =BCAPP_TestDataFactory.createAccount('Test Account');
        accountRecord.Azure_UserPrincipal_Id__c='testttt';
        insert accountRecord;
        
        
        Case testCase =BCAPP_TestDataFactory.createCase();
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Move In Holiday Homes').getRecordTypeId();
        testCase.RecordTypeId=RecordTypeCaseId;
        testCase.AccountId= accountRecord.id;
        testCase.Move_Out_Date__c=system.today();
        testCase.Email_Address__c='testuser@fff.com';
        testCase.User_Type__c=BCAPP_Constants.TENANT;
        insert testCase;
        
        
        
        Service_Catalog__c testServiceCatalog =BCAPP_TestDataFactory.createServiceCatalog();
        insert testServiceCatalog;
        testCase.Service_Catalog__c=testServiceCatalog.id;
        update testCase;
        Service_Catolog_Documents__c testService_Catolog_Documents =BCAPP_TestDataFactory.createServiceCatalogDocuments();
        testService_Catolog_Documents.Service_Catalog__c=testServiceCatalog.id;
        insert testService_Catolog_Documents;
        
        
        Service_Catalog_Fields__c testServiceCatalogFields =BCAPP_TestDataFactory.createserviceCatalogFields();
        testServiceCatalogFields.Service_Catalog__c=testServiceCatalog.id;
        insert testServiceCatalogFields;
        
        Customer_Document__c custDocs=BCAPP_TestDataFactory.createCustomerDocument();
        custDocs.Service_Catolog_Documents__c = testService_Catolog_Documents.Id;
        custDocs.Account__c = accountRecord.Id;
        insert custDocs;
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDoc.pdf',
            VersionData = Blob.valueOf('Test content'),
            IsMajorVersion = true
        );
        insert contentVersion;
        
        ContentVersion insertedVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
        String contentDocumentId = insertedVersion.ContentDocumentId;
        
        ContentDocumentLink documentLink = new ContentDocumentLink(
            ContentDocumentId = contentDocumentId,
            LinkedEntityId = custDocs.Id,
            ShareType = 'V', // Viewer access
            Visibility = 'AllUsers'
        );
        insert documentLink;
    }
    
    @IsTest
    static void testgetCustomerDocuments() {
        CustomerDocumentService instance=new CustomerDocumentService();
        instance.getCustomerDocuments([select id from case limit 1].id);
    }
    
    @IsTest
    static void testgetCustomerDocumentsByCatalogId() {
        CustomerDocumentService instance=new CustomerDocumentService();
        instance.getCustomerDocumentsByCatalogId([select id from Service_Catalog__c limit 1].id,[select id from case limit 1].id);
    }
    
    @IsTest
    static void testgetDocumentsCountOnCase() {
        CustomerDocumentService instance=new CustomerDocumentService();
        instance.getDocumentsCountOnCase([select id from case limit 1].id);
    }
    
    @IsTest
    static void testgetDocumentsRelatedToAccount() {
        CustomerDocumentService instance=new CustomerDocumentService();
        instance.getDocumentsRelatedToAccount([select id from Account limit 1].id);
    }
    
    
    @IsTest
    static void testgetcreateCustomerDocument() {
        CustomerDocumentService instance=new CustomerDocumentService();
        instance.createCustomerDocument(new List<Customer_Document__c>());
    }
    
      
    @IsTest
    static void testupdateCustomerDocument() {
        CustomerDocumentService instance=new CustomerDocumentService();
        
        List<Customer_Document__c> lstDocs=    new List<Customer_Document__c>();
        lstDocs.add([select id from Customer_Document__c limit 1]);
        instance.updateCustomerDocument(lstDocs);
    }
    
    
    
    
}