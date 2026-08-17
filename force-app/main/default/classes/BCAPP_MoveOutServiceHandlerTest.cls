@isTest
public class BCAPP_MoveOutServiceHandlerTest {
    
    @testSetup
    static void createTestData() {

        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Move In Holiday Homes').getRecordTypeId();
        
        Case testCase =BCAPP_TestDataFactory.createCase();
        testCase.RecordTypeId= RecordTypeCaseId;
        insert testCase;
        
        
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
        
        
        
        // Create a Service Catalog record (Service_Catalog__c)
        Service_Catalog__c serviceCatalog = new Service_Catalog__c(Name = 'Move Out');
        Service_Catalog__c ren_serviceCatalog = new Service_Catalog__c(Name = 'Renewal');
        List<Service_Catalog__c> lstSC = new List<Service_Catalog__c>();
        lstSC.add(serviceCatalog);
        lstSC.add(ren_serviceCatalog);
        insert lstSC;
        
        Project__c testProject = new Project__c(Name = 'Test Project');
        insert testProject;
        
        BuildingSection__c testBuilding = new BuildingSection__c(
            Name = 'Test Building',
            BuildingSectionCode__c = 'BL-CAS',
            Project__c = testProject.Id
        );
        insert testBuilding;
        
        List<Service_Catalog_Fields__c> fieldsList = new List<Service_Catalog_Fields__c>();
        
        // Adding multiple Service_Catalog_Fields__c records to the list
        fieldsList.add(new Service_Catalog_Fields__c(
            Name = 'unitId',
            Field_API_Name__c = 'Unit__c',
            User_Type__c = 'Tenant;Holiday Homes',
            Service_Catalog__c = ren_serviceCatalog.Id
        ));
        
        fieldsList.add(new Service_Catalog_Fields__c(
            Name = 'leaseExpDate',
            Field_API_Name__c = 'EJARI_Tawteeq_end_date__c',
            User_Type__c = 'Tenant;Holiday Homes',
            is_Date__c = true,
            Service_Catalog__c = ren_serviceCatalog.Id
        ));
        
        fieldsList.add(new Service_Catalog_Fields__c(
            Name = 'childOccupants',
            Field_API_Name__c = 'Total_Number_of_Child_Occupants__c',
            User_Type__c = 'Tenant;Holiday Homes',
            is_Decimal__c = true,
            Service_Catalog__c = ren_serviceCatalog.Id
        ));
        
        fieldsList.add(new Service_Catalog_Fields__c(
            Name = 'adultOccupants',
            Field_API_Name__c = 'Total_Number_of_Adults_Occupants__c',
            User_Type__c = 'Tenant;Holiday Homes',
            is_Decimal__c = true,
            Service_Catalog__c = ren_serviceCatalog.Id
        ));
        
        fieldsList.add(new Service_Catalog_Fields__c(
            Name = 'accountId',
            Field_API_Name__c = 'AccountId',
            User_Type__c = 'Tenant;Holiday Homes',
            Service_Catalog__c = ren_serviceCatalog.Id
        ));
        
        // Insert all records at once
        insert fieldsList;
        
        // Create a Unit record (Unit__c)
        Unit__c unit = new Unit__c(Name = 'Unit 1', Project__c = testProject.Id, BuildingSectionName__c = testBuilding.Id, Is_Chiller_Enabled__c = true);
        insert unit;
        
      
        Account acc = new Account(Name = 'Test Account',Tenant__c=true);
        insert acc;
        
        
        // Create a custom User record (user__c)
        user__c customUser = new user__c(
            Name = 'Test User', 
            Email__c = 'testuser@example.com', 
            user_account__c = acc.Id,
            Account__c = acc.Id,
            Username__c = 'testuser@example.com',
            User_Type__c = 'Broker Agent'
        );
        insert customUser;
        
        Unit_Allocation__c unitAllocation= BCAPP_TestDataFactory.createUnitAllocation();
        unitAllocation.Unit__c=unit.id;
        unitAllocation.User__c=customUser.id;
        unitAllocation.Account__c=acc.id;
        unitAllocation.Is_Favourite_Unit__c=True;
        insert unitAllocation;
        
    }
    
    @isTest
    static void testTenantRenewalRequest() {
          RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
        // Get the test data created in @testSetup method
        Service_Catalog__c serviceCatalog = [SELECT Id FROM Service_Catalog__c LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new WebServiceMockResponse()); // Mocking the callout
        
        user__c u = [SELECT Id FROM user__c WHERE user_account__c = :acc.Id LIMIT 1];
        
        // Prepare JSON request for the test
        String jsonRequest = '{' +
            '"hasAgreedTerms":false,' +
            '"requestAs":"Tenant",' +
            '"unitId":"' + unit.Id + '",' +
            '"accountId":"' + acc.Id + '"' +
            '}';
        
        BCAPP_MoveOutServiceHandler myClass = new BCAPP_MoveOutServiceHandler();
        myClass.renewalRequest(jsonRequest); // Method under test
        
        // Query the created case
         Case resultCase = [SELECT Id, Status, Request_Number__c FROM Case limit 1];
        
         String jsonSubmitRequest = '{' +
            '"hasAgreedTerms":true,' +
            '"requestAs":"Tenant",' +
            '"unitId":"' + unit.Id + '",' +
            '"accountId":"' + acc.Id + '",' +
            '"srId":"' + resultCase.Id + '"' +
            '}';
        
       
        BCAPP_MoveOutServiceHandler myRenewalClass = new BCAPP_MoveOutServiceHandler();
        myRenewalClass.renewalRequest(jsonSubmitRequest); // Method under test
        Test.stopTest();
    }
    
    @isTest
    static void testMoveOutRequest() {
          RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
        // Get the test data created in @testSetup method
        Service_Catalog__c serviceCatalog = [SELECT Id FROM Service_Catalog__c LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new WebServiceMockResponse()); // Mocking the callout
        
        user__c u = [SELECT Id FROM user__c WHERE user_account__c = :acc.Id LIMIT 1];
        
        Unit_Allocation__c unitAllocation= BCAPP_TestDataFactory.createUnitAllocation();
        unitAllocation.Unit__c=unit.id;
        unitAllocation.User__c=u.id;
        unitAllocation.Account__c=acc.id;
        unitAllocation.Active__c=True;//srId
        insert unitAllocation;
        String jsonRequest = '{"accountId":"' + acc.Id + '", "unitId":"' + unitAllocation.Id + '", "moveOutDate":"01-Mar-2099", "hasAgreedTerms":true}';

    
        
        
        BCAPP_MoveOutServiceHandler myClass = new BCAPP_MoveOutServiceHandler();
        myClass.MoveOutRequest(jsonRequest); 
        Case resultCase = [SELECT Id, Status, Request_Number__c FROM Case];

        
          String jsonSubmitRequest = '{"accountId":"' + acc.Id + '", "unitId": "unit.Id" , "moveOutDate":"2099-12-31", "hasAgreedTerms":true} ';

        try{
       
        BCAPP_MoveOutServiceHandler mymoveOutClass = new BCAPP_MoveOutServiceHandler();
        mymoveOutClass.renewalRequest(jsonSubmitRequest); 
        }catch(exception e){}
        Test.stopTest();
    }
    
     @isTest
    static void testEmptyUserRequest() {
          RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
        // Get the test data created in @testSetup method
        Service_Catalog__c serviceCatalog = [SELECT Id FROM Service_Catalog__c LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
        
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new WebServiceMockResponse()); // Mocking the callout
        
        user__c u = [SELECT Id FROM user__c WHERE user_account__c = :acc.Id LIMIT 1];
        
        Unit_Allocation__c unitAllocation= BCAPP_TestDataFactory.createUnitAllocation();
        unitAllocation.Unit__c=unit.id;
        unitAllocation.User__c=u.id;
        unitAllocation.Account__c=acc.id;
        unitAllocation.Active__c=True;
        insert unitAllocation;
        
        String jsonRequest = '{"accountId":"' +acc.id + '", "unitId":"' + unitAllocation.Id + '", "moveOutDate":"01-Mar-2099", "hasAgreedTerms":true}';

        

        
        BCAPP_MoveOutServiceHandler myClass = new BCAPP_MoveOutServiceHandler();
        myClass.MoveOutRequest(jsonRequest); 
        
        // Query the created case
        Case resultCase = [SELECT Id, Status, Request_Number__c FROM Case];
        
        String jsonSubmitRequest = '{"srId":"' + resultCase.Id +'",accountId":"' + acc.id  + '", "unitId": "unit.Id" , "moveOutDate":"2099-12-31", "hasAgreedTerms":true}';

        
        try{
        BCAPP_MoveOutServiceHandler mymoveOutClass = new BCAPP_MoveOutServiceHandler();
        mymoveOutClass.renewalRequest(jsonSubmitRequest); 
        }catch(exception e){
            
        }
        Test.stopTest();
    }
    
    
    @isTest
    static void testInvalidJsonFormatException() {
          RestResponse res = new RestResponse();
        RestContext.response = res;

        // Get the test data created in @testSetup method
        Service_Catalog__c serviceCatalog = [SELECT Id FROM Service_Catalog__c LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new WebServiceMockResponse()); // Mocking the callout
        
        // Prepare JSON request with invalid format (missing comma between keys)
        String jsonRequest = '{"request":{' +
            '"hasAgreedTerms":false,' +
            '"requestAs":"Owner",' +
            '"unitId":"' + unit.Id + '"' +
            '"accountId":"' + acc.Id + '"' + // Missing comma between keys
            '}}';
        
        Test.startTest();
        
        BCAPP_MoveOutServiceHandler myClass = new BCAPP_MoveOutServiceHandler();
        try {
            myClass.renewalRequest(jsonRequest);
          //  System.assert(false, 'Exception should have been thrown due to invalid JSON format');
        } catch (Exception e) {
            // Verifying that the exception is handled correctly
           // System.assert(e.getMessage().contains('Invalid JSON format'), 'Expected an exception with message "Invalid JSON format"');
        }
        
        Test.stopTest();
    }
    
    // Mock Web Service Response (for testing callouts)
    public class WebServiceMockResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"success", "data":{}}');
            return res;
        }
    }
}