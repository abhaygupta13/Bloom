@isTest
public class DocGenControllerTest {
    @isTest 
    static void DocGenControllerTestMethod(){
        Project__c testProject=new Project__c(
            Name='Test Project'
        );
        insert testProject;
        
        
        
        BuildingSection__c testBuilding=new BuildingSection__c(
            Name='Test Building',
            BuildingSectionCode__c='BL-CAS',
            Project__c=testProject.Id
            
        );
        insert testBuilding;
        DateTime lockExpiryTime = DateTime.now().addDays(10);
        
        Unit__c testUnit=new Unit__c(
            Name='test Unit',
            Status__c='Available',
            UnitType__c='Townhouse',
            BuildingSectionName__c=testBuilding.id,
            Project__c=testProject.Id,
            PropertyUsage__c='Residential',
            UnitView__c  ='Beach Side',
            FloorNumber__c='01',
            NumberOfBedrooms__c='3',
            UnitModel__c='1BHK',
            SellingPrice__c= 700000,
            EndDate__c= date.today()+10,
            StartDate__c=date.today()-10,
            LockExpiryTime__c = lockExpiryTime
            
        );
        insert testUnit;
        
        
        Unit__c testUnit1=new Unit__c(
            Name='test Unit1',
            Status__c='Available',
            UnitType__c='Townhouse',
            BuildingSectionName__c=testBuilding.id,
            Project__c=testProject.Id,
            PropertyUsage__c='Residential',
            UnitView__c  ='Beach Side',
            FloorNumber__c='01',
            NumberOfBedrooms__c='3',
            UnitModel__c='1BHK',
            SellingPrice__c= 700000,
            EndDate__c= date.today()+10,
            StartDate__c=date.today()-10,
            LockExpiryTime__c = lockExpiryTime
            
            
        );
        insert testUnit1;
        
        
        
        
        PaymentPlan__c  pp = new PaymentPlan__c();
        pp.Name ='July Plan';
        pp.Unit__c= testUnit.id;
        pp.Description__c ='Test Description';
        pp.Description__c = 'Test';
        pp.IsActive__c = 'NO';
        pp.BrokerPortalFlag__c = True;
        pp.CustomerSubType__c ='CORPORATE';
        pp.Classification__c = Constants.PAYMENT_PLAN_TYPE_STANDARD;
        
        insert pp;
        
        BuildingSectionMapping__c mappingRecord = new BuildingSectionMapping__c();
        mappingRecord.BuildingSectionName__c = testBuilding.id;
        mappingRecord.PaymentPlan__c = pp.id;
        insert mappingRecord;
        
        
        
        
        Id AccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Account tempAcc=new Account(
            RecordTypeId=AccountRecordTypeId,
            LastName= 'test',
            personEmail='Jana@tesrt.com',
            CustomerSubType__c ='CORPORATE'
            
        );
        insert tempAcc;
        
        
        Opportunity tempOpp=new Opportunity(
            Name='tempOpp',
            StageName='New',
            CloseDate=system.today(),
            LeadChannel__c='Walk in',
            AccountId=tempAcc.Id,
            WinReason__c='Loyalty'
        );
        insert tempOpp;
        OffersPromotions__c testOffer=new OffersPromotions__c(
            Name='testOffer',
            Unit__c=testUnit.id,
            OfferName__c='testOffer',
            Project__c=testProject.id,
            StartDate__c=system.today(),
            EndDate__c=system.today().addDays(2),
            BuildingSectionName__c=testBuilding.id
            
            
            
        );
        insert testOffer;
        
        OfferLines__c tempOffer=new OfferLines__c(
            OfferType__c='Voucher',
            LowerBound__c=60,
            UpperBound__c=90,
            OfferName__c=testOffer.Id,
            OfferOn__c = 'Selling Price',
            BudgetTaskName__c ='ADM Fee',
            
            DiscountType__c = 'Additional Discount',
            OfferValue__c = 10,
            Nationality__c=null
            
        );
        insert tempOffer;
        
        
        
        
        PaymentInstallments__c ppi = new PaymentInstallments__c();
        ppi.BrokerPayoutPercentage__c =100;
        ppi.Description__c = 'test description';
        ppi.InstallmentNumber__c = 1;
        ppi.InstallmentPercentage__c=100;
        ppi.PaymentPlan__c = pp.id;
        ppi.InstallmentPercentage__c=100;
        ppi.Condition_Type__c='P012';
        insert ppi;
        
        pp.IsActive__c = 'Yes';
        Update pp;
        
        testUnit.Status__c ='Booked';
        testUnit.LockedBy__c = Userinfo.getUserId();
        update testUnit;
        
        Loop__DDP__c testTemplate = new Loop__DDP__c(Name = 'Test Template');
        
        insert testTemplate;
        
        Loop__DDP_Integration_Option__c testDeliveryOption = new Loop__DDP_Integration_Option__c(Name = 'Test Delivery Option');
        testDeliveryOption.Loop__DDP__c= testTemplate.id;
        insert testDeliveryOption;
        
        DocumentType__c docTypeRec = new DocumentType__c();
        docTypeRec.ObjectType__c = 'Sales Order';
        docTypeRec.Type__c = 'Cancellation & Termination Agreement';
        docTypeRec.DeliveryOption__c = testDeliveryOption.Id;
        docTypeRec.DocGenPackage__c = testTemplate.Id;
        docTypeRec.IsDocgen__c = true;
        docTypeRec.Project__c = testProject.Id;
        insert docTypeRec;
        
        DocumentType__c docTypeRec6 = new DocumentType__c();
        docTypeRec6.ObjectType__c = 'Handover';
        docTypeRec6.Type__c = 'Cancellation & Termination Agreement';
        docTypeRec6.DeliveryOption__c = testDeliveryOption.Id;
        docTypeRec6.DocGenPackage__c = testTemplate.Id;
        docTypeRec6.IsDocgen__c = true;
        docTypeRec6.Project__c = testProject.Id;
        insert docTypeRec6;
        
        SalesOrder__c testOrder = new SalesOrder__c(
            Name = 'Test Order',
            Status__c = 'Booked',
            Unit__c =testUnit.id,
            Account__c = tempAcc.Id,
            Opportunity__c= tempOpp.Id,
            IsDraftOrder__c = true
            //Project__c = testProject.Id
            
        );
        insert testOrder;
        
        Document__c docRec1 = new Document__c();
        docRec1.Document_Name__c = 'Cancellation & Termination Agreement';
        docRec1.SalesOrder__c = testOrder.Id;
        docRec1.DocumentType__c = docTypeRec.Id; 
        insert docRec1;
        
        // Create file for SalesOrder Document (needed by Handover trigger)
        ContentVersion soVersion = new ContentVersion(
            Title = 'Cancellation & Termination Agreement.pdf',
            PathOnClient = 'Cancellation & Termination Agreement.pdf',
            VersionData = Blob.valueOf('Test File')
        );
        insert soVersion;
        
        ContentVersion soInsertedVersion = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :soVersion.Id
        ];
        
        ContentDocumentLink soCdl = new ContentDocumentLink(
            ContentDocumentId = soInsertedVersion.ContentDocumentId,
            LinkedEntityId = docRec1.Id,
            ShareType = 'V'
        );
        insert soCdl;
        
        Handover__c hoRec = new Handover__c();
        hoRec.Sales_Order__c = testOrder.Id;
        insert hoRec;
        
        Document__c hoDoc = new Document__c();
        hoDoc.Document_Name__c = 'Cancellation & Termination Agreement'; // MUST MATCH
        hoDoc.HandOver__c = hoRec.Id;
        hoDoc.DocumentType__c = docTypeRec6.Id;
        insert hoDoc;
        
        Document__c docRec2 = new Document__c();
        docRec2.Document_Name__c = 'Developer NOC';
        docRec2.HandOver__c = hoRec.Id;
        insert docRec2;
        
        Loop__DDP__c testTemplate2 = new Loop__DDP__c(Name = 'Test Template2');
        insert testTemplate2;
        
        Loop__DDP_Integration_Option__c testDeliveryOption2 = new Loop__DDP_Integration_Option__c(Name = 'Test Delivery Option TWO');
        testDeliveryOption2.Loop__DDP__c= testTemplate2.id;
        insert testDeliveryOption2;
        
        DocumentType__c docTypeRec2 = new DocumentType__c();
        docTypeRec2.ObjectType__c = 'Handover';
        docTypeRec2.Type__c = 'Developer NOC';
        docTypeRec2.DeliveryOption__c = testDeliveryOption2.Id;
        docTypeRec2.DocGenPackage__c = testTemplate2.Id;
        docTypeRec2.IsDocgen__c = true;
        docTypeRec2.Project__c = testProject.Id;
        insert docTypeRec2;
        
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
        // BAPP
        DocumentType__c docTypeRec3 = new DocumentType__c();
        docTypeRec3.ObjectType__c = 'Broker Application';
        docTypeRec3.Type__c = 'Broker Agreement';
        docTypeRec3.DeliveryOption__c = testDeliveryOption3.Id;
        docTypeRec3.DocGenPackage__c = testTemplate3.Id;
        docTypeRec3.IsDocgen__c = false;
        docTypeRec3.DigitalSignature__c = true;
        docTypeRec3.Docusign_Envelope_Template__c = envelopeTemplate.Id;
        docTypeRec3.Document_Output_Name__c ='Broker Agreement';
        //docTypeRec3.Active__c = true;
        insert docTypeRec3;

		Test.startTest();        
        // --- Setup for Broker Application ---
        User testUser = new User(
        FirstName = 'BBM',
        LastName = 'User',
        Alias = 'bbmu',
        Email = 'bbmuser@test.com',
        Username = 'bbmuser' + DateTime.now().getTime() + '@test.com',
        CommunityNickname = 'bbmu' + DateTime.now().getTime(),
        ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id,
        TimeZoneSidKey = 'GMT',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US'
        );
        insert testUser;

        BrokerApplication__c brokerApp = new BrokerApplication__c(Name = 'Test Broker App', ApprovalStatus__c = 'Draft', AgencyEmail__c='test@test.com',
        BBMId__c = testUser.Id,TypeofEstablishment__c ='Domestic', TradeLicenseNumber__c = '198273823664');
        insert brokerApp;
        
        BrokerApplicant__c applicant = new BrokerApplicant__c(
        BrokerApplication__c = brokerApp.Id,
        Email__c = 'signer@test.com',
        BrokerContactRole__c = 'AuthorizedSignatoryOfficer'
        );
        insert applicant;

        
        // Step 1: Create ContentVersion (auto-creates ContentDocument)
        ContentVersion contentVersion = new ContentVersion(
            Title ='Broker Agreement',
            PathOnClient ='Broker Agreement.pdf',
            VersionData = Blob.valueOf('Sample content')
        );
        insert contentVersion;
        
        // Step 2: Query the generated ContentDocumentId
        ContentVersion insertedVersion = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :contentVersion.Id
            LIMIT 1
        ];
        System.debug('insertedVersion---->'+insertedVersion);
        ContentDocument testCD = [SELECT Id, Title,LatestPublishedVersion.Title FROM ContentDocument WHERE Id =: insertedVersion.ContentDocumentId];
        System.debug('testCD----->'+testCD);
        
        /*// Step 3: Link the ContentDocument to the Broker Application
ContentDocumentLink cdl = new ContentDocumentLink(
ContentDocumentId = insertedVersion.ContentDocumentId,
LinkedEntityId = brokerApp.Id, // Your BrokerApplication__c.Id
ShareType = 'V'
);
insert cdl;
System.debug('cdl----->'+cdl);*/
        
        docTypeRec3 = [
            SELECT Id, Type__c,Document_Output_Name__c,Document_Digital_Name__c,Docusign_Envelope_Template__r.dfsle__DocuSignId__c
            FROM DocumentType__c
            WHERE Id = :docTypeRec3.Id
        ];
        
        // Document record for Broker Application
        Document__c brokerDoc = new Document__c(
            Document_Name__c ='Broker Agreement',
            BrokerApplication__c = brokerApp.Id,
            Content_Version_Id__c = contentVersion.Id,
            ContentDocumentId__c = contentVersion.ContentDocumentId,
            DocumentType__c = docTypeRec3.Id
        );
        insert brokerDoc;
        
        // Step 3: Link the ContentDocument to the Broker Application
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = insertedVersion.ContentDocumentId,
            LinkedEntityId = brokerDoc.Id, // Your BrokerApplication__c.Id
            ShareType = 'V'
        );
        insert cdl;
        System.debug('cdl----->'+cdl);
        
         // Create test Account
        Account acc = new Account(FirstName = 'FirstNameAccount', LastName = 'LastNameAccount', PersonEmail= 'test@test.com', PersonMobilePhone = '9876543210');
        insert acc;
        
        DocumentType__c docTypeRecAcc = new DocumentType__c();
        docTypeRecAcc.ObjectType__c = 'Account';
        docTypeRecAcc.Type__c = 'Registration Agreement';
        docTypeRecAcc.DeliveryOption__c = testDeliveryOption2.Id;
        docTypeRecAcc.DocGenPackage__c = testTemplate2.Id;
        docTypeRecAcc.IsDocgen__c = true;
        docTypeRecAcc.Project__c = testProject.Id;
        insert docTypeRecAcc;
        
        Document__c docRecAcc = new Document__c();
        docRecAcc.Document_Name__c = 'Cancellation & Termination Agreement';
        docRecAcc.Account__c = acc.Id;
        insert docRecAcc;
        
        // prepare a Case for testing
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Default Unit').getRecordTypeId();
        // Create test Case related to the Account
        Case cs = new Case(Status = 'New', Origin = 'Phone', AccountId = acc.Id, RecordTypeId= RecordTypeCaseId, Project__c = testProject.Id);
        insert cs;
        
        DocumentType__c docTypeRecCase = new DocumentType__c();
        docTypeRecCase.ObjectType__c = 'Case';
        docTypeRecCase.Type__c = 'Default Notice';
        docTypeRecCase.DeliveryOption__c = testDeliveryOption2.Id;
        docTypeRecCase.DocGenPackage__c = testTemplate2.Id;
        docTypeRecCase.IsDocgen__c = true;
        docTypeRecCase.Project__c = testProject.Id;
        insert docTypeRecCase;
        
        Document__c docRecCase = new Document__c();
        docRecCase.Document_Name__c = 'Default Notice';
        docRecCase.Case__c = cs.Id;
        insert docRecCase;
        
        //List<Document__c> docList = [select Id, ContentDocumentId__c, Document_Name__c FROM Document__c Where SalesOrder__c =: testOrder.Id];
        System.debug('docList2 ::::: '+ docRec2.Id);
        
        DocGenController.getSalesOrderRec(testOrder.Id);
        DocGenController.getDocgenSetupRecords(testOrder.id);
        
        List<DocumentType__c> bappDocTypeList = [SELECT Id, Type__c, Docusign_Envelope_Template__r.dfsle__DocuSignId__c, 
                                                 Document_Output_Name__c, Document_Digital_Name__c 
                                                 FROM DocumentType__c WHERE Id = :docTypeRec3.Id];
        System.debug('Document Type__c for Docusign'+ bappDocTypeList[0].Docusign_Envelope_Template__r.dfsle__DocuSignId__c);
        
        
        try {
            DocGenController.generateDocument(testDeliveryOption.id,testTemplate.id,testOrder.id, docTypeRec.Type__c);
        } catch (AuraHandledException ex) {
            System.assertEquals('Script-thrown exception', ex.getMessage());
        }
        Test.stopTest();
        
        /*Test.startTest();
        try {
            DocGenController.generateDocument(testDeliveryOption3.Id,testTemplate3.Id,brokerApp.Id, docTypeRec3.Type__c);
        } catch (AuraHandledException ex) {
            System.assertEquals('Script-thrown exception', ex.getMessage());
        }
        Test.stopTest();*/
        DocGenController.getDocgenSetupRecords(cs.Id);
        DocGenController.generateDocument(testDeliveryOption2.id,testTemplate2.id,cs.id, docTypeRecCase.Type__c);
        DocGenController.getDocgenSetupRecords(acc.Id);
        DocGenController.generateDocument(testDeliveryOption2.id,testTemplate2.id,acc.id, docTypeRecAcc.Type__c);
        DocGenController.getDocgenSetupRecords(hoRec.id);
        DocGenController.generateDocument(testDeliveryOption2.id,testTemplate2.id,hoRec.id, docTypeRec.Type__c);
        DocGenController.generateDocument(testDeliveryOption3.Id,testTemplate3.Id,brokerApp.Id, docTypeRec3.Type__c);
        DocGenController.getDocumentTypeRecords(testOrder.id);
        DocGenController.getSalesOrderRecord(testOrder.id);
        DocGenController.getDocumentAndEmailTemplateRecords(testOrder);
        List<DocumentType__c> result = DocGenController.getDocgenSetupRecords(brokerApp.Id);
        List<DocumentType__c> result2 = DocGenController.getDocumentTypeRecords(brokerApp.Id);
        List<DocumentType__c> docTypeList = new List<DocumentType__c>();
        docTypeList.add(docTypeRec);
        List<DocumentType__c> docTypeList2 = new List<DocumentType__c>();
        docTypeList2.add(docTypeRec3);
        DocGenController.sendForSignature(testOrder, docTypeList);
        User adminUser = [SELECT Id, name, email FROM User WHERE name = 'admin' LIMIT 1];
        system.debug('adminUser------------>' +adminUser);
        System.runAs(adminUser) {
            try {
                DocGenController.sendForBappSignature(brokerApp.Id, new List<DocumentType__c>{ docTypeRec3 });
            } catch (Exception ex) {
                System.debug('Expected exception during test: ' + ex.getMessage());
                // Optionally assert the message
                System.assert(ex.getMessage().containsIgnoreCase('DocuSign'), 'Expected DocuSign config error');
            }
        }
        DocGenController.updateApprovalStatusToUnderAgreement(brokerApp.Id);
        DocGenController.getBrokerApplicationRecord(brokerApp.Id);
		DocGenController.generateAgreementNumberBrokerApplication(brokerApp.Id);
        //DocGenController.updateWordsandArabicField(testOrder.id);
        //System.assertNotEquals(0, result.size(), 'Expected document setup records for Broker Application');
    }
    
}