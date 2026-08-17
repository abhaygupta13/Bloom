@istest
public class AssignmentRuleHandlerTest {
    @TestSetup
    static void testMethod1() {
        // Test for New status
        List<Lead> Llist = new List<Lead>();
        Lead l = new lead();
        l.LastName = 'Testclass';
        l.MobileCountryCode__c = '971';
        l.Status = 'New';
        l.MobilePhone = '37829292020';
        l.Email = 'Testclass@gmail.com';
        l.LeadTeam__c = 'Leasing';
        l.Project__c = 'Bloom Living';
        // l.Lead_Channel__c = 'Online'; 
        Llist.add(l);
        insert Llist;
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        User contactCenterUser = [SELECT Id FROM User WHERE Profile.Name = 'Contact Centre Team' AND IsActive = true LIMIT 1];
        AssignmentRule__c assr = new AssignmentRule__c();
        assr.RecordType__c = 'Lead';
        assr.ProcessName__c = 'Digital Lead Assignment';
        assr.ProcessType__c = 'Sales';
        assr.IsActive__c = true;
        insert assr;
        
        AssignmentRule__c assr1 = new AssignmentRule__c();
        assr1.RecordType__c = 'Case';
        assr1.ProcessName__c = 'Digital Case Assignment';
        assr1.ProcessType__c = 'Sales';
        assr1.IsActive__c = true;
        insert assr1;
        
        AssignmentRule__c assr2 = new AssignmentRule__c();
        assr2.RecordType__c = 'Lead';
        assr2.ProcessName__c = 'Qualified Lead Assignment';
        assr2.IsActive__c = true; 
        assr2.ProcessType__c = 'Sales';
        insert assr2;
        
        AssignmentRule__c assr3 = new AssignmentRule__c();
        assr3.RecordType__c = 'Case';
        assr3.ProcessName__c = 'General Complaint Case Assignment';
        assr3.IsActive__c = true; 
        assr3.ProcessType__c = 'Sales';
        insert assr3;
        
        AssignmentRule__c assr4 = new AssignmentRule__c();
        assr4.RecordType__c = 'Case';
        assr4.ProcessName__c = 'CRM Case Assignment';
        assr4.IsActive__c = true; 
        assr4.ProcessType__c = 'Sales';
        assr4.Project__c = 'Al Dhay';
        insert assr4;

         
        AssignmentRule__c assr41 = new AssignmentRule__c();
        assr41.RecordType__c = 'Case';
        assr41.ProcessName__c = 'CRM Case Assignment';
        assr41.IsActive__c = true; 
        assr41.ProcessType__c = 'Sales';
        insert assr41;

        AssignmentRule__c assr7 = new AssignmentRule__c();
        assr7.RecordType__c = 'Lead';
        assr7.ProcessName__c = 'ADHA Lead Assignment';
        assr7.IsActive__c = true; 
        assr7.ProcessType__c = 'Sales';
        insert assr7;
        
        List<BusinessHours> bhs=[select id from BusinessHours where isActive = true];
        
        
        AssignmentUser__c assru = new AssignmentUser__c();
        assru.IsActive__c = true;
        assru.AssignmentRule__c = assr.id;
        assru.User__c = adminUser.id;
        assru.BusinessHours__c = bhs[0].id;
        insert assru;
        
        AssignmentUser__c assru1 = new AssignmentUser__c();
        assru1.IsActive__c = true;
        assru1.AssignmentRule__c = assr1.id;
        assru.BusinessHours__c = bhs[0].id;
        assru1.User__c = adminUser.id;
        insert assru1;
        
        AssignmentUser__c assru2 = new AssignmentUser__c();
        assru2.IsActive__c = true;
        assru2.AssignmentRule__c = assr2.id;
        assru2.BusinessHours__c = bhs[0].id;
        assru2.User__c = adminUser.id;
        insert assru2;
        
        
        AssignmentRule__c assr5 = new AssignmentRule__c();
        assr5.RecordType__c = 'Lead';
        assr5.ProcessName__c = 'Digital Leasing Lead Assignment';
        assr5.ProcessType__c = 'Leasing';
        assr5.IsActive__c = true;
        insert assr5;

        AssignmentRule__c assr6 = new AssignmentRule__c();
        assr6.RecordType__c = 'Case';
        assr6.ProcessName__c = 'BFM Email To Case Assignment';
        assr6.IsActive__c = true;
        insert assr6;

        AssignmentRule__c assrSuperApp = new AssignmentRule__c();
        assrSuperApp.RecordType__c = 'Case';
        assrSuperApp.ProcessName__c = 'Super App Registration Case Assignment';
        assrSuperApp.ProcessType__c = 'Sales';
        assrSuperApp.IsActive__c = true;
        insert assrSuperApp;


        AssignmentRule__c handoverRule = new AssignmentRule__c();
        handoverRule.RecordType__c = 'Handover';
        handoverRule.ProcessName__c = 'Handover CRM Agent Assignment';
        handoverRule.ProcessType__c = 'Handover';
        handoverRule.IsActive__c = true;
        handoverRule.Project__c = 'Al Dhay';
        insert handoverRule;

        AssignmentRule__c anprAssignmentRule = new AssignmentRule__c();
        anprAssignmentRule.RecordType__c = 'Case';
        anprAssignmentRule.ProcessType__c = 'Community Management';
        anprAssignmentRule.ProcessName__c = 'ANPR Service Request Assignment';
        anprAssignmentRule.IsActive__c = true;
        anprAssignmentRule.Project__c = 'Al Dhay';
        insert anprAssignmentRule;


        AssignmentRule__c communityAppServiceReqAssignmentRule = new AssignmentRule__c();
        communityAppServiceReqAssignmentRule.RecordType__c = 'Case';
        communityAppServiceReqAssignmentRule.ProcessType__c = 'Community Management';
        communityAppServiceReqAssignmentRule.ProcessName__c = 'Community App Service Request Assignment';
        communityAppServiceReqAssignmentRule.IsActive__c = true;
        communityAppServiceReqAssignmentRule.Project__c = 'Al Dhay';
        insert communityAppServiceReqAssignmentRule;
        
        AssignmentUser__c assru3 = new AssignmentUser__c();
        assru3.IsActive__c = true;
        assru3.AssignmentRule__c = assr3.id;
        assru3.BusinessHours__c = bhs[0].id;
        assru3.User__c = contactCenterUser.id;
        insert assru3;

        AssignmentUser__c assru4 = new AssignmentUser__c();
        assru4.IsActive__c = true;
        assru4.AssignmentRule__c = assr6.id;
        assru4.BusinessHours__c = bhs[0].id;
        assru4.User__c = adminUser.id;
        insert assru4;

        AssignmentUser__c assru5 = new AssignmentUser__c();
        assru5.IsActive__c = true;
        assru5.AssignmentRule__c = assr4.id;
        assru5.BusinessHours__c = bhs[0].id;
        assru5.User__c = contactCenterUser.id;
        insert assru5;

        AssignmentUser__c assruLeasingComm = new AssignmentUser__c();
        assruLeasingComm.IsActive__c = true;
        assruLeasingComm.AssignmentRule__c = assr5.id;
        assruLeasingComm.BusinessHours__c = bhs[0].id;
        assruLeasingComm.User__c = contactCenterUser.id;
        insert assruLeasingComm;

        AssignmentUser__c assruCRM2 = new AssignmentUser__c();
        assruCRM2.IsActive__c = true;
        assruCRM2.AssignmentRule__c = assr41.id;
        assruCRM2.BusinessHours__c = bhs[0].id;
        assruCRM2.User__c = contactCenterUser.id;
        insert assruCRM2;

        AssignmentUser__c assruHandover = new AssignmentUser__c();
        assruHandover.IsActive__c = true;
        assruHandover.AssignmentRule__c = handoverRule.id;
        assruHandover.BusinessHours__c = bhs[0].id;
        assruHandover.User__c = contactCenterUser.id;
        insert assruHandover;

        AssignmentUser__c assru6 = new AssignmentUser__c();
        assru6.IsActive__c = true;
        assru6.AssignmentRule__c = assr7.id;
        assru6.BusinessHours__c = bhs[0].id;
        assru6.User__c = contactCenterUser.id;
        insert assru6;

        AssignmentUser__c assruSuperAPP = new AssignmentUser__c();
        assruSuperAPP.IsActive__c = true;
        assruSuperAPP.AssignmentRule__c = assrSuperApp.id;
        assruSuperAPP.BusinessHours__c = bhs[0].id;
        assruSuperAPP.User__c = contactCenterUser.id;
        insert assruSuperAPP;
        
        AssignmentRule__c blcRule = new AssignmentRule__c();
        blcRule.RecordType__c = 'Case';
        blcRule.ProcessName__c = 'BLC Common Area SR Assignment';
        blcRule.IsActive__c = true;
        insert blcRule;
        
        AssignmentRule__c dlpRule = new AssignmentRule__c();
        dlpRule.RecordType__c = 'Case';
        dlpRule.ProcessName__c = 'DLP Common Area SR Assignment';
        dlpRule.IsActive__c = true;
        insert dlpRule;
        
        
        AssignmentUser__c blcUser = new AssignmentUser__c();
        blcUser.IsActive__c = true;
        blcUser.AssignmentRule__c = blcRule.Id;
        blcUser.BusinessHours__c = bhs[0].Id;
        blcUser.User__c = adminUser.Id;
        insert blcUser;
        
        AssignmentUser__c dlpUser = new AssignmentUser__c();
        dlpUser.IsActive__c = true;
        dlpUser.AssignmentRule__c = dlpRule.Id;
        dlpUser.BusinessHours__c = bhs[0].Id;
        dlpUser.User__c = adminUser.Id;
        insert dlpUser;
        
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
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
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
        
        Id personRecId =Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        
        Account Acc = new Account();
        Acc.LastName__pc = 'Test class Account';
        Acc.LastName = 'Test class Account';
        Acc.PersonEmail='aaa@abc.com';
        Acc.PersonMobilePhone='123456789';
        //Address or Mobile Numbe
        Acc.RecordTypeId = personRecId;
        insert Acc;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Test class name';
        opp.AccountId = Acc.id;
        opp.CloseDate = system.today();
        opp.StageName = 'New';
        opp.ForecastCategoryName = 'Omitted';
        opp.LeadChannel__c = 'Call';
        opp.WinReason__c = 'Won - Special Discount';
        insert opp;
        Project__c testProject=new Project__c(
            Name='Al Dhay'
        );
        insert testProject;
        
        
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
            SellingPrice__c= 700000
        );
        insert testUnit;
        
        SalesOrder__c testOrder = new SalesOrder__c(
            Name = 'Test Order',
            Status__c = 'Booked',
            // Contact__c=tempContact.id,
            Unit__c =testUnit.id,
            Account__c = Acc.Id,
            Opportunity__c=Opp.Id            
        );
        insert testOrder;
        
        
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Social Media').getRecordTypeId();
        
        Case tempCase=new Case(
            CurrencyIsoCode='AED',
            Status='Draft',
            Origin='Email',
            RequesterEmail__c ='abc@gmail.com',
            RequesterContactNumber__c= '353535353535',
            Main_Buyer_Share_Percentage__c=40,
            // Case_Sub_Status__c= 'Created', 
            RecordTypeId=RecordTypeCaseId        
        );

        Case caseObj = TestDataFactory.createCase('Move_In','Email',null,'test description','test subject',null,testUnit.Id,null);
        insert caseObj;
        
        insert tempCase;
        List<case> clist = new list<case>();
        clist.add(tempCase);
        Test.startTest();
        AssignmentRuleService objAssignmentRuleService = AssignmentRuleService.getInstance();
        objAssignmentRuleService.getAvailableAssignmentUsers(new List<AssignmentUser__c>{assru});
        objAssignmentRuleService.getAvailableAssignmentUsers(new List<AssignmentUser__c>{assru1});
        objAssignmentRuleService.getAvailableAssignmentUsers(new List<AssignmentUser__c>{assru2});
        objAssignmentRuleService.getAvailableAssignmentUserMap(new List<AssignmentUser__c>{assru2});

        
        AssignmentRuleHandler.salesDigitalLeadAssignment(new List<Id>{Llist[0].Id});
        AssignmentRuleHandler.salesDigitalQualifiedLeadAssignment(new List<Id>{Llist[0].Id});
        AssignmentRuleHandler.leasingLeadAssignment(new List<Id>{Llist[0].Id});
        AssignmentRuleHandler.leasingQualifiedLeadAssignment(new List<Id>{Llist[0].Id});
        AssignmentRuleHandler.salesLeadReshuffle(new Set<Id>{Llist[0].Id});
        AssignmentRuleHandler.qualifiedLeadAssignment(new List<Id>{Llist[0].Id});
        AssignmentRuleHandler.salesDigitalCaseAssignment(new List<Id>{tempCase.Id});
        LeadAssignmentBatch la = new LeadAssignmentBatch();
        la.execute(null);
        la.start(null); 
        la.execute(null, Llist); 
        la.finish(null);
        CaseAssignmentBatch ca = new CaseAssignmentBatch();
        ca.execute(null);
        ca.start(null);
        ca.execute(null,clist);
        ca.finish(null);
        Test.stopTest();
    }

    @IsTest
    private static void testBFMEmailToCaseCaseAssignment(){
        List<Case> caseList = [SELECT Id FROM Case LIMIT 1];
        Test.StartTest();
            AssignmentRuleHandler.bfmEmailToCaseCaseAssignment(new List<Id>{caseList[0].Id});
            AssignmentRule__c assingmentRule = [SELECT Id FROM AssignmentRule__c WHERE ProcessName__c = 'BFM Email To Case Assignment'];
            AssignmentUser__c assUser = [SELECT Id,User__c FROM AssignmentUser__c WHERE AssignmentRule__c =: assingmentRule.Id];
            List<Case> cases = [SELECT Id,OwnerId FROM Case LIMIT 1];
        Test.StopTest();
        Assert.areEqual(assUser.User__c, cases[0].OwnerId, 'Case owner should be same as user in assigment rule user');
    }

    @IsTest
    private static void testANPRCaseAssignment(){
        Test.StartTest();
            User user = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
            AssignmentRule__c assignRule = [SELECT Id FROM AssignmentRule__c WHERE ProcessType__c = 'Community Management' LIMIT 1];
            assignRule.DefaultUser__c = user.Id;
            update assignRule;
            Unit__c unit = [SELECT Id,Project__c FROM Unit__c LIMIT 1];
            Case caseObj = TestDataFactory.createCase('VehicleParkingRequest','Email',null,'test description','test subject',null,unit.Id,null);
        	caseObj.Project__c = unit.Project__c;
            insert caseObj;
            AssignmentRuleHandler.anprCaseAssignment(new List<Id>{caseObj.Id});
        Test.StopTest();
        Case caseOb = [SELECT Id, OwnerId, User__c FROM Case WHERE Id =: caseObj.Id LIMIT 1];
        Assert.areEqual(caseOb.OwnerId, assignRule.DefaultUser__c, 'Case owner should be same as user in assigment rule user');
    }

    @IsTest
    private static void testCommunityAppServiceRequestAssignment(){
        Test.StartTest();
            Case caseObj = [SELECT Id FROM Case WHERE RecordType.DeveloperName = 'Move_In' LIMIT 1];
            User user = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
            System.runAs(user) {
                Group queueObj = TestDataFactory.createGroup('Community Management Team', 'Queue');
                insert queueObj;
                QueueSobject qso = new QueueSobject(QueueId = queueObj.Id,SObjectType = 'Case');
                insert qso;
            }
            Group gp = [SELECT Id,Name FROM Group WHERE Type = 'Queue' AND Name = 'Community Management Team' LIMIT 1];
            AssignmentRule__c assignRule = [SELECT Id,DefaultQueueID__c FROM AssignmentRule__c WHERE ProcessType__c = 'Community Management' AND ProcessName__c = 'Community App Service Request Assignment' LIMIT 1];
            assignRule.DefaultQueueID__c = gp.Id;
            update assignRule;
            Unit__c unit = [SELECT Id,Project__c FROM Unit__c LIMIT 1];
            AssignmentRuleHandler.communityAppServiceRequestAssignment(new List<Id>{caseObj.Id});
        Test.StopTest();
        Case caseOb = [SELECT Id, OwnerId, User__c FROM Case WHERE Id =: caseObj.Id LIMIT 1];
        Assert.areEqual(caseOb.OwnerId, assignRule.DefaultQueueID__c, 'Case owner should be same as queue in assigment rule');
    }
    
    @IsTest
    private static void testSalesComplaintCaseAssignment(){
        User contactCenterUser = [SELECT Id FROM User WHERE Profile.Name = 'Contact Centre Team' AND IsActive = true LIMIT 1];
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Social Media').getRecordTypeId();
        List<SalesOrder__c> soList = [SELECT Id FROM SalesOrder__c LIMIT 1];
        System.runAs(contactCenterUser){
            Case tempCase=new Case(
                CurrencyIsoCode='AED',
                Status='Draft',
                Origin='Email',
                RequesterEmail__c ='abcdef@gmail.com',
                RequesterContactNumber__c= '353535353535',
                Main_Buyer_Share_Percentage__c=41,
                RecordTypeId=RecordTypeCaseId,
                Sales_Order__c= soList[0].id
            );
            insert tempCase;
            Test.StartTest();
            List<Case> tetsCase = [SELECT Id,OwnerId FROM Case WHERE Main_Buyer_Share_Percentage__c = 41];
            AssignmentRuleHandler.salesComplaintCaseAssignment(new List<Id>{tetsCase[0].Id});
            AssignmentRule__c assingmentRule = [SELECT Id FROM AssignmentRule__c WHERE ProcessName__c = 'General Complaint Case Assignment'];
            AssignmentUser__c assUser = [SELECT Id,User__c FROM AssignmentUser__c WHERE AssignmentRule__c =: assingmentRule.Id];
            List<Case> cases = [SELECT Id,OwnerId FROM Case WHERE Main_Buyer_Share_Percentage__c = 41];
        Test.StopTest();
        Assert.areEqual(assUser.User__c, cases[0].OwnerId, 'Case owner should be same as user in assigment rule user');
        }
    }

    @IsTest
    private static void testCRMCaseAssignment(){
        User contactCenterUser = [SELECT Id FROM User WHERE Profile.Name = 'Contact Centre Team' AND IsActive = true LIMIT 1];
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Social Media').getRecordTypeId();
        List<SalesOrder__c> soList = [SELECT Id FROM SalesOrder__c LIMIT 1];
        List<Unit__c> testUnit = [SELECT Id FROM Unit__c];
        System.runAs(contactCenterUser){
            Case tempCase=new Case(
                CurrencyIsoCode='AED',
                Status='Draft',
                Origin='Email',
                RequesterEmail__c ='abcdef@gmail.com',
                RequesterContactNumber__c= '353535353535',
                Main_Buyer_Share_Percentage__c=41,
                RecordTypeId=RecordTypeCaseId,
                Sales_Order__c= soList[0].id,
                Unit__c = testUnit[0].id
            );
            insert tempCase;
            Test.StartTest();
            List<Case> tetsCase = [SELECT Id,OwnerId FROM Case WHERE Main_Buyer_Share_Percentage__c = 41];
            AssignmentRuleHandler.crmCaseAssignment(new List<Id>{tetsCase[0].Id});
            AssignmentRuleHandler.crmResaleCaseAssignment(new List<Id>{tetsCase[0].Id});
            AssignmentRule__c assingmentRule = [SELECT Id FROM AssignmentRule__c WHERE ProcessName__c = 'CRM Case Assignment' AND Project__c != null];
            AssignmentUser__c assUser = [SELECT Id,User__c FROM AssignmentUser__c WHERE AssignmentRule__c =: assingmentRule.Id];
            List<Case> cases = [SELECT Id,OwnerId FROM Case WHERE Main_Buyer_Share_Percentage__c = 41];
        Test.StopTest();
        Assert.areEqual(assUser.User__c, cases[0].OwnerId, 'Case owner should be same as user in assigment rule user');
        }
        
    }
    /*
    @IsTest
    private static void testADHALeadAssignment(){
        List<Lead> leadList = [SELECT Id FROM Lead LIMIT 1];
        Test.StartTest();
            AssignmentRuleHandler.adhaLeadAssignment(new List<Id>{leadList[0].Id});
            AssignmentRule__c assingmentRule = [SELECT Id FROM AssignmentRule__c WHERE ProcessName__c = 'General Complaint Case Assignment'];
            AssignmentUser__c assUser = [SELECT Id,User__c FROM AssignmentUser__c WHERE AssignmentRule__c =: assingmentRule.Id];
            List<Lead> Leads = [SELECT Id,OwnerId FROM Lead LIMIT 1];
        Test.StopTest();
        Assert.areEqual(assUser.User__c, Leads[0].OwnerId, 'Case owner should be same as user in assigment rule user');
    }*/
    
    @IsTest
    static void testGenericCaseAssignmentRule() {
        
        // === Create an active Assignment Rule for Case ===
        AssignmentRule__c assr1 = new AssignmentRule__c(
            RecordType__c = 'Case',
            ProcessName__c = 'Broker Case Assignment',
            ProcessType__c = 'Broker',
            IsActive__c = true
        );
        insert assr1;
        
        // === Fetch an active Business Hour ===
        List<BusinessHours> bhs = [SELECT Id FROM BusinessHours WHERE IsActive = TRUE LIMIT 1];
        
        // === Get System Administrator User ===
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE LIMIT 1];
        
        // === Create an Assignment User linked to the Assignment Rule ===
        AssignmentUser__c assru = new AssignmentUser__c(
            IsActive__c = true,
            AssignmentRule__c = assr1.Id,
            User__c = adminUser.Id,
            BusinessHours__c = bhs.isEmpty() ? null : bhs[0].Id
        );
        insert assru;
        
        // === Get RecordType Ids for Generic Cases ===
        Id delayedCommissionRT = Utility.getRecordTypeIdByDevName(Case.SObjectType, 'DelayedCommissionPayment');
        Id incorrectCommissionRT = Utility.getRecordTypeIdByDevName(Case.SObjectType, 'IncorrectCommissionAmount');
        Id otherServiceRequestRT = Utility.getRecordTypeIdByDevName(Case.SObjectType, 'OtherServiceRequest');
        
        // === Create Generic Case records ===
        List<Case> genericCases = new List<Case>{
            new Case(RecordTypeId = delayedCommissionRT, Status = 'New', Subject = 'Delayed Commission Payment'),
                new Case(RecordTypeId = incorrectCommissionRT, Status = 'New', Subject = 'Incorrect Commission Amount'),
                new Case(RecordTypeId = otherServiceRequestRT, Status = 'New', Subject = 'Other Service Request')
                };        
                    //insert genericCases;
                    Test.startTest();
        Test.enableChangeDataCapture();
        insert genericCases;
        Test.StopTest();
    }

    @IsTest
    private static void testsuperAppCaseAssignment(){
        List<Case> caseList = [SELECT Id FROM Case LIMIT 1];
        Test.StartTest();
            AssignmentRuleHandler.superAppCaseAssignment(new List<Id>{caseList[0].Id});
            AssignmentRule__c assingmentRule = [SELECT Id FROM AssignmentRule__c WHERE ProcessName__c = 'Super App Registration Case Assignment'];
            AssignmentUser__c assUser = [SELECT Id,User__c FROM AssignmentUser__c WHERE AssignmentRule__c =: assingmentRule.Id];
            List<Case> cases = [SELECT Id,OwnerId FROM Case LIMIT 1];
        Test.StopTest();
        Assert.areEqual(assUser.User__c, cases[0].OwnerId, 'Case owner should be same as user in assigment rule user');
    }

    @IsTest
    private static void testCRMCaseAssignmentWithoutProject(){
        User contactCenterUser = [SELECT Id FROM User WHERE Profile.Name = 'Contact Centre Team' AND IsActive = true LIMIT 1];
        
        System.runAs(contactCenterUser) {
            String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Social Media').getRecordTypeId();
            Case c = new Case(Subject = 'No Project Case', Status = 'New', Origin = 'Email',recordTypeId = RecordTypeCaseId);
            insert c;
            
            Test.StartTest();
                AssignmentRuleHandler.crmCaseAssignment(new List<Id>{c.Id});
            Test.StopTest();
            
            Case updatedCase = [SELECT Id, OwnerId FROM Case WHERE Id = :c.Id LIMIT 1];
            AssignmentRule__c assingmentRule = [SELECT Id FROM AssignmentRule__c WHERE ProcessName__c = 'CRM Case Assignment' AND Project__c = null LIMIT 1];
            AssignmentUser__c assUser = [SELECT Id,User__c FROM AssignmentUser__c WHERE AssignmentRule__c = :assingmentRule.Id LIMIT 1];
            Assert.areEqual(assUser.User__c, updatedCase.OwnerId, 'Case owner should be same as user in assignment rule user');
        }
    }

    @IsTest
    private static void testCRMCaseAssignmentSuperApp(){
        List<Case> caseList = [SELECT Id FROM Case WHERE Unit__c = null LIMIT 1 ];
        Case c = new Case(Id = caseList[0].Id,
            Subject = 'Super App Case',
            Origin = 'Super App',
            Status = 'New'
        );
        update c;

        Test.StartTest();
            AssignmentRuleHandler.crmCaseAssignment(new List<Id>{c.Id});
        Test.StopTest();
        
        Case updatedCase = [SELECT Id, OwnerId FROM Case WHERE Id = :c.Id];
        AssignmentRule__c assingmentRule = [SELECT Id FROM AssignmentRule__c WHERE ProcessName__c = 'CRM Case Assignment' AND Project__c = null LIMIT 1];
        AssignmentUser__c assUser = [SELECT Id,User__c FROM AssignmentUser__c WHERE AssignmentRule__c =: assingmentRule.Id LIMIT 1];
        Assert.areEqual(assUser.User__c, updatedCase.OwnerId, 'Case should have been assigned via Super App origin logic');
    }
    
    @IsTest
    private static void testBFMCommonAreaBLCCaseAssignment(){
    	Id recId =Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Common_Area_Request').getRecordTypeId();
        Case caseObj = [SELECT Id FROM Case LIMIT 1];
		caseObj.RecordTypeId = recId;
		update caseObj;
        Test.startTest();
            AssignmentRuleHandler.bfmCommonAreaBLCCaseAssignment(new List<Id>{caseObj.Id});
        Test.stopTest();
    
        Case updatedCase = [
            SELECT Id, PendingWith__c
            FROM Case
            WHERE Id = :caseObj.Id
        ];
    
        Assert.areEqual('BLC Team',updatedCase.PendingWith__c,'Pending With should be BLC Team');
    }


    @IsTest
    private static void testBFMCommonAreaDLPCaseAssignment(){
    	Id recId =Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Common_Area_Request').getRecordTypeId();
        Case caseObj = [SELECT Id FROM Case LIMIT 1];
    	caseObj.RecordTypeId = recId;
		update caseObj;
        Test.startTest();
            AssignmentRuleHandler.bfmCommonAreaDLPCaseAssignment(new List<Id>{caseObj.Id});
        Test.stopTest();
    
        Case updatedCase = [
            SELECT Id, PendingWith__c
            FROM Case
            WHERE Id = :caseObj.Id
        ];
    
        Assert.areEqual('DLP Team',updatedCase.PendingWith__c,'Pending With should be DLP Team');
    }
}