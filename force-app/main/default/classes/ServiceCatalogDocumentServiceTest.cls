@isTest
public class ServiceCatalogDocumentServiceTest {
@isTest
    static void testfetchBusinessRulesForCatalog() {
        Test.startTest();
        ServiceCatalogDocumentService.getCatalogDocumentsByService(new Set<Id>(),'');
        Test.stopTest();
        
    }
    
    @isTest
    static void testfetchServiceValidation() {
        Test.startTest();
        ServiceCatalogDocumentService.getCatalogDocumentsByCatalogName('');
        Test.stopTest();
        
    }
}