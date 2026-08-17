/***
Class       : OnlinePaymentLogHandler 
Author      : Aman Bharti
Description : 
TestClass   : OnlinePaymentLogTriggerHelperTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date          Author       Details
1.          V1.0              04/12/25                  Initial Version 
****************************************************************************************************************/
public inherited sharing class OnlinePaymentLogHandler {

    private static final String TECHNOLOGY_FEE_STR { get { return 'Technology Fee'; } }
    private static final String SUPER_APP_STR { get { return 'Super App'; } }
    private static final String CLEARED_STR { get { return 'Cleared'; } }
    private static final string BLOOM_NO_REPLY_SALES_OW_EMAIL_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    private static final string BLOOM_APP_PAYMENT_CONFIRMATION_EMAIL_TEMP_ID { get { return 'BloomAppPaymentConfirmationEmailTempId'; } }

    private static OnlinePaymentLogHandler instance;
    
    public OnlinePaymentLogHandler() {
        
    }
    
    public static OnlinePaymentLogHandler getInstance() { 
        if(instance == null) {
            instance = new OnlinePaymentLogHandler();
        }
        return instance;
    }

    public void processPayment(List<OnlinePaymentLog__c> newList) {
        SalesOrderOtherChargesService objSalesOrderOtherChargesService = SalesOrderOtherChargesService.getInstance();
        ReceiptAcknowledgementService objReceiptAcknowledgementService = ReceiptAcknowledgementService.getInstance();
        InstallmentLineService objInstallmentLineService = InstallmentLineService.getInstance();
        ReceiptAllocationService objReceiptAllocationService = ReceiptAllocationService.getInstance();
        OnlinePaymentLogService objOnlinePaymentLogService = OnlinePaymentLogService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();

        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        Id noReplyBloomSalesOWDId = objMetadataService.getAppSettingTextValue(BLOOM_NO_REPLY_SALES_OW_EMAIL_ID);
        Id bloomAppPaymentConfirmationTempId = objMetadataService.getAppSettingTextValue(BLOOM_APP_PAYMENT_CONFIRMATION_EMAIL_TEMP_ID);

        List<ReceiptAcknowledgement__c> raList = new List<ReceiptAcknowledgement__c>();
        List<SalesOrderOtherCharges__c> otherChargesList = new List<SalesOrderOtherCharges__c>();
        List<ReceiptAllocation__c> allocationList = new List<ReceiptAllocation__c>();

        Set<Id> installmentIdSet = new Set<Id>();
        Set<Id> otherChargesIdSet = new Set<Id>();

        Map<Integer, ReceiptAcknowledgement__c> receiptAckMap = new Map<Integer, ReceiptAcknowledgement__c>();
        Map<Integer, ReceiptAllocation__c> allocationMap = new Map<Integer, ReceiptAllocation__c>();
        Map<Integer, SalesOrderOtherCharges__c> salesOrderOtherChargesMap = new Map<Integer, SalesOrderOtherCharges__c>();
        List<OnlinePaymentLog__c> processedPaymentLogList = new List<OnlinePaymentLog__c>(); 


        for (OnlinePaymentLog__c paymentLog : newList) {
            PaymentWrapper paymentDetail = (PaymentWrapper) JSON.deserialize(paymentLog.JSONData__c, PaymentWrapper.class);   
            if (paymentDetail.instalments != null) {
                for (InstallmentWrapper inst : paymentDetail.instalments) {
                    installmentIdSet.add(inst.Id);
                }
                for (OtherChargeWrapper otherCharge : paymentDetail.other_charges) {
                    otherChargesIdSet.add(otherCharge.Id);
                }
            }
        }

        Map<Id, InstallmentLines__c> installmentLineMap = new Map<Id, InstallmentLines__c>(objInstallmentLineService.getInstallmentLinesByIds(installmentIdSet));
        Map<Id, SalesOrderOtherCharges__c> otherChargesMap = new Map<Id, SalesOrderOtherCharges__c>(objSalesOrderOtherChargesService.getSalesOrderOtherChargesByIds(otherChargesIdSet));

        Integer index = 0;
        for (OnlinePaymentLog__c paymentLog : newList) {
            PaymentWrapper paymentDetail = (PaymentWrapper) JSON.deserialize(paymentLog.JSONData__c, PaymentWrapper.class);
            if (paymentDetail.instalments != null) {
                for (InstallmentWrapper inst : paymentDetail.instalments) {
                    index += 1;
                    ReceiptAcknowledgement__c raPaidAmount = objReceiptAcknowledgementService.createReceiptAcknowledgementObj(inst.paid_amount, installmentLineMap.get(inst.Id).SalesOrder__c, installmentLineMap.get(inst.Id).SalesOrder__r.Unit__c,installmentLineMap.get(inst.Id).SalesOrder__r.Account__c, installmentLineMap.get(inst.Id).SalesOrder__r.Opportunity__c, SUPER_APP_STR, CLEARED_STR,true, 'Abu Dhabi Commercial Bank',paymentDetail.tran_ref);
                    raPaidAmount.Bank_Account__c = installmentLineMap.get(inst.Id).Type__c == 'Installment' || installmentLineMap.get(inst.Id).Type__c == 'Down Payment' ? installmentLineMap.get(inst.Id).SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__c : installmentLineMap.get(inst.Id).Type__c == 'Handover' ? installmentLineMap.get(inst.Id).SalesOrder__r.Unit__r.BuildingSectionName__r.HandoverAccountInstallment__c : installmentLineMap.get(inst.Id).Type__c == 'Post Handover Installment'  ? installmentLineMap.get(inst.Id).SalesOrder__r.Unit__r.BuildingSectionName__r.PHPPAccountInstallment__c : null;
                    raPaidAmount.SAP_Special_GL_Indicator__c = 'X';
                    raList.add(raPaidAmount);
                    receiptAckMap.put(index , raPaidAmount);

                    ReceiptAllocation__c allocationPaidAmount = objReceiptAllocationService.createReceiptAllocationObj(inst.paid_amount, inst.Id, null, installmentLineMap.get(inst.Id).SalesOrder__c,installmentLineMap.get(inst.Id).SalesOrder__r.Account__c);
                    allocationMap.put(index, allocationPaidAmount);
                    index += 1;
                    ReceiptAcknowledgement__c raTechFee = objReceiptAcknowledgementService.createReceiptAcknowledgementObj(inst.technology_fee, installmentLineMap.get(inst.Id).SalesOrder__c, installmentLineMap.get(inst.Id).SalesOrder__r.Unit__c,installmentLineMap.get(inst.Id).SalesOrder__r.Account__c, installmentLineMap.get(inst.Id).SalesOrder__r.Opportunity__c, SUPER_APP_STR, CLEARED_STR,true,  'Abu Dhabi Commercial Bank',paymentDetail.tran_ref);
                    raTechFee.Bank_Account__c = installmentLineMap.get(inst.Id).SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__c;
                    raList.add(raTechFee);  
                    receiptAckMap.put(index , raTechFee);

                    SalesOrderOtherCharges__c otherCharges = objSalesOrderOtherChargesService.createSalesOrderOtherChargesObj(installmentLineMap.get(inst.Id).SalesOrder__c,null, inst.Id,inst.technology_fee,TECHNOLOGY_FEE_STR,null,null,null,Date.today());
                    otherCharges.InvoicedAmount__c = inst.technology_fee;
                    otherCharges.SendtoSAP__c = true;
                    otherCharges.SAP_Condition_Type__c = installmentLineMap.get(inst.Id).SalesOrder__r.Unit__r.Project__r.TechnologyFeeConditionType__c;
                    otherChargesList.add(otherCharges);
                    salesOrderOtherChargesMap.put(index, otherCharges);

                    ReceiptAllocation__c allocationTechFee = objReceiptAllocationService.createReceiptAllocationObj(inst.technology_fee, null, null, installmentLineMap.get(inst.Id).SalesOrder__c, installmentLineMap.get(inst.Id).SalesOrder__r.Account__c);
                    allocationMap.put(index, allocationTechFee);
                }       
            }

            if (paymentDetail.other_charges != null) {
                for (OtherChargeWrapper otherCharge : paymentDetail.other_charges) {
                    index += 1;
                    ReceiptAcknowledgement__c raPaidAmount = objReceiptAcknowledgementService.createReceiptAcknowledgementObj(otherCharge.paid_amount, otherChargesMap.get(otherCharge.Id).SalesOrder__c, otherChargesMap.get(otherCharge.Id).SalesOrder__r.Unit__c, otherChargesMap.get(otherCharge.Id).SalesOrder__r.Account__c, otherChargesMap.get(otherCharge.Id).SalesOrder__r.Opportunity__c, SUPER_APP_STR, CLEARED_STR, true, 'Abu Dhabi Commercial Bank',paymentDetail.tran_ref);
                    raPaidAmount.Bank_Account__c = otherChargesMap.get(otherCharge.Id).SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__c;
                    raList.add(raPaidAmount);
                    receiptAckMap.put(index, raPaidAmount);

                    ReceiptAllocation__c allocationPaidAmount = objReceiptAllocationService.createReceiptAllocationObj(otherCharge.paid_amount, null, otherCharge.id, otherChargesMap.get(otherCharge.Id).SalesOrder__c, otherChargesMap.get(otherCharge.Id).SalesOrder__r.Account__c);
                    allocationMap.put(index, allocationPaidAmount);
                    index += 1;

                    ReceiptAcknowledgement__c raTechFee =  objReceiptAcknowledgementService.createReceiptAcknowledgementObj(otherCharge.technology_fee, otherChargesMap.get(otherCharge.Id).SalesOrder__c, otherChargesMap.get(otherCharge.Id).SalesOrder__r.Unit__c, otherChargesMap.get(otherCharge.Id).SalesOrder__r.Account__c, otherChargesMap.get(otherCharge.Id).SalesOrder__r.Opportunity__c, SUPER_APP_STR, CLEARED_STR, true, 'Abu Dhabi Commercial Bank',paymentDetail.tran_ref);
                    raTechFee.Bank_Account__c = otherChargesMap.get(otherCharge.Id).SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__c;
                    raList.add(raTechFee);  
                    receiptAckMap.put(index, raTechFee);

                    SalesOrderOtherCharges__c otherCharges = objSalesOrderOtherChargesService.createSalesOrderOtherChargesObj(otherChargesMap.get(otherCharge.Id).SalesOrder__c,null, null,otherCharge.technology_fee,TECHNOLOGY_FEE_STR,null,null,null,Date.today());
                    otherCharges.InvoicedAmount__c = otherCharge.technology_fee;
                    otherCharges.SendtoSAP__c = true;
                    otherCharges.SAP_Condition_Type__c = otherChargesMap.get(otherCharge.Id).SalesOrder__r.Unit__r.Project__r.TechnologyFeeConditionType__c;
                    otherChargesList.add(otherCharges);
                    salesOrderOtherChargesMap.put(index, otherCharges);
                    ReceiptAllocation__c allocationTechFee = objReceiptAllocationService.createReceiptAllocationObj(otherCharge.technology_fee, null, null, otherChargesMap.get(otherCharge.Id).SalesOrder__c, otherChargesMap.get(otherCharge.Id).SalesOrder__r.Account__c);
                    allocationMap.put(index, allocationTechFee);
                }
            }
            //update the payment log as processed
            OnlinePaymentLog__c onlinePaymentLog = new OnlinePaymentLog__c(Id = paymentlog.Id,IsProcessed__c = true);
            processedPaymentLogList.add(onlinePaymentLog);
            //Send email to customer list
            Messaging.SingleEmailMessage objMail = objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(bloomAppPaymentConfirmationTempId, noReplyBloomSalesOWDId, null, paymentlog.Contact__c, null, null, null);
            emailList.add(objMail); 
        }
        if (!raList.isEmpty()) {
            objReceiptAcknowledgementService.insertReceiptAcknowledgements(raList);
        }
        if (!otherChargesList.isEmpty()) {
            objSalesOrderOtherChargesService.insertSalesOrderOtherCharges(otherChargesList);
        }

        for (Integer key : allocationMap.keySet()) {
            ReceiptAllocation__c alloc = allocationMap.get(key);
            ReceiptAcknowledgement__c ra = receiptAckMap.get(key);
            Id otherChargesId = salesOrderOtherChargesMap.containsKey(key) ?  salesOrderOtherChargesMap.get(key).Id : alloc.SalesOrderOtherCharges__c;
            alloc.ReceiptAcknowledgement__c = ra.Id;
            alloc.SalesOrderOtherCharges__c = otherChargesId;
            allocationList.add(alloc);
        }

        if (!allocationList.isEmpty()) {
            objReceiptAllocationService.insertReceiptAllocations(allocationList);
            for(ReceiptAcknowledgement__c ra : raList){
                ra.SendtoSAP__c = true;
            }
            objReceiptAcknowledgementService.updateReceiptAcknowledgements(raList);
        }
        
        
        if(!processedPaymentLogList.isEmpty()){
            objOnlinePaymentLogService.updateOnlinePaymentLog(processedPaymentLogList);
        }
        if(!emailList.isEmpty()){
            objEmailService.sendEmail(emailList);
        }
    }

    public class PaymentWrapper {
        public List<InstallmentWrapper> instalments;
        public List<OtherChargeWrapper> other_charges;
        public List<CommunityChargeWrapper> community_charges;
        public RevenueWrapper revenue;

        public Decimal amount;
        public Decimal technology_fee;
        public String transactionStatus;
        public String auth_code;
        public String payment_id;
        public String card_tail;
        public String mode;
        public String tran_ref;
    }

    public class InstallmentWrapper {
        public String id;
        public Decimal amount;
        public Decimal paid_amount;
        public Decimal technology_fee;
        public Decimal total_paid_amount;
        public String MID;
    }

    public class OtherChargeWrapper {
        public String id;
        public Decimal amount;
        public Decimal paid_amount;
        public Decimal technology_fee;
        public Decimal total_paid_amount;
        public String MID;
    }

    public class CommunityChargeWrapper {
        
    }

    public class RevenueWrapper {
        public String MID;
        public Decimal amount;
    }
}