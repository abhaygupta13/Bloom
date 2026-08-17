@istest
public class EmailReminderhandlerTest {
     @istest
    public static void testmethod1(){
        Date today = Date.today();
        Date thirtyDaysFromToday = today.addDays(30);
        Id AccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Broker_Agency').getRecordTypeId();
        Account tempAcc=new Account(
            RecordTypeId=AccountRecordTypeId,
            Name= 'test',
            Broker_Registration_Expiry_Date__c = thirtyDaysFromToday,
            Trade_License_Expiry_Date__c = thirtyDaysFromToday
            
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
        List<Lead> Lelist = new List<Lead>();
         Lead testLead = new Lead();
        testLead.LastName = 'Test Lead';
        testLead.MobileCountryCode__c = '971';
        testLead.Status = 'New';
        testLead.MobilePhone = '37829292020';
        testLead.Email = 'testlead@example.com';
       // testLead.Lead_Channel__c = 'Online';
        testLead.LeadSource = 'Event';
        testLead.leadsubsource__c = 'Red Crescent Event';
        Lelist.add(testLead);
        insert Lelist;
        
        
        Test.startTest();
        EmailReminderhandler.BrokerAgencyExpiryReminder();
       // EmailReminderhandler.SendEmailforlead(Lelist);
     
        Test.stopTest();
    }

}