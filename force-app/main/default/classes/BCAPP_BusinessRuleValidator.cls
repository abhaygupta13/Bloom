//============================ BCAPP_BusinessRuleValidator =============================
/*
* @Author : Eagles
* @CreatedDate : 23rd OCT 2023
* @Name : BCAPP_BusinessRuleValidator
* @Description : This APEX class used to validate the Business rules in the Community APP
*/
/*****************************************************************************************************
* Version       Author                  Date             Comment                                                                       
* 1.0           Eagles               11NOV2023        Initial draft 
*****************************************************************************************************/

public class BCAPP_BusinessRuleValidator {
    
    public List<String> validateRecord(String recordId) {
     
        List<String> errors = new List<String>();
        List<String> fields = new List<String>();
        BCAPP_Utility utility = new BCAPP_Utility();
        List<Service_Catalog_Business_Rule__c> rules = new List<Service_Catalog_Business_Rule__c>();
        if(!String.isBlank(recordId)){

            CaseService cService = CaseService.getInstance();
            List<Case> service =  new List<Case>{cservice.getCaseById(recordId)};
            if(!service.isEmpty() && service[0].Service_Catalog__c !=null){
                for(Service_Catalog_Business_Rule__c rule:ServiceCatalogBusinessRuleService.fetchBusinessRulesForCatalog(service[0].Service_Catalog__c)){
                    if(rule.Field_Api_Name__c !=null){
                        fields.add(rule.Field_Api_Name__c);
                        fields.add(rule.Compare_Field_API_Name__c);
                        rules.add(rule);
                    }
                }
            }
        }
       
        List<Case> srRecords = (List<Case>)utility.getRecords('Case',fields,'Id=\'' + recordId + '\'');
        Case record = srRecords[0];
        for(Service_Catalog_Business_Rule__c rule:rules){
            // Retrieve the field value
            Object fieldValue = record.get(rule.Field_Api_Name__c);
            Object valueToCompare;
            if(rule.Compare_Field_API_Name__c !=null){
                valueToCompare = record.get(rule.Compare_Field_API_Name__c);
            }
            else if(rule.Default_Value__c!=null){
                valueToCompare = rule.Default_Value__c;
            }
            else{
                continue;
            }
            // Validate based on the comparison operator
            if (!isValid(fieldValue, rule.Comparison_Operator__c, valueToCompare)) {
                errors.add('Validation failed for ' + rule.Error_Message__c+ ': ' + comparisonErrorMessage(fieldValue, valueToCompare));
            }
        }
        
        return errors;
    }
    
    public Boolean isValid(Object fieldValue, String operator, Object defaultValueStr) {
        switch on operator {
            when '=' {
                return String.valueOf(fieldValue) == String.valueOf(defaultValueStr);
            }
            when '!=' {
                return String.valueOf(fieldValue) != String.valueOf(defaultValueStr);
            }
            when '>' {
                if (fieldValue instanceof Date) {
                    return Date.valueOf(String.valueOf(fieldValue)) > Date.valueOf(String.valueOf(defaultValueStr));
                } else if (fieldValue instanceof DateTime) {
                    return DateTime.valueOf(String.valueOf(fieldValue)) > DateTime.valueOf(String.valueOf(defaultValueStr));
                } else if (fieldValue instanceof Decimal) {
                    return Decimal.valueOf(String.valueOf(fieldValue)) > Decimal.valueOf(String.valueOf(defaultValueStr));
                } else {
                    return false; 
                }
            }
            when '<' {
                if (fieldValue instanceof Date) {
                    return Date.valueOf(String.valueOf(fieldValue)) <  Date.valueOf(String.valueOf(defaultValueStr));
                } else if (fieldValue instanceof DateTime) {
                    return DateTime.valueOf(String.valueOf(fieldValue)) <  Date.valueOf(String.valueOf(defaultValueStr));
                } else if (fieldValue instanceof Decimal) {
                    return Decimal.valueOf(String.valueOf(fieldValue)) <  Decimal.valueOf(String.valueOf(defaultValueStr));
                } else {
                    return false; 
                }
            }
            when '>=' {
                if (fieldValue instanceof Date) {
                    return Date.valueOf(String.valueOf(fieldValue)) >= Date.valueOf(String.valueOf(defaultValueStr));
                } else if (fieldValue instanceof DateTime) {
                    return DateTime.valueOf(String.valueOf(fieldValue)) >= Date.valueOf(String.valueOf(defaultValueStr));
                } else if (fieldValue instanceof Decimal) {
                    return Decimal.valueOf(String.valueOf(fieldValue)) >= Decimal.valueOf(String.valueOf(defaultValueStr));
                } else {
                    return false; 
                }
            }
            when '<=' {
                if (fieldValue instanceof Date) {
                    return Date.valueOf(String.valueOf(fieldValue)) <= Date.valueOf(String.valueOf(defaultValueStr));
                } else if (fieldValue instanceof DateTime) {
                    return DateTime.valueOf(String.valueOf(fieldValue)) <= DateTime.valueOf(String.valueOf(defaultValueStr));
                } else if (fieldValue instanceof Decimal) {
                    return Decimal.valueOf(String.valueOf(fieldValue)) <= Decimal.valueOf(String.valueOf(defaultValueStr)) ;
                } else {
                    return false; 
                }
            }
            when else {
                return true; // Default case, assume valid
            }
        }
    }
    
    private String comparisonErrorMessage(Object fieldValue, Object defaultValue) {
        return 'Field value: ' + String.valueOf(fieldValue) + ' does not match default value: ' + String.valueOf(defaultValue);
    }
}