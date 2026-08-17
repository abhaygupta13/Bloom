@isTest
public class BrokerApplicationTriggerHandlerTest {
    
    @isTest
    static void testAfterInsertTrigger() {
        // Arrange: Create test data
        BrokerApplication__c brokerApp = new BrokerApplication__c(
            Name = 'Test Broker Application',
            Account_Number__c = '180019001010',
            ApprovalStatus__c = 'Draft',
            AgencyType__c = 'LLC',
            AgencyEmail__c='test@test.com',
            typeOfEstablishment__c = 'Domestic'
        );
        
        // Create DocumentType__c records with ObjectType__c = 'Broker Application'
        List<DocumentType__c> docTypes = new List<DocumentType__c>();
        docTypes.add(new DocumentType__c(
            //Name = 'DocType ' + i,
            ObjectType__c = 'Broker Application',
            Type__c = 'Broker Agreement',
            Active__c = true,
            IsDocgen__c = true,
            typeOfEstablishment__c = 'Domestic'
        ));
        
        insert docTypes;
        
        // Act: Insert the record to trigger 'afterInsert'
        Test.startTest();
        insert brokerApp;
        Test.stopTest();
        
        // Assert: Check that related documents were created (if applicable)
        List<Document__c> docs = [
            SELECT Id, Name, BrokerApplication__c 
            FROM Document__c 
            WHERE BrokerApplication__c = :brokerApp.Id
        ];
        System.assert(!docs.isEmpty(), 'Expected related Document__c records to be created');
    }
    
    @isTest
    static void testOtherContextsForBrokerApplication() {
        // --------- Insert to prepare test data ---------
        BrokerApplication__c ba = new BrokerApplication__c(
            Name = 'Test Broker App'
        );
        insert ba;
        
        // --------- Update (to cover beforeUpdate and afterUpdate) ---------
        ba.Name = 'Updated Broker App';
        update ba;
        
        // --------- Delete (to cover beforeDelete and afterDelete) ---------
        delete ba;
        
        // --------- Undelete (to cover afterUnDelete) ---------
        undelete ba;
    }
}