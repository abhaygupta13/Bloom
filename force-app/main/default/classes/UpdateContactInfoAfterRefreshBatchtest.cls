@isTest
Private class UpdateContactInfoAfterRefreshBatchtest {
    static testMethod void createContact(){
        Account Acc = new Account();
        Acc.Name = 'testAcc';
        Acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Organization Account').getRecordTypeId();
        insert acc;
        
        Contact con = new contact();
        con.lastname ='lastname';
        con.Email='coneamil@email.com';
        con.MobilePhone='0551234567';
        insert con;        
        Test.startTest();       
        Id jobid= Database.executeBatch(new UpdateContactInfoAfterRefreshBatch(),5);
        Test.stopTest();
    }

}