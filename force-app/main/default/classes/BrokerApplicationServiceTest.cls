/*
* @Author      : Rushikesh Jadhav
* @CreatedDate : 09th JUNE 2025
* @Description : Test class for BrokerApplicationService, validating functionality such as fetching,
*                updating, and resetting BrokerApplication__c data and escalation date calculations.
*/
/*****************************************************************************************************
* Version   Author           Date           Comment
* 1.0       Rushikesh        09-JUN-2025    Initial draft - Covers unit tests for broker application fetch,
*                                           update, Drawloop field handling, and escalation date calculation.
*****************************************************************************************************/
@isTest
private class BrokerApplicationServiceTest {

    static BrokerApplication__c createMockApplication() {
        TestDataFactory.createBrokerApplication('Test Agency', 'Domestic');
        return [SELECT Id, Name, ApplicationNumber__c, Drawloop_Next_1__c FROM BrokerApplication__c WHERE Name = 'Test Agency' LIMIT 1];
    }

    @isTest
    static void testGetApplicationById() {
        BrokerApplication__c app = createMockApplication();
        Test.startTest();
        BrokerApplication__c result = BrokerApplicationService.getInstance().getApplicationById(app.Id);
        Test.stopTest();
        System.assertNotEquals(null, result, 'Should return application for valid Id');
    }

    @isTest
    static void testGetBrokerApplicationByNumber() {
        BrokerApplication__c app = createMockApplication();
        String appNumber = [SELECT ApplicationNumber__c FROM BrokerApplication__c WHERE Id = :app.Id].ApplicationNumber__c;
        System.debug('app >>'+appNumber );
        Test.startTest();
        BrokerApplication__c result = BrokerApplicationService.getInstance().getBrokerApplicationByNumber(appNumber);
        Test.stopTest();
        System.assertNotEquals(null, result.ApplicationNumber__c, 'Should return application by number');
        System.assertEquals(app.Id, result.Id);
    }

    @isTest
    static void testGetApplicationByIds() {
        BrokerApplication__c app = createMockApplication();
        Set<Id> ids = new Set<Id>{ app.Id };
        Test.startTest();
        List<BrokerApplication__c> result = BrokerApplicationService.getInstance().getApplicationByIds(ids);
        Test.stopTest();
        System.assertEquals(1, result.size(), 'Should return one record for valid Ids');
    }

    @isTest
    static void testResetDrawloopNext() {
        BrokerApplication__c app = createMockApplication();
        Test.startTest();
        BrokerApplicationService.getInstance().resetDrawloopNext(app.Id);
        Test.stopTest();
        app = [SELECT Drawloop_Next_1__c FROM BrokerApplication__c WHERE Id = :app.Id];
        System.assertEquals(null, app.Drawloop_Next_1__c, 'Drawloop_Next_1__c should be reset to blank');
    }

    @isTest
    static void testUpdateDrawloopNext() {
        BrokerApplication__c app = createMockApplication();
        Test.startTest();
        BrokerApplicationService.getInstance().updateDrawloopNext(app.Id, 'NextStep');
        Test.stopTest();
        app = [SELECT Drawloop_Next_1__c FROM BrokerApplication__c WHERE Id = :app.Id];
        System.assertEquals('NextStep', app.Drawloop_Next_1__c, 'Should update Drawloop_Next_1__c to NextStep');
    }

    @isTest
    static void testUpdateBrokerApplications() {
        BrokerApplication__c app = createMockApplication();
        app.Name = 'Updated Agency';
        List<BrokerApplication__c> listToUpdate = new List<BrokerApplication__c>{ app };

        Test.startTest();
        BrokerApplicationService.getInstance().updateBrokerApplications(listToUpdate);
        Test.stopTest();

        BrokerApplication__c updated = [SELECT Name FROM BrokerApplication__c WHERE Id = :app.Id];
        System.assertEquals('Updated Agency', updated.Name, 'Name should be updated');
    }
    
    @isTest
    static void testInsertApplications() {
        BrokerApplication__c app = new BrokerApplication__c(Name='Insert Test');
        List<BrokerApplication__c> apps = new List<BrokerApplication__c>{app};
    
        Test.startTest();
        BrokerApplicationService.getInstance().insertApplications(apps);
        Test.stopTest();
    
        // Query back inserted record to verify insert
        BrokerApplication__c inserted = [SELECT Id, Name FROM BrokerApplication__c WHERE Name = 'Insert Test' LIMIT 1];
        System.assertNotEquals(null, inserted, 'Record should be inserted');
        System.assertEquals('Insert Test', inserted.Name);
    }
    
    @isTest
    static void testInsertApplications_emptyList() {
        Test.startTest();
        BrokerApplicationService.getInstance().insertApplications(new List<BrokerApplication__c>());
        Test.stopTest();
        // No exception means pass, no records inserted
        // Optionally assert no records exist with a known name
        Integer countInserted = [SELECT count() FROM BrokerApplication__c WHERE Name = 'Insert Test Empty'];
        System.assertEquals(0, countInserted);
    }
    
    @isTest
    static void testUpdateApplications_emptyList() {
        Test.startTest();
        BrokerApplicationService.getInstance().updateApplications(new List<BrokerApplication__c>());
        Test.stopTest();
        // No exception means pass
    }
    
}