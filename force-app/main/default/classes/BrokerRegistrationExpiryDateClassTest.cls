@istest
public class BrokerRegistrationExpiryDateClassTest {
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
        BrokerRegistrationExpiryDateClass scheduler = new BrokerRegistrationExpiryDateClass();
        scheduler.execute(null);
        Test.stopTest();
    }

}