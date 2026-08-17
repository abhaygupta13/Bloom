public class RoundRobinUserTriggerHelper {
    
    //THis methoD is used to update the Round robin Id to round robin user record dynamically WHILE INSERTING A NEW RECORD.
 public static void updateRoundRobinId(List<Round_Robin_User__c> rruList) {
    Map<Id, Decimal> lastRoundRobinIds = new Map<Id, Decimal>();
        Set<id>ids = new Set<id>();
        for(Round_Robin_User__c ru:rruList){
            ids.add(ru.Round_Robin__c);
        }
        
        
    for (AggregateResult agr : [SELECT Round_Robin__c, MAX(Round_Robin_ID__c) maxRoundRobinId 
                                   FROM Round_Robin_User__c 
                                   WHERE Round_Robin__c IN :ids
                                   GROUP BY Round_Robin__c]) {
       lastRoundRobinIds.put((Id)agr.get('Round_Robin__c'), (Decimal)agr.get('maxRoundRobinId'));
      //  lastRoundRobinIds.put((Id)aggResult.get('Account__c'), (Decimal)aggResult.get('totalAmount'));
    }
    
    Decimal nextRoundRobinUserId;
    for (Round_Robin_User__c rru : rruList) {
        if (!lastRoundRobinIds.containsKey(rru.Round_Robin__c)) {
            nextRoundRobinUserId = 1;
            lastRoundRobinIds.put(rru.Round_Robin__c, nextRoundRobinUserId);
        } else {
            nextRoundRobinUserId = lastRoundRobinIds.get(rru.Round_Robin__c) + 1;
            lastRoundRobinIds.put(rru.Round_Robin__c, nextRoundRobinUserId);
        }
        rru.Round_Robin_ID__c = nextRoundRobinUserId;
    }
}
    // method to update Round_Robin_User_Name 
     public static void Populate_RoundRobinUserName(List<Round_Robin_User__c> rrNames) {
        Set<Id> setRoundRobin = new Set<Id>();
        Set<Id> setUser = new Set<Id>();
        
        for (Round_Robin_User__c rru : rrNames) {
            if (rru.Round_Robin__c != null) {
                system.debug('rru.Round_Robin__c' + rru.Round_Robin__c);
                setRoundRobin.add(rru.Round_Robin__c);
            }
            if (rru.User__c != null) {
                system.debug('rru.User__c' + rru.User__c);
                setUser.add(rru.User__c);
            }
            
        }
        
        Map<Id, User> userMap = new Map<Id, User>([Select Id, Name From User Where ID In :setUser]);
        Map<Id, Round_Robins__c> rrMap = new Map<Id, Round_Robins__c>([Select Id, Name From Round_Robins__c Where ID In :setRoundRobin]);
        
        // Loop through the Round_Robin_User__c records and set the afx_RR_User_Name__c field
        for (Round_Robin_User__c rrn : rrNames) {
            String s = '';
            if (rrn.Round_Robin__c != null && rrn.User__c != null && userMap.containsKey(rrn.User__c) && rrMap.containsKey(rrn.Round_Robin__c)) {
                // Get the building name and user name and concatenate them
                s = rrMap.get(rrn.Round_Robin__c).Name + ' - ' + userMap.get(rrn.User__c).Name;
            }
            rrn.RR_User_Name__c = s;
        }
    }
    //method for insert 
    Public static void RoundRobinUserInsert(List<Round_Robin_User__c> rruList ){
        Set<Id> setRoundRobin = new Set<Id>();
        Set<Id> setUser = new Set<Id>();
        Set<Round_Robin_User__c> existingUserSet = new  Set<Round_Robin_User__c>();
        for (Round_Robin_User__c rru :rruList){
            if(rru.Round_Robin__c !=null){
                setRoundRobin.add(rru.Round_Robin__c);
            }
            if(rru.User__c != null){
                setUser.add(rru.User__c);
            }
        }
        List<Round_Robin_User__c> RRUExistingList = [Select id, Round_Robin__c, User__c From Round_Robin_User__c Where 
                                                     (Round_Robin__c in : setRoundRobin and User__c in : setUser) ];
        For(Round_Robin_User__c rr : rruList){
            If(RRUExistingList.size() > 0) {
                rr.User__c.adderror('This User is already exist in this Queue. Please select a different user.');
            }
        }
        
    }
    //THis methoD is used to update the Round robin Id to round robin user records dynamically after deleting a user record.
    public static void updateRoundRobinId_delete (map<id,Round_Robin_User__c> rruMap){
        //Set<id> roundRobinids = new Set<id>();
        List<Round_Robin_User__c> rrList = new List<Round_Robin_User__c>();
        map<Id, List<Round_Robin_User__c>> rrId_rrUserList_Map = new map<Id, List<Round_Robin_User__c>>();
        //CApturing Roud Robin Ids and creating a map of "Round Robin Id and List of Round robin users"
        for(Round_Robin_User__c  rru:rruMap.Values()){
            //roundRobinids.add(rru.afx_Building__c);
            if(rrId_rrUserList_Map.containsKey(rru.Round_Robin__c)){
                rrId_rrUserList_Map.get(rru.Round_Robin__c).add(rru);
            }else{
                rrId_rrUserList_Map.put(rru.Round_Robin__c, new List<Round_Robin_User__c>{rru});
            }
        }
        
        //UPdating the Round robin User Id for the remining user records as per the ceated date, after deleting the round robin user
        Decimal nextRoundRobinUserId = 1;
        for(Round_Robin_User__c  rru:[Select Round_Robin__c,Round_Robin_ID__c,CreatedDate From Round_Robin_User__c 
                                      Where Round_Robin__c IN :rrId_rrUserList_Map.keyset() order by createdDate ASC]){
                                          rru.Round_Robin_ID__c = nextRoundRobinUserId;
                                          nextRoundRobinUserId++;
                                          rrList.add(rru);
                                      }
        
        //Updating the "Assigned TO" field on the Round Robin record to the newly updated user Id after deletion of the round robin user 
        List<Round_Robins__c> roundRobinToUpdate = new List<Round_Robins__c>();
        for(Round_Robins__c  rr :[Select Id,Name, Assigned_To__c,CreatedDate From Round_Robins__c 
                             Where Id IN :rrId_rrUserList_Map.keyset()]){
                                 
                                 decimal rrUserId = 0;
                                 decimal assignedTo = decimal.valueOf(rr.Assigned_To__c);
                                 if(rrId_rrUserList_Map.containsKey(rr.id) && rrId_rrUserList_Map.get(rr.id) <> null && rrId_rrUserList_Map.get(rr.id).size() == 1){
                                     rrUserId = rrId_rrUserList_Map.get(rr.Id)[0].Round_Robin_ID__c;
                                     rr.Assigned_To__c = ((rrUserId > assignedTo && assignedTo == 0) ? rr.Assigned_To__c : string.valueOf(assignedTo-1));
                                     roundRobinToUpdate.add(rr);
                                 }                                              
                                 
                             }
        if(rrList.size()>0){
            update rrList;
        }
        if(roundRobinToUpdate.size()>0){
            update roundRobinToUpdate;
        }
        
        
    }

}