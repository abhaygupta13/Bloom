/*****************************************************************************************
Class       : SalesTargetService
Author      : Vikas Baliyan
Description : Sales Target Service
Test Class  : 
Created Date: 09 NOV 2024 
*****************************************************************************************/
public inherited sharing class SalesTargetService {

    private static SalesTargetService instance;
    
    private SalesTargetService() {
        
    }
    
    public static SalesTargetService getInstance() { 
        if(instance == null) {
            instance = new SalesTargetService();
        }
        return instance;
    }
    /*
    * update Sales Target record
    */
    public List<SalesTarget__c> updateSalesTarget(List<SalesTarget__c> salesTargetList){
        if(salesTargetList != NULL && !salesTargetList.isEmpty()){
            Database.update(salesTargetList, false);
        }
        return salesTargetList;
    }
    /*
    * upsert Sales Target record
    */
    public List<Database.UpsertResult> upsertSalesTargetByExternalIdentifier(List<SalesTarget__c> salesTargetList){
        List<Database.UpsertResult> srList = new List<Database.UpsertResult>();
        if(salesTargetList != NULL && !salesTargetList.isEmpty()){
            //Database.upsert(salesTargetList, upsertField);
            srList = Database.upsert(salesTargetList, SalesTarget__c.Fields.ExternalIdentifier__c);
        }
        return srList;
    }
}