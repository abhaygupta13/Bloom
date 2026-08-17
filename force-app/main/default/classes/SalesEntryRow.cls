public class SalesEntryRow {

    @AuraEnabled public SalesEntrie__c salesEntry;
    @AuraEnabled public Boolean isMaster;

    public SalesEntryRow(SalesEntrie__c s, Boolean master){
        salesEntry = s;
        isMaster = master;
    }
}