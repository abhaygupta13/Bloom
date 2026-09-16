@IsTest
public class ContentDocumentLinkTriggerHelperTest {
    
    @IsTest
    static void testgetProjects() {
        
         Account accountRecord =BCAPP_TestDataFactory.createAccount('Test Account');
        accountRecord.Azure_UserPrincipal_Id__c='testttt';
        insert accountRecord;
        
        Profile profileDetail = [SELECT Id FROM Profile WHERE Name='CRM Operations'];
        User userRecord = new User(Alias = 'Zaki', Email='Zakial@gmail.com', 
                                   EmailEncodingKey='UTF-8', LastName='Zaki Al Bakri', LanguageLocaleKey='en_US', 
                                   LocaleSidKey='en_US', ProfileId = profileDetail.id, 
                                   TimeZoneSidKey='Asia/Dubai', UserName= 'testBloomEagles@mail.com');
        insert userRecord;
        
        
         Round_Robins__c rr=new Round_Robins__c(
            Name='Service/Case Request',
            Sobject__c='Case',Assigned_To__c = '1'
        );
        insert rr;
        
       
        Round_Robin_User__c rrUser=new Round_Robin_User__c(
            Name='Hani Zaki Al Bakri -  SM',
            Round_Robin__c=rr.Id,
            Total_Open_Count__c=0,
            User__c=userRecord.Id         
            
            
        );
        insert rrUser;
        
          Round_Robins__c rr1=new Round_Robins__c(
            Name='Service/Resale Case Request',
            Sobject__c='Case',Assigned_To__c = '1'
        );
        insert rr1;
        
       
        Round_Robin_User__c rrUser1=new Round_Robin_User__c(
            Name='Hani Zaki Al Bakri -  SM',
            Round_Robin__c=rr1.Id,
            Total_Open_Count__c=0,
            User__c=userRecord.Id         
            
            
        );
        insert rrUser1;
        
        
        
        Contact cntRecord= BCAPP_TestDataFactory.createContact(accountRecord.id,'ewew@dasds.com');
        insert cntRecord;
        Service_Contract__c Service_Contract=  BCAPP_TestDataFactory.createServiceContract();
        Service_Contract.Customer_Name__c=accountRecord.id;
        insert Service_Contract;
        
        Case testCase =BCAPP_TestDataFactory.createCase();
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Move In Holiday Homes').getRecordTypeId();
        testCase.RecordTypeId=RecordTypeCaseId;
        testCase.AccountId= accountRecord.id;
        testCase.Move_Out_Date__c=system.today();
        testCase.Email_Address__c='testuser@fff.com';
        testCase.User_Type__c=BCAPP_Constants.TENANT;
        insert testCase;
        
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDoc.pdf',
            VersionData = Blob.valueOf('Test content'),
            IsMajorVersion = true
        );
        insert contentVersion;
        
        Project__c testProject =BCAPP_TestDataFactory.createProject();
        insert testProject;
        Notifications__c testNotifications =BCAPP_TestDataFactory.createNotifications();
        testNotifications.Project__c= testProject.id;
        testNotifications.RecordTypeId= SObjectType.Notifications__c.getRecordTypeInfosByDeveloperName().get('Events').getRecordTypeId(); 
        insert testNotifications;
        ContentVersion insertedVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
        String contentDocumentId = insertedVersion.ContentDocumentId;
        Customer_Document__c custDocs=BCAPP_TestDataFactory.createCustomerDocument();
        insert custDocs;
        ContentDocumentLink documentLink = new ContentDocumentLink(
            ContentDocumentId = contentDocumentId,
            LinkedEntityId = testNotifications.Id,
            ShareType = 'V', // Viewer access
            Visibility = 'AllUsers'
        );
        insert documentLink;
         
        //update documentLink;
        delete documentLink;
        
        Unit__c unt = new Unit__c(Name = 'Unit Test A1435', Status__c = 'Unassigned');
        insert unt;
        
        SalesOrder__c salesOrd = new SalesOrder__c(
            Name = 'Test SalesOrder',
            Account__c = accountRecord.Id,
            Status__c = 'Booked'
        );
        insert salesOrd;
        
        DocumentType__c documentType = TestDataFactory.createDocumentType('Sales Order', 'NOC');
        insert documentType;
        
        
        // Create Document
        Document__c document = TestDataFactory.createDocument(null, documentType.Id, 'test');
        insert document;
		ContentVersion insertedVersion2 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
        String contentDocumentId2 = insertedVersion2.ContentDocumentId;
        Customer_Document__c custDocs2 = BCAPP_TestDataFactory.createCustomerDocument();
        insert custDocs2;
        ContentDocumentLink documentLink2 = new ContentDocumentLink(
            ContentDocumentId = contentDocumentId2,
            LinkedEntityId = document.Id,
            ShareType = 'V', // Viewer access
            Visibility = 'AllUsers'
        );
        //insert documentLink2;
        ContentDocumentLinkService objContentDocumentLinkService = ContentDocumentLinkService.getInstance();
        List<ContentDocumentLink> existingCDLinkList = objContentDocumentLinkService.insertContentDocumentLinkWithTrigger(new List<ContentDocumentLink>{documentLink2});
        
        //ContentDocumentLinkTriggerHelper.createContentDitributionForNotification(new List<ContentDocumentLink>{documentLink});
    }
    
       @IsTest
    static void testAfterInsert_RFIUpdateLogic() {
        
        BrokerApplication__c brokerApp = new BrokerApplication__c(Name = 'Test Broker App');
        insert brokerApp;
              
        Document__c doc = new Document__c(BrokerApplication__c = brokerApp.Id);
        insert doc;
       
        ContentVersion cv = new ContentVersion(
            Title = 'RFI Update File',
            PathOnClient = 'rfiupdate.pdf',
            VersionData = Blob.valueOf('Dummy data'),
            IsMajorVersion = true,
            IsRFIUpdated__c = true
        );
        insert cv;
        
        // Get ContentDocumentId
        Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        
        ContentDocumentLink link = new ContentDocumentLink(
            ContentDocumentId = contentDocId,
            LinkedEntityId = doc.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert link;
        
    }
     @isTest
    static void testGetLatestContentDocumentLinkByRecordAndTitle() {
        // Create a test record to link to (Account used here, adjust as needed)
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // Create a ContentVersion (this auto-creates ContentDocument)
        ContentVersion cv = new ContentVersion(
            Title = 'TestDocument123',
            PathOnClient = 'TestDocument123.pdf',
            VersionData = Blob.valueOf('Test content')
        );
        insert cv;

        // Retrieve ContentDocument Id
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        
        // Create ContentDocumentLink linking ContentDocument to Account
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = acc.Id,
            ShareType = 'V', // Viewer permission
            Visibility = 'AllUsers'
        );
        insert cdl;
        
        // Call the method with documentTitlePattern like 'TestDocument%'
        ContentDocumentLink result = ContentDocumentLinkService.getLatestContentDocumentLinkByRecordAndTitle(acc.Id, 'TestDocument%');
        
       
    }
    @isTest
    static void testLODocuments() {
        // Create a test record to link to (Account used here, adjust as needed)
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // Create a ContentVersion (this auto-creates ContentDocument)
        ContentVersion cv = new ContentVersion(
            Title = 'TestDocument123',
            PathOnClient = 'TestDocument123.pdf',
            VersionData = Blob.valueOf('Test content')
        );
        insert cv;
        
        Unit__c uc =  new Unit__c(Name = 'Unit1');
        insert uc;
        
        // Create a dummy LeasingOrder__c (contract)
        LeasingOrder__c contract = new LeasingOrder__c(
            Name = 'Test Contract',
            unit__c = uc.id
        );
        insert contract;
        
        System.debug('contractId>>'+contract.id);
         Document__c doc = new Document__c(Document_Name__c  = 'Leasing Offer - Signed', LeasingOrder__c = contract.Id);
        insert doc;

        // Retrieve ContentDocument Id
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        
        // Create ContentDocumentLink linking ContentDocument to Account
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = contract.Id,
            ShareType = 'V', // Viewer permission
            Visibility = 'AllUsers'
        );
        insert cdl;
        
        
       
    }
    @IsTest
static void testMoveSignedKYCFilesToDocument() {

    // Account
    Account acc = BCAPP_TestDataFactory.createAccount('Test Account');
    insert acc;

    // Case
    Case cs = BCAPP_TestDataFactory.createCase();
    cs.AccountId = acc.Id;
    cs.Case_Sub_Status__c = null;
    insert cs;

    // Document Type
    DocumentType__c docType = TestDataFactory.createDocumentType('Case', 'Signed KYC');
    insert docType;

    // Placeholder Document
    Document__c doc = TestDataFactory.createDocument(null, docType.Id, 'Test');
    doc.Case__c = cs.Id;
    insert doc;

    // Create File (Title must start with "CIS -")
    ContentVersion cv = new ContentVersion(
        Title = 'CIS - Client Information Sheet',
        PathOnClient = 'SignedKYC.pdf',
        VersionData = Blob.valueOf('Dummy Data'),
        IsMajorVersion = true
    );
    insert cv;

    cv = [
        SELECT Id, ContentDocumentId
        FROM ContentVersion
        WHERE Id = :cv.Id
    ];

    Test.startTest();

    // Fires ContentDocumentLink trigger
    insert new ContentDocumentLink(
        ContentDocumentId = cv.ContentDocumentId,
        LinkedEntityId = cs.Id,
        ShareType = 'V',
        Visibility = 'AllUsers'
    );

    Test.stopTest();

    // Verify link created for Document__c
    List<ContentDocumentLink> docLinks = [
        SELECT Id
        FROM ContentDocumentLink
        WHERE LinkedEntityId = :doc.Id
        AND ContentDocumentId = :cv.ContentDocumentId
    ];

    System.assertEquals(1, docLinks.size());
}
}