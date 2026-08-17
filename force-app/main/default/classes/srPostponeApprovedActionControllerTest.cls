@isTest
public class srPostponeApprovedActionControllerTest {
    
    @TestSetup
    public static void setupTestData() {
        // Create test ServiceCatalog record
        ServiceCatalog__c testServiceCatalog = new ServiceCatalog__c(
            Name = 'Test Service Catalog',
            Type__c = 'Service Request',
            Category__c = 'BFM Service',
            SubCategory__c = 'BFM Service Request',
            RecordTypeDevName__c = 'Post_Sale_Payment_Deferral'
        );
        insert testServiceCatalog;
        system.debug('testServiceCatalog----->'+testServiceCatalog);

        // Create test ServiceAction record
        ServiceAction__c testServiceAction = new ServiceAction__c(
            ServiceCatalog__c = testServiceCatalog.Id,
            TaskType__c = 'Post Sale Payment Deferral',
            TaskSubType__c = 'Post Sale Payment Deferral',
            Order__c = 1
        );
        insert testServiceAction;
        system.debug('testServiceAction----->'+testServiceAction);
        
         Account testAccount = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId(),
            LastName = 'Test Account',
            PersonEmail = 'testaccount@test.com'
        );
        insert testAccount;
        
        // Create Test Opportunity
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'New',
            CloseDate = System.today(),
            LeadChannel__c = 'Walk in',
            AccountId = testAccount.Id,
            WinReason__c = 'Loyalty'
        );
        insert testOpportunity;
        
        // Create Test Project
        Project__c testProject=new Project__c(
            Name='Test Project'
        );
        insert testProject;
        
        // Create Test Buidling
        BuildingSection__c testBuilding=new BuildingSection__c(
            Name='Test Building',
            BuildingSectionCode__c='BL-CAS',
            Project__c=testProject.Id
            
        );
        insert testBuilding;
        
        // Create Test Unit
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
        
        // Create Test Sales Order
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
        
        // Create test Case record
        Case testCase = new Case(
            CurrencyIsoCode = 'AED',
            Origin = 'Email',
            Status = 'Assigned',
            Step__c = '2',
            //OwnerId = testUser.Id,
            RecordTypeId = caseRecordTypeId,
            Sales_Order__c = testSalesOrder.Id,
            ServiceCatalog__c = testServiceCatalog.Id
        );
        insert testCase;
    }
    
    @isTest
static void testGetPostponeApprovedPicklistValues() {
    Test.startTest();
    List<String> values = srPostponeApprovedActionController.getPostponeApprovedPicklistValues();
    Test.stopTest();
    
    System.assertNotEquals(null, values, 'Picklist values should not be null');
    System.assert(values.size() > 0, 'Picklist values should not be empty');
}

@isTest
static void testUpdatePostponeApprovedField() {
    // Get the test Case record inserted in @TestSetup
    Case testCase = [SELECT Id FROM Case WHERE RecordType.DeveloperName = 'Post_Sale_Payment_Deferral' LIMIT 1];

    // Choose a valid picklist value (you can hardcode a label or query it)
    String selectedValue = 'Yes'; 

    Test.startTest();
    Map<String, Object> response = srPostponeApprovedActionController.updatePostponeApprovedField(testCase.Id, selectedValue);
    Test.stopTest();

    System.assertNotEquals(null, response, 'Response map should not be null');
}
    

}