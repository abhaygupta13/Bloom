@isTest
public class CaseAssignmentHistoryServiceTest {

    @testSetup
    static void setupTestData() {
        
        Round_Robins__c rr=new Round_Robins__c(
            Name='Service/Case Request',
            Assigned_To__c = String.valueof(1),
            Sobject__c='Case'
        );
        insert rr;
        
        Round_Robins__c Reseller=new Round_Robins__c(
            Name='Service/Resale Case Request',
            Assigned_To__c = String.valueof(1),
            Sobject__c='Case'
            
        );
        insert Reseller;
        
        Profile profileDetail = [SELECT Id FROM Profile WHERE Name='CRM Operations'];
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueOf(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '');
        Integer randomInt = Integer.valueOf(Math.rint(Math.random() * 1000000));
        String uniqueName = orgId + dateString + randomInt;
        
        User userRecord = new User(Alias = 'Zaki', Email='Zakial@gmail.com', 
                                   EmailEncodingKey='UTF-8', LastName='Zaki Al Bakri', LanguageLocaleKey='en_US', 
                                   LocaleSidKey='en_US', ProfileId = profileDetail.id, 
                                   TimeZoneSidKey='Asia/Dubai', UserName= uniqueName+'@mail.com');
        insert userRecord;
        User userRecord2 = new User(Alias = 'Zaki2', Email='Zakial2@gmail.com', 
                                    EmailEncodingKey='UTF-8', LastName='Zaki A2l Bakri', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = profileDetail.id, 
                                    TimeZoneSidKey='Asia/Dubai', UserName= uniqueName+'3232'+'@mail.com');
        insert userRecord2;
        
        User userRecord3 = new User(Alias = 'Zaki3', Email='Zakial3@gmail.com', 
                                    EmailEncodingKey='UTF-8', LastName='Zaki A2l Bakri', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = profileDetail.id, 
                                    TimeZoneSidKey='Asia/Dubai', UserName= uniqueName+'3432'+'@mail.com');
        insert userRecord3;
        
        Round_Robin_User__c rrUser=new Round_Robin_User__c(
            Name='Hani Zaki Al Bakri -  SM',
            Round_Robin__c=rr.Id,
            Total_Open_Count__c=0,
            User__c=userRecord.id
            
        );
        insert rrUser;
        
        Round_Robin_User__c rrUser1=new Round_Robin_User__c(
            Name='Zaki Al Bakri -  SM',
            Round_Robin__c=rr.Id,
            Total_Open_Count__c=10,
            User__c=userRecord2.id
        );
        insert rrUser1;
        
        Round_Robin_User__c rrUser2=new Round_Robin_User__c(
            Name='Zaki Al Bakri -  SM',
            Round_Robin__c=Reseller.Id,
            Total_Open_Count__c=10,
            User__c=userRecord3.id
            
        );
        insert rrUser2;
        
        User testUser = new User(
            Alias = 'testUsr',
            Email = 'testuser@mail.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profileDetail.Id,
            TimeZoneSidKey = 'Asia/Dubai',
            UserName = uniqueName + '@test.com'
        );
        insert testUser;
        
        Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Post_Sale_Payment_Deferral').getRecordTypeId();
        system.debug('This is recordType Id :'+caseRecordTypeId);
        
        Account testAccount = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId(),
            LastName = 'Test Account',
            PersonEmail = 'testaccount@test.com'
        );
        insert testAccount;
        
        // Create Contact with Email
        Contact testContact = new Contact(
            LastName = 'Test Contact',
            Email = 'sonali.sengar@infobeans.com'
        );
        insert testContact;
        
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'New',
            CloseDate = System.today(),
            LeadChannel__c = 'Walk in',
            AccountId = testAccount.Id,
            WinReason__c = 'Loyalty'
        );
        insert testOpportunity;
        
        Project__c testProject=new Project__c(
            Name='Test Project'
        );
        insert testProject;
        
        OffersPromotions__c testOfferPromotion = new OffersPromotions__c(
            OfferName__c = 'Almeria Normal ADM Included 2%',  // Required Field - Offer Name
            StartDate__c = Date.today(),       // Required Field - Start Date
            EndDate__c = Date.today().addDays(30),  // Required Field - End Date
            Project__c = testProject.Id  // Replace with a valid Project ID
        );
        insert testOfferPromotion;
        
        BuildingSection__c testBuilding=new BuildingSection__c(
            Name='Test Building',
            BuildingSectionCode__c='BL-CAS',
            Project__c=testProject.Id
            
        );
        insert testBuilding;
        
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
            StartDate__c=date.today()-10
            
        );
        insert testUnit;
        
        PaymentPlan__c  pp = new PaymentPlan__c();
        pp.Name ='July Plan';
        pp.Unit__c= testUnit.id;
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
        
        SalesOrder__c testSalesOrder = new SalesOrder__c(
            Name = 'Test Sales Order',
            Status__c = 'Booked',
            //Offer__c = testOfferPromotion.Id,
            Account__c = testAccount.Id,
            //Sales_Order_Number__c = '125236',
            Unit__c = testUnit.Id,
            Opportunity__c = testOpportunity.Id
        );
        insert testSalesOrder;
        
        SalesOrder__c testSalesOrder1 = new SalesOrder__c(
            Name = 'Test Sales Order1',
            Status__c = 'Sold',
            //Offer__c = testOfferPromotion.Id,
            Account__c = testAccount.Id,
            //Sales_Order_Number__c = '125236',
            Unit__c = testUnit.Id,
            Opportunity__c = testOpportunity.Id
        );
        insert testSalesOrder1;
        
        InstallmentLines__c installmentLines = new InstallmentLines__c();
        installmentLines.PaymentPlan__c = pp.id;
        installmentLines.PaymentInstallments__c =ppi.Id;
        installmentLines.SalesOrder__c = testSalesOrder1.id;
        installmentLines.Description__c='4th Installment';
        installmentLines.InstallmentAmount__c = 100000;
        installmentLines.LPCCutOffAmt__c =0;
        installmentLines.MinInvAmtrem__c =100;
        installmentLines.LPCRate__c =12;
        installmentLines.InstallmentPercentage__c = 25;
        installmentLines.BrokerPayoutPercentage__c = 20;
        installmentLines.Description__c = 'Description';
        installmentLines.RevisedDate__c=null;
        installmentLines.GracePeriod__c=1;
        installmentLines.InstallmentAmount__c =70000;
        installmentLines.Inst_inc_tax_in_words__c  = '';
        installmentLines.InstallmentDate__c= Date.today() - 12;
        installmentLines.AmountReceived__c=1500;
        installmentLines.CutOffDate__c=date.today();
        installmentLines.LPCAmount__c=500;
        //installmentLines.Name = 'Test Installment';
        //installmentLines.NewInstallmentDate__c = System.today();
        
        insert installmentLines;
        
        SalesOrder__c testSalesOrder2 = new SalesOrder__c(
            Name = 'Test Sales Order2',
            Status__c = 'Sold',
            Offer__c = testOfferPromotion.Id,
            Account__c = testAccount.Id,
            Opportunity__c = testOpportunity.Id
        );
        insert testSalesOrder2;
        
        // Create a Service Catalog
        ServiceCatalog__c testServiceCatalog = new ServiceCatalog__c(Name = 'Test Service', RecordTypeDevName__c = 'Post_Sale_Payment_Deferral'
                                                                     /*Category__c = 'BFM Service', SubCategory__c = 'Post Sale Payment Deferral'*/);
        insert testServiceCatalog;
        
        Case testCase = new Case(
            CurrencyIsoCode = 'AED',
            Origin = 'Email',
            OwnerId = testUser.Id,
            RecordTypeId = caseRecordTypeId,
            Sales_Order__c = testSalesOrder1.Id,
            ServiceCatalog__c = testServiceCatalog.Id,
            Case_Contact_Name__c = testContact.Id,
            ContactId = testContact.Id
        );
        insert testCase;
        
        Case testCase1 = new Case(
            CurrencyIsoCode = 'AED',
            Origin = 'Email',
            OwnerId = testUser.Id,
            RecordTypeId = caseRecordTypeId,
            Sales_Order__c = testSalesOrder1.Id,
            ServiceCatalog__c = testServiceCatalog.Id,
            Step__c = String.valueOf(1),
            PaymentDeferralReason__c = 'Changing date with replacing the cheque'
        );
        insert testCase1;
        
        Case testCase2 = new Case(
            CurrencyIsoCode = 'AED',
            Origin = 'Email',
            OwnerId = testUser.Id,
            RecordTypeId = caseRecordTypeId,
            Sales_Order__c = testSalesOrder1.Id,
            ServiceCatalog__c = testServiceCatalog.Id,
            Step__c = String.valueOf(2),
            Deferral_Within_1_Month__c = 'Yes',
            ChequeScanned__c =  'Yes' ,
            Deferral_Fee_Paid__c = 'Yes'
        );
        insert testCase2;
        
        Case testCase3 = new Case(
            CurrencyIsoCode = 'AED',
            Origin = 'Email',
            OwnerId = testUser.Id,
            RecordTypeId = caseRecordTypeId,
            Sales_Order__c = testSalesOrder1.Id,
            ServiceCatalog__c = testServiceCatalog.Id,
            Step__c = String.valueOf(2),
            Deferral_Within_1_Month__c = 'No',
            ChequeScanned__c =  'No' ,
            Deferral_Fee_Paid__c = 'No',
            DeferralApprovalStatus__c = 'Rejected',
            ContactId = testContact.Id
            //ContactEmail = testSalesOrder1.
        );
        insert testCase3;
        
        InstallmentLines__c installmentLines1 = [SELECT Id, Name FROM InstallmentLines__c LIMIT 1];
        
        CaseInstallment__c caseInstallment = new CaseInstallment__c(/*Name = installmentLines1.Name,*/
                                                                    Case__c = testCase3.Id,
                                                                    OwnerId = testUser.Id,
                                                                    NewInstallmentDate__c = system.today());
        
        insert caseInstallment;
        
        List<CaseAssignmentHistory__c> caseAssignHistoryToLog = new  List<CaseAssignmentHistory__c>();
        
        CaseAssignmentHistory__c historyObj = new CaseAssignmentHistory__c();
                historyObj.Case__c = testCase3.id;
                historyObj.AssignedBy__c = testCase3.OwnerId;
                historyObj.AssignedTo__c = testUser.Id;
                historyObj.AssignmentDate__c = system.today();
                historyObj.Description__c = 'CommentBody';
                historyObj.Reason__c = 'TPF Required';
                caseAssignHistoryToLog.add(historyObj); 
        
        insert caseAssignHistoryToLog;
    }

    @isTest
    static void testInsertCaseAssignmentHistory() {
        // Get singleton instance
        CaseAssignmentHistoryService service = CaseAssignmentHistoryService.getInstance();

        // Create dummy assignment history records
        List<CaseAssignmentHistory__c> caseAssHistList = [Select Id, Case__c, AssignedBy__c,AssignedTo__c,AssignmentDate__c,
                                                          Description__c,Reason__c from CaseAssignmentHistory__c];
        
        CaseAssignmentHistory__c caseAssHist = new CaseAssignmentHistory__c(Case__c = caseAssHistList[0].Case__c,
                                                                    AssignedBy__c = caseAssHistList[0].AssignedBy__c,
                                                                    AssignedTo__c = caseAssHistList[0].AssignedTo__c,
                                                                    Description__c = 'Test Description',
                                                                    Reason__c = caseAssHistList[0].Reason__c,
                                                                    AssignmentDate__c = System.today());
        List<CaseAssignmentHistory__c> caseAssHistList1 = New List<CaseAssignmentHistory__c>();
        caseAssHistList1.add(caseAssHist);

        Test.startTest();
        List<CaseAssignmentHistory__c> insertedList = service.insertCaseAssignmentHistory(caseAssHistList1);
        Test.stopTest();

        System.assertEquals(1, insertedList.size(), 'Two assignment history records should be inserted');
        System.assertNotEquals(null, insertedList[0].Id, 'Inserted records should have Ids');
    }

    @isTest
    static void testUpdateCaseAssignmentHistory() {
        // First insert some records to update
        List<CaseAssignmentHistory__c> caseAssHistList2 = [Select Id, Case__c, AssignedBy__c,AssignedTo__c,AssignmentDate__c,
                                                          Description__c,Reason__c from CaseAssignmentHistory__c];

        // Update some fields
        for (CaseAssignmentHistory__c hist : caseAssHistList2) {
            hist.AssignmentDate__c = System.today()+1;
        }

        // Get singleton instance
        CaseAssignmentHistoryService service = CaseAssignmentHistoryService.getInstance();

        Test.startTest();
        List<CaseAssignmentHistory__c> updatedList = service.updateCaseAssignmentHistory(caseAssHistList2);
        Test.stopTest();

        System.assertEquals(1, updatedList.size(), 'One assignment history records should be updated');
        //System.assert(updatedList[0].Name.contains('Updated'), 'Updated name should reflect change');
        System.assertEquals(System.today().addDays(1), updatedList[0].AssignmentDate__c, 'Date should be updated to today + 1');
    }

    @isTest
    static void testInsertWithEmptyList() {
        CaseAssignmentHistoryService service = CaseAssignmentHistoryService.getInstance();
        List<CaseAssignmentHistory__c> emptyList = new List<CaseAssignmentHistory__c>();

        List<CaseAssignmentHistory__c> result = service.insertCaseAssignmentHistory(emptyList);
        System.assertEquals(0, result.size(), 'Empty input list should return an empty result');
    }

    @isTest
    static void testUpdateWithNullList() {
        CaseAssignmentHistoryService service = CaseAssignmentHistoryService.getInstance();
        List<CaseAssignmentHistory__c> result = service.updateCaseAssignmentHistory(null);
        System.assertEquals(null, result, 'Null input list should return null');
    }
}