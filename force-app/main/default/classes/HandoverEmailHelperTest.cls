@isTest
public class HandoverEmailHelperTest {

    @isTest
   public static void HandoverEmailHelperTestMethod(){  
       
        
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
      EmailTemplate emailTemplate;
      EmailTemplate nocEmailTemplate;
      
   System.runAs(testUser) {
            emailTemplate = TestDataFactory.createEmailTemplate('templateName');
            emailTemplate.DeveloperName = 'templateName_' + DateTime.now().getTime(); 
            emailTemplate.Subject = 'BCC Announcement';
            emailTemplate.HtmlValue = 'Hello {{{Handover__c.Customer_Name__c}}}, your unit {{{Handover__c.Unit_Code__c}}} is ready.';
            emailTemplate.Body = 'Hello {{{Handover__c.Customer_Name__c}}}, your unit {{{Handover__c.Unit_Code__c}}} is ready.';
            // -----------------------------------------------
            
            insert emailTemplate;
       
         nocEmailTemplate = TestDataFactory.createEmailTemplate('nocEmailTemplate');
            nocEmailTemplate.DeveloperName = 'templateName_noc' + DateTime.now().getTime(); 
            nocEmailTemplate.Subject = 'nocEmailTemplate';
            nocEmailTemplate.HtmlValue = 'Hellonoc {{{Handover__c.Customer_Name__c}}}, your unit {{{Handover__c.Unit_Code__c}}} is ready.';
            nocEmailTemplate.Body = 'Hello {{{Handover__c.Customer_Name__c}}}, your unit {{{Handover__c.Unit_Code__c}}} is ready.';
            // -----------------------------------------------
            
            insert nocEmailTemplate;
        }
        
        User u = new User();
        System.runAs ( new User(Id = UserInfo.getUserId()) ) {
            Profile p = [SELECT Id FROM Profile WHERE Name='HO Agent'];
            PermissionSet ps = [SELECT Id,Name FROM PermissionSet WHERE Name = 'Handover_HO_Agent'];
            
            u = new User(FirstName = 'Ho Agent', LastName='User', Alias = 'op', Email='hoagent@bloom.com', EmailEncodingKey='UTF-8',ProfileId = p.Id, 
                         LocaleSidKey = 'en_US', LanguageLocaleKey='en_US', TimeZoneSidKey='America/Los_Angeles', UserName='hoagent@bloom.com.u1');
            insert u;
            
            insert new PermissionSetAssignment(AssigneeId = u.Id,PermissionSetId = ps.Id);

        User crmUser = new User();
        System.runAs ( new User(Id = UserInfo.getUserId()) ) {
            Profile pr = [SELECT Id FROM Profile WHERE Name='CRM Operations'];
            PermissionSet psi = [SELECT Id,Name FROM PermissionSet WHERE Name = 'Handover_CRM_Team'];
           
            
            crmUser = new User(FirstName = 'CRM', LastName='User', Alias = 'op', Email='crmUser@bloom.com', EmailEncodingKey='UTF-8',ProfileId = p.Id, 
                               LocaleSidKey = 'en_US', LanguageLocaleKey='en_US', TimeZoneSidKey='America/Los_Angeles', UserName='crmUser@bloom.com.u1');
            insert crmUser;
            
            insert new PermissionSetAssignment(AssigneeId = crmUser.Id,PermissionSetId = psi.Id);
        }
        
      
        
        Project__c project = new Project__c(
            Name = 'Test Project',
            Office_Location__c = 'Test Location',
            isHandoverAvailable__c=true
        );
        insert project;
        
       //   EmailTemplate emailTemplate  = TestDataFactory.createEmailTemplate('templateName');
       //     insert emailTemplate;
        
        HandoverPhase__c  hphase = new HandoverPhase__c();
        hphase.Project__c = project.id;
        hphase.NOCCHOEmailtemplateId__c = nocEmailTemplate.id;
        hphase.DoorNumberClarificationrequired__c= true;
        hphase.Name = 'Test';
        hphase.BCCRequired__c= true;
        hphase.BCCEmailTemplateId__c = emailTemplate.id;
        insert hphase;
        
        // Create a Unit
        Unit__c unit = new Unit__c(
            Name = 'Unit Test A1435',
            SAP_Unit_Number__c = 'SAP12345',
            Project__c= project.id,
            Status__c = 'Available',
            handoverPhase__c = hphase.Id
        );
        insert unit;
         Unit__c unit1 = new Unit__c(
            Name = 'Unit Test A14354',
            SAP_Unit_Number__c = 'SAP123455',
            Project__c= project.id,
             handoverPhase__c = hphase.Id,
            Status__c = 'Available'
        );
        insert unit1;
        
        
        Schema.RecordTypeInfo recordTypeInfo = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('PersonAccount');
        
        Account acc = new Account();
        acc.LastName = 'Test Acc';
        acc.RecordTypeId = recordTypeInfo.getRecordTypeId();
        acc.PersonEmail = 'test@gmail.com';
        insert acc;
        
        
        SalesOrder__c sc = new SalesOrder__c();
        sc.Name ='Test sales order';
        sc.Unit__c = unit.Id;
        sc.Account__c = acc.Id;
        insert sc;
        
        
        unit.Active_Sales_Order__c = sc.Id;
        unit.RelatedSalesOrder__c = sc.Id;
        update unit;
        
        Profile profileCRM = [SELECT Id FROM Profile WHERE Name = 'CRM Operations'];
        
        User userRecord = new User(
            Alias = 'zaki',
            Email = 'zakial@gmail.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Zaki Al Bakri',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profileCRM.Id,
            TimeZoneSidKey = 'Asia/Dubai',
            UserName = 'zaki.al.bakri@example.com'
        );
        insert userRecord;
        
         ServiceCatalog__c  servicecatalog = new ServiceCatalog__c();
        servicecatalog.ProcessFlowType__c= 'Handover';
        servicecatalog.ProcessType__c = 'Sales';
        servicecatalog.Active__c= true;
        servicecatalog.RecordTypeDevName__c = 'Non PHPP';
        insert servicecatalog;
        
        
       
        
        // Create a Handover record
        Handover__c handover1 = new Handover__c(
            Name = 'Test Handover',
            Customer_Email__c = 'test@example.com',
            OwnerId = crmUser.id,
            ServiceCatalog__c = servicecatalog.Id,
            Is_Orientation_Letter_Sent__c = false,
            Is_BCC_Announcement_Sent__c =false,
            Unit__c = unit.Id,
            CRM_Team_Assigned_User__c= crmUser.id,
            HO_Agent_Assigned_User__c= u.id,
            Project__c = project.Id,
            Customer_Availability_for_CHO__c = 'Customer Available',
            Unit_is_Ready__c=false,
            UnitCategory__c='Registered Unit',
            Is_Notice_of_Completion_Sent__c=false,
            Handover_Phase__c=hphase.id,
            Sub_Status__c= 'QA Snagging'
        );
        insert handover1;
        
        Event evn = new Event();
        evn.WhatId = handover1.Id;
        evn.Subject = 'Other';
        evn.StartDateTime = DateTime.newInstance(2024, 6, 20, 8, 43, 38); 
        evn.EndDateTime = DateTime.newInstance(2024, 6, 22, 8, 43, 38); 
        evn.CurrencyIsoCode ='AED';
        insert evn;
        
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'Full Guideline Document';
        contentVersion.PathOnClient = 'FullGuidelineDocument.pdf';
        contentVersion.VersionData = Blob.valueOf('Full Guideline Document');
        insert contentVersion;
        system.debug('contentVersion'+contentVersion);
        ContentVersion con = [SELECT Id, ContentDocumentId FROM ContentVersion where Id = : contentVersion.Id];
        system.debug('con version'+con);
        
        Document__c dc= new Document__c();
        dc.Document_Name__c = 'Full Guideline Document';
        dc.Handover__c = handover1.Id;
        dc.ContentDocumentId__c = con.ContentDocumentId;
        dc.Content_Version_Id__c = con.Id;
        insert dc;

        System.debug('DCCCCC=====> ' + dc);
        
        List<String> handoverIds = new List<String>{handover1.Id};
       
       HandoverEmailHelper.sendEmailProcess(
      emailTemplate.id,
    handover1.Id, // Replace with actual Handover__c record Id
    new List<String>{'to@example.com'},
    new List<String>{'bcc@example.com'},
    new List<String>{'Full Guideline Document'}
);
         HandoverEmailHelper.sendEmailProcess(
    emailTemplate.id,
    handover1.Id, // Replace with actual Handover__c record Id
    new List<String>{''},
    new List<String>{'bcc@example.com'},
    new List<String>{'Full Guideline Document'}
);
       
       HandoverEmailHelper.getDynamicBody('test',handover1);
      

       
   }
   }}