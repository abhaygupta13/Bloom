/*
* @Author : Biswajeet Samal
* @CreatedDate : 7th AUG 2024
* @Description : Unit object trigger helper
*/
/*****************************************************************************************************
* Version       Author      	Date             Comment                                                                       
* 1.0           Biswajeet   	07AUG2024        Initial draft                                                                 
* 2.0           Jayprakash   	12AUG2024        Added sendDetatoGIS() method
*****************************************************************************************************/
public class UnitTriggerHelper {
    
    private static final string INSTALLMENT_LINE_INTEGRATION_STATUS_IN_PROGRESS { get { return 'In Progress'; } }
    private static final string MTD_ENABLE_GIS_PE_INTEGRATION { get { return 'EnableGISPEIntegration'; } }
    
    public static void doPushToGIS(List<Unit__c> newList, Map<Id,Unit__c> oldMap){
        
        MetadataService objMetadataService = MetadataService.getInstance();
        UnitService objUnitService = UnitService.getInstance();
        IntegrationRecordService objIntegrationRecordService = IntegrationRecordService.getInstance();
        Boolean isEnableGISPEIntegration = objMetadataService.getAppSettingBooleanValue(MTD_ENABLE_GIS_PE_INTEGRATION);
        List<IntegrationRecord__c> objIntegrationRecordList = new List<IntegrationRecord__c>();
        Set<Unit__c> unitsToPushGIS = new Set<Unit__c>();
        for (Unit__c record : newList){
            if(record.Send_to_GIS__c && record.Send_to_GIS__c != oldMap.get(record.Id).Send_to_GIS__c){
                unitsToPushGIS.add(record);
                objIntegrationRecordList.add(objUnitService.getUnitGISIntegrationRecord(record));
            }
        }
        
        if(!unitsToPushGIS.isEmpty() && isEnableGISPEIntegration){
            IntegrationService igService = IntegrationService.getInstance();
            igService.handleIntegrations('GIS','Update',new List<Unit__c>(unitsToPushGIS), Unit__c.getSObjectType());
        }else{
            objIntegrationRecordService.insertIntegrationRecords(objIntegrationRecordList);
        }
    } 
    
    public static void assignHandoverToHOAgent(List<Unit__c> newUnitList, Map<Id,Unit__c> oldUnitMap){
        Map<String,String> unitIdWithHOAgent = new Map<String,String>();
        // check if the HO agent is changed on the unit.
        for(Unit__c unitObj : newUnitList){
            if(unitObj.HO_Agent__c != oldUnitMap.get(unitObj.Id).HO_Agent__c){
                unitIdWithHOAgent.put(unitObj.Id, unitObj.HO_Agent__c);
            }
        }
        // get all the handover for which unit HO Agent is changed
        List<Handover__c> handoverList = [SELECT ID, Unit__c, OwnerId from Handover__c WHERE Id IN : unitIdWithHOAgent.keySet()];
        for(Handover__c handOver : handoverList){
            handOver.OwnerId = unitIdWithHOAgent.get(handOver.OwnerId);
        }
        update handoverList;
    }  
    
    public static void createDocuments(List<Unit__c> newList){
        DocumentService objDocumentService = DocumentService.getInstance();
        List<DocumentType__c> projectDocTypeList = objDocumentService.getDocTypes('Unit');
        List<Document__c> documentList = new List<Document__c>();
        for(Unit__c unit :newList){
            for(DocumentType__c objDocumentType :projectDocTypeList){
                documentList.add(new Document__c(Unit__c = unit.Id, DocumentType__c = objDocumentType.Id, Document_Name__c = objDocumentType.Type__c));
            }
        }
        objDocumentService.insertDocuments(documentList);
    }
    
    public static void handleBeforeInsert(List<Unit__c> newList){
        for (Unit__c unit : newList) {            
            if (unit.GIS_Object_Id__c != NULL) {
                unit.Send_To_GIS__c = true;
                unit.GISIntegrationMessage__c = NULL;
                unit.GISIntegrationStatus__c = INSTALLMENT_LINE_INTEGRATION_STATUS_IN_PROGRESS;
            }
        } 
    }
    
    public static void handleBeforeUpdate(List<Unit__c> newList, Map<Id, Unit__c> oldMap){
        for (Unit__c unit : newList) {
            if (unit.SellingPrice__c != oldMap.get(unit.Id).SellingPrice__c
                || unit.Status__c != oldMap.get(unit.Id).Status__c
                || unit.UnitModel__c != oldMap.get(unit.Id).UnitModel__c
                || unit.UnitType__c != oldMap.get(unit.Id).UnitType__c
                || unit.PlotArea__c != oldMap.get(unit.Id).PlotArea__c
                || unit.SaleableArea__c != oldMap.get(unit.Id).SaleableArea__c
                || unit.Active_Sales_Order__c != oldMap.get(unit.Id).Active_Sales_Order__c) {
                    unit.Send_To_GIS__c = true;
                }
            if (unit.Send_To_GIS__c && !oldMap.get(unit.Id).Send_To_GIS__c) {
                unit.GISIntegrationStatus__c = INSTALLMENT_LINE_INTEGRATION_STATUS_IN_PROGRESS;
                unit.GISIntegrationMessage__c = NULL;
            }
        }
    }
}