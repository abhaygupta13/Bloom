/***
Class       : LeasingMoveOutFormBatch
Author      : 
Description : Batch class to send terminationnotice to customers
TestClass   : 
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              04/11/2025           Initial Version 
****************************************************************************************************************/
public class LeasingMoveOutFormBatch implements Database.Batchable<SObject>, Database.allowsCallouts, Schedulable{
    private static final String LEASING_ORDER_TERMINATION_STATUS {get {return 'Terminated';}}
    private static final string MOVE_OUT_REQUEST_FORM { get { return 'Move Out Request Form'; } }
    private static final string LEASING_ORDER_API_NAME { get { return 'LeasingOrder__c'; } } 
    private static final String BATCH_SIZE_METADATA {get {return 'LeasingMoveOutNoticeBatch';}}

    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator('SELECT Id, PropertyName__c, Unit__r.LeasingUnitNumber__c ' +
            'FROM LeasingOrder__c ' +
            'WHERE TerminationNoticeDate__c = TODAY AND Status__c = \'' + LEASING_ORDER_TERMINATION_STATUS + '\'');
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope){
        DocumentTypeService dtService = DocumentTypeService.getInstance();
        DocumentType__c requiredDt;
        
        for(DocumentType__c dt : dtService.getActiveDocuGenDocumentTypeRecords(LEASING_ORDER_API_NAME)){
            if(dt.Type__c == MOVE_OUT_REQUEST_FORM){
                requiredDt = dt;
                break;
            }
        }
        if(requiredDt != Null){
            for(LeasingOrder__c lo : (list<LeasingOrder__c>)scope){
                LeasingDocGenController.sendForSignature(lo,requiredDt);
            }
        }
    }

    public void finish(Database.BatchableContext bc){

    }
    
    
    public void execute(SchedulableContext sc) {
        MetadataService mtdtService = MetadataService.getInstance();
        LeasingMoveOutFormBatch batchJob = new LeasingMoveOutFormBatch();
        Database.executeBatch(batchJob, mtdtService.getAppSettingNumberValue(BATCH_SIZE_METADATA) != Null ? mtdtService.getAppSettingNumberValue(BATCH_SIZE_METADATA) : 5); 
    }
}