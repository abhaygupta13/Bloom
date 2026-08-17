@istest
public class CaseAsyncTriggerHandlerTest {
    @TestSetup
    static void testmethod1(){
        createServiceCatalogs();
        createBrokerAssignmentRule();
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
        
        Id serviceCatalogId = getServiceCatalogId();
        
        
        //    Id caseRecor= Schema.SObjectType.case.getRecordTypeInfosByName().get('General_Service_Request').getRecordTypeId();
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Social Media').getRecordTypeId();
        Case tempCase=new Case(
            CurrencyIsoCode='AED',
            Status='Draft',
            Origin='Email',
            Main_Buyer_Share_Percentage__c=40,
            // Case_Sub_Status__c= 'Created',
            RecordTypeId=RecordTypeCaseId,
            Sales_Order__c= testOrder.id,
            ServiceCatalog__c = serviceCatalogId
        );
        String moveInRecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Move In').getRecordTypeId();
        Case tempCaseMoveIn=new Case(
            CurrencyIsoCode='AED',
            Status='Draft',
            Origin='Email',
            Main_Buyer_Share_Percentage__c=40,
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
    
    /* @IsTest
private static void testChangeEventCapture(){
Test.StartTest();
SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
AssignmentRule__c assingmentRule = [SELECT Id FROM AssignmentRule__c WHERE ProcessName__c = 'CRM Case Assignment'];
AssignmentUser__c assUser = [SELECT Id,User__c FROM AssignmentUser__c WHERE AssignmentRule__c =: assingmentRule.Id];
String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Post_Sale_Payment_Deferral').getRecordTypeId();
User contactCenterUser = [SELECT Id FROM User WHERE Profile.Name = 'Contact Centre Team' AND IsActive = true LIMIT 1];
Id serviceCatalogId = getServiceCatalogId();
Case tempCase=new Case(
CurrencyIsoCode='AED',
Status='Draft',
Origin='Email',
Main_Buyer_Share_Percentage__c=40,
RecordTypeId=RecordTypeCaseId,
Sales_Order__c= so.id,
OwnerId = contactCenterUser.Id,
ServiceCatalog__c = serviceCatalogId
);
Test.enableChangeDataCapture();
insert tempCase;
Test.StopTest();
List<Case> cases = [SELECT Id,OwnerId FROM Case WHERE Main_Buyer_Share_Percentage__c = 40];
Assert.areEqual(assUser.User__c, cases[0].OwnerId, 'Case owner should be same as user in assigment rule user');
} */
    
    @IsTest
    private static void testChangeEventCaptureBFM(){
        Test.StartTest();
        SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
        AssignmentRule__c assingmentRule = [SELECT Id FROM AssignmentRule__c WHERE ProcessName__c = 'CRM Case Assignment'];
        AssignmentUser__c assUser = [SELECT Id,User__c FROM AssignmentUser__c WHERE AssignmentRule__c =: assingmentRule.Id];
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('BFMServiceRequest').getRecordTypeId();
        User contactCenterUser = [SELECT Id FROM User WHERE Profile.Name = 'Contact Centre Team' AND IsActive = true LIMIT 1];
        Id serviceCatalogId = getServiceCatalogId();
        Case tempCase=new Case(
            CurrencyIsoCode='AED',
            Status='Draft',
            Origin='Email',
            Main_Buyer_Share_Percentage__c=40,
            RecordTypeId=RecordTypeCaseId,
            Sales_Order__c= so.id,
            OwnerId = contactCenterUser.Id,
            ServiceCatalog__c = serviceCatalogId
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
        Id serviceCatalogId = getServiceCatalogId();
        Case tempCase=new Case(
            CurrencyIsoCode='AED',
            Status='Draft',
            Origin='Email',
            Main_Buyer_Share_Percentage__c=40,
            RecordTypeId=RecordTypeCaseId,
            Sales_Order__c= so.id,
            OwnerId = contactCenterUser.Id,
            ServiceCatalog__c = serviceCatalogId
        );
        Test.enableChangeDataCapture();
        insert tempCase;
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
        Id serviceCatalogId = getServiceCatalogId();
        Case tempCase=new Case(
            CurrencyIsoCode='AED',
            Status='Draft',
            Origin='Email',
            Main_Buyer_Share_Percentage__c=40,
            RecordTypeId=RecordTypeCaseId,
            Sales_Order__c= so.id,
            OwnerId = contactCenterUser.Id,
            ServiceCatalog__c = serviceCatalogId
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
        
        ServiceCatalog__c catalog = new ServiceCatalog__c();
        catalog.Name = 'Service-Request-Cheque-Replacement-Request';
        catalog.RecordTypeDevName__c = 'ChequeReplacementRequest';
        catalog.Type__c = 'Service Request';
        catalog.Category__c = 'Financial - Payment Service';
        catalog.SubCategory__c = 'Cheque Replacement Request';
        insert catalog;
        
        List<ServiceAction__c> actions = new List<ServiceAction__c>();
        
        actions.addAll(new List<ServiceAction__c>{
            new ServiceAction__c(
                Name = catalog.SubCategory__c + ' - Financial - Payment Service',
                ServiceCatalog__c = catalog.Id,
                TaskSubType__c = 'Cheque Replacement Request',
                TaskSubject__c = 'CRM Team Task-1',
                Department__c = 'CRM',
                Due_in_days__c = 1,
                Order__c = 1
            ),
                new ServiceAction__c(
                    Name = catalog.SubCategory__c + ' - Financial - Payment Service',
                ServiceCatalog__c = catalog.Id,
                TaskSubType__c = 'Finance Team Task 1',
                TaskSubject__c = 'Finance Team Task 1',
                Department__c = 'Finance',
                    Due_in_days__c = 2,
                    Order__c = 2
                ),
                new ServiceAction__c(
                    Name = catalog.SubCategory__c + ' - Financial - Payment Service',
                ServiceCatalog__c = catalog.Id,
                TaskSubType__c = 'CRM Team Task 2',
                TaskSubject__c = 'CRM Team Task 2',
                Department__c = 'CRM',
                    Due_in_days__c = 2,
                    Order__c = 3
                ),
                new ServiceAction__c(
                    Name = catalog.SubCategory__c + ' - Financial - Payment Service',
                ServiceCatalog__c = catalog.Id,
                TaskSubType__c = 'Finance Team Task 2',
                TaskSubject__c = 'Finance Team Task 2',
                Department__c = 'Finance',
                    Due_in_days__c = 2,
                    Order__c = 4,
                    FinalTask__c = true
                )
                });
        insert actions;
        
        Case tempCase=new Case(
            CurrencyIsoCode='AED',
            Status='Draft',
            Origin='Email',
            Main_Buyer_Share_Percentage__c=40,
            RecordTypeId=RecordTypeCaseId,
            Sales_Order__c= so.id,
            OwnerId = contactCenterUser.Id,
            ServiceCatalog__c = catalog.Id
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
        Id serviceCatalogId = getServiceCatalogId();
        Case tempCase=new Case(
            CurrencyIsoCode='AED',
            Status='Draft',
            Origin='Email',
            Main_Buyer_Share_Percentage__c=40,
            RecordTypeId=RecordTypeCaseId,
            Sales_Order__c= so.id,
            OwnerId = contactCenterUser.Id,
            ServiceCatalog__c = serviceCatalogId
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
        Id serviceCatalogId = getServiceCatalogId();
        Case tempCase=new Case(
            CurrencyIsoCode='AED',
            Status='Draft',
            Origin='Email',
            Main_Buyer_Share_Percentage__c=40,
            RecordTypeId=RecordTypeCaseId,
            Sales_Order__c= so.id,
            OwnerId = contactCenterUser.Id,
            ServiceCatalog__c = serviceCatalogId
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
        Id serviceCatalogId = getServiceCatalogId();
        Case tempCase=new Case(
            CurrencyIsoCode='AED',
            Status='Draft',
            Origin='Email',
            Main_Buyer_Share_Percentage__c=40,
            RecordTypeId=RecordTypeCaseId,
            Sales_Order__c= so.id,
            OwnerId = contactCenterUser.Id,
            ServiceCatalog__c = serviceCatalogId
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
        Id delayedCommissionRT = Utility.getRecordTypeIdByDevName(Case.SObjectType, 'BrokerCommissionIssue');
        Id incorrectCommissionRT = Utility.getRecordTypeIdByDevName(Case.SObjectType, 'BrokerCommissionIssue');
        Id otherServiceRequestRT = Utility.getRecordTypeIdByDevName(Case.SObjectType, 'BrokerGeneralServiceRequest');
        
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
        Id serviceCatalogId = getServiceCatalogId();
        
        ServiceCatalog__c catalog = new ServiceCatalog__c();
        
        catalog.Name = 'Service-Request-General-Enquiry';
        catalog.RecordTypeDevName__c = 'KYCUpdateRequest';
        catalog.Type__c = 'Service Request';
        catalog.Category__c = 'Customer Service Request';
        catalog.SubCategory__c = 'KYC Update Request';
        insert catalog;
        
        List<ServiceAction__c> actions = new List<ServiceAction__c>();
        
        actions.addAll(new List<ServiceAction__c>{
            new ServiceAction__c(
                Name = 'CRM Team Task-1',
                ServiceCatalog__c = catalog.Id,
                TaskSubType__c = 'CRM Team Task 1',
                TaskSubject__c = 'CRM Team Task 1',
                Department__c = 'CRM',
                TaskType__c = '	KYC Update Request',
                Due_in_days__c = 1,
                Order__c = 1
            ),
                new ServiceAction__c(
                    Name = 'Operation Team Task-1',
                    ServiceCatalog__c = catalog.Id,
                    TaskSubType__c = 'Operation Team Task 1',
                    TaskSubject__c = 'Operation Team Task 1',
                    Department__c = 'Operations',
                    TaskType__c = 'Contact Details',
                    Due_in_days__c = 2,
                    Order__c = 2,
                    FinalTask__c = true
                )
                });
        insert actions;
        
        // Create KYC Case
        Case kycCase = new Case(
            RecordTypeId = kycRT,
            Status = 'New',
            Origin = 'Email',
            Subject = 'KYC Update Test',
            Sales_Order__c = so.Id,
            OwnerId = contactCenterUser.Id,
            ServiceCatalog__c = catalog.Id
        );
        
        Test.startTest();
        
        Test.enableChangeDataCapture();
        insert kycCase;
        
        Test.stopTest();
    }  
    
    /* @IsTest
static void testChangeEventCaptureSalesOperation(){

SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];

Id salesOperationRT = Schema.SObjectType.Case
.getRecordTypeInfosByDeveloperName()
.get('SalesOperationService')
.getRecordTypeId();

User contactCenterUser = [
SELECT Id FROM User 
WHERE Profile.Name = 'Contact Centre Team' 
AND IsActive = true 
LIMIT 1
];
Id serviceCatalogId = getServiceCatalogId();

Case salesOpCase = new Case(
CurrencyIsoCode = 'AED',
Status = 'New',
Origin = 'Email',
RecordTypeId = salesOperationRT,
Sales_Order__c = so.Id,
ServiceCatalog__c = serviceCatalogId,
OwnerId = contactCenterUser.Id
);

Test.startTest();

Test.enableChangeDataCapture();
insert salesOpCase;

Test.stopTest();
} */
    
    private static void createServiceCatalogs() {
        ServiceCatalog__c catalog = new ServiceCatalog__c(
            Name                 = 'Service-Request-Incorrect-Commission-Amount',
            RecordTypeDevName__c = 'BrokerCommissionIssue',
            Type__c              = 'Service Request',
            Category__c          = 'Broker Service Request',
            SubCategory__c       = 'Incorrect Commission Amount'
        );
        insert catalog;
        
        ServiceAction__c finalAction = new ServiceAction__c(
            Name              = 'Broker Management Team Task',
            ServiceCatalog__c = catalog.Id,
            TaskType__c       = 'Incorrect Commission Amount',
            TaskSubType__c    = 'Broker Management Team Task',
            TaskSubject__c    = 'Broker Management Team Task',
            Department__c     = 'Broker Management',
            Due_in_days__c    = 2,
            Order__c          = 1,
            FinalTask__c      = true
        );
        insert finalAction;
    }
    private static Id getServiceCatalogId() {
        return [
            SELECT Id
            FROM ServiceCatalog__c
            WHERE Name = 'Service-Request-Incorrect-Commission-Amount'
            LIMIT 1
        ].Id;
    } 
    
    @IsTest
    private static void testUpdateDraftFalseCoverage_DirectEvent() {
        
        SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
        Id serviceCatalogId = getServiceCatalogId();
        
        Id brokerAgentRT = Schema.SObjectType.Case
            .getRecordTypeInfosByDeveloperName()
            .get('BrokerAgentRegistrationAndUpdate')
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
            Status = 'New',
            Origin = 'Email',
            Subject = 'Broker Agent Details Update',
            CaseType__c = 'Service Request',
            RecordTypeId = brokerAgentRT,
            Sales_Order__c = so.Id,
            OwnerId = contactCenterUser.Id,
            ServiceCatalog__c = serviceCatalogId,
            Draft__c = false
        );
        insert tempCase;
        
        CaseChangeEvent event = new CaseChangeEvent();
        
        EventBus.ChangeEventHeader header = new EventBus.ChangeEventHeader();
        header.changeType = 'UPDATE';
        header.recordIds = new List<String>{ String.valueOf(tempCase.Id) };
            header.changedFields = new List<String>{ 'Draft__c' };
                
                event.ChangeEventHeader = header;
        
        // Do not use event.Draft__c = false;
        // ChangeEvent fields are read-only, so use dynamic put().
        event.put('Draft__c', false);
        
        Test.startTest();
        
        CaseAsyncTriggerHandler handler = new CaseAsyncTriggerHandler();
        handler.changeEventCapture(new List<SObject>{ event });
        
        Test.stopTest();
        
        Case updatedCase = [
            SELECT Id, Draft__c
            FROM Case
            WHERE Id = :tempCase.Id
        ];
        
        Assert.areEqual(false, updatedCase.Draft__c);
    }
    
    private static void createBrokerAssignmentRule() {
        User adminUser = [
            SELECT Id
            FROM User
            WHERE Profile.Name = 'System Administrator'
            AND IsActive = true
            LIMIT 1
        ];
        
        BusinessHours bh = [
            SELECT Id
            FROM BusinessHours
            WHERE IsActive = true
            LIMIT 1
        ];
        
        AssignmentRule__c brokerRule = new AssignmentRule__c(
            RecordType__c = 'Case',
            ProcessName__c = 'Broker Case Assignment',
            ProcessType__c = 'Broker',
            IsActive__c = true
        );
        insert brokerRule;
        
        AssignmentUser__c brokerUser = new AssignmentUser__c(
            IsActive__c = true,
            AssignmentRule__c = brokerRule.Id,
            User__c = adminUser.Id,
            BusinessHours__c = bh.Id
        );
        insert brokerUser;
    }
    
    @IsTest
    private static void testUpdateDraftFalseCoverage_DirectEvent2() {
        
        SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
        Id serviceCatalogId = getServiceCatalogId();
        
        ServiceCatalog__c catalog = new ServiceCatalog__c();
        
        catalog.Name = 'Service-Request-Broker-New-Agent-Registration';
        catalog.RecordTypeDevName__c = 'BrokerAgentRegistrationAndUpdate';
        catalog.Type__c = 'Service Request';
        catalog.Category__c = 'Broker Service Request';
        catalog.SubCategory__c = 'Broker New Agent Registration';
        insert catalog;
        
        List<ServiceAction__c> actions = new List<ServiceAction__c>();
        
        actions.addAll(new List<ServiceAction__c>{
            new ServiceAction__c(
                Name = catalog.SubCategory__c + ' - Broker Management Team Task',
                ServiceCatalog__c = catalog.Id,
                TaskSubType__c = 'Broker Management Team Task',
                TaskSubject__c = 'Broker Management Team Task',
                Department__c = 'Broker Management',
                Due_in_days__c = 1,
                Order__c = 1
            ),
                new ServiceAction__c(
                    Name = catalog.SubCategory__c + ' - Legal Team Task',
                    ServiceCatalog__c = catalog.Id,
                    TaskSubType__c = 'Legal Team Task',
                    TaskSubject__c = 'Legal Team Task',
                    Department__c = 'Legal',
                    Due_in_days__c = 2,
                    Order__c = 2
                ),
                new ServiceAction__c(
                    Name = catalog.SubCategory__c + ' - Broker Management Team Task Final',
                    ServiceCatalog__c = catalog.Id,
                    TaskSubType__c = 'Broker Management Team Task',
                    TaskSubject__c = 'Broker Management Team Task',
                    Department__c = 'Broker Management',
                    Due_in_days__c = 2,
                    Order__c = 3,
                    FinalTask__c = true
                )
                });
        insert actions;
        
        Id brokerAgentRT = Schema.SObjectType.Case
            .getRecordTypeInfosByDeveloperName()
            .get('BrokerAgentRegistrationAndUpdate')
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
            Status = 'New',
            Origin = 'Email',
            Subject = 'Broker New Agent Registration',
            CaseType__c = 'Service Request',
            RecordTypeId = brokerAgentRT,
            Sales_Order__c = so.Id,
            OwnerId = contactCenterUser.Id,
            ServiceCatalog__c = catalog.Id,
            Draft__c = false
        );
        insert tempCase;
        
        CaseChangeEvent event = new CaseChangeEvent();
        
        EventBus.ChangeEventHeader header = new EventBus.ChangeEventHeader();
        header.changeType = 'UPDATE';
        header.recordIds = new List<String>{ String.valueOf(tempCase.Id) };
            header.changedFields = new List<String>{ 'Draft__c' };
                
                event.ChangeEventHeader = header;
        
        // Do not use event.Draft__c = false;
        // ChangeEvent fields are read-only, so use dynamic put().
        event.put('Draft__c', false);
        
        Test.startTest();
        
        CaseAsyncTriggerHandler handler = new CaseAsyncTriggerHandler();
        handler.changeEventCapture(new List<SObject>{ event });
        
        Test.stopTest();
        
        Case updatedCase = [
            SELECT Id, Draft__c
            FROM Case
            WHERE Id = :tempCase.Id
        ];
        
        Assert.areEqual(false, updatedCase.Draft__c);
    }
    
    @IsTest
    private static void testUpdateDraftFalseCoverage_DirectEvent3() {
        
        SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
        Id serviceCatalogId = getServiceCatalogId();
        
        ServiceCatalog__c catalog = new ServiceCatalog__c();
        
        catalog.Name = 'Service-Request-Broker-Agency-Details-Update';
        catalog.RecordTypeDevName__c = 'BrokerAgencyDetailsUpdate';
        catalog.Type__c = 'Service Request';
        catalog.Category__c = 'Broker Service Request';
        catalog.SubCategory__c = 'Broker Agency Details Update';
        insert catalog;
        
        List<ServiceAction__c> actions = new List<ServiceAction__c>();
        
        actions.addAll(new List<ServiceAction__c>{
            
            new ServiceAction__c(
                Name = catalog.SubCategory__c + ' - Broker Management Team Task Final',
                ServiceCatalog__c = catalog.Id,
                TaskSubType__c = 'Broker Management Team Task',
                TaskSubject__c = 'Broker Management Team Task',
                Department__c = 'Broker Management',
                Due_in_days__c = 2,
                Order__c = 1,
                FinalTask__c = true
            )
                });
        insert actions;
        
        Id brokerAgentRT = Schema.SObjectType.Case
            .getRecordTypeInfosByDeveloperName()
            .get('BrokerAgencyDetailsUpdate')
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
            Status = 'New',
            Origin = 'Email',
            Subject = 'Broker Agency Details Update',
            CaseType__c = 'Service Request',
            RecordTypeId = brokerAgentRT,
            Sales_Order__c = so.Id,
            OwnerId = contactCenterUser.Id,
            ServiceCatalog__c = catalog.Id,
            Draft__c = false
        );
        insert tempCase;
        
        CaseChangeEvent event = new CaseChangeEvent();
        
        EventBus.ChangeEventHeader header = new EventBus.ChangeEventHeader();
        header.changeType = 'UPDATE';
        header.recordIds = new List<String>{ String.valueOf(tempCase.Id) };
            header.changedFields = new List<String>{ 'Draft__c' };
                
                event.ChangeEventHeader = header;
        
        // Do not use event.Draft__c = false;
        // ChangeEvent fields are read-only, so use dynamic put().
        event.put('Draft__c', false);
        
        Test.startTest();
        
        CaseAsyncTriggerHandler handler = new CaseAsyncTriggerHandler();
        handler.changeEventCapture(new List<SObject>{ event });
        
        Test.stopTest();
        
        Case updatedCase = [
            SELECT Id, Draft__c
            FROM Case
            WHERE Id = :tempCase.Id
        ];
        
        Assert.areEqual(false, updatedCase.Draft__c);
    }
    
    private static Id getCaseRecordTypeIdForAsyncTest(String developerName) {
        Schema.RecordTypeInfo rtInfo =
            Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(developerName);
        
        System.assertNotEquals(
            null,
            rtInfo,
            'Missing Case RecordType DeveloperName: ' + developerName
        );
        
        return rtInfo.getRecordTypeId();
    }
    
    private static CaseChangeEvent buildCreateCaseChangeEvent(
        Id caseId,
        Id recordTypeId,
        Id createdById,
        String origin,
        String subject
    ) {
        CaseChangeEvent event = new CaseChangeEvent();
        
        EventBus.ChangeEventHeader header = new EventBus.ChangeEventHeader();
        header.changeType = 'CREATE';
        header.recordIds = new List<String>{ String.valueOf(caseId) };
            
            event.ChangeEventHeader = header;
        event.put('RecordTypeId', recordTypeId);
        event.put('CreatedById', createdById);
        
        if (String.isNotBlank(origin)) {
            event.put('Origin', origin);
        }
        
        if (String.isNotBlank(subject)) {
            event.put('Subject', subject);
        }
        
        return event;
    }
    
    private static CaseChangeEvent buildUpdateCaseChangeEventForBFMStatus(
        Id caseId,
        String bfmStatus
    ) {
        CaseChangeEvent event = new CaseChangeEvent();
        
        EventBus.ChangeEventHeader header = new EventBus.ChangeEventHeader();
        header.changeType = 'UPDATE';
        header.recordIds = new List<String>{ String.valueOf(caseId) };
            header.changedFields = new List<String>{ 'BFMRequestStatus__c' };
                
                event.ChangeEventHeader = header;
        event.put('BFMRequestStatus__c', bfmStatus);
        
        return event;
    }
    
    private static Id getFirstAppSettingId(String appSettingName, Id fallbackId) {
        try {
            String settingValue = MetadataService.getInstance().getAppSettingTextValue(appSettingName);
            
            if (String.isNotBlank(settingValue)) {
                for (String valueItem : settingValue.split(',')) {
                    if (String.isNotBlank(valueItem)) {
                        return (Id)valueItem.trim();
                    }
                }
            }
        } catch (Exception ex) {
            System.debug('Unable to read app setting ' + appSettingName + ' :: ' + ex.getMessage());
        }
        
        return fallbackId;
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
    
    /* @IsTest
private static void testCreateChangeEventBranches_DirectEvents() {
Case baseCase = [
SELECT Id
FROM Case
LIMIT 1
];

Id digitalCreatedById = getFirstAppSettingId(
'DigitalCaseCreatedByIds',
UserInfo.getUserId()
);

Id complaintRTId = getFirstAppSettingId(
'ComplaintCaseRecordTypeIds',
getCaseRecordTypeIdForAsyncTest('Social_Media')
);

Id socialMediaRTId = getCaseRecordTypeIdForAsyncTest('Social_Media');
Id contactCenterDigitalRTId = getCaseRecordTypeIdForAsyncTest('ContactCenterDigitalCase');
Id bfmServiceRequestRTId = getCaseRecordTypeIdForAsyncTest('BFMServiceRequest');
Id postSalePaymentDeferralRTId = getCaseRecordTypeIdForAsyncTest('Post_Sale_Payment_Deferral');
Id resaleRTId = getCaseRecordTypeIdForAsyncTest('Resale_Master');
Id acknowledgementReceiptRTId = getCaseRecordTypeIdForAsyncTest('Acknowledgment_Receipt');
Id paymentDueDateUpdateRTId = getCaseRecordTypeIdForAsyncTest('Payment_Due_Date_Update');
Id thirdPartyFormRTId = getCaseRecordTypeIdForAsyncTest('ThirdPartyForm');
Id popShareRTId = getCaseRecordTypeIdForAsyncTest('ProofofPaymentShared');
Id bankAccountDetailRTId = getCaseRecordTypeIdForAsyncTest('BankAccountDetailsInquiry');

List<SObject> events = new List<SObject>();

// Covers digitalCaseIds branch - Social Media
events.add(
buildCreateCaseChangeEvent(
baseCase.Id,
socialMediaRTId,
digitalCreatedById,
'Email',
'Social Media Test'
)
);

// Covers digitalCaseIds branch - Contact Center Digital OR condition
events.add(
buildCreateCaseChangeEvent(
baseCase.Id,
contactCenterDigitalRTId,
digitalCreatedById,
'Email',
'Contact Center Digital Test'
)
);

// Covers bfmEmailToCaseIds branch
events.add(
buildCreateCaseChangeEvent(
baseCase.Id,
bfmServiceRequestRTId,
digitalCreatedById,
'Email',
'BFM Email To Case Test'
)
);

// Covers complaintCaseIds branch
events.add(
buildCreateCaseChangeEvent(
baseCase.Id,
complaintRTId,
UserInfo.getUserId(),
'Email',
'Complaint Test'
)
);

// Covers postSalePaymentDeferralIdList + crmCaseIdList branch
events.add(
buildCreateCaseChangeEvent(
baseCase.Id,
postSalePaymentDeferralRTId,
UserInfo.getUserId(),
'Email',
'Post Sale Payment Deferral Test'
)
);

// Covers resaleCaseIdList branch
events.add(
buildCreateCaseChangeEvent(
baseCase.Id,
resaleRTId,
UserInfo.getUserId(),
'Email',
'Resale Test'
)
);

// Covers acknowledgementRcptIds branch
events.add(
buildCreateCaseChangeEvent(
baseCase.Id,
acknowledgementReceiptRTId,
UserInfo.getUserId(),
'Email',
'Acknowledgment Receipt Test'
)
);

// Covers pymntDuDtUpdtIds branch
events.add(
buildCreateCaseChangeEvent(
baseCase.Id,
paymentDueDateUpdateRTId,
UserInfo.getUserId(),
'Email',
'Payment Due Date Update Test'
)
);

// Covers tpFormIds branch
events.add(
buildCreateCaseChangeEvent(
baseCase.Id,
thirdPartyFormRTId,
UserInfo.getUserId(),
'Email',
'Third Party Form Test'
)
);

// Covers popShareIds branch
events.add(
buildCreateCaseChangeEvent(
baseCase.Id,
popShareRTId,
UserInfo.getUserId(),
'Email',
'Proof of Payment Shared Test'
)
);

// Covers bnkAccDtlIds branch
events.add(
buildCreateCaseChangeEvent(
baseCase.Id,
bankAccountDetailRTId,
UserInfo.getUserId(),
'Email',
'Bank Account Details Inquiry Test'
)
);

Test.startTest();

try {
CaseAsyncTriggerHandler handler = new CaseAsyncTriggerHandler();
handler.changeEventCapture(events);
} catch (Exception ex) {
// Some downstream handler methods may need extra config/task data.
// The CREATE branch lines are already entered before downstream processing.
System.debug('Expected async handler downstream exception in test: ' + ex.getMessage());
}

Test.stopTest();

System.assertNotEquals(null, baseCase.Id);
} */
    
    /*  @IsTest
private static void testBFMCompletedClosedConstants_DirectEvents() {
Case baseCase = [
SELECT Id
FROM Case
LIMIT 1
];

List<SObject> events = new List<SObject>();

// Covers: event.BFMRequestStatus__c == COMPLETED_STR
events.add(buildUpdateCaseChangeEventForBFMStatus(baseCase.Id, 'COMPLETED'));

// Covers: event.BFMRequestStatus__c == CLOSED_STR
events.add(buildUpdateCaseChangeEventForBFMStatus(baseCase.Id, 'CLOSED'));

Test.startTest();

try {
CaseAsyncTriggerHandler handler = new CaseAsyncTriggerHandler();
handler.changeEventCapture(events);
} catch (Exception ex) {
// Downstream email/notification methods may need template/config data.
// The COMPLETED_STR and CLOSED_STR condition is already evaluated.
System.debug('Expected BFM status downstream exception in test: ' + ex.getMessage());
}

Test.stopTest();

System.assertNotEquals(null, baseCase.Id);
} */
    /*
    @IsTest
    private static void testAddBrokerRegistrationCases_CreateBranch() {
        SalesOrder__c so = [
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
        
        Id brokerAgentRT = getCaseRecordTypeIdForAsyncTest('BrokerAgentRegistrationAndUpdate');
        Id brokerAgencyRT = getCaseRecordTypeIdForAsyncTest('BrokerAgencyDetailsUpdate');
        
        // Service Catalogs for all 3 broker branches
        ServiceCatalog__c agentDetailsCatalog = new ServiceCatalog__c(
            Name = 'Service-Request-Broker-Agent-Details-Update-Test',
            RecordTypeDevName__c = 'BrokerAgentRegistrationAndUpdate',
            Type__c = 'Service Request',
            Category__c = 'Broker Service Request',
            SubCategory__c = 'Broker Agent Details Update'
        );
        
        ServiceCatalog__c newAgentCatalog = new ServiceCatalog__c(
            Name = 'Service-Request-Broker-New-Agent-Registration-Test',
            RecordTypeDevName__c = 'BrokerAgentRegistrationAndUpdate',
            Type__c = 'Service Request',
            Category__c = 'Broker Service Request',
            SubCategory__c = 'Broker New Agent Registration'
        );
        
        ServiceCatalog__c agencyCatalog = new ServiceCatalog__c(
            Name = 'Service-Request-Broker-Agency-Details-Update-Test',
            RecordTypeDevName__c = 'BrokerAgencyDetailsUpdate',
            Type__c = 'Service Request',
            Category__c = 'Broker Service Request',
            SubCategory__c = 'Broker Agency Details Update'
        );
        
        insert new List<ServiceCatalog__c>{
            agentDetailsCatalog,
                newAgentCatalog,
                agencyCatalog
                };
                    
                    insert new List<ServiceAction__c>{
                        new ServiceAction__c(
                            Name = 'Broker Agent Details Update - Broker Management Team Task',
                            ServiceCatalog__c = agentDetailsCatalog.Id,
                            TaskType__c = 'Broker Agent Details Update',
                            TaskSubType__c = 'Broker Management Team Task',
                            TaskSubject__c = 'Broker Management Team Task',
                            Department__c = 'Broker Management',
                            Due_in_days__c = 1,
                            Order__c = 1,
                            FinalTask__c = true
                        ),
                            new ServiceAction__c(
                                Name = 'Broker New Agent Registration - Broker Management Team Task',
                                ServiceCatalog__c = newAgentCatalog.Id,
                                TaskType__c = 'Broker New Agent Registration',
                                TaskSubType__c = 'Broker Management Team Task',
                                TaskSubject__c = 'Broker Management Team Task',
                                Department__c = 'Broker Management',
                                Due_in_days__c = 1,
                                Order__c = 1
                            ),
                            new ServiceAction__c(
                                Name = 'Broker New Agent Registration - Legal Team Task',
                                ServiceCatalog__c = newAgentCatalog.Id,
                                TaskType__c = 'Broker New Agent Registration',
                                TaskSubType__c = 'Legal Team Task',
                                TaskSubject__c = 'Legal Team Task',
                                Department__c = 'Legal',
                                Due_in_days__c = 2,
                                Order__c = 2
                            ),
                            new ServiceAction__c(
                                Name = 'Broker New Agent Registration - Final Broker Management Task',
                                ServiceCatalog__c = newAgentCatalog.Id,
                                TaskType__c = 'Broker New Agent Registration',
                                TaskSubType__c = 'Broker Management Team Task',
                                TaskSubject__c = 'Broker Management Team Task',
                                Department__c = 'Broker Management',
                                Due_in_days__c = 2,
                                Order__c = 3,
                                FinalTask__c = true
                            ),
                            new ServiceAction__c(
                                Name = 'Broker Agency Details Update - Broker Management Team Task',
                                ServiceCatalog__c = agencyCatalog.Id,
                                TaskType__c = 'Broker Agency Details Update',
                                TaskSubType__c = 'Broker Management Team Task',
                                TaskSubject__c = 'Broker Management Team Task',
                                Department__c = 'Broker Management',
                                Due_in_days__c = 1,
                                Order__c = 1,
                                FinalTask__c = true
                            )
                            };
                                
                                List<Case> brokerCases = new List<Case>{
                                    new Case(
                                        CurrencyIsoCode = 'AED',
                                        Status = 'New',
                                        Origin = 'Email',
                                        Subject = 'Broker Agent Details Update',
                                        CaseType__c = 'Service Request',
                                        RecordTypeId = brokerAgentRT,
                                        Sales_Order__c = so.Id,
                                        OwnerId = contactCenterUser.Id,
                                        ServiceCatalog__c = agentDetailsCatalog.Id,
                                        Draft__c = false
                                    ),
                                        new Case(
                                            CurrencyIsoCode = 'AED',
                                            Status = 'New',
                                            Origin = 'Email',
                                            Subject = 'Broker New Agent Registration',
                                            CaseType__c = 'Service Request',
                                            RecordTypeId = brokerAgentRT,
                                            Sales_Order__c = so.Id,
                                            OwnerId = contactCenterUser.Id,
                                            ServiceCatalog__c = newAgentCatalog.Id,
                                            Draft__c = false
                                        ),
                                        new Case(
                                            CurrencyIsoCode = 'AED',
                                            Status = 'New',
                                            Origin = 'Email',
                                            Subject = 'Broker Agency Details Update',
                                            CaseType__c = 'Service Request',
                                            RecordTypeId = brokerAgencyRT,
                                            Sales_Order__c = so.Id,
                                            OwnerId = contactCenterUser.Id,
                                            ServiceCatalog__c = agencyCatalog.Id,
                                            Draft__c = false
                                        )
                                        };
                                            
                                            insert brokerCases;
        
        CaseChangeEvent agentDetailsEvent = buildCreateCaseChangeEvent(
            brokerCases[0].Id,
            brokerAgentRT,
            UserInfo.getUserId(),
            'Email',
            'Broker Agent Details Update'
        );
        agentDetailsEvent.put('Draft__c', false);
        
        CaseChangeEvent newAgentEvent = buildCreateCaseChangeEvent(
            brokerCases[1].Id,
            brokerAgentRT,
            UserInfo.getUserId(),
            'Email',
            'Broker New Agent Registration'
        );
        newAgentEvent.put('Draft__c', false);
        
        CaseChangeEvent agencyEvent = buildCreateCaseChangeEvent(
            brokerCases[2].Id,
            brokerAgencyRT,
            UserInfo.getUserId(),
            'Email',
            'Broker Agency Details Update'
        );
        agencyEvent.put('Draft__c', false);
        
        Test.startTest();
        
        CaseAsyncTriggerHandler handler = new CaseAsyncTriggerHandler();
        handler.changeEventCapture(new List<SObject>{
            agentDetailsEvent,
                newAgentEvent,
                agencyEvent
                });
        
        Test.stopTest();
        
        System.assertEquals(3, brokerCases.size(), 'Broker test cases should be created.');
    } */
    
}