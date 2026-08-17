public class SalesEntriesWrapper {

    @AuraEnabled
    public List<SalesEntrie__c> masterSalesEntries;

    @AuraEnabled
    public List<SalesEntrie__c> currentSalesEntries;
}