public class ReceiptAllocationTriggerForDeleteHandler  implements ITriggerHandler{
    //Use this variable to disable this trigger from transaction
    public static Boolean isTriggerDisabled = false;
    Boolean isAdmin = false;
    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled(){
        return isTriggerDisabled;
    }
   
    public void beforeDelete(List<SObject> oldList, Map<Id, SObject> oldMap) { 
   for(User u : [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()]){
        if(u.Profile.Name == 'System Administrator'){
            isAdmin = true;
            break;
        }
    }
    
        
        for (SObject sobj : oldList) {
            ReceiptAllocation__c record = (ReceiptAllocation__c) sobj;
            if(!isAdmin)
            record.addError('You do not have permission to delete this record.');
        }
    }
    public void beforeInsert(List<sObject> newList) {
        
    }
    
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        
    }
    
    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {
        
    }
    
    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap,  List<sObject> oldList, Map<Id, sObject> oldMap) {
        
    }
    
    
    
    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
        
    }
    
    
    
}