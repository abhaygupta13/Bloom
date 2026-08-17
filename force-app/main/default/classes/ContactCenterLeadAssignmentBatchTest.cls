@istest
public class ContactCenterLeadAssignmentBatchTest {
      @istest
    static void testMethod1() {
        
         List<Lead> Llist = new List<Lead>();
        Lead l = new lead();
        l.LastName = 'Testclass';
        l.MobileCountryCode__c = '971';
        l.Status = 'New';
        l.MobilePhone = '37829292020';
        l.Email = 'Testclass@gmail.com';
        l.LeadTeam__c = 'Leasing';
        l.Project__c = 'Bloom Living';
        // l.Lead_Channel__c = 'Online'; 
        Llist.add(l);
        insert Llist;
        ContactCenterLeadAssignmentBatch ccla = new ContactCenterLeadAssignmentBatch();
        ccla.execute(null);
        ccla.execute(null,Llist);
    }

}