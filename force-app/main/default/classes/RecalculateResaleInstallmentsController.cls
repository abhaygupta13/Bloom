public without sharing class RecalculateResaleInstallmentsController {
    private static final string RESALE_CASE_RECORDTYPE_IDS { get { return 'ResaleCaseRecordTypeIds'; } }
    
    @AuraEnabled
    public static String createInstallmentsReceipts(Id salesOrderId) {
        if(salesOrderId == null){
            return 'Invalid Sales Order Id';
        }
        try{
            ResaleServiceRequestHandler objResaleServiceRequestHandler = ResaleServiceRequestHandler.getInstance();
            MetadataService objMetadataService = MetadataService.getInstance();
            SalesOrderService objSalesOrderService = SalesOrderService.getInstance();
            CaseService objCaseService = CaseService.getInstance();
            ReceiptAllocationService objReceiptAllocationService = ReceiptAllocationService.getInstance();
            ReceiptAcknowledgementService objReceiptAcknowledgementService = ReceiptAcknowledgementService.getInstance();
            InstallmentLineService objInstallmentLineService = InstallmentLineService.getInstance();
            
            SalesOrder__c objSalesOrder = objSalesOrderService.getSalesOrdersById(salesOrderId);
            List<String> resalecaseRecordTypeIds = new List<String>();
            List<Case> caseList = new List<Case>();
            String resaleCaseRecordTypeId = objMetadataService.getAppSettingTextValue(RESALE_CASE_RECORDTYPE_IDS);
            if(resaleCaseRecordTypeId != null) resalecaseRecordTypeIds.addAll(resaleCaseRecordTypeId.split(','));
            if(objSalesOrder.PreviousSalesOrder__c != null){
                List<ReceiptAllocation__c> lstReceiptAllocation = objReceiptAllocationService.getReceiptAllocationBySO(salesOrderId);
                List<ReceiptAcknowledgement__c> lstReceiptAcknowledgement = objReceiptAcknowledgementService.getReceiptAcknowledgementAndReceiptAllocationsBySOId(salesOrderId);
                List<InstallmentLines__c> lstInstallmentLines = objInstallmentLineService.getAllInstallmentLinesBySalesOrderId(salesOrderId);
                if(!lstReceiptAllocation.isEmpty()){
                    objReceiptAllocationService.deleteReceiptAllocationsWithoutTrigger(lstReceiptAllocation);
                }
                if(!lstReceiptAcknowledgement.isEmpty()){
                    objReceiptAcknowledgementService.deleteReceiptAcknowledgementWithoutTrigger(lstReceiptAcknowledgement);
                }
                if(!lstInstallmentLines.isEmpty()){
                    objInstallmentLineService.deleteInstallmentLines(lstInstallmentLines);
                }
                caseList = objCaseService.getCasesByRecordTypeSalesOrderANDStatus(objSalesOrder.PreviousSalesOrder__c,resalecaseRecordTypeIds,'In Progress');
                if(!caseList.isEmpty()){
                    Set<Id> salesOrderIdSet = new Set<Id>{ caseList[0].Sales_Order__c };
                        Case caseRec = caseList[0];
                    InstallmentLineService lineServiceObj = InstallmentLineService.getInstance();
                    List<InstallmentLines__c> actualInstallments = lineServiceObj.getAllInstallmentLinesBySalesOrder(salesOrderIdSet);
                    List<InstallmentLines__c> handoverInstallments = new List<InstallmentLines__c>();
                    List<InstallmentLines__c> posthandoverInstallments = new List<InstallmentLines__c>();
                    
                    if(!actualInstallments.isEmpty()){
                        for(InstallmentLines__c line : actualInstallments){
                            if(line.Type__c =='Handover'){
                                handoverInstallments.add(line);
                            }
                            if(line.Type__c =='Post Handover Installment'){
                                posthandoverInstallments.add(line); 
                            }
                            
                        }   
                    }
                    if(!handoverInstallments.isEmpty()
                       &&!posthandoverInstallments.isEmpty()
                       &&(caseRec.TypeOfResale__c =='Resale' 
                          ||caseRec.TypeOfResale__c =='Gifting' 
                          ||((caseRec.TypeOfResale__c =='Addition/Deletion'
                              ||caseRec.TypeOfResale__c =='Add/Del of Kin') && caseRec.InitialOwnerRemoved__c =='Yes'))){
                                    System.debug('in if of recalcualte');
                                  objResaleServiceRequestHandler.calculateInstallmentsAndReceiptsForPHPP(caseRec.Sales_Order__c,objSalesOrder,caseRec);     
                              }
                    else{
                        System.debug('in else of recalcualte');  
                        objResaleServiceRequestHandler.calculateInstallmentsAndReceipts(caseRec.Sales_Order__c,objSalesOrder,caseRec);  
                    }
                    //objResaleServiceRequestHandler.calculateInstallmentsAndReceipts(objSalesOrder.PreviousSalesOrder__c, objSalesOrder, caseList[0]);
                }
                /*List<InstallmentLines__c> installmentLineList = objInstallmentLineService.getFirstInstallmentLineBySalesOrder(salesOrderId);
if(!installmentLineList.isEmpty()){
installmentLineList[0].InstallmentDate__c = objSalesOrder.BookingDate__c;
objInstallmentLineService.updateInstallmentLines(installmentLineList);
}*/
            }
            return 'Installments and Receipts created successfully.';
        }catch (Exception ex) {
            System.debug('Error: ' + ex.getMessage());
            throw new AuraHandledException('Error while creating installments and receipts: ' + ex.getMessage());
        }
    }
}