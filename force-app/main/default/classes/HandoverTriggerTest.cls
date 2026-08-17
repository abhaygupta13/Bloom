@isTest
public class HandoverTriggerTest {
    
    @testSetup static void setup() {
        Schema.RecordTypeInfo recordTypeInfo = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('PersonAccount');
        
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
        
        
        Account acc = new Account();
        acc.LastName = 'Test Acc';
        acc.RecordTypeId = recordTypeInfo.getRecordTypeId();
        acc.PersonEmail = 'test@gmail.com';
        insert acc;
        
        Account acc2 = new Account();
        acc2.LastName = 'Test Acc2';
        acc2.RecordTypeId = recordTypeInfo.getRecordTypeId();
        acc2.PersonEmail = 'test123@gmail.com';
        insert acc2;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.AccountId = acc.Id;
        opp.LeadChannel__c = 'Call';
        // opp.LeadSubSource__c = 'Kiosk';
        opp.StageName = 'New';
        opp.WinReason__c = 'Price';
        opp.CloseDate = Date.today();
        insert opp;
        
        Opportunity opp2 = new Opportunity();
        opp2.Name = 'Test Opp';
        opp2.AccountId = acc2.Id;
        opp2.LeadChannel__c = 'Call';
        // opp2.LeadSubSource__c = 'Broker';
        opp2.StageName = 'New';
        opp2.WinReason__c = 'Price';
        opp2.CloseDate = Date.today();
        insert opp2;
        
        Project__c pr = new Project__c();
        pr.Name = 'testProject'; 
        pr.ResaleUnitADMFeeVilla__c = 2;
        pr.ResaleUnitADMFeeApt__c = 2;
        pr.ResaleWithMortgageADMFeeVilla__c = 2;
        pr.ResaleWithMortgageADMFeeApt__c = 2;
        pr.NewSaleADMFeeVilla__c = 2;
        pr.NewSaleADMFeeApt__c = 2;
        pr.NewSaleWithMortgageADMFeeVilla__c = 2;
        pr.NewSaleWithMortgageADMFeeApt__c = 2;
        insert pr;
        
        Project__c pr2 = new Project__c();
        pr2.Name = 'testProject2';      
        pr2.ResaleUnitADMFeeVilla__c = 2;
        pr2.ResaleUnitADMFeeApt__c = 2;
        pr2.ResaleWithMortgageADMFeeVilla__c = 2;
        pr2.ResaleWithMortgageADMFeeApt__c = 2;
        pr2.NewSaleADMFeeVilla__c = 2;
        pr2.NewSaleADMFeeApt__c = 2;
        pr2.NewSaleWithMortgageADMFeeVilla__c = 2;
        pr2.NewSaleWithMortgageADMFeeApt__c = 2;
        insert pr2;
        
        BuildingSection__c bld = new BuildingSection__c();
        bld.Name = 'testBuilding';
        bld.BuildingSectionCode__c = '1234567890';
        bld.Project__c = pr.Id; 
        insert bld;
        
        BuildingSection__c bld2 = new BuildingSection__c();
        bld2.Name = 'testBuilding2';
        bld2.BuildingSectionCode__c = '12345678';
        bld2.Project__c = pr2.Id; 
        insert bld2;
        
        Unit__c unit = new Unit__c();
        unit.Name = 'Unit001';
        
        unit.SAP_Unit_Number__c = '123';
        unit.RelatedOpportunity__c = opp.Id;
        unit.BuildingSectionName__c = bld.Id;
        insert unit;
        
        Unit__c unit2 = new Unit__c();
        unit2.Name = 'Unit002';
       
        unit2.SAP_Unit_Number__c = '345';
        unit2.RelatedOpportunity__c = opp2.Id;
        unit2.BuildingSectionName__c = bld2.Id;
        insert unit2;
        
        
        SalesOrder__c sc = new SalesOrder__c();
        sc.Name ='Test sales order';
        sc.Unit__c = unit.Id;
        sc.Account__c = acc.Id;
        sc.NetAmount__c = 2345;
        insert sc;
        
        SalesOrder__c sc1 = new SalesOrder__c();
        sc1.Name ='Test sales order 2';
        sc1.Unit__c = unit2.Id;
        sc1.Account__c = acc2.Id;
        sc1.NetAmount__c = 2345;
        insert sc1;
        
         Document__c doc = new Document__c();
        doc.Project__c = pr.Id;
        doc.Document_Name__c = HandoverConstants.BCC_DOCUMENT;
        insert doc;
        
        unit.Active_Sales_Order__c = sc.Id;
        unit.RelatedSalesOrder__c = sc.Id;
        update unit;
        
        unit2.Active_Sales_Order__c = sc1.Id;
        unit2.RelatedSalesOrder__c = sc1.Id;
        update unit2;
        
        Document__c doc1 = new Document__c();
        doc1.Document_Name__c = 'Passport';
        doc1.SalesOrder__c = sc.Id;
        insert doc1;
         Document__c doc2 = new Document__c();
        doc2.Document_Name__c = 'Passport';
        doc2.SalesOrder__c = sc1.Id;
        insert doc2;
        
        List<String> documentNames = new List<String>{
            'ADDC NOC',
                'QA Snagging Report',
                'Emirates ID',
                'SOA',
                'CHO Desnagging Report',
                'SPA',
                'Bank NOC',
                'Mortgage Contract',
                'Mortgage Cheque Copy',
                'Leasing ADDC NOC',
                'Bloom Title Deed',
                'Service Charge Clearance Letter',
                'QA Desnagging Report',
                'CHO Snagging Report',
                'Developer NOC',
                'KHO',
                'Handover Payment Attachment',
                'Passport',
                'Lease Agreement 1',
                'Title Deed',
                'Tawtheeq Registration Confirmation'
                };
                    
                    List<DocumentType__c> documentRecords = new List<DocumentType__c>();
        
        for (String name : documentNames) {
            documentRecords.add(new DocumentType__c(
                Type__c = name,
                ObjectType__c = 'Handover',
                IsDocgen__c = false,
                Active__c = true,
                DigitalSignature__c = false
            ));
        }        
        insert documentRecords;
        
         ServiceCatalog__c  servicecatalog = new ServiceCatalog__c();
        servicecatalog.ProcessFlowType__c= 'Handover';
        servicecatalog.ProcessType__c = 'Sales';
        servicecatalog.Active__c= true;
        servicecatalog.RecordTypeDevName__c = 'Handover';
        insert servicecatalog;

        // Insert setup objects in a separate transaction
        
        // Insert Handover objects with runAs user
        Schema.RecordTypeInfo handoverRecordTypeInfo = Schema.getGlobalDescribe().get('Handover__c').getDescribe().getRecordTypeInfosByDeveloperName().get('Handover');
        System.runAs(operationUser) {
            Handover__c ho = new Handover__c();
           // ho.Sub_Status__c ='New';
            ho.Is_Manual__c = 'Yes';
            ho.unit__c = unit.Id;
            ho.Sales_Order__c = sc.Id;
            ho.Customer_Email__c ='test@gmail.com';
            ho.Project__c=pr.id;
            ho.RecordTypeId = handoverRecordTypeInfo.getRecordTypeId();
            ho.OwnerId = operationUser.Id;
            ho.ServiceCatalog__c = servicecatalog.Id;
            insert ho;
            
            Handover__c ho1 = new Handover__c();
           // ho1.Sub_Status__c ='New';
            ho1.Is_Manual__c = 'Yes';
            ho.unit__c = unit2.Id;
            ho1.Sales_Order__c = sc1.Id;
            ho1.ServiceCatalog__c = servicecatalog.Id;
            ho1.Customer_Email__c ='test134@gmail.com';
            ho1.RecordTypeId = handoverRecordTypeInfo.getRecordTypeId();
            ho1.OwnerId = operationUser.Id;
            insert ho1;
            system.debug('ho1--->'+ho1);
        }    
        
        PaymentPlan__c  pp = new PaymentPlan__c();
        pp.Name ='July Plan';
        pp.Unit__c= unit.id;
        pp.Description__c ='Test Description';
        pp.Description__c = 'Test';
        pp.IsActive__c = 'NO';
        pp.BrokerPortalFlag__c = True;
        pp.Classification__c = Constants.PAYMENT_PLAN_TYPE_STANDARD;
        insert pp;
        
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
        
        InstallmentLines__c installmentLines = new InstallmentLines__c();
        installmentLines.PaymentPlan__c = pp.id;
        installmentLines.PaymentInstallments__c =ppi.Id;
        installmentLines.SalesOrder__c = sc.id;
        installmentLines.Description__c='4th Installment';
        installmentLines.InstallmentAmount__c = 100000;
        installmentLines.LPCCutOffAmt__c =0;
        installmentLines.MinInvAmtrem__c =100;
        installmentLines.LPCRate__c =12;
        installmentLines.InstallmentPercentage__c = 25;
        installmentLines.BrokerPayoutPercentage__c = 20;
        installmentLines.Description__c = 'Description';
        installmentLines.RevisedDate__c=null;
        installmentLines.Send_to_SAP__c = true;
        installmentLines.GracePeriod__c=1;
        installmentLines.InstallmentAmount__c =70000;
        installmentLines.Inst_inc_tax_in_words__c  = '';
        installmentLines.InstallmentDate__c= Date.today() - 12;
        installmentLines.AmountReceived__c=1500;
        installmentLines.CutOffDate__c=date.today();
        installmentLines.LPCAmount__c=500;
        installmentLines.Type__c = 'Handover';
        insert installmentLines;
    }
    
    @isTest
    public static void QASnaggingAndDeSnagging(){
        User operationTeam = [SELECT Id,Email from User where Email = 'operationUser@bloom.com' LIMIT 1];
         User crmoperationTeam = [SELECT Id,Email from User where Email = 'crmUser@bloom.com' LIMIT 1];
        User hoAgent = [SELECT Id,Email from User where Email = 'hoagent@bloom.com' LIMIT 1];
        Handover__c handover = [Select ID,Name,Customer_Email__c,Is_Manual__c,Sub_Status__c,Sales_Order__c,unit__c,OwnerId from Handover__c WHERE Customer_Email__c ='test@gmail.com' LIMIT 1];
        
        
        
        // Handover__c handover2 = [Select ID,Name,Customer_Email__c,Is_Manual__c,Sub_Status__c,Sales_Order__c,unit__c,OwnerId from Handover__c WHERE Customer_Email__c ='test134@gmail.com' LIMIT 1];
        System.runAs(operationTeam){
            handover.OwnerId = hoAgent.Id;
            //update handover;
        }
        
        Group testQueue = new Group();
        testQueue.Name = 'Handover Operation Team Queue'; 
        testQueue.Type = 'Queue';
        insert testQueue;
        
        User user = [SELECT Id FROM User WHERE IsActive = true AND Profile.Name = 'System Administrator' LIMIT 1];
        System.runAs(user){
            GroupMember queueMember1 = new GroupMember();
            queueMember1.GroupId = testQueue.Id;
            queueMember1.UserOrGroupId = operationTeam.Id;
            insert queueMember1;
        }
        
        System.runAs(user){
            handover.Sub_Status__c = HandoverConstants.Handover_Sub_Status_QA_Snagging;
            try {
                update handover;
            } catch (Exception e) {
            }
            
            handover.Sub_Status__c = HandoverConstants.Handover_Sub_Status_QA_DeSnagging;
            try {
                update handover;
            } catch (Exception e) {
            }
            
            Test.startTest();
            List<Document__c> QASnagDocList = [SELECT Id, Document_Name__c FROM Document__c WHERE Document_Name__c = 'QA Snagging Report' AND Handover__c =: handover.Id LIMIT 1];
            System.debug('QASnagDocList'+QASnagDocList);
            if(QASnagDocList.size()>0){
                CustomDocManageController.addFilesonRecordCreate('base64Pdf', 'hello'+'pdf', QASnagDocList[0]);
            }
            List<Document__c> QADeSnagDocList = [SELECT Id, Document_Name__c FROM Document__c WHERE Document_Name__c = 'QA Desnagging Report' AND Handover__c =: handover.Id LIMIT 1];
            System.debug('QADeSnagDocList'+QADeSnagDocList);
            if(QADeSnagDocList.size()>0){
                CustomDocManageController.addFilesonRecordCreate('base64Pdf', 'hello'+'pdf', QADeSnagDocList[0]);
            }
            
            handover.Sub_Status__c = HandoverConstants.Handover_Sub_Status_QA_Snagging;
            handover.Operation_Team_Assigned_User__c = operationTeam.id;
            update handover;
             handover.CRM_Team_Assigned_User__c = crmoperationTeam.id;
            update handover;
           
            Test.stopTest();
           
        }
    }
    
    @isTest
    public static void bookAppointmentsForAllUnitCategories() {
        List<String> unitCategories = new List<String>{
            'Registered Unit',
            'Resale Unit',
            'Resale with Mortgage',
            'New Sale',
            'New Sale with Mortgage',
            'Registered Unit with Mortgage'
        };

        User operationTeam = [SELECT Id, Email FROM User WHERE Email = 'operationUser@bloom.com' LIMIT 1];
        User hoAgent = [SELECT Id, Email FROM User WHERE Email = 'hoagent@bloom.com' LIMIT 1];
        User crmUser = [SELECT Id, Email FROM User WHERE Email = 'crmUser@bloom.com' LIMIT 1];

        Handover__c handover = [Select ID,Name,Customer_Email__c,UnitCategory__c,Project__c,Is_Manual__c,Sub_Status__c,Sales_Order__c,unit__c,OwnerId from Handover__c WHERE Customer_Email__c ='test@gmail.com' LIMIT 1];
         Project__c pr = new Project__c();
        pr.Name = 'testProject'; 
        pr.ResaleUnitADMFeeVilla__c = 2;
        pr.ResaleUnitADMFeeApt__c = 2;
        pr.ResaleWithMortgageADMFeeVilla__c = 2;
        pr.ResaleWithMortgageADMFeeApt__c = 2;
        pr.NewSaleADMFeeVilla__c = 2;
        pr.NewSaleADMFeeApt__c = 2;
        pr.NewSaleWithMortgageADMFeeVilla__c = 2;
        pr.NewSaleWithMortgageADMFeeApt__c = 2;
        insert pr;
        handover.UnitCategory__c = 'Resale Unit';
        handover.Project__c = pr.id;
        update handover;

        List<Document__c> QADeSnagDocList = [
            SELECT Id, Document_Name__c
            FROM Document__c
            WHERE Document_Name__c = 'QA Desnagging Report' AND Handover__c = :handover.Id
            LIMIT 1
        ];

        if (!QADeSnagDocList.isEmpty()) {
            CustomDocManageController.addFilesonRecordCreate('base64Pdf', 'hello.pdf', QADeSnagDocList[0]);
        }
        Test.startTest();
        List<Handover__c> allHandovers = new List<Handover__c>();
        
        for (String category : unitCategories) {
            Handover__c ho = handover;
            ho.Sub_Status__c = HandoverConstants.Handover_Sub_Status_QA_DeSnagging;
            ho.OwnerId = operationTeam.Id;
            ho.UnitCategory__c = category;
            ho.Unit_is_Ready__c = true;
            ho.Is_Orientation_Letter_Sent__c = true;
            ho.Notice_of_Completion_Date__c = Date.today();
            update ho;
        }
        
        Test.stopTest();
    }
    
  /*  @isTest
    public static void bookAnAppoin(){
        User operationTeam = [SELECT Id,Email from User where Email = 'operationUser@bloom.com' LIMIT 1];
        User hoAgent = [SELECT Id,Email from User where Email = 'hoagent@bloom.com' LIMIT 1];
        Handover__c handover = [Select ID,Name,Customer_Email__c,Is_Manual__c,Sub_Status__c,Sales_Order__c,unit__c,OwnerId from Handover__c WHERE Customer_Email__c ='test@gmail.com' LIMIT 1];
        User crmUser = [SELECT Id,Email from User where Email = 'crmUser@bloom.com' LIMIT 1];
        handover.OwnerId = operationTeam.Id;
        List<Document__c> QADeSnagDocList = [SELECT Id, Document_Name__c FROM Document__c WHERE Document_Name__c = 'QA Desnagging Report' AND Handover__c =: handover.Id LIMIT 1];
        System.debug('QADeSnagDocList'+QADeSnagDocList);
        if(QADeSnagDocList.size()>0){
            CustomDocManageController.addFilesonRecordCreate('base64Pdf', 'hello'+'pdf', QADeSnagDocList[0]);
        }
        handover.Sub_Status__c = HandoverConstants.Handover_Sub_Status_QA_DeSnagging;
        Update handover;
        Test.startTest();
        System.runAs(operationTeam){
            handover.Sub_Status__c = HandoverConstants.Handover_Sub_Status_Home_Orientation_Sent;
            handover.OwnerId = operationTeam.Id;
            try {
                update handover;
            } catch (Exception e) {
            }
        }
        handover.Sub_Status__c = HandoverConstants.Handover_Sub_Status_Home_Orientation_Sent;
        handover.Unit_is_Ready__c = True;
        handover.Is_Orientation_Letter_Sent__c = true;
        handover.OwnerId = crmUser.Id;
        handover.UnitCategory__c = 'Resale Unit';
        Update handover;
        
        System.runAs(crmUser){
            handover.Customer_Availability_for_CHO__c = HandoverConstants.Customer_Not_Available;
            update handover;
            
            
            handover.Customer_Availability_for_CHO__c = HandoverConstants.Customer_Available;
            handover.Is_Notice_of_Completion_Sent__c = false;
            handover.HO_Agent_Assigned_User__c = hoAgent.Id;
            //handover.OwnerId = hoAgent.Id;
            update handover;
            
            Event e = new Event();
            e.Subject = 'Meeting';
            e.DurationInMinutes = 20;
            e.ActivityDateTime = DateTime.now();
            e.WhatId = handover.Id;
            insert e;
              try {
             handover.Notice_of_Completion_Date__c = system.today();
             handover.Is_Notice_of_Completion_Sent__c=false;
             handover.Sub_Status__c ='Send Handover Notice';
                update handover;
            } catch (Exception ex) {
        }
            
              handover.Notice_of_Completion_Date__c = system.today();
             handover.Is_Notice_of_Completion_Sent__c=true;
            handover.Sub_Status__c ='Send Handover Notice';
            update handover;
        }
             User user = [SELECT Id FROM User WHERE IsActive = true AND Profile.Name = 'System Administrator' LIMIT 1];
            handover.Sub_Status__c = 'Potential Defaulter';
             update handover;
             System.runAs(user){
            handover.Sub_Status__c = 'Notice of Completion sent';
            try {
                update handover;
            } catch (Exception e) {
            }
           
              
        }
    }
   /*   @isTest
    public static void paymentSettlement(){
        Handover__c handover = [Select ID,Name,Customer_Email__c,Is_Manual__c,Sub_Status__c,Sales_Order__c,unit__c,OwnerId from Handover__c WHERE Customer_Email__c ='test@gmail.com' LIMIT 1];
        User crmUser = [SELECT Id,Email from User where Email = 'crmUser@bloom.com' LIMIT 1];
        handover.OwnerId = crmUser.Id;
        update handover;
        
        List<Document__c> passportDoclist = [SELECT Id, Document_Name__c FROM Document__c WHERE Document_Name__c = 'Passport' AND Handover__c =: handover.Id LIMIT 1];
        List<Document__c> EmirateIddoclist = [SELECT Id, Document_Name__c FROM Document__c WHERE Document_Name__c = 'Emirates Id' AND Handover__c =: handover.Id LIMIT 1];
        System.runAs(crmUser){
        if(passportDoclist.size()>0){
            CustomDocManageController.addFilesonRecordCreate('base64Pdf', 'hello'+'pdf', passportDoclist[0]);
        }
        if(EmirateIddoclist.size()>0){
            CustomDocManageController.addFilesonRecordCreate('base64Pdf', 'hello'+'pdf', EmirateIddoclist[0]);
        }
         try {
        handover.Sub_Status__c = 'Payment Settled';
       
                update handover;
            } catch (Exception e) {
        }
    }
    }

    @isTest
    public static void MortgageReleaseInitiated(){
      
        Handover__c handover = [Select ID,Name,Customer_Email__c,Is_Manual__c,Sub_Status__c,Sales_Order__c,unit__c,OwnerId from Handover__c WHERE Customer_Email__c ='test@gmail.com' LIMIT 1];
         try{
          handover.Sub_Status__c = HandoverConstants.Mortgage_Release_Initiated;
        }catch(exception e){
             Update handover;
        }
       
        List<Document__c>bankNoc = [SELECT Id, Document_Name__c FROM Document__c WHERE Document_Name__c = 'Bank NOC' AND Handover__c =: handover.Id LIMIT 1];
        if(bankNoc.size()>0){
            CustomDocManageController.addFilesonRecordCreate('base64Pdf', 'hello'+'pdf', bankNoc[0]);
        } 
        User operationTeam = [SELECT Id,Email from User where Email = 'operationUser@bloom.com' LIMIT 1];
        User governmentUser = [SELECT Id,Email from User where Email = 'governmentUser@bloom.com' LIMIT 1];
        handover.OwnerId = governmentUser.Id;
        handover.Sub_Status__c = HandoverConstants.Mortgage_Release_Initiated;
        Update handover;
    }
    
    @isTest
    public static void MortgageReleaseDocumentUploaded(){
        Handover__c handover = [Select ID,Name,Customer_Email__c,Is_Manual__c,Sub_Status__c,Sales_Order__c,unit__c,OwnerId from Handover__c WHERE Customer_Email__c ='test@gmail.com' LIMIT 1];
          try{
          handover.Sub_Status__c =  HandoverConstants.Mortgage_Release_Document_Uploaded;
        }catch(exception e){
             Update handover;
        }
       
        List<Document__c>titleDeed = [SELECT Id, Document_Name__c FROM Document__c WHERE Document_Name__c = 'Bloom Title Deed' AND Handover__c =: handover.Id LIMIT 1];
        if(titleDeed.size()>0){
            CustomDocManageController.addFilesonRecordCreate('base64Pdf', 'hello'+'pdf', titleDeed[0]);
        } 
        handover.Sub_Status__c = HandoverConstants.Mortgage_Release_Document_Uploaded;
        Update handover;
    }
    
    @isTest
    public static void MortgageReleaseCompleted(){
      
        Handover__c handover = [Select ID,Name,Customer_Email__c,Is_Manual__c,Sub_Status__c,Sales_Order__c,unit__c,OwnerId from Handover__c WHERE Customer_Email__c ='test@gmail.com' LIMIT 1];
          try{
          handover.Sub_Status__c =  HandoverConstants.Mortgage_Release_Completed;
        }catch(exception e){
             Update handover;
        }
        handover.Sub_Status__c = HandoverConstants.Mortgage_Release_Completed;
        handover.Payment_Type__c ='PHPP';
        Update handover;
        
    }
    
    @isTest
    public static void PHPPCompletionPending(){
        Handover__c handover = [Select ID,Name,Customer_Email__c,Is_Manual__c,Sub_Status__c,Sales_Order__c,unit__c,OwnerId from Handover__c WHERE Customer_Email__c ='test@gmail.com' LIMIT 1];
        handover.Sub_Status__c = HandoverConstants.PHPP_Completion_Pending;
        handover.Payment_Type__c = HandoverConstants.Handover_Payment_Type_PHPP;
        Update handover;
    }
    
    @isTest
    public static void titleDeedRegistrationCompleted(){
        User governmentUser = [SELECT Id,Email from User where Email = 'governmentUser@bloom.com' LIMIT 1];
        User crmUser = [SELECT Id,Email from User where Email = 'crmUser@bloom.com' LIMIT 1];
        Handover__c handover = [Select ID,Name,Customer_Email__c,Is_Manual__c,Sub_Status__c,Sales_Order__c,unit__c,OwnerId from Handover__c WHERE Customer_Email__c ='test@gmail.com' LIMIT 1];
         
        User financeUser = [SELECT Id,Email from User where Email = 'financeUser@bloom.com' LIMIT 1];
        Group testQueue = new Group();
        testQueue.Name = 'Handover Finance Queue'; 
        testQueue.Type = 'Queue';
        insert testQueue;
        User user = [SELECT Id FROM User WHERE IsActive = true AND Profile.Name = 'System Administrator' LIMIT 1];
        System.runAs(user){
            GroupMember queueMember1 = new GroupMember();
            queueMember1.GroupId = testQueue.Id;
            queueMember1.UserOrGroupId = financeUser.Id;
            insert queueMember1;
        }
        List<Document__c> handoverPaymentattch = [SELECT Id, Document_Name__c FROM Document__c WHERE Document_Name__c = 'Handover Payment Attachment' AND Handover__c =: handover.Id LIMIT 1];
        if(handoverPaymentattch.size()>0){
            CustomDocManageController.addFilesonRecordCreate('base64Pdf', 'hello'+'pdf', handoverPaymentattch[0]);
        }  
        handover.Sub_Status__c = HandoverConstants.Handover_Sub_Status_Finance_Verified;
        handover.Payment_Settled__c = false;
        handover.Collection_of_PDC_s__c = true;
        handover.Collection_Till_Handover__c = true;
        handover.Collection_Till_Handover_Amount__c = 12;
        handover.Collection_on_H_O__c = true;
        handover.Collection_on_H_O_Amount__c = 1;
        handover.Collection_of_PDC_s__c = true;
        handover.Collection_of_PDC_s_Amount__c = 1;
        handover.Hassantuk_Fees__c = 1;
        handover.Title_Deed_Fee__c = 1;
        handover.Service_Charge_Collection_Amount__c = 1;
        handover.Service_Charge_Collection__c = true;
        handover.Payment_Type__c = 'Cash';
        handover.Other_Charges_Checkbox__c = true;
        handover.Other_Charges_Amount__c = 1;
        handover.Other_Charges_Description__c = 'Test';
        handover.Payment_Cleared__c = true;
        handover.Payment_Settled__c = true;
        handover.Service_charge_clearance__c =1;
        handover.Post_HO_PDCs_Collection__c = 1;
        handover.Admin_fees__c = 1;
        handover.Late_payment_fees__c=1;
        handover.Bounced_chqs_fees__c=1;
        handover.Payment_Date__c = Date.today();
        handover.OwnerId = governmentUser.id;
        update handover;
        System.runAs(governmentUser){
            handover.Sub_Status__c = HandoverConstants.Handover_Sub_Status_Title_Deed_Registration_Completed;
            try {
                update handover;
            } catch (Exception e) {
            }
            List<Document__c> TitleDeedDocList = [SELECT Id, Document_Name__c FROM Document__c WHERE Document_Name__c = 'Title Deed' AND Handover__c =: handover.Id LIMIT 1];
            if(TitleDeedDocList.size()>0){
                CustomDocManageController.addFilesonRecordCreate('base64Pdf', 'hello'+'pdf', TitleDeedDocList[0]);
            }           
        }
        //System.assertEquals(HandoverConstants.Handover_Sub_Status_Title_Deed_Registration_Completed, handover.Sub_Status__c);
    }

    @isTest
    public static void propertyRegistrationValidation(){
        User crmUser = [SELECT Id,Email from User where Email = 'crmUser@bloom.com' LIMIT 1];
        
        Handover__c handover = [Select ID,Name,Customer_Email__c,Is_Manual__c,Sub_Status__c,Sales_Order__c,unit__c,OwnerId from Handover__c WHERE Customer_Email__c ='test@gmail.com' LIMIT 1];
        List<Document__c> handoverPaymentattch = [SELECT Id, Document_Name__c FROM Document__c WHERE Document_Name__c = 'Handover Payment Attachment' AND Handover__c =: handover.Id LIMIT 1];
        if(handoverPaymentattch.size()>0){
            CustomDocManageController.addFilesonRecordCreate('base64Pdf', 'hello'+'pdf', handoverPaymentattch[0]);
        }  
        handover.Sub_Status__c = HandoverConstants.Handover_Sub_Status_Finance_Verified;
        handover.Payment_Settled__c = false;
        handover.Collection_of_PDC_s__c = true;
        handover.Collection_Till_Handover__c = true;
        handover.Collection_Till_Handover_Amount__c = 12;
        
        handover.Collection_on_H_O__c = true;
        handover.Collection_on_H_O_Amount__c = 1;
        handover.Collection_of_PDC_s__c = true;
        handover.Collection_of_PDC_s_Amount__c = 1;
        handover.Hassantuk_Fees__c = 1;
        handover.Title_Deed_Fee__c = 1;
        handover.Service_Charge_Collection_Amount__c = 1;
        handover.Service_Charge_Collection__c = true;
        handover.Payment_Type__c = HandoverConstants.Handover_Payment_Type_PHPP;
        handover.Other_Charges_Checkbox__c = true;
        handover.Other_Charges_Amount__c = 1;
        handover.Other_Charges_Description__c = 'Test';
        handover.Payment_Cleared__c = true;
        handover.Payment_Settled__c = true;
        handover.Service_charge_clearance__c =1;
        handover.Post_HO_PDCs_Collection__c = 1;
        handover.Admin_fees__c = 1;
        handover.Late_payment_fees__c=1;
        handover.Bounced_chqs_fees__c=1;
        handover.Payment_Date__c = Date.today();
        update handover;
        handover.Sub_Status__c = HandoverConstants.Handover_Sub_Status_Property_Registration_Completed;
        try {
            update handover;
        } catch (Exception e) {
        }    
    }
    
    @isTest
    public static void mortgageChequeClearanceValidation(){
        User crmUser = [SELECT Id,Email from User where Email = 'crmUser@bloom.com' LIMIT 1];
        Handover__c handover = [Select ID,Name,Customer_Email__c,Is_Manual__c,Sub_Status__c,Sales_Order__c,unit__c,OwnerId from Handover__c WHERE Customer_Email__c ='test@gmail.com' LIMIT 1];
        handover.Payment_Type__c = 'Mortgage';
        update handover;
        handover.Sub_Status__c = HandoverConstants.Handover_Status_Mortgage_Cheque_Clearance;
        try {
            update handover;
        } catch (Exception e) {
        }
        
    }
    
    @isTest
    public static void pHPPKHOAppointmentvalidation(){
        User crmUser = [SELECT Id,Email from User where Email = 'crmUser@bloom.com' LIMIT 1];
        Handover__c handover = [Select ID,Name,Customer_Email__c,Is_Manual__c,Sub_Status__c,Sales_Order__c,unit__c,OwnerId from Handover__c WHERE Customer_Email__c ='test@gmail.com' LIMIT 1];
        handover.Payment_Type__c = HandoverConstants.Handover_Payment_Type_PHPP;
        update handover;
        handover.Sub_Status__c = HandoverConstants.Handover_Sub_Status_PHPP_KHO_Appointment_Scheduled;
        try {
            update handover;
        } catch (Exception e) {
        }    
    }
    
    @isTest
    public static void leaseAgreement(){
        User crmUser = [SELECT Id,Email from User where Email = 'crmUser@bloom.com' LIMIT 1];
        Handover__c handover = [Select ID,Name,Customer_Email__c,Is_Manual__c,Sub_Status__c,Sales_Order__c,unit__c,OwnerId from Handover__c WHERE Customer_Email__c ='test@gmail.com' LIMIT 1];
        handover.Payment_Type__c = HandoverConstants.Handover_Payment_Type_PHPP;
        update handover;
        handover.Sub_Status__c = HandoverConstants.Handover_Sub_Status_Lease_Agreement;
        try {
            update handover;
        } catch (Exception e) {
        }    
    }
    
    @isTest
    public static void khoAppointmentBooked(){
        User crmUser = [SELECT Id,Email from User where Email = 'crmUser@bloom.com' LIMIT 1];
        Handover__c handover = [Select ID,Name,Customer_Email__c,Is_Manual__c,Sub_Status__c,Sales_Order__c,unit__c,OwnerId from Handover__c WHERE Customer_Email__c ='test@gmail.com' LIMIT 1];
        handover.Sub_Status__c = HandoverConstants.Handover_Status_Utilities_Transfer_Completed;
        List<Document__c> ADDCNOClist = [SELECT Id, Document_Name__c FROM Document__c WHERE Document_Name__c = 'ADDC NOC' AND Handover__c =: handover.Id LIMIT 1];
        if(ADDCNOClist.size()>0){
            CustomDocManageController.addFilesonRecordCreate('base64Pdf', 'hello'+'pdf', ADDCNOClist[0]);
        }  
        List<Document__c>leasingDoc = [SELECT Id, Document_Name__c FROM Document__c WHERE Document_Name__c = 'Leasing ADDC NOC' AND Handover__c =: handover.Id LIMIT 1];
        if(leasingDoc.size()>0){
            CustomDocManageController.addFilesonRecordCreate('base64Pdf', 'hello'+'pdf', leasingDoc[0]);
        } 
        handover.Is_Notice_of_Completion_Sent__c = true;
        handover.Payment_Type__c = 'Cash';
        
        handover.Payment_Date__c = date.today();
        handover.Payment_Settled__c = true;
        handover.OwnerId = crmUser.Id;
        update handover;
        System.runAs(crmUser){
            handover.Sub_Status__c = HandoverConstants.Handover_Sub_Status_KHO_Appointment_Scheduled;
            try {
                update handover;
            } catch (Exception e) {
            }
            Event e = new Event();
            e.Subject = 'Meeting';
            e.DurationInMinutes = 20;
            e.ActivityDateTime = DateTime.now();
            e.WhatId = handover.Id;
            insert e;
        }
        System.assertEquals(HandoverConstants.Handover_Sub_Status_KHO_Appointment_Scheduled, handover.Sub_Status__c);
        System.assertEquals(crmUser.Id, handover.OwnerId);
    }
    
    @isTest
    public static void phppKHOAppointmentScheduled(){
        User crmUser = [SELECT Id,Email from User where Email = 'crmUser@bloom.com' LIMIT 1];
        Handover__c handover = [Select ID,Name,Customer_Email__c,Payment_Type__c,Customer_Availability_for_CHO__c,Is_Manual__c,Sub_Status__c,Sales_Order__c,unit__c,OwnerId from Handover__c WHERE Customer_Email__c ='test@gmail.com' LIMIT 1];
        handover.OwnerId = crmUser.Id;
        handover.Sub_Status__c = HandoverConstants.Handover_Sub_Status_Finance_Verified;
        handover.Is_Notice_of_Completion_Sent__c = true;
        handover.Payment_Settled__c = false;
        handover.Collection_of_PDC_s__c = true;
        handover.Collection_Till_Handover__c = true;
        handover.Collection_Till_Handover_Amount__c = 12;
        handover.Collection_on_H_O__c = true;
        handover.Collection_on_H_O_Amount__c = 1;
        handover.Collection_of_PDC_s__c = true;
        handover.Collection_of_PDC_s_Amount__c = 1;
        handover.Hassantuk_Fees__c = 1;
        handover.Title_Deed_Fee__c = 1;
        handover.Service_Charge_Collection_Amount__c = 1;
        handover.Service_Charge_Collection__c = true;
        handover.Payment_Type__c = 'Cash';
        handover.Other_Charges_Checkbox__c = true;
        handover.Other_Charges_Amount__c = 1;
        handover.Other_Charges_Description__c = 'Test';
        handover.Payment_Cleared__c = true;
        handover.Payment_Type__c = HandoverConstants.Handover_Payment_Type_PHPP;
        //update handover;
        System.runAs(crmUser){
            test.startTest();
            handover.Sub_Status__c = HandoverConstants.Handover_Sub_Status_PHPP_KHO_Appointment_Scheduled;
            try {
                // update handover;
            } catch (Exception e) {
            }
            
            Event e = new Event();
            e.Subject = 'Meeting';
            e.DurationInMinutes = 20;
            e.ActivityDateTime = DateTime.now();
            e.WhatId = handover.Id;
            // insert e;
            test.stopTest();
            
        }
        // System.assertEquals(HandoverConstants.Handover_Sub_Status_PHPP_KHO_Appointment_Scheduled, handover.Sub_Status__c);
    }
    
    @isTest
    public static void updateStatusSlacreation(){
        User hoAgent = [SELECT Id,Email from User where Email = 'hoagent@bloom.com' LIMIT 1];
        Handover__c handover = [Select ID,Name,Customer_Email__c,Is_Manual__c,Sub_Status__c,Sales_Order__c,unit__c,OwnerId from Handover__c WHERE Customer_Email__c ='test@gmail.com' LIMIT 1];
        List<Document__c> CHODesnagging = [SELECT Id, Document_Name__c FROM Document__c WHERE Document_Name__c = 'CHO Desnagging Report' AND Handover__c =: handover.Id LIMIT 1];
        if(CHODesnagging.size()>0){
            CustomDocManageController.addFilesonRecordCreate('base64Pdf', 'hello'+'pdf', CHODesnagging[0]);
        }  
        User crmUser = [SELECT Id,Email from User where Email = 'crmUser@bloom.com' LIMIT 1];
        handover.OwnerId = hoAgent.Id;
        handover.Sub_Status__c ='CHO De-Snagging Completed';
        handover.Is_Notice_of_Completion_Sent__c =true;
        Update handover;   
    }*/
}