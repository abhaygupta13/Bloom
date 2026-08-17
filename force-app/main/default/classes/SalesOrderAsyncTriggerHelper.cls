/*
* @Author : Bloom Holding
* @CreatedDate : 28 APRIL 2025
* @Description : Sales Order object CDC trigger helper
*/
/*****************************************************************************************************
* Version       Author      	Date             Comment                                                                       
* 1.0           Anjaneya   	    28April2025      initial draft
*****************************************************************************************************/
public without sharing class SalesOrderAsyncTriggerHelper {
    
    private static final string INTEGRATION_STATUS_IN_PROGRESS { get { return 'In Progress'; } }
    private static final string SALES_ORDER_MULE_STATUS_DEV_NEW { get { return 'DEV_NEW'; } }
    private static final string SALES_ORDER_MULE_STATUS_DEV_SALES_OFFER_GENERATED { get { return 'DEV_SALES_OFFER_GENERATED'; } }
    private static final string SALES_ORDER_MULE_STATUS_DEV_RESERVATION_AGREEMENT_SIGNED { get { return 'DEV_RESERVATION_AGREEMENT_SIGNED'; } }
    private static final string SALES_ORDER_MULE_STATUS_DEV_SPA_SIGNED { get { return 'DEV_SPA_SIGNED'; } }
    private static final string SALES_ORDER_ADHA_STATUS_DEV_NEW { get { return 'Dev New'; } }
    private static final string SALES_ORDER_ADHA_STATUS_DEV_SALES_OFFER_GENERATED { get { return 'Dev Sales Offer Generated	'; } }
    private static final string SALES_ORDER_ADHA_STATUS_DEV_RESERVATION_AGREEMENT_SIGNED { get { return 'Dev Reservation Agreement Signed'; } }
    private static final string SALES_ORDER_ADHA_STATUS_DEV_SPA_SIGNED { get { return 'Dev SPA Signed'; } }
    
    public static void createIntegrationRecord(List<Id> adhaSalesOrderIdsList)
    {           
        SalesOrderService objsalesOrderService = SalesOrderService.getInstance();
        Set<Id> salesOrderIdSet = new Set<Id>();
        salesOrderIdSet.addAll(adhaSalesOrderIdsList);
        List<IntegrationRecord__c> integrationRecordsToInsert = new List<IntegrationRecord__c>();
        List<SalesOrder__c> salesOrderList = objsalesOrderService.getADHASalesOrders(salesOrderIdSet);
        List<SalesOrder__c> updSalesOrderList = new List<SalesOrder__c>();
        for(SalesOrder__c salesOrder : salesOrderList ){
            //Prepare Integration record here.. 
            integrationRecordsToInsert.add(objsalesOrderService.prepareIntegrationRecord(salesOrder));
            Map<String,String> statusValueMappings = new Map<String, String>{
                SALES_ORDER_MULE_STATUS_DEV_NEW => SALES_ORDER_ADHA_STATUS_DEV_NEW,
                    SALES_ORDER_MULE_STATUS_DEV_SALES_OFFER_GENERATED =>  SALES_ORDER_ADHA_STATUS_DEV_SALES_OFFER_GENERATED,
                    SALES_ORDER_MULE_STATUS_DEV_RESERVATION_AGREEMENT_SIGNED => SALES_ORDER_ADHA_STATUS_DEV_RESERVATION_AGREEMENT_SIGNED,
                    SALES_ORDER_MULE_STATUS_DEV_SPA_SIGNED => SALES_ORDER_ADHA_STATUS_DEV_SPA_SIGNED
                    };
                        String adhaStatusVar = statusValueMappings.get(objsalesOrderService.prepareIntegrationRecord(salesOrder).Param2__c);  //Param2__c is the Status vaue we send to Mule                             
            updSalesOrderList.add(new SalesOrder__c(id=salesOrder.id,ADHAIntegrationStatus__c=INTEGRATION_STATUS_IN_PROGRESS,
                                                    ADHAStatus__c = adhaStatusVar ,ADHASalesOrderLastIntegrateddate__c=DateTime.now().addHours(4)));
        }
        objsalesOrderService.updateSalesOrdersWithoutTrigger(updSalesOrderList);
        IntegrationRecordService integService = IntegrationRecordService.getInstance();
        integService.insertIntegrationRecords(integrationRecordsToInsert);
    }
}