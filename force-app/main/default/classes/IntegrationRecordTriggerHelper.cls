/*****************************************************************************************
Class       : IntegrationRecordTriggerHelper
Author      : Vikas Baliyan
Description : Integration Record Trigger Helper
Test Class  : IntegrationRecordTriggerHelperTest
Created Date: 12 DEC 2024 
*****************************************************************************************/

public without sharing class IntegrationRecordTriggerHelper {
    
    public static void invokePlatformEvent(List<IntegrationRecord__c> newList){
        IntegrationService objIntegrationService = IntegrationService.getInstance();
        List<IntegrationEvent__e> eventToPublish = new List<IntegrationEvent__e>();
        
        for(IntegrationRecord__c record: newList){
            Map<String,String> paramsMap = new Map<String,String>();
            paramsMap.put('Param1',record.Param1__c);
            paramsMap.put('Param2',record.Param2__c);
            paramsMap.put('Param3',record.Param3__c);
            paramsMap.put('Param4',record.Param4__c);
            paramsMap.put('Param5',record.Param5__c);
            paramsMap.put('Param6',record.Param6__c);
            paramsMap.put('Param7',record.Param7__c);
            paramsMap.put('Param8',record.Param8__c);
            paramsMap.put('Param9',record.Param9__c);
            paramsMap.put('Param10',record.Param10__c);
            paramsMap.put('Param11',record.Param11__c);
            paramsMap.put('Param12',record.Param12__c);
            paramsMap.put('Param13',record.Param13__c);
            paramsMap.put('Param14',record.Param14__c);
            paramsMap.put('Param15',record.Param15__c);
            paramsMap.put('Param16',record.Param16__c);
            paramsMap.put('Param17',record.Param17__c);
            paramsMap.put('Param18',record.Param18__c);
            paramsMap.put('Param19',record.Param19__c);
            paramsMap.put('Param20',record.Param20__c);
            paramsMap.put('Param21',record.Param21__c);
            paramsMap.put('Param22',record.Param22__c);
            paramsMap.put('Param23',record.Param23__c);
            paramsMap.put('Param24',record.Param24__c);
            paramsMap.put('Param25',record.Param25__c);
            paramsMap.put('Param26',record.Param26__c);
            paramsMap.put('Param27',record.Param27__c );
            paramsMap.put('Param28',record.Param28__c);
            paramsMap.put('Param29',record.Param29__c);
            paramsMap.put('Param30',record.Param30__c);
            paramsMap.put('Param31',record.Param31__c);
            paramsMap.put('Param32',record.Param32__c);
            paramsMap.put('Param33',record.Param33__c);
            paramsMap.put('Param34',record.Param34__c);
            paramsMap.put('LongTextParam1',record.LongTextParam1__c);
            IntegrationEvent__e eventInstance = objIntegrationService.getIntegrationEvent(
                 record.Type__c,
                record.Action__c,
                record.ObjectAPIName__c,
                record.SubAction__c,
                record.userType__c,
                record.RecordId__c,
                paramsMap
            );
            eventToPublish.add(eventInstance);
        }
        //publish the event
        if(!eventToPublish.isEmpty()){
            List<Database.SaveResult> results = EventBus.publish(eventToPublish);
        }
    }
}