trigger ContactTriggerForDelete on Contact (before insert,before delete) {
     Boolean isAdmin = false;
    for(User u : [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()]){
        if(u.Profile.Name == 'System Administrator'){
            isAdmin = true;
            break;
        }
    }
    
    if(trigger.isDelete && trigger.isBefore && !isAdmin){
        for(Contact record: trigger.old){
             record.addError('You do not have permission to delete this record.');
        }
    }

}