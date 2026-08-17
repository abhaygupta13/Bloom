@isTest
private class LeasingDocGenControllerTest {
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
        DocumentType__c ds = new DocumentType__c
            (
                ObjectType__c='LeasingOrder__c',
                Active__c=true,
                IsDocgen__c=false,
                DigitalSignature__c=true,
                Type__c='Leasing Offer',
                Document_Output_Name__c='Output',
                Document_Digital_Name__c='Digital',
                Docusign_Envelope_Template__c = envelopeTemplate.Id
            );
        insert ds;
        
        DocumentType__c ds1 = new DocumentType__c(
            
            ObjectType__c='LeasingOrder__c',
            Active__c=true,
            IsDocgen__c=false,
            DigitalSignature__c=true,
            Type__c='Move Out Request Form',
            Document_Output_Name__c='Output1',
            Document_Digital_Name__c='Digital1',
            Docusign_Envelope_Template__c = envelopeTemplate.Id
        );
        insert ds1;
        
        // Create ContentVersion (this auto-creates ContentDocument)
        ContentVersion cv = new ContentVersion(
            Title = 'Offer Letter',
            PathOnClient = 'Offer Letter.pdf',
            VersionData = Blob.valueOf('Test file body'),
            IsMajorVersion = true
        );
        insert cv;
        ContentVersion contractLetter = new ContentVersion(
            Title = 'Leasing Contract.pdf',
            PathOnClient = 'Leasing Contract.pdf',
            VersionData = Blob.valueOf('Test file body'),
            IsMajorVersion = true
        );
        insert contractLetter;
        
        ContentVersion cv1 = new ContentVersion(
            Title = 'Move Out Request Form',
            PathOnClient = 'Move Out Request Form.pdf',
            VersionData = Blob.valueOf('Test file body'),
            IsMajorVersion = true
        );
        insert cv1;
        
        // After insert, query ContentDocumentId from ContentVersion
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        ContentDocument cd = [SELECT Id FROM ContentDocument WHERE Id = :cv.ContentDocumentId];
        
        cv1 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv1.Id];
        ContentDocument cd1 = [SELECT Id FROM ContentDocument WHERE Id = :cv1.ContentDocumentId];
        
        
        
        
        // Create Document
        Document__c doc = new Document__c(
            LeasingOrder__c = lo.Id,
            Document_Name__c = 'Leasing Offer',
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
        
        
        
        Document__c doc1 = new Document__c(
            LeasingOrder__c = lo.Id,
            Document_Name__c = 'Move Out Request Form',
            DocumentType__c = ds1.id,
            Content_Version_Id__c = cv1.Id ,
            ContentDocumentId__c = cv1.ContentDocumentId
        );
        insert doc1;
        // Link the file to the Document__c record
        ContentDocumentLink cdl1 = new ContentDocumentLink(
            LinkedEntityId = doc1.Id,
            ContentDocumentId = cd1.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl1;
      
        
        DocumentType__c leasingRADocGenType = new DocumentType__c(ObjectType__c = 'LeasingReceiptAcknowledgment__c' ,
                                                                  Type__c = 'Leasing Receipt document',
                                                                  Customer_Type__c = 'Individual' ,
                                                                  ProcessType__c = 'Lease' ,
                                                                  Active__c =true ,
                                                                  DeliveryOption__c = testDeliveryOption3.id ,
                                                                  DocGenPackage__c = testTemplate3.id,
                                                                  IsDocgen__c = true
                                                                 );
        insert leasingRADocGenType ;
        
        LeasingReceiptAcknowledgment__c receipt = new LeasingReceiptAcknowledgment__c(
            LeasingOrder__c = lo.Id,
            Amount__c = 10000
        );
        insert receipt;
        
        Document__c leasingRADoc = new Document__c(
            LeasingReceiptAcknowledgment__c  = receipt.Id,
            Document_Name__c = 'Leasing Receipt document',
            DocumentType__c = leasingRADocGenType.id
            
        );
        insert leasingRADoc;
        
        DocumentType__c   leasingOrderDocGenType = new DocumentType__c(ObjectType__c = 'LeasingOrder__c' ,
                                                                       Type__c = 'Leasing Contract',
                                                                       Customer_Type__c = 'Individual' ,
                                                                       ProcessType__c = 'Lease' ,
                                                                       Active__c =true ,
                                                                       DeliveryOption__c = testDeliveryOption3.id ,
                                                                       DocGenPackage__c = testTemplate3.id,
                                                                       IsDocgen__c = true,
                                                                       DigitalSignature__c = true  ,   
                                                                       Docusign_Envelope_Template__c = envelopeTemplate.Id 
                                                                      );
        insert leasingOrderDocGenType ;
        contractLetter = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contractLetter.Id];
        ContentDocument contractLetterCD = [SELECT Id FROM ContentDocument WHERE Id = :contractLetter.ContentDocumentId];
        Document__c leasingOrderDoc = new Document__c(
            LeasingOrder__c = lo.Id,
            Document_Name__c = 'Leasing Contract',
            DocumentType__c = leasingOrderDocGenType.id, 
            Content_Version_Id__c = contractLetter.Id ,
            ContentDocumentId__c = contractLetter.ContentDocumentId
            
        );
        insert leasingOrderDoc;
        
        ContentDocumentLink leasingContractCDL = new ContentDocumentLink(
            LinkedEntityId = leasingOrderDoc.Id,
            ContentDocumentId = contractLetterCD.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert leasingContractCDL;
    }
    @isTest
    static void testGetLeasingOrderRec() {
        LeasingOrder__c lo = [SELECT Id FROM LeasingOrder__c LIMIT 1];
        Test.startTest();
        LeasingOrder__c result = LeasingDocGenController.getLeasingOrderRec(lo.Id);
        Test.stopTest();
        System.assertEquals(lo.Id, result.Id);
    }
    @isTest
    static void testGetDocSignSetupRecords() {
        LeasingOrder__c lo = [SELECT Id FROM LeasingOrder__c LIMIT 1];
        List<DocumentType__c> docs = LeasingDocGenController.getDocSignSetupRecords(lo.Id);
    }
    @isTest
    static void testLeasingOfferSendForSignature() {
        LeasingOrder__c lo = [SELECT Id,PropertyName__c,Unit__r.LeasingUnitNumber__c,owner.email FROM LeasingOrder__c LIMIT 1];
        List<DocumentType__c> docs = [SELECT Id, Type__c, Document_Output_Name__c,
                                      Docusign_Envelope_Template__r.dfsle__DocuSignId__c,
                                      Document_Digital_Name__c FROM DocumentType__c
                                      WHERE DigitalSignature__c = true AND  Type__c='Leasing Offer' LIMIT 1];
        
        Test.startTest();
        User adminUser = [SELECT Id, name, email FROM User WHERE name = 'admin' LIMIT 1];
        
        System.runAs(adminUser) {
            LeasingDocGenController.sendForSignature(lo, docs[0]);
        }
        Test.stopTest();
    }
    @isTest
    static void testLeasingContractSendForSignature() {
        LeasingOrder__c lo = [SELECT Id,PropertyName__c,Unit__r.LeasingUnitNumber__c FROM LeasingOrder__c LIMIT 1];
        List<DocumentType__c> docs = [SELECT Id, Type__c, Document_Output_Name__c,
                                      Docusign_Envelope_Template__r.dfsle__DocuSignId__c,
                                      Document_Digital_Name__c FROM DocumentType__c
                                      WHERE DigitalSignature__c = true AND  Type__c = 'Leasing Contract' LIMIT 1];
        
        Test.startTest();
        User adminUser = [SELECT Id, name, email FROM User WHERE name = 'admin' LIMIT 1];
        
        System.runAs(adminUser) {
            LeasingDocGenController.sendForSignature(lo, docs[0]);
        }
        Test.stopTest();
    }
    @isTest
    static void testLeasingOrderGenerateDocument() {
        DocumentType__c loDoctype = [SELECT DeliveryOption__c,DocGenPackage__c  FROM DocumentType__c WHERE Type__c = 'Leasing Contract'];
        LeasingOrder__c lo = [Select id from LeasingOrder__c LIMIT 1];
        LeasingDocGenController.generateDocument( loDoctype.DeliveryOption__c, loDoctype.DocGenPackage__c, lo.id, 'Leasing Contract');
    }
    @isTest
    static void testLeasingRAGenerateDocument() {
        DocumentType__c loDoctype = [SELECT DeliveryOption__c,DocGenPackage__c  FROM DocumentType__c WHERE Type__c = 'Leasing Receipt document'];
        LeasingReceiptAcknowledgment__c lo = [Select id from LeasingReceiptAcknowledgment__c LIMIT 1];
        LeasingDocGenController.generateDocument( loDoctype.DeliveryOption__c, loDoctype.DocGenPackage__c, lo.id, 'Leasing Receipt document');
    }
    
}