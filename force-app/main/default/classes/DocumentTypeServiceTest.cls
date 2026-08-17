@isTest
public class DocumentTypeServiceTest {
    
    @TestSetup
    static void creatingData() {    
        DocumentType__c documentType = TestDataFactory.createDocumentType('Account', 'Emirates ID');
        insert documentType;
    }
    
    TestMethod static void unitTest1(){
        DocumentTypeService dts = DocumentTypeService.getInstance();
        dts.getDocumentTypeRecords('Account');
        DocumentType__c insertedDocType = [SELECT Id FROM DocumentType__c LIMIT 1];
        dts.getDocumentTypeByIds(new List<Id>{ insertedDocType.Id });
    }

}