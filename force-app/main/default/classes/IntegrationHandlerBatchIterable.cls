/*
* @Author : Biswajeet Samal
* @CreatedDate : 7th AUG 2024
* @Description : Bulk integration handler in a batch class
*/
/*****************************************************************************************************
* Version       Author      Date             Comment                                              
* 1.0           Biswajeet   07AUG2024        Initial draft 
* 2.0           Jayprakash  20AUG2024        Implemented GIS Integration
*****************************************************************************************************/
public without sharing class IntegrationHandlerBatchIterable implements Database.Batchable<SObject>, Database.AllowsCallouts{
    
    private string integrationType {get;set;}
    private string integrationAction {get;set;}
    private List<Sobject> recordList {get;set;}
    private SObjectType sObjType {get;set;}
    //private batchIterable iterable;
    
    public IntegrationHandlerBatchIterable(String integrationType, String integrationAction, List<Sobject> recordList, SObjectType sObjType){
        this.integrationType = integrationType;
        this.integrationAction = integrationAction;
        this.recordList = recordList;
        this.sObjType = sObjType;
        //this.iterable = new batchIterable(this.recordList);
    }
    
    public Iterable<sObject> start(Database.BatchableContext BC) {        	
        //write coder to update Recordlist if needed
        return recordList;
    }
    
    public void execute(Database.BatchableContext BC, List<sObject> sObjList) {
        //call the integration handler methods
        switch on String.valueOf(integrationType+'_'+integrationAction+'_'+sObjType) {
            when 'GIS_Update_Unit__c' {
                GISIntegrationService gisService = GISIntegrationService.getInstance();
                gisService.getUnitList(sObjList);
                gisService.executeIntegration();
            }   
        }
    }
    
    public void finish(Database.BatchableContext BC) {}
    
    // Iterable class
    /*class batchIterable implements Iterable<SObject> {
        private List<SObject> records;        
        public batchIterable(List<SObject> records) {
            this.records = records;
        }
        public Iterator<SObject> iterator() {
            return records.iterator();
        }
    }*/
}