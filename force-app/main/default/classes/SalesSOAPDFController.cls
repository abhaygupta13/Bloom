/***
Class       : SalesSOAPDFController
    Author      : Dhanraj Poojary
    Description :
    TestClass   : SalesSOAPDFControllerTest
    ----------------------------------------------------------------------------------------------------------------
    -- History --
    ----------------------------------------------------------------------------------------------------------------
    Sr.No.  version    ¯          Date                Details
    1.          V1.0              20/11/25           Initial Version
     ****************************************************************************************************************/

public without sharing class SalesSOAPDFController {
    
    private static final string MTD_OTHER_CHARGES_EXCLUDED_TYPES { get { return 'SOAOtherChargesExcludedTypes'; } }
    public List<SalesOrderWrapper> salesOrderWrapperList { get; set; }
    public String propertyType { get; set; }
    public String totalBalanceInstallment { get; set; }
    
    public SalesSOAPDFController() {
        SalesOrderService objSalesOrderService = SalesOrderService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        String otherChargesExcludedTypes = objMetadataService.getAppSettingTextValue(MTD_OTHER_CHARGES_EXCLUDED_TYPES);
        List<String> otherChargesExcludedTypesList = String.isNotBlank(otherChargesExcludedTypes) ? otherChargesExcludedTypes.split(',') : new List<String>();
        salesOrderWrapperList = new List<SalesOrderWrapper>();
        
        Id soId = ApexPages.currentPage().getParameters().get('id');
        if (soId == null) return;
        
        Salesorder__c objSalesOrder = objSalesOrderService.getSalesOrderWithInstallmentAndReceiptAllocation(soId);
        if (objSalesOrder == null) return;
        
        List<Salesorder__c> lstSOAccount = objSalesOrderService.getAccountWithJointOwners(objSalesOrder.Id);
        
        List<String> customerNameList = new List<String>();
        
        if (lstSOAccount != null && !lstSOAccount.isEmpty()) {
            // Primary account holder name
            String primaryName = lstSOAccount[0].Account__r.Name;
            
            if (String.isNotBlank(primaryName)) {
                customerNameList.add(primaryName.trim());
            }
            
            // Joint owners
            if (lstSOAccount[0].Joint_OwnersSalesOrder__r != null) {
                for (JointOwner__c jo : lstSOAccount[0].Joint_OwnersSalesOrder__r) {
                    String jointName;
                    if (String.isNotBlank(jo.Account__r.Name)) {
                        jointName = (jo.Account__r.Name);
                    } 
                    if (String.isNotBlank(jointName)) {
                        customerNameList.add(jointName.trim());
                    }
                }
            }
        }
        
        String customerNamesFormatted = String.join(customerNameList, '<br/><br/>');
        
        propertyType = objSalesOrder.Tax_Percentage__c > 0 ? 'Commercial' : 'Residential';
        // Flags for ADM/Waiver logic
        Boolean admIncluded = Utility.getOrDefault(objSalesOrder.ADM_Fee_Included__c);
        Boolean hasWaiver = Utility.getOrDefault(objSalesOrder.ADM_Waiver__c) && objSalesOrder.ADMFeeWaivedAmount__c > 0;
        Boolean hasVAT = Utility.getOrDefault(objSalesOrder.Tax_Percentage__c) > 0;
        
        // Determine flags with mutual exclusivity
        Boolean isWaiver = hasWaiver && !admIncluded && !hasVAT;
        Boolean isADM = admIncluded && !hasWaiver && !hasVAT;
        Boolean isRegular = !hasWaiver && !admIncluded && !hasVAT;
        Boolean isVAT = hasVAT && !admIncluded && !hasWaiver && !isRegular;
        
        Decimal totalCollected = 0;
        Decimal totalOtherChargeCollected = 0;
        Decimal totalBalance = 0;
        Decimal totalDisplayedBalance = 0;
        Decimal admFee = 0;
        Map<String, Decimal> admMap = new Map<String, Decimal>();
        Map<String, Decimal> admClearedMap = new Map<String, Decimal>();
        Map<String, Decimal> admReceivedMap = new Map<String, Decimal>();
        String admReceiptReference = null;
        
        // Prepare installments map and allocated receipt tracking
        Map<Id, InstallmentLines__c> mapInstallment = new Map<Id, InstallmentLines__c>();
        Map<Id, Decimal> receivedAppliedByInstallment = new Map<Id, Decimal>();
        Set<Id> allocatedInstallmentIds = new Set<Id>();
        Map<Id, ConsolidatedInstallment> consMap = new Map<Id, ConsolidatedInstallment>();
        Map<String, ConsolidatedOtherCharge> consOtherChargeMap = new Map<String, ConsolidatedOtherCharge>();
        
        if (objSalesOrder.InstallmentLines__r != null) {
            for (InstallmentLines__c inst : objSalesOrder.InstallmentLines__r) {
                mapInstallment.put(inst.Id, inst);
            }
        }
        
        List<ReceiptAllocation__c> installmentReceipts = new List<ReceiptAllocation__c>();
        List<ReceiptAllocation__c> salesOrderReceipts = new List<ReceiptAllocation__c>();
        List<ReceiptAllocation__c> admFeeReceipts = new List<ReceiptAllocation__c>();
        Set<String> installmentReceiptReferences = new Set<String>();
        // Track refunds against ReceiptAcknowledgement
        Map<Id, Decimal> refundAmountByReceiptAcknowledgementId = new Map<Id, Decimal>();
        Map<Id, Decimal> refundAgainstCollectedByReceiptId = new Map<Id, Decimal>();
        
        // ---------------------------------------------------------
        // Build Refund Amount Map by ReceiptAcknowledgement
        // Refund should reduce Collected only when Receipt is linked
        // ---------------------------------------------------------
        List<ConsolidatedRefund> refundList = new List<ConsolidatedRefund>();
        Decimal totalRefund = 0;
        if (objSalesOrder.SalesOrderRefunds__r != null) {
            for (SalesOrderRefund__c rf : objSalesOrder.SalesOrderRefunds__r) {
                Decimal refundAmount = Utility.getOrDefault(rf.Amount__c);
                // Consolidated Refund row
                ConsolidatedRefund cr = new ConsolidatedRefund();
                cr.refundNo = rf.Name;
                cr.refundDate = rf.CreatedDate.date();
                cr.amount = refundAmount;
                cr.status = rf.Status__c;
                cr.remarks = rf.Remarks__c;
                cr.receiptNo = rf.Receipt__r != null ? rf.Receipt__r.Name : '';
                refundList.add(cr);
                totalRefund += refundAmount;
                // Only refunds linked to a ReceiptAcknowledgement
                // should reduce Collected.
                if (rf.Receipt__c != null && refundAmount > 0) {
                    Decimal existingRefund = refundAmountByReceiptAcknowledgementId.containsKey(rf.Receipt__c) ? refundAmountByReceiptAcknowledgementId.get(rf.Receipt__c) : 0;
                    refundAmountByReceiptAcknowledgementId.put(rf.Receipt__c,existingRefund + refundAmount);
                }
            }
        }
        
        ReceiptAcknowledgementService objRAService = ReceiptAcknowledgementService.getInstance();
        List<ReceiptAcknowledgement__c> specialGLReceipts  = objRAService.getSpecialGLReceipts(soId);
        
        // ---------------------------------------------------------
        // Determine which portion of each refund reduces Collected.
        // Refund should first consume the unapplied portion.
        // ---------------------------------------------------------
        for (ReceiptAcknowledgement__c ra : specialGLReceipts) {
            if (ra.Id == null || !refundAmountByReceiptAcknowledgementId.containsKey(ra.Id)) {
                continue;
            }
            Decimal receiptAmount = Utility.getOrDefault(ra.Amount__c);
            Decimal appliedAmount = Utility.getOrDefault(ra.AmountApplied__c);
            Decimal unappliedAmount = receiptAmount - appliedAmount;
            if (unappliedAmount < 0) {
                unappliedAmount = 0;
            }
            Decimal refundAmount = refundAmountByReceiptAcknowledgementId.get(ra.Id);
            // Refund first consumes unapplied amount.
            Decimal refundAgainstUnapplied = Math.min(refundAmount, unappliedAmount);
            // Only the excess refund reduces Collected.
            Decimal refundAgainstCollected = refundAmount - refundAgainstUnapplied;
            if (refundAgainstCollected > 0) {
                refundAgainstCollectedByReceiptId.put(ra.Id,refundAgainstCollected);
            }
        }
        
        if (objSalesOrder.ReceiptAllocations__r != null) {
            for (ReceiptAllocation__c r : objSalesOrder.ReceiptAllocations__r) {
                if (Utility.getOrDefault(r.AmountApplied__c) != 0) {
                    Decimal applied = Utility.getOrDefault(r.AmountApplied__c);
                    
                    Boolean isInstallmentReceipt = (r.InstallmentLine__c != null);
                    Boolean isOtherCharge = (r.SalesOrderOtherCharges__c != null);
                    
                    if (isInstallmentReceipt && r.ReceiptStatus__c == 'Received') {
                        Decimal existingReceived = receivedAppliedByInstallment.containsKey(r.InstallmentLine__c) ? receivedAppliedByInstallment.get(r.InstallmentLine__c) : 0;
                        receivedAppliedByInstallment.put(r.InstallmentLine__c,existingReceived + applied);
                    }
                    
                    // === Total Collected ===
                    if (r.ReceiptStatus__c == 'Cleared') {
                        Decimal collectedAmount = applied;
                        // Deduct refund linked to this ReceiptAcknowledgement
                        if (r.ReceiptAcknowledgement__c != null && refundAgainstCollectedByReceiptId.containsKey(r.ReceiptAcknowledgement__c)) {
                            Decimal refundAgainstCollected = refundAgainstCollectedByReceiptId.get(r.ReceiptAcknowledgement__c);
                            collectedAmount -= refundAgainstCollected;
                            if (collectedAmount < 0) {
                                collectedAmount = 0;
                            }
                        }
                        
                        // Normal installment receipt
                        if (isInstallmentReceipt && !isOtherCharge) {
                            totalCollected += collectedAmount;
                        }
                        
                        // ADM receipt merged into installment
                        else if (admIncluded && (r.InstallmentNumberOrChargeType__c == 'ADM Fee' || r.InstallmentNumberOrChargeType__c == 'ADM')) {
                            totalCollected += collectedAmount;
                        }
                        
                        // Other Charge receipt (non-ADM)
                        else if (isOtherCharge) {
                            totalOtherChargeCollected += collectedAmount;
                        }
                    }
                    else if (r.ReceiptStatus__c != 'Cleared' && isInstallmentReceipt && !isOtherCharge && (r.InstallmentLine__r == null || r.InstallmentLine__r.Due_Date__c == null || r.InstallmentLine__r.Due_Date__c <= Date.today())) {
                        //totalBalance += applied;
                    }
                    
                    if (r.InstallmentLine__c != null) {
                        allocatedInstallmentIds.add(r.InstallmentLine__c);
                        installmentReceipts.add(r);
                        if (r.Receipt_Reference__c != null)
                            installmentReceiptReferences.add(r.Receipt_Reference__c);
                    }
                    
                    // Sales Order Other Charges handling
                    if (r.SalesOrderOtherCharges__c != null) {
                        String otherChargeType = r.SalesOrderOtherCharges__r != null ? r.SalesOrderOtherCharges__r.TypeOfCharge__c : null;
                        // Exclude configured Other Charge types from SOA
                        if (otherChargeType != null && otherChargesExcludedTypesList.contains(otherChargeType.trim())) {
                            continue;
                        }
                        
                        Boolean isADMCharge = (r.InstallmentNumberOrChargeType__c == 'ADM Fee' || r.InstallmentNumberOrChargeType__c == 'ADM');
                        // === Track ADM receipts ===
                        if (admIncluded && isADMCharge) {
                            admFee += applied;
                            if (r.Receipt_Reference__c != null) {
                                admMap.put(r.Receipt_Reference__c, applied);
                                if (r.ReceiptStatus__c == 'Cleared') {
                                    admClearedMap.put(r.Receipt_Reference__c, applied);   // NEW
                                }
                                else if (r.ReceiptStatus__c == 'Received') {
                                    Decimal existingReceived = admReceivedMap.containsKey(r.Receipt_Reference__c) ? admReceivedMap.get(r.Receipt_Reference__c) : 0;
                                    admReceivedMap.put(r.Receipt_Reference__c,existingReceived + applied);
                                }
                                if (admReceiptReference == null) {
                                    admReceiptReference = r.Receipt_Reference__c;
                                }
                            }
                            admFeeReceipts.add(r);
                        }
                        else if(!admIncluded && isADMCharge){
                            admFee += applied;
                        }
                        
                        if (!admIncluded || !isADMCharge) {
                            // allow only non-ADM OR when ADM not included
                            salesOrderReceipts.add(r);
                        }
                        
                        if (!admIncluded || !isADMCharge) {
                            Id ocId = r.SalesOrderOtherCharges__c;
                            SalesOrderOtherCharges__c oc = r.SalesOrderOtherCharges__r;
                            
                            if (!consOtherChargeMap.containsKey(ocId)) {
                                ConsolidatedOtherCharge coc = new ConsolidatedOtherCharge();
                                coc.otherChargeId = ocId;
                                coc.chargeName = oc.Name;
                                coc.purpose = oc.TypeOfCharge__c;
                                coc.dueDate = oc.Due_Date__c;
                                coc.amount = Utility.getOrDefault(oc.Amount__c);
                                coc.applied = 0;
                                coc.pending = Utility.getOrDefault(oc.PendingAmount__c);
                                coc.rvDetails = new List<RVDetailOC>();
                                consOtherChargeMap.put(ocId, coc);
                            }
                            
                            ConsolidatedOtherCharge row = consOtherChargeMap.get(ocId);
                            
                            // RV-level data
                            RVDetailOC rv = new RVDetailOC();
                            rv.rvNo = r.Receipt_Reference__c;
                            rv.mode = r.Receipt_Type__c;
                            rv.status = r.ReceiptStatus__c;
                            rv.applied = Utility.getOrDefault(r.AmountApplied__c);
                            rv.pending = Utility.getOrDefault(oc.PendingAmount__c);
                            
                            // RV Date
                            Date rvDate = null;
                            rvDate = r.DateOfApplication__c != null ? r.DateOfApplication__c : (r.ReceiptAcknowledgement__c != null && r.ReceiptAcknowledgement__r.MaturityDate__c != null
                                ? r.ReceiptAcknowledgement__r.MaturityDate__c : null);
                            
                            rv.rvDate = rvDate;
                            rv.rvDateFormatted = Utility.formatDate(rvDate);
                            
                            // Add RV row
                            row.rvDetails.add(rv);
                            
                            // Summary update
                            row.applied += Utility.getOrDefault(r.AmountApplied__c);
                            
                        }
                    }
                    
                    if ((r.InstallmentNumberOrChargeType__c == 'ADM Fee' || r.InstallmentNumberOrChargeType__c == 'ADM') && r.SalesOrderOtherCharges__c == null) {
                        admFee += applied;
                        admFeeReceipts.add(r);
                        if (r.Receipt_Reference__c != null) admMap.put(r.Receipt_Reference__c, applied);
                    }
                }
            }
        }
        
        // Add LPF charges even if no Receipt Allocation exists
        if (objSalesOrder.SalesOrdersOtherCharges__r != null) {
            for (SalesOrderOtherCharges__c oc : objSalesOrder.SalesOrdersOtherCharges__r) {
                // Exclude configured Other Charge types from SOA
                if (oc.TypeOfCharge__c != null && otherChargesExcludedTypesList.contains(oc.TypeOfCharge__c.trim())) {
                    continue;
                }
                
                if (consOtherChargeMap.containsKey(oc.Id)) {
                    continue;
                }
                
                Boolean isADMCharge = (oc.TypeOfCharge__c == 'ADM Fee' || oc.TypeOfCharge__c == 'ADM');
                if (isADMCharge) {
                    continue;
                }
                
                ConsolidatedOtherCharge coc = new ConsolidatedOtherCharge();
                coc.otherChargeId = oc.Id;
                coc.chargeName    = oc.Name;
                coc.purpose       = oc.TypeOfCharge__c;
                coc.dueDate       = oc.Due_Date__c;
                coc.amount        = Utility.getOrDefault(oc.Amount__c);
                coc.applied       = 0;
                coc.pending       = Utility.getOrDefault(oc.PendingAmount__c);
                coc.rvDetails     = new List<RVDetailOC>();
                
                consOtherChargeMap.put(oc.Id, coc);
            }
        }
        
        // Handle additional ADM fee receipts not allocated to installments
        List<ReceiptAllocation__c> additionalAdmFeeList = new List<ReceiptAllocation__c>();
        if (admFeeReceipts.size() > 1) {
            for (ReceiptAllocation__c admReceipt : admFeeReceipts) {
                if (!installmentReceiptReferences.contains(admReceipt.Receipt_Reference__c)) {
                    additionalAdmFeeList.add(admReceipt);
                }
            }
        }
        
        // Clone additional ADM fee to first installment (if present)
        InstallmentLines__c firstInstallment = objSalesOrder.InstallmentLines__r != null && !objSalesOrder.InstallmentLines__r.isEmpty()
            ? objSalesOrder.InstallmentLines__r[0]
            : null;
        
        if (firstInstallment != null && additionalAdmFeeList.size() > 0) {
            for (ReceiptAllocation__c admReceipt : additionalAdmFeeList) {
                ReceiptAllocation__c cloneReceipt = admReceipt.clone(false, true, false, false);
                cloneReceipt.InstallmentLine__c = firstInstallment.Id;
                cloneReceipt.InstallmentLine__r = firstInstallment;
                installmentReceipts.add(cloneReceipt);
            }
        }
        
        // Add dummy receipts for unallocated installments and compute pending/partial logic
        Boolean isDeductADMFee = false;
        Decimal combinedOtherCharges = 0;
        
        for (Id instId : mapInstallment.keySet()) {
            InstallmentLines__c inst = mapInstallment.get(instId);
            Decimal pendingAmount = Utility.getOrDefault(inst.PendingAmount__c);
            Boolean isFutureInstallment = inst.Due_Date__c != null && inst.Due_Date__c > Date.today();
            
            if (!allocatedInstallmentIds.contains(instId)) {
                // No receipt allocated to the installment.
                ReceiptAllocation__c dummy = new ReceiptAllocation__c();
                dummy.InstallmentLine__c = inst.Id;
                dummy.InstallmentLine__r = inst;
                dummy.AmountApplied__c = pendingAmount;
                installmentReceipts.add(dummy);
                totalBalance += pendingAmount;
                if (!isFutureInstallment) {
                    totalDisplayedBalance += pendingAmount;
                }
            }else {
                Decimal receivedNotCleared = receivedAppliedByInstallment.containsKey(instId) ? receivedAppliedByInstallment.get(instId) : 0;
                Decimal outstandingForInst = pendingAmount + receivedNotCleared;
                
                if (outstandingForInst > 0) {
                    totalBalance += outstandingForInst;
                    isDeductADMFee = true;
                }
                if (!isFutureInstallment && outstandingForInst > 0) {
                    totalDisplayedBalance += outstandingForInst;
                }
            }
        }
        
        // NEW: ADM received-but-not-cleared adds to installment 1's outstanding total
        Decimal admReceivedGrandTotal = 0;
        for (Decimal v : admReceivedMap.values()) {
            admReceivedGrandTotal += v;
        }
        if (admIncluded && admReceivedGrandTotal > 0 && firstInstallment != null) {
            Boolean firstInstIsFuture = firstInstallment.Due_Date__c != null && firstInstallment.Due_Date__c > Date.today();
            totalBalance += admReceivedGrandTotal;
            if (!firstInstIsFuture) {
                totalDisplayedBalance += admReceivedGrandTotal;
            }
        }
        
        // Combine other charges value
        if (objSalesOrder.ReceiptAllocations__r != null) {
            for (ReceiptAllocation__c r : objSalesOrder.ReceiptAllocations__r) {
                if (r.SalesOrderOtherCharges__c != null) {
                    String otherChargeType = r.SalesOrderOtherCharges__r != null ? r.SalesOrderOtherCharges__r.TypeOfCharge__c : null;
                    if (otherChargeType != null && otherChargesExcludedTypesList.contains(otherChargeType.trim())) {
                        continue;
                    }
                    combinedOtherCharges += Utility.getOrDefault(r.AmountApplied__c);
                }
            }
        }
        
        // ---------------------------
        // Consolidate by InstallmentLine Id
        // ---------------------------
        
        for (InstallmentLines__c inst : (objSalesOrder.InstallmentLines__r != null ? objSalesOrder.InstallmentLines__r : new List<InstallmentLines__c>())) {
            ConsolidatedInstallment ci = new ConsolidatedInstallment();
            ci.installmentLineId = inst.Id;
            ci.installmentNumber = (inst.InstallmentNumber__c != null) ? String.valueOf(inst.InstallmentNumber__c) : '';
            ci.installmentAmount = Utility.getOrDefault(inst.InstallmentAmount__c);
            ci.dueDate = inst.Due_Date__c;
            ci.amount = Utility.getOrDefault(inst.InstallmentAmount__c);
            ci.percentage = Utility.getOrDefault(inst.InstallmentPercentage__c);
            if (inst.Due_Date__c != null && inst.Due_Date__c > Date.today()) {
                ci.pendingAmount = 0;
            } else {
                Decimal receivedNotClearedForInst = receivedAppliedByInstallment.containsKey(inst.Id) ? receivedAppliedByInstallment.get(inst.Id) : 0;
                ci.pendingAmount = Utility.getOrDefault(inst.PendingAmount__c) + receivedNotClearedForInst;
            }
            ci.reversalDate = null;
            ci.rvDetails = new List<RVDetail>();
            consMap.put(inst.Id, ci);
        }
        
        for (ReceiptAllocation__c r : installmentReceipts) {
            if (r.InstallmentLine__c == null) continue;
            
            ConsolidatedInstallment ci;
            if (consMap.containsKey(r.InstallmentLine__c)) {
                ci = consMap.get(r.InstallmentLine__c);
            } else {
                ci = new ConsolidatedInstallment();
                ci.installmentLineId = r.InstallmentLine__c;
                ci.installmentNumber = (r.InstallmentLine__r != null && r.InstallmentLine__r.InstallmentNumber__c != null) ? String.valueOf(r.InstallmentLine__r.InstallmentNumber__c) : '';
                ci.installmentAmount = (r.InstallmentLine__r != null && r.InstallmentLine__r.InstallmentAmount__c != null) ? Utility.getOrDefault(r.InstallmentLine__r.InstallmentAmount__c) : null;
                ci.dueDate = (r.InstallmentLine__r != null) ? r.InstallmentLine__r.Due_Date__c : null;
                ci.amount = (r.InstallmentLine__r != null) ? Utility.getOrDefault(r.InstallmentLine__r.InstallmentAmount__c) : Utility.getOrDefault(r.AmountApplied__c);
                ci.percentage = (r.InstallmentLine__r != null) ? Utility.getOrDefault(r.InstallmentLine__r.InstallmentPercentage__c) : 0;
                if (r.InstallmentLine__r != null && r.InstallmentLine__r.Due_Date__c != null && r.InstallmentLine__r.Due_Date__c > Date.today()) {
                    ci.pendingAmount = 0;
                } else {
                    Decimal basePending = (r.InstallmentLine__r != null) ? Utility.getOrDefault(r.InstallmentLine__r.PendingAmount__c) : 0;
                    Decimal receivedNotClearedForInst = (r.InstallmentLine__c != null && receivedAppliedByInstallment.containsKey(r.InstallmentLine__c)) ? receivedAppliedByInstallment.get(r.InstallmentLine__c) : 0;
                    ci.pendingAmount = basePending + receivedNotClearedForInst;
                }
                ci.rvDetails = new List<RVDetail>();
                consMap.put(r.InstallmentLine__c, ci);
            }
            
            RVDetail rv = new RVDetail();
            rv.rvNo = r.Receipt_Reference__c;
            Date rvDate = null;
            rvDate = r.ReceiptAcknowledgement__r.MaturityDate__c != null ? r.ReceiptAcknowledgement__r.MaturityDate__c : (r.ReceiptAcknowledgement__c != null && r.ReceiptAcknowledgement__r.MaturityDate__c != null
                ? r.ReceiptAcknowledgement__r.MaturityDate__c : null);
            rv.rvDate = rvDate;
            rv.rvDateFormatted = Utility.formatDate(rvDate);
            rv.mode = r.Receipt_Type__c;
            rv.status = r.ReceiptStatus__c;
            // Collected: if cleared -> amount applied less refund
            Decimal collectedAmt = (r.ReceiptStatus__c == 'Cleared') ? Utility.getOrDefault(r.AmountApplied__c) : 0;
            if (r.ReceiptAcknowledgement__c != null && refundAgainstCollectedByReceiptId.containsKey(r.ReceiptAcknowledgement__c)) {
                Decimal refundAgainstCollected = refundAgainstCollectedByReceiptId.get(r.ReceiptAcknowledgement__c);
                collectedAmt -= refundAgainstCollected;
                if (collectedAmt < 0) {
                    collectedAmt = 0;
                }
            }
            
            // === MERGE ADM INTO INSTALLMENT 1 AT RECEIPT LEVEL ===
            if (admIncluded && r.InstallmentNumberOrChargeType__c == '1' && r.Receipt_Reference__c != null && admClearedMap.containsKey(r.Receipt_Reference__c)) {
                collectedAmt += admClearedMap.get(r.Receipt_Reference__c);
            }
            
            rv.collected = collectedAmt;
            
            Boolean isFutureInstallment = r.InstallmentLine__r.Due_Date__c != null && r.InstallmentLine__r.Due_Date__c > Date.today();
            
            // Outstanding: if not cleared -> amount applied else use Installment pending if available
            if (isFutureInstallment) {
                rv.outstanding = 0;
            } else {
                Decimal basePending = (r.InstallmentLine__r != null) ? Utility.getOrDefault(r.InstallmentLine__r.PendingAmount__c) : 0;
                Decimal receivedNotClearedForInst = (r.InstallmentLine__c != null && receivedAppliedByInstallment.containsKey(r.InstallmentLine__c)) ? receivedAppliedByInstallment.get(r.InstallmentLine__c) : 0;
                rv.outstanding = basePending + receivedNotClearedForInst;
                
                // NEW: ADM received-but-not-cleared belongs to installment 1's outstanding
                if (admIncluded && r.InstallmentNumberOrChargeType__c == '1' && r.Receipt_Reference__c != null && admReceivedMap.containsKey(r.Receipt_Reference__c)) {
                    rv.outstanding += admReceivedMap.get(r.Receipt_Reference__c);
                }
            }
            ci.rvDetails.add(rv);
            ci.amount += collectedAmt;
            if (rv.rvDate != null) {
                if (ci.reversalDate == null || rv.rvDate < ci.reversalDate) {
                    ci.reversalDate = rv.rvDate;
                }
            }
        }
        
        
        // Sort rvDetails for each consolidated installment by rvDate ascending
        for (ConsolidatedInstallment ci : consMap.values()) {
            if (ci.rvDetails != null && !ci.rvDetails.isEmpty()) {
                ci.rvDetails.sort(new RVDetailComparator());
                ci.receiptCount = ci.rvDetails.size();
            } else {
                ci.receiptCount = 1;
            }
        }
        
        for (ConsolidatedOtherCharge c : consOtherChargeMap.values()) {
            c.rvDetails.sort(new RVDetailComparatorOC());
        }
        
        // ---------------------------
        // Consolidate Rebates
        // ---------------------------
        List<ConsolidatedRebate> rebateList = new List<ConsolidatedRebate>();
        Decimal totalRebate = 0;
        
        if (objSalesOrder.SalesOrderRebates__r != null) {
            
            for (SalesOrderRebate__c rb : objSalesOrder.SalesOrderRebates__r) {
                
                ConsolidatedRebate cr = new ConsolidatedRebate();
                
                cr.chargeNo = rb.Name;
                cr.rebateDate = rb.Date__c;
                cr.percentage = Utility.getOrDefault(rb.Percentage__c);
                cr.amount = Utility.getOrDefault(rb.Amount__c);
                cr.rebatedAmount = Utility.getOrDefault(rb.Amount__c);
                
                if (rb.InstallmentLine__r != null) {
                    cr.refNo = rb.InstallmentLine__r.Name;
                }
                
                rebateList.add(cr);
                totalRebate += Utility.getOrDefault(rb.Amount__c);
            }
        }
        
        // === Merge ADM Fee with Installment #1 where Receipt Reference matches ===
        if (admFeeReceipts != null && !admFeeReceipts.isEmpty()) {
            ConsolidatedInstallment firstInst = null;
            for (ConsolidatedInstallment ci : consMap.values()) {
                if (ci.installmentNumber == '1') {
                    firstInst = ci;
                    break;
                }
            }
            if (firstInst != null) {
                for (RVDetail rv : firstInst.rvDetails) {
                    for (ReceiptAllocation__c admR : admFeeReceipts) {
                        if (admR.Receipt_Reference__c != null && rv.rvNo == admR.Receipt_Reference__c && admR.ReceiptStatus__c == 'Cleared') {
                            firstInst.amount += Utility.getOrDefault(admR.AmountApplied__c); // increase total for installment 1
                        }
                    }
                }
                // NEW: fold received-not-cleared ADM into installment 1's pendingAmount
                Decimal admReceivedTotal = 0;
                for (Decimal v : admReceivedMap.values()) {
                    admReceivedTotal += v;
                }
                if (admReceivedTotal > 0) {
                    firstInst.pendingAmount += admReceivedTotal;
                }
            }
        }
        
        // Create sorted consolidatedInstallments list (sort by reversalDate ascending; nulls last)
        List<ConsolidatedInstallment> consolidatedInstallments = new List<ConsolidatedInstallment>(consMap.values());
        consolidatedInstallments.sort(new InstallmentNumberComparator ());
        List<ReceiptWrapper> onAccountWrappers = new List<ReceiptWrapper>();
        Decimal totalOnAccountAmount = 0;
        
        // === Append Special GL Receipts to the bottom of Installment & Other Charge tables ===
        if (!specialGLReceipts.isEmpty()) {
            Boolean hasUnappliedInstallment = false;
            Boolean hasUnappliedOtherCharge = false;
            
            // Row for Installment "On Account" (Indicator X)
            ConsolidatedInstallment specialRowInst = new ConsolidatedInstallment();
            specialRowInst.installmentNumber = 'On Account';
            specialRowInst.rvDetails = new List<RVDetail>();
            
            // Row for Other Charges "On Account" (Indicator V)
            ConsolidatedOtherCharge specialRowOC = new ConsolidatedOtherCharge();
            specialRowOC.chargeName = 'On Account';
            specialRowOC.purpose = 'Unapplied Credit';
            specialRowOC.rvDetails = new List<RVDetailOC>();
            specialRowOC.amount = 0;
            specialRowOC.applied = 0;
            specialRowOC.pending = 0;
            
            for (ReceiptAcknowledgement__c ra : specialGLReceipts) {
                if (ra.Amount__c == null) {
                    continue;
                }
                Decimal unappliedAmount = Utility.getOrDefault(ra.Amount__c) - Utility.getOrDefault(ra.AmountApplied__c);
                if (unappliedAmount < 0) {
                    unappliedAmount = 0;
                }
                // Refund should first consume the unapplied amount.
                if (refundAmountByReceiptAcknowledgementId.containsKey(ra.Id)) {
                    Decimal refundAmount = refundAmountByReceiptAcknowledgementId.get(ra.Id);
                    Decimal refundAgainstUnapplied = Math.min(refundAmount, unappliedAmount);
                    unappliedAmount -= refundAgainstUnapplied;
                }
                
                // Ignore fully applied/refunded receipts
                if (unappliedAmount <= 0) {
                    continue;
                }
                
                // Only the remaining unapplied amount is On Account
                //totalCollected += unappliedAmount;
                
                // Logic for Installment "On Account"
                if (ra.SAP_Special_GL_Indicator__c == 'X') {
                    if (unappliedAmount <= 0) continue;
                    hasUnappliedInstallment = true;
                    if (ra.Status__c == 'Cleared') {
                        totalOnAccountAmount += unappliedAmount;
                    }
                    RVDetail rv = new RVDetail();
                    rv.rvNo = ra.Name;
                    rv.rvDate = (ra.New_Maturity_Date__c != null) ? ra.New_Maturity_Date__c : ra.MaturityDate__c;
                    rv.mode = ra.BankName__c;
                    rv.collected = (ra.Status__c == 'Cleared') ? unappliedAmount : 0;
                    rv.outstanding = 0;
                    rv.status = ra.Status__c;
                    specialRowInst.rvDetails.add(rv);
                }
                // Logic for Other Charges "On Account"
                else {
                    if (unappliedAmount <= 0) continue;
                    String fakeId = 'ONACC-' + ra.Id;
                    if (!consOtherChargeMap.containsKey(fakeId)) {
                        ConsolidatedOtherCharge coc = new ConsolidatedOtherCharge();
                        coc.otherChargeId = fakeId;
                        coc.chargeName = '';
                        coc.purpose = 'On Account';
                        coc.dueDate = ra.MaturityDate__c;
                        coc.amount = unappliedAmount;
                        coc.applied = unappliedAmount;
                        coc.pending = 0;
                        coc.rvDetails = new List<RVDetailOC>();
                        consOtherChargeMap.put(fakeId, coc);
                    }
                    
                    ConsolidatedOtherCharge row = consOtherChargeMap.get(fakeId);
                    RVDetailOC rv = new RVDetailOC();
                    rv.rvNo = ra.Name;
                    rv.rvDate = (ra.New_Maturity_Date__c != null) ? ra.New_Maturity_Date__c : ra.MaturityDate__c;
                    rv.rvDateFormatted = Utility.formatDate(rv.rvDate);
                    rv.mode = ra.BankName__c;
                    rv.status = ra.Status__c;
                    rv.applied = unappliedAmount;
                    rv.pending = 0;
                    row.rvDetails.add(rv);
                }
            }
            
            // Add pseudo-row to Installment List
            if (hasUnappliedInstallment && !specialRowInst.rvDetails.isEmpty()) {
                consolidatedInstallments.add(specialRowInst);
            }
        }
        SalesOrderWrapper wrapper = new SalesOrderWrapper(objSalesOrder,installmentReceipts,salesOrderReceipts,admFee,admIncluded,totalCollected,totalBalance,totalDisplayedBalance,admFee,admReceiptReference,isWaiver,isADM,isRegular,isVAT,admMap,admClearedMap,admReceivedMap,refundAgainstCollectedByReceiptId,receivedAppliedByInstallment);
        wrapper.consolidatedInstallments = consolidatedInstallments;
        wrapper.customerNamesFormatted = customerNamesFormatted;
        // Include "On Account" receipts in Installment Collected Total
        for (ConsolidatedInstallment ci : wrapper.consolidatedInstallments) {
            if (ci.installmentNumber == 'On Account' && ci.rvDetails != null) {
                for (RVDetail rv : ci.rvDetails) {
                    wrapper.installmentCollectedAmount += Utility.getOrDefault(rv.collected);
                }
            }
        }
        wrapper.otherChargeCollectedAmount = Utility.getOrDefault(totalOtherChargeCollected);
        wrapper.totalCollectionAmount = Utility.getOrDefault(wrapper.installmentCollectedAmount);
        wrapper.consolidatedOtherCharges = new List<ConsolidatedOtherCharge>(consOtherChargeMap.values());
        wrapper.consolidatedRebates = rebateList;
        wrapper.hasRebates = !rebateList.isEmpty();
        wrapper.totalRebateAmount = totalRebate;
        wrapper.consolidatedRefunds = refundList;
        wrapper.totalRefundAmount = totalRefund;
        wrapper.hasRefunds = !refundList.isEmpty();
        // =============================================
        // CORRECT OC TOTAL CALCULATION
        // =============================================
        Decimal totalAmtOC = 0;
        Decimal totalAppliedOC = 0;
        Decimal totalPendingOC = 0;
        
        for (ConsolidatedOtherCharge oc : wrapper.consolidatedOtherCharges) {
            totalAmtOC += (oc.amount != null ? oc.amount : 0);
            if (oc.rvDetails != null && !oc.rvDetails.isEmpty()) {
                Decimal appliedSum = 0;
                for (RVDetailOC rv : oc.rvDetails) {
                    appliedSum += (rv.applied != null ? rv.applied : 0);
                }
                totalAppliedOC += appliedSum;
            }
            else {
                totalAppliedOC += (oc.applied != null ? oc.applied : 0);
            }
            totalPendingOC += (oc.pending != null ? oc.pending : 0);
        }
        
        // Assign
        wrapper.totalAmtOtherCharge = totalAmtOC;
        wrapper.totalAppliedAmtOtherCharge = totalAppliedOC;
        wrapper.totalPendingAmtOtherCharge = totalPendingOC;
        
        // --- UPDATE OUTSTANDING AFTER OC RECALC ---
        wrapper.otherChargesOutstandingAmount = Utility.getOrDefault(wrapper.totalPendingAmtOtherCharge);
        //wrapper.totalOutstandingAmount = Utility.getOrDefault(wrapper.installmentOutstandingAmount) + Utility.getOrDefault(wrapper.otherChargesOutstandingAmount);
        wrapper.totalOutstandingAmount = Utility.getOrDefault(wrapper.installmentOutstandingAmount);
        wrapper.totalOutstandingAmount -= totalOnAccountAmount;
        if (wrapper.totalOutstandingAmount < 0) {
            wrapper.totalOutstandingAmount = 0;
        }
        // Append On Account wrappers after wrapper is created
        if (!onAccountWrappers.isEmpty()) {
            if (wrapper.salesOrderReceiptWrappers == null) {
                wrapper.salesOrderReceiptWrappers = new List<ReceiptWrapper>();
            }
            wrapper.salesOrderReceiptWrappers.addAll(onAccountWrappers);
        }
        
        salesOrderWrapperList.add(wrapper);
        totalBalanceInstallment = Utility.formatCurrency(totalDisplayedBalance);
    }
    
    public class SalesOrderWrapper {
        public Salesorder__c salesOrder { get; set; }
        public List<ReceiptWrapper> installmentReceiptWrappers { get; set; }
        public List<ReceiptWrapper> salesOrderReceiptWrappers { get; set; }
        public List<ConsolidatedInstallment> consolidatedInstallments { get; set; }
        public List<ConsolidatedOtherCharge> consolidatedOtherCharges { get; set; }
        public List<ConsolidatedRebate> consolidatedRebates { get; set; }
        public List<ConsolidatedRefund> consolidatedRefunds { get; set; }
        public Decimal totalAmount { get; set; }
        public Decimal totalAmtOtherCharge { get; set; }
        public Decimal totalAppliedAmtOtherCharge { get; set; }
        public Decimal totalPendingAmtOtherCharge { get; set; }
        public Decimal totalPendingAmtInstallment { get; set; }
        public Decimal totalAppliedAmtInstallment { get; set; }
        public Decimal totalInstallmentAmount { get;set; }
        public Decimal totalInstallmentPercentage { get;set; }
        public Decimal installmentCollectedAmount { get; set; }
        public Decimal otherChargeCollectedAmount { get; set; }
        public Decimal totalCollectionAmount { get; set; }
        public Decimal totalCollectedAmt { get; set; }
        public Decimal totalBalanceInstallment { get; set; }
        public Decimal totalDisplayedBalance { get; set; }
        public Decimal totalRebateAmount { get; set; }
        public Decimal totalRefundAmount { get; set; }
        public Decimal admAmount { get; set; }
        public String admReceiptReference { get; set; }
        public Boolean isWaiver { get; set; }
        public Boolean isADM { get; set; }
        public Boolean isRegular { get; set; }
        public Boolean isVAT { get; set; }
        public Boolean admFeeIncludedValue { get; set; }
        public String todayDate { get; set; }
        public String bookingDateFormatted { get; set; }
        public String totalAmountFormatted { get; set; }
        public String totalAmountInWords { get; set; }
        public Decimal totalAmountWithVAT { get; set; }
        public String totalAmountWithVATFormatted { get; set; }
        public Map<String, Decimal> admMap;
        public Map<String, Decimal> admClearedMap;
        public Map<String, Decimal> admReceivedMap;   // NEW
        public Decimal installmentOutstandingAmount { get; set; }
        public Decimal otherChargesOutstandingAmount { get; set; }
        public Decimal totalOutstandingAmount { get; set; }
        public Boolean hasRebates { get; set; }
        public Boolean hasRefunds { get; set; }
        public String customerNamesFormatted { get; set; }
        
        public SalesOrderWrapper(Salesorder__c so,List<ReceiptAllocation__c> instReceipts,List<ReceiptAllocation__c> soReceipts,Decimal otherChargeAdmFeeAmt,Boolean admFeeIncluded,
        Decimal totalCollected,Decimal totalBalance,Decimal totalDisplayedBalance,Decimal admAmount,String admReceiptReference,Boolean isWaiver,Boolean isADM,Boolean isRegular,Boolean isVAT,Map<String, Decimal> admMap,Map<String, Decimal> admClearedMap,Map<String, Decimal> admReceivedMap,Map<Id, Decimal> refundAmountByReceiptAcknowledgementId,Map<Id, Decimal> receivedAppliedByInstallment) {
            this.salesOrder = so;
            this.installmentReceiptWrappers = new List<ReceiptWrapper>();
            this.salesOrderReceiptWrappers = new List<ReceiptWrapper>();
            this.consolidatedInstallments = new List<ConsolidatedInstallment>();
            this.consolidatedOtherCharges = new List<ConsolidatedOtherCharge>();
            this.consolidatedRebates = new List<ConsolidatedRebate>();
            this.consolidatedRefunds = new List<ConsolidatedRefund>();
            this.totalCollectedAmt = Utility.getOrDefault(totalCollected);
            this.totalBalanceInstallment = Utility.getOrDefault(totalDisplayedBalance);
            this.totalRebateAmount = 0;
            this.totalRefundAmount = 0;
            this.admAmount = Utility.getOrDefault(admAmount);
            this.admMap = admMap != null ? admMap : new Map<String,Decimal>();
            this.admClearedMap = admClearedMap != null ? admClearedMap : new Map<String,Decimal>();
            this.admReceivedMap = admReceivedMap != null ? admReceivedMap : new Map<String,Decimal>();
            this.admReceiptReference = admReceiptReference;
            this.isWaiver = isWaiver;
            this.isADM = isADM;
            this.isRegular = isRegular;
            this.isVAT = isVAT;
            this.admFeeIncludedValue = admFeeIncluded;
            this.todayDate = DateTime.now().format('dd-MMM-yy');
            this.bookingDateFormatted = Utility.formatDate(so.SoldDate__c);
            this.hasRebates = false;
            this.hasRefunds = false;
            totalAmount = 0;
            totalAppliedAmtInstallment = 0;
            totalPendingAmtInstallment = 0;
            totalInstallmentAmount = 0;
            totalInstallmentPercentage = 0;
            installmentCollectedAmount = 0;
            totalAmtOtherCharge = 0;
            totalAppliedAmtOtherCharge = 0;
            totalPendingAmtOtherCharge = 0;
            
            if(so.InstallmentLines__r != null){
                for(InstallmentLines__c objInst : so.InstallmentLines__r){
                    totalInstallmentAmount += objInst.InstallmentAmount__c;
                    totalInstallmentPercentage += objInst.InstallmentPercentage__c != null ? objInst.InstallmentPercentage__c : 0;
                }
            }
            
            if (instReceipts != null) {
                for (ReceiptAllocation__c r : instReceipts) {
                    this.installmentReceiptWrappers.add(new ReceiptWrapper(r, otherChargeAdmFeeAmt, admFeeIncluded, admReceiptReference, admMap, admClearedMap, admReceivedMap, receivedAppliedByInstallment));
                }
            }
            
            if (soReceipts != null) {
                for (ReceiptAllocation__c r : soReceipts) {
                    this.salesOrderReceiptWrappers.add(new ReceiptWrapper(r, otherChargeAdmFeeAmt, admFeeIncluded, admReceiptReference, admMap, admClearedMap, admReceivedMap, null));
                }
            }
            
            this.installmentReceiptWrappers.sort(new ReceiptWrapperComparator());
            // Calculate totals (preserve existing behavior)
            Set<Id> processedInstallmentIdsForPending = new Set<Id>();
            if (installmentReceiptWrappers != null) {
                for (ReceiptWrapper rw : installmentReceiptWrappers) {
                    if (rw != null) {
                        totalAmount += Utility.getOrDefault(rw.adjustedAmount);
                        totalAppliedAmtInstallment += Utility.getOrDefault(rw.adjustedAmount);
                        Id instId = (rw.receipt != null) ? rw.receipt.InstallmentLine__c : null;
                        if (instId == null || !processedInstallmentIdsForPending.contains(instId)) {
                            if (instId != null) processedInstallmentIdsForPending.add(instId);
                            totalPendingAmtInstallment += Utility.getOrDefault(rw.getPendingAmount());
                        }
                        if (rw.isCleared()) {
                            Decimal collectedAmount = Utility.getOrDefault(rw.receipt.AmountApplied__c);
                            // Deduct refund linked to this ReceiptAcknowledgement
                            if (rw.receipt.ReceiptAcknowledgement__c != null && refundAmountByReceiptAcknowledgementId != null && refundAmountByReceiptAcknowledgementId.containsKey(rw.receipt.ReceiptAcknowledgement__c)) {
                                collectedAmount -= refundAmountByReceiptAcknowledgementId.get(rw.receipt.ReceiptAcknowledgement__c);
                                if (collectedAmount < 0) {
                                    collectedAmount = 0;
                                }
                            }
                            installmentCollectedAmount += collectedAmount;
                        }
                    }
                }
            }
            
            if (salesOrderReceiptWrappers != null) {
                Set<Id> processedReceiptIds = new Set<Id>();
                
                for (ReceiptWrapper rw : salesOrderReceiptWrappers) {
                    if (rw != null && rw.receipt != null && rw.receipt.Id != null) {
                        
                        // Check uniqueness
                        if (!processedReceiptIds.contains(rw.receipt.Id)) {
                            
                            processedReceiptIds.add(rw.receipt.Id);
                            
                            totalAmtOtherCharge += Utility.getOrDefault(rw.getOtherChargeAmount());
                            totalAppliedAmtOtherCharge += Utility.getOrDefault(rw.receipt.AmountApplied__c);
                            totalPendingAmtOtherCharge += Utility.getOrDefault(rw.getOtherChargePending());
                        }
                    }
                }
                
            }
            
            this.totalAmountFormatted = Utility.formatCurrency(totalAmount);
            this.totalAmountInWords = Utilities.amountInWords(totalAmount, 'Dirham', 'Fils');
            // === VAT CALCULATION ===
            if (Utility.getOrDefault(so.Tax_Percentage__c) > 0) {
                totalAmountWithVAT = (Utility.getOrDefault(so.Amount_Payable_Excluding_ADM__c) + Utility.getOrDefault(so.TaxableAmount__c));
                totalAmountWithVATFormatted = Utility.formatCurrency(totalAmountWithVAT);
            } else {
                totalAmountWithVAT = Utility.getOrDefault(so.NetAmount__c);
                totalAmountWithVATFormatted = Utility.formatCurrency(totalAmountWithVAT);
            }
            this.installmentOutstandingAmount = Utility.getOrDefault(totalBalance);
            this.otherChargesOutstandingAmount = Utility.getOrDefault(this.totalPendingAmtOtherCharge);
            this.totalOutstandingAmount = this.installmentOutstandingAmount;
        }
    }
    
    public class ReceiptWrapper {
        public ReceiptAllocation__c receipt { get; set; }
        public Decimal adjustedAmount { get; set; }
        public String installmentDueDateFormatted { get; set; }
        public String rvDateFormatted { get; set; }
        public String otherChargeDueDateFormatted { get; set; }
        public String admReceiptReference { get; set; }
        public Map<String, Decimal> admMap { get; set; }
        public Map<String, Decimal> admClearedMap { get; set; }
        public Map<String, Decimal> admReceivedMap { get; set; }
        public String displayReceiptReference { get; set; }
        public String displayReceiptType { get; set; }
        public String displayReceiptStatus { get; set; }
        public Map<Id, Decimal> receivedAppliedByInstallmentMap { get; set; }
        
        public ReceiptWrapper(ReceiptAllocation__c r,Decimal otherChargeAdmFeeAmt,Boolean admFeeIncluded,String admReceiptReference,Map<String, Decimal> admMap,Map<String, Decimal> admClearedMap,Map<String, Decimal> admReceivedMap,Map<Id, Decimal> receivedAppliedByInstallment) {
            this.receipt = r;
            this.admMap = admMap != null ? admMap : new Map<String, Decimal>();
            this.admClearedMap = admClearedMap != null ? admClearedMap : new Map<String, Decimal>();
            this.admReceiptReference = admReceiptReference;
            this.installmentDueDateFormatted = Utility.formatDate(r.InstallmentLine__r != null ? r.InstallmentLine__r.Due_Date__c : null);
            Date rvDate = null;
            rvDate = r.DateOfApplication__c != null ? r.DateOfApplication__c : (r.ReceiptAcknowledgement__c != null && r.ReceiptAcknowledgement__r.MaturityDate__c != null
                ? r.ReceiptAcknowledgement__r.MaturityDate__c : null);
            this.rvDateFormatted = Utility.formatDate(rvDate);
            this.otherChargeDueDateFormatted = Utility.formatDate(r.SalesOrderOtherCharges__r != null ? r.SalesOrderOtherCharges__r.Due_Date__c : null);
            // Adjusted amount logic: preserve original ADM add-to-installment-1 behavior
            Decimal baseAmount = Utility.getOrDefault(r.AmountApplied__c);
            if (admFeeIncluded && r.InstallmentNumberOrChargeType__c == '1' && r.Receipt_Reference__c != null && this.admClearedMap.containsKey(r.Receipt_Reference__c)) {
                baseAmount += this.admClearedMap.get(r.Receipt_Reference__c);
                if (r.AmountApplied__c == null) r.AmountApplied__c = 0;
                r.AmountApplied__c = r.AmountApplied__c + this.admClearedMap.get(r.Receipt_Reference__c);
            }
            this.adjustedAmount = baseAmount;
            this.receivedAppliedByInstallmentMap = receivedAppliedByInstallment != null ? receivedAppliedByInstallment : new Map<Id, Decimal>();
            this.admReceivedMap = admReceivedMap != null ? admReceivedMap : new Map<String, Decimal>();
        }
        
        public ReceiptWrapper(ReceiptAllocation__c r,Decimal otherChargeAdmFeeAmt,Boolean admFeeIncluded,String admReceiptReference,Map<String, Decimal> admMap,String displayRef,String displayType,String displayStatus) {
            this(r,otherChargeAdmFeeAmt,admFeeIncluded,admReceiptReference,admMap,(Map<String, Decimal>)null,(Map<String, Decimal>)null,(Map<Id, Decimal>)null);
            this.displayReceiptReference = displayRef;
            this.displayReceiptType = displayType;
            this.displayReceiptStatus = displayStatus;
        }
        
        public Boolean isCleared() { return receipt != null && receipt.ReceiptStatus__c == 'Cleared'; }
        public Decimal getPendingAmount() {
            if (receipt == null || receipt.InstallmentLine__r == null) return 0;
            Decimal basePending = Utility.getOrDefault(receipt.InstallmentLine__r.PendingAmount__c);
            Decimal receivedNotCleared = (receipt.InstallmentLine__c != null && receivedAppliedByInstallmentMap != null && receivedAppliedByInstallmentMap.containsKey(receipt.InstallmentLine__c)) ? receivedAppliedByInstallmentMap.get(receipt.InstallmentLine__c) : 0;
            Decimal admReceivedForThisReceipt = (admReceivedMap != null && receipt.InstallmentNumberOrChargeType__c == '1' && receipt.Receipt_Reference__c != null && admReceivedMap.containsKey(receipt.Receipt_Reference__c)) ? admReceivedMap.get(receipt.Receipt_Reference__c) : 0;
            return basePending + receivedNotCleared + admReceivedForThisReceipt;
        }
        public Decimal getOtherChargeAmount() { return (receipt != null && receipt.SalesOrderOtherCharges__r != null) ? Utility.getOrDefault(receipt.SalesOrderOtherCharges__r.Amount__c) : 0; }
        public Decimal getOtherChargePending() { return (receipt != null && receipt.SalesOrderOtherCharges__r != null) ? Utility.getOrDefault(receipt.SalesOrderOtherCharges__r.PendingAmount__c) : 0; }
    }
    
    public class ReceiptWrapperComparator implements Comparator<ReceiptWrapper> {
        public Integer compare(ReceiptWrapper a, ReceiptWrapper b) {
            Integer aNum = (a.receipt.InstallmentLine__r != null && a.receipt.InstallmentLine__r.InstallmentNumber__c != null)
                ? Integer.valueOf(a.receipt.InstallmentLine__r.InstallmentNumber__c) : 0;
            Integer bNum = (b.receipt.InstallmentLine__r != null && b.receipt.InstallmentLine__r.InstallmentNumber__c != null)
                ? Integer.valueOf(b.receipt.InstallmentLine__r.InstallmentNumber__c) : 0;
            if (aNum == bNum) return 0;
            else if (aNum < bNum) return -1;
            else return 1;
        }
    }
    
    /* =========================
     * ConsolidatedInstallment + RVDetail
     * ConsolidatedInstallment represents one single installment row (Due Date / Inst# / Amount / %)
     * rvDetails is the list of payment rows (RV No / RV Date / Mode / Status / Collected / Outstanding / LPF)
     * ========================= */
    public class ConsolidatedInstallment {
        public Id installmentLineId { get; set; }
        public Date dueDate { get; set; }
        public String installmentNumber { get; set; }
        public Decimal installmentAmount {get; set; }
        public Decimal amount { get; set; }
        public Decimal percentage { get; set; }
        public Decimal pendingAmount { get; set; }
        public Date reversalDate { get; set; }
        public List<RVDetail> rvDetails { get; set; }
        public Integer receiptCount { get; set; }
        public String dueDateFormatted { get { return Utility.formatDate(dueDate); } set; }
        public String amountFormatted { get { return Utility.formatCurrency(amount); } set; }
    }
    
    public class RVDetail {
        public String rvNo { get; set; }
        public Date rvDate { get; set; }
        public String rvDateFormatted { get; set; }
        public String mode { get; set; }
        public String status { get; set; }
        public Decimal collected { get; set; }
        public Decimal outstanding { get; set; }
        public Decimal lpf { get; set; }
    }
    
    public class ConsolidatedOtherCharge {
        public String otherChargeId { get; set; }
        public String chargeName { get; set; }
        public String purpose { get; set; }
        public Date dueDate { get; set; }
        public Decimal amount { get; set; }
        public Decimal applied { get; set; }
        public Decimal pending { get; set; }
        public List<RVDetailOC> rvDetails { get; set; }
        
        public String amountFormatted { get { return Utility.formatCurrency(amount); } }
        public String appliedFormatted { get { return Utility.formatCurrency(applied); } }
        public String pendingFormatted { get { return Utility.formatCurrency(pending); } }
    }
    
    public class ConsolidatedRebate {
        public String chargeNo {get;set;}
        public Date rebateDate {get;set;}
        public Decimal percentage {get;set;}
        public Decimal amount {get;set;}
        public String refNo {get;set;}
        public Decimal rebatedAmount {get;set;}
        public String chargeNoFormatted {get { return chargeNo; }}
        public String rebateDateFormatted {get { return Utility.formatDate(rebateDate); }}
        public String amountFormatted {get { return Utility.formatCurrency(amount); }}
        public String rebatedAmountFormatted {get { return Utility.formatCurrency(rebatedAmount); }}
    }
    
    public class ConsolidatedRefund {
        public String refundNo { get; set; }
        public Date refundDate { get; set; }
        public String refundDateFormatted {get {return Utility.formatDate(refundDate);}}
        public Decimal amount { get; set; }
        public String status { get; set; }
        public String remarks { get; set; }
        public String receiptNo { get; set; }
        public String amountFormatted {get {return Utility.formatCurrency(amount);}}
    }
    
    public class RVDetailOC {
        public String rvNo { get; set; }
        public Date rvDate { get; set; }
        public String rvDateFormatted { get; set; }
        public String mode { get; set; }
        public String status { get; set; }
        public Decimal applied { get; set; }
        public Decimal pending { get; set; }
    }
    
    //Comparator for consolidated installments (by reversalDate ascending; nulls last)
    public class ConsolidatedInstallmentComparator implements Comparator<ConsolidatedInstallment> {
        public Integer compare(ConsolidatedInstallment a, ConsolidatedInstallment b) {
            if (a == null || b == null) return 0;
            Date aDate = a.reversalDate;
            Date bDate = b.reversalDate;
            if (aDate == null && bDate == null) return 0;
            if (aDate == null) return 1; // nulls last
            if (bDate == null) return -1;
            if (aDate == bDate) return 0;
            return aDate < bDate ? -1 : 1;
        }
    }
    
    //Comparator for consolidated installments by Installment Number
    public class InstallmentNumberComparator implements Comparator<ConsolidatedInstallment> {
        public Integer compare(ConsolidatedInstallment a, ConsolidatedInstallment b) {
            if (a == null || b == null) return 0;
            
            Integer aNum = 0;
            Integer bNum = 0;
            
            if (!String.isBlank(a.installmentNumber)) {
                aNum = Integer.valueOf(a.installmentNumber);
            }
            if (!String.isBlank(b.installmentNumber)) {
                bNum = Integer.valueOf(b.installmentNumber);
            }
            
            if (aNum == bNum) return 0;
            return aNum < bNum ? -1 : 1;
        }
    }
    
    //Comparator for rvDetails by rvDate asc (nulls last)
    public class RVDetailComparator implements Comparator<RVDetail> {
        public Integer compare(RVDetail a, RVDetail b) {
            if (a == null || b == null) return 0;
            Date ad = a.rvDate;
            Date bd = b.rvDate;
            if (ad == null && bd == null) return 0;
            if (ad == null) return 1;
            if (bd == null) return -1;
            if (ad == bd) return 0;
            return ad < bd ? -1 : 1;
        }
    }
    
    public class RVDetailComparatorOC implements Comparator<RVDetailOC> {
        public Integer compare(RVDetailOC a, RVDetailOC b) {
            if (a == null || b == null) return 0;
            Date ad = a.rvDate;
            Date bd = b.rvDate;
            if (ad == null && bd == null) return 0;
            if (ad == null) return 1;
            if (bd == null) return -1;
            if (ad == bd) return 0;
            return ad < bd ? -1 : 1;
        }
    }
    
    @AuraEnabled
    public static String generateAndAttachPdf(Id salesOrderId) {
        
        if (salesOrderId == null) {
            throw new AuraHandledException('Sales Order Id was not provided.');
        }
        
        PageReference pdfPage = Page.SalesSOAPDF;
        
        // Pass Sales Order Id to SalesSOAPDF Visualforce page
        pdfPage.getParameters().put('id', salesOrderId);
        
        Blob pdfBlob;
        
        if (Test.isRunningTest()) {
            pdfBlob = Blob.valueOf('Test PDF Content');
        } else {
            pdfBlob = pdfPage.getContent();
        }
        
        // Create Salesforce File
        ContentVersion cv = new ContentVersion();
        
        cv.Title = 'Statement-' + salesOrderId;
        cv.PathOnClient = 'StatementOfAccount.pdf';
        cv.VersionData = pdfBlob;
        cv.IsMajorVersion = true;
        
        insert cv;
        
        // Get ContentDocument Id
        ContentVersion insertedCV = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
            LIMIT 1
        ];
        
        // Link File to Sales Order
        ContentDocumentLink cdl = new ContentDocumentLink();
        
        cdl.ContentDocumentId = insertedCV.ContentDocumentId;
        cdl.LinkedEntityId = salesOrderId;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        
        insert cdl;
        
        return insertedCV.Id;
    }
}