@isTest
public class BCAPP_MoveInServiceHandlerTest {
    
    // @testSetup Method to create common test data for all test methods
    @testSetup
    static void createTestData() {
        
        
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
        Service_Catalog__c serviceCatalog = new Service_Catalog__c(Name = 'Move In');
        insert serviceCatalog;
        
        Project__c testProject=new Project__c(
            Name='Test Project'
        );
        insert testProject;
        
        
        BuildingSection__c testBuilding=new BuildingSection__c(
            Name='Test Building',
            BuildingSectionCode__c='BL-CAS',
            Project__c=testProject.Id
            
        );
        
        List<Service_Catalog_Fields__c> fieldsList = new List<Service_Catalog_Fields__c>();
        
        // Adding multiple Service_Catalog_Fields__c records to the list
        fieldsList.add(new Service_Catalog_Fields__c(
            Name = 'unitId',
            Field_API_Name__c = 'Unit__c',
            User_Type__c = 'Tenant;Owner',
            Service_Catalog__c = serviceCatalog.Id
        ));
        
        fieldsList.add(new Service_Catalog_Fields__c(
            Name = 'emailAddress',
            Field_API_Name__c = 'Email_Address__c',
            User_Type__c = 'Tenant;Owner',
            Service_Catalog__c = serviceCatalog.Id
        ));
        
        fieldsList.add(new Service_Catalog_Fields__c(
            Name = 'moveInDate',
            Field_API_Name__c = 'Move_In_Date__c',
            User_Type__c = 'Tenant;Owner',
            is_Date__c = true,
            Service_Catalog__c = serviceCatalog.Id
        ));
        fieldsList.add(new Service_Catalog_Fields__c(
            Name = 'ejariStartDate',
            Field_API_Name__c = 'EJARI_Tawteeq_start_date__c',
            User_Type__c = 'Tenant;Owner',
            is_Date__c = true,
            Service_Catalog__c = serviceCatalog.Id
        ));
        fieldsList.add(new Service_Catalog_Fields__c(
            Name = 'ejariNumber',
            Field_API_Name__c = 'EJARI_Tawteeq_number__c',
            User_Type__c = 'Tenant;Owner',
            Service_Catalog__c = serviceCatalog.Id
        ));
        fieldsList.add(new Service_Catalog_Fields__c(
            Name = 'ejariEndDate',
            Field_API_Name__c = 'EJARI_Tawteeq_end_date__c',
            User_Type__c = 'Tenant;Owner',
            is_Date__c = true,
            Service_Catalog__c = serviceCatalog.Id
        ));
        fieldsList.add(new Service_Catalog_Fields__c(
            Name = 'requestAs',
            Field_API_Name__c = 'User_Type__c',
            User_Type__c = 'Tenant;Owner',
            Service_Catalog__c = serviceCatalog.Id
        ));
        
        // Insert all records at once
        insert fieldsList;
        
        // Create a Unit record (Unit__c)
        Unit__c unit = new Unit__c(Name = 'Unit 1', Project__c = testProject.Id,BuildingSectionName__c =testBuilding.Id, Is_Chiller_Enabled__c = true);
        insert unit;
        
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // Create a custom User record (user__c)
        user__c customUser = new user__c(
            Name = 'Test User', 
            Email__c = 'testuser@example.com', 
            user_account__c = acc.Id,
            Username__c = 'testuser@example.com',
            User_Type__c = 'Owner'
        );
        insert customUser;
    }
    
    @isTest
    static void testCreateMoveInRequest() {
        
                RestResponse res = new RestResponse();
        RestContext.response = res;


        // Get the test data created in @testSetup method
        Service_Catalog__c serviceCatalog = [SELECT Id FROM Service_Catalog__c LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
        
        Test.setMock(HttpCalloutMock.class, new WebServiceMockResponse());

        // Prepare JSON request for the test
        String jsonRequest = '{"request":{' +
            '"hasAgreedTerms":false,' +
            '"requestAs":"Tenant",' +
            '"unitId":"' + unit.Id + '"' +
            '}}';
        
        // Mock the BCAPP_Utility and WebServiceHelper methods using stubs or mocks.
        Test.startTest();
        
        BCAPP_MoveInServiceHandler myClass = new BCAPP_MoveInServiceHandler();
        myClass.createMoveInRequest(jsonRequest);
        
        Test.stopTest();
        
        // Verify that the correct responses are returned
        Case resultCase = [SELECT Id, Status, Request_Number__c FROM Case];
        
        // Assertions to check the result
        
        
    }
    
    @isTest
    static void testOwnerCreateMoveInRequest() {
        
                RestResponse res = new RestResponse();
        RestContext.response = res;


        // Get the test data created in @testSetup method
        Service_Catalog__c serviceCatalog = [SELECT Id FROM Service_Catalog__c LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
        Account acc = [select Id from Account];
        Test.setMock(HttpCalloutMock.class, new WebServiceMockResponse());

        // Prepare JSON request for the test
        String jsonRequest = '{"request":{' +
            '"hasAgreedTerms":false,' +
            '"requestAs":"Owner",' +
            '"unitId":"' + unit.Id + '",' +
            '"accountId":"' + acc.Id + '"' +
            '}}';
        
        // Mock the BCAPP_Utility and WebServiceHelper methods using stubs or mocks.
        Test.startTest();
        
        BCAPP_MoveInServiceHandler myClass = new BCAPP_MoveInServiceHandler();
        myClass.createMoveInRequest(jsonRequest);
        
        Test.stopTest();
        
        // Verify that the correct responses are returned
        Case resultCase = [SELECT Id, Status, Request_Number__c FROM Case];
        
        
        
    }
    @isTest
    static void testInvalidJsonFormatException() {

        RestResponse res = new RestResponse();
        RestContext.response = res;
        // Get the test data created in @testSetup method
        Service_Catalog__c serviceCatalog = [SELECT Id FROM Service_Catalog__c LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
        Account acc = [select Id from Account];
        Test.setMock(HttpCalloutMock.class, new WebServiceMockResponse());

        // Prepare JSON request for the test
        String jsonRequest = '{"request":{' +
            '"hasAgreedTerms":false,' +
            '"requestAs":"Owner",' +
            '"unitId":"' + unit.Id + '"' +
            '"accountId":"' + acc.Id + '"' +
            '}}';
        
        // Mock the BCAPP_Utility and WebServiceHelper methods using stubs or mocks.
        Test.startTest();
        
        BCAPP_MoveInServiceHandler myClass = new BCAPP_MoveInServiceHandler();
        myClass.createMoveInRequest(jsonRequest);
        
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