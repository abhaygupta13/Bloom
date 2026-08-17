@isTest
private class BAPPAssignUnassignUnitHandlerTest {
	@testSetup static void setup() {
        Project__c projectObj = TestDataFactory.createProject('Test Project', Date.newinstance(2025, 01, 01), Date.newInstance(2025, 01, 15), Date.newInstance(2025, 01, 20), Date.newInstance(2025, 01, 25), Date.newInstance(2025, 01, 30), Date.newInstance(2025, 02, 01));
		insert projectObj;
        
        //Available Unit - Apartment
        Unit__c unitObj1 = TestDataFactory.createUnit(projectObj.Id, 'Test Unit 1', 'Available');
        unitObj1.UnitNumber__c='1111';
        unitObj1.UnitModel__c='2BHK';
        unitObj1.UnitType__c='Apartment';
        unitObj1.WebFloorPlan__c='testFloorPlan';
        unitObj1.isPublic__c=false;
        unitObj1.StartDate__c=Date.today().addDays(-1);
        unitObj1.Project__c=projectObj.Id;
        insert unitObj1;
        
        //In-Progress Unit - Villa
        Unit__c unitObj2 = TestDataFactory.createUnit(projectObj.Id, 'Test Unit 2', 'In-Progress');
        unitObj2.UnitNumber__c='2222';
        unitObj2.UnitModel__c='1BHK';
        unitObj2.UnitType__c='Villa';
        unitObj2.WebFloorPlan__c='testFloorPlan';
        unitObj2.isPublic__c=false;
        unitObj2.StartDate__c=Date.today().addDays(-1);
        unitObj2.Project__c=projectObj.Id;
        unitObj2.SellingPrice__c = 200000.10;
        unitObj2.LockedBy__c = UserInfo.getUserId();
        insert unitObj2;
        
        
        //Available Unit - Villa
        Unit__c unitObj3 = TestDataFactory.createUnit(projectObj.Id, 'Test Unit 3', 'Available');
        unitObj3.UnitNumber__c='3333';
        unitObj3.UnitModel__c='3BHK';
        unitObj3.UnitType__c='Villa';
        unitObj3.WebFloorPlan__c='testFloorPlan';
        unitObj3.isPublic__c=false;
        unitObj3.StartDate__c=Date.today().addDays(-1);
        unitObj3.Project__c=projectObj.Id;
        unitObj3.SellingPrice__c = 300000.10;
        insert unitObj3;
        
        //Available Unit - Public
        Unit__c unitObj4 = TestDataFactory.createUnit(projectObj.Id, 'Test Unit 4', 'Available');
        unitObj4.UnitNumber__c='4444';
        unitObj4.UnitModel__c='3BHK';
        unitObj4.UnitType__c='Villa';
        unitObj4.WebFloorPlan__c='testFloorPlan';
        unitObj4.isPublic__c=true;
        unitObj4.StartDate__c=Date.today().addDays(-1);
        unitObj4.Project__c=projectObj.Id;
        unitObj4.SellingPrice__c = 300000.10;
        insert unitObj4;
        
        //Create Broker Account 1
        Account brokerAccount1 = TestDataFactory.createBrokerAccount('Test Broker Account 1', false, '1111999911');
        insert brokerAccount1;
        
        //Create Broker Account 2
        Account brokerAccount2 = TestDataFactory.createBrokerAccount('Test Broker Account 2', false, '1111999222');
        insert brokerAccount2;

        Id brokerContactRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Broker').getRecordTypeId();
        
        //Create Broker Contact 1 : For Broker Account 1 - Admin
        Contact brokerContact1 = TestDataFactory.createBrokerContact('Test Contact 1', brokerAccount1.Id, false, false, true,'testContact1@test.com');
        brokerContact1.BrokerContactRole__c = 'Admin';
        brokerContact1.RecordTypeId = brokerContactRecordTypeId;
        insert brokerContact1;
        System.debug('Test >> objBrokerContact1 INSERT >> '+brokerContact1.Id);

        //Create Broker Contact 2 : For Broker Account 1 - Agent
        Contact brokerContact2 = TestDataFactory.createBrokerContact('Test Contact 2', brokerAccount1.Id, false, false, true,'testContact2@test.com');
        brokerContact2.BrokerContactRole__c = 'Agent';
        brokerContact2.RecordTypeId = brokerContactRecordTypeId;
        insert brokerContact2;
        System.debug('Test >> objBrokerContact2 INSERT >> '+brokerContact2.Id);

        //Create Broker Contact 3 : For Broker Account 2 - Admin
        Contact brokerContact3 = TestDataFactory.createBrokerContact('Test Contact 3', brokerAccount2.Id, false, false, true,'testContact3@test.com');
        brokerContact3.BrokerContactRole__c = 'Admin';
        brokerContact3.RecordTypeId = brokerContactRecordTypeId;
        insert brokerContact3;
        
        //Create Broker Contact 4 : For Broker Account 2 - Agent
        Contact brokerContact4 = TestDataFactory.createBrokerContact('Test Contact 4', brokerAccount2.Id, false, false, true,'testContact4@test.com');
        brokerContact4.BrokerContactRole__c = 'Agent';
        brokerContact4.RecordTypeId = brokerContactRecordTypeId;
        insert brokerContact4;
        
        //Create Broker Contact 5 : For Broker Account 1 - Agent 2
        Contact brokerContact5 = TestDataFactory.createBrokerContact('Test Contact 5', brokerAccount1.Id, false, false, true,'testContact5@test.com');
        brokerContact5.BrokerContactRole__c = 'Agent';
        brokerContact5.RecordTypeId = brokerContactRecordTypeId;
        insert brokerContact5;

        
		//Create Broker Unit Allocation 1 : For Broker Account 1 and Unit 1     
        BrokerUnitAllocations__c brokerUnitAllocation1 = TestDataFactory.createBrokerUnitAllocation(brokerAccount1.Id, unitObj1.Id, true);
        insert brokerUnitAllocation1;
        
		//Create Broker Unit Allocation 2 : For Broker Account 1 and Unit 2
        BrokerUnitAllocations__c brokerUnitAllocation2 = TestDataFactory.createBrokerUnitAllocation(brokerAccount1.Id, unitObj2.Id, true);
        insert brokerUnitAllocation2;

       	//Create Broker Unit Allocation 3 : For Broker Account 2 and Unit 3
        BrokerUnitAllocations__c brokerUnitAllocation3 = TestDataFactory.createBrokerUnitAllocation(brokerAccount2.Id, unitObj3.Id, true);
        insert brokerUnitAllocation3;
        
        //Create Broker Unit Assignment 1 : For Broker Account 1 - Admin
        BrokerUnitAssignment__c brokerUnitAssignment1 = TestDataFactory.createBrokerUnitAssignment(brokerUnitAllocation1.Id, brokerContact1.Id, true);
        insert brokerUnitAssignment1;
        
        //Create Broker Unit Assignment 2 : For Broker Account 1 - Agent
        BrokerUnitAssignment__c brokerUnitAssignment2 = TestDataFactory.createBrokerUnitAssignment(brokerUnitAllocation1.Id, brokerContact2.Id, true);
        insert brokerUnitAssignment2; 
        
        //Create Broker Unit Assignment 3 : For Broker Account 2 - Admin
        BrokerUnitAssignment__c brokerUnitAssignment3 = TestDataFactory.createBrokerUnitAssignment(brokerUnitAllocation1.Id, brokerContact3.Id, true);
        insert brokerUnitAssignment3; 
        
        //Create Broker Unit Assignment 4 : For Broker Account 2 - Agent
        BrokerUnitAssignment__c brokerUnitAssignment4 = TestDataFactory.createBrokerUnitAssignment(brokerUnitAllocation3.Id, brokerContact4.Id, false);
        insert brokerUnitAssignment4; 
   
    }
    @isTest
    static void testAssignUnit() {
     	//Get Broker Account
        Account objBrokerAccount1 = [Select Id from Account where name = 'Test Broker Account 1']; 
        
        //Get Broker Contact 1 - Admin
        Contact objBrokerContact1 = [Select Id from Contact where lastname = 'Test Contact 1' ];
        System.debug('Test >> objBrokerContact Admin >> '+objBrokerContact1.Id);
        
        //Get Broker Contact 1 - Agent
        Contact objBrokerContact2 = [Select Id from Contact where lastname = 'Test Contact 5' ];
        System.debug('Test >> objBrokerContact Agent>> '+objBrokerContact2.Id);
        
        //Get Project
        Project__c objProject = [Select Id from Project__c where name='Test Project'];
        
        BrokerUnitAllocations__c objBrokerUnitAllocation = [Select Id from BrokerUnitAllocations__c where Account__c=:objBrokerAccount1.Id and Unit__r.UnitNumber__c = '1111'];
            
       	// Prepare JSON request body
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'accountId' => objBrokerAccount1.Id,
            'contactId' => objBrokerContact1.Id,
            'brokerUnitAssignments' => new List<Object>{
                new Map<String, Object>{
                    'brokerUnitAllocationRecordId' => objBrokerUnitAllocation.Id,
                    'contactIds' => new List<String>{ objBrokerContact2.Id }
                }
            },
            'unassignBrokerUnitAssignmentRecordIds' => new List<String>{ '' }
        });

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestUri = '/services/apexrest/brokerAppWebService/V1/unitAssignment';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(jsonBody);

        try {
            Test.startTest();
            BAPPWebService.doPost();
            Test.stopTest();
        } catch (Exception e) {
            system.debug('Catch >> CustomException >>' +e.getMessage());
        }
    }
    
    @isTest
    static void testAssignUnitForInactiveAssignment() {
     	//Get Broker Account
        Account objBrokerAccount1 = [Select Id from Account where name = 'Test Broker Account 2']; 
        
        //Get Broker Contact 1 - Admin
        Contact objBrokerContact1 = [Select Id from Contact where lastname = 'Test Contact 3' ];
        System.debug('Test >> objBrokerContact Admin >> '+objBrokerContact1.Id);
        
        //Get Broker Contact 2 - Agent
        Contact objBrokerContact2 = [Select Id from Contact where lastname = 'Test Contact 4' ];
        System.debug('Test >> objBrokerContact Agent>> '+objBrokerContact2.Id);
        
        //Get Project
        Project__c objProject = [Select Id from Project__c where name='Test Project'];
        
        BrokerUnitAllocations__c objBrokerUnitAllocation = [Select Id from BrokerUnitAllocations__c where Account__c=:objBrokerAccount1.Id and Unit__r.UnitNumber__c = '3333'];
        System.debug('CHECK Allocation Id - Method>> '+objBrokerUnitAllocation);    
       	// Prepare JSON request body
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'accountId' => objBrokerAccount1.Id,
            'contactId' => objBrokerContact1.Id,
            'brokerUnitAssignments' => new List<Object>{
                new Map<String, Object>{
                    'brokerUnitAllocationRecordId' => objBrokerUnitAllocation.Id,
                    'contactIds' => new List<String>{ objBrokerContact2.Id }
                }
            },
            'unassignBrokerUnitAssignmentRecordIds' => new List<String>{ '' }
        });

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestUri = '/services/apexrest/brokerAppWebService/V1/unitAssignment';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(jsonBody);

        try {
            Test.startTest();
            BAPPWebService.doPost();
            Test.stopTest();
        } catch (Exception e) {
            system.debug('Catch >> CustomException >>' +e.getMessage());
        }
    }
    
    @isTest
    static void testInvalidContactAndAccountRelationship() {
     	//Get Broker Account
        Account objBrokerAccount1 = [Select Id from Account where name = 'Test Broker Account 1']; 
        
        //Get Broker Account
        Account objBrokerAccount2 = [Select Id from Account where name = 'Test Broker Account 2']; 
        
        //Get Broker Contact 1 - Admin
        Contact objBrokerContact1 = [Select Id from Contact where lastname = 'Test Contact 3' ];
        System.debug('Test >> objBrokerContact Admin >> '+objBrokerContact1.Id);
        
        //Get Broker Contact 1 - Agent
        Contact objBrokerContact2 = [Select Id from Contact where lastname = 'Test Contact 4' ];
        System.debug('Test >> objBrokerContact Agent>> '+objBrokerContact2.Id);
        
        //Get Project
        Project__c objProject = [Select Id from Project__c where name='Test Project'];
        
        BrokerUnitAllocations__c objBrokerUnitAllocation = [Select Id from BrokerUnitAllocations__c where Account__c=:objBrokerAccount2.Id and Unit__r.UnitNumber__c = '3333'];
            
       	// Prepare JSON request body
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'accountId' => objBrokerAccount1.Id,
            'contactId' => objBrokerContact1.Id,
            'brokerUnitAssignments' => new List<Object>{
                new Map<String, Object>{
                    'brokerUnitAllocationRecordId' => objBrokerUnitAllocation.Id,
                    'contactIds' => new List<String>{ objBrokerContact2.Id }
                }
            },
            'unassignBrokerUnitAssignmentRecordIds' => new List<String>{ '' }
        });

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestUri = '/services/apexrest/brokerAppWebService/V1/unitAssignment';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(jsonBody);

        try {
            Test.startTest();
            BAPPWebService.doPost();
            Test.stopTest();
        } catch (Exception e) {
            system.debug('Catch >> CustomException >>' +e.getMessage());
        }
    }
    
    @isTest
    static void testInvalidRole() {
     	//Get Broker Account
        Account objBrokerAccount1 = [Select Id from Account where name = 'Test Broker Account 2']; 
        
        //Get Broker Contact 1 - Admin
        Contact objBrokerContact1 = [Select Id from Contact where lastname = 'Test Contact 3' ];
        System.debug('Test >> objBrokerContact Admin >> '+objBrokerContact1.Id);
        
        //Get Broker Contact 1 - Agent
        Contact objBrokerContact2 = [Select Id from Contact where lastname = 'Test Contact 4' ];
        System.debug('Test >> objBrokerContact Agent>> '+objBrokerContact2.Id);
        
        //Get Project
        Project__c objProject = [Select Id from Project__c where name='Test Project'];
        
        BrokerUnitAllocations__c objBrokerUnitAllocation = [Select Id from BrokerUnitAllocations__c where Account__c=:objBrokerAccount1.Id and Unit__r.UnitNumber__c = '3333'];
            
       	// Prepare JSON request body
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'accountId' => objBrokerAccount1.Id,
            'contactId' => objBrokerContact2.Id,
            'brokerUnitAssignments' => new List<Object>{
                new Map<String, Object>{
                    'brokerUnitAllocationRecordId' => objBrokerUnitAllocation.Id,
                    'contactIds' => new List<String>{ objBrokerContact2.Id }
                }
            },
            'unassignBrokerUnitAssignmentRecordIds' => new List<String>{ '' }
        });

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestUri = '/services/apexrest/brokerAppWebService/V1/unitAssignment';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(jsonBody);

        try {
            Test.startTest();
            BAPPWebService.doPost();
            Test.stopTest();
        } catch (Exception e) {
            system.debug('Catch >> CustomException >>' +e.getMessage());
        }
    }
    
    @isTest
    static void testUnassign() {
     	//Get Broker Account 1
        Account objBrokerAccount1 = [Select Id from Account where name = 'Test Broker Account 2']; 
        
        //Get Broker Account
        Account objBrokerAccount = [Select Id from Account where name = 'Test Broker Account 1']; 
        
        //Get Broker Contact 1 - Admin
        Contact objBrokerContact1 = [Select Id from Contact where lastname = 'Test Contact 3' ];
        System.debug('Test >> objBrokerContact Admin >> '+objBrokerContact1.Id);
        
        //Get Broker Contact 1 - Agent
        Contact objBrokerContact2 = [Select Id from Contact where lastname = 'Test Contact 4' ];
        System.debug('Test >> objBrokerContact Agent>> '+objBrokerContact2.Id);
        
        //Get Project
        Project__c objProject = [Select Id from Project__c where name='Test Project'];
        
        //Account 2 related
        BrokerUnitAllocations__c objBrokerUnitAllocation = [Select Id from BrokerUnitAllocations__c where Account__c=:objBrokerAccount1.Id and Unit__r.UnitNumber__c = '3333'];
        
        //Account 1 related
        BrokerUnitAllocations__c objBrokerUnitAllocation2 = [Select Id from BrokerUnitAllocations__c where Account__c=:objBrokerAccount.Id and Unit__r.UnitNumber__c = '1111'];
        
        //BrokerUnitAssignment related to Agency 1 Agent
        BrokerUnitAssignment__c objBrokerUnitAssignment = [Select Id from BrokerUnitAssignment__c where BrokerUnitAllocation__c=:objBrokerUnitAllocation2.Id and Contact__r.LastName = 'Test Contact 2' LIMIT 1];
        
       	// Prepare JSON request body
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'accountId' => objBrokerAccount1.Id,
            'contactId' => objBrokerContact2.Id,
            'brokerUnitAssignments' => new List<Object>{
                new Map<String, Object>{
                    'brokerUnitAllocationRecordId' => objBrokerUnitAllocation.Id,
                    'contactIds' => new List<String>{ objBrokerContact2.Id }
                }
            },
            'unassignBrokerUnitAssignmentRecordIds' => new List<String>{ objBrokerUnitAssignment.id }
        });

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestUri = '/services/apexrest/brokerAppWebService/V1/unitAssignment';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(jsonBody);

        try {
            Test.startTest();
            BAPPWebService.doPost();
            Test.stopTest();
        } catch (Exception e) {
            system.debug('Catch >> CustomException >>' +e.getMessage());
        }
    }
    @isTest
    static void testmissingAccountOrContactInRequest() {
     	//Get Broker Account 1
        Account objBrokerAccount1 = [Select Id from Account where name = 'Test Broker Account 2']; 
        
        //Get Broker Account
        Account objBrokerAccount = [Select Id from Account where name = 'Test Broker Account 1']; 
        
        //Get Broker Contact 1 - Admin
        Contact objBrokerContact1 = [Select Id from Contact where lastname = 'Test Contact 3' ];
        System.debug('Test >> objBrokerContact Admin >> '+objBrokerContact1.Id);
        
        //Get Broker Contact 1 - Agent
        Contact objBrokerContact2 = [Select Id from Contact where lastname = 'Test Contact 4' ];
        System.debug('Test >> objBrokerContact Agent>> '+objBrokerContact2.Id);
        
        //Get Project
        Project__c objProject = [Select Id from Project__c where name='Test Project'];
        
        //Account 2 related
        BrokerUnitAllocations__c objBrokerUnitAllocation = [Select Id from BrokerUnitAllocations__c where Account__c=:objBrokerAccount1.Id and Unit__r.UnitNumber__c = '3333'];
        
        //Account 1 related
        BrokerUnitAllocations__c objBrokerUnitAllocation2 = [Select Id from BrokerUnitAllocations__c where Account__c=:objBrokerAccount.Id and Unit__r.UnitNumber__c = '1111'];
        
        //BrokerUnitAssignment related to Agency 1 Agent
        BrokerUnitAssignment__c objBrokerUnitAssignment = [Select Id from BrokerUnitAssignment__c where BrokerUnitAllocation__c=:objBrokerUnitAllocation2.Id and Contact__r.LastName = 'Test Contact 2' LIMIT 1];
        
       	// Prepare JSON request body
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'accountId' => objBrokerAccount1.Id,
            'contactId' => '',
            'brokerUnitAssignments' => new List<Object>{
                new Map<String, Object>{
                    'brokerUnitAllocationRecordId' => objBrokerUnitAllocation.Id,
                    'contactIds' => new List<String>{ objBrokerContact2.Id }
                }
            },
            'unassignBrokerUnitAssignmentRecordIds' => new List<String>{ objBrokerUnitAssignment.id }
        });

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestUri = '/services/apexrest/brokerAppWebService/V1/unitAssignment';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(jsonBody);

        try {
            Test.startTest();
            BAPPWebService.doPost();
            Test.stopTest();
        } catch (Exception e) {
            system.debug('Catch >> CustomException >>' +e.getMessage());
        }
    }
}