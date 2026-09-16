public without sharing class ContentDocumentLinkTriggerHandler implements ITriggerHandler {
    
    //Use this variable to disable this trigger from transaction
    public static Boolean isTriggerDisabled = false;
    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled() {
        return isTriggerDisabled;
    }
    
    public void beforeInsert(List<sObject> newList) {
        ContentDocumentLinkTriggerHelper.handleFileBeforeInsert((List<ContentDocumentLink>) newList);
    }
    
    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
        ContentDocumentLinkTriggerHelper.handleAfterFileInsert((List<ContentDocumentLink>) newList);
        ContentDocumentLinkTriggerHelper.createContentDitributionForNotification(newList);
        ContentDocumentLinkTriggerHelper.moveLeasingSignedFilesToDocument((List<ContentDocumentLink>) newList);
     ContentDocumentLinkTriggerHelper.moveSignedKYCFilesToDocument((List<ContentDocumentLink>) newList);
    }
    
    public void beforeUpdate(
        List<sObject> newList,
        Map<Id, sObject> newMap,
        List<sObject> oldList,
        Map<Id, sObject> oldMap) {
        }
    
    public void afterUpdate(
        List<sObject> newList,
        Map<Id, sObject> newMap,
        List<sObject> oldList,
        Map<Id, sObject> oldMap) {
        }
    
    public void beforeDelete(List<sObject> oldList, Map<Id, sObject> oldMap) {
    }
    
    public void afterDelete(List<sObject> oldList, Map<Id, sObject> oldMap) {
    }
    
    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
    }
}