/*
* @Author : EaglesDev
* @CreatedDate : 9th Nov 2024
* @Description :  ServiceCatalogBusinessRule Service class
*/
/*****************************************************************************************************
* Version       Author      Date             Comment                                                                       
* 1.0           EaglesDev   9th Nov 2024    Initial draft 
*****************************************************************************************************/
public class ServiceCatalogBusinessRuleService {

    public static List<Service_Catalog_Business_Rule__c> fetchBusinessRulesForCatalog(String catalogId){
         return [select Compare_Field_API_Name__c ,Error_Message__c,Comparison_Operator__c,Default_Value__c,Field_Api_Name__c from
                                                                Service_Catalog_Business_Rule__c where ServiceCatalog__c=:catalogId];
        
    }
    
    public static List<Service_Catalog_Business_Rule__c > fetchServiceValidation(String validationName){
        
        return [select Active__c,Comparison_Operator__c ,Default_Value__c ,Field_Api_Name__c ,ServiceCatalog__c, 
                sObjectAPIName__c  from Service_Catalog_Business_Rule__c   where Name=:validationName limit 1];
    }
}