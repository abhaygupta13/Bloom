global with sharing class ConnectorTimeLogController {

    public ConnectorTimeLogController(Object o) { } 

    @RemoteAction
    global static softphone_it__ConnectorEventTimeLog__c createConnectorEventTimeLog(Map<String, Object> obj) {
        
        try{
        	Long callTime = (Long)(Decimal)obj.get('callTime'); 
            if ( callTime == null ){
                callTime = Datetime.now().getTime();
            }
            softphone_it__ConnectorEventTimeLog__c timeLog = new softphone_it__ConnectorEventTimeLog__c();
            timeLog.Name = (String)obj.get('interactionId');
            timeLog.softphone_it__Ringing_Time__c = DateTime.newInstance(callTime);
            //timeLog.Ringing_Time__c = DateTime.now();
            timeLog.softphone_it__Interaction_Id__c = (String)obj.get('interactionId');
            timeLog.softphone_it__Agent_Id__c = (String)obj.get('agentId');
            timeLog.softphone_it__Direction__c = (String)obj.get('callType');
            timeLog.softphone_it__Media_Type__c = (String)obj.get('mediaType');
                        
            Database.SaveResult sr =  Database.insert(timeLog);
            System.debug('save result : ' + sr);   
            return timeLog;
        } catch(Exception e){
            System.debug('Error in createConnectorEventTimeLog ' + e);     
        }
        
        return null;
    }
    
    @RemoteAction
    global static boolean updateConnectorEventTimeLog(Map<String, Object> obj) {
        boolean result = true;
        String interactionId = (String)obj.get('interactionId');
        String field = (String)obj.get('field');
        String state = (String)obj.get('state');
        Long callTime = (Long)(Decimal)obj.get('callTime');
        String disposition = (String)obj.get('disposition');
        DateTime value = DateTime.newInstance(callTime);
        String parentId = (String)obj.get('parentId');
        String caseId = (String)obj.get('caseId');
        String contactId = (String)obj.get('contactId');
        Integer interactionDuration = Integer.valueOf(obj.get('interactionDuration'));
         Integer totalAcdDuration = Integer.valueOf(obj.get('totalAcdDuration'));
         Integer totalIvrDuration = Integer.valueOf(obj.get('totalIvrDuration'));
         Integer dispositionDuration = Integer.valueOf(obj.get('dispositionDuration'));
        System.debug('caseid  : ' + caseId);
        try{ 
            List<softphone_it__ConnectorEventTimeLog__c> timeLogs = [Select id, softphone_it__established_Time__c from softphone_it__ConnectorEventTimeLog__c where softphone_it__Interaction_Id__c = :interactionId  order by softphone_it__ringing_time__c desc limit 1];
            
            System.debug('ConnectorEventTimeLog found : ' + timeLogs);
            
            if ( timelogs == null || timelogs.size() == 0 ){
                return null;
            }
            
            
            softphone_it__ConnectorEventTimeLog__c timelog = timelogs[0];
            timelog.put(field,value);
            if ( caseId != null && caseId != 'a' ){
                timelog.softphone_it__Case__c = caseId; 
            }
            if(contactId != null){
                timelog.softphone_it__Contact__c = contactId; 
            }
            if(parentId != null){
                timelog.softphone_it__Parent_Id__c  = parentId; 
            }
            if(state != null){
                timelog.softphone_it__State__c = state; 
            }
            if(disposition != null){
                timelog.softphone_it__Disposition_Code__c = disposition; 
            }
            if(interactionDuration != null){
                timelog.softphone_it__Interaction_Duration__c = interactionDuration; 
            }
            if(totalAcdDuration != null){
                timelog.softphone_it__Total_Acd_Duration__c = totalAcdDuration; 
            }
            if(totalIvrDuration != null){
                timelog.softphone_it__Total_Ivr_Duration__c = totalIvrDuration; 
            }
            if(dispositionDuration != null){
                timelog.softphone_it__Disposition_Duration__c = dispositionDuration; 
            }
            if(field == 'softphone_it__Released_Time__c' && state == 'answered' && timeLog.softphone_it__Established_Time__c == null){
                timelog.softphone_it__State__c = 'not answered';
            }
        
            update timelog;  
        } catch(Exception e){
            System.debug('Error in updateConnectorEventTimeLog ' + e);
            result = false;
        }
        
        return result;
    }

}