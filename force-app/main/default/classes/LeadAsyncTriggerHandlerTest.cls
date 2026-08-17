@istest
public class LeadAsyncTriggerHandlerTest {
    @istest
    static void TestMethod1(){
        Test.enableChangeDataCapture();
        List<Lead> Llist = new List<Lead>();
        Lead l = new lead();
        l.LastName = 'Testclass';
        l.MobileCountryCode__c = '971';
        l.Status = 'New';
        l.MobilePhone = '37829292020';
        l.Email = 'Testclass@gmail.com';
        // l.Lead_Channel__c = 'Online'; 
        Llist.add(l);
        insert Llist;
        //  l.LastName = 'testlead1';
        //  Llist.add(l);
        Update l;
        Test.getEventBus().deliver();
        
        //Delete the record
        Test.enableChangeDataCapture();
        DELETE l;
        Test.getEventBus().deliver();
        //UnDelete the record
        Test.enableChangeDataCapture();
        UNDELETE l;
        Test.getEventBus().deliver();
        
        
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        AssignmentRule__c assr = new AssignmentRule__c();
        assr.RecordType__c = 'Lead';
        assr.ProcessName__c = 'Digital Lead Assignment';
        assr.IsActive__c = true;
        insert assr;
        
        time startime = Time.newInstance(9, 30, 0, 0);
        Time Endtime = Time.newInstance(20, 30, 0, 0);
        AssignmentUser__c assru = new AssignmentUser__c();
        assru.IsActive__c = true;
        assru.AssignmentDays__c = 'Monday;Tuesday;Wednesday';
        assru.MondayStartTime__c = startime;
        assru.MondayEndTime__c = Endtime;
        assru.TuesdayStartTime__c  = startime;
        assru.TuesdayEndTime__c = Endtime;
        assru.AssignmentRule__c = assr.id;
        assru.User__c = adminUser.id;
        assru.MaximumCapacity__c = 100;
        insert assru;
        
        
        
        
        LeadChangeEvent event = new LeadChangeEvent();
        
        // Set the ChangeEventHeader
        EventBus.ChangeEventHeader header = new EventBus.ChangeEventHeader();
        header.changeType = 'CREATE'; // Change to 'UPDATE', 'DELETE', or 'UNDELETE' to test other scenarios
        event.ChangeEventHeader = header;
        //  EventBus.Publish(event);
        
        
        // Set the ChangeEventHeader
        EventBus.ChangeEventHeader header2 = new EventBus.ChangeEventHeader();
        header2.changeType = 'UPDATE'; // Change to 'UPDATE', 'DELETE', or 'UNDELETE' to test other scenarios
        event.ChangeEventHeader = header2;
        EventBus.ChangeEventHeader header3 = new EventBus.ChangeEventHeader();
        header3.changeType = 'DELETE'; // Change to 'UPDATE', 'DELETE', or 'UNDELETE' to test other scenarios
        event.ChangeEventHeader = header3;
        EventBus.ChangeEventHeader header4 = new EventBus.ChangeEventHeader();
        header4.changeType = 'UNDELETE'; // Change to 'UPDATE', 'DELETE', or 'UNDELETE' to test other scenarios
        event.ChangeEventHeader = header4;
        test.starttest();
        
        
        LeadAsyncTriggerHandler ias = new LeadAsyncTriggerHandler(); 
        //ias.changeTypeCreate(new List<Id>{Llist[0].Id});
        //ias.changeTypeDelete(new List<Id>{Llist[0].Id});
       // ias.changeTypeUndelete(new List<Id>{Llist[0].Id});
       // ias.changeTypeUpdate(new List<Id>{Llist[0].Id});
        
        ias.isDisabled();
        AsyncTriggerDispatcher.disableAllAsyncTriggers();
        AsyncTriggerDispatcher.enableAllAsyncTriggers();
        //AsyncTriggerDispatcher.run(null);
        
        test.stoptest();
    }
    
}