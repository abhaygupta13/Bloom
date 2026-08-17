/*
* @Author : Jayprakash Bharti
* @CreatedDate : 26th AUG 2024
* @Description : ReceiptAcknowledgement object trigger helper
*/
/*****************************************************************************************************
* Version       Author      	Date             Comment                                                                       
* 1.0           Jayprakash   	26AUG2024        
*****************************************************************************************************/
public without sharing class ReceiptAcknowledgementTriggerHelper {
    
    private static final string MTD_OWE_NO_REPLY_BLOOM_SALES_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    private static final string BOUNCE_CHEQUE_FEE_CC_EMAILS { get { return 'BounceChequeFeeCCEmails'; } }
    private static final string DOWNPAYMENT_BOUNCE_CHEQUE_FEE_CC_EMAILS { get { return 'DownpaymentBounceChequeFeeCCEmails'; } }
    private static final string MTD_CHEQUE_BOUNCE_EMAIL_TEMPLATE_ID { get { return 'ChequeBouncedETId'; } }
    private static final string MTD_CHEQUE_BOUNCE_POOR_QUALITY_EMAIL_TEMPLATE_ID { get { return 'ChequeBouncedPoorQualityETId'; } }
    private static final string MTD_CHEQUE_BOUNCE_SIGN_MISSING_EMAIL_TEMPLATE_ID { get { return 'ChequeBouncedSignMissingETId'; } }
    private static final Set<String> POOR_QUALITY_EMAIL_REASONS_SET = new Set<String>{'Poor Quality','Swift Confirmation Awaited'};
        private static final String CHEQUE_PRESENTED_BY_MISTAKE { get { return 'Cheque Presented by Mistake'; } }
    private static final String BOUNCED_CHEQUE { get { return 'Bounced Cheque'; } }
    private static final String SIGNATURE_MISSING { get { return 'Signature Missing'; } }
    private static final String REVERSED_STR { get { return 'Reversed'; } }
    private static final String CLEARED_STR { get { return 'Cleared'; } }
    private static final String RECEIVED_STR { get { return 'Received'; } }
    private static final String POST_HANDOVER_STR { get { return 'Post Handover'; } }
    private static final String INTEGRATION_TYPE_SALES_RECEIPT_INTEGRATION { get { return 'SALES_RECEIPT_INTEGRATION'; } }
    
    public static void updateInstallmentOtherCharges(Set<Id> receiptIds){
        Map<Id,InstallmentLines__c> installmentLineMap = new  Map<Id,InstallmentLines__c>();
        Map<Id,SalesOrderOtherCharges__c> otherChargesMap = new  Map<Id,SalesOrderOtherCharges__c>();
        Set<Id> installmentLines = new Set<Id>();
        Set<Id> otherCharges = new Set<Id>();
        Set<Id> ReceiptAcknowledgement = new Set<Id>();
        Map<Id,Decimal> recordInstallmentOtherChargeMap = new Map<Id,Decimal>();
        Map<Id,Decimal> installmentOtherSupportCost = new Map<Id,Decimal>();
        List<ReceiptAllocation__c> allocationRecordList1 = new List<ReceiptAllocation__c>();
        
        for(ReceiptAllocation__c receiptAllocation : [SELECT Id,InstallmentLine__c,SalesOrderOtherCharges__c,ReceiptAcknowledgement__c FROM ReceiptAllocation__c WHERE ReceiptAcknowledgement__c IN:receiptIds]){
            if(receiptAllocation.ReceiptAcknowledgement__c != null)
                ReceiptAcknowledgement.add(receiptAllocation.ReceiptAcknowledgement__c);
            if(receiptAllocation.InstallmentLine__c != null)
                installmentLines.add(receiptAllocation.InstallmentLine__c);
            if(receiptAllocation.SalesOrderOtherCharges__c != null)
                otherCharges.add(receiptAllocation.SalesOrderOtherCharges__c);
        }
        for(ReceiptAllocation__c receiptAllocation1 : [SELECT Id,ReceiptAcknowledgement__r.Status__c FROM ReceiptAllocation__c
                                                       WHERE ReceiptAcknowledgement__c IN: ReceiptAcknowledgement AND AmountApplied__c > 0 AND ReceiptAcknowledgement__r.Status__c =: REVERSED_STR ]){
                                                           if(receiptAllocation1.ReceiptAcknowledgement__r.Status__c == REVERSED_STR){ 
                                                               receiptAllocation1.AmountApplied__c = 0;
                                                               allocationRecordList1.add(receiptAllocation1);
                                                           }
                                                       }                                                  
        
        if(installmentLines!=null || otherCharges!=null){
            
            for(ReceiptAllocation__c receiptAllocationRec : [SELECT AmountApplied__c,SalesOrderOtherCharges__c,InstallmentLine__c,ReceiptAcknowledgement__r.Status__c,
                                                             Unapply__c FROM ReceiptAllocation__c WHERE (InstallmentLine__c IN:installmentLines OR SalesOrderOtherCharges__c IN:otherCharges) ORDER BY InstallmentLine__c,SalesOrderOtherCharges__c,ReceiptAcknowledgement__r.Status__c]){
                                                                 
                                                                 Id installmentLineId = (receiptAllocationRec.InstallmentLine__c!=null ? receiptAllocationRec.InstallmentLine__c : null );
                                                                 Id otherChargesId = (receiptAllocationRec.SalesOrderOtherCharges__c!=null ? receiptAllocationRec.SalesOrderOtherCharges__c : null ); 
                                                                 Decimal amount = ((!receiptAllocationRec.Unapply__c && receiptAllocationRec.ReceiptAcknowledgement__r.Status__c == CLEARED_STR)? receiptAllocationRec.AmountApplied__c :0);
                                                                 //  Decimal amountRecieved = ((!receiptAllocationRec.Unapply__c && receiptAllocationRec.ReceiptAcknowledgement__r.Status__c == RECEIVED_STR) ? receiptAllocationRec.AmountApplied__c :0);
                                                                 Decimal amountReceive; 
                                                                 If(!receiptAllocationRec.Unapply__c && receiptAllocationRec.ReceiptAcknowledgement__r.Status__c == REVERSED_STR ){
                                                                     amountReceive = 0;
                                                                 }else{
                                                                     amountReceive = receiptAllocationRec.AmountApplied__c;
                                                                 }
                                                                 Decimal amountRecieved = amountReceive;
                                                                 if(installmentLineId !=null && amount !=null){
                                                                     
                                                                     InstallmentLines__c installmentLineRec = new InstallmentLines__c();
                                                                     amount = amount + ((recordInstallmentOtherChargeMap!=null && recordInstallmentOtherChargeMap.containsKey(installmentLineId))? recordInstallmentOtherChargeMap.get(installmentLineId) : 0);
                                                                     amountRecieved = amountRecieved + ((installmentLineMap!=null && installmentLineMap.containsKey(installmentLineId))? installmentLineMap.get(installmentLineId).AmountReceived__c : 0);
                                                                     installmentLineRec.Id = installmentLineId ;
                                                                     installmentLineRec.ClearedAmount__c = amount ;
                                                                     installmentLineRec.AmountReceived__c = amountRecieved ;
                                                                     installmentLineMap.put(installmentLineId,installmentLineRec);
                                                                     recordInstallmentOtherChargeMap.put(installmentLineId,amount);
                                                                 }
                                                                 
                                                                 if(otherChargesId !=null && amount !=null){
                                                                     amount = amount + ((recordInstallmentOtherChargeMap!=null && recordInstallmentOtherChargeMap.containsKey(otherChargesId))? recordInstallmentOtherChargeMap.get(otherChargesId) : 0);
                                                                     SalesOrderOtherCharges__c otherChargeRec = new SalesOrderOtherCharges__c();
                                                                     amountRecieved = amountRecieved + ((otherChargesMap!=null && otherChargesMap.containsKey(otherChargesId))? otherChargesMap.get(otherChargesId).AmountReceived__c : 0);
                                                                     otherChargeRec.Id = otherChargesId ;
                                                                     otherChargeRec.InvoicedAmount__c = amount ;
                                                                     otherChargeRec.AmountReceived__c = amountRecieved ;
                                                                     otherChargesMap.put(otherChargesId,otherChargeRec);
                                                                     recordInstallmentOtherChargeMap.put(otherChargesId,amount);
                                                                 }
                                                             }
            //----- Update all the installment lines with the amount invoiced
            if(allocationRecordList1!= null || allocationRecordList1.size()>0){
                update allocationRecordList1;
            }
            //----- Update all the installment lines with the amount invoiced
            
            if(installmentLineMap!=null || installmentLineMap.size()>0){
                update installmentLineMap.values() ; 
            }
            //----- Update all the other charges with the amount invoiced
            
            if(otherChargesMap!=null || otherChargesMap.size()>0){
                update otherChargesMap.values() ; 
            }
            
        }
    }
    
    public static void unApplyReceiptsBeforeDelete(Map<Id,SObject> oldMap){
        //ReceiptAcknowledgement__c
        List<ReceiptAllocation__c> allocationRecordList = new List<ReceiptAllocation__c>();
        for(ReceiptAllocation__c allocationRecord : [SELECT Id FROM ReceiptAllocation__c
                                                     WHERE ReceiptAcknowledgement__c IN: oldMap.keySet()
                                                     AND AmountApplied__c > 0]){
                                                         allocationRecord.AmountApplied__c = 0;
                                                         allocationRecordList.add(allocationRecord);
                                                     }
        Update allocationRecordList;
    }
    
    //Send email notification and create record of Sales Order Other Charges when the cheque bounced
    public static void sendChequeBounceNotification(Map<Id,SObject> newMap,Map<Id,SObject> oldMap){
        Map<String, String> reasonMap = new Map<String, String>{
            'Cheque Presented by Mistake' => 'Cheque_Presented_by_Mistake',
                'Poor Quality' => 'Poor_Quality',
                'Irregular Signature' => 'Irregular_Signature',
                'Overwriting' => 'Overwriting',
                'Altered' => 'Altered',
                'Amount in words not matching with number' => 'Amount_in_words_not_matching_with_number',
                'Insufficient Fund' => 'Insufficient_Fund',
                'Closed Account' => 'Closed_Account',
                'Frozen Account' => 'Frozen_Account',
                'Swift Confirmation Awaited' => 'Swift_Confirmation_Awaited',
                'Signature Missing' => 'Signature_Missing'
                };
                    
                    ReceiptAcknowledgementService objReceiptAcknowledgementService = ReceiptAcknowledgementService.getInstance();
        ProjectService objProjectService = ProjectService.getInstance();
        
        Set<Id> receiptAcknowledegementSet = new Set<Id>();
        MetadataService objMetadataService = MetadataService.getInstance();
        Id bloomNoReplySalesOWEId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_SALES_ID);
        String bounceChequeFeeCCEmails = objMetadataService.getAppSettingTextValue(BOUNCE_CHEQUE_FEE_CC_EMAILS);
        List<String> bounceChequeCCEmailAddressList = bounceChequeFeeCCEmails.split(',');
        String downpaymentBounceChequeFeeCCEmails = objMetadataService.getAppSettingTextValue(DOWNPAYMENT_BOUNCE_CHEQUE_FEE_CC_EMAILS);
        List<String> downpaymentBounceChequeCCEmailAddressList = downpaymentBounceChequeFeeCCEmails.split(',');
        Id chequeBounceETId = objMetadataService.getAppSettingTextValue(MTD_CHEQUE_BOUNCE_EMAIL_TEMPLATE_ID);
        Id ChequeBouncedPoorQualityETId = objMetadataService.getAppSettingTextValue(MTD_CHEQUE_BOUNCE_POOR_QUALITY_EMAIL_TEMPLATE_ID);
        Id ChequeBouncedSignMissingETId = objMetadataService.getAppSettingTextValue(MTD_CHEQUE_BOUNCE_SIGN_MISSING_EMAIL_TEMPLATE_ID);
        EmailService objEmailService = EmailService.getInstance();
        List<Messaging.SingleEmailMessage> msgList =new List<Messaging.SingleEmailMessage>();
        EmailTemplate chequeBounceET = objEmailService.getEmailTemplateById(chequeBounceETId);
        EmailTemplate ChequeBouncedPoorQualityET = objEmailService.getEmailTemplateById(ChequeBouncedPoorQualityETId);
        EmailTemplate ChequeBouncedSignMissingET = objEmailService.getEmailTemplateById(ChequeBouncedSignMissingETId);
        
        for(Id acknowledgementRecordId : newMap.keySet()){
            ReceiptAcknowledgement__c acknowledgementRecord = (ReceiptAcknowledgement__c)newMap.get(acknowledgementRecordId);
            ReceiptAcknowledgement__c oldAcknowledgementRecord = (ReceiptAcknowledgement__c)oldMap.get(acknowledgementRecordId);
            if(acknowledgementRecord.ReceiptReversalCategory__c == BOUNCED_CHEQUE && acknowledgementRecord.ReceiptReversalCategory__c != oldAcknowledgementRecord.ReceiptReversalCategory__c && acknowledgementRecord.Reason__c != CHEQUE_PRESENTED_BY_MISTAKE){
                receiptAcknowledegementSet.add(acknowledgementRecordId);
            }
        }
        
        if(!receiptAcknowledegementSet.isEmpty()){
            List<ReceiptAcknowledgement__c> receiptList = objReceiptAcknowledgementService.getReceiptAcknowledgementAndAllocationsByIds(receiptAcknowledegementSet);
            
            for(ReceiptAcknowledgement__c objRA : receiptList){
                String emailSubject = chequeBounceET.Subject;
                String emailBody = POOR_QUALITY_EMAIL_REASONS_SET.contains(objRA.Reason__c) ? ChequeBouncedPoorQualityET.HtmlValue : objRA.Reason__c == SIGNATURE_MISSING ? ChequeBouncedSignMissingET.HtmlValue : chequeBounceET.HtmlValue;
                emailSubject = emailSubject.replace('[Project_Name]', objRA.SalesOrder__r != null && objRA.SalesOrder__r.Unit__r != null && objRA.SalesOrder__r.Unit__r.Project__r != null ? objRA.SalesOrder__r.Unit__r.Project__r.Name : '');
                emailSubject = emailSubject.replace('[Project_Arabic]', objRA.SalesOrder__r != null && objRA.SalesOrder__r.Unit__r != null && objRA.SalesOrder__r.Unit__r.Project__r != null ? objRA.SalesOrder__r.Unit__r.Project__r.ProjectNameArabic__c : '');
                emailSubject = emailSubject.replace('[Unit_Name]', objRA.Unit__r != null ? objRA.Unit__r.Name : '');
                emailBody = emailBody.replace('[Customer_Name]', (objRA.Account__r != null && objRA.Account__r.Name != null ?  objRA.Account__r.Name : ''));
                emailBody = emailBody.replace('[Customer_NameArabic]', (objRA.Account__r != null && objRA.Account__r.NameinArabic__c != null ?  objRA.Account__r.NameinArabic__c : ''));
                emailBody = emailBody.replace('[Project_Name]', (objRA.SalesOrder__r != null && objRA.SalesOrder__r.Unit__r != null && objRA.SalesOrder__r.Unit__r.Project__r != null ?  objRA.SalesOrder__r.Unit__r.Project__r.Name : ''));
                emailBody = emailBody.replace('[Project_Arabic]', (objRA.SalesOrder__r != null && objRA.SalesOrder__r.Unit__r != null && objRA.SalesOrder__r.Unit__r.Project__r != null ?  objRA.SalesOrder__r.Unit__r.Project__r.ProjectNameArabic__c : ''));
                emailBody = emailBody.replace('[Unit_Name]', (objRA.Unit__r != null ?  objRA.Unit__r.Name : ''));
                emailBody = emailBody.replace('[Cheque_Number]', (String.valueOf(objRA.ReferenceNumber__c) != null ?  String.valueOf(objRA.ReferenceNumber__c) : ''));
                emailBody = emailBody.replace('[Date]', (String.valueOf(objRA.ActualReversalDate__c) != null ?  objRA.ActualReversalDate__c.format() : ''));
                emailBody = emailBody.replace('[Amount]', (String.valueOf(objRA.Amount__c) != null ?  String.valueOf(objRA.Amount__c) : ''));
                emailBody = emailBody.replace('[Reason]', (String.valueOf(objRA.Reason__c) != null ?  String.valueOf(objRA.Reason__c) : ''));
                emailBody = emailBody.replace('[Reason_Arabic]', (String.valueOf(objRA.Reason__c) != null && reasonMap.containsKey(objRA.Reason__c)?  objMetadataService.getAppSettingTextValue(reasonMap.get(objRA.Reason__c)) : ''));
                
                //fetch bank details
                BankAccount__c selectedBank = new BankAccount__c();
                BankAccount__c selectedBankBounceCheque = new BankAccount__c();
                Boolean isReceiptAccPostHandover = objRA.Bank_Account__r.Type__c == POST_HANDOVER_STR;
                selectedBank.BankNameCorporate__c = isReceiptAccPostHandover ? objRA.Bank_Account__r.BankNameCorporate__c : objRA.SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.BankNameCorporate__c;
                selectedBank.Name = isReceiptAccPostHandover ? objRA.Bank_Account__r.BeneficiaryNameCorporate__c : objRA.SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.BeneficiaryNameCorporate__c;
                selectedBank.AccountNumberCorporate__c = isReceiptAccPostHandover ? objRA.Bank_Account__r.AccountNumberCorporate__c : objRA.SalesOrder__r.Virtual_Bank_Account_Number__c;
                selectedBank.IBANNoCorporate__c = isReceiptAccPostHandover ? objRA.Bank_Account__r.IBANNoCorporate__c : objRA.SalesOrder__r.Virtual_Account_IBAN__c;
                selectedBank.SwiftCodeCorporate__c = isReceiptAccPostHandover ? objRA.Bank_Account__r.SwiftCodeCorporate__c : objRA.SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.SwiftCodeCorporate__c;
                // fetch Bounce cheque Bank details
                selectedBankBounceCheque.BankNameCorporate__c = objRA.SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__r.BankNameCorporate__c;
                selectedBankBounceCheque.Name = objRA.SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__r.BeneficiaryNameCorporate__c;
                selectedBankBounceCheque.AccountNumberCorporate__c = objRA.SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__r.AccountNumberCorporate__c;
                selectedBankBounceCheque.IBANNoCorporate__c = objRA.SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__r.IBANNoCorporate__c;
                selectedBankBounceCheque.SwiftCodeCorporate__c = objRA.SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__r.SwiftCodeCorporate__c;
                
                
                if(selectedBank != null){
                    emailBody = emailBody.replace('[BankName]', selectedBank.BankNameCorporate__c != null ? selectedBank.BankNameCorporate__c : '')
                        .replace('[BankAccountName]', selectedBank.Name != null ? selectedBank.Name : '')
                        .replace('[BankAccountNumber]', selectedBank.AccountNumberCorporate__c != null ? selectedBank.AccountNumberCorporate__c : '')
                        .replace('[BankAccountIBAN]', selectedBank.IBANNoCorporate__c != null ? selectedBank.IBANNoCorporate__c : '')
                        .replace('[BankSwiftCode]', selectedBank.SwiftCodeCorporate__c != null ? selectedBank.SwiftCodeCorporate__c : '');
                }
                if(selectedBankBounceCheque != null){
                    emailBody = emailBody.replace('[BankName2]', selectedBankBounceCheque.BankNameCorporate__c != null ? selectedBankBounceCheque.BankNameCorporate__c : '')
                        .replace('[BankAccountName2]', selectedBankBounceCheque.Name != null ? selectedBankBounceCheque.Name : '')
                        .replace('[BankAccountNumber2]', selectedBankBounceCheque.AccountNumberCorporate__c != null ? selectedBankBounceCheque.AccountNumberCorporate__c : '')
                        .replace('[BankAccountIBAN2]', selectedBankBounceCheque.IBANNoCorporate__c != null ? selectedBankBounceCheque.IBANNoCorporate__c : '')
                        .replace('[BankSwiftCode2]', selectedBankBounceCheque.SwiftCodeCorporate__c != null ? selectedBankBounceCheque.SwiftCodeCorporate__c : '');
                }
                
                if(objRA.Receipt_Allocations__r != NULL && !objRA.Receipt_Allocations__r.isEmpty()){
                    if(objRA.SalesOrder__r != NULL && objRA.SalesOrder__r.SalesManager__r != NULL && objRA.SalesOrder__r.SalesManager__r.Email != NULL){
                        downpaymentBounceChequeCCEmailAddressList.add(objRA.SalesOrder__r.SalesManager__r.Email);
                    }
                    msgList.add(objEmailService.getSingleEmailMessage(null,objRA.Account__c,(objRA.Account__r.isPersonAccount == true ?  objRA.Account__r.PersonContactId : objRA.Contact__c), emailSubject, emailBody, bloomNoReplySalesOWEId, downpaymentBounceChequeCCEmailAddressList, null)); 
                } else {
                    msgList.add(objEmailService.getSingleEmailMessage(null,objRA.Account__c,(objRA.Account__r.isPersonAccount == true ?  objRA.Account__r.PersonContactId : objRA.Contact__c), emailSubject, emailBody, bloomNoReplySalesOWEId, bounceChequeCCEmailAddressList, null)); 
                }
            }
            objEmailService.sendEmail(msgList);
        } 
    }
    
    public static void beforeUpdateAction(List<ReceiptAcknowledgement__c> newList, Map<Id, ReceiptAcknowledgement__c> oldMap){
        for(ReceiptAcknowledgement__c ra : newList){
            // update cheque bounced to true
            if(ra.ReceiptReversalCategory__c != null && ra.ReceiptReversalCategory__c == 'Bounced Cheque' && ra.ReceiptReversalCategory__c != oldMap.get(ra.Id).ReceiptReversalCategory__c){
                ra.ChequeBouncedDate__c = Date.today();
            }
            
            if(ra.Finance_Verified__c && !oldMap.get(ra.Id).Finance_Verified__c && ra.ReceiptPostingDate__c <= System.today()){
                ra.SendtoSAP__c = true;
            }
            
            if(ra.Finance_Verified__c && ra.SAP_Document_No__c != null && ra.TotalAppliedAmount__c != oldMap.get(ra.Id).TotalAppliedAmount__c && ra.ReceiptPostingDate__c <= System.today()){
                ra.SendtoSAP__c = true;
            }
            
            if(ra.SendtoSAP__c && !oldMap.get(ra.Id).SendtoSAP__c){
                ra.IntegrationStatus__c = 'In Progress';
                ra.IntegrationMessage__c = '';
            }
            if((ra.SAPReversalDocumentNumber__c != oldMap.get(ra.Id).SAPReversalDocumentNumber__c && String.isNotBlank(ra.SAPReversalDocumentNumber__c)) ||
               (ra.ReversalApprovalStatus__c != oldMap.get(ra.Id).ReversalApprovalStatus__c && ra.ReversalApprovalStatus__c == 'Approved' && String.isBlank(ra.SAP_Document_No__c))){
                   ra.Status__c = REVERSED_STR;
               }
            if(ra.SAP_Condition_Type__c == 'P125' || ra.SAP_Condition_Type__c == 'P132'){
                ra.SAP_Special_GL_Indicator__c = 'V';
            }
        }
    }
    
    public static void handleAfterUpdate(List<ReceiptAcknowledgement__c> newList, Map<Id, ReceiptAcknowledgement__c> oldMap){
        ReceiptAllocationService objReceiptAllocationService = ReceiptAllocationService.getInstance();
        Set<Id> receiptAckUpdateActionIds = new Set<Id>();
        Set<Id> receiptAckInsertActionIds = new Set<Id>();
        Set<Id> receiptAckIds = new Set<Id>();
        for(ReceiptAcknowledgement__c ra : newList){
            if(ra.SendtoSAP__c == true && !oldMap.get(ra.Id).SendtoSAP__c){
                if(ra.ReversalApprovalStatus__c == 'Approved'){
                    if(String.isNotBlank(ra.SAP_Document_No__c)){
                        receiptAckUpdateActionIds.add(ra.Id);
                    }
                }
                else if(String.isNotBlank(ra.SAP_Document_No__c) && ra.TotalAppliedAmount__c != oldMap.get(ra.Id).TotalAppliedAmount__c){
                    receiptAckUpdateActionIds.add(ra.Id);
                }
                else if(ra.Finance_Verified__c == true){
                    receiptAckInsertActionIds.add(ra.Id);
                }
                if(ra.Finance_Verified__c == true && ra.Status__c != 'Reversed'){
                    receiptAckIds.add(ra.Id);
                }
            }
        }
        
        if(!receiptAckIds.isEmpty()){
            InstallmentLineService objInstallmentLineService = InstallmentLineService.getInstance();
            List<ReceiptAllocation__c> receiptAllocationList = objReceiptAllocationService.getReceiptAllocationsByReceiptIds(receiptAckIds);
            List<SalesOrderOtherCharges__c> salesOrderOtherChargesList = new List<SalesOrderOtherCharges__c>();
            Set<Id> installmentIds = new Set<Id>();
            
            for(ReceiptAllocation__c objReceiptAllocation :receiptAllocationList){
                if(objReceiptAllocation.InstallmentLine__c != NULL && objReceiptAllocation.InstallmentLine__r.SAP_Document_No__c == NULL){
                    installmentIds.add(objReceiptAllocation.InstallmentLine__c);
                }else if(objReceiptAllocation.SalesOrderOtherCharges__c != NULL && objReceiptAllocation.SalesOrderOtherCharges__r.SAP_Document_No__c == NULL){
                    salesOrderOtherChargesList.add(new SalesOrderOtherCharges__c(Id = objReceiptAllocation.SalesOrderOtherCharges__c, SendtoSAP__c = true));
                }
            }
            SalesOrderOtherChargesService.getInstance().updateOtherCharges(salesOrderOtherChargesList);
            
            if(!installmentIds.isEmpty()){
                IntegrationRecordService objIntegrationRecordService = IntegrationRecordService.getInstance();
                List<IntegrationRecord__c> objIntegrationRecordList = objInstallmentLineService.getInstallmentPostingIntegrationRecords(installmentIds);
                objIntegrationRecordService.insertIntegrationRecords(objIntegrationRecordList);
            }
        }
        
        if(!receiptAckInsertActionIds.isEmpty()){
            //Send to SAP Insert Action
            createReceiptAckIntegrationRecord('Insert', receiptAckInsertActionIds);
        }
        
        if(!receiptAckUpdateActionIds.isEmpty()){
            //Send to SAP Update Action              
            createReceiptAckIntegrationRecord('Update', receiptAckUpdateActionIds);
        }
    }
    
    public static void sendSOCToSap(Set<Id> socIds){
        SalesOrderOtherChargesService salesOrderOtherChargeService = SalesOrderOtherChargesService.getInstance();
        List<SalesOrderOtherCharges__c> listSalesOrderOtherCharge = salesOrderOtherChargeService.getSalesOrderOtherChargesByIds(socIds); 
        if(!listSalesOrderOtherCharge.isEmpty()){
            for(SalesOrderOtherCharges__c objSOC : listSalesOrderOtherCharge){
                if(objSOC.ReversalCategory__c == 'Reversal of LPF paid'){
                    objSOC.SendtoSAP__c = true;
                    objSOC.Due_Date__c = Date.today();
                }
            }
            salesOrderOtherChargeService.updateOtherCharges(listSalesOrderOtherCharge);
        }
    }
    
    public static void createReceiptAckIntegrationRecord(String action, Set<Id> ReceiptAckUpdateActionIds){
        ReceiptAcknowledgementService objReceiptAcknowledgementService = ReceiptAcknowledgementService.getInstance();
        IntegrationRecordService objIntegrationRecordService = IntegrationRecordService.getInstance();
        List<ReceiptAcknowledgement__c> receiptAckList = objReceiptAcknowledgementService.getReceiptAcknowledgementByIds(ReceiptAckUpdateActionIds);
        List<IntegrationRecord__c> objIntegrationRecordList = new List<IntegrationRecord__c>();
        for(ReceiptAcknowledgement__c receiptAck :receiptAckList){
            objIntegrationRecordList.add(objReceiptAcknowledgementService.getReceiptAckIntegrationRecord(action, receiptAck));
        }
        objIntegrationRecordService.insertIntegrationRecords(objIntegrationRecordList);
    }
    
    public static void beforeInsertAction(List<ReceiptAcknowledgement__c> newList){
        for(ReceiptAcknowledgement__c ra : newList){
            if(ra.Finance_Verified__c && ra.ReceiptPostingDate__c <= System.today()){
                ra.SendtoSAP__c = true;
                ra.IntegrationStatus__c = 'In Progress';
                ra.IntegrationMessage__c = '';
            }
        }
    }
    
    public static void afterInsertAction(List<ReceiptAcknowledgement__c> newList){
        Set<Id> receiptAckIds = new Set<Id>();
        for(ReceiptAcknowledgement__c ra : newList){
            if(ra.SendtoSAP__c){
                receiptAckIds.add(ra.Id);
            }
        }
        if(!receiptAckIds.isEmpty()){
            createReceiptAckIntegrationRecord('Insert', receiptAckIds);
        }
    }
}