@isTest
public class ServiceCatalogBusinessRuleServiceTest {
@isTest
    static void testfetchBusinessRulesForCatalog() {
        Test.startTest();
        ServiceCatalogBusinessRuleService.fetchBusinessRulesForCatalog('');
        Test.stopTest();
        
    }
    
    @isTest
    static void testfetchServiceValidation() {
        Test.startTest();
        ServiceCatalogBusinessRuleService.fetchServiceValidation('');
        Test.stopTest();
        
    }
}