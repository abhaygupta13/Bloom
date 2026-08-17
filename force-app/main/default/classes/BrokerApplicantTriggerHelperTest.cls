@isTest
public class BrokerApplicantTriggerHelperTest {
    
    @testSetup
    static void setupTestData() {
        // Create DocumentType__c records with matching roles
        List<DocumentType__c> docTypes = new List<DocumentType__c>();
        docTypes.add(new DocumentType__c(
            ObjectType__c = 'Broker Applicant',
            Type__c = 'Broker Agreement',
            Active__c = true,
            IsDocgen__c = true,
            BrokerContactRole__c = 'Owner'
        ));
        docTypes.add(new DocumentType__c(
            ObjectType__c = 'Broker Applicant',
            Type__c = 'Trade License',
            Active__c = true,
            IsDocgen__c = true,
            BrokerContactRole__c = 'CEO'
        ));
        insert docTypes;
        
        // Insert BrokerApplication
        BrokerApplication__c ba = new BrokerApplication__c(Name = 'Test Broker Application Record');
        insert ba;
    }
    
    
    @isTest
    static void testCreateDocuments() {
        BrokerApplication__c ba = [SELECT Id FROM BrokerApplication__c LIMIT 1];
        
        // Set matching roles
        BrokerApplicant__c applicant = new BrokerApplicant__c(
            BrokerApplication__c = ba.Id,
            Title__c = 'Mr.',
            FirstName__c = 'Test',
            LastName__c = 'Contact',
            BrokerContactRole__c = 'CEO'
        );
        insert applicant;
        update applicant;
        
        Test.startTest();
        BrokerApplicantTriggerHelper.createDocuments(new List<BrokerApplicant__c>{ applicant });
        Test.stopTest();
        
        List<Document__c> docs = [
            SELECT Id, BrokerApplicant__c, DocumentType__c, Document_Name__c
            FROM Document__c
            WHERE BrokerApplicant__c = :applicant.Id
        ];
        
        System.assertEquals(1, docs.size(), 'Expected 1 Document__c records to be created for BrokerApplicant');
    }
}