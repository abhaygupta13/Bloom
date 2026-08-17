public with sharing class LeasingReceiptController {

    @AuraEnabled(cacheable=true)
    public static ReceiptWrapper loadData(Id leasingOrderId){

        ReceiptWrapper wrap = new ReceiptWrapper();

LeasingOrder__c orderRec = [
    SELECT Id,
       LeasingSAPContractId__c,
       LeasingStartDate__c,
       Project__c,
       Project__r.Name,
       Project__r.LeasingBankAccount__c,
       Project__r.LeasingBankAccount__r.Name,
       Project__r.LeasingBankAccount__r.AccountNumberCorporate__c,
       Unit__c,
       Unit__r.Name,
       Account__r.Name
FROM LeasingOrder__c
WHERE Id = :leasingOrderId
];

wrap.projectId = orderRec.Project__c;
wrap.projectName = orderRec.Project__r.Name;
wrap.unitName = orderRec.Unit__r.Name;
wrap.bankAccount = orderRec.Project__r.LeasingBankAccount__c;
wrap.accountName = orderRec.Account__r.Name;
if(orderRec.Project__r.LeasingBankAccount__c != null){
    wrap.bankAccountName = orderRec.Project__r.LeasingBankAccount__r.Name;
    wrap.bankAccountNumber = orderRec.Project__r.LeasingBankAccount__r.AccountNumberCorporate__c;
}
wrap.sapContract = orderRec.LeasingSAPContractId__c;
wrap.leasingStartDate = orderRec.LeasingStartDate__c;
        wrap.rows = new List<AllocationRow>();

        for(PaymentPlanSchedule__c rec :
            [SELECT Id, Name, DueDate__c,
                    TotalInstallmentAmount__c,
                    ClearedAmount__c,
       PaymentStatus__c
             FROM PaymentPlanSchedule__c
             WHERE LeasingOrder__c =: leasingOrderId
             AND PaymentStatus__c IN ('Un Paid', 'Not Invoiced')]){

            AllocationRow row = new AllocationRow();

            row.recordId = rec.Id;
            row.name = rec.Name;
            row.paymentStatus = rec.PaymentStatus__c;
            row.dueDate = rec.DueDate__c;
            row.totalAmount = rec.TotalInstallmentAmount__c;
            row.paidAmount = rec.ClearedAmount__c;
            row.type = 'schedule';
            row.subType = null; //added 4/10/26

            wrap.rows.add(row);
        }

        for(LeasingOrdersOtherCharges__c rec :
            [SELECT Id, Name, DueDate__c,
                    TotalAmount__c,
                    ClearedAmount__c,
                    type__c, //added 4/10/26
       PaymentStatus__c
             FROM LeasingOrdersOtherCharges__c
             WHERE LeasingOrder__c =: leasingOrderId
             AND PaymentStatus__c IN ('Un Paid', 'Not Invoiced')]){

            AllocationRow row = new AllocationRow();

            row.recordId = rec.Id;
            row.name = rec.Name;
            row.paymentStatus = rec.PaymentStatus__c;
            row.dueDate = rec.DueDate__c;
            row.totalAmount = rec.TotalAmount__c;
            row.paidAmount = rec.ClearedAmount__c;
            row.type = 'charge';
            row.subType = rec.type__c; //added 4/10/26

            wrap.rows.add(row);
        }

        return wrap;
    }

@AuraEnabled
public static void saveReceipt(
    Id leasingOrderId,
    LeasingReceiptAcknowledgment__c receipt,
    String rowsJson){
    try{
        List<LeasingReceiptAcknowledgment__c> existingReceiptAckList = LeasingReceiptAcknowledgementService.getDuplicateReceipt(receipt);
        
        if(existingReceiptAckList.size() > 0){
            AuraHandledException e = new AuraHandledException('Duplicate Receipt is not Allowed.');
            e.setMessage('Duplicate Receipt is not Allowed.');
            throw e;
        }

        insert receipt;

        List<AllocationRow> rows =
            (List<AllocationRow>)JSON.deserialize(rowsJson, List<AllocationRow>.class);

        if(rows == null || rows.isEmpty()){
            return;
        }

        List<LeasingReceiptAllocation__c> allocations = new List<LeasingReceiptAllocation__c>();

        for(AllocationRow r : rows){

            System.debug('Processing Row -> ' + JSON.serialize(r));

            if(r.appliedAmount != null){

                LeasingReceiptAllocation__c a = new LeasingReceiptAllocation__c();

                a.LeasingReceiptAcknowledgment__c = receipt.Id;
                a.LeasingOrder__c = leasingOrderId;
                a.AmountApplied__c = r.appliedAmount;

                if(r.type == 'schedule'){
                    a.PaymentPlanSchedule__c = r.recordId;
                }else{
                    a.LeasingOrderOtherCharges__c = r.recordId;
                }

                    allocations.add(a);
            }
        }

        System.debug('Allocations to Insert -> ' + allocations);
        if(!allocations.isEmpty()){
            insert allocations;
        }

    }catch(Exception e){
        System.debug('ERROR -> ' + e.getMessage());
        throw new AuraHandledException(e.getMessage());
    }
}

@AuraEnabled
public static void saveReceiptAllocation( Id leasingOrderId,
    Id receiptId,
    String rowsJson){

    try{
        List<LeasingReceiptAcknowledgment__c> receipts = [SELECT Id, UnappliedAmount__c FROM LeasingReceiptAcknowledgment__c WHERE Id = :receiptId];
        if(receipts.isEmpty()){
            AuraHandledException e = new AuraHandledException('Invalid receipt Id');
            e.setMessage('Invalid receipt Id');
            throw e;
        }
        List<AllocationRow> rows =
            (List<AllocationRow>)JSON.deserialize(rowsJson, List<AllocationRow>.class);

        if(rows == null || rows.isEmpty()){
            return;
        }
        Decimal appliedTotal = 0;

        List<LeasingReceiptAllocation__c> allocations = new List<LeasingReceiptAllocation__c>();

        for(AllocationRow r : rows){

            System.debug('Processing Row -> ' + JSON.serialize(r));

            if(r.apply != null && r.apply && r.appliedAmount != null){

                LeasingReceiptAllocation__c a = new LeasingReceiptAllocation__c();

                a.LeasingReceiptAcknowledgment__c = receiptId;
                a.LeasingOrder__c = leasingOrderId;
                a.AmountApplied__c = r.appliedAmount;

                if(r.type == 'schedule'){
                    a.PaymentPlanSchedule__c = r.recordId;
                }else{
                    a.LeasingOrderOtherCharges__c = r.recordId;
                }
                appliedTotal += r.appliedAmount;
                if(r.appliedAmount > 0)
                    allocations.add(a);
            }
        }

        Decimal unapplied = receipts[0].UnappliedAmount__c == null ? 0 : receipts[0].UnappliedAmount__c;

        if(appliedTotal > unapplied){
            AuraHandledException e = new AuraHandledException('Total applied amount exceeds receipt unapplied amount.');
            e.setMessage('Total applied amount exceeds receipt unapplied amount.');
            throw e;
        }
        if(!allocations.isEmpty()){
            insert allocations;
        }

    }catch(Exception e){
        System.debug('ERROR -> ' + e.getMessage());
        throw new AuraHandledException(e.getMessage());
    }
}

@AuraEnabled(cacheable=true)
    public static List<BankAccount__c> searchBankAccounts(String searchKey) {

        return [
            SELECT Id, Name, AccountNumberCorporate__c
            FROM BankAccount__c
            WHERE Name LIKE :('%' + searchKey + '%')
        ];
    }

    @AuraEnabled
    public static String createFinanceTask(String inputData){
        try{
            LeasingReceiptAcknowledgementDataWrapper data = (LeasingReceiptAcknowledgementDataWrapper) JSON.deserialize(
                    inputData,
                    LeasingReceiptAcknowledgementDataWrapper.class
                );

            Set<Id> ackIds = new Set<Id>{ data.receiptAcknowledgementId };

            List<LeasingReceiptAcknowledgment__c> receiptAckList = LeasingReceiptAcknowledgementService.getLeasingReceiptAcknowledgementByIds(ackIds);
            LeasingReceiptAcknowledgment__c receiptAck = receiptAckList[0];
            if(data.checkStatus == 'On Hold')
                receiptAck.OnHold__c = true;
            else if(data.checkStatus ==  'Withdrawal')
                receiptAck.Withdrawal__c = true;
            else{
                receiptAck.Replacement__c = true;
            }

            LeasingReceiptAcknowledgementService.getInstance().updateLeasingReceiptAcknowledgement(new List<LeasingReceiptAcknowledgment__c>{receiptAck});

            List<Task> receiptTasks = new List<Task>();

            Task financeTask = new Task();
            financeTask.Subject = Label.LRAUpdateChequeTaskSubject + ' ' + receiptAck.Name;
            financeTask.OwnerId = data.financeUser;
            financeTask.WhatId = receiptAck.Id;
            receiptTasks.add(financeTask);

            ActivityService activityService = ActivityService.getInstance();
            activityService.insertTasks(receiptTasks);

            return 'Success';

        } catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String handleFinanceFileUpload(
        String receiptAcknowledgementId,
        String fileName,
        String base64Data
    ){
        String documentName = 'Proof of payment';

        try{
            if (String.isBlank(receiptAcknowledgementId)) {
                throw new AuraHandledException('Receipt Acknowledgment Id is required.');
            }
            if (String.isBlank(fileName)) {
                throw new AuraHandledException('File name is required.');
            }
            if (String.isBlank(base64Data)) {
                throw new AuraHandledException('File data is required.');
            }

            DocumentService documentService = DocumentService.getInstance();
            Id documentId;

            List<Document__c> documentList =
                documentService.getRequiredLeasingReceiptAckDocument(
                    (Id)receiptAcknowledgementId,
                    documentName
                );

            if (!documentList.isEmpty()) {
                documentId = documentList[0].Id;
            } else {
                return '';
            }
            documentService.addFile(
                base64Data,
                fileName,
                documentId
            );

            return 'File uploaded successfully.';

        } catch(Exception ex){
            throw new AuraHandledException(
                'Error uploading file: ' + ex.getMessage()
            );
        }
    }

    /* =========================================================================
       INNER CLASSES
       ========================================================================= */

    /**
    * Wrapper class used by LWC for Finance Task creation.
    */
    public class LeasingReceiptAcknowledgementDataWrapper {
        @AuraEnabled public String receiptAcknowledgementId;
        @AuraEnabled public String financeUser;
        @AuraEnabled public String checkStatus;
    }

public class ReceiptWrapper{
    @AuraEnabled public Id projectId;
    @AuraEnabled public String projectName;
    @AuraEnabled public String unitName;
    @AuraEnabled public String bankAccount;
    @AuraEnabled public String bankAccountName;
    @AuraEnabled public String bankAccountNumber;
    @AuraEnabled public String sapContract;
    @AuraEnabled public List<AllocationRow> rows;
    @AuraEnabled public String accountName;
    @AuraEnabled public Date leasingStartDate;

}

    public class AllocationRow{
        @AuraEnabled public Id recordId;
        @AuraEnabled public String name;
        @AuraEnabled public Date dueDate;
        @AuraEnabled public Decimal totalAmount;
        @AuraEnabled public Decimal paidAmount;
        @AuraEnabled public Decimal appliedAmount;
        @AuraEnabled public Boolean apply;
        @AuraEnabled public String type;
        @AuraEnabled public String paymentStatus;
        @AuraEnabled public String subType; //added 4/10/26
    }
}