@istest
public class CaseAsyncTriggerHandlerTest {
    @TestSetup
    static void testmethod1(){
         
        User contactCenterUser = [SELECT Id FROM User WHERE Profile.Name = 'Contact Centre Team' AND IsActive = true LIMIT 1];
        List<BusinessHours> bhs=[select id from BusinessHours where isActive = true];

        AssignmentRule__c assr4 = new AssignmentRule__c();
        assr4.RecordType__c = 'Case';
        assr4.ProcessName__c = 'CRM Case Assignment';
        assr4.IsActive__c = true; 
        assr4.ProcessType__c = 'Sales';
        insert assr4;

        AssignmentUser__c assru5 = new AssignmentUser__c();
        assru5.IsActive__c = true;
        assru5.AssignmentRule__c = assr4.id;
        assru5.BusinessHours__c = bhs[0].id;
        assru5.User__c = contactCenterUser.id;
        insert assru5;

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
            Name='Test Project'
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
        
        
        //    Id caseRecor= Schema.SObjectType.case.getRecordTypeInfosByName().get('General_Service_Request').getRecordTypeId();
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Social Media').getRecordTypeId();
        Case tempCase=new Case(
            CurrencyIsoCode='AED',
            Status='Draft',
            Origin='Email',
            Main_Buyer_Share_Percentage__c=40,
            // Case_Sub_Status__c= 'Created',
            RecordTypeId=RecordTypeCaseId,
            Sales_Order__c= testOrder.id
        );
        String moveInRecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Move In').getRecordTypeId();
        Case tempCaseMoveIn=new Case(
            CurrencyIsoCode='AED',
            Status='Draft',
            Origin='Email',
            Main_Buyer_Share_Percentage__c=50,
            // Case_Sub_Status__c= 'Created',
            RecordTypeId=moveInRecordTypeCaseId,
            Sales_Order__c= testOrder.id
        );
         Test.enableChangeDataCapture();
        insert tempCase;
        insert tempCaseMoveIn;
         Test.getEventBus().deliver();
        Account tempAcc=new Account(
            Name='test'
        );
        insert tempAcc;
        JointOwner__c tempJointOwner=new JointOwner__c(
            Account__c=tempAcc.id,
            SharePercentage__c=40,
            Case__c=tempCase.id
        );
        insert tempJointOwner;
        
        list<Case> trgNewList=new list<Case>();
        trgNewList.add(tempCase);        
        tempCase.Contacts_Case_Email__c='abc@xyz.com';
        Test.enableChangeDataCapture();
        update  tempCase;
        Test.getEventBus().deliver();
         Test.enableChangeDataCapture();
        delete  tempCase;
            Test.getEventBus().deliver();
           CaseChangeEvent event = new CaseChangeEvent();
        
        // Set the ChangeEventHeader
        EventBus.ChangeEventHeader header = new EventBus.ChangeEventHeader();
        header.changeType = 'CREATE'; // Change to 'UPDATE', 'DELETE', or 'UNDELETE' to test other scenarios
        event.ChangeEventHeader = header;
        //  EventBus.Publish(event);
        
        
        // Set the ChangeEventHeader
        EventBus.ChangeEventHeader header2 = new EventBus.ChangeEventHeader();
        header2.changeType = 'UPDATE'; // Change to 'UPDATE', 'DELETE', or 'UNDELETE' to test other scenarios
        event.ChangeEventHeader = header2;
        EventBus.ChangeEventHeader header3 = new EventBus.ChangeEventHeader();
        header3.changeType = 'DELETE'; // Change to 'UPDATE', 'DELETE', or 'UNDELETE' to test other scenarios
        event.ChangeEventHeader = header3;
        EventBus.ChangeEventHeader header4 = new EventBus.ChangeEventHeader();
        header4.changeType = 'UNDELETE'; // Change to 'UPDATE', 'DELETE', or 'UNDELETE' to test other scenarios
        event.ChangeEventHeader = header4;
    }

    @IsTest
    private static void testChangeEventCapture(){
        Test.StartTest();
            SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
            AssignmentRule__c assingmentRule = [SELECT Id FROM AssignmentRule__c WHERE ProcessName__c = 'CRM Case Assignment'];
            AssignmentUser__c assUser = [SELECT Id,User__c FROM AssignmentUser__c WHERE AssignmentRule__c =: assingmentRule.Id];
            String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Post_Sale_Payment_Deferral').getRecordTypeId();
            User contactCenterUser = [SELECT Id FROM User WHERE Profile.Name = 'Contact Centre Team' AND IsActive = true LIMIT 1];
            Case tempCase=new Case(
                CurrencyIsoCode='AED',
                Status='Draft',
                Origin='Email',
                Main_Buyer_Share_Percentage__c=40,
                RecordTypeId=RecordTypeCaseId,
                Sales_Order__c= so.id,
                OwnerId = contactCenterUser.Id
            );
            Test.enableChangeDataCapture();
            insert tempCase;
        Test.StopTest();
        List<Case> cases = [SELECT Id,OwnerId FROM Case WHERE Main_Buyer_Share_Percentage__c = 40];
        Assert.areEqual(assUser.User__c, cases[0].OwnerId, 'Case owner should be same as user in assigment rule user');
    }
    
    @IsTest
    private static void testChangeEventCaptureBFM(){
        Test.StartTest();
            SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
            AssignmentRule__c assingmentRule = [SELECT Id FROM AssignmentRule__c WHERE ProcessName__c = 'CRM Case Assignment'];
            AssignmentUser__c assUser = [SELECT Id,User__c FROM AssignmentUser__c WHERE AssignmentRule__c =: assingmentRule.Id];
            String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('BFMServiceRequest').getRecordTypeId();
            User contactCenterUser = [SELECT Id FROM User WHERE Profile.Name = 'Contact Centre Team' AND IsActive = true LIMIT 1];
            Case tempCase=new Case(
                CurrencyIsoCode='AED',
                Status='Draft',
                Origin='Email',
                Main_Buyer_Share_Percentage__c=40,
                RecordTypeId=RecordTypeCaseId,
                Sales_Order__c= so.id,
                OwnerId = contactCenterUser.Id
            );
            Test.enableChangeDataCapture();
            insert tempCase;
        Test.StopTest();
    }
    
    @IsTest
    private static void testChangeEventCaptureResale(){
        Test.StartTest();
            SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
            AssignmentRule__c assingmentRule = [SELECT Id FROM AssignmentRule__c WHERE ProcessName__c = 'CRM Case Assignment'];
            AssignmentUser__c assUser = [SELECT Id,User__c FROM AssignmentUser__c WHERE AssignmentRule__c =: assingmentRule.Id];
            String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Resale_Property_Under_Construction').getRecordTypeId();
            User contactCenterUser = [SELECT Id FROM User WHERE Profile.Name = 'Contact Centre Team' AND IsActive = true LIMIT 1];
            Case tempCase=new Case(
                CurrencyIsoCode='AED',
                Status='Draft',
                Origin='Email',
                Main_Buyer_Share_Percentage__c=40,
                RecordTypeId=RecordTypeCaseId,
                Sales_Order__c= so.id,
                OwnerId = contactCenterUser.Id
            );
        Test.enableChangeDataCapture();
        insert tempCase;
        
        tempCase.Status = 'Cancelled';
        Test.enableChangeDataCapture();
        update tempCase;
        Test.getEventBus().deliver();
        Test.StopTest();
      
    }
    
    @IsTest
    private static void testChangeEventCaptureDefault(){
        Test.StartTest();
            SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
            AssignmentRule__c assingmentRule = [SELECT Id FROM AssignmentRule__c WHERE ProcessName__c = 'CRM Case Assignment'];
            AssignmentUser__c assUser = [SELECT Id,User__c FROM AssignmentUser__c WHERE AssignmentRule__c =: assingmentRule.Id];
            String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('DefaultUnit').getRecordTypeId();
            User contactCenterUser = [SELECT Id FROM User WHERE Profile.Name = 'Contact Centre Team' AND IsActive = true LIMIT 1];
            Case tempCase=new Case(
                CurrencyIsoCode='AED',
                Status='Draft',
                Origin='Email',
                Main_Buyer_Share_Percentage__c=40,
                RecordTypeId=RecordTypeCaseId,
                Sales_Order__c= so.id,
                OwnerId = contactCenterUser.Id
            );
            Test.enableChangeDataCapture();
            insert tempCase;
        Test.StopTest();
    }
    
    @IsTest
    private static void testChangeEventCaptureChequeReplacement(){
        Test.StartTest();
            SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
            AssignmentRule__c assingmentRule = [SELECT Id FROM AssignmentRule__c WHERE ProcessName__c = 'CRM Case Assignment'];
            AssignmentUser__c assUser = [SELECT Id,User__c FROM AssignmentUser__c WHERE AssignmentRule__c =: assingmentRule.Id];
            String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ChequeReplacementRequest').getRecordTypeId();
            User contactCenterUser = [SELECT Id FROM User WHERE Profile.Name = 'Contact Centre Team' AND IsActive = true LIMIT 1];
            Case tempCase=new Case(
                CurrencyIsoCode='AED',
                Status='Draft',
                Origin='Email',
                Main_Buyer_Share_Percentage__c=40,
                RecordTypeId=RecordTypeCaseId,
                Sales_Order__c= so.id,
                OwnerId = contactCenterUser.Id
            );
            Test.enableChangeDataCapture();
            insert tempCase;
        Test.StopTest();
    }
    
    @IsTest
    private static void testChangeEventCaptureChequeWithdrawal(){
        Test.StartTest();
            SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
            AssignmentRule__c assingmentRule = [SELECT Id FROM AssignmentRule__c WHERE ProcessName__c = 'CRM Case Assignment'];
            AssignmentUser__c assUser = [SELECT Id,User__c FROM AssignmentUser__c WHERE AssignmentRule__c =: assingmentRule.Id];
            String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ChequeWithdrawalRequest').getRecordTypeId();
            User contactCenterUser = [SELECT Id FROM User WHERE Profile.Name = 'Contact Centre Team' AND IsActive = true LIMIT 1];
            Case tempCase=new Case(
                CurrencyIsoCode='AED',
                Status='Draft',
                Origin='Email',
                Main_Buyer_Share_Percentage__c=40,
                RecordTypeId=RecordTypeCaseId,
                Sales_Order__c= so.id,
                OwnerId = contactCenterUser.Id
            );
            Test.enableChangeDataCapture();
            insert tempCase;
        Test.StopTest();
    }
    
    @IsTest
    private static void testChangeEventCaptureLPFWaiverRequest(){
        Test.StartTest();
            SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
            AssignmentRule__c assingmentRule = [SELECT Id FROM AssignmentRule__c WHERE ProcessName__c = 'CRM Case Assignment'];
            AssignmentUser__c assUser = [SELECT Id,User__c FROM AssignmentUser__c WHERE AssignmentRule__c =: assingmentRule.Id];
            String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('LPFWaiverRequest').getRecordTypeId();
            User contactCenterUser = [SELECT Id FROM User WHERE Profile.Name = 'Contact Centre Team' AND IsActive = true LIMIT 1];
            Case tempCase=new Case(
                CurrencyIsoCode='AED',
                Status='Draft',
                Origin='Email',
                Main_Buyer_Share_Percentage__c=40,
                RecordTypeId=RecordTypeCaseId,
                Sales_Order__c= so.id,
                OwnerId = contactCenterUser.Id
            );
            Test.enableChangeDataCapture();
            insert tempCase;
        Test.StopTest();
    }
    
    @IsTest
    private static void testChangeEventCaptureSOARequest(){
        Test.StartTest();
            SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
            AssignmentRule__c assingmentRule = [SELECT Id FROM AssignmentRule__c WHERE ProcessName__c = 'CRM Case Assignment'];
            AssignmentUser__c assUser = [SELECT Id,User__c FROM AssignmentUser__c WHERE AssignmentRule__c =: assingmentRule.Id];
            String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('SOARequest').getRecordTypeId();
            User contactCenterUser = [SELECT Id FROM User WHERE Profile.Name = 'Contact Centre Team' AND IsActive = true LIMIT 1];
            Case tempCase=new Case(
                CurrencyIsoCode='AED',
                Status='Draft',
                Origin='Email',
                Main_Buyer_Share_Percentage__c=40,
                RecordTypeId=RecordTypeCaseId,
                Sales_Order__c= so.id,
                OwnerId = contactCenterUser.Id
            );
            Test.enableChangeDataCapture();
            insert tempCase;
        Test.StopTest();
    }
    
    
    @IsTest
    static void testGenericCaseAssignment() {
        
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
static void testKYCUpdateRequestCoverage() {
    
    // Fetch required data
    SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
    
    Id kycRT = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                    .get('KYCUpdateRequest').getRecordTypeId();
    
    User contactCenterUser = [
        SELECT Id FROM User 
        WHERE Profile.Name = 'Contact Centre Team' 
        AND IsActive = true 
        LIMIT 1
    ];
    
    // Create KYC Case
    Case kycCase = new Case(
        RecordTypeId = kycRT,
        Status = 'New',
        Origin = 'Email',
        Subject = 'KYC Update Test',
        Sales_Order__c = so.Id,
        OwnerId = contactCenterUser.Id
    );
    
    Test.startTest();
    
    Test.enableChangeDataCapture();
    insert kycCase;
    
    Test.stopTest();
}  
  
      @IsTest
private static void testChangeEventCaptureSalesOperation(){
    
    Test.startTest();
    
    SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
    
    String recordTypeCaseId = Schema.SObjectType.Case
        .getRecordTypeInfosByDeveloperName()
        .get('SalesOperationService')
        .getRecordTypeId();
    
    User contactCenterUser = [
        SELECT Id 
        FROM User 
        WHERE Profile.Name = 'Contact Centre Team' 
        AND IsActive = true 
        LIMIT 1
    ];
    
    Case tempCase = new Case(
        CurrencyIsoCode = 'AED',
        Status = 'Draft',
        Origin = 'Email',
        Subject = 'Sales Operation Test',
        Main_Buyer_Share_Percentage__c = 40,
        RecordTypeId = recordTypeCaseId,
        Sales_Order__c = so.Id,
        OwnerId = contactCenterUser.Id
    );
    
    Test.enableChangeDataCapture();
    insert tempCase;
    
    Test.stopTest();
    
    // Optional assertion
    List<Case> insertedCases = [
        SELECT Id, RecordTypeId 
        FROM Case 
        WHERE Id = :tempCase.Id
    ];
    
    System.assertEquals(1, insertedCases.size());
}
    @IsTest
static void testAdditionalCreateBranchesCoverage() {

    SalesOrder__c salesOrder = [
        SELECT Id
        FROM SalesOrder__c
        LIMIT 1
    ];

    User contactCenterUser = [
        SELECT Id
        FROM User
        WHERE Profile.Name = 'Contact Centre Team'
        AND IsActive = true
        LIMIT 1
    ];

    Map<String, Schema.RecordTypeInfo> caseRecordTypes =
        Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName();

    List<Case> casesToInsert = new List<Case>{
        new Case(
            Subject = 'General Service Request Coverage',
            Status = 'Draft',
            Origin = 'Email',
            CurrencyIsoCode = 'AED',
            RecordTypeId = caseRecordTypes
                .get('General_Service_Request')
                .getRecordTypeId(),
            Sales_Order__c = salesOrder.Id,
            OwnerId = contactCenterUser.Id
        ),
        new Case(
            Subject = 'Financial Service Request Coverage',
            Status = 'Draft',
            Origin = 'Email',
            CurrencyIsoCode = 'AED',
            RecordTypeId = caseRecordTypes
                .get('Financial_Services')
                .getRecordTypeId(),
            Sales_Order__c = salesOrder.Id,
            OwnerId = contactCenterUser.Id
        ),
        new Case(
            Subject = 'Handover Service Request Coverage',
            Status = 'Draft',
            Origin = 'Email',
            CurrencyIsoCode = 'AED',
            RecordTypeId = caseRecordTypes
                .get('Handover_Service_Request')
                .getRecordTypeId(),
            Sales_Order__c = salesOrder.Id,
            OwnerId = contactCenterUser.Id
        ),
        new Case(
            Subject = 'Special Service Request Coverage',
            Status = 'Draft',
            Origin = 'Email',
            CurrencyIsoCode = 'AED',
            RecordTypeId = caseRecordTypes
                .get('Special_Services')
                .getRecordTypeId(),
            Sales_Order__c = salesOrder.Id,
            OwnerId = contactCenterUser.Id
        ),
        new Case(
            Subject = 'Payment SR Coverage',
            Status = 'Draft',
            Origin = 'Email',
            CurrencyIsoCode = 'AED',
            RecordTypeId = caseRecordTypes
                .get('Payment_SR')
                .getRecordTypeId(),
            Sales_Order__c = salesOrder.Id,
            OwnerId = contactCenterUser.Id
        )
    };

    Test.startTest();

    Test.enableChangeDataCapture();
    insert casesToInsert;
    Test.getEventBus().deliver();

    Test.stopTest();

    System.assertEquals(
        5,
        [
            SELECT COUNT()
            FROM Case
            WHERE Id IN :casesToInsert
        ]
    );
}

    @IsTest
    private static void testChangeEventCaptureMoveIn(){
        Test.StartTest();
            String moveInRecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Move In').getRecordTypeId();
            List<Case> moveINList = [SELECT Id,Status, Origin FROM Case WHERE recordTypeId = : moveInRecordTypeCaseId]; 
            moveINList[0].Status = 'Submitted';
            update moveINList;
            Test.enableChangeDataCapture();
        Test.StopTest();
    }
   
    
}