/*****************************************************************************************
Class       : SalesCommissionBatch
Author      : Vikas Baliyan
Description : Sales Commission Batch
Test Class  : 
Created Date: 06 NOV 2024 
*****************************************************************************************/

public class SalesCommissionBatch implements Database.Batchable<sObject>, Schedulable,Database.Stateful {

    private static final string COMMISSION_INVOICE_RECEIVER_EMAILS { get { return 'CommissionInvoiceReceiverEmails'; } }
    private static final string INVOICE_EMAIL_TEMPLATE_ID { get { return 'InvoiceEmailTemplateId'; } }
    private static final string BLOOM_NO_REPLY_SALES_OW_EMAIL_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    private static final string SALES_COMMISSION_BUFFER_DAYS_STR { get { return 'SalesCommissionBufferDays'; } }
    private static final string INSTALLMENT_THRESHOLD_AMOUNT_STR { get { return 'InstallmentThresholdAmount'; } }
    private static final String APPROVAL_STATUS_NOTAPPROVED = 'Not Approved';
    private static final String COMMISSION_FOR_BROKER = 'Broker';

    private List<BrokerCommission__c> commissionList = new List<BrokerCommission__c>();

    public Database.QueryLocator start(Database.BatchableContext bc) {  
        String query = 'SELECT Id, Name, UnitType__c, UnitModel__c, StartDate__c, EndDate__c, LaunchType__c,  Project__c, Project__r.VATPercentage__c,Project__r.ProjectRegistrationDate__c, Percentage__c, Amount_Range_Start__c, Amount_Range_End__c,CommissionSchedule__c.BrokerAccount__c FROM CommissionSchedule__c WHERE ApprovalStatus__c = \'Approved\'';
        return Database.getQueryLocator(query);
    }
    // Main logic of processing each batch
    public void execute(Database.BatchableContext bc, List<CommissionSchedule__c> scope){
        MetadataService objMetadataService = MetadataService.getInstance();
        Integer thresholdAmount = objMetadataService.getAppSettingNumberValue(INSTALLMENT_THRESHOLD_AMOUNT_STR);
        InstallmentLineService installmentService = InstallmentLineService.getInstance();
        SalesOrderService objSalesOrderService = SalesOrderService.getInstance();
        
        BrokerCommissionService objBrokerCommService = BrokerCommissionService.getInstance();
        //installment Number Set for 1st and 2nd installment
        Set<Integer> installmentNumberSet = new Set<Integer>{1,2};
        
        // Map of Agent Id to Total Net Amount
        Map<String, Decimal> agencyIdToAmountMap = new Map<String, Decimal>();
        
        List<InstallmentLines__c> installmentLineList = installmentService.getFirstNSecInstallmentByCommissionCreated(false, installmentNumberSet, Constants.SALES_ORDER_STATUS_SOLD);
        
        Set<Id> brokerIdSet = new Set<Id>();
        Set<Id> projectIdSet = new Set<Id>();
        for(InstallmentLines__c installmentLine : installmentLineList){
            brokerIdSet.add(installmentLine.SalesOrder__r.Opportunity__r.BrokerAgencyAccount__c);
            projectIdSet.add(installmentLine.SalesOrder__r.Unit__r.Project__c);
        }
        Set<Id> fixedCommissionBrokerAccountIdSet = new Set<Id>();
        for(CommissionSchedule__c cs : CommissionScheduleService.getInstance().getCommissionSchedule()){
            fixedCommissionBrokerAccountIdSet.add(cs.BrokerAccount__c);
        }
        
        // Map of sales order
        Map<Id, SalesOrder__c> salesOrderMap = new Map<Id, SalesOrder__c>(objSalesOrderService.getSalesOrdersNOtherChargesByIds(brokerIdSet, projectIdSet, thresholdAmount));
        for(SalesOrder__c so : salesOrderMap.values()){
            for(CommissionSchedule__c cs : scope){
                if(cs.StartDate__c <= so.SoldDate__c && (cs.EndDate__c == null || cs.EndDate__c >= so.SoldDate__c) && so.Unit__r.Project__c == cs.Project__c){
                    if(!agencyIdToAmountMap.containsKey(so.Opportunity__r.BrokerAgencyAccount__c + '-' +so.Unit__r.Project__c+'-'+cs.StartDate__c+'-'+cs.EndDate__c)){
                        agencyIdToAmountMap.put(so.Opportunity__r.BrokerAgencyAccount__c + '-' +so.Unit__r.Project__c+'-'+cs.StartDate__c+'-'+cs.EndDate__c, 0);
                    }
                    agencyIdToAmountMap.put(so.Opportunity__r.BrokerAgencyAccount__c +'-'+so.Unit__r.Project__c +'-'+ cs.StartDate__c +'-'+ cs.EndDate__c, agencyIdToAmountMap.get(so.Opportunity__r.BrokerAgencyAccount__c + '-' +so.Unit__r.Project__c+'-'+cs.StartDate__c+'-'+cs.EndDate__c) + (so.ADM_Fee_Included__c ? (so.Sales_Price_Excluding_ADM__c != null ? so.Sales_Price_Excluding_ADM__c :0) : (so.NetAmount__c != null ? so.NetAmount__c : 0)));
                    break;
                }   
            } 
        }

        // List of Installment Lines to update
        List<InstallmentLines__c> installmentLinesToUpdate = new List<InstallmentLines__c>();
        for(InstallmentLines__c installmentLine : installmentLineList){
            for(CommissionSchedule__c commissionSchedule : scope){
                // Retrieve Sales Order from salesOrderMap
                SalesOrder__c salesOrder = installmentLine.SalesOrder__r.PreviousSalesOrder__c != null ? salesOrderMap.get(installmentLine.SalesOrder__r.PreviousSalesOrder__c) : salesOrderMap.get(installmentLine.SalesOrder__c);
                if(salesOrder == null || salesOrder.Unit__r.Project__r.ProjectRegistrationDate__c == null){
                    continue;
                }
                Decimal taxableAmount = salesOrder.TaxableAmount__c != null && salesOrder.TaxableAmount__c > 0 ? salesOrder.TaxableAmount__c : 0; 
                Decimal commissionEligibleAmount = salesOrder.ADM_Fee_Included__c ? salesOrder.Sales_Price_Excluding_ADM__c : (salesOrder.NetAmount__c != null ? (salesOrder.NetAmount__c - taxableAmount) : 0);
                Decimal admFeePaidAmount = salesOrder.ADM_Fee_Included__c &&  installmentLine.InstallmentNumber__c == 1 && salesOrder.SalesOrdersOtherCharges__r != null && salesOrder.SalesOrdersOtherCharges__r.size() > 0  && salesOrder.SalesOrdersOtherCharges__r[0].InvoicedAmount__c != null ? salesOrder.SalesOrdersOtherCharges__r[0].InvoicedAmount__c : 0;
                Boolean isAmountCleared = (installmentLine.ClearedAmount__c != null && installmentLine.InstallmentAmount__c != null) ? ((installmentLine.InstallmentAmount__c - (installmentLine.ClearedAmount__c + admFeePaidAmount)) <= thresholdAmount) : false;
                Boolean isProjectMatching = salesOrder.Unit__r.Project__c == commissionSchedule.Project__c && commissionSchedule.Project__r.ProjectRegistrationDate__c != null;
                Boolean isTotalAmountInRange = (commissionSchedule.Amount_Range_Start__c == null ||(commissionSchedule.Amount_Range_Start__c <= agencyIdToAmountMap.get(salesOrder.Opportunity__r.BrokerAgencyAccount__c+ '-' +salesOrder.unit__r.Project__c+'-'+commissionSchedule.StartDate__c+'-'+commissionSchedule.EndDate__c))) && (commissionSchedule.Amount_Range_End__c == null || commissionSchedule.Amount_Range_End__c >= agencyIdToAmountMap.get(salesOrder.Opportunity__r.BrokerAgencyAccount__c+ '-' +salesOrder.Unit__r.Project__c+'-'+commissionSchedule.StartDate__c+'-'+commissionSchedule.EndDate__c));
                Boolean isUnitTypeMatching = commissionSchedule.UnitType__c == null || String.isEmpty(commissionSchedule.UnitType__c) ? true : (commissionSchedule.UnitType__c.split(';').contains(salesOrder.Unit__r.UnitType__c));
                Boolean isUnitModelMatching = commissionSchedule.UnitModel__c == null || String.isEmpty(commissionSchedule.UnitModel__c) ? true : (commissionSchedule.UnitModel__c.split(';').contains(salesOrder.Unit__r.UnitModel__c));
                Boolean isSoldDateInCommiScheduleDateRange = salesOrder.SoldDate__c >= commissionSchedule.StartDate__c && (commissionSchedule.EndDate__c == null || salesOrder.SoldDate__c <= commissionSchedule.EndDate__c);
                

                Integer bufferDays = objMetadataService.getAppSettingNumberValue(SALES_COMMISSION_BUFFER_DAYS_STR);
                Date runningDate;
                String launchType;
               
                if(commissionSchedule.EndDate__c != null){
                    runningDate = commissionSchedule.EndDate__c.addDays(bufferDays);
                }
                else{
                    runningDate = Date.today();
                }
                Boolean hasFixedCommission = fixedCommissionBrokerAccountIdSet.contains(salesOrder.Opportunity__r.BrokerAgencyAccount__c);
                Boolean eligibileForFixedCommission =  hasFixedCommission && commissionSchedule.BrokerAccount__c != null && commissionSchedule.BrokerAccount__c == salesOrder.Opportunity__r.BrokerAgencyAccount__c && isAmountCleared && salesOrder.Unit__r.Project__r.ProjectRegistrationDate__c != null;
                Decimal commissionPercentage = commissionSchedule.Percentage__c/2;
                Decimal commissionAmount = commissionEligibleAmount*commissionSchedule.Percentage__c/200;
                Date startDate = commissionSchedule.StartDate__c;
                Decimal vatPercentage = salesOrder.Opportunity__r.BrokerAgencyAccount__r.Is_VAT_Registered__c == 'Yes' ? salesOrder.Unit__r.Project__r.VATPercentage__c : null;
                if(eligibileForFixedCommission){

                    commissionList.add(createBrokerCommissionObj(commissionSchedule.Id, commissionPercentage, commissionAmount, startDate, salesOrder.Unit__r.Project__c, installmentLine.Id, salesOrder.Id, salesOrder.Opportunity__r.BrokerAgencyAccount__c, salesOrder.Opportunity__r.BrokerAgentContact__c, COMMISSION_FOR_BROKER, vatPercentage, APPROVAL_STATUS_NOTAPPROVED, commissionEligibleAmount));
                    
                    installmentLine.BrokerCommissionCreated__c = true;
                    installmentLinesToUpdate.add(installmentLine);
                    break;
                }
                else if(!hasFixedCommission && isAmountCleared && isSoldDateInCommiScheduleDateRange && isUnitTypeMatching && isUnitModelMatching && isProjectMatching && isTotalAmountInRange && runningDate <= Date.today()){   
                    // if commission % is more then 4, creating 2 invoices for 2nd installment
                    if(commissionSchedule.Percentage__c > 4 && installmentLine.InstallmentNumber__c == 2 && salesOrder.Unit__r.Project__r.ApplyADRECBrokerCommissionPolicy__c){
                        Decimal secCommissionPercentage = 4 - commissionSchedule.Percentage__c/2;
                        Decimal secCommissionAmount = commissionEligibleAmount * secCommissionPercentage/100;
                        Decimal thirdCommissionPercentage = commissionSchedule.Percentage__c - (commissionSchedule.Percentage__c/2 + secCommissionPercentage);
                        Decimal thirdCommissionAmount = commissionEligibleAmount * thirdCommissionPercentage/100;
                        commissionList.add(createBrokerCommissionObj(commissionSchedule.Id, secCommissionPercentage, secCommissionAmount, startDate, commissionSchedule.Project__c, installmentLine.Id, salesOrder.Id, salesOrder.Opportunity__r.BrokerAgencyAccount__c, salesOrder.Opportunity__r.BrokerAgentContact__c, COMMISSION_FOR_BROKER, vatPercentage, APPROVAL_STATUS_NOTAPPROVED, commissionEligibleAmount));
                        commissionList.add(createBrokerCommissionObj(commissionSchedule.Id, thirdCommissionPercentage, thirdCommissionAmount, startDate, commissionSchedule.Project__c, installmentLine.Id, salesOrder.Id, salesOrder.Opportunity__r.BrokerAgencyAccount__c, salesOrder.Opportunity__r.BrokerAgentContact__c, COMMISSION_FOR_BROKER, vatPercentage, APPROVAL_STATUS_NOTAPPROVED, commissionEligibleAmount));
                    }
                    else{
                        commissionList.add(createBrokerCommissionObj(commissionSchedule.Id, commissionPercentage, commissionAmount, startDate, commissionSchedule.Project__c, installmentLine.Id, salesOrder.Id, salesOrder.Opportunity__r.BrokerAgencyAccount__c, salesOrder.Opportunity__r.BrokerAgentContact__c, COMMISSION_FOR_BROKER, vatPercentage, APPROVAL_STATUS_NOTAPPROVED, commissionEligibleAmount));
                    }

                    // prepare installment lines list to update
                    installmentLine.BrokerCommissionCreated__c = true;
                    installmentLinesToUpdate.add(installmentLine);
                    break;
                }
            }
        } 
        //Insert commission records
        objBrokerCommService.insertBrokerCommissions(commissionList);

        // Update Installment Lines
        InstallmentLineService installmentLineService = InstallmentLineService.getInstance();
        installmentLineService.updateInstallmentLines(installmentLinesToUpdate);
        
        // Enqueue the Queueable class to create PDF File for the Broker Commission
        System.enqueueJob(new PDFQueueable(commissionList ,BrokerCommission__c.SObjectType , 'Broker Invoice' ));

    }

    private static BrokerCommission__c createBrokerCommissionObj(Id commissionScheduleId, Decimal commissionPercentage, Decimal commissionAmount, Date startDate, Id project, Id installmentLine, Id salesOrder, Id agency, Id agent, String commissionFor, Decimal VATPercentage, String status, Decimal commissionEligibleAmount){
        BrokerCommission__c commission = new BrokerCommission__c();
        commission.CommissionSchedule__c = commissionScheduleId;
        commission.CommissionPercentage__c = commissionPercentage;
        commission.CommissionAmount__c = commissionAmount;
        commission.StartDate__c =  startDate;
        commission.Project__c = project;
        commission.InstallmentLine__c = installmentLine;
        commission.SalesOrder__c = salesOrder;
        commission.Agency__c = agency;
        commission.Agent__c = agent;
        commission.CommissionFor__c = commissionFor;
        commission.VATPercentage__c = VATPercentage;
        commission.FirstApprovalStatus__c = status;
        commission.CommissionEligibleAmount__c = commissionEligibleAmount;
        return commission;
    }

    public void finish(Database.BatchableContext bc){
        if(commissionList.isEmpty()){
            return;
        }
        // Calling the Invoice batch
        EmailService objEmailService = EmailService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        BrokerCommissionService objBrokerCommService = BrokerCommissionService.getInstance();
        //Fetch Emails to notify
        String emailsToNotify = objMetadataService.getAppSettingTextValue(COMMISSION_INVOICE_RECEIVER_EMAILS);
        // Fetch email template Id
        Id invoiceEmailTemplateId = objMetadataService.getAppSettingTextValue(INVOICE_EMAIL_TEMPLATE_ID);
        Id noReplyBloomSalesOWDId = objMetadataService.getAppSettingTextValue(BLOOM_NO_REPLY_SALES_OW_EMAIL_ID);
        EmailTemplate emailTemplate = objEmailService.getEmailTemplateById(invoiceEmailTemplateId);
        String emailBody = emailTemplate.HtmlValue;
        String htmlBody = ('<table style="border-collapse: collapse" Border="1" ><thead><tr><th>S. No</th><th>Invoice Number</th> <th>Project Name</th> <th>Sales Order</th> <th>Unit</th> <th>Agency Name</th> <th>Total Invoice Amount</th><th>Total Invoice Amount with VAT</th></tr></thead><tbody>');
                        
        
        Integer i = 1;
        List<BrokerCommission__c> bcList = objBrokerCommService.getBrokerCommission(commissionList);
        if(bcList.isEmpty()){
            return;
        }
        for(BrokerCommission__c broker : bcList){
            Decimal commissionAmount = broker.CommissionAmount__c != null ? broker.CommissionAmount__c : 0;
            Decimal totalCommissionAmountWithVAT = broker.VATPercentage__c != null ? commissionAmount + (commissionAmount * broker.VATPercentage__c/100) : commissionAmount;
            String brokerName = broker.Name != null ? broker.Name : '';
            String projectName = broker.Project__c != null ? broker.Project__r.Name : '' ;
            String salesOrderName = broker.SalesOrder__c != null ? broker.SalesOrder__r.Name : '';
            String unitName = broker.SalesOrder__r.Unit__c != null ? broker.SalesOrder__r.Unit__r.Name : '';
            String brokerAgency = broker.Agency__c != null ? broker.Agency__r.Name : '';
            htmlBody += '<tr><td>' + i++ + '</td>';
            htmlBody += '<td>' + brokerName + '</td>';
            htmlBody += '<td>' + projectName + '</td>';
            htmlBody += '<td>' + salesOrderName + '</td>';
            htmlBody += '<td>' + unitName + '</td>';
            htmlBody += '<td>' + brokerAgency + '</td>';
            htmlBody += '<td>' + commissionAmount.setscale(2) + '</td>';
            htmlBody += '<td>' + totalCommissionAmountWithVAT.setscale(2) + '</td></tr>';
        }
        htmlBody += ('</tbody></table>');
        emailBody = emailBody.replace('{{INVOICETABLE}}', htmlBody);
        // Send email
        Messaging.SingleEmailMessage email = objEmailService.getSingleEmailMessage(emailsToNotify.split(','), emailTemplate.Subject, emailBody, noReplyBloomSalesOWDId);
        // Sending emails
        Messaging.SendEmailResult[] results = objEmailService.sendEmail(new List<Messaging.SingleEmailMessage>{email});
    }

    // Scheduling the batch
    public void execute(SchedulableContext sc) {
        SalesCommissionBatch batch = new SalesCommissionBatch();
        Database.executeBatch(batch, 200);
    }
}