/*
* @Author : Jayprakash Bharti
* @CreatedDate : 8th Sept 2024
* @Description : 
*/
/*****************************************************************************************************
* Version       Author      Date             Comment       
* 1.0           Jayprakash  8Sept2024        
*****************************************************************************************************/
@isTest
public class ContactServiceTest {
    
    @isTest static void TestMethodOne(){
       	List<Id> contactIdList = new List<Id>();
        ContactService cs = ContactService.getInstance();
        Account Acc = new Account();
        Acc.Name = 'testAcc';
        Acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Organization Account').getRecordTypeId();
        insert acc;
        
        Contact con0 = new contact();
        con0.lastname ='lastname';
        con0.Email='coneamil0@email.com';
        con0.MobilePhone='05512345670';
        con0.PrimaryContact__c = true;
        cs.insertContact(con0);
        cs.updateContactWithoutTrigger(con0);
        
        Case cse = new Case(contactId = con0.Id, Type= 'Question', Case_Sub_Status__c = 'In Progress');
        insert cse;
        
        List<Contact> lstContacts = cs.getContactEmail(new List<Case>{cse});
        
        Contact con = new contact();
        con.lastname ='lastname';
        con.Email='coneamil@email.com';
        con.MobilePhone='0551234567';
        List<Contact> contactList = new List<Contact>();
        contactList.add(con);
        cs.insertContacts(contactList);       
        cs.updateContactsWithoutTrigger(contactList);
        cs.updateContacts(contactList);
        cs.getContactByAccountId(acc.id);
        lstContacts = cs.getContactByEmails(new Set<String>{'coneamil0@email.com'});
        System.assertEquals(lstContacts[0].Email ,  'coneamil0@email.com' , 'Error in finding Contacts by Email');
        for(Contact objContact : contactList){
            contactIdList.add(objContact.Id);
        }
        
        cs.getContactById(contactList[0].Id);
        cs.getContactByIds(contactIdList);
        cs.getActiveContactByAccountId(new Set<Id>{acc.Id});
        cs.getContactByAccountIdNReceiveInvoiceCommunication(new Set<Id>{acc.Id});
        cs.getPrimaryContactByAccountId(acc.Id, true);
        cs.getContactsByIds(new Set<Id>{contactList[0].Id});
        cs.getActiveContactsByAccount(acc.Id);
        cs.getASOContactsByAccountIds(new Set<Id>{acc.Id});
        cs.getBrokerAuthSignContactsByAccount('test string');
        cs.getAgentContactsByAccountIds(new Set<Id>{acc.Id});
        ContactService.fetchContactsByIds(new Set<Id>{contactList[0].Id});
        ContactService.updateExistingContacts(contactList);
    }
}