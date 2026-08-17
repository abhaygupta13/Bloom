@isTest
public class BrokerApplicantTriggerHandlerTest {
    
    @testSetup
    static void setupTestData() {
        // Insert a BrokerApplication__c record for lookup requirement
        BrokerApplication__c ba = new BrokerApplication__c(
            Name = 'Test Broker Application'
        );
        insert ba;
        
        // Insert required DocumentType__c records with roles that match test applicant
        List<DocumentType__c> docTypes = new List<DocumentType__c>{
            new DocumentType__c(
                ObjectType__c = 'Broker Applicant',
                Type__c = 'Broker Agreement',
                Active__c = true,
                IsDocgen__c = true,
                BrokerContactRole__c = 'Owner;CEO'
            ),
                new DocumentType__c(
                    ObjectType__c = 'Broker Applicant',
                    Type__c = 'Trade License',
                    Active__c = true,
                    IsDocgen__c = true,
                    BrokerContactRole__c = 'Owner;CEO'
                )
                };
                    insert docTypes;
    }
    
    
    @isTest
    static void testAfterInsertTriggerHandler() {
        // Get the setup BrokerApplication record
        BrokerApplication__c ba = [SELECT Id FROM BrokerApplication__c LIMIT 1];
        
        // Insert BrokerApplicant__c record (this will invoke afterInsert trigger)
        BrokerApplicant__c applicant = new BrokerApplicant__c(
            Title__c = 'Mr.',
            FirstName__c = 'Test',
            LastName__c = 'Contact',
            BrokerApplication__c = ba.Id,
            BrokerContactRole__c = 'Owner;CEO'
        );
        
        Test.startTest();
        insert applicant;
        Test.stopTest();
        
        // Assert that Document__c records were created for the inserted applicant
        List<Document__c> docs = [SELECT Id, BrokerApplicant__c, DocumentType__c,DocumentType__r.BrokerContactRole__c, Document_Name__c 
                                  FROM Document__c 
                                  WHERE BrokerApplicant__c = :applicant.Id];
        System.assertEquals(2, docs.size(), 'Two Document__c records should be created by the trigger');
        
        for (Document__c doc : docs) {
            System.assertEquals(applicant.Id, doc.BrokerApplicant__c);
            System.assertNotEquals(null, doc.Document_Name__c);
        }
    }
    
    @isTest
    static void testOtherTriggerContexts() {
        // Get setup BrokerApplication
        BrokerApplication__c ba = [SELECT Id FROM BrokerApplication__c LIMIT 1];
        
        // Insert a BrokerApplicant__c record
        BrokerApplicant__c applicant = new BrokerApplicant__c(
            Title__c = 'Mr.',
            FirstName__c = 'Test',
            LastName__c = 'Contact',
            BrokerApplication__c = ba.Id
        );
        insert applicant;
        
        // --------- Update (to cover beforeUpdate and afterUpdate) ---------
        BrokerApplicant__c bapp = [SELECT Id FROM BrokerApplicant__c LIMIT 1];
        bapp.FirstName__c = 'Test New';
        update bapp;
        
        // --------- Delete (to cover beforeDelete and afterDelete) ---------
        delete applicant;
        
        // --------- Undelete (to cover afterUnDelete) ---------
        Undelete applicant;
    }
}