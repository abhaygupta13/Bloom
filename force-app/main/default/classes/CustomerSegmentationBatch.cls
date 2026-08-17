/***
Class       : CustomerSegmentationBatch
Author      : Dhanraj
Description : 
TestClass   : CustomerSegmentationBatchTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.        V1.0              09/06/26           Initial Version 
****************************************************************************************************************/

public without sharing class CustomerSegmentationBatch implements Database.Batchable<SObject>,Schedulable {
    private static final String CUSTOMER_CATEGORY_PLATINUM_VALUE = 'CustomerCategoryPlatinumThreshold';
    private static final String CUSTOMER_CATEGORY_GOLD_VALUE = 'CustomerCategoryGoldThreshold';
    private static final String CUSTOMER_CATEGORY_DAYSTOCHECK = 'CustomerCategoryDaysToLookBack';
    private static final String CUSTOMER_CATEGORY_SILVER = 'Silver';
    private static final String CUSTOMER_CATEGORY_GOLD = 'Gold';
    private static final String CUSTOMER_CATEGORY_PLATINUM = 'Platinum';
    private static final Set<String> INVALID_STATUSES = new Set<String>{'Cancelled','Book Cancelled'};        
    private static final Set<String> ROYAL_SALUTATIONS = new Set<String>{'Her Royal Highness','His Royal Highness','Her Excellency','His Highness','His Excellency','Sheikh/Sheikah'};
    public final Decimal platinumThreshold;
    public final Decimal goldThreshold;
    public final Integer daysToLookBack;
    
    public CustomerSegmentationBatch() {
        MetadataService metadataService = MetadataService.getInstance();
        platinumThreshold = metadataService.getAppSettingNumberValue(CUSTOMER_CATEGORY_PLATINUM_VALUE);
        goldThreshold = metadataService.getAppSettingNumberValue(CUSTOMER_CATEGORY_GOLD_VALUE);     
        daysToLookBack = Integer.valueOf(metadataService.getAppSettingNumberValue(CUSTOMER_CATEGORY_DAYSTOCHECK));
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String salutationSet = '\'' + String.join(new List<String>(ROYAL_SALUTATIONS),'\',\'') + '\'';
        String query = 'SELECT Id, Account__c,Account__r.LastName FROM SalesOrder__c WHERE LastModifiedDate = LAST_N_DAYS:' + daysToLookBack +
            ' AND Account__c != NULL AND Account__r.Salutation NOT IN (' + salutationSet + ')';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc,List<SalesOrder__c> scope) {
        SalesOrderService salesOrderService = SalesOrderService.getInstance();
        Set<Id> accountIds = new Set<Id>();
        for (SalesOrder__c so : scope) {
            if (so.Account__c != null) {
                accountIds.add(so.Account__c);
            }
        }
        
        if (accountIds.isEmpty()) {
            return;
        }
        
        Map<Id, Decimal> accountTotals = new Map<Id, Decimal>();
        Map<Id, String> existingSegments = new Map<Id, String>();
        List<SalesOrder__c> lstSalesorder = salesOrderService.getSalesOrdersByAccountIdsForSegment(accountIds,INVALID_STATUSES);
        for (SalesOrder__c so : lstSalesorder) {
            if (!existingSegments.containsKey(so.Account__c)) {
                existingSegments.put(so.Account__c,so.Account__r.Segment__c);
            }
            Decimal runningTotal = accountTotals.containsKey(so.Account__c) ? accountTotals.get(so.Account__c) : 0;
            runningTotal += so.NetAmount__c == null ? 0 : so.NetAmount__c;
            accountTotals.put(so.Account__c, runningTotal);
        }
        
        List<Account> accountsToUpdate = new List<Account>();
        for (Id accountId : accountTotals.keySet()) {
            String newSegment = calculateCategory(accountTotals.get(accountId));
            accountsToUpdate.add(new Account(Id = accountId,Segment__c = newSegment));
        }
        AccountService.getInstance().updateAccountsWithoutTriggerDB(accountsToUpdate);
    }
    
    public void finish(Database.BatchableContext bc) {
    }
    
    private String calculateCategory(Decimal totalAmount) {
        if (totalAmount >= platinumThreshold) {
            return CUSTOMER_CATEGORY_PLATINUM;
        }
        if (totalAmount >= goldThreshold) {
            return CUSTOMER_CATEGORY_GOLD;
        }
        return CUSTOMER_CATEGORY_SILVER;
    }
    
    public void execute(SchedulableContext context) {
        Database.executeBatch(new CustomerSegmentationBatch(),200);
    }
}