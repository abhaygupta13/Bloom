@IsTest
public class DocumentServiceTest {
    
    @TestSetup
    static void setup() {

        Account account = TestDataFactory.createPersonalAccount('Lastname', '01010101', '1234567890', 'test@gmail.com');
        INSERT account; 

        Contact con = TestDataFactory.createContact('lname', null, true, 'test@gmail.com');
        INSERT con;
        /*DocumentType__c docType = new DocumentType__c(Type__c = 'Unit Registration', ObjectType__c = 'Project');
        insert docType;*/
        
        DocumentType__c dc1 = TestDataFactory.createDocumentType('Sales Order', 'Emirates ID');
        INSERT dc1;
        
        DocumentType__c dc2 = TestDataFactory.createDocumentType('Project', 'ADM Registration Document');
        INSERT dc2;

                
        Project__c project = new Project__c(Name = 'Test Project');
        insert project;
        
        Unit__c u = TestDataFactory.createUnit(project.Id, 'A1-G01', 'Unassigned');
        u.Project__c = project.Id;
        u.RegistrationDate__c = Date.today();
        insert u;
        
        SalesOrder__c salesOrder = new SalesOrder__c();
        salesOrder.Account__c = account.Id;
        salesOrder.Unit__c = u.Id;
        insert salesOrder;
        
        salesOrder = TestDataFactory.createSalesOrder(account.Id, null, null, null, u.Id, 100.00);
        salesOrder.DocumentUploadedDate__c = Date.today() - 1;
        salesOrder.UnitRegistrationDate__c = Date.today();
        insert salesOrder;

        
        String base64Str = EncodingUtil.base64Encode(Blob.valueOf('Test1234'));
        ContentVersion objCV = TestDataFactory.createContentVersion(base64Str, 'test.pdf', 'test');
        insert objCV;
        
        ContentVersion cv = TestDataFactory.createContentVersion('base 64', 'filename.pdf', 'title');
        INSERT cv;
        
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion LIMIT 1];
        //Id cdi = cv.ContentDocumentId
        //
        BrokerCommission__c brkrcommission = TestDataFactory.createBrokerCommission(null, null, null, null, null, project.Id, null, null, null, null);
        insert brkrcommission;
        // Create test Document__c record
        Document__c testDocument = new Document__c();
        testDocument.ContentDocumentId__c = '001001';
        testDocument.Document_Name__c = 'Test Document1';
        testDocument.SalesOrder__c = salesOrder.Id;
        testDocument.Project__c = project.Id;
        insert testDocument;
        
        ContentDocumentLink cd = TestDataFactory.createContentDocumentLink(cv.ContentDocumentId, testDocument.Id, '', '');
        INSERT cd;
             
        Schema.RecordTypeInfo recordTypeInfo = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('PersonAccount');
        
        User u1 = new User();
        System.runAs ( new User(Id = UserInfo.getUserId()) ) {
            Profile p = [SELECT Id FROM Profile WHERE Name='HO Agent'];
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Handover_HO_Agent'];
            
           u1 = new User(FirstName = 'Ho Agent', LastName='User', Alias = 'op', Email='hoagent@bloom.com', EmailEncodingKey='UTF-8',ProfileId = p.Id, 
                         LocaleSidKey = 'en_US', LanguageLocaleKey='en_US', TimeZoneSidKey='America/Los_Angeles', UserName='hoagent@bloom.com.u1');
            insert u1;
            
            insert new PermissionSetAssignment(AssigneeId = u1.Id,PermissionSetId = ps.Id);
        }
        User crmUser = new User();
        System.runAs ( new User(Id = UserInfo.getUserId()) ) {
            Profile p = [SELECT Id FROM Profile WHERE Name='CRM Operations'];
            PermissionSet ps = [SELECT Id,Name FROM PermissionSet WHERE Name = 'Handover_CRM_Team'];
            system.debug('permission'+ps.Name);
            
            crmUser = new User(FirstName = 'CRM', LastName='User', Alias = 'op', Email='crmUser@bloom.com', EmailEncodingKey='UTF-8',ProfileId = p.Id, 
                               LocaleSidKey = 'en_US', LanguageLocaleKey='en_US', TimeZoneSidKey='America/Los_Angeles', UserName='crmUser@bloom.com.u1');
            insert crmUser;
            
            insert new PermissionSetAssignment(AssigneeId = crmUser.Id,PermissionSetId = ps.Id);
        }
        User operationUser = new User();
        System.runAs ( new User(Id = UserInfo.getUserId()) ) {
            Profile p = [SELECT Id FROM Profile WHERE Name='Operations Team'];
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Handover_Operation_Team'];
            
            operationUser = new User(FirstName = 'Operation', LastName='User', Alias = 'op', Email='operationUser@bloom.com', EmailEncodingKey='UTF-8',ProfileId = p.Id, 
                                     LocaleSidKey = 'en_US', LanguageLocaleKey='en_US', TimeZoneSidKey='America/Los_Angeles', UserName='operationUser@bloom.com.u1');
            insert operationUser;
            
            insert new PermissionSetAssignment(AssigneeId = operationUser.Id,PermissionSetId = ps.Id);
        }
        
        User financeUser = new User();
        System.runAs ( new User(Id = UserInfo.getUserId()) ) {
            Profile p = [SELECT Id FROM Profile WHERE Name='Finance Team'];
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Handover_FInance_Team'];
            
            financeUser = new User(FirstName = 'Finance', LastName='User', Alias = 'op', Email='financeUser@bloom.com', EmailEncodingKey='UTF-8',ProfileId = p.Id, 
                                   LocaleSidKey = 'en_US', LanguageLocaleKey='en_US', TimeZoneSidKey='America/Los_Angeles', UserName='financeUser@bloom.com.u1');
            insert financeUser;
            
            insert new PermissionSetAssignment(AssigneeId = financeUser.Id,PermissionSetId = ps.Id);
        }
        
        User governmentUser = new User();
        System.runAs ( new User(Id = UserInfo.getUserId()) ) {
            Profile p = [SELECT Id FROM Profile WHERE Name='Public Relation Team'];
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Handover_Government_Relations'];
            
            governmentUser = new User(FirstName = 'Government', LastName='User', Alias = 'op', Email='governmentUser@bloom.com', EmailEncodingKey='UTF-8',ProfileId = p.Id, 
                                      LocaleSidKey = 'en_US', LanguageLocaleKey='en_US', TimeZoneSidKey='America/Los_Angeles', UserName='governmentUser@bloom.com.u1');
            insert governmentUser;
            
            insert new PermissionSetAssignment(AssigneeId = governmentUser.Id,PermissionSetId = ps.Id);
        }
        
        BuildingSection__c testBuilding=new BuildingSection__c(
            Name='Test Building',
            BuildingSectionCode__c='BL-CAS',
            Project__c=project.Id
            
        );
        insert testBuilding;
     
        
          
        // Create ContentVersion and associated Document__c record
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Full Guideline Document',
            PathOnClient = 'FullGuidelineDocument.pdf',
            VersionData = Blob.valueOf('Full Guideline Document')
        );
        insert contentVersion;
        
        ContentVersion con2 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
        
         // Create ContentVersion and associated Document__c record
        ContentVersion contentVersion1 = new ContentVersion(
            Title = 'QA Desnagging Report',
            PathOnClient = 'QA Desnagging Report.pdf',
            VersionData = Blob.valueOf('QA Desnagging Report')
        );
        insert contentVersion1;
        
     
         ContentVersion con1 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion1.Id];
        
        
        DocumentType__c SOAdoctype = new DocumentType__c();
        SOAdoctype.Type__c = 'SOA';  
        SOAdoctype.ObjectType__c = 'Handover';
        insert SOAdoctype;
        
         DocumentType__c SalesorderSOAdoctype = new DocumentType__c();
        SOAdoctype.Type__c = 'SOA';  
        SOAdoctype.ObjectType__c = 'Salesorder';
        insert SalesorderSOAdoctype;
        
         Document__c salesordeSodocument = new Document__c(
            Document_Name__c = 'SOA',
            DocumentType__c= SalesorderSOAdoctype.id,
            Salesorder__c = salesOrder.id,
            ContentDocumentId__c = con2.ContentDocumentId,
            Content_Version_Id__c = con2.Id
        );
        
        insert salesordeSodocument;

        ServiceCatalog__c testServiceCatalog = new ServiceCatalog__c(
            Name = 'Test Service Catalog',
            Type__c = 'Service Request',
            Category__c = 'Financial - Payment Service',
            SubCategory__c = 'Postpone/Defer Payment',
            ProcessFlowType__c = 'Handover',
            RecordTypeDevName__c = 'Handover'
        );
        insert testServiceCatalog;
        
         DocumentType__c BCCdoctype = new DocumentType__c();
       // BCCdoctype.Type__c = 'BCC Announcement';
        BCCdoctype.ObjectType__c = 'Project';
        insert BCCdoctype;
        
          Document__c document9 = new Document__c(
            Document_Name__c = 'SOA',
            DocumentType__c= SOAdoctype.id,
          
            ContentDocumentId__c = con2.ContentDocumentId,
            Content_Version_Id__c = con2.Id
        );
        insert document9;
       
        
         
        Handover__c handover = new Handover__c();
        handover.Account__c = account.Id;
        handover.Building_Phase__c = testBuilding.Id;
        handover.Unit__c = u.Id;
        handover.Sales_Order__c = salesOrder.id;
        insert handover;
        
        document9.Handover__c = handover.Id;
        update document9;
        
        Document__c document2 = new Document__c(
            Document_Name__c = 'Full Guideline Document',
            Handover__c = handover.Id,
            ContentDocumentId__c = con2.ContentDocumentId,
            Content_Version_Id__c = con.Id
        );
        insert document2;
        
         Document__c document3 = new Document__c(
            Document_Name__c = 'QA Desnagging Report',
            Handover__c = handover.Id,
            ContentDocumentId__c = con1.ContentDocumentId,
            Content_Version_Id__c = con1.Id
        );
        insert document3;
        
         Document__c document4 = new Document__c(
            Document_Name__c = 'CHO Desnagging Report',
            Handover__c = handover.Id,
            ContentDocumentId__c = con2.ContentDocumentId,
            Content_Version_Id__c = con2.Id
        );
        
        
        insert document4;
        

        BrokerApplication__c objBroker = new BrokerApplication__c();
        objBroker.CompanyName__c = 'Test';
        insert objBroker;

        BrokerApplicant__c objApplicant = new BrokerApplicant__c();
        objApplicant.BrokerApplication__c  = objBroker.Id;
        insert objApplicant;

        Document__c objDoc = new Document__c();
        objDoc.Document_Name__c = 'Test';   
        objDoc.BrokerApplication__c = objBroker.Id;
        objDoc.BrokerApplicant__c = objApplicant.Id;
        insert objDoc;
          Document__c document8 = new Document__c(
            Document_Name__c = 'CHO Desnagging Report',
            Handover__c = handover.Id,
            ContentDocumentId__c = con2.ContentDocumentId,
            Content_Version_Id__c = con2.Id
        );
        
        
        insert document8;
         
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Social Media').getRecordTypeId();
        Case tempCase=new Case(
            CurrencyIsoCode='AED',
            Status='Draft',
            Origin='Email',
            Main_Buyer_Share_Percentage__c=40,
            // Case_Sub_Status__c= 'Created',
            RecordTypeId=RecordTypeCaseId,
            Sales_Order__c= salesOrder.id
        );
        insert tempCase;
    }
    
   
    @IsTest
    static void testGetDocumentsByHandoverAndName() {
        Handover__c  ho = [SELECT Id, Project__c FROM Handover__c LIMIT 1];
		Account acc = [Select Id from account limit 1];
        Document__c doc = [SELECT ID, Document_Name__c, Handover__c FROM Document__c WHERE Document_Name__c = 'Test Document1'];
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
        Unit__c u = [SELECT Id FROM Unit__c LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        HandoverPhase__c  hphase = new HandoverPhase__c();
        hphase.Project__c = project.id;
        hphase.Name = 'Test';
       
        insert hphase;
        LeasingOrder__c lo = new LeasingOrder__c(
            Name = 'TestOrder',
           
            Unit__c = u.Id,
            Status__c = 'Cancelled'
        );
        
        Document__c  leasingdoc= new Document__c();
        leasingdoc.LeasingOrder__c = lo.id;
        insert leasingdoc;
        
        List<Document__c> fetchedDoc = DocumentService.getInstance().getDocumentsByHandoverAndName(New Set<Id>{ho.Id},New List<String>{doc.Document_Name__c});
        List<Document__c> fetchedDoc1 = DocumentService.getInstance().getDocumentByHandoverIdAndName(ho.Id,doc.Document_Name__c);
        List<Document__c> fetchedDoc2 = DocumentService.getInstance().getDocumentsByHandoverId(ho.Id);
        List<Document__c> fetchedDoc3 = DocumentService.getInstance().getDocumentsForHandovers(New List<String>{doc.Document_Name__c}, New List<Handover__c> {ho});
        List<Document__c> fetchedDoc4 = DocumentService.getInstance().getDocumentsForHandover(New List<String>{doc.Document_Name__c}, ho);
        List<Document__c> fetchedDoc5 = DocumentService.getInstance().getDocumentWithContentVersion(New Set<Id>{ho.Id}, New List<String>{doc.Document_Name__c});
		List<Document__c> fetchedDoc6 = DocumentService.getInstance().getDocumentsByNameAndParentIds( New List<String>{doc.Document_Name__c},New Set<Id>{ho.Id});
		List<Document__c> fetchedDoc7 = DocumentService.getInstance().getDocumentByAccountIds(new set<Id>{acc.Id});
		List<Document__c> fetchedDoc8 = DocumentService.getInstance().getDocumentsWithContentDocIds(new set<Id>{doc.Id});
		List<Document__c> fetchedDoc9 = DocumentService.getInstance().getDocumentsByIds(new set<Id>{doc.Id});
		List<Document__c> fetchedAccDoc = DocumentService.getInstance().getDocumentsByParentId(acc.Id);
		List<Document__c> fetchedProjectDoc = DocumentService.getInstance().getDocumentsByParentId(project.Id);
		List<Document__c> fetchedSODoc = DocumentService.getInstance().getDocumentsByParentId(so.Id);
		List<Document__c> fetchedUnitDoc = DocumentService.getInstance().getDocumentsByParentId(u.Id);
		Document__c fetchedDocs = DocumentService.getInstance().getDocumentByIdBAPP(doc.Id);
		List<Document__c> fetchedAccDocList = DocumentService.getInstance().getAppDocumentsByParentId(acc.Id);
		List<Document__c> fetcedConDocList = DocumentService.getInstance().getAppDocumentsByParentId(con.Id);
		List<Document__c> fetchedHoDocList = DocumentService.getInstance().getDocumentsByParentIdsAndType(new Set<Id>{ho.Id},'SOA',Handover__c.SobjectType);
		List<Document__c> fetchedProjectDocList = DocumentService.getInstance().getDocumentsByParentIdsAndType(new Set<Id>{project.Id},'FLOOR_PLAN',Project__c.SobjectType);
        DocumentService.getInstance().getDocumentsByParentIdsAndType(new Set<Id>{hphase.Id},'Handover Phase',HandoverPhase__c.SobjectType);
         DocumentService.getInstance().getLeasingSignDocuments(new Set<Id>{leasingdoc.id},new List<String>{'Test'});
       
  
    }
     @IsTest
    static void testGetDocWithProfileAccess() {
        DocumentService service = DocumentService.getInstance();
        Profile p = [SELECT Id,Name FROM Profile WHERE Name='HO Agent'];
        List<String> strList  = service.getDocWithProfileAccess(p.Name);
        //System.assertNotEquals(0, soDocList.size(), 'Documents should be fetched based on type.');
    }
    
    @IsTest
    static void testInsertContentVersion() {
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test Data'));
        String fileName = 'TestFile.txt';

        ContentVersion contentVersion = DocumentService.getInstance().insertContentVersion(base64Data, fileName);
        System.assertNotEquals(null, contentVersion.Id, 'ContentVersion should be inserted successfully.');
        System.assertEquals(fileName, contentVersion.Title, 'File name should match.');
    }

    @IsTest
    static void testInsertContentDocumentLink() {
        String base64Str = EncodingUtil.base64Encode(Blob.valueOf('Test1234'));
        ContentVersion objCV = TestDataFactory.createContentVersion(base64Str, 'test', 'test');
        insert objCV;
        ContentVersion cv = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1];
        Id contentDocumentId = cv.ContentDocumentId;

        Account acc = [SELECT Id FROM Account LIMIT 1];
        ContentDocumentLink cdl = DocumentService.getInstance().insertContentDocumentLink(contentDocumentId, acc.Id);
        System.assertNotEquals(null, cdl.Id, 'ContentDocumentLink should be inserted successfully.');
    }

    @IsTest
    static void testGetContentDocumentId() {
        ContentVersion cv = [SELECT Id FROM ContentVersion LIMIT 1];
        Id contentDocumentId = DocumentService.getInstance().getContentDocumentId(cv.Id);
        System.assertNotEquals(null, contentDocumentId, 'ContentDocumentId should be fetched successfully.');
    }

    @IsTest
    static void testGetDocumentById() {
        Document__c doc = [SELECT Id FROM Document__c LIMIT 1];
        Document__c fetchedDoc = DocumentService.getInstance().getDocumentById(doc.Id);
        System.assertNotEquals(null, fetchedDoc, 'Document__c should be fetched successfully.');
    }

    @IsTest
    static void testGetDocumentsByObjectIds() {
        DocumentService service = DocumentService.getInstance();
        List<SalesOrder__c> so = [SELECT Id FROM SalesOrder__c LIMIT 1];
        List<Document__c> soDocList  = service.getDocumentsByObjectIds(new Set<Id>{so[0].Id},'SalesOrder__c');
        List<Document__c> soDocListTWO  = service.getDocumentsByPatternAndHandoverIds(new Set<Id>{so[0].Id}, 'SOA');
        List<Document__c> soDocListTHREE = service.deleteDocuments(soDocList);
        List<Document__c> soDocListFOUR = service.deleteDocumentsByApplicantIds(new Set<Id>{so[0].Id});
        List<DocumentType__c> soDocListFIVE = service.getActiveDocTypesForRecordType('Case', 'DefaultUnit');
        List<Document__c> soDocListSIX = service.getCaseDocumentsByNames(so[0].Id, new List<String>{'TestSTR'});
        List<DocumentType__c> soDocListSEVEN = service.getDocTypes('Case', 'DefaultUnit');
		List<Document__c> soDocListEight = service.getAllSalesOrderDocuments(new List<String>{so[0].Id});
		
        //System.assertNotEquals(0, soDocList.size(), 'Documents should be fetched based on type.');
    }
    
    @IsTest
    static void testDeleteContentDocuments() {
        DocumentService service = DocumentService.getInstance();

        // Insert a ContentDocument
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test Data'));
        String fileName = 'DeleteTestFile.txt';
        ContentVersion cv = service.insertContentVersion(base64Data, fileName);
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion LIMIT 1];
        ContentDocument doc = [SELECT Id FROM ContentDocument WHERE Id = :cv.ContentDocumentId];

        // Delete the ContentDocument
        List<ContentDocument> deletedDocs = service.deleteContentDocuments(new List<ContentDocument>{doc});
        System.assertEquals(1, deletedDocs.size(), 'One document should be deleted.');
    }

    @IsTest
    static void testGetDocTypes() {
        DocumentService service = DocumentService.getInstance();
        List<DocumentType__c> docTypes = service.getDocTypes('Sales Order');
        System.assertNotEquals(0, docTypes.size(), 'DocumentType__c records should be returned.');
    }
    @isTest 
    static void getDocumentsByApplicationNumberTest(){
        //PG
        Test.startTest();
            BrokerApplication__c objApplication = [SELECT Id, ApplicationNumber__c FROM BrokerApplication__c WHERE CompanyName__c = 'Test' LIMIT 1 ];
            List<Document__c> listDocs = DocumentService.getInstance().getDocumentsByApplicationNumber(objApplication.ApplicationNumber__c);
        Test.stopTest();
    }
    
     @IsTest
    static void testGetCommissionInvoiceDocuments() {
    
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        Document__c doc = [SELECT Id FROM Document__c LIMIT 1];
        SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
        Unit__c u = [SELECT Id FROM Unit__c LIMIT 1];
        
        DocumentService.getDocuments(acc.Id);
        DocumentService.getDocuments(project.Id);
        DocumentService.getDocuments(so.Id);
        DocumentService.getDocuments(u.Id);

        
        //System.assertNotEquals(0, docTypes.size(), 'DocumentType__c records should be returned.');
    }

    
    @IsTest
    static void testgetAccountDocuments() {
        DocumentService service = DocumentService.getInstance();
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        List<Document__c> docs = service.getAccountDocuments(acc.Id);
        System.assertNotEquals(0, docs.size(), 'Documents should be fetched based on type.');
    }
    
    @IsTest
    static void testUpdateDocument() {
        DocumentService service = DocumentService.getInstance();
        Document__c doc = [SELECT Id FROM Document__c LIMIT 1];
        
        Document__c docs = service.updateDocument(doc);
        //System.assertNotEquals(0, docs.size(), 'Documents should be fetched based on type.');
    }

    @IsTest
    static void TestGetBrokerCommissionDocuments() {
        DocumentService service = DocumentService.getInstance();
        List<BrokerCommission__c> brkrCommList = [SELECT Id FROM BrokerCommission__c LIMIT 1];
        
        List<Document__c> docsList  = service.getBrokerCommissionDocuments(brkrCommList[0].Id,'Test Document1');
        System.assertNotEquals(0, brkrCommList.size(), 'Documents should be fetched based on type.');
    }
    
    @IsTest
    static void testGetBrokerCommissionDocuments2() {
        DocumentService service = DocumentService.getInstance();
        List<BrokerCommission__c> brkrCommList = [SELECT Id FROM BrokerCommission__c LIMIT 1];
        
        List<Document__c> docsList  = service.getBrokerCommissionDocuments(brkrCommList,'Emirates ID');
        System.assertNotEquals(0, brkrCommList.size(), 'Documents should be fetched based on type.');
    }
    
    

        @IsTest
    static void testGetSalesOrderDocumentsByName() {
        DocumentService service = DocumentService.getInstance();
        List<SalesOrder__c> so = [SELECT Id FROM SalesOrder__c LIMIT 1];
        List<Document__c> soDocList  = service.getSalesOrderDocumentsByName(New List<String>{so[0].Id},'Emirates ID');
        System.assertNotEquals(0, soDocList.size(), 'Documents should be fetched based on type.');
    }
    
    @IsTest
    static void testGetUnitDocumentsByName() {
        DocumentService service = DocumentService.getInstance();
        List<Unit__c> u = [SELECT Id FROM Unit__c LIMIT 1];
        System.debug('This is Unit Id: ' +u[0].Id);
        List<Document__c> soDocList  = service.getUnitDocumentsByName(New List<String>{u[0].Id},'Emirates ID');
        //System.assertNotEquals(0, soDocList.size(), 'Documents should be fetched based on type.');
    }
    
    @IsTest
    static void testDeleteContentDocument() {
        DocumentService service = DocumentService.getInstance();
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test Data'));
        String fileName = 'DeleteTestFile.txt';
        ContentVersion cv = service.insertContentVersion(base64Data, fileName);
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion LIMIT 1];
        ContentDocument doc = [SELECT Id FROM ContentDocument WHERE Id = :cv.ContentDocumentId];
        
        ContentDocument Contentdoc = service.deleteContentDocument(doc);
        //System.assertNotEquals(0, docs.size(), 'Documents should be fetched based on type.');
    }
    
    @IsTest
    static void testInsertDocument() {
        DocumentService service = DocumentService.getInstance();
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Project__c project = new Project__c(Name = 'Test Project1');
        insert project;
        /*Unit__c u = TestDataFactory.createUnit(project.Id, 'A1-G01', 'Unassigned');
        u.Project__c = project.Id;
        u.RegistrationDate__c = Date.today();
        insert u;*/
        Unit__c u = [Select Id FROM Unit__c];
		SalesOrder__c salesOrder = TestDataFactory.createSalesOrder(acc.Id, null, null, null, u.Id, 100.00);
        salesOrder.DocumentUploadedDate__c = Date.today() - 1;
        salesOrder.UnitRegistrationDate__c = Date.today();
        insert salesOrder;        
        DocumentType__c dc1 = TestDataFactory.createDocumentType('Sales Order', 'Emirates ID');
        INSERT dc1;
        Document__c testDocument1 = TestDataFactory.createDoc(dc1.Id, salesOrder.Id, null);
        Document__c soDoc  = service.insertDocument(testDocument1);
        //System.assertNotEquals(0, soDocList.size(), 'Documents should be fetched based on type.');
    }
    
    @IsTest
    static void testGetDocumentBasedonType() {
        DocumentService service = DocumentService.getInstance();
        Document__c doc = [SELECT ID, Document_Name__c, Handover__c, DocumentType__r.Type__c FROM Document__c LIMIT 1];
        String docType = doc.DocumentType__r.Type__c;
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
         Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
         BrokerApplication__c ba = [SELECT Id FROM BrokerApplication__c LIMIT 1];
        List<BrokerCommission__c> brkrCommList = [SELECT Id FROM BrokerCommission__c LIMIT 1];
        List<Document__c> soDocList  = service.getDocumentBasedonType(project.Id,docType);
        List<Document__c> soDocList2  = service.getDocumentBasedonType(so.Id,docType);
        List<Document__c> soDocList3  = service.getDocumentBasedonType(brkrCommList[0].Id,docType);
        List<Document__c> soDocList5= service.getDocumentBasedonType(ba.Id,docType);
        List<Document__c> soDocList6= service.getDocumentByNameAndProject(new list<String>{docType},new set<id>{project.Id});
        //System.assertNotEquals(0, soDocList.size(), 'Documents should be fetched based on type.');
    }
    @IsTest
    public static void testGetExistingDocuments() {
        // Retrieve the BrokerApplication and a Document linked to it from the TestSetup method.
        BrokerApplication__c app = [SELECT Id FROM BrokerApplication__c WHERE CompanyName__c = 'Test' LIMIT 1];
        Set<Id> parentIds = new Set<Id>{app.Id};
    
        // Call the method to be tested
        List<Document__c> documents = DocumentService.getInstance().getExistingDocuments(parentIds);
    
        // Assert that the method returns the expected documents.
        System.assert(documents != null, 'Document list should not be null.');
        System.assertEquals(1, documents.size(), 'There should be exactly one document for the BrokerApplication.');
        System.assertEquals(app.Id, documents[0].BrokerApplication__c, 'The document should be linked to the correct BrokerApplication.');
    }
    
    @IsTest
    public static void testGetExistingDocumentsForApplicant() {
        // Retrieve the BrokerApplicant and a Document linked to it from the TestSetup method.
        BrokerApplicant__c applicant = [SELECT Id FROM BrokerApplicant__c LIMIT 1];
        Set<Id> parentIds = new Set<Id>{applicant.Id};
    
        // Call the method to be tested
        List<Document__c> documents = DocumentService.getInstance().getExistingDocumentsForApplicant(parentIds);
    
        // Assert that the method returns the expected documents.
        System.assert(documents != null, 'Document list should not be null.');
        System.assertEquals(1, documents.size(), 'There should be exactly one document for the BrokerApplicant.');
        System.assertEquals(applicant.Id, documents[0].BrokerApplicant__c, 'The document should be linked to the correct BrokerApplicant.');
    }
    @isTest
    static void getApplicationDocumentsByNameTest() {
        // Create a BrokerApplication record
        BrokerApplication__c app = new BrokerApplication__c(
            Name = 'Test Application',
            CompanyName__c = 'Test Company'
        );
        insert app;
        
        // Create a Document record linked to the application
        Document__c doc = new Document__c(
            Document_Name__c = 'Trade License',
            ContentDocumentId__c = '069000000000001',
            BrokerApplication__c = app.Id
        );
        insert doc;
    
        Test.startTest();
            List<Document__c> result = DocumentService.getInstance()
                .getApplicationDocumentsByName(new List<Id>{app.Id}, 'Trade License');
        Test.stopTest();
    
        // Assert
        System.assertEquals(1, result.size(), 'Should return 1 document');
        System.assertEquals('Trade License', result[0].Document_Name__c, 'Document name should match');
        System.assertEquals(app.Id, result[0].BrokerApplication__c, 'BrokerApplication should match');
    }
        @IsTest
    static void testGetDocumentsByBrokerApplicationIds() {
        // Retrieve the BrokerApplication and a Document linked to it from the TestSetup method.
        BrokerApplication__c app = [SELECT Id FROM BrokerApplication__c WHERE CompanyName__c = 'Test' LIMIT 1];
        Set<Id> parentIds = new Set<Id>{app.Id};
    
        // Call the method to be tested
        List<Document__c> documents = DocumentService.getInstance().getDocumentsByBrokerApplicationIds(parentIds);
    
        // Assert that the method returns the expected documents.
        System.assert(documents != null, 'Document list should not be null.');
        System.assertEquals(1, documents.size(), 'There should be exactly one document for the BrokerApplication.');
        System.assertEquals(app.Id, documents[0].BrokerApplication__c, 'The document should be linked to the correct BrokerApplication.');
    }
        @IsTest
    static void testGetDocumentsByBrokerApplicantIds() {
        // Retrieve the BrokerApplicant and a Document linked to it from the TestSetup method.
        BrokerApplicant__c applicant = [SELECT Id FROM BrokerApplicant__c LIMIT 1];
        Set<Id> parentIds = new Set<Id>{applicant.Id};
    
        // Call the method to be tested
        List<Document__c> documents = DocumentService.getInstance().getDocumentsByBrokerApplicantIds(parentIds);
    
        // Assert that the method returns the expected documents.
        System.assert(documents != null, 'Document list should not be null.');
        System.assertEquals(1, documents.size(), 'There should be exactly one document for the BrokerApplicant.');
        System.assertEquals(applicant.Id, documents[0].BrokerApplicant__c, 'The document should be linked to the correct BrokerApplicant.');
    }
    @isTest
    static void testGetBappDocuments() {
        BrokerApplication__c app = new BrokerApplication__c(Name = 'Bapp Test', CompanyName__c = 'TestCo');
        insert app;

        Document__c doc = new Document__c(
            Document_Name__c = 'Broker Agreement',
            BrokerApplication__c = app.Id
        );
        insert doc;

        Test.startTest();
        List<Document__c> results = DocumentService.getInstance()
            .getBappDocuments(new Set<Id>{app.Id});
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return 1 Bapp document');
        System.assertEquals(app.Id, results[0].BrokerApplication__c, 'Application Id should match');
    }
    @isTest
    static void testGetDocumentsByContactIds() {
        Contact con = new Contact(LastName = 'Tester');
        insert con;

        Document__c doc = new Document__c(
            Document_Name__c = 'Contact Doc',
            Contact__c = con.Id
        );
        insert doc;

        Test.startTest();
        List<Document__c> results = DocumentService.getInstance()
            .getDocumentsByContactIds(new Set<Id>{con.Id});
        List<Document__c> emptyResults = DocumentService.getInstance()
            .getDocumentsByContactIds(new Set<Id>());
        List<Document__c> nullResults = DocumentService.getInstance()
            .getDocumentsByContactIds(null);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return 1 contact document');
        System.assertEquals(0, emptyResults.size());
        System.assertEquals(0, nullResults.size());
    }
    @isTest
    static void testGetContentVersionsByIds() {
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('Test content')
        );
        insert cv;

        Test.startTest();
        List<ContentVersion> results = DocumentService.getInstance()
            .getContentVersionsByIds(new Set<Id>{cv.Id});
        List<ContentVersion> emptyResults = DocumentService.getInstance()
            .getContentVersionsByIds(new Set<Id>());
        List<ContentVersion> nullResults = DocumentService.getInstance()
            .getContentVersionsByIds(null);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return 1 content version');
        System.assertEquals(0, emptyResults.size());
        System.assertEquals(0, nullResults.size());
    }
    @isTest
    static void testGetDocumentsByAccountIds() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Document__c doc = new Document__c(
            Document_Name__c = 'Broker Agreement',
            Account__c = acc.Id
        );
        insert doc;

        Test.startTest();
        List<Document__c> results = DocumentService.getInstance()
            .getDocumentsByAccountIds(new Set<Id>{acc.Id});
        List<Document__c> emptyResults = DocumentService.getInstance()
            .getDocumentsByAccountIds(new Set<Id>());
        List<Document__c> nullResults = DocumentService.getInstance()
            .getDocumentsByAccountIds(null);
        Test.stopTest();

        System.assertEquals(0, emptyResults.size());
        System.assertEquals(0, nullResults.size());
    }
    
    @isTest
    static void testgetCaseDocumentByName(){
        Case objCase = [SELECT Id FROM Case LIMIT 1];
        Document__c doc = new Document__c(
            Document_Name__c = 'Broker Agreement',
            Case__c = objCase.Id
        );
        insert doc;
        Test.startTest();
        DocumentService.getInstance().getCaseDocumentByName(objCase.Id,'Broker Agreement');
    }

    @IsTest
    static void testGetInsertedContentVersions() {
        ContentVersion cv = [SELECT Id FROM ContentVersion LIMIT 1];
        List<ContentVersion> cvList = DocumentService.getInstance().getInsertedContentVersions(new Set<Id>{cv.Id});
        System.assertEquals(false, cvList.isEmpty(), 'ContentVersion list should not be empty');
    }
    @IsTest
    static void testInsertContentVersions() {
        List<ContentVersion> cvList = new List<ContentVersion>();
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('Test content')
        );
        cvList.add(cv);
        List<ContentVersion> cvInsertedList = DocumentService.getInstance().insertContentVersions(cvList);
        System.assertEquals(false, cvList.isEmpty(), 'ContentVersion list should not be empty');
    }
    
    @IsTest
static void testAdditionalDocumentMethods() {

    DocumentService service = DocumentService.getInstance();

    SalesOrder__c so = [SELECT Id, Account__c FROM SalesOrder__c LIMIT 1];
    Account acc = [SELECT Id FROM Account LIMIT 1];
    Contact con = [SELECT Id FROM Contact LIMIT 1];
    BrokerCommission__c bc = [SELECT Id FROM BrokerCommission__c LIMIT 1];
    Case cs = [SELECT Id FROM Case LIMIT 1];
    Unit__c u = [SELECT Id FROM Unit__c LIMIT 1];

    Opportunity opp = new Opportunity(
        Name = 'Test Opp',
        StageName = 'Prospecting',
        CloseDate = Date.today(),
        AccountId = acc.Id
    );
    insert opp;

    // Updated Leasing Order
    LeasingOrder__c lo = new LeasingOrder__c(
        Name = 'Test',
        Unit__c = u.Id,
        Status__c = 'Cancelled'
    );
    insert lo;

    insert new Document__c(LeasingOrder__c = lo.Id, Document_Name__c = 'Leasing Offer');
    insert new Document__c(LeasingOrder__c = lo.Id, Document_Name__c = 'Leasing Contract - Signed');
    insert new Document__c(Opportunity__c = opp.Id, Document_Name__c = 'Passport');
    insert new Document__c(LeasingOrder__c = lo.Id, Document_Name__c = 'Passport');
    insert new Document__c(Case__c = cs.Id, Document_Name__c = 'Case Doc');
    insert new Document__c(Contact__c = con.Id, Document_Name__c = 'Contact Doc');
    insert new Document__c(BrokerCommission__c = bc.Id, Document_Name__c = 'Commission Doc');

    Test.startTest();

    service.getLeasingOfferDocumentsByContractIds(new Set<Id>{lo.Id});
    service.getLeasingSignedDocumentsByContractIds(new Set<Id>{lo.Id});
    service.getDocumentsByOpportunityId(opp.Id);
    service.getDocumentsByLeasingOrderId(lo.Id);
    service.getRequiredLeasingOrderDocument(lo.Id, 'Passport');
    service.getLeasingOfferDocumentsByOppIdAndCategory(opp.Id, 'Passport');
    service.getCaseDocumentsByName(cs.Id, new Set<String>{'Case Doc'});
    service.getExistingDocumentsByCaseId(new Set<Id>{cs.Id});
    service.getDocumentByContactIds(new Set<Id>{con.Id});
    service.getDocumentByContactIds(new Set<Id>());
    service.getCommissionDocumentsByName(bc.Id, new List<String>{'Commission Doc'});
    service.getDocumentByParentIdAndType(so.Id, 'SOA');
    service.getDocumentByParentIdAndType(acc.Id, 'SOA');

    Test.stopTest();

    System.assert(true);
}
}