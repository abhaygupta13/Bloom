/***
Class       : CaseInstallmentTriggerHandler 
Author      : Sonali S
Description : 
TestClass   : CaseInstallmentTriggerHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  Version    Date        Author      Details
1.      V1.0       15/04/25    Sonali S    Initial Version 
****************************************************************************************************************/

public class CaseInstallmentTriggerHandler implements ITriggerHandler {

    // Use this variable to disable this trigger from transaction
    public static Boolean isTriggerDisabled = false;

    // Check if the trigger is disabled from transaction
    public Boolean isDisabled() { 
        return isTriggerDisabled;
    }

    public void beforeInsert(List<SObject> newList) {
        // Implement logic if needed
    }

    public void afterInsert(List<SObject> newList, Map<Id, SObject> newMap) {   
        
    }

    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) {
        // Implement logic if needed
    }

    public void afterUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) {
         CaseInstallmentTriggerHelper.handleAfterUpdate(newList,(Map<Id,CaseInstallment__c>)oldMap); 
    }

    public void beforeDelete(List<SObject> oldList, Map<Id, SObject> oldMap) {
        // Implement logic if needed
    }

    public void afterDelete(List<SObject> oldList, Map<Id, SObject> oldMap) {
        // Implement logic if needed
    }

    public void afterUnDelete(List<SObject> newList, Map<Id, SObject> newMap) {
        // Implement logic if needed
    }
}