/***
Class       : SalesOrderAsyncTriggerHandler
Author      : Jhilik
Description : 
TestClass   : SalesOrderAsyncTriggerHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.     version              Date                      Details
1.          V1.0                20-03-2025                Initial Version 
****************************************************************************************************************/
public without sharing class SalesOrderAsyncTriggerHandler implements IAsyncTriggerHandler {
    
    //Use this variable to disable this trigger from transaction
    public static Boolean isAsyncTriggerDisabled = false;
    private static final Set<String> SALES_ORDER_ADHA_STATUSES = new Set<String>{'Booked','Reserved','Sold'};
        private static final Set<String> SALES_ORDER_ADHA_CANCEL_STATUSES = new Set<String>{'Booked','Reserved'};
            
            private static final string CUSTOMER_SIGNED_SUB_STATUS { get { return 'SPA Counter Signed'; } }
    private static final string SALES_ORDER_SUB_STATUS_BOOKING_FORMS_SIGNED { get { return 'Booking Forms Signed'; } }
    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled(){
        return isAsyncTriggerDisabled;
    }
    
    Set<Id> soldSalesOrderIdsSet = new Set<Id>();
    List<Id> soldSalesOrderIdsList = new List<Id>();
    List<Id> adhaSalesOrderIdsList = new List<Id>();
    
    
    public void changeEventCapture(List<sObject> newList) {
        List<SalesOrder__ChangeEvent> objLeadChangeEventList =  (List<SalesOrder__ChangeEvent>)newList;
        for (SalesOrder__ChangeEvent event : objLeadChangeEventList) {
            //Get event header fields
            EventBus.ChangeEventHeader header = event.ChangeEventHeader;
            switch on header.changeType {
                when 'CREATE'{
                    if((event.get('Status__c') != NULL && ((String)(event.get('Status__c'))) == 'Booked') ){
                        adhaSalesOrderIdsList.addAll(header.getRecordIds());
                    }
                }
                when 'UPDATE'{
                    if(event.get('CustomerSignedSPADate__c') != NULL){
                        soldSalesOrderIdsList.addAll(header.getRecordIds());
                    }
                    if((event.get('Status__c') != NULL && SALES_ORDER_ADHA_STATUSES.contains((String)(event.get('Status__c'))) ) 
                       || (event.get('SubStatus__c') != NULL && event.get('SubStatus__c') == CUSTOMER_SIGNED_SUB_STATUS ) 
                       || (event.get('SubStatus__c') != NULL && event.get('SubStatus__c') == SALES_ORDER_SUB_STATUS_BOOKING_FORMS_SIGNED ) 
                       || (event.get('ADHACancellationReason__c') != NULL) ){
                           adhaSalesOrderIdsList.addAll(header.getRecordIds());
                       }
                }
                when 'DELETE'{ 
                }
                when 'UNDELETE'{
                }
            }
        }
        
        if(!soldSalesOrderIdsList.isEmpty()){
            soldSalesOrderIdsSet.addAll(soldSalesOrderIdsList);
            SurveyHandler.sendSalesCustomerSurvey(soldSalesOrderIdsSet);
        }
        if(!adhaSalesOrderIdsList.isEmpty()){
            SalesOrderAsyncTriggerHelper.createIntegrationRecord(adhaSalesOrderIdsList);
        }
    }
}