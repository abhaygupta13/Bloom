/*****************************************************************************************
Class       : BrokerFormPDFController
Author      : Vikas Baliyan
Description : Broker Form PDF Controller
Test Class  : 
Created Date: 12 DEC 2024 
*****************************************************************************************/
public class BrokerFormPDFController {

    private static final String BROKER_COMMISSION_ID_STRING { get { return 'brokerCommissionId'; } }
    public BrokerCommission__c brokerCommission { get;  set; }
    public List<ApproverList> approverList { get; set; }
    private static final String APPROVED_STR {get {return 'Approved';}}
    private static final String DATE_FORMAT_STR {get {return 'dd/MM/yyyy';}}
    private static final String FIRST_COMMISSION_STRING { get { return 'Broker Commission First Payment'; } }
    private static final String SECOND_COMMISSION_STRING { get { return 'Broker Commission Second Payment'; } }
    private static final String FULL_PAYMENT_STRING { get { return 'Broker Commission Full Payment'; } }
    public String spaDate { get;  set; }
    public String soldDate { get;  set; }
    public String dueDateInstallment1 { get;  set; }
    public String dueDateInstallment2 { get;  set; }
    public String verifiedDate { get;  set; }
    public String collectionPercentage { get;  set; }
    public Decimal netAmountWithoutADMFee { get;  set; }
    public String operationalExcellenceStr { get;  set; }
    public String salesFinanceStr { get;  set; }
    public String salesFinanceStr2 { get;  set; }
    public String financeDirectorStr { get;  set; }
    public Integer emptyTdCount { get;  set; }
    public String unitPriceString {get; set;}
    public String netAmountString {get; set;}
    public String commissionAmountString {get; set;}
    public String taxAmountString {get; set;}
    public String admFeeString {get; set;}
    public String totalCommissionPercentage {get; set;}
    public String typeOfPayment {get; set;}
    
    public BrokerFormPDFController() {
        try {
            UserService objUserService = UserService.getInstance();
            BrokerCommissionService objBrokerCommissionServ = BrokerCommissionService.getInstance();
            String BrokerCommissionParamId = ApexPages.currentPage().getParameters().get(BROKER_COMMISSION_ID_STRING);
            InstallmentLineService objInstallmentLineService = InstallmentLineService.getInstance();

            // fetch broker commission details to show on page
            brokerCommission = objBrokerCommissionServ.getBrokerCommissionById(BrokerCommissionParamId);
            
            List<InstallmentLines__c> installmentList = objInstallmentLineService.getAllInstallmentLinesBySalesOrderId(brokerCommission.SalesOrder__c);
            InstallmentLines__c firstInstallment;
            InstallmentLines__c secondInstallment;
            Decimal totalClearedAmount = 0;
            for(InstallmentLines__c inst: installmentList){
                totalClearedAmount += inst.ClearedAmount__c;
                if(inst.InstallmentNumber__c == 1){
                    firstInstallment = inst;
                }
                else if(inst.InstallmentNumber__c == 2){
                    secondInstallment = inst;
                }
            }

            // formated date strings
            verifiedDate = brokerCommission.VerifiedDate__c != null ? brokerCommission.VerifiedDate__c.format(DATE_FORMAT_STR) : '';
            spaDate = brokerCommission.SalesOrder__c != null && brokerCommission.SalesOrder__r.Unit__c != null && brokerCommission.SalesOrder__r.Unit__r.Sales_Order_SPA_Signed_Date__c != null ? brokerCommission.SalesOrder__r.Unit__r.Sales_Order_SPA_Signed_Date__c.format() : '';
            soldDate = brokerCommission.SalesOrder__c != null && brokerCommission.SalesOrder__r.SoldDate__c != null ? brokerCommission.SalesOrder__r.SoldDate__c.format() : '';
            dueDateInstallment1 = firstInstallment != null && firstInstallment.Due_Date__c != null ? firstInstallment.Due_Date__c.format() : '';
            dueDateInstallment2 = secondInstallment != null && secondInstallment.Due_Date__c != null && secondInstallment.Due_Date__c <= Date.today() ? secondInstallment.Due_Date__c.format() : '';
            netAmountWithoutADMFee = brokerCommission.SalesOrder__c != null && brokerCommission.SalesOrder__r.ADM_Fee_Included__c ? brokerCommission.SalesOrder__r.Sales_Price_Excluding_ADM__c : brokerCommission.SalesOrder__r.NetAmount__c;
            collectionPercentage = formatNumber(brokerCommission.SalesOrder__c != null && brokerCommission.SalesOrder__r.Sales_Price_Excluding_ADM__c != null && brokerCommission.SalesOrder__r.Sales_Price_Excluding_ADM__c > 0 ? (totalClearedAmount / brokerCommission.SalesOrder__r.Sales_Price_Excluding_ADM__c) * 100 : 0);
            totalCommissionPercentage = formatNumber(brokerCommission.CommissionSchedule__r.Percentage__c);

            admFeeString = 'AED '+formatNumber(brokerCommission.SalesOrder__r.ADMFeeWaivedAmount__c);
            netAmountString = 'AED '+formatNumber(brokerCommission.SalesOrder__r.NetAmount__c);
            unitPriceString = 'AED '+formatNumber(brokerCommission.SalesOrder__r.Sales_Price_Excluding_ADM__c);
            commissionAmountString = 'AED '+formatNumber(brokerCommission.CommissionAmount__c);
            taxAmountString = brokerCommission.TotalCommissionAmountWithVAT__c != null && brokerCommission.CommissionAmount__c != null ? 'AED '+formatNumber(brokerCommission.TotalCommissionAmountWithVAT__c - brokerCommission.CommissionAmount__c) : 'AED 0.00';
            typeOfPayment = brokerCommission.IsFullPayment__c ? FULL_PAYMENT_STRING : (brokerCommission.InstallmentLine__r.InstallmentNumber__c == 1) ? FIRST_COMMISSION_STRING : SECOND_COMMISSION_STRING;
            //Approvers Id set
            ApprovalProcessService approvalProcessObj = ApprovalProcessService.getInstance();
            List<ProcessInstanceNode> approvalNodesList = approvalProcessObj.getProcessInstanceNodsByRecordId(BrokerCommissionParamId, APPROVED_STR);

            approverList = new List<ApproverList>();
            for(ProcessInstanceNode node : getDisplayApprovalNodes(approvalNodesList)){
                approverList.add(new ApproverList(node.LastActor.Name,  node.LastActor.Title != null ? ' - '+node.LastActor.Title : '' , node.LastModifiedDate.format(DATE_FORMAT_STR)));
            }

        } catch (Exception ex) {
            System.debug('Exception: ' + ex.getMessage());
            System.debug('Line: ' + ex.getLineNumber());
        }       
    }

    private List<ProcessInstanceNode> getDisplayApprovalNodes(List<ProcessInstanceNode> nodes){
        List<ProcessInstanceNode> result = new List<ProcessInstanceNode>();

        if (nodes == null || nodes.isEmpty()) {
            return result;
        }

        Id firstProcessInstanceId = nodes[0].ProcessInstanceId;

        Set<String> firstProcessStepNames = new Set<String>();
        for (ProcessInstanceNode n : nodes) {
            if (n.ProcessInstanceId == firstProcessInstanceId) {
                firstProcessStepNames.add(n.ProcessNodeName);
            }
        }

        Boolean isOldFirstApproval = firstProcessStepNames.contains('Step 2');

        for (ProcessInstanceNode node : nodes) {
            if (isOldFirstApproval && node.ProcessInstanceId == firstProcessInstanceId && node.ProcessNodeName == 'Step 1') {
                continue;
            }
            result.add(node);
        }

        return result;
    }




     private String formatNumber(Decimal num) {
        if (num == null) {
            return '0.00';
        }

        String numberStr = num.setScale(2, RoundingMode.HALF_UP).format();
        if (!numberStr.contains('.')) numberStr += '.00';
        else if (numberStr.split('\\.')[1].length() == 1) numberStr += '0';
        return numberStr;
    }

    public class ApproverList {
        public String approverName { get;  set; }
        public String approverTitle { get;  set; }
        public String approvedDate { get;  set; }

        public ApproverList(String approverName, String approverTitle, String approvedDate) {
            this.approverName = approverName;
            this.approverTitle = approverTitle;
            this.approvedDate = approvedDate;
        }
    }
}