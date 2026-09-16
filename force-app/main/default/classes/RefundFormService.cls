/*****************************************************************************************
Class       : RefundFormService
Author      : Kalpana
Description : Service Class for Generate Refund Form Requiremenet.
Created Date: 20/07/26
*****************************************************************************************/
public with sharing class RefundFormService {
    
    
    public static RefundFormWrapper getRefundForm(
        Id leasingOrderId,
        String notes,
        Date waterElectricityDate,
        Date maintenanceCheckoutDate
    ){
        
        if(leasingOrderId == null){
            throw new AuraHandledException('Leasing Order Id is required.');
        }
        
        LeasingOrder__c order = [
            SELECT  Id,
            Name,
            OwnerId,
            Owner.Name,
            Project__r.Name,
            Project__r.Leasing_Company__r.Name,
            SAPCompanyCode__c,
            Unit__r.Name,
            Unit__r.UnitType__c,
            Account__r.Name,
            LeasingSAPContractId__c,
            TotalAnnualRentwithVAT__c,
            LeasingStartDate__c,
            LeasingEndDate__c,
            TerminationDate__c,
            SecurityDeposit__c,
            MasterLeasingOrder__c
            FROM LeasingOrder__c
            WHERE Id=:leasingOrderId
        ];
        
        List<LeasingOrdersOtherCharges__c> otherCharges = [
            
            SELECT Id,
            Type__c,
            TotalAmount__c
            
            FROM LeasingOrdersOtherCharges__c
            
            WHERE LeasingOrder__c=:leasingOrderId
            
        ];
        
        List<LeasingReceiptAcknowledgment__c> receipts = [
            
            SELECT Id,
            ChequeNumber__c,
            ChequeDate__c,
            Amount__c
            
            FROM LeasingReceiptAcknowledgment__c
            
            WHERE LeasingOrder__c=:leasingOrderId
            
            ORDER BY ChequeDate__c
            
        ];
        
        RefundFormWrapper wrapper = new RefundFormWrapper();
        
        populateHeader(
            wrapper,
            order,
            notes,
            waterElectricityDate,
            maintenanceCheckoutDate
        );
        
        populateCalculations(
            wrapper,
            order,
            otherCharges,
            receipts
        );
        
        populatePDC(
            wrapper,
            receipts,
            order.TerminationDate__c
        );
        
        populateAttachments(
            wrapper,
            leasingOrderId
        );
        
        return wrapper;
        
    }
    
    private static void populateHeader(
        
        RefundFormWrapper wrapper,
        
        LeasingOrder__c order,
        
        String notes,
        
        Date waterDate,
        
        Date maintenanceDate
        
    ){
        
        wrapper.todayDate = System.today();
        
        wrapper.leasingCompanyName =
            order.Project__r != null &&
            order.Project__r.Leasing_Company__r != null
            ? order.Project__r.Leasing_Company__r.Name
            : '';
        
        wrapper.propertyName = order.Project__r != null ? order.Project__r.Name : '';
        wrapper.unitType = order.Unit__r != null ? order.Unit__r.UnitType__c : '';
        wrapper.unitName = order.Unit__r != null ? order.Unit__r.Name : '';
        wrapper.tenantName = order.Account__r != null ? order.Account__r.Name : '';
        wrapper.preparedBy = order.Owner != null ? order.Owner.Name : '';
        
        wrapper.occupantName = '';
        
        wrapper.tenancyContractNo = order.LeasingSAPContractId__c;
        
        wrapper.sapCompanyCode = order.SAPCompanyCode__c;
        
        wrapper.annualRent = order.TotalAnnualRentwithVAT__c;
        
        wrapper.leasingStartDate = order.LeasingStartDate__c;
        
        wrapper.leasingEndDate = order.LeasingEndDate__c;
        
        wrapper.terminationDate = order.TerminationDate__c;
        
        wrapper.notes = notes;
        
        wrapper.waterElectricityDate = waterDate;
        
        wrapper.maintenanceCheckoutDate = maintenanceDate;
        
    }
    
    private static void populateCalculations(
        RefundFormWrapper wrapper,
        LeasingOrder__c order,
        List<LeasingOrdersOtherCharges__c> otherCharges,
        List<LeasingReceiptAcknowledgment__c> receipts
    ){
        
        wrapper.additionalDays =
            RefundCalculationService.calculateAdditionalDays(
                order.LeasingEndDate__c,
                order.TerminationDate__c
            );
        
        wrapper.valueOfDays =
            RefundCalculationService.calculateValueOfDays(
                order.TotalAnnualRentwithVAT__c,
                order.LeasingStartDate__c,
                order.LeasingEndDate__c,
                wrapper.additionalDays
            );
        
        wrapper.breakLeasePenalty =
            RefundCalculationService.calculateBreakLeaseCharges(
                otherCharges
            );
        
        wrapper.maintenanceCharges =
            RefundCalculationService.calculateMaintenanceCharges(
                otherCharges
            );
        wrapper.balancePayment = 0;
        wrapper.adminFees = 0;
        
        wrapper.securityDeposit =
            calculateSecurityDeposit(order);
        
        wrapper.totalPDCReturn =
            RefundCalculationService.calculatePDCTotal(
                receipts,
                order.TerminationDate__c
            );
        
        wrapper.dueAmount =
            RefundCalculationService.calculateDueAmount(
                wrapper.valueOfDays,
                wrapper.breakLeasePenalty,
                wrapper.balancePayment,
                wrapper.adminFees,
                wrapper.maintenanceCharges,
                wrapper.securityDeposit
            );
        
        wrapper.dueAmountAfterPOCAdj =
            RefundCalculationService.calculateDueAmountAfterPOCAdj(
                wrapper.dueAmount,
                wrapper.totalPDCReturn
            );
        
    }
    
    private static Decimal calculateSecurityDeposit(
        LeasingOrder__c order
    ){
        
        Id masterOrderId =
            order.MasterLeasingOrder__c == null
            ? order.Id
            : order.MasterLeasingOrder__c;
        
        Decimal total = 0;
        
        for(LeasingOrder__c leasingOrder : [
            
            SELECT SecurityDeposit__c
            
            FROM LeasingOrder__c
            
            WHERE Id=:masterOrderId
            OR MasterLeasingOrder__c=:masterOrderId
            
        ]){
            
            if(leasingOrder.SecurityDeposit__c!=null){
                
                total+=leasingOrder.SecurityDeposit__c;
                
            }
            
        }
        
        return total.setScale(2);
        
    }
    
    private static void populatePDC(
        
        RefundFormWrapper wrapper,
        
        List<LeasingReceiptAcknowledgment__c> receipts,
        
        Date terminationDate
        
    ){
        
        Integer serialNo=1;
        
        for(LeasingReceiptAcknowledgment__c receipt:receipts){
            
            if(receipt.ChequeDate__c==null){
                
                continue;
                
            }
            
            if(receipt.ChequeDate__c<=terminationDate){
                
                continue;
                
            }
            
            RefundFormWrapper.PDCRow row=
                new RefundFormWrapper.PDCRow();
            
            row.serialNo=serialNo++;
            
            row.chequeNo=receipt.ChequeNumber__c;
            
            row.dueDate=receipt.ChequeDate__c;
            
            row.amount=receipt.Amount__c;
            
            wrapper.pdcRows.add(row);
            
        }
        
    }
    
    private static void populateAttachments(
        RefundFormWrapper wrapper,
        Id leasingOrderId
    ) {
        
        List<Document__c> documents = [
            SELECT Document_Name__c, ContentDocumentId__c
            FROM Document__c
            WHERE LeasingOrder__c = :leasingOrderId
            AND Document_Name__c != null
        ];
        
        Set<String> uploadedDocuments = new Set<String>();
        
        for (Document__c doc : documents) {
            if (String.isNotBlank(doc.ContentDocumentId__c)) {
                uploadedDocuments.add(doc.Document_Name__c.trim().toLowerCase());
            }
        }
        
        wrapper.attachments.add(buildAttachment(
            'Last tenancy contract',
            uploadedDocuments.contains('last tenancy contract'),
            null
        ));
        
        wrapper.attachments.add(buildAttachment(
            'Water & Electricity Clearance Certificate',
            uploadedDocuments.contains('water & electricity clearance certificate'),
            wrapper.waterElectricityDate
        ));
        
        wrapper.attachments.add(buildAttachment(
            'Maintenance Checkout Report',
            uploadedDocuments.contains('maintenance checkout report'),
            wrapper.maintenanceCheckoutDate
        ));
        
        wrapper.attachments.add(buildAttachment(
            'Tenant Letter for Break Lease',
            uploadedDocuments.contains('tenant letter for break lease'),
            null
        ));
        
        wrapper.attachments.add(buildAttachment(
            'Break Lease Forms Signed by Tenant',
            uploadedDocuments.contains('break lease forms signed by tenant'),
            null
        ));
    }
    
    private static RefundFormWrapper.AttachmentRow buildAttachment(
        String documentName,
        Boolean available,
        Date documentDate
    ) {
        
        RefundFormWrapper.AttachmentRow row =
            new RefundFormWrapper.AttachmentRow();
        
        row.documentName = documentName;
        row.available = available;
        row.documentDate = documentDate;
        row.corNumber = '';
        row.corDate = null;
        
        return row;
    }
    
}