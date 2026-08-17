@IsTest
public class HandoverControllerTest {
    @IsTest
    static void HandoverControllerTestMethod() {
        
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
      EmailTemplate emailTemplate;
   System.runAs(testUser) {
            emailTemplate = TestDataFactory.createEmailTemplate('templateName');
            emailTemplate.DeveloperName = 'templateName_' + DateTime.now().getTime(); 
            emailTemplate.Subject = 'BCC Announcement';
            
            // --- ADD THESE LINES TO FIX THE NULL POINTER ---
            emailTemplate.HtmlValue = 'Hello {{{Handover__c.Customer_Name__c}}}, your unit {{{Handover__c.Unit_Code__c}}} is ready.';
            emailTemplate.Body = 'Hello {{{Handover__c.Customer_Name__c}}}, your unit {{{Handover__c.Unit_Code__c}}} is ready.';
            // -----------------------------------------------
            
            insert emailTemplate;
        }
        
        User u = new User();
        System.runAs ( new User(Id = UserInfo.getUserId()) ) {
            Profile p = [SELECT Id FROM Profile WHERE Name='HO Agent'];
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Handover_HO_Agent'];
            
            u = new User(FirstName = 'Ho Agent', LastName='User', Alias = 'op', Email='hoagent@bloom.com', EmailEncodingKey='UTF-8',ProfileId = p.Id, 
                         LocaleSidKey = 'en_US', LanguageLocaleKey='en_US', TimeZoneSidKey='America/Los_Angeles', UserName='hoagent@bloom.com.u1');
            insert u;
            
            insert new PermissionSetAssignment(AssigneeId = u.Id,PermissionSetId = ps.Id);
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
        hphase.Name = 'Test';
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
        servicecatalog.RecordTypeDevName__c = 'Handover';
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
         
         Survey__c survey = new Survey__c();
        survey.Handover__c = handover1.id;
        survey.SurveyType__c = 'Handover Survey';
        survey.Link__c ='';
        insert survey;
        
        
        // Create ContentVersion and associated Document__c record
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Full Guideline Document',
            PathOnClient = 'FullGuidelineDocument.pdf',
            VersionData = Blob.valueOf('Full Guideline Document')
        );
        insert contentVersion;
        
        ContentVersion con = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
        
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
        
        DocumentType__c BCCdoctype = new DocumentType__c();
        BCCdoctype.Type__c = 'BCC Announcement';
      
        BCCdoctype.ObjectType__c = 'Handover Phase';
        
        insert BCCdoctype;
        
        
        
        Document__c document = new Document__c(
            Document_Name__c = 'Full Guideline Document',
            Handover__c = handover1.Id,
            ContentDocumentId__c = con.ContentDocumentId,
            Content_Version_Id__c = con.Id
        );
        insert document;
        Document__c document2 = new Document__c(
            Document_Name__c = 'Full Guideline Document',
            Handover__c = handover1.Id,
            ContentDocumentId__c = con.ContentDocumentId,
            Content_Version_Id__c = con.Id
        );
        insert document2;
        
        Document__c document3 = new Document__c(
            Document_Name__c = 'QA Desnagging Report',
            Handover__c = handover1.Id,
            ContentDocumentId__c = con1.ContentDocumentId,
            Content_Version_Id__c = con1.Id
        );
        insert document3;
        
        Document__c document4 = new Document__c(
            Document_Name__c = 'CHO Desnagging Report',
            Handover__c = handover1.Id,
            ContentDocumentId__c = con.ContentDocumentId,
            Content_Version_Id__c = con.Id
        );
        
        
        insert document4;
        Document__c document5 = new Document__c(
            Document_Name__c = 'SOA',
            DocumentType__c= SOAdoctype.id,
            Handover__c = handover1.Id,
            ContentDocumentId__c = con.ContentDocumentId,
            Content_Version_Id__c = con.Id
        );
        insert document5;
        Document__c document6 = new Document__c(
            Document_Name__c = 'BCC Announcement',
            DocumentType__c= BCCdoctype.id,
            Project__c= project.id,
            HandoverPhase__c=hphase.id,
            ContentDocumentId__c = con.ContentDocumentId,
            Content_Version_Id__c = con.Id
        );
        insert document6;
        Test.startTest();  
        System.runAs(crmUser){
            HandoverController.sendBCCEmails(new list<id>{handover1.id});
            HandoverController.sendNOCCHOEmail(new list<id>{handover1.id},project.id,new List<Id>{sc.id});
            HandoverController.getProjects();
            HandoverController.getHandoverPhase(project.Id);
            HandoverController.getHandoverData(project.Id,hphase.id,'BCC');
            HandoverController.getHandoverData(project.Id,hphase.id,'NOC-CHO');
             HandoverController.validateForNextReview(handover1.id);
             HandoverController.updateHandoverOwner(handover1.id);
            // HandoverController.getSurveyLink(handover1.id);
            
         
           
           Test.stopTest();
            
            
        }
    }
    
}