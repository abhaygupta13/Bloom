@isTest
public class PdfGeneratorControllerSampleTest {

        
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
            Account__c = acc.Id
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
    public static void testGeneratePdfMoveIn() {
        // Step 1: Create a RecordType for 'Move In'
        RecordType moveInRecordType = [SELECT Id FROM RecordType WHERE Name = 'Move In' LIMIT 1];

        // Step 2: Create a Case record with 'Move In' RecordType
        Case caseRecord = new Case(
            RecordTypeId = moveInRecordType.Id,
            Subject = 'Test Case for Move In'
        );
        insert caseRecord;

        // Step 3: Call the generatePdf method
        Test.startTest();
        Blob pdfContent = PdfGeneratorControllerSample.generatePdf(caseRecord.Id);
        
        Test.stopTest();

    }

    @isTest
    public static void testGeneratePdfAccessPermit() {
        // Step 1: Create a RecordType for 'Access Permit'
        RecordType accessPermitRecordType = [SELECT Id FROM RecordType WHERE Name = 'Access Permit' LIMIT 1];

        // Step 2: Create a Case record with 'Access Permit' RecordType
        Case caseRecord = new Case(
            RecordTypeId = accessPermitRecordType.Id,
            Subject = 'Test Case for Access Permit'
        );
        insert caseRecord;

        // Step 3: Call the generatePdf method
        Test.startTest();
        Blob pdfContent = PdfGeneratorControllerSample.generatePdf(caseRecord.Id);
        Test.stopTest();

    }

    @isTest
    public static void testGeneratePdfMoveOut() {
        // Step 1: Create a RecordType for 'Move Out'
        RecordType moveOutRecordType = [SELECT Id FROM RecordType WHERE Name = 'Move Out' LIMIT 1];

        // Step 2: Create a Case record with 'Move Out' RecordType
        Case caseRecord = new Case(
            RecordTypeId = moveOutRecordType.Id,
            Subject = 'Test Case for Move Out'
        );
        insert caseRecord;

        // Step 3: Call the generatePdf method
        Test.startTest();
        Blob pdfContent = PdfGeneratorControllerSample.generatePdf(caseRecord.Id);
        Test.stopTest();

    }
    @isTest
    public static void testGenerateSitePdf() {
         RecordType moveInRecordType = [SELECT Id FROM RecordType WHERE Name = 'Move In' LIMIT 1];
        Case testCase = new Case(
            Subject = 'Test Case for PDF generation',
            Status = 'Approved',
            RecordTypeId = moveInRecordType.Id
        );
        insert testCase;
        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        // Step 3: Call the method under test
		Blob pdfSiteContent = PdfGeneratorControllerSample.generateSitePdf(testCase.Id);
       
        Test.stopTest();
    }
    
    @isTest
    public static void testAccessPermitEmailHelperQueuable() {

   	  Id personRecId =Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        
        Account testAccount = new Account();
        testAccount.LastName__pc = 'Test class Account';
        testAccount.LastName = 'Test class Account';
        testAccount.PersonEmail='aaa@abc.com';
        testAccount.PersonMobilePhone='123456789';
        testAccount.RecordTypeId = personRecId;
        insert testAccount;

        Case case1 = new Case(
            Status = 'Approved',
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Access Permit').getRecordTypeId()
          );
        insert case1;
         Case case2 = new Case(
            Status = 'Approved',
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Access Permit').getRecordTypeId(),
             ParentId = case1.Id,AccountId=testAccount.Id
          );
        insert case2;
        
        
        Test.startTest();
        accessPermitEmailHelperQueuable queueableJob = new accessPermitEmailHelperQueuable(new List<Case>{case2});
        System.enqueueJob(queueableJob);
        Test.stopTest(); 
     
    }


    class MockHttpResponseGenerator implements HttpCalloutMock {
    	public HTTPResponse respond(HTTPRequest req) {
        // Create a mock response with a sample access token
        HTTPResponse res = new HTTPResponse();
        res.setStatusCode(200);
        res.setBody('{"access_token": "mockedAccessToken"}');
        return res;
    }
    }
}