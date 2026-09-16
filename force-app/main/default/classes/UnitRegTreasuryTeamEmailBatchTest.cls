@isTest
public class UnitRegTreasuryTeamEmailBatchTest {

    @TestSetup
    static void creatingData() {
        Account account = TestDataFactory.createPersonalAccount('Lastname', '01010101', '1234567890', 'test@gmail.com');
        INSERT account;

        //Test data for Project__c and related Units
        Project__c project = TestDataFactory.createProject('ProjectTest', Date.today() - 1);
        insert project;

        Unit__c u = TestDataFactory.createUnit(project.Id, 'A1-G01', 'Unassigned');
        u.RegistrationDate__c = Date.today();
        insert u;
		
        SalesOrder__c salesOrder = TestDataFactory.createSalesOrder(account.Id, null, null, null, u.Id, 100.00);
        salesOrder.DocumentUploadedDate__c = Date.today() - 1;
        insert salesOrder;

        u.Active_Sales_Order__c = salesOrder.Id;
        update u;
        
        Project__c project1 = TestDataFactory.createProject('ProjectTest1', Date.today() - 10);
        project1.LastProjectRegEmailReminder__c = Date.today() - 3;
        insert project1;
        
        Unit__c u1 = TestDataFactory.createUnit(project1.Id, 'A1-G02', 'Unassigned');
        u1.RegistrationDate__c = Null;
        insert u1;
		
        SalesOrder__c salesOrder1 = TestDataFactory.createSalesOrder(account.Id, null, null, null, u1.Id, 100.00);
        salesOrder1.DocumentUploadedDate__c = Date.today() - 1;
        insert salesOrder1;

        u1.Active_Sales_Order__c = salesOrder1.Id;
        update u1;

        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        System.runAs(testUser){
            EmailTemplate emailTemplate  = TestDataFactory.createEmailTemplate('templateName');
            insert emailTemplate;
        }
        
    }

    @isTest
    static void testBatchExecution() {
        SalesOrder__c objSO = [SELECT Id FROM SalesOrder__c LIMIT 1];
        objSO.FundReleaseRequested__c = true;
        objSO.FundMovedToGRDate__c = System.today().addDays(-1);
        update objSO;
        Test.startTest();
        UnitRegTreasuryTeamEmailBatch batch = new UnitRegTreasuryTeamEmailBatch();
        Database.executeBatch(batch);
        Test.stopTest();
    }
    
    @isTest
    static void testExecute() {
        Test.startTest();
        // Act: Schedule the scheduler class
        String cronExpression = '0 0 12 * * ?'; // Example cron expression
        String jobId = System.schedule('Test Batch Scheduler', cronExpression, new UnitRegTreasuryTeamEmailBatch());
        // Assert: Check that the job has been scheduled
        CronTrigger ct = [SELECT Id, CronExpression, State FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals('WAITING', ct.State, 'Job should be in WAITING state after scheduling');
        Test.stopTest();
    }
}