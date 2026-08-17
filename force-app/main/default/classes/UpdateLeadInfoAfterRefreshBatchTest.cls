@isTest
Private class UpdateLeadInfoAfterRefreshBatchTest {
    static testMethod void createLead(){
        Lead le = new Lead();
        le.lastname='lastname';
        le.Email='email@email.com';
        le.MobilePhone='053243433';
        le.Status ='New';
        insert le;

        Test.startTest();       
        Id jobid= Database.executeBatch(new UpdateLeadInfoAfterRefreshBatch(),5);
        Test.stopTest();
    }

}