@isTest
private class BCAPP_CreateOwnerUsersBatchTest {

    @isTest
    static void testBatchExecution() {
        
        
        // Step 1: Set up mock data
        List<Account> accounts = new List<Account>();
        
        // Create test accounts with necessary fields
        for (Integer i = 0; i < 2; i++) {
            Account acc = new Account();
            acc.FirstName = 'Test';
            acc.LastName = 'Owner' + i;
            acc.PersonEmail = 'testowner' + i + '@example.com';
            acc.Create_User__c = true;
            acc.owner__c = true;
            accounts.add(acc);
        }

        // Insert the accounts
        insert accounts;
        
         
        SalesOrder__c order1 = new SalesOrder__c(
            Name = 'Test SalesOrder',
            Account__c = accounts[0].Id,
            Status__c = 'Booked'
        );
        SalesOrder__c order2 = new SalesOrder__c(
            Name = 'Test SalesOrder T',
            Account__c = accounts[1].Id,
            Status__c = 'Booked'
        );
        insert new List<SalesOrder__c>{order1, order2};
         Project__c testProject = BCAPP_TestDataFactory.createProject();
        testProject.isEnabledMIP__c = true;
        testProject.Name='Bloom Gardens';
        insert testProject;
        

        Unit__c unit1 = new Unit__c(Project__c = testProject.Id, Name = 'Test001', Active_Sales_Order__c = order1.Id);
        Unit__c unit2 = new Unit__c(Project__c = testProject.Id, Name = 'Test002', Active_Sales_Order__c = order2.Id);
        insert new List<Unit__c>{unit1, unit2};
 
        // Step 2: Mock HTTP response for the callout
        Test.startTest();
        
        // Set the mock response for HTTP callouts
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        try{
        // Step 3: Execute the batch class
        BCAPP_CreateOwnerUsersBatch batch = new BCAPP_CreateOwnerUsersBatch();
        Id batchId = Database.executeBatch(batch, 5); // Use a small batch size for testing
        }catch(exception e){
            
        }
       
        Test.stopTest();
    }

    // Mock response generator for HTTP callouts
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            // Create a mock response
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"id": "mockId", "userPrincipalName": "mockuser@example.com"}');
            return res;
        }
    }
}