/*************************************************************************************************
Class       : TaskBusinessDaysBatchTest
Author      : Prashant Sahu
Description : Test class for TaskBusinessDaysBatch.
              Verifies business day calculation and schedulable execution.
*************************************************************************************************/
@IsTest
private class TaskBusinessDaysBatchTest {

  /*  @TestSetup
    static void setupData() {

        // Get an active Business Hours record
        BusinessHours bh = [ SELECT Id FROM BusinessHours WHERE IsActive = true LIMIT 1 ];
        Task taskRec = new Task( Subject = 'Task Business Days Batch Test', Status = 'Open', Priority = 'Normal', BusinessHours__c = bh.Id, SLAHours__c = 8, AssignedDateTime__c = System.now().addHours(-4) );
        insert taskRec;
    }*/
    
    @TestSetup
    static void setupData() {
        
        // Get an active Business Hours record
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsActive = true LIMIT 1];
        
        // Create Contact for WhoId
        Contact con = new Contact(
            LastName = 'Test Contact'
        );
        insert con;
        
        // Create Task
        Task taskRec = new Task(
            Subject = 'Task Business Days Batch Test',
            Status = 'Open',
            Priority = 'Normal',
            WhoId = con.Id,
            BusinessHours__c = bh.Id,
            SLAHours__c = 8,
            AssignedDateTime__c = System.now().addHours(-4)
        );
        insert taskRec;
    }

    @IsTest
    static void testBatchExecution() {

        Test.startTest();
        Database.executeBatch(new TaskBusinessDaysBatch(), 1);
        Test.stopTest();
        Task taskRec = [ SELECT WorkingDaysSpent__c FROM Task WHERE Subject = 'Task Business Days Batch Test' LIMIT 1 ];

       System.assertNotEquals( null, taskRec.WorkingDaysSpent__c, 'WorkingDaysSpent__c should be populated.' );
       System.assertNotEquals( null, taskRec.WorkingDaysSpent__c, 'WorkingDaysSpent__c should be populated.' );
    }

    @IsTest
    static void testSchedulableExecution() {

        Test.startTest();
        String cronExp = '0 0 0 1 1 ? 2099';
        System.schedule( 'TaskBusinessDaysBatchScheduler', cronExp, new TaskBusinessDaysBatch() );
        Test.stopTest();
        CronTrigger ct = [ SELECT Id, CronJobDetail.Name FROM CronTrigger WHERE CronJobDetail.Name = 'TaskBusinessDaysBatchScheduler' LIMIT 1 ];
        System.assertNotEquals(null, ct.Id);
    }
}