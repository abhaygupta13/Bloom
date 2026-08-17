/***
Class       : LeasingOrderExpiryBatchScheduler
Author      : 
Description : 
TestClass   : 
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
****************************************************************************************************************/
public class LeasingOrderExpiryBatchScheduler implements Database.Batchable<SObject>, Schedulable {
    private static final string BLOOM_NO_REPLY_LEASING_OW_EMAIL_ID { get { return 'BloomNoReplyLeasingOWEmailId'; } }
    private static final string LEASING_ORDER_EXPIRY_TEMPLATE_ID { get { return 'LeasingOrderExpiryNotification'; } }
    private static final string LEASING_ORDER_STATUS_CANCELLED { get { return 'Cancelled'; } }
    private static final string UNIT_STATUS_AVAILABLE { get { return 'Available'; } }
    
    
    // === Start method ===
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 
            'SELECT Id, Name, OwnerId, CreatedDate, OfferValidityDays__c, Status__c, Unit__c,Owner.lastname,Owner.email ' +
            'FROM LeasingOrder__c WHERE Status__c = \'Leasing Offer\' AND OfferValidityDays__c != null' ;
        // Return as query locator
        return Database.getQueryLocator(query);
    }
    
    // === Execute method ===
    public void execute(Database.BatchableContext bc, List<LeasingOrder__c> expiredOrders) {
        
        Set<Id> unitIds = new Set<Id>();
        Date todayVar = Date.today();
        Map<Id, LeasingOrder__c> leasingOrderMap = new Map<Id, LeasingOrder__c>();
        Map<Id, Unit__c> unitMap = new Map<Id, Unit__c>();
        
        for (LeasingOrder__c order : expiredOrders) {
            if((order.CreatedDate.adddays(Integer.valueOf(order.OfferValidityDays__c))) < todayVar ){
                order.Status__c = LEASING_ORDER_STATUS_CANCELLED;
                if(!leasingOrderMap.containsKey(order.Id)){ 
                    leasingOrderMap.put(order.id,order);  
                }
                if (order.Unit__c != null)
                {
                    unitIds.add(order.Unit__c);   
                }
            }
        }
        
        // Update Leasing Orders
        if (!leasingOrderMap.isEmpty()) {
            LeasingOrderService.getInstance().updateLeasingOrderswithOutTrigger(leasingOrderMap.values());
        }
        // Update related Units
        if (!unitIds.isEmpty()) {
            for (Unit__c unit : UnitService.getAllUnitsById(unitIds))
            {
                unit.LeasingUnitStatus__c = UNIT_STATUS_AVAILABLE;
                if(unitMap.containsKey(unit.Id)){
                    continue ;  
                }
                unitMap.put(unit.Id, unit);
            }
            if (!unitMap.isEmpty()) {
                UnitService.getInstance().updateUnitsWithoutTrigger(unitMap.values());
            }
        }
        
        if (!leasingOrderMap.isEmpty()) {
            sendNotificationToLeaseOwners(leasingOrderMap.values());
        }
    }
    
    // === Send Email using Lightning Email Template ===
    private void sendNotificationToLeaseOwners(List<LeasingOrder__c> expiredOrders) {
        if (expiredOrders.isEmpty()) return;
        MetadataService objMetadataService = MetadataService.getInstance();
        
        Id templateId = objMetadataService.getAppSettingTextValue(LEASING_ORDER_EXPIRY_TEMPLATE_ID);
        Id orgWideEmailId = objMetadataService.getAppSettingTextValue(BLOOM_NO_REPLY_LEASING_OW_EMAIL_ID);
        
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        for (LeasingOrder__c order : expiredOrders) {
            // Render the template content using WhatId
            Messaging.SingleEmailMessage renderedMail = Messaging.renderStoredEmailTemplate(templateId, null, order.Id);
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail = EmailService.getInstance().getSingleEmailMessage(new List<String>{ order.Owner.Email },order.Id,
                                                                    null,renderedMail.getSubject(),renderedMail.getHtmlBody(),
                                                                    orgWideEmailId,null,null);
            mail.setSaveAsActivity(true);
            emails.add(mail);
        }
        if(!test.isRunningTest())
        EmailService.getInstance().sendEmail(emails);
        // if (!emails.isEmpty()) Messaging.sendEmail(emails);
    }
    
    
    // === Finish ===
    public void finish(Database.BatchableContext bc) {
        
    }
    
    // === Schedulable execute method ===
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new LeasingOrderExpiryBatchScheduler(), 20);
    }
    
}