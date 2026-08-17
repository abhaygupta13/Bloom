trigger SalesorderTriggerForDelete on SalesOrder__c (before delete) {
    
      Boolean isAdmin = false;
    for(User u : [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()]){
        if(u.Profile.Name == 'System Administrator'){
            isAdmin = true;
            break;
        }
    }
    
    if(trigger.isDelete && trigger.isBefore && !isAdmin){
        for(SalesOrder__c record: trigger.old){
             record.addError('You do not have permission to delete this record.');
        }
    }

}