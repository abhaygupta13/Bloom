/*****************************************************************************************
Class       : IntegrationRecordService
Author      : Vikas Baliyan
Description : Integration Record Service
Test Class  : 
Created Date: 12 DEC 2024 
*****************************************************************************************/
public inherited sharing class IntegrationRecordService {
    
    private static IntegrationRecordService instance;
    
    private IntegrationRecordService() { }
    
    public static IntegrationRecordService getInstance() {
        if(instance == null) {
            instance = new IntegrationRecordService();
        }
        return instance;
    }
    
    public List<IntegrationRecord__c> insertIntegrationRecords(List<IntegrationRecord__c> integrationRecordList){
        if(integrationRecordList != NULL && !integrationRecordList.isEmpty()){
            insert integrationRecordList;
        }
        return integrationRecordList;
    }
    
    public IntegrationRecord__c getIntegrationRecord(String Action, String ObjectApiName, String recordId, String Param1, String Param2, String Param3, String Param4, String Param5, String Param6, String Param7 ,String Param8, String Param9, String Param10, String Param11, String Param12, String Param13, String Param14, String Param15, String Param16, String Param17, String Param18 ){
        IntegrationRecord__c integrationRecord = new IntegrationRecord__c(
            Action__c = Action,
            ObjectAPIName__c = ObjectApiName,
            RecordId__c = recordId,
            Param1__c = Param1,
            Param2__c = Param2,
            Param3__c = Param3,
            Param4__c = Param4,
            Param5__c = Param5,
            Param6__c = Param6,
            Param7__c = Param7,
            Param8__c = Param8,
            Param9__c = Param9,
            Param10__c = Param10,
            Param11__c = Param11,
            Param12__c = Param12,
            Param13__c = Param13,
            Param14__c = Param14,
            Param15__c = Param15,
            Param16__c = Param16,
            Param17__c = Param17,
            Param18__c = Param18
        );
        return integrationRecord;        
    }
    
    public IntegrationRecord__c getIntegrationRecord(String action, String objectApiName, String recordId, Map<String,String> paramMap){
        IntegrationRecord__c integrationRecord = new IntegrationRecord__c(
            Action__c = action,
            ObjectAPIName__c = objectApiName,
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
        return integrationRecord;        
    } 
    
    public IntegrationRecord__c getIntegrationRecord(String integrationType, String action, String SubAction, 
                                                     String userType, String objectApiName, String recordId, 
                                                     Map<String,String> paramMap){
                                                         IntegrationRecord__c integrationRecord = new IntegrationRecord__c(
                                                             Action__c = action,
                                                             ObjectAPIName__c = objectApiName,
                                                             RecordId__c = recordId,
                                                             SubAction__c = SubAction,
                                                             userType__c = userType,
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
                                                             Param34__c = paramMap.containsKey('Param34') ? paramMap.get('Param34') : null
                                                         );
                                                         return integrationRecord;        
                                                     } 
    
    public IntegrationRecord__c getIntegrationRecord(String integrationType, String action, String objectApiName, String recordId, 
                                                     Map<String,String> paramMap){
                                                         IntegrationRecord__c integrationRecord = new IntegrationRecord__c(
                                                             Action__c = action,
                                                             ObjectAPIName__c = objectApiName,
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
                                                         return integrationRecord;        
                                                     }
    
    public IntegrationRecord__c getIntegrationRecord(String integrationType, String action, String SubAction, String objectApiName, String recordId,  Map<String,String> paramMap){
        IntegrationRecord__c integrationRecord = new IntegrationRecord__c(
            Action__c = action,
            ObjectAPIName__c = objectApiName,
            RecordId__c = recordId,
            SubAction__c = SubAction,
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
            Param34__c = paramMap.containsKey('Param34') ? paramMap.get('Param34') : null
        );
        return integrationRecord;        
    } 
}