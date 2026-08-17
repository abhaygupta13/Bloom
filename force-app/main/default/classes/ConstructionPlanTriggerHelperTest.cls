@isTest
public class ConstructionPlanTriggerHelperTest {
    
    @isTest static void ConstructionPlanTriggerHelperTestMethod(){
        Project__c testProject=new Project__c(
            Name='Test Project'
        );
        insert testProject;
        
        Construction_Plan__c cp = new Construction_Plan__c();
        cp.Cumulative_Plan__c = 20;
        cp.Project__c = testProject.Id;
        cp.Months__c = 'January';
        cp.Years__c = '2024';
        insert cp;
        
        cp.Months__c = 'February';
        cp.Years__c = '2025';
        update cp;
        
        
        List<Construction_Plan__c>cplist = new list<Construction_Plan__c>();
        cplist.add(cp);
        test.startTest();
        ConstructionPlanTriggerHelper.sendProjectUpdateEmail(cplist);
        test.stopTest();
        
        delete cp;
        
    }
    
}