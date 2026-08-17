/*
* @Author : Rajat Rastogi
* @CreatedDate : 7th AUG 2024
* @Description : Sales Order object trigger helper
*/
/*****************************************************************************************************
* Version       Author      	Date             Comment                                                                       
* 1.0           Biswajeet   	07AUG2024        Initial draft  
* 1.1           Jayesh   	    15NOV2024        Added createDocument method   
* 1.2           Kalpana      22May2025    Added handleafterInsertFieldUpdates
* 1.3           Kalpana      22May2025    Added handleBeforeInsertFieldUpdates
*****************************************************************************************************/

public without sharing class SalesOrderTriggerHelper { 
    
    private static final string SALES_ORDER_STATUS_CANCELLED { get { return 'Cancelled'; } }
    private static final string SALES_ORDER_STATUS_BOOK_CANCELLED { get { return 'Book Cancelled'; } }
    private static final string SALES_ORDER_SUBSTATUS_CANCELLATION_INITIATED { get { return 'Cancellation Initiated'; } }
    private static final string SALES_ORDER_SUBSTATUS_APPROVED_BY_AD_SALES { get { return 'Approved by AD Sales'; } }
    private static final string SALES_ORDER_SUBSTATUS_DOCUMENT_ISSUED { get { return 'Document Issued'; } }
     private static final String SO_STATUS_SOLD = 'Sold';
    private static final String STATUS_COMPLETED = 'Completed';
    
       
    public static void updateSAPFlag(List<SalesOrder__c> newList, Map<Id, SalesOrder__c> oldMap){
        for(SalesOrder__c objSalesOrder :newList){
            if((objSalesOrder.Reserved_Date__c != oldMap.get(objSalesOrder.Id).Reserved_Date__c)
               || (objSalesOrder.Bloom_Signed_SPA_Date__c != oldMap.get(objSalesOrder.Id).Bloom_Signed_SPA_Date__c)
               || (objSalesOrder.SoldDate__c != oldMap.get(objSalesOrder.Id).SoldDate__c)
               || (objSalesOrder.Cancellation_Request_Date__c != oldMap.get(objSalesOrder.Id).Cancellation_Request_Date__c)
               || (objSalesOrder.SalesOrderCancelledDate__c != oldMap.get(objSalesOrder.Id).SalesOrderCancelledDate__c)
               || (objSalesOrder.Status__c != oldMap.get(objSalesOrder.Id).Status__c)
               || (objSalesOrder.SubStatus__c != oldMap.get(objSalesOrder.Id).SubStatus__c)){
                   objSalesOrder.SAP_Update_Flag__c  = true;
               } 
              if(oldMap != NULL && oldMap.get(objSalesOrder.Id).ADHACancellationReason__c != objSalesOrder.ADHACancellationReason__c){
                objSalesOrder.PriorADHAStatus__c = oldMap.get(objSalesOrder.Id).ADHAStatus__c ; // helps in ADHA Cancellation Process
            }
        }
    }
    
  public static void updateSalesorderOnHandover(List<SalesOrder__c> newList, Map<Id, SalesOrder__c> oldMap) {
        HandoverService objHandoverService = HandoverService.getInstance();
        List<Handover__c> handoversToUpdate = new list<Handover__c>();
        Set<Id> salesorderUnitIds = new Set<Id>();
        for (SalesOrder__c slsObj : newList) {
            if (slsObj.Status__c != oldMap.get(slsObj.Id).Status__c && slsObj.Status__c == SO_STATUS_SOLD) {
                salesorderUnitIds.add(slsObj.Unit__c);
            }
        }
        if(!salesorderUnitIds.isEmpty()){
            handoversToUpdate = objHandoverService.getHandoversByUnitIds(salesorderUnitIds); 
           
        }  
        List<Handover__c> updatedHandovers = new List<Handover__c>();
        if(handoversToUpdate != null && !handoversToUpdate.isEmpty()){
            for (Handover__c ho : handoversToUpdate) {
                if (ho.Unit__r != null) {
                    Id activeSOId = ho.Unit__r.Active_Sales_Order__c;
                    if (ho.Sales_Order__c != activeSOId ) {
                        ho.Sales_Order__c = activeSOId;
                        ho.Account__c = ho.Unit__r.Active_Sales_Order__r.Account__c;
                    }
                    if(ho.Sub_Status__c == 'Under Resale'){
                        ho.Sub_Status__c = ho.Previous_HO_Status__c;
                        ho.Previous_HO_Status__c = 'Under Resale';
                    }
                    updatedHandovers.add(ho);
                }
            }
        }
        //objHandoverService.updateHandoversWithoutTrigger(updatedHandovers);
        objHandoverService.updateHandovers(updatedHandovers);
    }
    
    public static void updateUnitActiveSOAfterUpdate(List<SalesOrder__c> newList, Map<Id,SalesOrder__c> oldMap){
        
        List<Unit__c> unitList = new List<Unit__c>();
        for (SalesOrder__c objSalesOrder : newList){
            
            if(objSalesOrder.Unit__c != NULL && objSalesOrder.Status__c != 'Cancelled' && objSalesOrder.Status__c != 'Book Cancelled' 
               && objSalesOrder.Status__c != oldMap.get(objSalesOrder.Id).Status__c && oldMap != NULL && !objSalesOrder.IsDraftOrder__c){
                   Unit__c unitToUpdate = new Unit__c();
                   unitToUpdate.Id = objSalesOrder.Unit__c;
                   unitToUpdate.hasValidSalesorder__c = true;
                   unitToUpdate.Active_Sales_Order__c = objSalesOrder.Id;
                   if(objSalesOrder.Sale_Type__c != 'Resale'){
                       unitToUpdate.OriginalSalesOrder__c = objSalesOrder.Id;
                   }
                   unitList.add(unitToUpdate);
               }else if(objSalesOrder.Unit__c != NULL && (objSalesOrder.Status__c == 'Cancelled' || objSalesOrder.Status__c == 'Book Cancelled')
                        && objSalesOrder.Status__c != oldMap.get(objSalesOrder.Id).Status__c && oldMap != NULL && !objSalesOrder.IsDraftOrder__c){
                            unitList.add(new Unit__c(Id = objSalesOrder.Unit__c, hasValidSalesorder__c = false, Active_Sales_Order__c = NULL));
                        }   
            
            
            UnitService objUnitService = UnitService.getInstance();
            objUnitService.updateUnitsWithoutTrigger(unitList);
        }
    }
    
    public static void updateUnitActiveSOAfterInsert(List<SalesOrder__c> newList){
        
        List<Unit__c> unitList = new List<Unit__c>();
        for (SalesOrder__c objSalesOrder : newList){
            
            if(objSalesOrder.Unit__c != NULL && objSalesOrder.Status__c != 'Cancelled' && objSalesOrder.Status__c != 'Book Cancelled' && !objSalesOrder.IsDraftOrder__c){
                Unit__c unitToUpdate = new Unit__c();
                unitToUpdate.Id = objSalesOrder.Unit__c;
                unitToUpdate.hasValidSalesorder__c = true;
                unitToUpdate.Active_Sales_Order__c = objSalesOrder.Id;
                if(objSalesOrder.Sale_Type__c != 'Resale'){
                    unitToUpdate.OriginalSalesOrder__c = objSalesOrder.Id;
                }
                unitList.add(unitToUpdate);
            }else if(objSalesOrder.Unit__c != NULL && (objSalesOrder.Status__c == 'Cancelled' || objSalesOrder.Status__c == 'Book Cancelled')){
                unitList.add(new Unit__c(Id = objSalesOrder.Unit__c, hasValidSalesorder__c = false, Active_Sales_Order__c = NULL));
            }
            
        }
        UnitService objUnitService = UnitService.getInstance();
        objUnitService.updateUnitsWithoutTrigger(unitList);
    }
    
    public static void createDocuments(List<SalesOrder__c> newList){
        DocumentService objDocumentService = DocumentService.getInstance();
        List<DocumentType__c> salesDocTypeList = objDocumentService.getDocTypes('Sales Order');
        List<Document__c> documentList = new List<Document__c>();
        Map<id,id>soUnitMap = new map<id,id>();
        set<id>unitIds = new set<id>();
        Set<Id> accountIds = new Set<Id>();
        for (SalesOrder__c so : newList) {
            System.debug('unitid'+so.Unit__c);
            if (so.Unit__c != null) {
                soUnitMap.put(so.Id, so.Unit__c);
                unitIds.add(so.Unit__c);
            }
            if(so.Account__c != NULL){
                accountIds.add(so.Account__c);
            }
        }
        List<Unit__c> unitInfoList = UnitService.getAllUnitsById(unitIds);
        AccountService accSer = AccountService.getInstance();
        Map<Id, Account> accountMap = new Map<Id, Account>(accSer.getAccountByIds(accountIds));
        Map<Id, Id> unitProjectMap = new Map<Id, Id>();
        for (Unit__c unit : unitInfoList) {
            unitProjectMap.put(unit.Id, unit.Project__c);
        }
        
        for(SalesOrder__c salesOrder :newList){
            Boolean isResaleOrder = false;
            if(salesOrder.IsDraftOrder__c || salesOrder.PreviousSalesOrder__c != NULL || salesOrder.Resale__c){
                isResaleOrder = true;
            }
            for(DocumentType__c objDocumentType :salesDocTypeList){
                if(objDocumentType.IsDocgen__c == false && objDocumentType.DigitalSignature__c == false){
                    documentList.add(new Document__c(SalesOrder__c	= salesOrder.Id, DocumentType__c = objDocumentType.Id, Document_Name__c = objDocumentType.Type__c));
                }
                if (soUnitMap.containsKey(salesOrder.Id)) {
                    Id unitId = soUnitMap.get(salesOrder.Id);
                    if (unitProjectMap.containsKey(unitId)) {
                        Id projectId = unitProjectMap.get(unitId);
                        
                        if (objDocumentType.Project__c == projectId && objDocumentType.Active__c == true && objDocumentType.Resale__c == isResaleOrder
                            && (objDocumentType.Customer_Type__c == accountMap.get(salesOrder.Account__c).RecordType.DeveloperName || objDocumentType.Customer_Type__c == 'All')
                            && ((objDocumentType.IsDocgen__c == true && objDocumentType.DigitalSignature__c == false) || (objDocumentType.IsDocgen__c == false && objDocumentType.DigitalSignature__c == true))) {
                                
                                documentList.add(new Document__c(
                                    SalesOrder__c = salesOrder.Id,
                                    DocumentType__c = objDocumentType.Id,
                                    Document_Name__c = objDocumentType.Type__c
                                ));
                            }
                        /*if (objDocumentType.IsDocgen__c == false && objDocumentType.DigitalSignature__c == true &&  objDocumentType.Project__c == projectId && objDocumentType.Active__c == true) {
documentList.add(new Document__c(
SalesOrder__c = salesOrder.Id,
DocumentType__c = objDocumentType.Id,
Document_Name__c = objDocumentType.Type__c
));
}*/
                    }
                }
            }
        }
        if (!documentList.isEmpty()) {
            objDocumentService.insertDocuments(documentList);
        }
        
    }
    public static void handleBeforeInsertFieldUpdates(List<SalesOrder__c> newList){
        Set<Id> unitIds = new Set<Id>();
        
        for (SalesOrder__c so : newList) {
            if (so.Unit__c != null) {
                unitIds.add(so.Unit__c);
            }
        }
        
        Map<Id, Unit__c> unitMap = new Map<Id, Unit__c>();
        if (!unitIds.isEmpty()) {
            unitMap = new Map<Id, Unit__c>(UnitService.getAllUnitsById(unitIds));
        }
        
        for (SalesOrder__c so : newList) {
            if (so.Unit__c != null && unitMap.containsKey(so.Unit__c)) {
                so.Company_Code__c = unitMap.get(so.Unit__c).SAP_Company_Code__c;
            }
        } 
    }
    
    public static void handleafterInsertFieldUpdates(List<SalesOrder__c> newList){     
        
        Map<Id, Account> accountsToUpdate = new Map<Id, Account>();
        Map<Id, Opportunity> opportunitiesToUpdate = new Map<Id, Opportunity>();
        
        for (SalesOrder__c so : newList) {
            
            if (so.Opportunity__c != null ) {
                Opportunity opp = new Opportunity(Id = so.Opportunity__c, StageName = 'Closed Won');
                opportunitiesToUpdate.put(opp.Id, opp);
            }
            if (so.Account__c != null) {
                Account acc = new Account(Id = so.Account__c, Main_Buyer__c = true, Send_To_SAP__c = true);
                if (so.Company_Code__c != null) {
                    acc.SAP_Company_Code__c = so.Company_Code__c;
                }
                accountsToUpdate.put(acc.Id, acc);
            }
            if (so.Broker_Agency__c != null) {
                Account acc = new Account(Id = so.Broker_Agency__c, Send_To_SAP__c = true);
                if (so.Company_Code__c != null) {
                    acc.SAP_Company_Code__c = so.Company_Code__c;
                }
                accountsToUpdate.put(acc.Id, acc);
            }
        }
        AccountService.getInstance().updateAccounts(accountsToUpdate.values());
        OpportunityService.getInstance().updateOpportunitiesWithoutTrigger(opportunitiesToUpdate.values());
    }
    
    public static void handleBeforeUpdateFieldUpdates(List<SalesOrder__c> newList, Map<Id,SalesOrder__c> oldMap){
        //Set<Id> soldSalesOrderUnitIds = new Set<Id>();
        for(SalesOrder__c objSalesOrder : newList){
            if(objSalesOrder.Status__c != oldMap.get(objSalesOrder.Id).Status__c) {
                if(objSalesOrder.Status__c == SALES_ORDER_STATUS_CANCELLED || objSalesOrder.Status__c == SALES_ORDER_STATUS_BOOK_CANCELLED){
                    objSalesOrder.SalesOrderCancelledDate__c = System.today();
                }
                /* if(objSalesOrder.Status__c == SO_STATUS_SOLD){
                    soldSalesOrderUnitIds.add(objSalesOrder.Unit__c);
                } */
            }

            if(objSalesOrder.SubStatus__c != oldMap.get(objSalesOrder.Id).SubStatus__c){
                if(objSalesOrder.SubStatus__c == SALES_ORDER_SUBSTATUS_CANCELLATION_INITIATED){
                    objSalesOrder.Cancellation_Request_Date__c = System.today();
                }
                if(objSalesOrder.SubStatus__c == SALES_ORDER_SUBSTATUS_APPROVED_BY_AD_SALES){
                    objSalesOrder.SalesApprovedDate__c = System.today();
                }
                if(objSalesOrder.SubStatus__c == SALES_ORDER_SUBSTATUS_DOCUMENT_ISSUED){
                    objSalesOrder.ContractIssuedDate__c = System.today();
                }
            }

            if(objSalesOrder.Bloom_Signed_SPA_Date__c != oldMap.get(objSalesOrder.Id).Bloom_Signed_SPA_Date__c){
                if(!objSalesOrder.Resale__c)
                objSalesOrder.SoldDate__c = objSalesOrder.Bloom_Signed_SPA_Date__c;
            }
        }
        /* if(!soldSalesOrderUnitIds.isEmpty()){
            handleSoldSalesOrderDetailsUpdate(soldSalesOrderUnitIds, newList);
        } */
    }

    /* public static void handleSoldSalesOrderDetailsUpdate(Set<Id> soldSalesOrderUnitIds, List<SalesOrder__c> newList){
        SalesOrderService objSalesOrderService = SalesOrderService.getInstance();
        HandoverService objHandoverService = HandoverService.getInstance();
        List<Handover__c> relatedHandovers = objHandoverService.getHandoversByUnitIds(soldSalesOrderUnitIds);
        Map<Id,Handover__c> salesOrderTohandoverMap = new Map<Id,Handover__c>();
        for(Handover__c ho : relatedHandovers) {
            if (ho.Unit__r != null) {
                salesOrderTohandoverMap.put(ho.Unit__r.Active_Sales_Order__c, ho);
            }
        }
        for(SalesOrder__c soRec : newList){
            if(salesOrderTohandoverMap != NULL && salesOrderTohandoverMap.containsKey(soRec.Id) ){
                soRec.Handover__c = salesOrderTohandoverMap.get(soRec.Id).Id;
            }
        }
    } */
}