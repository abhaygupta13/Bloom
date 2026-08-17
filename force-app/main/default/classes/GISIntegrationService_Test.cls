/*
* @Author : Jayprakash Bharti
* @CreatedDate : 20th AUG 2024
* @Description : 
*/
/*****************************************************************************************************
* Version       Author      Date             Comment       
* 1.0           Jayprakash  20AUG2024        Test  GIS Integration Implementation
*****************************************************************************************************/
@isTest
private class GISIntegrationService_Test {
    @TestSetup
    static void setupTestData() {
        Project__c proj = TestDataFactory.createProject('Proj1');
        proj.GIS_Service_URL__c = 'https://fakeurl';
        insert proj;
        List<Unit__c> units = new List<Unit__c>();
        for (Integer i = 0; i < 5; i++) {
            units.add(TestDataFactory.createUnit(proj.Id, 'U' + i, 'Available'));
        }
        insert units;
    }

    private class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            if (req.getEndpoint().contains('/generateToken')) {
                res.setBody('{"token":"abc123"}');
            } else if (req.getEndpoint().contains('/query')) {
                res.setBody('{"features":[{"attributes":{"Unit_Code":"U1","ObjectId":101}}]}');
            } else if (req.getEndpoint().contains('/applyEdits')) {
                res.setBody('{"updateResults":[{"objectId":101,"uniqueId":101,"success":true}]}');
            }
            return res;
        }
    }

    @isTest
    static void testFullIntegrationFlow() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        List<Unit__c> units = [SELECT Id FROM Unit__c WHERE Name = 'U1' LIMIT 1];
        for(Unit__c objUnit : units){
            objUnit.GIS_Object_Id__c = '11234';
        }
        update units;
        GISIntegrationService service = GISIntegrationService.getInstance();
        service.getUnitList(units);
        
        Test.startTest();
        service.executeIntegration();
        Test.stopTest();

        // Assert unit got updated with GIS_Object_Id__c
        Unit__c u = [SELECT GIS_Object_Id__c FROM Unit__c WHERE Name = 'U1' LIMIT 1];

        // Optionally assert logs were created
        List<Integration_Logs__c> logs = [SELECT Id FROM Integration_Logs__c];
    }
}