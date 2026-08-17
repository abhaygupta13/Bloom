/***
Class       : LeadRoundRobin
Author      : Smaartt
Description : 
TestClass   : LeadRoundRobinTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              27/04/23           Initial Version 
2.          V2.0             13/12/23            Optimized the code
****************************************************************************************************************/
public class LeadRoundRobin {
    
    public static void ownerRRRAssignment(list<lead> trgNew,Map<id,lead> trgOldMap){
        Integer lastAssigned;
        Integer initialAssigned;
        Map<Id,string> recTypeIdVsRecTypeName =new Map<Id,string>();
        map<integer,Round_Robin_User__c> rIdVsRuser = new map<integer,Round_Robin_User__c>();
        List<Round_Robins__c> rrList = [SELECT Id,Name,Assigned_To__c,(SELECT Id,User__c,Total_Open_Count__c, IsActive__c, Round_Robin_ID__c,Round_Robin__r.Assigned_To__c,Round_Robin__c FROM Round_Robin_Users__r WHERE IsActive__c = TRUE AND Sobject__c='Lead')
                                        FROM Round_Robins__c Where Sobject__c='Lead' limit 1];
        
        
        list<Round_Robin_User__c> rruUpdate = new list<Round_Robin_User__c>();
        if(rrList.size()>0){
            lastAssigned = integer.ValueOf(rrList[0].Assigned_To__c);
            initialAssigned = integer.ValueOf(rrList[0].Assigned_To__c);
            for(Round_Robins__c rr : rrList){
                for(Round_Robin_User__c ru : rr.Round_Robin_Users__r){
                    rIdVsRuser.put(integer.ValueOf(ru.Round_Robin_ID__c),ru);
                }                
            }  
            
            for(lead le : trgNew){ 
                
                if( le.Status=='Qualified' && le.Status!=trgOldMap.get(le.Id).status){
                    
                    if(rIdVsRuser.size() == lastAssigned ||rIdVsRuser.size() < lastAssigned ){
                        lastAssigned = 0;
                    }
                    lastAssigned = lastAssigned+1;
                    if(rIdVsRuser.containskey(lastAssigned)){
                        le.ownerId =rIdVsRuser.get(lastAssigned).User__c;                    
                        
                    }else{
                        for(integer i=1; i<rIdVsRuser.size();i++){
                            lastAssigned = lastAssigned+1;
                            if(rIdVsRuser.containskey(lastAssigned)){
                                le.ownerId =rIdVsRuser.get(lastAssigned).User__c;
                                break;
                            }
                        }
                    }   
                    Round_Robin_User__c rru = new Round_Robin_User__c();
                    rru.Id = rIdVsRuser.get(lastAssigned).Id;
                    rru.Total_Open_Count__c=rIdVsRuser.get(lastAssigned).Total_Open_Count__c+1;
                    rruUpdate.add(rru);
                }
                
            }
            if(initialAssigned != lastAssigned){
                Round_Robins__c rr = new Round_Robins__c();
                rr.Id = rrList[0].Id;
                rr.Assigned_To__c = string.valueOf(lastAssigned);
                update rr;
            }
                if(rruUpdate.size()>0)
                update rruUpdate;
            
        } 
        
        
    }
    
    public static void LeadCountMethod(List<Lead> Leadlist, Map<Id, Lead> LeadMapold) {
        
        Map<Id,integer> rrUserIdVsCount = new Map<Id,integer>();   
        set<id> leadOwnerIds = new set<id>();
        List<Round_Robin_User__c> roundrobinlist = new List<Round_Robin_User__c>();     
        
        if(trigger.isUpdate){              
            for(lead le : Leadlist){                
                If((le.status =='Converted' && le.Status != LeadMapold.get(le.id).status)||(le.Status == 'Retired' && LeadMapold.get(le.id).Status != 'Retired')){
                    leadOwnerIds.add(le.OwnerId);
                }
                If(LeadMapold.get(le.Id).OwnerId!= le.OwnerId ){
                    leadOwnerIds.add(LeadMapold.get(le.Id).OwnerId);
                    leadOwnerIds.add(le.OwnerId);
                    
                }
                
            }
            for(AggregateResult agr : [select count(id) cnt, OwnerId Owner from Lead where status!='Retired' AND status!='Converted' AND OwnerId=:leadOwnerIds GROUP BY OwnerId]){
                rrUserIdVsCount.put((Id)agr.get('Owner'),(Integer)agr.get('cnt'));
            }
            
            for (Round_Robin_User__c rru : [SELECT Id, Total_Open_Count__c, User__c, User__r.Name FROM Round_Robin_User__c WHERE Sobject__c='Lead' AND User__c =:rrUserIdVsCount.keyset()]) {
                if(rru.Total_Open_Count__c >= 0 && rrUserIdVsCount.containskey(rru.User__c)){
                    rru.Total_Open_Count__c = rrUserIdVsCount.get(rru.User__c);
                    roundrobinlist.add(rru);
                }
            }
            
        }
        if(trigger.isDelete){ 
            
            for(lead le : LeadMapold.values()){                
                leadOwnerIds.add(le.OwnerId);             
            }
            for(AggregateResult agr : [select count(id) cnt, OwnerId Owner from Lead where status!='Retired' AND status!='Converted'AND OwnerId=:leadOwnerIds GROUP BY OwnerId]){
                rrUserIdVsCount.put((Id)agr.get('Owner'),(Integer)agr.get('cnt'));
            }
            for (Round_Robin_User__c rru : [SELECT Id, Total_Open_Count__c, User__c, User__r.Name FROM Round_Robin_User__c WHERE Sobject__c='Lead' AND User__c =:rrUserIdVsCount.keyset()]) {
                if(rru.Total_Open_Count__c >= 0 && rrUserIdVsCount.containskey(rru.User__c)){
                    rru.Total_Open_Count__c = rrUserIdVsCount.get(rru.User__c);
                    roundrobinlist.add(rru);
                }
            }
            
        }
        if(roundrobinlist.size()>0)
            update roundrobinlist;
        
        
    }
}