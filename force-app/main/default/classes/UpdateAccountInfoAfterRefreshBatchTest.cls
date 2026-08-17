@isTest
Private class UpdateAccountInfoAfterRefreshBatchTest {
    static testMethod void createAcc(){
        Account Acc = new Account();
        Acc.lastname = 'testAcc';
        acc.PersonEmail='test@test.com';
        acc.PersonMobilePhone ='055123456';
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        insert acc;       

        Test.startTest();       
        Id jobid= Database.executeBatch(new UpdateAccountInfoAfterRefreshBatch(),5);
        Test.stopTest();
    }

}