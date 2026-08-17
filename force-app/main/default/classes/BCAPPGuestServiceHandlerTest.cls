@isTest
public class BCAPPGuestServiceHandlerTest {

    @testSetup
    static void setupData() {
        Test.startTest();
        Project__c project = new Project__c(Name = 'Test Project');
        insert project;
        
        BuildingSection__c  phase = new BuildingSection__c (
            Name = 'Phase 1',
            Project__c = project.Id,
            BuildingSectionCode__c = 'BL-CAS'
        );
        insert phase;
        
        
        Unit__c unit = new Unit__c(
            Name = 'Unit 101',
            Project__c = project.Id,
            BuildingSectionName__c  = phase.Id
        );
        insert unit;
        

        // Setup Service Catalog
        Service_Catalog__c serviceCatalog = new Service_Catalog__c(
            Name = BCAPP_Constants.GUEST_MGMT
        );
        insert serviceCatalog;
		 Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // Create a custom User record (user__c)
        user__c customUser = new user__c(
            Name = 'Test User', 
            Email__c = 'testuser@example.com', 
            user_account__c = acc.Id,
            Username__c = 'testuser@example.com'
        );
        insert customUser;
	
        Unit_Allocation__c unitAllocation= BCAPP_TestDataFactory.createUnitAllocation();
        unitAllocation.Unit__c=unit.id;
        unitAllocation.User__c=customUser.id;
        unitAllocation.Account__c=acc.id;
        insert unitAllocation;
        Test.stopTest();
    }

    @isTest
    static void testHandleSubmit_NewGuestRequest() {
        // Fetch test unit
        Unit__c unit = [SELECT Id, project__c FROM Unit__c LIMIT 1];
        Service_Catalog__c catalog = [SELECT Id FROM Service_Catalog__c WHERE Name = :BCAPP_Constants.GUEST_MGMT LIMIT 1];

        // Build the guest info
        List<Object> guestList = new List<Object>{
            new Map<String, Object>{
                'name' => 'Guest1.pdf',
                'document' => EncodingUtil.base64Encode(Blob.valueOf('sampledoc'))
            }
        };

        // Build the request map
        Map<String, Object> requestMap = new Map<String, Object>{
            'unitId' => unit.Id,
            'accountId' => [select Id from Account].Id, 
            'type' => 'new',
            'fromDate' => '01-Oct-2026',
            'toDate' => '15-Oct-2026',
            'guests' => guestList
        };
		RestResponse res = new RestResponse();
        RestContext.response = res;


        Test.startTest();
         Test.setMock(HttpCalloutMock.class, new WebServiceMockResponse());
        BCAPP_GeneralServiceRequestHelper.manageGuestRequest(JSON.serialize(requestMap));
        Test.stopTest();

        List<Case> submitted = [SELECT Id, Status FROM Case WHERE Status = 'Submitted'];
        System.assertEquals(1, submitted.size(), 'Expected one Guest Request to be submitted');
    }
    
    public class WebServiceMockResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"success", "data":{}}');
            return res;
        }
    }
}