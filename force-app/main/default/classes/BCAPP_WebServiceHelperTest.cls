@IsTest
public class BCAPP_WebServiceHelperTest {
    @IsTest
    static void testgetProjects() {
        RestResponse res = new RestResponse();
        RestContext.response = res;
        Project__c testProject =BCAPP_TestDataFactory.createProject();
        testProject.isEnabledMIP__c=true;
        insert testProject;
        BCAPP_WebServiceHelper.getProjects(true);
    }
   
     @IsTest
    static void testgetNationality() {
        RestResponse res = new RestResponse();
        RestContext.response = res;
        BCAPP_WebServiceHelper.getNationality();
    }
    
     @IsTest
    static void testcreateAzureUser() {
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
          String jsonSubmitRequest = '{"firstName":"firstName","lastName":"lastName","email":"lastName@gg.com","userType":"Broker Agent"}';
        BCAPP_WebServiceHelper.createAzureUser(jsonSubmitRequest);
         String jsonSubmitRequest2 = '{"firstName":"firstName","lastName":"lastName","email":""}';
        BCAPP_WebServiceHelper.createAzureUser(jsonSubmitRequest2);
    }
    
      @IsTest
    static void testdeactivateAzureUser() {
        RestResponse res = new RestResponse();
        RestContext.response = res;
                Account accountRecord =BCAPP_TestDataFactory.createAccount('Test Account');
        accountRecord.Azure_UserPrincipal_Id__c='testttt';
        insert accountRecord;
          String jsonSubmitRequest = '{"principalId":"testttt","lastName":"lastName","email":"lastName@gg.com"}';
        BCAPP_WebServiceHelper.deactivateAzureUser(jsonSubmitRequest);
        BCAPP_WebServiceHelper.preLoginOtpFlow(jsonSubmitRequest);
        BCAPP_WebServiceHelper.getAccessPermitCategoryOptions();
    }
    
    
    
    
    
       @IsTest
    static void testgetLastNameFromRequest() {
        RestRequest req = new RestRequest();
        req.httpMethod = 'GET';
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;

         Account accountRecord =BCAPP_TestDataFactory.createAccount('Test Account');
        accountRecord.Azure_UserPrincipal_Id__c='testttt';
        insert accountRecord;
        
        Contact cntRecord= BCAPP_TestDataFactory.createContact(accountRecord.id,'ewew@dasds.com');
        insert cntRecord;
        Service_Contract__c Service_Contract=  BCAPP_TestDataFactory.createServiceContract();
        Service_Contract.Customer_Name__c=accountRecord.id;
        insert Service_Contract;
        
        Case testCase =BCAPP_TestDataFactory.createCase();
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Move In Holiday Homes').getRecordTypeId();
        testCase.RecordTypeId=RecordTypeCaseId;
        testCase.AccountId= accountRecord.id;
        testCase.Move_Out_Date__c=system.today();
        testCase.Email_Address__c='testuser@fff.com';
        insert testCase;
        
        BCAPP_WebServiceHelper.getLastNameFromRequest('{"projectId":"projectId"}');
            User__c userRecord= BCAPP_TestDataFactory.createUser('testttt');
        userRecord.Email__c=testCase.Email_Address__c;
        userRecord.Account__c=accountRecord.id;
        userRecord.Is_Azure_Active__c = true;
        userRecord.User_Account__c=accountRecord.id;

        insert userRecord;

          String jsonSubmitRequest = '{"email":"userRecord.Email__c","lastName":"lastName","email":"lastName@gg.com"}';
         BCAPP_WebServiceHelper.preLoginOtpFlow(jsonSubmitRequest);
    }
    
    
       @IsTest
    static void testgetBuildings() {
        RestRequest req = new RestRequest();
        req.httpMethod = 'GET';
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        Project__c testProject =BCAPP_TestDataFactory.createProject();
        testProject.isEnabledMIP__c=true;
        insert testProject;
        
        BuildingSection__c testBuildingSection =BCAPP_TestDataFactory.createBuildingSection('Test');
        testBuildingSection.Project__c=testProject.id;
        testBuildingSection.isEnabledMIP__c = true;
        insert testBuildingSection;
        BCAPP_WebServiceHelper.getBuildings(testProject.id, true);
    }
    
      @IsTest
    static void testgetFavourites() {
        RestRequest req = new RestRequest();
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;

        Account accountRecord =BCAPP_TestDataFactory.createAccount('Test Account');
        accountRecord.Azure_UserPrincipal_Id__c='testttt';
        insert accountRecord;
        
        Contact cntRecord= BCAPP_TestDataFactory.createContact(accountRecord.id,'ewew@dasds.com');
        insert cntRecord;
        Service_Contract__c Service_Contract=  BCAPP_TestDataFactory.createServiceContract();
        Service_Contract.Customer_Name__c=accountRecord.id;
        insert Service_Contract;
        
        Case testCase =BCAPP_TestDataFactory.createCase();
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Move In Holiday Homes').getRecordTypeId();
        testCase.RecordTypeId=RecordTypeCaseId;
        testCase.AccountId= accountRecord.id;
        testCase.Move_Out_Date__c=system.today();
        testCase.Email_Address__c='testuser@fff.com';
        insert testCase;
        
        List<User__c> customers = [SELECT Id FROM User__c];
        customers[0].User_Account__c = null;
        update customers;
        User__c userRecord= BCAPP_TestDataFactory.createUser('testttt');
        userRecord.Email__c=testCase.Email_Address__c;
        userRecord.Account__c=accountRecord.id;
        
        userRecord.User_Account__c=accountRecord.id;

        insert userRecord;
        
        Unit__c unit= BCAPP_TestDataFactory.createUnit();
        insert unit;
        testCase.Unit__c=unit.id;
        update testCase;
        
        Unit_Allocation__c unitAllocation= BCAPP_TestDataFactory.createUnitAllocation();
        unitAllocation.Unit__c=unit.id;
        unitAllocation.User__c=userRecord.id;
        unitAllocation.Account__c=accountRecord.id;
        unitAllocation.Is_Favourite_Unit__c=True;
        insert unitAllocation;
        
        
        
        Project__c testProject =BCAPP_TestDataFactory.createProject();
        testProject.isEnabledMIP__c=true;
        insert testProject;
        
        BuildingSection__c testBuildingSection =BCAPP_TestDataFactory.createBuildingSection('Test');
        testBuildingSection.Project__c=testProject.id;
        insert testBuildingSection;
        
        Map<string,string> maprequest=new  Map<string,string>();
        maprequest.put('accountId',accountRecord.Id);
        BCAPP_WebServiceHelper.getFavourites(JSON.serialize(maprequest));
        maprequest.remove('accountId');
        BCAPP_WebServiceHelper.getFavourites(JSON.serialize(maprequest));
    }
    @IsTest
    static void testCreateVacationRequest() {
        RestRequest req = new RestRequest();
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
		Account accountRecord =BCAPP_TestDataFactory.createAccount('Test Account');
        accountRecord.Azure_UserPrincipal_Id__c='testttt';
        insert accountRecord;
        
        Service_Catalog__c testServiceCatalog =BCAPP_TestDataFactory.createServiceCatalog();
        testServiceCatalog.Name = 'Vacation Request';
        insert testServiceCatalog;
        
        Case testCase =BCAPP_TestDataFactory.createCase();
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Move In Holiday Homes').getRecordTypeId();
        testCase.RecordTypeId=RecordTypeCaseId;
        testCase.AccountId= accountRecord.id;
        testCase.Move_Out_Date__c=system.today();
        testCase.Email_Address__c='testuser@fff.com';
        insert testCase;
        
        User__c userRecord= BCAPP_TestDataFactory.createUser('testttt');
        userRecord.Email__c=testCase.Email_Address__c;
        userRecord.Account__c=accountRecord.id;
        
        userRecord.User_Account__c=accountRecord.id;

        insert userRecord;
        
         Unit__c unit= BCAPP_TestDataFactory.createUnit();
        insert unit;
        testCase.Unit__c=unit.id;
        update testCase;
        
        Unit_Allocation__c unitAllocation= BCAPP_TestDataFactory.createUnitAllocation();
        unitAllocation.Unit__c=unit.id;
        unitAllocation.User__c=userRecord.id;
        unitAllocation.Account__c=accountRecord.id;
        unitAllocation.Is_Favourite_Unit__c=True;
        insert unitAllocation;
        
        
        
        Project__c testProject =BCAPP_TestDataFactory.createProject();
        testProject.isEnabledMIP__c=true;
        insert testProject;
        
        BuildingSection__c testBuildingSection =BCAPP_TestDataFactory.createBuildingSection('Test');
        testBuildingSection.Project__c=testProject.id;
        insert testBuildingSection;
        
        Map<string,string> maprequest=new  Map<string,string>();
        maprequest.put('accountId',accountRecord.Id);
        maprequest.put('unitId',unit.Id);
        maprequest.put('emergencyNumber','0123456789');
        maprequest.put('toDate',String.valueOf(Date.today().addDays(-7)));
        maprequest.put('fromDate',String.valueOf(Date.today()));
        Test.startTest();
        BCAPP_WebServiceHelper.createVacationRequest(JSON.serialize(maprequest));
        unit.Legal_Status__c = 'With Legal';
        update unit;
        BCAPP_WebServiceHelper.createVacationRequest(JSON.serialize(maprequest));
        maprequest.remove('accountId');
        BCAPP_WebServiceHelper.createVacationRequest(JSON.serialize(maprequest));
        maprequest.put('unitId','test');
        BCAPP_WebServiceHelper.createVacationRequest(JSON.serialize(maprequest));
        Test.stopTest();
        Id vacationRecTypeId = Utilities.getRecordTypeId('Case','Community General Service Request'); 
        List<Case> vacationCase = [SELECT Id FROM Case WHERE RecordTypeId =: vacationRecTypeId];
        Assert.areEqual(1,vacationCase.size(),'There should be 1 records');

    }
    
    @IsTest
    static void testCreateLoginHistory() {
        RestResponse res = new RestResponse();
        RestContext.response = res;

        // Prepare mock input JSON
        String inputJson = JSON.serialize(new Map<String, Object>{
            'location' => 'New York',
                'ip' => '192.168.1.1',
                'logintime' => '2025-01-11T10:00:00Z',
                'name' => 'John Doe',
                'username' => 'jdoe',
                'email' => 'jdoe@example.com'
                });
        
        Test.startTest();
        BCAPP_WebServiceHelper.createLoginHisory(inputJson);
        Test.stopTest();
        
        
    }
    
     @IsTest
    static void testvalidateMoveInBusinessRule() {
        RestRequest req = new RestRequest();
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;

        Account accountRecord =BCAPP_TestDataFactory.createAccount('Test Account');
        accountRecord.Azure_UserPrincipal_Id__c='testttt';
        insert accountRecord;

        System.debug('--->>>accountRecord.lastName--->>>'+accountRecord.lastName);
        
        Contact cntRecord= BCAPP_TestDataFactory.createContact(accountRecord.id,'ewew@dasds.com');
        insert cntRecord;
        Service_Contract__c Service_Contract=  BCAPP_TestDataFactory.createServiceContract();
        Service_Contract.Customer_Name__c=accountRecord.id;
        insert Service_Contract;
        
        Case testCase =BCAPP_TestDataFactory.createCase();
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Move In Holiday Homes').getRecordTypeId();
        testCase.RecordTypeId=RecordTypeCaseId;
        testCase.AccountId= accountRecord.id;
        testCase.Move_Out_Date__c=system.today();
        testCase.Email_Address__c='testuser@fff.com';
        testCase.Status = 'Assigned';
        insert testCase;
        
        User__c userRecord= BCAPP_TestDataFactory.createUser('testttt');
        userRecord.Email__c=testCase.Email_Address__c;
        userRecord.Account__c=accountRecord.id;
        
        userRecord.User_Account__c=accountRecord.id;


        insert userRecord;
        
        
     
        

        Unit__c unit= BCAPP_TestDataFactory.createUnit();

        insert unit;
        testCase.Unit__c=unit.id;
        update testCase;
        
        Unit_Allocation__c unitAllocation= BCAPP_TestDataFactory.createUnitAllocation();
        unitAllocation.Unit__c=unit.id;
        unitAllocation.User__c=userRecord.id;
        unitAllocation.Account__c=accountRecord.id;
        unitAllocation.Is_Favourite_Unit__c=True;
        insert unitAllocation;
        
        
        
        Project__c testProject =BCAPP_TestDataFactory.createProject();
        testProject.isEnabledMIP__c=true;
        insert testProject;
        
        BuildingSection__c testBuildingSection =BCAPP_TestDataFactory.createBuildingSection('Test');
        testBuildingSection.Project__c=testProject.id;
        insert testBuildingSection;
        BCAPP_WebServiceHelper instance= new BCAPP_WebServiceHelper();
        instance.validateMoveInBusinessRule(unit.id);
        BCAPP_WebServiceHelper.captureLogs('','');
        unit.BuildingSectionName__c=testBuildingSection.id;
        unit.PropertyUsage__c='Residential';
        update unit;
        BCAPP_WebServiceHelper.getUnits(testBuildingSection.id);
          BCAPP_WebServiceHelper.getPendingCases('Test Account');
    }
    
    
    @IsTest
    static void testvalidategetServiceCatalogs() {
        RestResponse res = new RestResponse();
        RestContext.response = res;
        Service_Catalog__c testServiceCatalog =BCAPP_TestDataFactory.createServiceCatalog();
        insert testServiceCatalog;

         Service_Catolog_Documents__c testService_Catolog_Documents =BCAPP_TestDataFactory.createServiceCatalogDocuments();
        testService_Catolog_Documents.Service_Catalog__c=testServiceCatalog.id;
        insert testService_Catolog_Documents;

        ServiceCatalogService.getServiceCatalogAndrelatedDocuments();
        BCAPP_WebServiceHelper.getServiceCatalogs();
    }
    
     @IsTest
    static void testfetchMyPortfolio() {
        RestRequest req = new RestRequest();
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;

        Account accountRecord =BCAPP_TestDataFactory.createAccount('Test Account');
        accountRecord.Azure_UserPrincipal_Id__c='testttt';
        insert accountRecord;
        
        Contact cntRecord= BCAPP_TestDataFactory.createContact(accountRecord.id,'ewew@dasds.com');
        insert cntRecord;
        Service_Contract__c Service_Contract=  BCAPP_TestDataFactory.createServiceContract();
        Service_Contract.Customer_Name__c=accountRecord.id;
        insert Service_Contract;
        
        Case testCase =BCAPP_TestDataFactory.createCase();
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Move In Holiday Homes').getRecordTypeId();
        testCase.RecordTypeId=RecordTypeCaseId;
        testCase.AccountId= accountRecord.id;
        testCase.Move_Out_Date__c=system.today();
        testCase.Email_Address__c='testuser@fff.com';
        insert testCase;
        
        User__c userRecord= BCAPP_TestDataFactory.createUser('testttt');
        userRecord.Email__c=testCase.Email_Address__c;
        userRecord.Account__c=accountRecord.id;
        
        userRecord.User_Account__c=accountRecord.id;

        insert userRecord;
        
        Unit__c unit= BCAPP_TestDataFactory.createUnit();
        insert unit;
        testCase.Unit__c=unit.id;
        update testCase;
        
        Unit_Allocation__c unitAllocation= BCAPP_TestDataFactory.createUnitAllocation();
        unitAllocation.Unit__c=unit.id;
        unitAllocation.User__c=userRecord.id;
        unitAllocation.Account__c=accountRecord.id;
        unitAllocation.Is_Favourite_Unit__c=True;
        insert unitAllocation;
        
        
        
        Project__c testProject =BCAPP_TestDataFactory.createProject();
        testProject.isEnabledMIP__c=true;
        insert testProject;
        
        BuildingSection__c testBuildingSection =BCAPP_TestDataFactory.createBuildingSection('Test');
        testBuildingSection.Project__c=testProject.id;
        insert testBuildingSection;
        
        Map<string,string> maprequest=new  Map<string,string>();
        maprequest.put('accountId',accountRecord.Id);
        BCAPP_WebServiceHelper.fetchMyPortfolio(JSON.serialize(maprequest));
        maprequest.remove('accountId');
        BCAPP_WebServiceHelper.fetchMyPortfolio(JSON.serialize(maprequest));
    }
    
    @IsTest
    static void testupdateProfile() {
        RestRequest req = new RestRequest();
        RestContext.request = req;
        RestResponse res = new RestResponse();
        RestContext.response = res;

        
        Account accountRecord =BCAPP_TestDataFactory.createAccount('Test Account');
        accountRecord.Azure_UserPrincipal_Id__c='testttt';
        insert accountRecord;
        
        Contact cntRecord= BCAPP_TestDataFactory.createContact(accountRecord.id,'ewew@dasds.com');
        insert cntRecord;
        Service_Contract__c Service_Contract=  BCAPP_TestDataFactory.createServiceContract();
        Service_Contract.Customer_Name__c=accountRecord.id;
        insert Service_Contract;
        
        Case testCase =BCAPP_TestDataFactory.createCase();
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Move In Holiday Homes').getRecordTypeId();
        testCase.RecordTypeId=RecordTypeCaseId;
        testCase.AccountId= accountRecord.id;
        testCase.Move_Out_Date__c=system.today();
        testCase.Email_Address__c='testuser@fff.com';
        insert testCase;
        
        List<User__c> userList = [SELECT Id,User_Account__c FROM User__c WHERE User_Account__c = : accountRecord.id];
        if(userList != null && !userList.isEmpty()){
            userList[0].User_Account__c = null;
            update userList;
        }

        User__c userRecord= BCAPP_TestDataFactory.createUser('testttt');
        userRecord.Email__c=testCase.Email_Address__c;
        userRecord.Account__c=accountRecord.id;
        userRecord.Forget_Password_Request_OTP__c = '23232';
        userRecord.User_Account__c=accountRecord.id;

        insert userRecord;
        
        Unit__c unit= BCAPP_TestDataFactory.createUnit();
        insert unit;
        testCase.Unit__c=unit.id;
        update testCase;
        
        Unit_Allocation__c unitAllocation= BCAPP_TestDataFactory.createUnitAllocation();
        unitAllocation.Unit__c=unit.id;
        unitAllocation.User__c=userRecord.id;
        unitAllocation.Account__c=accountRecord.id;
        unitAllocation.Is_Favourite_Unit__c=True;
        insert unitAllocation;
        
        
        
        Project__c testProject =BCAPP_TestDataFactory.createProject();
        testProject.isEnabledMIP__c=true;
        insert testProject;
        
        BuildingSection__c testBuildingSection =BCAPP_TestDataFactory.createBuildingSection('Test');
        testBuildingSection.Project__c=testProject.id;
        insert testBuildingSection;
        
        Map<string,string> maprequest=new  Map<string,string>();
        maprequest.put('accountId',accountRecord.Id);
        maprequest.put('email','email@saS.COM');
        maprequest.put('mobileNumber','23232');
        maprequest.put('otp',userRecord.Forget_Password_Request_OTP__c);
        
        BCAPP_WebServiceHelper.updateProfile(JSON.serialize(maprequest));
        maprequest.put('accountId','EWWEE');
        maprequest.remove('otp');
        BCAPP_WebServiceHelper.updateProfile(JSON.serialize(maprequest));
        maprequest.put('otp','1111');
        BCAPP_WebServiceHelper.updateProfile(JSON.serialize(maprequest));

    }
    
    
    @IsTest
    static void testgetProfile() {
        RestRequest req = new RestRequest();
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;

        Account accountRecord =BCAPP_TestDataFactory.createAccount('Test Account');
        accountRecord.Azure_UserPrincipal_Id__c='testttt';
        insert accountRecord;
        
        Contact cntRecord= BCAPP_TestDataFactory.createContact(accountRecord.id,'ewew@dasds.com');
        insert cntRecord;
        Service_Contract__c Service_Contract=  BCAPP_TestDataFactory.createServiceContract();
        Service_Contract.Customer_Name__c=accountRecord.id;
        insert Service_Contract;
        
        Case testCase =BCAPP_TestDataFactory.createCase();
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Move In Holiday Homes').getRecordTypeId();
        testCase.RecordTypeId=RecordTypeCaseId;
        testCase.AccountId= accountRecord.id;
        testCase.Move_Out_Date__c=system.today();
        testCase.Email_Address__c='testuser@fff.com';
        insert testCase;

        List<User__c> userList = [SELECT Id,User_Account__c FROM User__c WHERE User_Account__c = : accountRecord.id];
        if(userList != null && !userList.isEmpty()){
            userList[0].User_Account__c = null;
            update userList;
        }
        
        
        User__c userRecord= BCAPP_TestDataFactory.createUser('testttt');
        userRecord.Email__c=testCase.Email_Address__c;
        userRecord.Account__c=accountRecord.id;
        //userRecorD.User_Type__c=BCAPP_Constants.TENANT;
        userRecord.User_Account__c=accountRecord.id;

        insert userRecord;
        
        Unit__c unit= BCAPP_TestDataFactory.createUnit();
        insert unit;
        testCase.Unit__c=unit.id;
        update testCase;
        
        Unit_Allocation__c unitAllocation= BCAPP_TestDataFactory.createUnitAllocation();
        unitAllocation.Unit__c=unit.id;
        unitAllocation.User__c=userRecord.id;
        unitAllocation.Account__c=accountRecord.id;
        unitAllocation.Is_Favourite_Unit__c=True;
        insert unitAllocation;
        
        
        
        Project__c testProject =BCAPP_TestDataFactory.createProject();
        testProject.isEnabledMIP__c=true;
        insert testProject;
        
        BuildingSection__c testBuildingSection =BCAPP_TestDataFactory.createBuildingSection('Test');
        testBuildingSection.Project__c=testProject.id;
        insert testBuildingSection;
        
        Map<string,string> maprequest=new  Map<string,string>();
        maprequest.put('accountId',accountRecord.Id);
        maprequest.put('userToken','testttt');

        BCAPP_WebServiceHelper.getProfile(JSON.serialize(maprequest));
        userRecord.User_Type__c=BCAPP_Constants.HOLIDAY_HOMES;
        update userRecord;
        test.StartTest();
        BCAPP_WebServiceHelper.getProfile(JSON.serialize(maprequest));
        userRecord.User_Type__c = 'Security';
        update userRecord;
        BCAPP_WebServiceHelper.getProfile(JSON.serialize(maprequest));
        test.StopTest();


    }
    
    @IsTest
    static void testgetProfileTenant() {
        RestRequest req = new RestRequest();
        RestContext.request = req;
        RestResponse res = new RestResponse();
        RestContext.response = res;

        
        Account accountRecord =BCAPP_TestDataFactory.createAccount('Test Account');
        accountRecord.Azure_UserPrincipal_Id__c='testttt';
        insert accountRecord;
        
        Contact cntRecord= BCAPP_TestDataFactory.createContact(accountRecord.id,'ewew@dasds.com');
        insert cntRecord;
        Service_Contract__c Service_Contract=  BCAPP_TestDataFactory.createServiceContract();
        Service_Contract.Customer_Name__c=accountRecord.id;
        insert Service_Contract;
        
        Case testCase =BCAPP_TestDataFactory.createCase();
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Move In Holiday Homes').getRecordTypeId();
        testCase.RecordTypeId=RecordTypeCaseId;
        testCase.AccountId= accountRecord.id;
        testCase.Move_Out_Date__c=system.today();
        testCase.Email_Address__c='testuser@fff.com';
        insert testCase;
        
        User__c userRecord= BCAPP_TestDataFactory.createUser('testttt');
        userRecord.Email__c=testCase.Email_Address__c;
        userRecord.Account__c=accountRecord.id;
        userRecorD.User_Type__c=BCAPP_Constants.TENANT;
        userRecord.User_Account__c=accountRecord.id;
        
        insert userRecord;
        
        Unit__c unit= BCAPP_TestDataFactory.createUnit();
        insert unit;
        testCase.Unit__c=unit.id;
        update testCase;
        
        Unit_Allocation__c unitAllocation= BCAPP_TestDataFactory.createUnitAllocation();
        unitAllocation.Unit__c=unit.id;
        unitAllocation.User__c=userRecord.id;
        unitAllocation.Account__c=accountRecord.id;
        unitAllocation.Is_Favourite_Unit__c=True;
        insert unitAllocation;
        
        
        
        Project__c testProject =BCAPP_TestDataFactory.createProject();
        testProject.isEnabledMIP__c=true;
        insert testProject;
        
        BuildingSection__c testBuildingSection =BCAPP_TestDataFactory.createBuildingSection('Test');
        testBuildingSection.Project__c=testProject.id;
        insert testBuildingSection;
        
        Map<string,string> maprequest=new  Map<string,string>();
        maprequest.put('accountId',accountRecord.Id);
        maprequest.put('userToken','testttt');
        
        BCAPP_WebServiceHelper.getProfile(JSON.serialize(maprequest));
        
        
    }

    static void testgetProfileSecurity() {
        RestRequest req = new RestRequest();
        RestContext.request = req;
        RestResponse res = new RestResponse();
        RestContext.response = res;

        
        Account accountRecord =BCAPP_TestDataFactory.createAccount('Test Account');
        accountRecord.Azure_UserPrincipal_Id__c='testttt';
        insert accountRecord;
        
        Contact cntRecord= BCAPP_TestDataFactory.createContact(accountRecord.id,'ewew@dasds.com');
        insert cntRecord;
        Service_Contract__c Service_Contract=  BCAPP_TestDataFactory.createServiceContract();
        Service_Contract.Customer_Name__c=accountRecord.id;
        insert Service_Contract;
        
        Case testCase =BCAPP_TestDataFactory.createCase();
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Move In Holiday Homes').getRecordTypeId();
        testCase.RecordTypeId=RecordTypeCaseId;
        testCase.AccountId= accountRecord.id;
        testCase.Move_Out_Date__c=system.today();
        testCase.Email_Address__c='testuser@fff.com';
        insert testCase;
        
        User__c userRecord= BCAPP_TestDataFactory.createUser('testttt');
        userRecord.Email__c=testCase.Email_Address__c;
        userRecord.Account__c=accountRecord.id;
        userRecorD.User_Type__c='Security';
        userRecord.User_Account__c=accountRecord.id;
        
        insert userRecord;
        
        Unit__c unit= BCAPP_TestDataFactory.createUnit();
        insert unit;
        testCase.Unit__c=unit.id;
        update testCase;
        
        Unit_Allocation__c unitAllocation= BCAPP_TestDataFactory.createUnitAllocation();
        unitAllocation.Unit__c=unit.id;
        unitAllocation.User__c=userRecord.id;
        unitAllocation.Account__c=accountRecord.id;
        unitAllocation.Is_Favourite_Unit__c=True;
        insert unitAllocation;
        
        
        
        Project__c testProject =BCAPP_TestDataFactory.createProject();
        testProject.isEnabledMIP__c=true;
        insert testProject;
        
        BuildingSection__c testBuildingSection =BCAPP_TestDataFactory.createBuildingSection('Test');
        testBuildingSection.Project__c=testProject.id;
        insert testBuildingSection;
        
        Map<string,string> maprequest=new  Map<string,string>();
        maprequest.put('accountId',accountRecord.Id);
        maprequest.put('userToken','testttt');
        
        BCAPP_WebServiceHelper.getProfile(JSON.serialize(maprequest));
        
        
    }
    
    
    @IsTest
    static void testcreateDocument() {
        RestRequest req = new RestRequest();
        RestContext.request = req;
        RestResponse res = new RestResponse();
        RestContext.response = res;

        
        Account accountRecord =BCAPP_TestDataFactory.createAccount('Test Account');
        accountRecord.Azure_UserPrincipal_Id__c='testttt';
        insert accountRecord;
        
        Contact cntRecord= BCAPP_TestDataFactory.createContact(accountRecord.id,'ewew@dasds.com');
        insert cntRecord;
        Service_Contract__c Service_Contract=  BCAPP_TestDataFactory.createServiceContract();
        Service_Contract.Customer_Name__c=accountRecord.id;
        insert Service_Contract;
        
        Case testCase =BCAPP_TestDataFactory.createCase();
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Move In Holiday Homes').getRecordTypeId();
        testCase.RecordTypeId=RecordTypeCaseId;
        testCase.AccountId= accountRecord.id;
        testCase.Move_Out_Date__c=system.today();
        testCase.Email_Address__c='testuser@fff.com';
        insert testCase;
        
        User__c userRecord= BCAPP_TestDataFactory.createUser('testttt');
        userRecord.Email__c=testCase.Email_Address__c;
        userRecord.Account__c=accountRecord.id;
        userRecorD.User_Type__c=BCAPP_Constants.TENANT;
        userRecord.User_Account__c=accountRecord.id;
        
        insert userRecord;
        
        Unit__c unit= BCAPP_TestDataFactory.createUnit();
        insert unit;
        testCase.Unit__c=unit.id;
        update testCase;
        
        Unit_Allocation__c unitAllocation= BCAPP_TestDataFactory.createUnitAllocation();
        unitAllocation.Unit__c=unit.id;
        unitAllocation.User__c=userRecord.id;
        unitAllocation.Account__c=accountRecord.id;
        unitAllocation.Is_Favourite_Unit__c=True;
        insert unitAllocation;
        
        
        
        Project__c testProject =BCAPP_TestDataFactory.createProject();
        testProject.isEnabledMIP__c=true;
        insert testProject;
        
        BuildingSection__c testBuildingSection =BCAPP_TestDataFactory.createBuildingSection('Test');
        testBuildingSection.Project__c=testProject.id;
        insert testBuildingSection;
        
        Map<string,string> maprequest=new  Map<string,string>();
        maprequest.put('accountId',accountRecord.Id);
        maprequest.put('srId',testCase.id);
        
        Service_Catalog__c testServiceCatalog =BCAPP_TestDataFactory.createServiceCatalog();
        insert testServiceCatalog;
        maprequest.put('sCatalogDocId',testServiceCatalog.id);
        Service_Catolog_Documents__c testService_Catolog_Documents =BCAPP_TestDataFactory.createServiceCatalogDocuments();
        testService_Catolog_Documents.Service_Catalog__c=testServiceCatalog.id;
        insert testService_Catolog_Documents;
        maprequest.put('sCatalogDocId',testService_Catolog_Documents.Id);
        maprequest.put('fileName',testService_Catolog_Documents.Id);
        maprequest.put('fileContent','324324');

        
        
        try{   
        BCAPP_WebServiceHelper.createDocument(JSON.serialize(maprequest));
        BCAPP_WebServiceHelper.createDocument(null);
        }catch(exception e){}
        Customer_Document__c custDocs=BCAPP_TestDataFactory.createCustomerDocument();
        custDocs.Service_Catolog_Documents__c = testService_Catolog_Documents.Id;
        custDocs.Case__c = testCase.id;
        insert custDocs;
        BCAPP_WebServiceHelper instance=new BCAPP_WebServiceHelper();
        instance.isAnyDocumentMissingFile(new List<Customer_Document__c>{custDocs});
        
        Map<string,string> maprequestDocs=new  Map<string,string>();
        maprequest.put('userType','Holiday Home');

        BCAPP_WebServiceHelper.getRequestDocuments(JSON.serialize(maprequest)); 
        BCAPP_WebServiceHelper.getRequestDocuments(null);

    }
    
     @IsTest
    static void testgetServiceRequestDetails() {
        RestRequest req = new RestRequest();
        RestContext.request = req;
        RestResponse res = new RestResponse();
        RestContext.response = res;

        
        Account accountRecord =BCAPP_TestDataFactory.createAccount('Test Account');
        accountRecord.Azure_UserPrincipal_Id__c='testttt';
        insert accountRecord;
        
        Contact cntRecord= BCAPP_TestDataFactory.createContact(accountRecord.id,'ewew@dasds.com');
        insert cntRecord;
        Service_Contract__c Service_Contract=  BCAPP_TestDataFactory.createServiceContract();
        Service_Contract.Customer_Name__c=accountRecord.id;
        insert Service_Contract;
        
        Case testCase =BCAPP_TestDataFactory.createCase();
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Move In Holiday Homes').getRecordTypeId();
        testCase.RecordTypeId=RecordTypeCaseId;
        testCase.AccountId= accountRecord.id;
        testCase.Move_Out_Date__c=system.today();
        testCase.Email_Address__c='testuser@fff.com';
        testCase.User_Type__c=BCAPP_Constants.TENANT;
        insert testCase;
        
        User__c userRecord= BCAPP_TestDataFactory.createUser('testttt');
        userRecord.Email__c=testCase.Email_Address__c;
        userRecord.Account__c=accountRecord.id;
        userRecorD.User_Type__c=BCAPP_Constants.TENANT;
        userRecord.User_Account__c=accountRecord.id;
        
        insert userRecord;
        
        Unit__c unit= BCAPP_TestDataFactory.createUnit();
        insert unit;
        testCase.Unit__c=unit.id;
        update testCase;
        
        Unit_Allocation__c unitAllocation= BCAPP_TestDataFactory.createUnitAllocation();
        unitAllocation.Unit__c=unit.id;
        unitAllocation.User__c=userRecord.id;
        unitAllocation.Account__c=accountRecord.id;
        unitAllocation.Is_Favourite_Unit__c=True;
        insert unitAllocation;
        
        
        
        Project__c testProject =BCAPP_TestDataFactory.createProject();
        testProject.isEnabledMIP__c=true;
        insert testProject;
        
        BuildingSection__c testBuildingSection =BCAPP_TestDataFactory.createBuildingSection('Test');
        testBuildingSection.Project__c=testProject.id;
        insert testBuildingSection;
        
        Map<string,string> maprequest=new  Map<string,string>();
        maprequest.put('accountId',accountRecord.Id);
        maprequest.put('srId',testCase.id);
        
        Service_Catalog__c testServiceCatalog =BCAPP_TestDataFactory.createServiceCatalog();
        insert testServiceCatalog;
        testCase.Service_Catalog__c=testServiceCatalog.id;
        update testCase;
        Service_Catolog_Documents__c testService_Catolog_Documents =BCAPP_TestDataFactory.createServiceCatalogDocuments();
        testService_Catolog_Documents.Service_Catalog__c=testServiceCatalog.id;
        insert testService_Catolog_Documents;
       
        
        Map<string,string> maprequestDocs=new  Map<string,string>();
        maprequest.put('reqId',testCase.id);
        
        Service_Catalog_Fields__c testServiceCatalogFields =BCAPP_TestDataFactory.createserviceCatalogFields();
        testServiceCatalogFields.Service_Catalog__c=testServiceCatalog.id;
        insert testServiceCatalogFields;
        
        BCAPP_WebServiceHelper.getServiceRequestDetails(JSON.serialize(maprequest));
    }
    
      @IsTest
    static void testgetUserRequests() {
        RestRequest req = new RestRequest();
        RestContext.request = req;
        RestResponse res = new RestResponse();
        RestContext.response = res;

        
        Account accountRecord =BCAPP_TestDataFactory.createAccount('Test Account');
        accountRecord.Azure_UserPrincipal_Id__c='testttt';
        insert accountRecord;
        
        Contact cntRecord= BCAPP_TestDataFactory.createContact(accountRecord.id,'ewew@dasds.com');
        insert cntRecord;
        Service_Contract__c Service_Contract=  BCAPP_TestDataFactory.createServiceContract();
        Service_Contract.Customer_Name__c=accountRecord.id;
        insert Service_Contract;
        
        Case testCase =BCAPP_TestDataFactory.createCase();
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Move In Holiday Homes').getRecordTypeId();
        testCase.RecordTypeId=RecordTypeCaseId;
        testCase.AccountId= accountRecord.id;
        testCase.Move_Out_Date__c=system.today();
        testCase.Email_Address__c='testuser@fff.com';
        testCase.User_Type__c=BCAPP_Constants.TENANT;
        insert testCase;

        List<User__c> userList = [SELECT Id,User_Account__c FROM User__c WHERE User_Account__c = : accountRecord.id];
        for(User__c u : userList){
            u.User_Account__c = null;
        }
        update userList;

        
        
        User__c userRecord= BCAPP_TestDataFactory.createUser('testttt');
        userRecord.Email__c=testCase.Email_Address__c;
        userRecord.Account__c=accountRecord.id;
        userRecorD.User_Type__c=BCAPP_Constants.TENANT;
        userRecord.User_Account__c=accountRecord.id;
        
        insert userRecord;
        
        Unit__c unit= BCAPP_TestDataFactory.createUnit();
        insert unit;
        testCase.Unit__c=unit.id;
        update testCase;
        
        Unit_Allocation__c unitAllocation= BCAPP_TestDataFactory.createUnitAllocation();
        unitAllocation.Unit__c=unit.id;
        unitAllocation.User__c=userRecord.id;
        unitAllocation.Account__c=accountRecord.id;
        unitAllocation.Is_Favourite_Unit__c=True;
        insert unitAllocation;
        
        
        
        Project__c testProject =BCAPP_TestDataFactory.createProject();
        testProject.isEnabledMIP__c=true;
        insert testProject;
        
        BuildingSection__c testBuildingSection =BCAPP_TestDataFactory.createBuildingSection('Test');
        testBuildingSection.Project__c=testProject.id;
        insert testBuildingSection;
        
        Map<string,string> maprequest=new  Map<string,string>();
        maprequest.put('accountId',accountRecord.Id);
        maprequest.put('srId',testCase.id);
        maprequest.put('unitId',unit.id);
        maprequest.put('status','Submitted');
        maprequest.put('requestType','accesscardrequests');
        maprequest.put('pendingCases','false');
        
        Service_Catalog__c testServiceCatalog =BCAPP_TestDataFactory.createServiceCatalog();
        testServiceCatalog.Name = 'Access Card';
        insert testServiceCatalog;
        testCase.Service_Catalog__c=testServiceCatalog.id;
        testCase.Status = 'Submitted';
        update testCase;
        Service_Catolog_Documents__c testService_Catolog_Documents =BCAPP_TestDataFactory.createServiceCatalogDocuments();
        testService_Catolog_Documents.Service_Catalog__c=testServiceCatalog.id;
        insert testService_Catolog_Documents;
       
        
        Map<string,string> maprequestDocs=new  Map<string,string>();
        maprequest.put('reqId',testCase.id);
        
        Service_Catalog_Fields__c testServiceCatalogFields =BCAPP_TestDataFactory.createserviceCatalogFields();
        testServiceCatalogFields.Service_Catalog__c=testServiceCatalog.id;
        insert testServiceCatalogFields;
        
        BCAPP_WebServiceHelper.getUserRequests(JSON.serialize(maprequest));
        testServiceCatalog.Name = 'Move In';
        update testServiceCatalog;
        BCAPP_WebServiceHelper.getUserRequests(JSON.serialize(maprequest));
        maprequest.remove('requestType');
        BCAPP_WebServiceHelper.getUserRequests(JSON.serialize(maprequest));
        BCAPP_WebServiceHelper.getUserRequests(null);

    }
    
     @IsTest
    static void testaccountDocuments() {
        RestRequest req = new RestRequest();
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;

        Account accountRecord =BCAPP_TestDataFactory.createAccount('Test Account');
        accountRecord.Azure_UserPrincipal_Id__c='testttt';
        insert accountRecord;
        
        Contact cntRecord= BCAPP_TestDataFactory.createContact(accountRecord.id,'ewew@dasds.com');
        insert cntRecord;
        Service_Contract__c Service_Contract=  BCAPP_TestDataFactory.createServiceContract();
        Service_Contract.Customer_Name__c=accountRecord.id;
        insert Service_Contract;
        
        Case testCase =BCAPP_TestDataFactory.createCase();
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Move In Holiday Homes').getRecordTypeId();
        testCase.RecordTypeId=RecordTypeCaseId;
        testCase.AccountId= accountRecord.id;
        testCase.Move_Out_Date__c=system.today();
        testCase.Email_Address__c='testuser@fff.com';
        testCase.User_Type__c=BCAPP_Constants.TENANT;
        insert testCase;
        
        User__c userRecord= BCAPP_TestDataFactory.createUser('testttt');
        userRecord.Email__c=testCase.Email_Address__c;
        userRecord.Account__c=accountRecord.id;
        userRecorD.User_Type__c=BCAPP_Constants.TENANT;
        userRecord.User_Account__c=accountRecord.id;
        
        insert userRecord;
        
        Unit__c unit= BCAPP_TestDataFactory.createUnit();
        insert unit;
        testCase.Unit__c=unit.id;
        update testCase;
        
        Unit_Allocation__c unitAllocation= BCAPP_TestDataFactory.createUnitAllocation();
        unitAllocation.Unit__c=unit.id;
        unitAllocation.User__c=userRecord.id;
        unitAllocation.Account__c=accountRecord.id;
        unitAllocation.Is_Favourite_Unit__c=True;
        insert unitAllocation;
        
        
        
        Project__c testProject =BCAPP_TestDataFactory.createProject();
        testProject.isEnabledMIP__c=true;
        insert testProject;
        
        BuildingSection__c testBuildingSection =BCAPP_TestDataFactory.createBuildingSection('Test');
        testBuildingSection.Project__c=testProject.id;
        insert testBuildingSection;
        
        Map<string,string> maprequest=new  Map<string,string>();
        maprequest.put('accountId',accountRecord.Id);
        maprequest.put('srId',testCase.id);
        
        Service_Catalog__c testServiceCatalog =BCAPP_TestDataFactory.createServiceCatalog();
        insert testServiceCatalog;
        testCase.Service_Catalog__c=testServiceCatalog.id;
        update testCase;
        Service_Catolog_Documents__c testService_Catolog_Documents =BCAPP_TestDataFactory.createServiceCatalogDocuments();
        testService_Catolog_Documents.Service_Catalog__c=testServiceCatalog.id;
        insert testService_Catolog_Documents;
       
        
        Map<string,string> maprequestDocs=new  Map<string,string>();
        maprequest.put('reqId',testCase.id);
        
        Service_Catalog_Fields__c testServiceCatalogFields =BCAPP_TestDataFactory.createserviceCatalogFields();
        testServiceCatalogFields.Service_Catalog__c=testServiceCatalog.id;
        insert testServiceCatalogFields;
        
        Customer_Document__c custDocs=BCAPP_TestDataFactory.createCustomerDocument();
        custDocs.Service_Catolog_Documents__c = testService_Catolog_Documents.Id;
        custDocs.Account__c = accountRecord.Id;
        insert custDocs;
        
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDoc.pdf',
            VersionData = Blob.valueOf('Test content'),
            IsMajorVersion = true
        );
        insert contentVersion;
        
        ContentVersion insertedVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
        String contentDocumentId = insertedVersion.ContentDocumentId;
        
        ContentDocumentLink documentLink = new ContentDocumentLink(
            ContentDocumentId = contentDocumentId,
            LinkedEntityId = custDocs.Id,
            ShareType = 'V', // Viewer access
            Visibility = 'AllUsers'
        );
        insert documentLink;
        
        BCAPP_WebServiceHelper.accountDocuments(JSON.serialize(maprequest));
    }

    
     @IsTest
    static void testvalidateEmailOTPTemp() {
        
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/bloomholdingsWebService/V1/getProjects?param1=value1&param2=value2';
        req.httpMethod = 'GET';
        RestContext.request = req;
                
        RestResponse res = new RestResponse();
        RestContext.response = res;

        Account accountRecord =BCAPP_TestDataFactory.createAccount('Test Account');
        accountRecord.Azure_UserPrincipal_Id__c='testttt';
        accountRecord.Tenant__c=true;
        insert accountRecord;
        
        Contact cntRecord= BCAPP_TestDataFactory.createContact(accountRecord.id,'ewew@dasds.com');
        insert cntRecord;
        Service_Contract__c Service_Contract=  BCAPP_TestDataFactory.createServiceContract();
        Service_Contract.Customer_Name__c=accountRecord.id;
        insert Service_Contract;
        
        Case testCase =BCAPP_TestDataFactory.createCase();
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Move In Holiday Homes').getRecordTypeId();
        testCase.RecordTypeId=RecordTypeCaseId;
        testCase.AccountId= accountRecord.id;
        testCase.Move_Out_Date__c=system.today();
        testCase.Email_Address__c='testuser@fff.com';
        insert testCase;

        List<User__c> userList = [SELECT Id,User_Account__c FROM User__c WHERE User_Account__c = : accountRecord.id];
        if(userList != null && !userList.isEmpty()){
            userList[0].User_Account__c = null;
            update userList;
        }
        
        User__c userRecord= BCAPP_TestDataFactory.createUser('testttt');
        userRecord.Email__c=testCase.Email_Address__c;
        userRecord.Account__c=accountRecord.id;
        userRecorD.User_Type__c=BCAPP_Constants.TENANT;
        userRecord.User_Account__c=accountRecord.id;
        userRecord.Forget_Password_Request_OTP__c='22222';
        insert userRecord;
        
        Unit__c unit= BCAPP_TestDataFactory.createUnit();
        insert unit;
        testCase.Unit__c=unit.id;
        update testCase;
        
        Unit_Allocation__c unitAllocation= BCAPP_TestDataFactory.createUnitAllocation();
        unitAllocation.Unit__c=unit.id;
        unitAllocation.User__c=userRecord.id;
        unitAllocation.Account__c=accountRecord.id;
        unitAllocation.Is_Favourite_Unit__c=True;
        insert unitAllocation;
        
        
        
        Project__c testProject =BCAPP_TestDataFactory.createProject();
        testProject.isEnabledMIP__c=true;
        insert testProject;
        
        BuildingSection__c testBuildingSection =BCAPP_TestDataFactory.createBuildingSection('Test');
        testBuildingSection.Project__c=testProject.id;
        insert testBuildingSection;
        
        Map<string,string> maprequest=new  Map<string,string>();
        maprequest.put('accountId',accountRecord.Id);
        maprequest.put('srId',testCase.id);
        
        Service_Catalog__c testServiceCatalog =BCAPP_TestDataFactory.createServiceCatalog();
        insert testServiceCatalog;
        
        Service_Catolog_Documents__c testService_Catolog_Documents =BCAPP_TestDataFactory.createServiceCatalogDocuments();
        testService_Catolog_Documents.Service_Catalog__c=testServiceCatalog.id;
        insert testService_Catolog_Documents;
        maprequest.put('sCatalogDocId',testService_Catolog_Documents.Id);
        maprequest.put('fileName',testService_Catolog_Documents.Id);
        maprequest.put('fileContent','324324');

        maprequest.put('otp', '22222');
        maprequest.put('email', '3232@ASD.COM');
        maprequest.put('accountId', accountRecord.Id);
        maprequest.put('type', 'Profile Update');
        maprequest.put('messaging', 'mobile');

        
        try{   
            
            
            BCAPP_WebServiceHelper.sendOTPToVerifyEmailTemp(JSON.serialize(maprequest));
            BCAPP_WebServiceHelper.sendOTPToVerifyEmailTemp(null);

            userRecord.Forget_Password_Request_OTP__c='22222';
            update userRecord;
            BCAPP_WebServiceHelper.validateEmailOTPTemp(JSON.serialize(maprequest));  
            BCAPP_WebServiceHelper.validateEmailOTPTemp(null);

            
            maprequest.put('messaging', 'email');
            userRecord.Forget_Password_Request_OTP__c='22222';
            update userRecord;
            BCAPP_WebServiceHelper.sendOTPToVerifyEmailTemp(JSON.serialize(maprequest));
            userRecord.Forget_Password_Request_OTP__c='22222';
            update userRecord;
            BCAPP_WebServiceHelper.validateEmailOTPTemp(JSON.serialize(maprequest));

        }catch(exception e){}
         
    }
    
      @IsTest
    static void testvalidateEmailOTPTempHH() {
        Test.startTest();
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/bloomholdingsWebService/V1/getProjects?param1=value1&param2=value2';
        req.httpMethod = 'GET';
        RestContext.request = req;
                
        RestResponse res = new RestResponse();
        RestContext.response = res;

        Account accountRecord =BCAPP_TestDataFactory.createAccount('Test Account');
        accountRecord.Azure_UserPrincipal_Id__c='testttt';
        accountRecord.Holiday_Homes__c=true;
        insert accountRecord;
        
        Contact cntRecord= BCAPP_TestDataFactory.createContact(accountRecord.id,'ewew@dasds.com');
        insert cntRecord;
        Service_Contract__c Service_Contract=  BCAPP_TestDataFactory.createServiceContract();
        Service_Contract.Customer_Name__c=accountRecord.id;
        insert Service_Contract;
        
        Case testCase =BCAPP_TestDataFactory.createCase();
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Move In Holiday Homes').getRecordTypeId();
        testCase.RecordTypeId=RecordTypeCaseId;
        testCase.AccountId= accountRecord.id;
        testCase.Move_Out_Date__c=system.today();
        testCase.Email_Address__c='testuser@fff.com';
        insert testCase;
        
        List<User__c> userList = [SELECT Id,User_Account__c FROM User__c WHERE User_Account__c = : accountRecord.id];
        if(userList != null && !userList.isEmpty()){
            userList[0].User_Account__c = null;
            update userList;
        }

        User__c userRecord= BCAPP_TestDataFactory.createUser('testttt');
        userRecord.Email__c=testCase.Email_Address__c;
        userRecord.Account__c=accountRecord.id;
        userRecorD.User_Type__c='Holiday Homes';
        userRecord.User_Account__c=accountRecord.id;
        userRecord.Forget_Password_Request_OTP__c='22222';
        insert userRecord;
        
        Unit__c unit= BCAPP_TestDataFactory.createUnit();
        insert unit;
        testCase.Unit__c=unit.id;
        update testCase;
        
        Unit_Allocation__c unitAllocation= BCAPP_TestDataFactory.createUnitAllocation();
        unitAllocation.Unit__c=unit.id;
        unitAllocation.User__c=userRecord.id;
        unitAllocation.Account__c=accountRecord.id;
        unitAllocation.Is_Favourite_Unit__c=True;
        insert unitAllocation;
        
        
        
        Project__c testProject =BCAPP_TestDataFactory.createProject();
        testProject.isEnabledMIP__c=true;
        insert testProject;
        
        BuildingSection__c testBuildingSection =BCAPP_TestDataFactory.createBuildingSection('Test');
        testBuildingSection.Project__c=testProject.id;
        insert testBuildingSection;
        
        Map<string,string> maprequest=new  Map<string,string>();
        maprequest.put('accountId',accountRecord.Id);
        maprequest.put('srId',testCase.id);
        
        Service_Catalog__c testServiceCatalog =BCAPP_TestDataFactory.createServiceCatalog();
        insert testServiceCatalog;
        
        Service_Catolog_Documents__c testService_Catolog_Documents =BCAPP_TestDataFactory.createServiceCatalogDocuments();
        testService_Catolog_Documents.Service_Catalog__c=testServiceCatalog.id;
        insert testService_Catolog_Documents;
        maprequest.put('sCatalogDocId',testService_Catolog_Documents.Id);
        maprequest.put('fileName',testService_Catolog_Documents.Id);
        maprequest.put('fileContent','324324');

        maprequest.put('otp', '22222');
        maprequest.put('email', '3232@ASD.COM');
        maprequest.put('accountId', accountRecord.Id);
        maprequest.put('type', 'Profile Update');
        maprequest.put('messaging', 'mobile');

        
        try{   
            
            
            BCAPP_WebServiceHelper.sendOTPToVerifyEmailTemp(JSON.serialize(maprequest));
            BCAPP_WebServiceHelper.sendOTPToVerifyEmailTemp(null);

            userRecord.Forget_Password_Request_OTP__c='22222';
            update userRecord;
            BCAPP_WebServiceHelper.validateEmailOTPTemp(JSON.serialize(maprequest));  
            BCAPP_WebServiceHelper.validateEmailOTPTemp(null);

            
            maprequest.put('messaging', 'email');
            userRecord.Forget_Password_Request_OTP__c='22222';
            update userRecord;
            BCAPP_WebServiceHelper.sendOTPToVerifyEmailTemp(JSON.serialize(maprequest));
            userRecord.Forget_Password_Request_OTP__c='22222';
            update userRecord;
            BCAPP_WebServiceHelper.validateEmailOTPTemp(JSON.serialize(maprequest));

        }catch(exception e){}
          Test.StopTest();
    }
    
    
    @IsTest
    static void testcustomerFeedback() {
        
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/bloomholdingsWebService/V1/getProjects?param1=value1&param2=value2';
        req.httpMethod = 'GET';
        RestContext.request = req;
                
        RestResponse res = new RestResponse();
        RestContext.response = res;

        Account accountRecord =BCAPP_TestDataFactory.createAccount('Test Account');
        accountRecord.Azure_UserPrincipal_Id__c='testttt';
        accountRecord.Tenant__c=true;
        insert accountRecord;
               Map<string,object> maprequest=new  Map<string,object>();
        maprequest.put('accountId', accountRecord.Id);
        maprequest.put('rating', 5);
        maprequest.put('feedback', 'test');

        

            BCAPP_WebServiceHelper.customerFeedback(JSON.serialize(maprequest));

         
    }
    
    
    @IsTest
    static void testgetNotices() {
        
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/bloomholdingsWebService/V1/getProjects?param1=value1&param2=value2';
        req.httpMethod = 'GET';
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        Project__c testProject =BCAPP_TestDataFactory.createProject();
        insert testProject;
        Notifications__c testNotifications =BCAPP_TestDataFactory.createNotifications();
        testNotifications.Project__c= testProject.id;
        testNotifications.RecordTypeId= SObjectType.Notifications__c.getRecordTypeInfosByDeveloperName().get('Events').getRecordTypeId(); 
        insert testNotifications;
        
        
        Map<string,string> maprequest=new  Map<string,string>();
        maprequest.put('projectId', testProject.id);
        maprequest.put('type', 'events');

        
        BCAPP_WebServiceHelper.getNotices(JSON.serialize(maprequest));
        BCAPP_WebServiceHelper.getNotificationsOptions(JSON.serialize(maprequest));

        
    }
    
    @IsTest
    static void testcreateServiceRequest() {
        
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/bloomholdingsWebService/V1/getProjects?param1=value1&param2=value2';
        req.httpMethod = 'GET';
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
         Account accountRecord =BCAPP_TestDataFactory.createAccount('Test Account');
        accountRecord.Azure_UserPrincipal_Id__c='testttt';
        accountRecord.Tenant__c=true;
        insert accountRecord;
        
        Contact cntRecord= BCAPP_TestDataFactory.createContact(accountRecord.id,'ewew@dasds.com');
        insert cntRecord;
        Service_Contract__c Service_Contract=  BCAPP_TestDataFactory.createServiceContract();
        Service_Contract.Customer_Name__c=accountRecord.id;
        insert Service_Contract;
        
        Case testCase =BCAPP_TestDataFactory.createCase();
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Move In Holiday Homes').getRecordTypeId();
        testCase.RecordTypeId=RecordTypeCaseId;
        testCase.AccountId= accountRecord.id;
        testCase.Move_Out_Date__c=system.today();
        testCase.Email_Address__c='testuser@fff.com';
        insert testCase;
        
        User__c userRecord= BCAPP_TestDataFactory.createUser('testttt');
        userRecord.Email__c=testCase.Email_Address__c;
        userRecord.Account__c=accountRecord.id;
        userRecorD.User_Type__c=BCAPP_Constants.TENANT;
        userRecord.User_Account__c=accountRecord.id;
        userRecord.Forget_Password_Request_OTP__c='22222';
        insert userRecord;
        
        Unit__c unit= BCAPP_TestDataFactory.createUnit();
        insert unit;
        testCase.Unit__c=unit.id;
        update testCase;
        
        Unit_Allocation__c unitAllocation= BCAPP_TestDataFactory.createUnitAllocation();
        unitAllocation.Unit__c=unit.id;
        unitAllocation.User__c=userRecord.id;
        unitAllocation.Account__c=accountRecord.id;
        unitAllocation.Is_Favourite_Unit__c=True;
        insert unitAllocation;
        
        
        
        Project__c testProject =BCAPP_TestDataFactory.createProject();
        testProject.isEnabledMIP__c=true;
        insert testProject;
        
        BuildingSection__c testBuildingSection =BCAPP_TestDataFactory.createBuildingSection('Test');
        testBuildingSection.Project__c=testProject.id;
        insert testBuildingSection;
        
        Service_Catalog__c testServiceCatalog =BCAPP_TestDataFactory.createServiceCatalog();
        insert testServiceCatalog;
        
        Service_Catolog_Documents__c testService_Catolog_Documents =BCAPP_TestDataFactory.createServiceCatalogDocuments();
        testService_Catolog_Documents.Service_Catalog__c=testServiceCatalog.id;
        insert testService_Catolog_Documents;
 
        
        
        Map<string,string> maprequest=new  Map<string,string>();
        maprequest.put('accountId', accountRecord.id);
        maprequest.put('unitId', unit.id);
        maprequest.put('srCategory', '');

        BCAPP_WebServiceHelper.createServiceRequest(JSON.serialize(maprequest));

        
    }
    
    @IsTest
    static void testgetAccessPermitOptions() {
      
        RestRequest req = new RestRequest();
        req.httpMethod = 'GET';
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        Map<string,string> maprequest=new  Map<string,string>();
        maprequest.put('type', 'category');
        BCAPP_WebServiceHelper.getAccessPermitOptions(JSON.serialize(maprequest));
        
        maprequest.put('type', 'service');
        BCAPP_WebServiceHelper.getAccessPermitOptions(JSON.serialize(maprequest));
        
        
        maprequest.put('type', 'validity');
        BCAPP_WebServiceHelper.getAccessPermitOptions(JSON.serialize(maprequest));
        
        
        maprequest.put('type', 'sr_category');
        BCAPP_WebServiceHelper.getAccessPermitOptions(JSON.serialize(maprequest));
        
        maprequest.put('type', 'status');
        BCAPP_WebServiceHelper.getAccessPermitOptions(JSON.serialize(maprequest));
        
        maprequest.put('type', 'requestType');
        BCAPP_WebServiceHelper.getAccessPermitOptions(JSON.serialize(maprequest));



    }
    
    @IsTest
    static void testupdateServiceRequest() {
        
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/bloomholdingsWebService/V1/getProjects?param1=value1&param2=value2';
        req.httpMethod = 'GET';
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
         Account accountRecord =BCAPP_TestDataFactory.createAccount('Test Account');
        accountRecord.Azure_UserPrincipal_Id__c='testttt';
        accountRecord.Tenant__c=true;
        insert accountRecord;
     
        Case testCase =BCAPP_TestDataFactory.createCase();
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Move In Holiday Homes').getRecordTypeId();
        testCase.RecordTypeId=RecordTypeCaseId;
        testCase.AccountId= accountRecord.id;
        testCase.Move_Out_Date__c=system.today();
        testCase.Email_Address__c='testuser@fff.com';
        insert testCase;
        

        
        Map<string,string> maprequest=new  Map<string,string>();
        maprequest.put('srId', testCase.id);
        maprequest.put('status','Approved');
        maprequest.put('comments', 'tesr');
        maprequest.put('isFavorite', 'true');

        BCAPP_WebServiceHelper.updateServiceRequest(JSON.serialize(maprequest));

       
    }
}