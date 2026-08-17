trigger InstallmentTriggerForDelete on InstallmentLines__c (before delete) {
 Boolean isAdmin = false;
    for(User u : [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()]){
        if(u.Profile.Name == 'System Administrator'){
            isAdmin = true;
            break; 
        }
    }
    Set<Id> soIds = new Set<Id>();
    for (InstallmentLines__c line : Trigger.old) {
        if (line.SalesOrder__c != null) {
            soIds.add(line.SalesOrder__c);
        }
    }

List<SalesOrder__c> soList =
    SalesOrderService.getInstance().getSalesOrdersByIds(soIds);

Map<Id, SalesOrder__c> soMap = new Map<Id, SalesOrder__c>(soList);

    
    if(trigger.isDelete && trigger.isBefore && !isAdmin){
    for (InstallmentLines__c line : Trigger.old) {
        SalesOrder__c so = soMap.get(line.SalesOrder__c);
        if (so != null && !so.Resale__c) {
            line.addError('You do not have permission to delete this record.');
        }
       
    }
    } 
}