@isTest
public class HandoverPaymentReminderBatchTest {
    @testSetup
    static void setup() {
        user crmUser = new User();
        System.runAs ( new User(Id = UserInfo.getUserId()) ) {
            Profile p = [SELECT Id FROM Profile WHERE Name='CRM Operations'];
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Handover_CRM_Team'];
            
            crmUser = new User(FirstName = 'CRM', LastName='User', Alias = 'op', Email='crmUser@bloom.com', EmailEncodingKey='UTF-8',ProfileId = p.Id, 
                               LocaleSidKey = 'en_US', LanguageLocaleKey='en_US', TimeZoneSidKey='America/Los_Angeles', UserName='crmUser@bloom.com.u1');
            insert crmUser;
            
            insert new PermissionSetAssignment(AssigneeId = crmUser.Id,PermissionSetId = ps.Id);
        }
           User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
      EmailTemplate firstpaymentremindertemplate;
      EmailTemplate secondpaymentremindertemplate;
        
      
   System.runAs(testUser) {
            firstpaymentremindertemplate = TestDataFactory.createEmailTemplate('firstpaymentremindertemplate');
            firstpaymentremindertemplate.DeveloperName = 'firstpaymentremindertemplate' + DateTime.now().getTime(); 
            firstpaymentremindertemplate.Subject = 'firstpaymentremindertemplate';
            firstpaymentremindertemplate.HtmlValue = 'Hello {{{Handover__c.Customer_Name__c}}}, your unit {{{Handover__c.Unit_Code__c}}} is ready.';
            firstpaymentremindertemplate.Body = 'Hello {{{Handover__c.Customer_Name__c}}}, your unit {{{Handover__c.Unit_Code__c}}} is ready.';
            // -----------------------------------------------
            
            insert firstpaymentremindertemplate;
       
         secondpaymentremindertemplate = TestDataFactory.createEmailTemplate('secondpaymentremindertemplate');
            secondpaymentremindertemplate.DeveloperName = 'secondpaymentremindertemplate' + DateTime.now().getTime(); 
            secondpaymentremindertemplate.Subject = 'secondpaymentremindertemplate';
            secondpaymentremindertemplate.HtmlValue = 'Hellonoc {{{Handover__c.Customer_Name__c}}}, your unit {{{Handover__c.Unit_Code__c}}} is ready.';
            secondpaymentremindertemplate.Body = 'Hello {{{Handover__c.Customer_Name__c}}}, your unit {{{Handover__c.Unit_Code__c}}} is ready.';
            // -----------------------------------------------
            
            insert secondpaymentremindertemplate;
        }
     
        
        Schema.RecordTypeInfo recordTypeInfo = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('PersonAccount');
        Account acc = new Account();
        acc.LastName = 'Test Acc';
        acc.RecordTypeId = recordTypeInfo.getRecordTypeId();
        acc.PersonEmail = 'testa@gmail.com';
        insert acc;
        
         Account acc2 = new Account();
        acc2.LastName = 'Test Acc';
        acc2.RecordTypeId = recordTypeInfo.getRecordTypeId();
        acc2.PersonEmail = 'testa@gmail.com';
        insert acc2;
        
         Account acc1 = new Account();
        acc1.LastName = 'Test Acc';
        acc1.RecordTypeId = recordTypeInfo.getRecordTypeId();
        acc1.PersonEmail = 'testa@gmail.com';
        insert acc1;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.AccountId = acc.Id;
        opp.LeadChannel__c = 'Call';
       // opp.LeadSubSource__c = 'Broker';
        opp.StageName = 'New';
        opp.WinReason__c = 'Price';
        opp.CloseDate = Date.today();
        insert opp;
        
        
        
        
        SalesOrder__c sc = new SalesOrder__c();
        sc.Name ='Test sales order';
        sc.Account__c = acc.Id;
        insert sc;
        
         DocumentType__c SOAdoctype = new DocumentType__c();
        SOAdoctype.Type__c = 'SOA';
        SOAdoctype.ObjectType__c = 'Handover';
        insert SOAdoctype;
        
        
        
           SalesOrder__c sc1 = new SalesOrder__c();
        sc1.Name ='Test sales order';
        sc1.Account__c = acc1.Id;
        insert sc1;
        
           SalesOrder__c sc2 = new SalesOrder__c();
        sc2.Name ='Test sales order';
        sc2.Account__c = acc2.Id;
        insert sc2;
        
        
           SalesOrder__c sc3 = new SalesOrder__c();
        sc3.Name ='Test sales order';
        sc3.Account__c = acc2.Id;
        insert sc3;
        
        
           SalesOrder__c sc4 = new SalesOrder__c();
        sc4.Name ='Test sales order';
        sc4.Account__c = acc2.Id;
        insert sc4;
        
        
           SalesOrder__c sc5 = new SalesOrder__c();
        sc5.Name ='Test sales order';
        sc5.Account__c = acc2.Id;
        insert sc5;
        
        Project__c pr = new Project__c();
        pr.Name = 'testProject';        
        insert pr;
        
        BuildingSection__c bld = new BuildingSection__c();
        bld.Name = 'testBuilding';
        bld.BuildingSectionCode__c = '1234567890';
        bld.Project__c = pr.Id; 
        insert bld; 
        
          HandoverPhase__c  hphase = new HandoverPhase__c();
        hphase.Project__c = pr.id;
         hphase.PaymentReminderStop__c = false;
        hphase.RequiredSOAAttachment__c=true;
        hphase.FirstHOPaymentReminderEmailTempId__c=firstpaymentremindertemplate.id;
        hphase.SecondHOPaymentReminderEmailTempId__c=secondpaymentremindertemplate.id;
       hphase.ThirdHOPaymentReminderEmailTempId__c=firstpaymentremindertemplate.id;
        
        hphase.Name = 'Test';
       
        insert hphase;
        
        Unit__c unit = new Unit__c();
        unit.Name = 'Unit001';
        unit.SAP_Unit_Number__c = '123';
        unit.Project__c= pr.id;
        unit.RelatedOpportunity__c = opp.Id;
        unit.Active_Sales_Order__c = sc.Id;
        unit.RelatedSalesOrder__c = sc.Id;
        unit.BuildingSectionName__c = bld.Id;
        insert unit;
        
         
        Unit__c unit1 = new Unit__c();
        unit1.Name = 'Unit002';
        unit1.Project__c= pr.id;
        unit1.SAP_Unit_Number__c = '123';
        
        unit1.RelatedOpportunity__c = opp.Id;
        unit1.Active_Sales_Order__c = sc1.Id;
        unit1.RelatedSalesOrder__c = sc1.Id;
        unit1.Project__c= pr.id;
        unit1.BuildingSectionName__c = bld.Id;
        insert unit1;
        
         
        Unit__c unit2 = new Unit__c();
        unit2.Name = 'Unit003';
        unit2.SAP_Unit_Number__c = '123';
        unit2.RelatedOpportunity__c = opp.Id;
        unit2.Active_Sales_Order__c = sc2.Id;
        unit2.Project__c= pr.id;
        unit2.RelatedSalesOrder__c = sc2.Id;
        unit2.BuildingSectionName__c = bld.Id;
        insert unit2;
        
         Unit__c unit3 = new Unit__c();
        unit3.Name = 'Unit004';
        unit3.SAP_Unit_Number__c = '123';
        unit3.RelatedOpportunity__c = opp.Id;
        unit3.Active_Sales_Order__c = sc3.Id;
        unit3.Project__c= pr.id;
        unit3.RelatedSalesOrder__c = sc3.Id;
        unit3.BuildingSectionName__c = bld.Id;
        insert unit3;
       
         Unit__c unit4 = new Unit__c();
        unit4.Name = 'Unit005';
        unit4.Project__c= pr.id;
        unit4.SAP_Unit_Number__c = '123';
        unit4.RelatedOpportunity__c = opp.Id;
        unit4.Active_Sales_Order__c = sc4.Id;
        unit4.RelatedSalesOrder__c = sc4.Id;
        unit4.BuildingSectionName__c = bld.Id;
        insert unit4;
        
         Unit__c unit5 = new Unit__c();
        unit5.Name = 'Unit006';
        unit5.Project__c= pr.id;
        unit5.SAP_Unit_Number__c = '123';
        unit5.RelatedOpportunity__c = opp.Id;
        unit5.Active_Sales_Order__c = sc5.Id;
        unit5.RelatedSalesOrder__c = sc5.Id;
        unit5.BuildingSectionName__c = bld.Id;
        insert unit5;
        
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
        
       
        
        
         ServiceCatalog__c  servicecatalog = new ServiceCatalog__c();
        servicecatalog.ProcessFlowType__c= 'Handover';
        servicecatalog.ProcessType__c = 'Sales';
        servicecatalog.Active__c= true;
        servicecatalog.RecordTypeDevName__c = 'Non PHPP';
        insert servicecatalog;

        
        List<Handover__c> handovers = new List<Handover__c>();
        Date tenDaysReminder = Date.today().addDays(-10);
        Date twentyDaysReminder = Date.today().addDays(-20);
        Date thirtyDaysReminder = Date.today().addDays(-30);
        Handover__c ho = new Handover__c();
        ho.Sub_Status__c ='QA De-Snagging';
        ho.Project__c = pr.id;
        ho.Is_Orientation_Letter_Sent__c = true;
        ho.Unit_is_Ready__c = true;
        ho.Customer_Availability_for_CHO__c = Constants.Customer_Not_Available;
        ho.Notice_of_Completion_Date__c = tenDaysReminder;
        ho.unit__c = unit.Id;
        ho.Handover_Phase__c= hphase.id;
        ho.StopAllEmailCommunication__c=false;
        ho.Sales_Order__c = sc.Id;
        ho.ServiceCatalog__c = servicecatalog.Id;
        ho.CRM_Team_Assigned_User__c = crmUser.Id;
        
        handovers.add(ho);
        
        Handover__c ho1 = new Handover__c();
        ho1.Sub_Status__c ='QA De-Snagging';
        ho1.Project__c= pr.id;
        ho1.Is_Orientation_Letter_Sent__c = true;
        ho1.Handover_Phase__c= hphase.id;
        ho1.StopAllEmailCommunication__c=false;
        ho1.Unit_is_Ready__c = true;
        ho1.Customer_Availability_for_CHO__c = Constants.Customer_Not_Available;
      
        ho1.unit__c = unit1.Id;
        ho1.ServiceCatalog__c = servicecatalog.Id;
       
         ho1.CRM_Team_Assigned_User__c = crmUser.Id;
        handovers.add(ho1);
        
         Document__c document5 = new Document__c(
            Document_Name__c = 'SOA',
            DocumentType__c= SOAdoctype.id,
            Handover__c = ho.Id,
            SalesOrder__c = sc1.Id,
            ContentDocumentId__c = con.ContentDocumentId,
            Content_Version_Id__c = con.Id
        );
        insert document5;
        
      
        
        Handover__c ho2 = new Handover__c();
        ho2.Sub_Status__c ='QA De-Snagging';
        ho2.Is_Orientation_Letter_Sent__c = true;
        ho2.Unit_is_Ready__c = true;
        ho2.Project__c= pr.id;
        ho2.Handover_Phase__c= hphase.id;
        ho2.StopAllEmailCommunication__c=false;
        ho2.Customer_Availability_for_CHO__c = Constants.Customer_Not_Available;
        ho2.Notice_of_Completion_Date__c = thirtyDaysReminder;
        ho2.unit__c = unit2.Id;
        ho2.Sales_Order__c = sc2.Id;
        ho2.CRM_Team_Assigned_User__c = crmUser.Id;
        ho2.ServiceCatalog__c = servicecatalog.Id;
        handovers.add(ho2);
        
         Handover__c ho3 = new Handover__c();
        ho3.Sub_Status__c ='QA De-Snagging';
        ho3.Is_Orientation_Letter_Sent__c = true;
        ho3.Handover_Phase__c= hphase.id;
        ho3.Project__c= pr.id;
        ho3.StopAllEmailCommunication__c=false;
        ho3.Unit_is_Ready__c = true;
        ho3.Customer_Availability_for_CHO__c = Constants.Customer_Not_Available;
        ho3.Notice_of_Completion_Date__c = thirtyDaysReminder;
        ho3.Promise_to_Pay_Date__c = thirtyDaysReminder;
        ho3.unit__c = unit3.Id;
        ho3.Sales_Order__c = sc3.Id;
        ho3.CRM_Team_Assigned_User__c = crmUser.Id;
        ho3.ServiceCatalog__c = servicecatalog.Id;
        handovers.add(ho3);
        
        Handover__c ho4 = new Handover__c();
        ho4.Sub_Status__c ='QA De-Snagging';
        ho4.Is_Orientation_Letter_Sent__c = true;
        ho4.Handover_Phase__c= hphase.id;
        ho4.Project__c= pr.id;
        ho4.StopAllEmailCommunication__c=false;
        ho4.Unit_is_Ready__c = true;
        ho4.Customer_Availability_for_CHO__c = Constants.Customer_Not_Available;
        ho4.Notice_of_Completion_Date__c = twentyDaysReminder;
        ho4.Promise_to_Pay_Date__c = twentyDaysReminder;
        ho4.unit__c = unit4.Id;
        ho4.Sales_Order__c = sc4.Id;
        ho4.ServiceCatalog__c = servicecatalog.Id;
        ho4.CRM_Team_Assigned_User__c = crmUser.Id;
        handovers.add(ho4);
       
        
       
        
        Handover__c ho5 = new Handover__c();
        ho5.Sub_Status__c ='QA De-Snagging';
        ho5.Handover_Phase__c= hphase.id;
        ho5.Project__c= pr.id;
        ho5.StopAllEmailCommunication__c=false;
        ho5.Is_Orientation_Letter_Sent__c = true;
        ho5.Unit_is_Ready__c = true;
        ho5.Customer_Availability_for_CHO__c = Constants.Customer_Not_Available;
        ho5.Notice_of_Completion_Date__c = tenDaysReminder;
        ho5.Promise_to_Pay_Date__c = tenDaysReminder;
        ho5.unit__c = unit5.Id;
        ho5.Sales_Order__c = sc5.Id;
        ho5.CRM_Team_Assigned_User__c = crmUser.Id;
        ho5.ServiceCatalog__c = servicecatalog.Id;
        handovers.add(ho5);

        Handoverservice objHandoverService = Handoverservice.getInstance();
        objHandoverService.insertHandovers(handovers);
        
          ho1.Notice_of_Completion_Date__c = twentyDaysReminder;
         ho1.Sales_Order__c = sc1.Id;
        update ho1;
       
        
        
    }
     @isTest
    public static void testBatchExecution() {
        Test.startTest();
        Database.executeBatch(new HandoverPaymentReminderBatch());
           HandoverPaymentReminderBatch scheduler = new HandoverPaymentReminderBatch();
        
        scheduler.execute(null);
        Test.stopTest();
        
        

    }
    
   
}