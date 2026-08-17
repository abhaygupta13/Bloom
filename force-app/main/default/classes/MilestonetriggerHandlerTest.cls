@istest
public class MilestonetriggerHandlerTest{
    
    @istest
    static void Testmethod1(){
          
        List<milestone__c> mlist = new List<milestone__c>();
        milestone__c m = new milestone__c();
        m.Milestone_Date__c = date.valueof(system.now());
        m.Milestone_Status__c = 'delayed';
        m.Name = 'Test milestone';
        mlist.add(m);
        insert mlist;
        mlist[0].Name = 'Test milestone 1';
        update mlist;
        
        delete mlist;
    }
   

}