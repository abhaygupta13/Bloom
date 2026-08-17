@isTest
private class HandoverSLABatchTest {
    
    @testSetup
    static void setupTestData() {
        HandoverTriggerHandler.isTriggerDisabled = true;

        Account ac = new Account(Name = 'test Account');
        insert ac;
        
        SalesOrder__c so = new SalesOrder__c(Name = 'Test SalesOrder', Account__c = ac.Id);
        insert so;
        
        Unit__c unt = new Unit__c(Name = 'Unit Test A1435', Status__c = 'Unassigned');
        insert unt;
        
        Handover__c handover1 = new Handover__c(
            Unit__c = unt.Id,  
            Customer_Email__c = 'test@example.com',
            Sub_Status__c = HandoverConstants.HANDOVER_STATUS_QA_DESnagging_Completed,
            Is_BCC_Announcement_Sent__c = true,
            Customer_Availability_for_CHO__c = 'Customer Available',
            Sales_Order__c = so.Id);
        insert handover1;
        
        Handover__History histories1 = new Handover__History(ParentId = handover1.Id,Field = 'Sub_Status__c');
        insert histories1;
  
    }
    
    @isTest
    static void testHandoverSLABatch() {   
        Test.startTest();
        Database.executeBatch(new HandoverSLABatch());
        Test.stopTest();
    }
    
    @isTest
    static void testHandoverSLABatchScheduler() {
        HandoverSLABatchScheduler scheduler = new HandoverSLABatchScheduler();
        
        String cronExp = '0 0 0 * * ?'; 
        String jobId = System.schedule('Test Handover SLA Batch Job', cronExp, scheduler);
        
        CronTrigger cronTrigger = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                                   FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(cronExp, cronTrigger.CronExpression, 'Cron expression should match.');
        
        Test.startTest();
        Database.executeBatch(new HandoverSLABatch(), 100);
        Test.stopTest();
    }
}