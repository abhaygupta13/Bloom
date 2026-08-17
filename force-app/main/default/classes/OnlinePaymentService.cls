/**
 * Class: OnlinePaymentService
 * Purpose: Service class for performing SOQL/DML operations on OnlinePayment__c.
 *          Centralized helper for insert, update, and retrieval of OnlinePayment__c records.
 *
 * Created By: Bloom Dev
 * Created On: 2025-09-01
 *
 * Notes:
 * - All queries and DML operations related to OnlinePayment__c live here.
 * - Consumers (handlers/controllers) must call this service instead of running SOQL/DML directly.
 */
public inherited sharing class OnlinePaymentService {

    private static OnlinePaymentService inst;
    public static OnlinePaymentService getInstance() {
        if (inst == null) inst = new OnlinePaymentService();
        return inst;
    }
    private OnlinePaymentService() {}

    /**
     * Fetch a single OnlinePayment__c by Id.
     */
    public OnlinePayment__c getPaymentById(Id paymentId) {
        if (paymentId == null) return null;
       return [
            SELECT Id, Status__c, PaidAmount__c, GatewayReference__c,TechnologyFee__c,
                   Account__c, PaymentMethod__c, Unit__c, ResponseMessage__c,
                   CreatedDate
            FROM OnlinePayment__c
            WHERE Id = :paymentId
            LIMIT 1
        ];
    }

    /**
     * Fetch related OnlinePaymentLineItem__c records for a given OnlinePayment Id.
     */
    public List<OnlinePaymentLineItem__c> getLineItemsByPayment(Id paymentId) {
        if (paymentId == null) return new List<OnlinePaymentLineItem__c>();
        return [
            SELECT Id, Invoice__c, Invoice__r.Name, PlannedAmount__c, OnlinePayment__c
            FROM OnlinePaymentLineItem__c
            WHERE OnlinePayment__c = :paymentId
        ];
    }

    /**
     * Fetch the most recent successful payments for a given Account.
     * @param limitSize → max number of results to return
     */
    public List<OnlinePayment__c> getSuccessfulPaymentsByAccount(Id accountId, Integer limitSize) {
        if (accountId == null) return new List<OnlinePayment__c>();
        Integer n = (limitSize == null || limitSize <= 0) ? 50 : limitSize;
        return [
            SELECT Id, PaidAmount__c, Status__c, GatewayReference__c, ResponseMessage__c, CreatedDate,TechnologyFee__c
            FROM OnlinePayment__c
            WHERE Account__c = :accountId AND Status__c = 'Success'
            ORDER BY LastModifiedDate DESC
            LIMIT :n
        ];
    }
    
    /**
     * Unified bulk fetch for any email composition use case.
     * Superset of fields needed by previous Receipt/Status variants.
     * Returns a Map<Id, OnlinePayment__c> directly from the query.
     */
    public Map<Id, OnlinePayment__c> getByIdsForEmail(Set<Id> ids) {
        if (ids == null || ids.isEmpty()) return new Map<Id, OnlinePayment__c>();
        return new Map<Id, OnlinePayment__c>([
            SELECT Id,
                   RequestSource__c,
                   Unit__r.Name,
                   Account__c,
                   Account__r.Name,
                   Account__r.PersonEmail,
                   Account__r.PersonContactId,
                   Invoice__c,
                   Invoice__r.SAPInvoiceNumber__c
            FROM OnlinePayment__c
            WHERE Id IN :ids
        ]);
    }
    
    /**
     * Unified single-record selector for posting (Service + Misc union).
     * - If Misc, Invoice__* fields may be null (safe).
     * - If Service, CustomerNumber/SAP Invoice are populated.
     */
    public OnlinePayment__c getForPaymentPosting(Id paymentId) {
        if (paymentId == null) return null;
        return [
            SELECT Id,
                   Status__c,
                   PaidAmount__c,
                   PaymentMethod__c,
                   GatewayReference__c,
                   CreatedDate,
                   Account__r.AccountNumber,
            	   Account__r.SAP_BP_No__c,
                   Account__r.Name,
            	   Account__r.PersonMobilePhone,
                   Account__r.PersonEmail,
                    Account__r.PersonMailingAddress,
                    Account__r.PersonMailingCity,
                    Account__r.PersonMailingState,
                    Account__r.PersonMailingPostalCode,
                    Account__r.PersonMailingCountry,  
            	   Unit__r.SAP_Company_Code__c,
            	   Unit__r.SAP_Contract_No__c,
            	   Unit__r.CommunityCompanyCode__c,
            	   Unit__r.CommunityContractNumber__c,
                   // Service-specific (nullable for Misc)
                   Invoice__c,
                   Invoice__r.SAPInvoiceNumber__c,
                   Invoice__r.CustomerNumber__c,
                   Account__r.SAP_Company_Code__c,
                   CurrencyIsoCode,
            		TechnologyFee__c	
            FROM OnlinePayment__c
            WHERE Id = :paymentId
            LIMIT 1
        ];
    }
    
    /**
     * Inserts a new OnlinePayment__c record.
     */
    public OnlinePayment__c insertPayment(OnlinePayment__c payment) {
        if (payment == null) return null;
        insert payment;
        return payment;
    }

    /**
     * Updates an existing OnlinePayment__c record.
     */
    public OnlinePayment__c updatePayment(OnlinePayment__c payment) {
        if (payment == null || payment.Id == null) return payment;
        update payment;
        return payment;
    }
    
}