/***
Class       : HandoverAsyncTriggerHandler
Author      : Jhilik
Description : 
TestClass   : HandoverAsyncTriggerHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.     version              Date                      Details
1.          V1.0                07-10-2025                Initial Version 
****************************************************************************************************************/
public without sharing class HandoverAsyncTriggerHandler implements IAsyncTriggerHandler {
    private static final string PHPP_HANDOVER_RT_DEV_NAME { get { return 'Handover_PHPP'; } }
    
    //Use this variable to disable this trigger from transaction
    public static Boolean isAsyncTriggerDisabled = false;
    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled(){
        return isAsyncTriggerDisabled;
    }

    Set<Id> completedHandoverIdsSet = new Set<Id>();
    List<Id> completedHandoverIdsList = new List<Id>();
    
    public void changeEventCapture(List<sObject> newList) {
        
        List<Handover__ChangeEvent> objHandoverChangeEventList =  (List<Handover__ChangeEvent>)newList;

        List<Id> crmHandoverIdList = new List<Id>();
        List<Id> handoverRecordIdList = new List<Id>();
        List<Id> handoverRecordIdListWithStatusUpdate = new List<Id>();
        List<Id> potentialDefaulterHandoverRecordIdList = new List<Id>();
        Map<String,List<Id>> statusToHandoverIdMap = new Map<String,List<Id>>();
        HandoverService servObj = HandoverService.getInstance();
        

        for (Handover__ChangeEvent event : objHandoverChangeEventList) {
            //Get event header fields
            EventBus.ChangeEventHeader header = event.ChangeEventHeader;
            switch on header.changeType {
                when 'CREATE'{
                    //handoverRecordIdList.addAll(header.getRecordIds());  
                    crmHandoverIdList.addAll(header.getRecordIds());
                    handoverRecordIdListWithStatusUpdate.addAll(header.getRecordIds());
                }
                when 'UPDATE'{
                    if(event.get('Sub_Status__c') != NULL){
                        System.debug('event.getSub_Status__c ::::: '+ event.get('Sub_Status__c'));
                        if(event.get('Sub_Status__c') == 'Potential Defaulter'){
                            potentialDefaulterHandoverRecordIdList.addAll(header.getRecordIds());
                        } else {
                            handoverRecordIdListWithStatusUpdate.addAll(header.getRecordIds());
                        }
                    }
                    if((Boolean)event.get('Is_Property_keys_given__c')){
                        completedHandoverIdsList.addAll(header.getRecordIds());
                    }
                }
                when 'DELETE'{ 
                }
                when 'UNDELETE'{
                }
            }
        }

        if(!completedHandoverIdsList.isEmpty()){
            completedHandoverIdsSet.addAll(completedHandoverIdsList);
            SurveyHandler.sendHandoverSurvey(completedHandoverIdsSet);
        }

        /* if(!handoverRecordIdList.isEmpty()){
            List<Handover__c> handoverRecordList = servObj.getHandoverByIds(new Set<Id>(handoverRecordIdList));
            PHPPHandoverHandler obj = PHPPHandoverHandler.getInstance();
            obj.createFirstTask(handoverRecordList); 
        } */

        if(!potentialDefaulterHandoverRecordIdList.isEmpty()){
            List<Handover__c> handoverRecordList = servObj.getHandoverByIds(new Set<Id>(potentialDefaulterHandoverRecordIdList));
            HandoverHandler objHandoverHandler = HandoverHandler.getInstance();
            objHandoverHandler.createPotentialDefaulterCase(handoverRecordList);
        }

        if(!handoverRecordIdListWithStatusUpdate.isEmpty()){
            List<Handover__c> handoverRecordList = servObj.getHandoverByIds(new Set<Id>(handoverRecordIdListWithStatusUpdate));
            HandoverHandler objHandoverHandler = HandoverHandler.getInstance();
            objHandoverHandler.createNewAndCloseCurrentTask(handoverRecordList, true);
        }
    }
}