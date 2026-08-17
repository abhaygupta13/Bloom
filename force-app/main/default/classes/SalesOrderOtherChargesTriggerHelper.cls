/*****************************************************************************************
Class       : SalesOrderOtherChargesTriggerHelper
Author      : Vikas Baliyan
Description : SalesOrderOtherChargesTriggerHelper
Test Class  : 
Created Date: 14 MAY 2025 
*****************************************************************************************/
public without sharing class SalesOrderOtherChargesTriggerHelper {
    
    private static final string INSERT_STR { get { return 'Insert'; } }
    private static final string UPDATE_STR { get { return 'Update'; } }
    private static final string SALES_ORDER_OTHER_CHARGES_STR { get { return 'Sales Order Other Charges'; } }
    private static final string CHEQUE_BOUNCE_FEE_STR { get { return 'Cheque Bounce Fee'; } }
    
    private static final Map<String, String> CHARGE_VS_CONDITION_TYPE = new Map<String, String>{
        'Recovery Fee' => 'RecoveryFeeCondType__c',
            'Pending Fee' => 'PendingFeeCondType__c',
            'Cheque Bounce Fee' => 'ChequeBounceFeeCondType__c',
            'Late Payment Charges' => 'LatePaymentChargesCondType__c',
            //'Cheque with Withdrawal Fee' => 'ChequeWithWithdrawalFeeCondType__c',
            'ADM Admin Fee' => 'ADMAdminFeeCondType__c',
            'Evaluation Fees' => 'EvaluationFeesCondType__c',
            'Mortgage Fees' => 'MortgageFeesCondType__c',
            'Hassantuk Fee' => 'HassantukFeeCondType__c',
            'Cheque Postponement Fee'  =>  'ChequePostponementFeeCondType__c',
            'Property Enrollment Under Tawtheeq' => 'PropertyEnrollmentUnderTawtheeqCondType__c',
            'Cheque Withdrawal Fee' => 'ChequeWithdrawalFeeCondType__c',
            'Resale Admin fee' => 'ResaleAdminFeeCondType__c',
            'Dari Title Deed Fee' => 'DariTitleDeedFeeCondType__c',
            'ADDC' => 'ADDCConditionType__c',
            'Merged Paid Installment' => 'MergedPaidInstallmentConditionType__c',
            'Rebate' => 'RebateConditionType__c',
            'Additional ADM Fee' => 'AdditionalADMFeeConditionType__c',
            'UAE Pass Fee' => 'UAEPassFeeConditionType__c',
            'ADM Fee' => 'ADMFeeCondType__c',
            'Admin Charges' => 'AdminChargesCondType__c',
            'Unit Cancellation Fees' => 'UnitCancellationFeesCondType__c',
            'Modification Advance Fee' => 'ModificationAdvanceFeeCondType__c',
            'Tamm Fee'=>'TammFeeConditionType__c',
            'Resale Renewal Fees'=>'ResaleRenewalFeesCondType__c'
            };
                
                private static final List<String> VAT_APPLICABLE_CHARGE_TYPES = new List<String>{
                    'Resale Admin Fee',
                        'Cheque Bounce Fee',
                        'Cheque Withdrawal Fee',
                        'Cheque with Withdrawal Fee',
                        'Cheque Postponement Fee',
                        'Admin Charges'
                        };
                            
                            public static void handleBeforeInsert(List<SalesOrderOtherCharges__c> newList){
                                Set<Id> orderIds = new Set<Id>();
                                for(SalesOrderOtherCharges__c otherCharges : newList){
                                    if(otherCharges.SendtoSAP__c){
                                        otherCharges.IntegrationStatus__c = 'In Progress';
                                        otherCharges.IntegrationMessage__c = '';
                                    }
                                    if(otherCharges.SalesOrder__c!=null){
                                        orderIds.add(otherCharges.SalesOrder__c);
                                    }
                                    if(VAT_APPLICABLE_CHARGE_TYPES.contains(otherCharges.TypeOfCharge__c)){
                                        otherCharges.IsVATApplicable__c = true;
                                    }
                                }
                                populateConditionType(newList,orderIds);    
                            }
    
    public static void populateConditionType(List<SalesOrderOtherCharges__c> newList, Set<Id> orderIds) {
        Map<Id, SalesOrder__c> orderMap = new Map<Id, SalesOrder__c>(
            SalesOrderService.getInstance().getSalesOrdersByIds(orderIds)
        );
        
        for (SalesOrderOtherCharges__c charge : newList) {
            String condTypeField = CHARGE_VS_CONDITION_TYPE.get(charge.TypeOfCharge__c);
            SalesOrder__c order = orderMap.get(charge.SalesOrder__c);
            if (!String.isEmpty(condTypeField)) {
                if (order != null && order.Unit__c != null && order.Unit__r.Project__c != null) {
                    charge.SAP_Condition_Type__c = String.valueOf(order.Unit__r.Project__r.get(condTypeField));
                }
            }
            if(order != null && order.Account__c != null && charge.Account__c == null){
                charge.Account__c = order.Account__c;
            }
            if(charge.TypeOfCharge__c == 'Cheque Bounce Fee'){
                charge.IsVATApplicable__c = order.Unit__r.Project__r.BounceChequeFeeVATApplicable__c;
            }
        }
    }
    
    public static void handleAfterInsert(List<SalesOrderOtherCharges__c> newList){
        IntegrationRecordService objIntegrationRecordService = IntegrationRecordService.getInstance();
        SalesOrderOtherChargesService objSalesOrderOtherChargesService = SalesOrderOtherChargesService.getInstance();
        List<IntegrationRecord__c> objIntegrationRecordList = new List<IntegrationRecord__c>();
        Set<Id> otherChargesIds = new Set<Id>();
        for(SalesOrderOtherCharges__c otherCharge : newList){
            if(otherCharge.TypeOfCharge__c != 'Late Payment Charges'){
                otherChargesIds.add(otherCharge.Id);
            }
        }
        if(!otherChargesIds.isEmpty()){
            List<SalesOrderOtherCharges__c> otherChargesList = objSalesOrderOtherChargesService.getSalesOrderOtherChargesByIds(otherChargesIds);
            for(SalesOrderOtherCharges__c objOtherCharges : otherChargesList){
                objIntegrationRecordList.add(objSalesOrderOtherChargesService.createOtherChargeIntegrationRecord(objOtherCharges, INSERT_STR));
            }
            objIntegrationRecordService.insertIntegrationRecords(objIntegrationRecordList);
        }
    }
    
    public static void handleBeforeUpdate(List<SalesOrderOtherCharges__c> newList, Map<Id, SalesOrderOtherCharges__c> oldMap){
        for(SalesOrderOtherCharges__c otherCharges : newList){
            if(otherCharges.SendtoSAP__c && !oldMap.get(otherCharges.Id).SendtoSAP__c && otherCharges.TypeOfCharge__c == 'Late Payment Charges' && otherCharges.IsReversed__c == true && String.isBlank(otherCharges.SAP_Document_No__c)){
                otherCharges.SendtoSAP__c = false;
            }
            if(otherCharges.SendtoSAP__c && !oldMap.get(otherCharges.Id).SendtoSAP__c){
                otherCharges.IntegrationStatus__c = 'In Progress';
                otherCharges.IntegrationMessage__c = '';
            }
            if(otherCharges.TypeOfCharge__c == 'Late Payment Charges' && otherCharges.WaivedAmount__c != null && (otherCharges.WaivedAmount__c != oldMap.get(otherCharges.Id).WaivedAmount__c || otherCharges.Amount__c != oldMap.get(otherCharges.Id).Amount__c)){
                otherCharges.Amount__c = otherCharges.Amount__c - otherCharges.WaivedAmount__c;
            }
            if(VAT_APPLICABLE_CHARGE_TYPES.contains(otherCharges.TypeOfCharge__c)){
                otherCharges.IsVATApplicable__c = true;
            }
        }
    }
    
    public static void handleAfterUpdate(List<SalesOrderOtherCharges__c> newList, Map<Id, SalesOrderOtherCharges__c> oldMap){
        // Sales order other charges id set
        Set<Id> otherChargesIds = new Set<Id>();
        Set<Id> otherChargesDocIds = new Set<Id>();
        SalesOrderOtherChargesService objSalesOrderOtherChargesService = SalesOrderOtherChargesService.getInstance();
        
        for(SalesOrderOtherCharges__c otherCharges : newList){
            if(!oldMap.get(otherCharges.Id).SendtoSAP__c && otherCharges.SendtoSAP__c){
                otherChargesIds.add(otherCharges.Id);
            }
            if(oldMap.get(otherCharges.Id).SAP_Document_No__c != NULL && oldMap.get(otherCharges.Id).SAP_Document_No__c != otherCharges.SAP_Document_No__c && oldMap.get(otherCharges.Id).SAP_Document_No__c == NULL){
                otherChargesDocIds.add(otherCharges.Id);
            }
        }
        if(!otherChargesIds.isEmpty()){
            IntegrationRecordService objIntegrationRecordService = IntegrationRecordService.getInstance();
            List<IntegrationRecord__c> objIntegrationRecordList = new List<IntegrationRecord__c>();
            List<SalesOrderOtherCharges__c> otherChargesList = objSalesOrderOtherChargesService.getSalesOrderOtherChargesByIds(otherChargesIds);
            for(SalesOrderOtherCharges__c objOtherCharges :otherChargesList){
                String action = (objOtherCharges.SAP_Document_No__c != NULL) ? UPDATE_STR : INSERT_STR;
                objIntegrationRecordList.add(objSalesOrderOtherChargesService.createOtherChargeIntegrationRecord(objOtherCharges, action));   
            }
            objIntegrationRecordService.insertIntegrationRecords(objIntegrationRecordList);
        }
        if(!otherChargesDocIds.isEmpty()){
            ReceiptAllocationService objReceiptAllocationService = ReceiptAllocationService.getInstance();
            ReceiptAcknowledgementService objReceiptAcknowledgementService = ReceiptAcknowledgementService.getInstance();
            List<ReceiptAllocation__c> objReceiptAllocationList = objReceiptAllocationService.getReceiptAllocationByOtherChargeIds(otherChargesDocIds);
            
            Map<Id,ReceiptAcknowledgement__c> objReceiptAcknowledgementMap = new Map<Id,ReceiptAcknowledgement__c>();
            for(ReceiptAllocation__c objReceiptAllocation :objReceiptAllocationList){
                objReceiptAcknowledgementMap.put(objReceiptAllocation.ReceiptAcknowledgement__c, new ReceiptAcknowledgement__c(Id = objReceiptAllocation.ReceiptAcknowledgement__c, SendtoSAP__c = true));
            }
            objReceiptAcknowledgementService.updateReceiptAcknowledgements(objReceiptAcknowledgementMap.values());
        }     
    }
}