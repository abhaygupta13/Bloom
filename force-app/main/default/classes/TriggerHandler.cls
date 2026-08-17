/***
Class       : TriggerHandler
Author      : Smaartt
Description : 
TestClass   : ReceiptAcknowledgementTriggerHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              27/04/23           Initial Version 
****************************************************************************************************************/
public with sharing virtual class TriggerHandler {
    
    public static Set<Id> processedIds {get;set;}
    private static SystemConfiguration__mdt triggerConfig {get;set;}
    
    static {
        processedIds = new Set<Id>();
    }
    
    public void run(String objectName) {
        
        if (triggerConfig == null || (triggerConfig!=null && triggerConfig.MasterLabel != objectName)) {
            triggerConfig = Utilities.getSystemInformation(objectName);
            
        }
        
        system.debug('Trigger configurations' + triggerConfig);
        if (triggerConfig != null && triggerConfig.IsRunTrigger__c) {
            
            if (Trigger.isBefore && Trigger.isInsert && triggerConfig.IsRunBeforeInsert__c) {
                this.beforeInsert();
            } else if (Trigger.isBefore && Trigger.isUpdate && triggerConfig.IsRunBeforeUpdate__c) {
                this.beforeUpdate();
            } else if (Trigger.isAfter && Trigger.isInsert && triggerConfig.IsRunAfterInsert__c) {
                this.afterInsert();
            } else if(Trigger.isAfter && Trigger.isUpdate && triggerConfig.IsRunAfterUpdate__c) {
                this.afterUpdate();
            } else if(Trigger.isBefore && Trigger.isdelete && triggerConfig.IsRunBeforeDelete__c) {
                this.beforeDelete();
            } else if(Trigger.isAfter && Trigger.isdelete && triggerConfig.IsRunAfterDelete__c) {
                this.afterDelete();
            }
        }
    } 
    
    /** Preprocessing Methods **/
    protected void beforeInsert() {
        this.beforeInsertMethod(this.newList(), this.newMap());
    }
    
    protected void beforeUpdate() {
        this.beforeUpdateMethod(this.newList(), this.newMap(), this.oldList(), this.oldMap());
    }
    
    protected void beforeDelete() {
        this.beforeDeleteMethod(this.oldList(), this.oldMap());
    }
    
    protected void afterInsert() {
        Map<Id, SObject> newMap = this.newMap();
        List<SObject> newList = this.newList();
        addProcessedIds(Trigger.New);
        this.afterInsertMethod(newList, newMap);
    }
    
    protected void afterUpdate() {
        Map<Id, SObject> newMap = this.newMap();
        List<SObject> newList = this.newList();
        Map<Id, SObject> oldMap = this.oldMap();
        List<SObject> oldList = this.oldList();
        addProcessedIds(Trigger.New);
        this.afterUpdateMethod(newList, newMap, oldList, oldMap);
    }
    
    protected void afterDelete() {
        this.afterDeleteMethod(this.oldList(), this.oldMap());
    }
    
    
    /** Methods to override in the Trigger Handlers extending this class **/
    //*** Before Insert Action***//
    protected virtual void beforeInsertMethod(List<SObject> newList, Map<Id, SObject> newMap){
        
        //Override me
    }
    
    //*** Before Update Action***//
    protected virtual void beforeUpdateMethod(list<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap){
        
        //Override me
    }
    
    //*** Before Delete Action***//
    protected virtual void beforeDeleteMethod(List<SObject> oldList, Map<Id, SObject> oldMap){
        
        //Override me
    }
    
    //*** After Insert Action***//
    protected virtual void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap){
        
        //Override me   
    }
    
    //*** After Update Action***//
    protected virtual void afterUpdateMethod(list<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap){
        
        //Override me
    }
    
    //*** After Delete Action***//
    protected virtual void afterDeleteMethod(List<SObject> oldList, Map<Id, SObject> oldMap){
        
        //Override me
    }
    
    /** Methods to handle recursion **/
    private static void addProcessedIds (List<SObject> sobjs) {
        
        for (SObject sobj : sobjs) {
            processedIds.add(sobj.Id);
        }
    }
    
    private static List<SObject> filterList (List<SObject> sobjs) {
        
        if (sobjs == null) return null;
        
        List<SObject> filteredList = new List<SObject>();
        
        for (SObject sobj : sobjs) {
            
            if (!processedIds.contains(sobj.Id)) 
                filteredList.add(sobj);
        }
        
        return filteredList;
    }
    
    private static Map<Id, SObject> filterMap (Map<Id, SObject> idToSObj) {
        
        if (idToSObj == null) return null;
        
        Map<Id, SObject> filteredMap = new Map<Id, SObject>();
        
        for (Id sobjId : idToSObj.keySet()) {
            
            if (!processedIds.contains(sobjId)) 
                filteredMap.put(sobjId, idToSObj.get(sobjId));
        }
        
        return filteredMap;
    }
    
    private List<SObject> newList() {
        
        return filterList(Trigger.new);
    }
    
    private Map<Id, SObject> newMap() {
        
        return filterMap(Trigger.newMap);
    }
    
    private List<SObject> oldList() {
        
        return filterList(Trigger.old);
    }
    
    private Map<Id, SObject> oldMap() {
        
        return filterMap(Trigger.oldMap);
    }
    
}