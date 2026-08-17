/*****************************************************************************************
Class       : LeasingMoveOutFormBatchSchedulerTest
Author      : 
Description : 
Test Class  : 
Created Date: 
*****************************************************************************************/
@isTest
private class LeasingMoveOutFormBatchSchedulerTest {
    @testSetup
    static void setupData() {
        Id personRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'PersonAccount' LIMIT 1].Id;
        Account accPerson = new Account(LastName = 'Test Person',  RecordTypeId = personRecordTypeId, PersonEmail = 'test@test.com', PersonMobilePhone = '00971111111111');
        insert accPerson;
        
        Id orgRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'OrganizationAccount' LIMIT 1].Id;
        Account acc = new Account(Name = 'TestOrganisation',  RecordTypeId = orgRecordTypeId);
        insert acc;
        
        
        Contact con = new Contact(LastName='Test Contact', Email='test@test.com', AccountId=acc.Id);
        insert con;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = accPerson.Id
        );
        insert opp;

        Unit__c unit = new Unit__c(Name = 'Test Unit',PropertyUsage__c='Commercial');
        insert unit;

        LeasingOrder__c lo = new LeasingOrder__c(
            Name = 'Test LO',
            Opportunity__c = opp.Id,
            Account__c = accPerson.Id,
            Unit__c = unit.Id
        );
        insert lo;
        
          // Insert dummy DocuSign template with a valid UUID format
        dfsle__EnvelopeConfiguration__c envelopeTemplate = new dfsle__EnvelopeConfiguration__c(
            Name = 'Test Template',
            dfsle__DocuSignId__c = 'fde1ec0a-94f8-44df-82da-dcbda1419eb9' // Valid UUID format
        );
        insert envelopeTemplate;
        
        Loop__DDP__c testTemplate3 = new Loop__DDP__c(Name = 'Test Template3');
        insert testTemplate3;
        
        Loop__DDP_Integration_Option__c testDeliveryOption3 = new Loop__DDP_Integration_Option__c(Name = 'Test Delivery Option Three');
        testDeliveryOption3.Loop__DDP__c= testTemplate3.id;
        insert testDeliveryOption3;
        
        // Create DocumentType for DocSign
        DocumentType__c ds = new DocumentType__c(
            
            ObjectType__c='LeasingOrder__c',
            Active__c=true,
            IsDocgen__c=true,
            DigitalSignature__c=true,
            Type__c='Move Out Request Form',
            Document_Output_Name__c='Output',
            Document_Digital_Name__c='Digital',
            Docusign_Envelope_Template__c = envelopeTemplate.Id
        );
        insert ds;
        
        // Create ContentVersion (this auto-creates ContentDocument)
        ContentVersion cv = new ContentVersion(
            Title = 'Leasing Contract.pdf',
            PathOnClient = 'Leasing Contract.pdf',
            VersionData = Blob.valueOf('Test file body'),
            IsMajorVersion = true
        );
        insert cv;
        
        // After insert, query ContentDocumentId from ContentVersion
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        ContentDocument cd = [SELECT Id FROM ContentDocument WHERE Id = :cv.ContentDocumentId];
        

          // Create Document
        Document__c doc = new Document__c(
            LeasingOrder__c = lo.Id,
            Document_Name__c = 'Move Out Request Form',
            DocumentType__c = ds.id,
            Content_Version_Id__c = cv.Id ,
            ContentDocumentId__c = cv.ContentDocumentId
        );
        insert doc;
                // Link the file to the Document__c record
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = doc.Id,
            ContentDocumentId = cd.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;   
        
    }

    @isTest
    static void testSendForSignature() {
         LeasingOrder__c lo = [SELECT Id,PropertyName__c,Unit__r.LeasingUnitNumber__c, TerminationNoticeDate__c, Status__c FROM LeasingOrder__c LIMIT 1];
         lo.TerminationNoticeDate__c = Date.Today();
         lo.Status__c = 'Terminated';
         update lo;
        // List<DocumentType__c>    = [SELECT Id, Type__c, Document_Output_Name__c,
        //                               Docusign_Envelope_Template__r.dfsle__DocuSignId__c,
        //                               Document_Digital_Name__c FROM DocumentType__c
        //                               WHERE DigitalSignature__c = true LIMIT 1];
        
        Test.startTest();
         User adminUser = [SELECT Id, name, email FROM User WHERE name = 'admin' LIMIT 1];
        
        System.runAs(adminUser) {
            try {
                LeasingMoveOutFormBatch  m = new LeasingMoveOutFormBatch ();
                String sch = '20 30 8 10 2 ?';
                
                String jobID = System.schedule('Merge Job', sch, m);

                Database.executeBatch(new LeasingMoveOutFormBatch());
            } catch (Exception ex) {
               
            }
        }
       
        Test.stopTest();
        
      
    }
}