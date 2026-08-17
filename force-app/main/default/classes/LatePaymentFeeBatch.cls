/*****************************************************************************************
Class       : LatePaymentFeeBatch
Author      : Dhanraj Poojary
Description : Batch to create Late Payment Fee Record if Installment Amount is pending after Due Date
Test Class  : LatePaymentFeeBatchTest
Created Date: 02 JAN 2025 
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.     Version              Date                Details
1.          V1.0              25/08/25           Initial Version 
2.			V1.1			  31/07/26		Updated logic to include records beyond the start date set at project level
****************************************************************************************************************/
public class LatePaymentFeeBatch implements Database.Batchable<sObject>, Schedulable{
    
    private static final string MTD_SALES_ORDER_STATUS_VALUE { get { return 'SalesOrderStatusforPendingPayment'; } }
    private static final string MTD_LPF_CALCULATION_DAYS { get { return 'LatePaymentFeeCalculationDays'; } }
    private static final string TYPE_OF_CHARGE { get { return 'Late Payment Charges'; } }
    private static final string MTD_OWE_NO_REPLY_BLOOM_SALES_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    private static final string MTD_LPF_CUSTOMER_NOTIFICATION_EMAIL_TEMPLATE_ID { get { return 'LPFCustomerNotificationTemplateId'; } }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id,Name,EnableLatePaymentFee__c,DailyLPFPercentage__c FROM Project__c WHERE EnableLatePaymentFee__c = TRUE AND LatePaymentFeeCalculationStartDate__c != NULL';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Project__c> scope){
        System.debug('scope'+scope);
        MetadataService objMetadataService = MetadataService.getInstance();
        LatePaymentFeeService latePaymentService = LatePaymentFeeService.getInstance();
        SalesOrderOtherChargesService salesOrderOtherChargeService = SalesOrderOtherChargesService.getInstance();
        InstallmentLineService installmentLineService = InstallmentLineService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        String salesOrderStatusValue = objMetadataService.getAppSettingTextValue(MTD_SALES_ORDER_STATUS_VALUE);
        List<String> salesOrderStatusValueList = salesOrderStatusValue.split(',');
        Integer lpfCalculationDays = objMetadataService.getAppSettingNumberValue(MTD_LPF_CALCULATION_DAYS);
        List<LatePaymentFee__c> latePaymentFeeList = new List<LatePaymentFee__c>();
        Map<Id,SalesOrderOtherCharges__c> mapExistingSOCharges = new Map<Id,SalesOrderOtherCharges__c>();
        List<SalesOrderOtherCharges__c> lstSOCharges = new List<SalesOrderOtherCharges__c>();
        List<InstallmentLines__c> installmentList = new List<InstallmentLines__c>();
        List<InstallmentLines__c> installmentLinesToUpdate = new List<InstallmentLines__c>();
        Set<Id> setUpdatedInstallment = new Set<Id>();
        Map<Id,Date> startDateByInstallment = new Map<Id,Date>();
        Map<Id, Decimal> totalFeeByInstallment = new Map<Id, Decimal>();
        Map<Id, Id> installmentToSOChargeId = new Map<Id, Id>();
        Map<Id, Project__c> projectMap = new Map<Id, Project__c>(scope);
        Date currentDate = Date.today();
        Set<Id> newlyCreatedInstallmentIds = new Set<Id>();
        Id bloomNoReplySalesOWEId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_SALES_ID);
        Id lpfCustomerNotificationETId = objMetadataService.getAppSettingTextValue(MTD_LPF_CUSTOMER_NOTIFICATION_EMAIL_TEMPLATE_ID);
        EmailTemplate lpfCustomerNotificationTemplate = objEmailService.getEmailTemplateById(lpfCustomerNotificationETId);
        List<Messaging.SingleEmailMessage> msgList = new List<Messaging.SingleEmailMessage>();
        List<InstallmentLines__c> lstInstallmentLines = installmentLineService.getInstallmentLinesByProject(projectMap.keySet(),salesOrderStatusValueList);
        Map<Id, SalesOrderOtherCharges__c> installmentToSOCharge = new Map<Id, SalesOrderOtherCharges__c>();
        
        for (InstallmentLines__c pi : lstInstallmentLines) {
            Date lastLPFDate = pi.LastLPFCreatedDate__c;
            Date calculationStartDate;
            Date dueDate = pi.Due_Date__c;
            Integer gracePeriodDays = 0;
            Boolean shouldCalculateLPF = false;
            Date projectLPFStartDate = pi.SalesOrder__r.Unit__r.Project__r.LatePaymentFeeCalculationStartDate__c;
            
            if (pi.Type__c == 'Handover') {
                gracePeriodDays = pi.SalesOrder__r.Unit__r.Project__r.HandoverLPFGracePeriod__c != null ? 
                    Integer.valueOf(pi.SalesOrder__r.Unit__r.Project__r.HandoverLPFGracePeriod__c) : 0;
            } else if(pi.Type__c == 'Installment'){
                gracePeriodDays = pi.SalesOrder__r.Unit__r.Project__r.InstallmentLPFGracePeriod__c != null ? 
                    Integer.valueOf(pi.SalesOrder__r.Unit__r.Project__r.InstallmentLPFGracePeriod__c) : 0;
            }
            
            if (lastLPFDate == null) {
                // Existing overdue installments before LPF activation
                if (dueDate < projectLPFStartDate) {
                    calculationStartDate = projectLPFStartDate;
                    if (currentDate >= calculationStartDate) {
                        shouldCalculateLPF = true;
                    }
                }
                else {
                    // Existing flow for installments due after LPF activation
                    Date graceEndDate = dueDate.addDays(gracePeriodDays + 1);
                    if (currentDate >= graceEndDate) {
                        calculationStartDate = dueDate.addDays(1);
                        shouldCalculateLPF = true;
                    }
                }
                
            }
            else {
                calculationStartDate = lastLPFDate.addDays(1);
                shouldCalculateLPF = currentDate >= calculationStartDate ? true : false;
            }
            
            if (shouldCalculateLPF) {
                Integer daysToCharge = calculationStartDate.daysBetween(currentDate) + 1; // Include current date
                Decimal dailyLPFPercent = pi.SalesOrder__r.Unit__r.Project__r.DailyLPFPercentage__c;
                Decimal lpfThresholdAmount = pi.SalesOrder__r.Unit__r.Project__r.LPFThresholdAmount__c;
                
                // Skip calculation if Daily LPF Percentage is not configured
                if (dailyLPFPercent == null || dailyLPFPercent <= 0) {
                    continue;
                }
                
                Decimal fee = pi.PendingAmount__c * (dailyLPFPercent / 100) * daysToCharge;
                fee = fee.setScale(3, RoundingMode.HALF_UP);
                
                // Skip LPF creation if calculated LPF amount is below threshold
                if (lpfThresholdAmount != null && fee < lpfThresholdAmount) {
                    continue;
                }
                
                LatePaymentFee__c objLatePaymentFee = new LatePaymentFee__c(
                    DueAmount__c = pi.PendingAmount__c, DueDate__c = pi.Due_Date__c,
                    InstallmentLine__c = pi.Id, LatePaymentFeePercentage__c = dailyLPFPercent,
                    StartDate__c = calculationStartDate, EndDate__c = currentDate, Fee__c = fee);
                
                totalFeeByInstallment.put(pi.Id, (totalFeeByInstallment.get(pi.Id) ?? 0) + fee);
                latePaymentFeeList.add(objLatePaymentFee);
                setUpdatedInstallment.add(pi.Id);
                startDateByInstallment.put(pi.Id,calculationStartDate);
                installmentList.add(pi);
                installmentLinesToUpdate.add(new InstallmentLines__c(Id = pi.Id, LastLPFCreatedDate__c = currentDate));
            }   
        }
        
        for (SalesOrderOtherCharges__c objSOC : salesOrderOtherChargeService.getSalesOrderChargesByInstallment(setUpdatedInstallment, TYPE_OF_CHARGE)) {
            mapExistingSOCharges.put(objSOC.Installment_Line__c, objSOC);
        } 
        
        for (InstallmentLines__c pi : installmentList) { 
            Decimal totalFee = totalFeeByInstallment.get(pi.Id);
            SalesOrderOtherCharges__c soc = mapExistingSOCharges.get(pi.Id);
            
            if (soc == null) {
                soc = new SalesOrderOtherCharges__c(
                    Installment_Line__c = pi.Id,
                    StartDate__c = startDateByInstallment.get(pi.Id),
                    TypeOfCharge__c = 'Late Payment Charges',
                    Account__c = pi.SalesOrder__r.Account__c,
                    SalesOrder__c = pi.SalesOrder__c,
                    SAP_Condition_Type__c = pi.SalesOrder__r.Unit__r.Project__r.LPFSAPConditionCode__c ?? ''
                );
                newlyCreatedInstallmentIds.add(pi.Id);
            }
            Decimal existingFee = soc.TotalLatePaymentFee__c != null ? soc.TotalLatePaymentFee__c : 0;
            Decimal updatedFee = existingFee > 0 ? existingFee + totalFee : totalFee;
            updatedFee = updatedFee.setScale(2, RoundingMode.HALF_UP);
            soc.EndDate__c = currentDate;
            soc.Amount__c = updatedFee;
            soc.TotalLatePaymentFee__c = updatedFee;
            lstSOCharges.add(soc);
        }
        
        if(!lstSOCharges.isEmpty()){
            List<SalesOrderOtherCharges__c> insertedCharges = salesOrderOtherChargeService.upsertSalesOrderOtherCharges(lstSOCharges);
            for (SalesOrderOtherCharges__c soc : insertedCharges) {
                installmentToSOChargeId.put(soc.Installment_Line__c, soc.Id);
                installmentToSOCharge.put(soc.Installment_Line__c, soc);
            }
        }
        
        for (LatePaymentFee__c lpf : latePaymentFeeList) {
            lpf.SalesOrderOtherCharges__c = installmentToSOChargeId.get(lpf.InstallmentLine__c);
        }
        latePaymentService.insertLatePaymentFeeLists(latePaymentFeeList);
        
        installmentLineService.updateInstallmentLines(installmentLinesToUpdate);
        
        if (!newlyCreatedInstallmentIds.isEmpty()) {
            if (lpfCustomerNotificationTemplate != null) {
                for (InstallmentLines__c pi : installmentList) {
                    
                    if (!newlyCreatedInstallmentIds.contains(pi.Id)) {
                        continue;
                    }
                    SalesOrderOtherCharges__c soc = installmentToSOCharge.get(pi.Id);
                    Messaging.SingleEmailMessage emailMsg = getEmailContent(pi,soc,objEmailService,lpfCustomerNotificationTemplate,bloomNoReplySalesOWEId);
                    
                    if (emailMsg != null) {
                        msgList.add(emailMsg);
                    }
                }
            }
            objEmailService.sendEmail(msgList);
        }
    }
    
    public void finish(Database.BatchableContext BC) {
    }
    
    public void execute(SchedulableContext sc){
        Database.executeBatch(new LatePaymentFeeBatch(),1);
    }
    
    public Messaging.SingleEmailMessage getEmailContent(InstallmentLines__c pi,SalesOrderOtherCharges__c soc,EmailService objEmailService,EmailTemplate emailTemplate,Id bloomNoReplySalesOWEId) {
        if (pi == null || pi.Due_Date__c == null) return null;
        
        Id contactId = pi.SalesOrder__r.Account__r.IsPersonAccount
            ? pi.SalesOrder__r.Account__r.PersonContactId
            : pi.SalesOrder__r.Contact__c;
        
        String email = pi.SalesOrder__r.Account__r.IsPersonAccount
            ? pi.SalesOrder__r.Account__r.PersonEmail
            : pi.SalesOrder__r.Contact__r.Email;
        
        if (contactId == null || String.isBlank(email)) {
            return null;
        }
        Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(emailTemplate.Id,contactId,pi.SalesOrder__c);
        String body = mail.getHtmlBody();
        String subject = mail.getSubject();
        Datetime dt = Datetime.newInstance(pi.Due_Date__c.year(),pi.Due_Date__c.month(),pi.Due_Date__c.day());
        String formattedDate = dt.format('dd-MM-yyyy');
        
        body = body.replace('[Project_Name]', pi.SalesOrder__r.Unit__r.Project__r.Name != null ? pi.SalesOrder__r.Unit__r.Project__r.Name : '')
            .replace('[Amount]', soc.Amount__c != null ? String.valueOf(soc.Amount__c) : '')
            .replace('[Installment_Date]', formattedDate != null ? formattedDate : '');
        
        mail.setHtmlBody(body);
        subject = subject
            .replace('[Project_Name]', pi.SalesOrder__r.Unit__r.Project__r.Name != null ? pi.SalesOrder__r.Unit__r.Project__r.Name : '')
            .replace('[Unit_Code]', pi.SalesOrder__r.Unit__r.Name != null ? pi.SalesOrder__r.Unit__r.Name : '');
        mail.setSubject(subject);
        mail.setOrgWideEmailAddressId(bloomNoReplySalesOWEId);
        
        return mail;
    }
}