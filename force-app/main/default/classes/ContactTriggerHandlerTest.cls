@isTest
public class ContactTriggerHandlerTest {

    @isTest
    static void TestMethod1() {
       // Account account = TestDataFactory.createPersonalAccount('name1', 'Emirates_Id', '1234567890','abc@pqr.xyz');
       // insert account;
        Contact contact = new contact();
        contact.LastName='lastNAme';
        contact.Emirates_Id__c='Emirates_Id';
        insert contact;
        contact.Emirates_Id__c='Emirates_Id2';
        update contact;
        delete contact;
        
    }
}