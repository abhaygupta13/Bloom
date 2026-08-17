@isTest
public class OpportunityAutoCloseBatchTest {
    @isTest 
    static void OpportunityTriggerHandlerTestMethod(){
        List<Opportunity> lstOpportunity = new List<Opportunity>();
        Id AccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Account objAccount = new Account(RecordTypeId=AccountRecordTypeId, LastName= 'test', personEmail='Jana@tesrt.com', CustomerSubType__c ='CORPORATE');
        insert objAccount;
        
        Opportunity objOpportunity=new Opportunity(Name = 'Test Opportunity', StageName = 'Closed Won', WinReason__c = 'Bloom Brand', CloseDate = System.today(), LeadChannel__c = 'Walk in', AccountId = objAccount.Id);
        lstOpportunity.add(objOpportunity);
        
        Opportunity objOpportunity1=new Opportunity(Name = 'Test Opportunity 1', StageName = 'New', CloseDate = System.today(), LeadChannel__c = 'Walk in', AccountId = objAccount.Id);
        lstOpportunity.add(objOpportunity1);
        insert lstOpportunity;
        
        List<Opportunity> lstOpp = [SELECT Id, CreatedDate FROM Opportunity];
        for(Opportunity objOpp : lstOpp){
            Test.setCreatedDate(objOpp.Id, System.today().addDays(-35));
        }
        
        Test.startTest();      
        String sch = '0 0 23 * * ?';
        OpportunityAutoCloseBatch batchJob = new OpportunityAutoCloseBatch();
        System.schedule('OpportunityAutoCloseBatch',sch,batchJob);
        Test.stopTest();
    }        
}