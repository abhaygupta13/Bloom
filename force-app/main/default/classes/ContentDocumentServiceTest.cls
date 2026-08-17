@IsTest
public class ContentDocumentServiceTest {
    
    
    
   @testSetup
    static void testgetProjects() {
        
        Account accountRecord =BCAPP_TestDataFactory.createAccount('Test Account');
        accountRecord.Azure_UserPrincipal_Id__c='testttt';
        insert accountRecord;
        
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
        
        //ContentDocumtLinkTriggerHelper.createContentDitributionForNotification(new List<ContentDocumentLink>{documentLink});
    }
    
    @isTest
    static void testfetchContentVersion() {
        ContentDocumentService inst=new ContentDocumentService();
        inst.fetchContentVersion([select id from ContentVersion]);
        
    } 
    
     @isTest
    static void testContentDocLinkFromLinkEntityId() {
        ContentDocumentService inst=new ContentDocumentService();
        inst.getContentDocLinkFromLinkEntityId(new set<id>{[select id from Notifications__c limit 1].id});
        
    } 
    
       
     @isTest
    static void testfetchContentVersionByContentIds() {
        ContentDocumentService inst=new ContentDocumentService();
        inst.fetchContentVersionByContentIds(new set<id>{[select id from ContentDocument limit 1].id});
        
    } 
    
     @isTest
    static void testfetchContentDocLinksByLinkEntityIds() {
        ContentDocumentService inst=new ContentDocumentService();
        inst.fetchContentDocLinksByLinkEntityIds(new List<id>{[select id from Notifications__c limit 1].id});
        
    } 
    
    
    
    
    
    
    
        
    
}