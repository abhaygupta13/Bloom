@isTest
public class DLPEmailHandlerTest {
    private static String WORKORDER_CLOSED_NOTIFICATION_FOR_CUSTOMER = 'WorkOrder Closed Notification for Customer';
    private static String CUSTOMER_NOT_AVAILABLE_WORK_ORDER_CLOSE = 'Customer Not Available Work Order Close';
    private static String CUSTOMER_NOT_AVAILABLE = 'Customer Not Available';
    private static String DLP_OUT_OF_SCOPE_FOR_CUSTOMER = 'DLP Out Of Scope For Customer';
    private static String SERVICE_APPOINTMENT_BOOKED_NOTIFICATION_FOR_CONTRACTOR = 'Service Appointment Booked Notification for Contractor';
    private static String SERVICE_APPOINTMENT_BOOKED_NOTIFICATION_FOR_DLP_AGENT = 'Service Appointment Booked Notification for DLP Agent';
    private static String WORKORDER_CREATION_NOTIFICATION_FOR_CUSTOMER = 'WorkOrder Creation Notification for Customer';
    
    @TestSetup
    static void setupTestData() {
        Profile profileCC = [SELECT Id FROM Profile WHERE Name = 'Contractor' LIMIT 1];
        
        // Generate a unique username
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueOf(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(Math.rint(Math.random() * 1000000));
        String uniqueName = orgId + dateString + randomInt;
        
        // Create a new User record
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
        insert userRecord;         
        
        Project__c prj = new Project__c();
        prj.Name = 'Test Project';    
        prj.Contractor__c = userRecord.Id; //cnt.Id;
        insert prj;
        
        Unit__c unt = new Unit__c(Name = 'C-1233',Project__c = prj.Id, Location__Longitude__s = 98.345445, Location__Latitude__s = 22.22222);
        insert unt;
        
        WorkOrder wrk = new WorkOrder(
            Subject = 'New work order is created.',
            Description = 'This description is for test class.',
            Closure_Reason__c = 'Out Of Scope',
            Type_of_Incident__c = 'Out of Scope',
            Resolution_Priority__c = 'Priority 1',
            Resolution_Typology__c = 'Repair',
            Category__c = 'Civil',
            Location__c = 'Master Bedroom',
            Priority = 'Low',
            Status = 'Closed',
            Check_In__c = true,
            Customer_Availability__c = 'Customer not available',
            Incident_description__c = 'Paint Peeling off',
            Problem_Code__c = 'CM-PQA-Wall-Ceiling',
            Sub_category__c = 'walls/ceiling',
            Repair__c = '2 Days',
            Replace__c = 'Within 2 Day',
            Unit__c = unt.Id
        );
        insert wrk;
        
        ServiceAppointment newSA = new ServiceAppointment(
            ParentRecordId = wrk.Id,
            Status = 'None',
            EarliestStartTime = System.now().addDays(-1),
            DueDate = System.now().addDays(7),
            Subject = wrk.Subject,
            Description = wrk.Description
        );
        insert newSA;
        
        String fileContent = 'This is a test file content';
        ContentVersion contentVersionObj = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.txt',
            VersionData = Blob.valueOf(fileContent),
            ContentLocation = 'S'
        );
        insert contentVersionObj;
    }
    
    @isTest
    static void sendEmailProcess_Test() {
        EmailTemplate mailTemplateCustomerNotAvailable = EmailUtil.getEmailTemplateByName(CUSTOMER_NOT_AVAILABLE);
        EmailTemplate mailTemplateWorkOrderClosedForCustomer = EmailUtil.getEmailTemplateByName(WORKORDER_CLOSED_NOTIFICATION_FOR_CUSTOMER);
        EmailTemplate mailTemplateDlpOutOfScopeForCustomer = EmailUtil.getEmailTemplateByName(DLP_OUT_OF_SCOPE_FOR_CUSTOMER);
        EmailTemplate mailTemplateCustomer = EmailUtil.getEmailTemplateByName(WORKORDER_CREATION_NOTIFICATION_FOR_CUSTOMER);            
        
        WorkOrder wo = [SELECT Id, CaseId, Case.CaseNumber, Customer_Email__c, Contractor__c,Customer_Phone__c, Customer_Name__c, Unit__r.Name, Unit__r.SAP_Unit_Number__c,
                        Project__r.Office_Location__c, Status, Project__r.Name, EndDate, StartDate, Unit__c, WorkOrderNumber, Project__r.ProjectNameArabic__c,
                        Owner.Name,Owner.Email, Contractor_Name__c,Contractor_Email__c, New_Requester_Phone__c, New_Requester_Name__c, New_Requester_Email__c, Requester_Name__c, Requester_Comment__c, Requester_Phone__c, Requester_Email__c, Is_Tenet_Request__c FROM WorkOrder LIMIT 1];
        ServiceAppointment sa = [SELECT Id, Status, ParentRecordId, SchedStartTime, SchedEndTime, EarliestStartTime, DueDate FROM ServiceAppointment LIMIT 1];
        ContentVersion contentVersionObj = [SELECT Id, Title, VersionData FROM ContentVersion LIMIT 1];
        OrgWideEmailAddress orgWideEmail = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];
        
        
        Messaging.SingleEmailMessage res = DLPEmailHandler.sendEmailProcess(
            mailTemplateCustomer, wo, sa, new List<String>{wo.Customer_Email__c}, contentVersionObj, orgWideEmail
        );
        // Test with an HTML template
        Messaging.SingleEmailMessage res1 = DLPEmailHandler.sendEmailProcess(
            mailTemplateDlpOutOfScopeForCustomer, wo, sa, new List<String>{wo.Customer_Email__c}, contentVersionObj, orgWideEmail
        );
        
        // Test with a text template
        Messaging.SingleEmailMessage resText = DLPEmailHandler.sendEmailProcess(
            mailTemplateWorkOrderClosedForCustomer, wo, sa, new List<String>{wo.Customer_Email__c}, contentVersionObj, orgWideEmail
        );
        
        // Test missing content version object
        Messaging.SingleEmailMessage resNoAttachment = DLPEmailHandler.sendEmailProcess(
            mailTemplateCustomerNotAvailable, wo, sa, new List<String>{wo.Customer_Email__c}, null, orgWideEmail
        );
        
        // Additional template variations
        EmailTemplate mailTemplateServiceAppointment = EmailUtil.getEmailTemplateByName(SERVICE_APPOINTMENT_BOOKED_NOTIFICATION_FOR_CONTRACTOR);
        Messaging.SingleEmailMessage resServiceAppointment = DLPEmailHandler.sendEmailProcess(
            mailTemplateServiceAppointment, wo, sa, new List<String>{wo.Customer_Email__c}, contentVersionObj, orgWideEmail
        );
    }    
    
    @isTest
    static void sendEmailProcess_Test2() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'testcontact@example.com',
            AccountId = testAccount.Id
        );
        insert testContact;
        
        List<DLPEmailHandler.SendEmailRequest> requests = new List<DLPEmailHandler.SendEmailRequest>();
        DLPEmailHandler.SendEmailRequest request = new DLPEmailHandler.SendEmailRequest();
        request.templateName = 'Customer Not Available';
        request.TargetObjectId = testContact.Id;
        request.whatId = testAccount.Id;
        request.toAddress = new List<String>{'recipient@example.com'};
            requests.add(request);
        
        Test.startTest();
        DLPEmailHandler.sendEmailAndLogActivity(requests);
        Test.stopTest();
        
        Task loggedTask = [SELECT Id, Subject, WhatId, WhoId FROM Task WHERE WhatId = :testAccount.Id AND WhoId = :testContact.Id LIMIT 1];
        System.assertNotEquals(null, loggedTask, 'A task should have been logged.');
    }
}