/*****************************************************************************************
Class       : IntegrationController
Author      : Vikas Baliyan
Description : Integration Controller
Test Class  : 
Created Date: 04 Feb 2025 
*****************************************************************************************/
public without sharing class IntegrationController {
    
    private static final string APPROVED_STR { get { return 'Approved'; } }
    private static final string SUCCESS_STR { get { return 'Success'; } }
    private static final string INSERT_STR { get { return 'Insert'; } }
    private static final string UPDATE_STR { get { return 'Update'; } }
    
    @AuraEnabled
    public static void reTriggerPlatformEvent(Id recordId){
        IntegrationRecordService integService = IntegrationRecordService.getInstance();
        try{
            Boolean isSuccess = false;
            if(recordId.getSObjectType() == BrokerCommission__c.getSObjectType()){
                BrokerCommissionService ObjbrokerCommissionService = BrokerCommissionService.getInstance();
                //Fetch broker commission record
                BrokerCommission__c broker = ObjbrokerCommissionService.getBrokerRecordsByidSet(new Set<Id>{recordId})[0];
                IntegrationRecord__c integrationRecord;
                
                //invoke insert/update event 
                if(broker.SecondApprovalStatus__c == APPROVED_STR && broker.IntegrationStatus__c != SUCCESS_STR && broker.FinalApprovalStatus__c != APPROVED_STR){
                    integrationRecord = BrokerCommissionTriggerHelper.getIntegrationRecord(broker, INSERT_STR);
                }
                else if(broker.FinalApprovalStatus__c == APPROVED_STR && broker.IntegrationStatus__c != SUCCESS_STR){
                    integrationRecord = BrokerCommissionTriggerHelper.getIntegrationRecord(broker, UPDATE_STR);
                }
                ObjbrokerCommissionService.updateBrokerCommissionWithoutTrigger(new List<BrokerCommission__c>{new BrokerCommission__c(Id = broker.Id,IntegrationStatus__c = 'In Progress',IntegrationMessage__c = '')});
                integService.insertIntegrationRecords(new List<IntegrationRecord__c>{integrationRecord});
            }else if(recordId.getSObjectType() == Account.getSObjectType()){
                AccountService objAccountService = AccountService.getInstance();
                objAccountService.updateAccount(new Account(Id = recordId, Send_To_SAP__c = true));
            }else if(recordId.getSObjectType() == InstallmentLines__c.getSObjectType()){
                InstallmentLineService objInstallmentLineService = InstallmentLineService.getInstance();
                objInstallmentLineService.updateinstallmentLine(new InstallmentLines__c(Id = recordId, Send_To_SAP__c = true));
            }else if(recordId.getSObjectType() == SalesOrderOtherCharges__c.getSObjectType()){
                IntegrationRecord__c integrationRec;
                SalesOrderOtherChargesService objSalesOrderOtherChargesService = SalesOrderOtherChargesService.getInstance();
                SalesOrderOtherCharges__c otherCharges = objSalesOrderOtherChargesService.getSalesOrderOtherChargesByIds(new Set<Id>{recordId})[0];
                if(otherCharges.ReversalApprovalDate__c != null){
                    //update event
                    objSalesOrderOtherChargesService.updateOtherChargesWithoutTrigger(new List<SalesOrderOtherCharges__c>{new SalesOrderOtherCharges__c(Id = recordId, SendtoSAP__c = false)});
                    objSalesOrderOtherChargesService.updateOtherCharge(new SalesOrderOtherCharges__c(Id = recordId, SendtoSAP__c = true));
                }else{
                    //insert event
                    objSalesOrderOtherChargesService.updateOtherChargesWithoutTrigger(new List<SalesOrderOtherCharges__c>{new SalesOrderOtherCharges__c(Id = recordId, IntegrationStatus__c = 'In Progress', IntegrationMessage__c = '')});
                    integrationRec = objSalesOrderOtherChargesService.createOtherChargeIntegrationRecord(otherCharges, INSERT_STR);
                    integService.insertIntegrationRecords(new List<IntegrationRecord__c>{integrationRec});
                }
            }else if(recordId.getSObjectType() == ReceiptAcknowledgement__c.getSObjectType()){
                ReceiptAcknowledgementService objReceiptAcknowledgementService = ReceiptAcknowledgementService.getInstance();
                
                objReceiptAcknowledgementService.updateReceiptAcknowledgementWithoutTrigger(new List<ReceiptAcknowledgement__c>{new ReceiptAcknowledgement__c(Id = recordId, SendtoSAP__c = false)});
                objReceiptAcknowledgementService.updateReceiptAcknowledgement(new ReceiptAcknowledgement__c(Id = recordId, SendtoSAP__c = true));         
            }else if (recordId.getSObjectType() == LeasingOrder__c.getSObjectType()) {
                LeasingOrderService objLeasingOrderService = LeasingOrderService.getInstance();
                /*objLeasingOrderService.updateLeasingOrder(new LeasingOrder__c(Id = recordId, SendToSAP__c = true,IntegrationTriggeredDate__c = System.Now()));*/
                LeasingOrder__c leasingOrder = objLeasingOrderService.getLeasingOrderforSyncById(recordId);
                AccountService objAccountService = AccountService.getInstance();
                objAccountService.updateAccount(new Account(Id = leasingOrder.Account__c, Send_To_SAP__c = true));
            }else if (recordId.getSObjectType() == User__c.getSObjectType()) {
                CustomUserService objCustomUserService = CustomUserService.getInstance();
                objCustomUserService.updateUser(new User__c(Id = recordId, IsSendToAB2C__c = true));
            }else if (recordId.getSObjectType() == PaymentPlanSchedule__c.getSObjectType()) {
                LeasingPaymentScheduleService objLeasingPaymentPlanScheduleService = LeasingPaymentScheduleService.getInstance();
                objLeasingPaymentPlanScheduleService.updatePaymentPlanSchedule(new PaymentPlanSchedule__c(Id = recordId, SendToSAP__c = true));
            }else if (recordId.getSObjectType() == LeasingOrdersOtherCharges__c.getSObjectType()) {
                LeasingOtherChargesService objLeasingOtherChargesService = LeasingOtherChargesService.getInstance();
                objLeasingOtherChargesService.updateOtherCharge(new LeasingOrdersOtherCharges__c(Id = recordId, SendToSAP__c = true));
            } else if(recordId.getSObjectType() == LeasingReceiptAcknowledgment__c.getSObjectType()){
                LeasingReceiptAcknowledgementService leasingRAService = LeasingReceiptAcknowledgementService.getInstance();
                leasingRAService.updateOtherCharge(new LeasingReceiptAcknowledgment__c(Id = recordId, SendtoSAP__c = true));
            }if(recordId.getSObjectType() == LeasingReceiptAllocation__c.getSObjectType()){
                LeasingReceiptAllocation__c lra =  new LeasingReceiptAllocation__c(Id = recordId, SendtoSAP__c = true);
                //update lra;
                LeasingReceiptAllocationService service = LeasingReceiptAllocationService.getInstance();
                service.updateLeasingReceiptAllocation(lra);
            }
        } 
        catch(System.exception ex){
            throw new AuraHandledException('Error: '+ ex.getMessage());   
        } 
    }   
    
    @AuraEnabled
    public static void sendLeasingOrderToSAP(Id recordId) {
        try {
            if (recordId == null) {
                throw new AuraHandledException('Leasing Order Id is required.');
            }
            
            LeasingOrderService objLeasingOrderService = LeasingOrderService.getInstance();
            objLeasingOrderService.updateLeasingOrder(new LeasingOrder__c(Id = recordId, SendToSAP__c = true,IntegrationTriggeredDate__c = System.Now()));
            
            
        } catch (Exception ex) {
            throw new AuraHandledException('Error while sending Leasing Order to SAP: ' + ex.getMessage());
        }
    }
}