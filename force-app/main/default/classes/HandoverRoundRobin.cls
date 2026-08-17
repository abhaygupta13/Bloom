/***
Class       : HandoverRoundRobin
Author      : Rajat Rastogi
Description : 
TestClass   : HandoverTriggerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.      V1.0             	 11/06/2024           Initial Version  
****************************************************************************************************************/ 

public class HandoverRoundRobin {
    public static void handoverRRAssignmentToTeam(List<Handover__c> newHOList, String teamToBeAssigned){
        try{
            Integer lastAssigned;
            Integer initialAssigned;
            Map<Id,String> recTypeIdVsRecTypeName =new Map<Id,String>();
            Map<Integer,Round_Robin_User__c> rIdVsRuser = new Map<Integer,Round_Robin_User__c>();
            List<Round_Robins__c> rrList = [SELECT Id,Name,Assigned_To__c,(SELECT Id,User__c,Total_Open_Count__c, IsActive__c, Round_Robin_ID__c,Round_Robin__r.Assigned_To__c,Round_Robin__c FROM Round_Robin_Users__r WHERE IsActive__c = TRUE AND Sobject__c=: HandoverConstants.HANDOVER_SOBJECT)
                                            FROM Round_Robins__c 
                                            WHERE Sobject__c=: HandoverConstants.HANDOVER_SOBJECT AND Team__c =:teamToBeAssigned AND Project__c =: newHOList[0].Project__c
                                            LIMIT 1];
                      
            System.debug('rrList ::::: '+ rrList);
            List<Round_Robin_User__c> rruUpdate = new List<Round_Robin_User__c>();
            if(rrList.size()>0){ 
                lastAssigned = Integer.ValueOf(rrList[0].Assigned_To__c);  
                initialAssigned = Integer.ValueOf(rrList[0].Assigned_To__c);
                for(Round_Robins__c rr : rrList){
                    for(Round_Robin_User__c ru : rr.Round_Robin_Users__r){
                        rIdVsRuser.put(Integer.ValueOf(ru.Round_Robin_ID__c),ru);
                    }                
                }  
                List<Handover__c> handOverListToUpdate = new List<Handover__c>();
                
                if(!newHOList.isEmpty()){
                    for(Handover__c hoObj : newHOList){ 
                        Handover__c HO = new Handover__c();
                        HO.Id = hoObj.Id;	
                     
                            if(rIdVsRuser.size() == lastAssigned ||rIdVsRuser.size() < lastAssigned ){
                                lastAssigned = 0;
                            }
                           Id assignedUserId;
                            lastAssigned = lastAssigned+1;
                            if(rIdVsRuser.containskey(lastAssigned)){
                                assignedUserId = rIdVsRuser.get(lastAssigned).User__c;
                            }else{
                                for(Integer i=1; i<=rIdVsRuser.size();i++){
                                    lastAssigned = lastAssigned+1;
                                    if(rIdVsRuser.containskey(lastAssigned)){
                                        assignedUserId = rIdVsRuser.get(lastAssigned).User__c;
                                        break;
                                    }
                                }
                            }
                            if(teamToBeAssigned == HandoverConstants.TEAM_CRM && String.isNotBlank(assignedUserId)){                             
                                HO.CRM_Team_Assigned_User__c = assignedUserId;
                              
                            }
							if(teamToBeAssigned == HandoverConstants.TEAM_OPERATION && String.isNotBlank(assignedUserId)){
                              
                               HO.Operation_Team_Assigned_User__c = assignedUserId;
                            }                                                     
                            
                            Round_Robin_User__c rru = new Round_Robin_User__c();
                            rru.Id = rIdVsRuser.get(lastAssigned).Id;
                            rru.Total_Open_Count__c=rIdVsRuser.get(lastAssigned).Total_Open_Count__c+1;
                            rruUpdate.add(rru);
                            
                            handOverListToUpdate.add(HO);
                     
                    }

                    System.debug('handOverListToUpdate ::::: '+ handOverListToUpdate);
                   
                    if(!handOverListToUpdate.isEmpty()){
                        update handOverListToUpdate;
                    }
                    if(initialAssigned != lastAssigned){
                        Round_Robins__c rr = new Round_Robins__c();
                        rr.Id = rrList[0].Id;
                        rr.Assigned_To__c = string.valueOf(lastAssigned);
                        update rr;
                    }
                    if(rruUpdate.size()>0){
                        update rruUpdate;
                    }
                }
            }
        }catch(Exception ex){
            ErrorLogHandler.logError('HandoverRoundRobin','handoverRRAssignmentToTeam',ex,'');
        }
    }
}