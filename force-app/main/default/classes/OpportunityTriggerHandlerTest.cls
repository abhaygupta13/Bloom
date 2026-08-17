@isTest
public class OpportunityTriggerHandlerTest {
    @isTest static void OpportunityTriggerHandlerTestMethod(){
        Id AccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Account tempAcc=new Account(
            RecordTypeId=AccountRecordTypeId,
            LastName= 'test',
            personEmail='Jana@tesrt.com',
            CustomerSubType__c ='CORPORATE'
            
        );
        insert tempAcc;
        
        Opportunity tempOpp=new Opportunity(
            Name='tempOpp',
            StageName='New',
            CloseDate=system.today(),
            LeadChannel__c='Walk in',
            AccountId=tempAcc.Id
            
        );
        insert tempOpp;
        
        Opportunity tempOpp1=new Opportunity(
            Name='tempOpp',
            StageName='New',
            CloseDate=system.today(),
            LeadChannel__c='Walk in',
            AccountId=tempAcc.Id
        );
        insert tempOpp1;
        
        List<Opportunity> newOpp=new List<Opportunity>();
        newOpp.add(tempOpp);
        List<Opportunity> createdOpp= new List<Opportunity>();
        createdOpp.add(tempOpp);
        List<Opportunity> allOpenOpp= new List<Opportunity>();
        createdOpp.add(tempOpp1);
        
        update newOpp;
        
        delete newOpp;
    }
}