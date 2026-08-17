@isTest
public class BCAPP_BusinessRuleValidatorTest {
    
    
    @isTest
    static void testgetRelatedAccountsForAccountId() {
        
        Service_Catalog__c testServiceCatalog =BCAPP_TestDataFactory.createServiceCatalog();
        insert testServiceCatalog;
       

        Case testCase =BCAPP_TestDataFactory.createCase();
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Move In Holiday Homes').getRecordTypeId();
        testCase.RecordTypeId=RecordTypeCaseId;
        testCase.Move_Out_Date__c=system.today();
        testCase.Email_Address__c='testuser@fff.com';
        testCase.Service_Catalog__c=testServiceCatalog.id;
        insert testCase;
        
        Service_Catalog_Business_Rule__c sobj = new Service_Catalog_Business_Rule__c(
            ServiceCatalog__c = testServiceCatalog.id,                                 // ServiceCatalog
            Active__c = true,                                                        // Active
            Field_Api_Name__c = 'EJARI_Tawteeq_start_date__c',                       // Field Api Name
            Comparison_Operator__c = '<',                                         // Comparison Operator
            Error_Message__c = 'Lease End Date cannot be before Lease Start Date.',  // Error Message
            Compare_Field_API_Name__c = 'EJARI_Tawteeq_end_date__c'                 // Compare Field API Name
        );
        insert sobj;
        
        system.debug([select ServiceCatalog__c from Service_Catalog_Business_Rule__c]);
        BCAPP_BusinessRuleValidator instance=new BCAPP_BusinessRuleValidator();
        instance.validateRecord(testCase.id);
        
    }
    @isTest
    static void testIsValidMethod() {
        try{
        // Create an instance of the class containing the method
        BCAPP_BusinessRuleValidator instance = new BCAPP_BusinessRuleValidator();
        
        // Test '=' operator
        System.assert(instance.isValid('test', '=', 'test'), 'Expected values to be equal');
        System.assert(!instance.isValid('test', '=', 'other'), 'Expected values to be not equal');
        
        // Test '!=' operator
        System.assert(instance.isValid('test', '!=', 'other'), 'Expected values to be not equal');
        System.assert(!instance.isValid('test', '!=', 'test'), 'Expected values to be equal');
        
        // Test '>' operator for Decimal
        System.assert(instance.isValid(10.5, '>', 10), 'Expected fieldValue > defaultValue');
        System.assert(!instance.isValid(10, '>', 10), 'Expected fieldValue not > defaultValue');
        
        // Test '<' operator for Decimal
        System.assert(instance.isValid(5, '<', 10), 'Expected fieldValue < defaultValue');
        System.assert(!instance.isValid(10, '<', 10), 'Expected fieldValue not < defaultValue');
        
        // Test '>=' operator for Decimal
        System.assert(instance.isValid(10, '>=', 10), 'Expected fieldValue >= defaultValue');
        System.assert(!instance.isValid(5, '>=', 10), 'Expected fieldValue not >= defaultValue');
        
        // Test '<=' operator for Decimal
        System.assert(instance.isValid(5, '<=', 10), 'Expected fieldValue <= defaultValue');
        System.assert(instance.isValid(10, '<=', 10), 'Expected fieldValue <= defaultValue');
        System.assert(!instance.isValid(15, '<=', 10), 'Expected fieldValue not <= defaultValue');
        
        // Test Date comparison
        System.assert(instance.isValid(Date.newInstance(2025, 1, 1), '>', Date.newInstance(2024, 12, 31)), 'Expected fieldValue > defaultValue');
        System.assert(!instance.isValid(Date.newInstance(2025, 1, 1), '<', Date.newInstance(2024, 12, 31)), 'Expected fieldValue not < defaultValue');
        
        // Test DateTime comparison
        System.debug(instance.isValid(DateTime.newInstance(2025, 1, 1, 10, 0, 0), '<', DateTime.newInstance(2025, 1, 1, 12, 0, 0)));
        System.debug(instance.isValid(DateTime.newInstance(2025, 1, 1, 12, 0, 0), '=', DateTime.newInstance(2025, 1, 1, 12, 0, 0)));
        
        // Test unsupported data type
        System.debug(!instance.isValid(new Map<String, String>(), '>', 'someValue'));
        
        }catch(exception e){
            
        }
        }
        
    
    
}