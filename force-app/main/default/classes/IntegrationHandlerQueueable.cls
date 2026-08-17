/*
* @Author : Biswajeet Samal
* @CreatedDate : 7th AUG 2024
* @Description : Async integration handler
*/
/*****************************************************************************************************
* Version       Author      Date             Comment                                                                       
* 1.0           Biswajeet   07AUG2024        Initial draft                                                                 
* 2.0           Jayprakash  20AUG2024        Implemented GIS Integration
*****************************************************************************************************/
public without sharing class IntegrationHandlerQueueable implements Queueable, Database.AllowsCallouts{
    
    private string integrationType {get;set;}
    private string integrationAction {get;set;}
    private SObjectType sObjType {get;set;}
    private List<Sobject> recordList {get;set;}
    
    public IntegrationHandlerQueueable(String integrationType, String integrationAction, List<Sobject> recordList, SObjectType sObjType){
        this.integrationType = integrationType;
        this.integrationAction = integrationAction;
        this.recordList = recordList;
        this.sObjType = sObjType;
    }
    
    public void execute(QueueableContext qc){
        //call the integration handler methods
        switch on String.valueOf(integrationType+'_'+integrationAction+'_'+sObjType) {
            when 'GIS_Update_Unit__c' { //''
                GISIntegrationService gisService = GISIntegrationService.getInstance();
                gisService.getUnitList(this.recordList);
                gisService.executeIntegration();
            }   
        }        
    }
}