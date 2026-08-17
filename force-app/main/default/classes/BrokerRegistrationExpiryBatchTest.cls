@istest
public class BrokerRegistrationExpiryBatchTest {
  @istest
    public static void testmethod1(){
        Date today = Date.today();
        Date thirtyDaysFromToday = today.addDays(30);
        Id AccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Broker_Agency').getRecordTypeId();
        Account tempAcc=new Account(
            RecordTypeId=AccountRecordTypeId,
            Name= 'test',
            Broker_Registration_Expiry_Date__c = thirtyDaysFromToday
            
        );
        insert tempAcc;
        Id BrokerContactRecTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Broker').getRecordTypeId();
         Contact tempContact =new Contact(
            LastName='test',
            AccountId=tempAcc.id,
            Email='test@gmail.com',
             RecordTypeId = BrokerContactRecTypeId, 
             BrokerType__c ='Agency Admin'
        );
        insert tempContact;
        
        Test.startTest();
       Database.executeBatch(new BrokerRegistrationExpiryBatch());
        Test.stopTest();
    }
    
    @istest
    public static void testmethod2(){ 
        
        BrokerApplication__c bApp = new BrokerApplication__c(Name = 'Test Application');
        Insert bApp;
        
        Date today = Date.today();
        //Date thirtyDaysFromToday = today.addDays(30);
        Id AccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Broker_Agency').getRecordTypeId();
        Account tempAcc=new Account(
            RecordTypeId=AccountRecordTypeId,
            Name= 'test',
            Trade_License_Expiry_Date__c = today,
            Broker_Application__c = bApp.Id
        );
        insert tempAcc;
        Id BrokerContactRecTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Broker').getRecordTypeId();
         Contact tempContact =new Contact(
            LastName='test',
            AccountId=tempAcc.id,
            Email='test@gmail.com',
             RecordTypeId = BrokerContactRecTypeId, 
             BrokerType__c ='Agency Admin'
        );
        insert tempContact;
        
        Test.startTest();
       Database.executeBatch(new BrokerRegistrationExpiryBatch());
        Test.stopTest();
    }
}