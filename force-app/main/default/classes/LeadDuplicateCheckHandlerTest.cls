@istest
public class LeadDuplicateCheckHandlerTest {
   @istest
     static void testMethod1() {
        list<Lead>  Llist2 = new list<Lead>();
        Lead l = new lead();
        l.LastName = 'Testclass';
        l.MobileCountryCode__c = '971';
        l.Status = 'Working';
        l.MobilePhone = '37829292020';
        l.Email = 'Testclass@gmail.com';
       // l.Lead_Channel__c = 'Online'; 
        insert l;
       
         Lead l2 = new lead();
        l2.LastName = 'Testclass2';
        l2.MobileCountryCode__c = '971';
        l2.Status = 'New';
        l2.MobilePhone = '37829292020';
        l2.Email = 'Testclass@gmail.com';
        l2.Lead_Channel__c = 'Call'; 
        Llist2.add(l2); 
        insert Llist2; 
        
        Test.startTest();
         LeadDuplicateCheckHandler.handleDuplicateLeads(Llist2);
        Test.stopTest();
    } 
    @istest
     static void testMethod2() {
        list<Lead>  Llist2 = new list<Lead>();
        List<Lead> Llist = new List<Lead>();
        List<Lead> Llist3 = new List<Lead>();
        
        Lead l = new lead();
        l.LastName = 'Testclass';
        l.MobileCountryCode__c = '971';
      
        l.MobilePhone = '37829292020';
        l.Email = 'Testclass@gmail.com';
       l.Lead_Channel__c = 'Call'; 
        l.RetiredReason__c = 'Duplicate';
        l.RetirementComments__c = 'retired'; 
         l.Status = 'New';
       
       Llist.add(l);
       insert Llist; 
        
        
         Lead l2 = new lead();
        l2.LastName = 'Testclass2';
        l2.MobileCountryCode__c = '971';
        l2.Status = 'New';
        l2.MobilePhone = '37829292020';
        l2.Email = 'Testclass@gmail.com';
        l2.Lead_Channel__c = 'Call';
        Llist2.add(l2); 
        insert Llist2; 
        
        Test.startTest();
         LeadDuplicateCheckHandler.handleDuplicateLeads(Llist2);
        Test.stopTest();
    } 
     @istest
     static void testMethod3() {
        list<Lead>  Llist2 = new list<Lead>();
        List<Account> Alist = new List<Account>();
         Id personRecId =Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
         Account a = new Account();
         a.LastName = 'TestVinay';
         a.PersonEmail = 'Testclass@gmail.com';
         a.PersonMobilePhone = '37829292020';
         a.RecordTypeId = personRecId;
         insert a;
         
         Lead l2 = new lead();
        l2.LastName = 'Testclass2';
        l2.MobileCountryCode__c = '971';
        l2.Status = 'New';
        l2.MobilePhone = '37829292020';
        l2.Email = 'Testclass@gmail.com';
        //l2.Lead_Channel__c = 'Online'; 
        Llist2.add(l2); 
        insert Llist2; 
        
        Test.startTest();
         LeadDuplicateCheckHandler.handleDuplicateLeads(Llist2);
        Test.stopTest();
    } 

}