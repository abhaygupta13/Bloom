@isTest
public class WorkOrderImageControllerTest {
    @testSetup
    static void setupTestData() {
        Profile profileCC = [SELECT Id FROM Profile WHERE Name = 'Contractor' LIMIT 1];
        
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueOf(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(Math.rint(Math.random() * 1000000));
        String uniqueName = orgId + dateString + randomInt;
        
        
        User userRecord = new User();
        userRecord.Username = uniqueName + '@mail.com';
        userRecord.LastName = 'Zaki Al Bakri';
        userRecord.Email = 'Zakial@gmail.com';
        userRecord.Alias = 'Zaki';
        userRecord.TimeZoneSidKey = 'Asia/Dubai';
        userRecord.LocaleSidKey = 'en_US';
        userRecord.EmailEncodingKey = 'UTF-8';
        userRecord.ProfileId = profileCC.Id;  
        userRecord.LanguageLocaleKey = 'en_US';
        userRecord.IsActive = TRUE;
        userRecord.is_On_Vacation__c = FALSE;
        userRecord.isFreezed__c = FALSE;
        insert userRecord;
        
        Project__c prj = new Project__c();
        prj.Name = 'Test Project';    
        prj.Contractor__c = userRecord.Id; 
        insert prj;       
        
        Unit__c unt = new Unit__c();
        unt.Name = 'C-1233';
        unt.Project__c = prj.Id;
        unt.Is_Property_keys_given__c = true;
        insert unt;
        
        Account acc = new Account();
        acc.Name = 'Test Acc';
        insert acc;
        
        
        
        WorkOrder wrk = new WorkOrder();
        wrk.Subject = 'New work order is created.--test';
        wrk.Description = 'This decriptions for test class.';
        wrk.Type_of_Incident__c = 'New';
        wrk.Unit__c = unt.Id; 
        wrk.Is_Emergency__c = true;
        wrk.Resolution_Priority__c = 'Emergency'; // 'Priority 1';        
        wrk.Resolution_Typology__c = 'Repair';
        wrk.Category__c = 'Civil';
        wrk.Location__c = 'Laundry Room';
        wrk.Priority = 'Low';
        wrk.AccountId = acc.Id;
        wrk.Check_In__c = true;
        wrk.Customer_Availability__c = 'Not Available';
        wrk.Incident_description__c = 'Full external paint';
        wrk.Problem_Code__c = 'CM-PQA-Wall-Ceiling';
        wrk.Sub_category__c = 'Walls/Ceiling';
        wrk.Repair__c = '2 Days';        
        wrk.ServiceReportLanguage = ' ';
        wrk.Replace__c = 'Within 2 Day';
        wrk.Requester_Email__c='alt.jm-eef16gn@yopmail.com';        
        wrk.OwnerId=userRecord.id;
        insert  wrk;
        
        WorkType newWrkType = new WorkType();
        newWrkType.Name = 'DLP';
        newWrkType.EstimatedDuration = 2;
        newWrkType.DurationType = 'Hours';
        insert newWrkType;
        
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        
            ContentVersion cv1 = new ContentVersion();
            cv1.Title = 'Signature';
            cv1.PathOnClient = 'Signature'+ '.jpg';
            cv1.VersionData = Blob.valueOf('Test PDF Data ');
            cv1.IsMajorVersion = true;
            contentVersions.add(cv1);
        
        for (Integer i = 1; i <= 5; i++) { 
            ContentVersion cv = new ContentVersion();
            cv.Title = 'Before_Test_Work_Order_PDF_' + i;
            cv.PathOnClient = 'TestWorkOrder' + i + '.jpg';
            cv.VersionData = Blob.valueOf('Test PDF Data ' + i);
            cv.IsMajorVersion = true;
            contentVersions.add(cv);
        }
        
        for (Integer i = 1; i <= 5; i++) { 
            ContentVersion cv = new ContentVersion();
            cv.Title = 'After_Test_Work_Order_PDF_' + i;
            cv.PathOnClient = 'TestWorkOrder' + i + '.jpg';
            cv.VersionData = Blob.valueOf('Test PDF Data ' + i);
            cv.IsMajorVersion = true;
            contentVersions.add(cv);
        }
        
        insert contentVersions;
        
        List<Id> contentVersionIds = new List<Id>();
        for (ContentVersion cv : contentVersions) {
            contentVersionIds.add(cv.Id);
        }
        
        List<Id> contentDocIds = new List<Id>();
        for (ContentVersion cv : [SELECT ContentDocumentId FROM ContentVersion WHERE Id IN :contentVersionIds]) {
            contentDocIds.add(cv.ContentDocumentId);
        }
        
        List<ContentDocumentLink> contentLinks = new List<ContentDocumentLink>();
        for (Id contentDocId : contentDocIds) {
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = contentDocId;
            cdl.LinkedEntityId = wrk.Id; 
            cdl.ShareType = 'V';
            cdl.Visibility = 'AllUsers';
            contentLinks.add(cdl);
        }
        
        insert contentLinks;
    }
    
    @isTest
    static void testWorkOrderImageController() {
        Test.startTest();
        PageReference pageRef = Page.WorkOrderPdf;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', [SELECT Id FROM WorkOrder LIMIT 1].Id);
        WorkOrderImageController controller = new WorkOrderImageController();        
        Test.stopTest();
    }
    
    @isTest
    static void testGenerateAndAttachPdf() {
        Id workOrderId = [SELECT Id FROM WorkOrder LIMIT 1].Id;
        ServiceAppointment serviceAppointments = [Select Id, Status, Closure_Reason__c From ServiceAppointment where ParentRecordId =: workOrderId ORDER BY CreatedDate DESC Limit 1];
         if(serviceAppointments.Status != Constants.IN_PROGRESS){
            serviceAppointments.Status = Constants.SCHEDULED;
            update serviceAppointments;
            serviceAppointments.Status = Constants.IN_PROGRESS;
            update serviceAppointments;
        }
        Test.startTest();
        WorkOrderImageController.generateAndAttachPdf(workOrderId);
        Test.stopTest();
        
    }
    
}