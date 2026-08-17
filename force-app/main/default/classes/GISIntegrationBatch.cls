/*****************************************************************************************
Class       : GISIntegrationBatch
Author      : Biswajeet
Description : GIS Integration Batch
Test Class  : GISIntegrationBatchTest
Created Date: 24 JUL 2025 
*****************************************************************************************/
public class GISIntegrationBatch implements Database.Batchable<SObject>, Schedulable {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id, Project__c, ADMPlotNumber__c, GIS_Object_Id__c,
                                         Status__c, Net_Amount_Selling_Price__c, UnitType__c,
                                         UnitModel__c, PlotArea__c, Customer_Name__c,
                                         Send_to_GIS__c, GISServiceQueryURL__c,
                                         SaleableArea__c, GISServiceURL__c, GIS_Plot_No__c
                                         FROM Unit__c WHERE Project__r.GIS_Service_URL__c != NULL]);
    }
    
    public void execute(Database.BatchableContext bc, List<Unit__c> unitList) {
        List<IntegrationRecord__c> objIntegrationRecordList = new List<IntegrationRecord__c>();
        for (Unit__c record : unitList){
            record.Send_to_GIS__c = true;
        }
        UnitService.getInstance().updateUnits(unitList);
    }
    
    public void finish(Database.BatchableContext bc) {
        
    }
    
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new GISIntegrationBatch(), 1);
    }
}