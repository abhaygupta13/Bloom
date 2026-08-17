@isTest
public class OpportunityTriggerHelperTest{

    @testSetup
    static void setupData() {
        // Insert document types for both individual and organization
        insert new List<DocumentType__c>{
            new DocumentType__c(Type__c = 'Passport', Customer_Type__c = 'Individual',ObjectType__c='Opportunity'),
            //new DocumentType__c(Type__c = 'COI', Customer_Type__c = 'Organization')
            new DocumentType__c(Type__c = 'SOA', Customer_Type__c = 'Organization',ObjectType__c='Opportunity')
        };
    }

   

    @isTest
    static void testCreateDocuments() {
        Id personRtId = [SELECT Id FROM RecordType WHERE SObjectType='Account' AND DeveloperName='PersonAccount' LIMIT 1].Id;
        Id orgRtId = [SELECT Id FROM RecordType WHERE SObjectType='Account' AND DeveloperName='OrganizationAccount' LIMIT 1].Id;

        /*Account acc1 = new Account(RecordTypeId = personRtId, FirstName = 'Person', LastName = 'One');
        Account acc2 = new Account(RecordTypeId = orgRtId, Name = 'Org Account');*/
        Account acc1 = new Account(RecordTypeId = personRtId, FirstName = 'Person', LastName = 'One',PersonEmail = 'test@test1.com', PersonMobilePhone = '00971111111112');
        Account acc2 = new Account(RecordTypeId = orgRtId, Name = 'Org Account');
        insert new List<Account>{ acc1, acc2 };

        Opportunity opp1 = new Opportunity(Name = 'Opp1', StageName = 'Prospecting', CloseDate = Date.today().addDays(10), AccountId = acc1.Id,OpportunityType__c ='Leasing');
        Opportunity opp2 = new Opportunity(Name = 'Opp2', StageName = 'Prospecting', CloseDate = Date.today().addDays(15), AccountId = acc2.Id,OpportunityType__c ='Leasing');
        insert new List<Opportunity>{ opp1, opp2 };

        Test.startTest();
        OpportunityTriggerHelper.createDocuments(new List<Opportunity>{ opp1, opp2 });
        Test.stopTest();

        List<Document__c> insertedDocs = [
            SELECT Id, Opportunity__c FROM Document__c
            WHERE Opportunity__c IN :new List<Id>{opp1.Id, opp2.Id}
        ];
        System.assert(insertedDocs.size() > 0, 'Documents should be created');
    }
}