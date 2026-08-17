/*
* @Author : Biswajeet Samal
* @CreatedDate : 7th AUG 2024
* @Description : Integration common service class
*/
/*****************************************************************************************************
* Version       Author      Date             Comment                                                                       
* 1.0           Biswajeet   07AUG2024        Initial draft 
* 2.0           Jayprakash  20AUG2024        Implemented GIS Integration
* 3.0           Jayprakash  20AUG2024        GIS update batchSize Limit
*****************************************************************************************************/
public class IntegrationService {
    
    //Start: v3.0 change
    private static final string MDT_GIS_TOKEN_INTEGRATION_SETTING { get{return 'GISIntegrationSetting'; } }
    //End: v3.0 change
    
    private static IntegrationService instance;
    
    private IntegrationService() {
        
    }
    
    public static IntegrationService getInstance() {
        if(instance == null) {
            instance = new IntegrationService();
        }
        return instance;
    }
    
    public void handleIntegrations(String integrationType, String integrationAction, List<Sobject> recordList, SObjectType sObjType){
        if(Trigger.isExecuting && !System.isBatch() && !System.isFuture() && !System.isQueueable()){
            handleAsyncIntegrations(integrationType, integrationAction, recordList, sObjType);
        }else{
            
        }
    }
    
    public void handleAsyncIntegrations(String integrationType, String integrationAction, List<Sobject> recordList, SObjectType sObjType){
        //Start: v3.0 change
        if(recordList != NULL){
            MetadataService objMetadataService = MetadataService.getInstance();
            Integration_Details__mdt objIntegrationdetails = objMetadataService.getIntegrationDetails(MDT_GIS_TOKEN_INTEGRATION_SETTING);
            if(recordList.size() <= Integer.valueOf(objIntegrationdetails?.QueueableCount__c) ?? null ){
                System.enqueueJob(new IntegrationHandlerQueueable(integrationType, integrationAction, recordList, sObjType));
            }else{
                Database.executeBatch(new IntegrationHandlerBatchIterable(integrationType, integrationAction, recordList, sObjType), Integer.valueOf(objIntegrationdetails?.BatchRecordCount__c)  );
            }
        }
        //End: v3.0 change
    }
    
    public void handleSyncIntegrations(String integrationType, String integrationAction, List<Sobject> recordList, SObjectType sObjType){
        
    }
    
    public IntegrationEvent__e getIntegrationEvent(String action, String objectApiName, Id recordId, Map<String, String> paramMap ){
        
        IntegrationEvent__e eventInstance = new IntegrationEvent__e(
            Action__c = Action,
            ObjectAPIName__c = ObjectApiName,
            RecordId__c = recordId,
            Param1__c = paramMap.containsKey('Param1') ? paramMap.get('Param1') : null,
            Param2__c = paramMap.containsKey('Param2') ? paramMap.get('Param2') : null,
            Param3__c = paramMap.containsKey('Param3') ? paramMap.get('Param3') : null,
            Param4__c = paramMap.containsKey('Param4') ? paramMap.get('Param4') : null,
            Param5__c = paramMap.containsKey('Param5') ? paramMap.get('Param5') : null,
            Param6__c = paramMap.containsKey('Param6') ? paramMap.get('Param6') : null,
            Param7__c = paramMap.containsKey('Param7') ? paramMap.get('Param7') : null,
            Param8__c = paramMap.containsKey('Param8') ? paramMap.get('Param8') : null,
            Param9__c = paramMap.containsKey('Param9') ? paramMap.get('Param9') : null,
            Param10__c = paramMap.containsKey('Param10') ? paramMap.get('Param10') : null,
            Param11__c = paramMap.containsKey('Param11') ? paramMap.get('Param11') : null,
            Param12__c = paramMap.containsKey('Param12') ? paramMap.get('Param12') : null,
            Param13__c = paramMap.containsKey('Param13') ? paramMap.get('Param13') : null,
            Param14__c = paramMap.containsKey('Param14') ? paramMap.get('Param14') : null,
            Param15__c = paramMap.containsKey('Param15') ? paramMap.get('Param15') : null,
            Param16__c = paramMap.containsKey('Param16') ? paramMap.get('Param16') : null,
            Param17__c = paramMap.containsKey('Param17') ? paramMap.get('Param17') : null,
            Param18__c = paramMap.containsKey('Param18') ? paramMap.get('Param18') : null,
            Param19__c = paramMap.containsKey('Param19') ? paramMap.get('Param19') : null,
            Param20__c = paramMap.containsKey('Param20') ? paramMap.get('Param20') : null,
            Param21__c = paramMap.containsKey('Param21') ? paramMap.get('Param21') : null,
            Param22__c = paramMap.containsKey('Param22') ? paramMap.get('Param22') : null,
            Param23__c = paramMap.containsKey('Param23') ? paramMap.get('Param23') : null,
            Param24__c = paramMap.containsKey('Param24') ? paramMap.get('Param24') : null,
            Param25__c = paramMap.containsKey('Param25') ? paramMap.get('Param25') : null,
            Param26__c = paramMap.containsKey('Param26') ? paramMap.get('Param26') : null,
            Param27__c = paramMap.containsKey('Param27') ? paramMap.get('Param27') : null,
            Param28__c = paramMap.containsKey('Param28') ? paramMap.get('Param28') : null,
            Param29__c = paramMap.containsKey('Param29') ? paramMap.get('Param29') : null,
            Param30__c = paramMap.containsKey('Param30') ? paramMap.get('Param30') : null,
            Param31__c = paramMap.containsKey('Param31') ? paramMap.get('Param31') : null,
            Param32__c = paramMap.containsKey('Param32') ? paramMap.get('Param32') : null,
            Param33__c = paramMap.containsKey('Param33') ? paramMap.get('Param33') : null,
            Param34__c = paramMap.containsKey('Param34') ? paramMap.get('Param34') : null
            
        );
        return eventInstance;         
    }
    
    public IntegrationEvent__e getIntegrationEvent(String action, String objectApiName,String subAction, String userType, Id recordId, Map<String, String> paramMap ){
        
        IntegrationEvent__e eventInstance = new IntegrationEvent__e(
            Action__c = Action,
            ObjectAPIName__c = ObjectApiName,
            SubAction__c = SubAction,
            userType__c = userType,
            RecordId__c = recordId,
            Param1__c = paramMap.containsKey('Param1') ? paramMap.get('Param1') : null,
            Param2__c = paramMap.containsKey('Param2') ? paramMap.get('Param2') : null,
            Param3__c = paramMap.containsKey('Param3') ? paramMap.get('Param3') : null,
            Param4__c = paramMap.containsKey('Param4') ? paramMap.get('Param4') : null,
            Param5__c = paramMap.containsKey('Param5') ? paramMap.get('Param5') : null,
            Param6__c = paramMap.containsKey('Param6') ? paramMap.get('Param6') : null,
            Param7__c = paramMap.containsKey('Param7') ? paramMap.get('Param7') : null,
            Param8__c = paramMap.containsKey('Param8') ? paramMap.get('Param8') : null,
            Param9__c = paramMap.containsKey('Param9') ? paramMap.get('Param9') : null,
            Param10__c = paramMap.containsKey('Param10') ? paramMap.get('Param10') : null,
            Param11__c = paramMap.containsKey('Param11') ? paramMap.get('Param11') : null,
            Param12__c = paramMap.containsKey('Param12') ? paramMap.get('Param12') : null,
            Param13__c = paramMap.containsKey('Param13') ? paramMap.get('Param13') : null,
            Param14__c = paramMap.containsKey('Param14') ? paramMap.get('Param14') : null,
            Param15__c = paramMap.containsKey('Param15') ? paramMap.get('Param15') : null,
            Param16__c = paramMap.containsKey('Param16') ? paramMap.get('Param16') : null,
            Param17__c = paramMap.containsKey('Param17') ? paramMap.get('Param17') : null,
            Param18__c = paramMap.containsKey('Param18') ? paramMap.get('Param18') : null,
            Param19__c = paramMap.containsKey('Param19') ? paramMap.get('Param19') : null,
            Param20__c = paramMap.containsKey('Param20') ? paramMap.get('Param20') : null,
            Param21__c = paramMap.containsKey('Param21') ? paramMap.get('Param21') : null,
            Param22__c = paramMap.containsKey('Param22') ? paramMap.get('Param22') : null,
            Param23__c = paramMap.containsKey('Param23') ? paramMap.get('Param23') : null,
            Param24__c = paramMap.containsKey('Param24') ? paramMap.get('Param24') : null,
            Param25__c = paramMap.containsKey('Param25') ? paramMap.get('Param25') : null,
            Param26__c = paramMap.containsKey('Param26') ? paramMap.get('Param26') : null,
            Param27__c = paramMap.containsKey('Param27') ? paramMap.get('Param27') : null,
            Param28__c = paramMap.containsKey('Param28') ? paramMap.get('Param28') : null,
            Param29__c = paramMap.containsKey('Param29') ? paramMap.get('Param29') : null,
            Param30__c = paramMap.containsKey('Param30') ? paramMap.get('Param30') : null,
            Param31__c = paramMap.containsKey('Param31') ? paramMap.get('Param31') : null,
            Param32__c = paramMap.containsKey('Param32') ? paramMap.get('Param32') : null,
            Param33__c = paramMap.containsKey('Param33') ? paramMap.get('Param33') : null,
            Param34__c = paramMap.containsKey('Param34') ? paramMap.get('Param34') : null
        );
        return eventInstance;         
    }
    
    public IntegrationEvent__e getIntegrationEvent(String integrationType, String action, String objectAPIName, String SubAction,
                                                   String userType, Id recordId, Map<String, String> paramMap){
        
        IntegrationEvent__e eventInstance = new IntegrationEvent__e(
            Action__c = Action,
            ObjectAPIName__c = ObjectApiName,
            SubAction__c = SubAction,
            userType__c = userType,
            RecordId__c = recordId,
            Type__c = integrationType,
            Param1__c = paramMap.containsKey('Param1') ? paramMap.get('Param1') : null,
            Param2__c = paramMap.containsKey('Param2') ? paramMap.get('Param2') : null,
            Param3__c = paramMap.containsKey('Param3') ? paramMap.get('Param3') : null,
            Param4__c = paramMap.containsKey('Param4') ? paramMap.get('Param4') : null,
            Param5__c = paramMap.containsKey('Param5') ? paramMap.get('Param5') : null,
            Param6__c = paramMap.containsKey('Param6') ? paramMap.get('Param6') : null,
            Param7__c = paramMap.containsKey('Param7') ? paramMap.get('Param7') : null,
            Param8__c = paramMap.containsKey('Param8') ? paramMap.get('Param8') : null,
            Param9__c = paramMap.containsKey('Param9') ? paramMap.get('Param9') : null,
            Param10__c = paramMap.containsKey('Param10') ? paramMap.get('Param10') : null,
            Param11__c = paramMap.containsKey('Param11') ? paramMap.get('Param11') : null,
            Param12__c = paramMap.containsKey('Param12') ? paramMap.get('Param12') : null,
            Param13__c = paramMap.containsKey('Param13') ? paramMap.get('Param13') : null,
            Param14__c = paramMap.containsKey('Param14') ? paramMap.get('Param14') : null,
            Param15__c = paramMap.containsKey('Param15') ? paramMap.get('Param15') : null,
            Param16__c = paramMap.containsKey('Param16') ? paramMap.get('Param16') : null,
            Param17__c = paramMap.containsKey('Param17') ? paramMap.get('Param17') : null,
            Param18__c = paramMap.containsKey('Param18') ? paramMap.get('Param18') : null,
            Param19__c = paramMap.containsKey('Param19') ? paramMap.get('Param19') : null,
            Param20__c = paramMap.containsKey('Param20') ? paramMap.get('Param20') : null,
            Param21__c = paramMap.containsKey('Param21') ? paramMap.get('Param21') : null,
            Param22__c = paramMap.containsKey('Param22') ? paramMap.get('Param22') : null,
            Param23__c = paramMap.containsKey('Param23') ? paramMap.get('Param23') : null,
            Param24__c = paramMap.containsKey('Param24') ? paramMap.get('Param24') : null,
            Param25__c = paramMap.containsKey('Param25') ? paramMap.get('Param25') : null,
            Param26__c = paramMap.containsKey('Param26') ? paramMap.get('Param26') : null,
            Param27__c = paramMap.containsKey('Param27') ? paramMap.get('Param27') : null,
            Param28__c = paramMap.containsKey('Param28') ? paramMap.get('Param28') : null,
            Param29__c = paramMap.containsKey('Param29') ? paramMap.get('Param29') : null,
            Param30__c = paramMap.containsKey('Param30') ? paramMap.get('Param30') : null,
            Param31__c = paramMap.containsKey('Param31') ? paramMap.get('Param31') : null,
            Param32__c = paramMap.containsKey('Param32') ? paramMap.get('Param32') : null,
            Param33__c = paramMap.containsKey('Param33') ? paramMap.get('Param33') : null,
            Param34__c = paramMap.containsKey('Param34') ? paramMap.get('Param34') : null,
            LongTextParam1__c = paramMap.containsKey('LongTextParam1') ? paramMap.get('LongTextParam1') : null,
            LongTextParam2__c = paramMap.containsKey('LongTextParam2') ? paramMap.get('LongTextParam2') : null
        );
        return eventInstance;         
    }
    
}