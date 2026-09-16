/*
* @Author : Jayesh
* @CreatedDate : 12th Dec 2024
* @Description : Document object trigger handler
*/
/*****************************************************************************************************
* Version       Author      Date             Comment                                                                       
* 1.0           Jayesh     12DEC2024        Initial draft 
*****************************************************************************************************/
public class DocumentTriggerHandler implements ITriggerHandler{
    
    //Use this variable to disable this trigger from transaction
    public static Boolean isTriggerDisabled = false;
    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled(){
        return isTriggerDisabled;
    }
    
    public void beforeInsert(List<sObject> newList) {
        
    }
    
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {

    }
    
    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {
        
    }
    
    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap,  List<sObject> oldList, Map<Id, sObject> oldMap) {
        DocumentTriggerHelper.updateDocumentUploadDate((List<Document__c>) newList, (Map<Id, Document__c>) oldMap);
        
        DocumentTriggerHelper.sendEmailAlertToFinanceOwner((List<Document__c>) newList, (Map<Id, Document__c>) oldMap);
        
        //Added By Ranjan
        // NEW — Archive document when ContentDocumentId__c is replaced
        DocumentTriggerHelper.archiveDocument(
            (List<Document__c>) newList, 
            (Map<Id, Document__c>) oldMap
        );
        
    }
    
    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
        
    }
}