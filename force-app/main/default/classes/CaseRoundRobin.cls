/***
Class       : CaseRoundRobin
Author      : Smaartt
Description : 
TestClass   : CaseRoundRobinTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              12/12/23           Initial Version  
2.          V2.0             13/12/23            Optimized the code

1. Complaints Record Type skip Round Robin
2. SkipRRR_Profiles - these profiles skip Round Robin
****************************************************************************************************************/ 
public class CaseRoundRobin {
    
    public static void ownerRRRAssignment(list<Case> trgNew){
        Boolean skippResaleProject = false;
        
        Round_Robins__c commonrr = new Round_Robins__c();
        Round_Robins__c resalerr = new Round_Robins__c();
        set<Id> cmplntRecTypeIds =new set<Id>();        
        list<string> profiles = system.label.SkipRRR_Profiles.split(',');
        Id profileId=userinfo.getProfileId();
        Id resaleRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Resale').getRecordTypeId();
        Id socialMediaRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Social_Media').getRecordTypeId();
        String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
        list<Round_Robin_User__c> rruUpdate = new list<Round_Robin_User__c>();
        list<Round_Robins__c> roundRobinUpdate = new list<Round_Robins__c>();
        
         for(CaseTypeConfig__mdt cf : [SELECT Id, Case_Type__c, Case_Category__c FROM CaseTypeConfig__mdt where Case_Category__c ='Complaint' ]){
            Id recTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(cf.Case_Type__c).getRecordTypeId();
            if(recTypeId != null)
                cmplntRecTypeIds.add(recTypeId);
        }        

        
         //Common RR logic - end
     Map<Id,Id> PrjIdVsUsrId = new  Map<Id,Id>();

         for(RaiseServiceRequestAssignment__mdt rsa : [Select id,Project__c,Owner__c from RaiseServiceRequestAssignment__mdt WHERE IsActive__c=true]){
            PrjIdVsUsrId.put(rsa.Project__c,rsa.Owner__c);
             System.debug('PrjIdVsUsrId'+PrjIdVsUsrId);
        }
        
         Set<id>salesorderIds = new Set<id>();
            Map<id,id>salesorderIdvsProject = new Map<id,id>();
            for(case ca:trgNew){
                salesorderIds.add(ca.Sales_Order__c);
                System.debug('salesorderIds'+salesorderIds);
            }
          id skipProjectOwnerId;
            for(Salesorder__c sc:[Select id,Project__c From Salesorder__c Where id=:salesorderIds]){
                System.debug('project'+sc.Project__c);
               salesorderIdvsProject.put(sc.id,sc.Project__c);
               System.debug(PrjIdVsUsrId.containsKey(sc.Project__c));
                if(PrjIdVsUsrId.containsKey(sc.Project__c)){
                    skippResaleProject= true;
                    System.debug('skippResaleProject'+skippResaleProject);
                }
                if(PrjIdVsUsrId.containsKey(sc.Project__c)){
                   skipProjectOwnerId =  PrjIdVsUsrId.get(sc.Project__c);
                }
                
            }
        if(skipProjectOwnerId!=null){
        for(Case ca:trgNew){
            if(!cmplntRecTypeIds.contains(ca.RecordTypeId)){
           ca.OwnerId = skipProjectOwnerId;
            
            }}
        }
        
              
        
        for(Round_Robins__c rrli : [SELECT Id,Name,Assigned_To__c,(SELECT Id,User__c,Total_Open_Count__c, IsActive__c, Round_Robin_ID__c,Round_Robin__r.Assigned_To__c,Round_Robin__c FROM Round_Robin_Users__r WHERE IsActive__c = TRUE AND Sobject__c='Case')
                                    FROM Round_Robins__c Where Sobject__c='Case']){
                                        if(rrli.Name=='Service/Resale Case Request')  
                                            resalerr=rrli;
                                        if(rrli.Name=='Service/Case Request')  
                                            commonrr= rrli;     
                                        
                                    }
        
        
       
        
        //Common RR logic - Start
        Integer lastAssigned;
        Integer initialAssigned;        
        map<integer,Round_Robin_User__c> rIdVsRuser = new map<integer,Round_Robin_User__c>();

        if(commonrr != null && commonrr.Id != NULL && !profiles.contains(profileName)){
            System.debug('@@##$$$'+commonrr.Assigned_To__c+'@@###@@@'+commonrr);
            lastAssigned = integer.ValueOf(commonrr.Assigned_To__c);
            initialAssigned = integer.ValueOf(commonrr.Assigned_To__c);
            
                for(Round_Robin_User__c ru : commonrr.Round_Robin_Users__r){
                    rIdVsRuser.put(integer.ValueOf(ru.Round_Robin_ID__c),ru);
                }                
            
            
            for(Case ca : trgNew){                
                if(!cmplntRecTypeIds.contains(ca.RecordTypeId) && ca.RecordTypeId !=resaleRecTypeId && ca.RecordTypeId != socialMediaRecTypeId){//skip resal recordType cases
                    if(rIdVsRuser.size() == lastAssigned ||rIdVsRuser.size() < lastAssigned ){
                        lastAssigned = 0;
                    }
                    lastAssigned = lastAssigned+1;
                    if(rIdVsRuser.containskey(lastAssigned)){
                        ca.ownerId =rIdVsRuser.get(lastAssigned).User__c;                    
                        
                    }else{
                        for(integer i=1; i<rIdVsRuser.size();i++){
                            lastAssigned = lastAssigned+1;
                            if(rIdVsRuser.containskey(lastAssigned)){
                                ca.ownerId =rIdVsRuser.get(lastAssigned).User__c;
                                break;
                            }
                        }
                    }   
                    Round_Robin_User__c rru = new Round_Robin_User__c();
                    system.debug('check'+rIdVsRuser.get(lastAssigned).Id);
                    rru.Id = rIdVsRuser.get(lastAssigned).Id;
                   rru.Total_Open_Count__c=rIdVsRuser.get(lastAssigned).Total_Open_Count__c+1;
                    rruUpdate.add(rru);
                    
                }
                if(initialAssigned != lastAssigned){
                    Round_Robins__c rr = new Round_Robins__c();
                    rr.Id = commonrr.Id;
                    rr.Assigned_To__c = string.valueOf(lastAssigned);
                    roundRobinUpdate.add(rr);
                }
                
            }            
        }  
        
         
       
       //Reseller RR logic - Start
        Integer lastAssignedReseller;
        Integer initialAssignedReseller;
        map<integer,Round_Robin_User__c> resellerIdVsRuser = new map<integer,Round_Robin_User__c>();
        if(resalerr!=null && resalerr.Id != NULL && !profiles.contains(profileName)){
            lastAssignedReseller = integer.ValueOf(resalerr.Assigned_To__c);
            initialAssignedReseller = integer.ValueOf(resalerr.Assigned_To__c);
            
                for(Round_Robin_User__c ru : resalerr.Round_Robin_Users__r){
                    resellerIdVsRuser.put(integer.ValueOf(ru.Round_Robin_ID__c),ru);
                }                
            
            for(Case ca : trgNew){
                if(skippResaleProject==false){
                if(!cmplntRecTypeIds.contains(ca.RecordTypeId) && ca.RecordTypeId==resaleRecTypeId ){
                    if(resellerIdVsRuser.size() == lastAssignedReseller ||resellerIdVsRuser.size() < lastAssignedReseller ){
                        lastAssignedReseller = 0;
                    }
                    lastAssignedReseller = lastAssignedReseller+1;
                    if(resellerIdVsRuser.containskey(lastAssignedReseller)){
                        ca.ownerId =resellerIdVsRuser.get(lastAssignedReseller).User__c;                    
                        
                    }else{
                        for(integer i=1; i<resellerIdVsRuser.size();i++){
                            lastAssignedReseller = lastAssignedReseller+1;
                            if(resellerIdVsRuser.containskey(lastAssignedReseller)){
                                ca.ownerId =resellerIdVsRuser.get(lastAssignedReseller).User__c;
                                break;
                            }
                        }
                    }   
                    Round_Robin_User__c rru1 = new Round_Robin_User__c();
                    if(resellerIdVsRuser.get(lastAssignedReseller)!=null){
                    rru1.Id = resellerIdVsRuser.get(lastAssignedReseller).Id;
                    rru1.Total_Open_Count__c=resellerIdVsRuser.get(lastAssignedReseller).Total_Open_Count__c+1;
                    rruUpdate.add(rru1);
                    }
                    
                }
                if(initialAssignedReseller != lastAssignedReseller){
                    Round_Robins__c rr1 = new Round_Robins__c();
                    rr1.Id = resalerr.Id;
                    rr1.Assigned_To__c = string.valueOf(lastAssignedReseller);
                    roundRobinUpdate.add(rr1);
                }
                
                }
            }
            }
    //} 
       //Reseller RR logic - end
       if(rruUpdate.size()>0)
                update rruUpdate;
        if(roundRobinUpdate.size()>0)
            update roundRobinUpdate;
        
    }
    
    public static void caseCountMethod(List<Case> caselist, Map<Id, Case> caseMapold) {
        
        Map<Id,integer> rrUserIdVsCount = new Map<Id,integer>();   
        set<id> caseOwnerIds = new set<id>();
        List<Round_Robin_User__c> roundrobinlist = new List<Round_Robin_User__c>();
        set<Id> cmplntRecTypeIds =new set<Id>();
        for(CaseTypeConfig__mdt cf : [SELECT Id, Case_Type__c, MasterLabel FROM CaseTypeConfig__mdt where Case_Category__c ='Complaint' ]){
            Id recTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(cf.MasterLabel).getRecordTypeId();
            if(recTypeId != null)
                cmplntRecTypeIds.add(recTypeId);
        } 
        
        if(trigger.isUpdate ){   
            
            for(Case le : caselist){              
                caseOwnerIds.add(le.OwnerId);                
                If(caseMapold.get(le.Id).OwnerId!= le.OwnerId ){
                    caseOwnerIds.add(caseMapold.get(le.Id).OwnerId);                  
                }
            }
            for(AggregateResult agr : [select count(id) cnt, OwnerId Owner from Case where OwnerId=:caseOwnerIds AND status !='Closed' AND RecordTypeId !=:cmplntRecTypeIds GROUP BY OwnerId]){
                rrUserIdVsCount.put((Id)agr.get('Owner'),(Integer)agr.get('cnt'));
            }
            
            for (Round_Robin_User__c rru : [SELECT Id,Total_Open_Count__c, User__c, User__r.Name FROM Round_Robin_User__c WHERE Sobject__c='Case' AND User__c =:rrUserIdVsCount.keyset()]) {
                if(rru.Total_Open_Count__c >= 0 && rrUserIdVsCount.containskey(rru.User__c)){
                    rru.Total_Open_Count__c = rrUserIdVsCount.get(rru.User__c);
                    roundrobinlist.add(rru);
                }
            }
            
        }
        if(trigger.isDelete){ 
            
            for(Case le : caseMapold.values()){                
                caseOwnerIds.add(le.OwnerId);             
            }
            for(AggregateResult agr : [select count(id) cnt, OwnerId Owner from Case where OwnerId=:caseOwnerIds AND status !='Closed' GROUP BY OwnerId]){
                rrUserIdVsCount.put((Id)agr.get('Owner'),(Integer)agr.get('cnt'));
            }
            for (Round_Robin_User__c rru : [SELECT Id, Total_Open_Count__c, User__c, User__r.Name FROM Round_Robin_User__c WHERE Sobject__c='Case' AND User__c =:rrUserIdVsCount.keyset()]) {
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