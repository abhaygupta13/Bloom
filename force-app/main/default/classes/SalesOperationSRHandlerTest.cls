@isTest
private class SalesOperationSRHandlerTest {

    @testSetup
    static void setupTestData() {

       Account acc = TestDataFactory.createBrokerAccount('test', false, '1122334455');
	   insert acc;

	   Contact con = TestDataFactory.createContact('lname', acc.Id, true, 'test@gmail.com');
       insert con;

        Project__c project = new Project__c(Name = 'Test Project');
        insert project;

        Unit__c unit = new Unit__c(Name = 'Test Unit', Project__c = project.Id);
        insert unit;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(10),
            AccountId = acc.Id
        );
        insert opp;

        SalesOrder__c so = new SalesOrder__c(
            Name = 'Test SO',
            Account__c = acc.Id,
            Unit__c = unit.Id
            
        );
        insert so;

        ServiceCatalog__c sc = new ServiceCatalog__c(
            Name = 'Sales Operation Service',
            Type__c = 'Service Request',
            Category__c = 'Sales Operation Service',
            SubCategory__c = 'Sales Operation',
            RecordTypeDevName__c = 'SalesOperationService'
        );
        insert sc;

      
        Id rtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('SalesOperationService').getRecordTypeId();

        Case cs = new Case(
            Status = 'New',
            Origin = 'Phone',
            AccountId = acc.Id,
            RecordTypeId = rtId,
            ServiceCatalog__c = sc.Id,
            Unit__c = unit.Id,
            Subject = 'Test Case'
        );
        insert cs;
    }

    static Case getDummyCase() {
        return [SELECT Id, Step__c, AccountId, Unit__c, Sales_Order__c, SubType__c, ServiceCatalog__c, Status 
                FROM Case LIMIT 1];
    }

    
    @isTest
    static void testGetInstance() {
        Test.startTest();
        SalesOperationSRHandler handler = SalesOperationSRHandler.getInstance();
        System.assertNotEquals(null, handler);
        Test.stopTest();
    }


    
    @isTest
    static void testValidateEligibility() {
        SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
        Case c = getDummyCase();

        Test.startTest();
        String result = SalesOperationSRHandler.getInstance().validateEligibility(so, c);
        Test.stopTest();

        System.assertEquals(null, result);
    }

   
    @isTest
    static void testCreateCaseRecord_WithSalesOrder() {

        SalesOrder__c so = [
            SELECT Id, Account__c, Unit__c, Project__c,
                   Account__r.Name, Account__r.Id,
                   Account__r.isPersonAccount,
                   Account__r.PersonMobilePhone,
                   Unit__r.Name
            FROM SalesOrder__c LIMIT 1
        ];

        ServiceCatalog__c sc = [
            SELECT Id, RecordTypeDevName__c, SubCategory__c
            FROM ServiceCatalog__c LIMIT 1
        ];

        Test.startTest();
        Case newCase = SalesOperationSRHandler.getInstance().createCaseRecord(
            so, sc, null, null, 'Service Request', 'Test Desc', 'Web'
        );
        Test.stopTest();

        System.assertNotEquals(null, newCase);
        System.assertEquals('New', newCase.Status);
        System.assertEquals('Web', newCase.Origin);
    }

    
    @isTest
    static void testCreateCaseRecord_WithoutSalesOrder() {

        ServiceCatalog__c sc = [
            SELECT Id, RecordTypeDevName__c, SubCategory__c
            FROM ServiceCatalog__c LIMIT 1
        ];

        Account acc = [SELECT Id FROM Account LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];

        Test.startTest();
        Case newCase = SalesOperationSRHandler.getInstance().createCaseRecord(
            null, sc, acc.Id, unit.Id, 'Service Request', 'No SO', 'Email'
        );
        Test.stopTest();

        System.assertNotEquals(null, newCase);
        System.assertEquals('New', newCase.Status);
        System.assertEquals('Email', newCase.Origin);
    }

    

    
    @isTest
    static void testValidateCaseForNextReview_Null() {

        Test.startTest();
        Map<String, Object> res = SalesOperationSRHandler.getInstance()
            .validateCaseForNextReview(null);
        Test.stopTest();

        System.assertEquals('error', res.get('status'));
        System.assertEquals('Invalid Case ID.', res.get('message'));
    }

  
    @isTest
    static void testValidateCase_InvalidStep() {

        Case c = getDummyCase();
        c.Step__c = '0';
        update c;

        Test.startTest();
        Map<String, Object> res = SalesOperationSRHandler.getInstance()
            .validateCaseForNextReview(c);
        Test.stopTest();

        System.assertEquals('error', res.get('status'));
        System.assertEquals('Invalid Case Step.', res.get('message'));
    }

   
}