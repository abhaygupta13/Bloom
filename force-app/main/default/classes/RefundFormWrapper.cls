/*****************************************************************************************
Class       : RefundFormWrapper
Author      : Kalpana
Description : Wrapper for Generate Refund Form Requiremenet.
Created Date: 20/07/26
*****************************************************************************************/
public class RefundFormWrapper {
    
    public Date todayDate {get;set;}
    
    public String propertyName {get;set;}
    
    public String unitType {get;set;}
    
    public String unitName {get;set;}
    
    public String leasingCompanyName {get;set;}
    
    public String tenantName {get;set;}
    
    public String occupantName {get;set;}
    
    public String sapCompanyCode {get;set;}
    
    public String tenancyContractNo {get;set;}
    
    public Decimal annualRent {get;set;}
    
    public Date leasingStartDate {get;set;}
    
    public Date leasingEndDate {get;set;}
    
    public Date terminationDate {get;set;}
    
    public Integer additionalDays {get;set;}
    
    public Decimal valueOfDays {get;set;}
    
    public Decimal breakLeasePenalty {get;set;}
    
    public Decimal balancePayment {get;set;}
    
    public Decimal adminFees {get;set;}
    
    public Decimal maintenanceCharges {get;set;}
    
    public Decimal securityDeposit {get;set;}
    
    public Decimal dueAmount {get;set;}
    
    public Decimal totalPDCReturn {get;set;}
    
    public String preparedBy {get;set;}
    
    public String notes {get;set;}
    
    public String paidInFull {get;set;}
    
    public String rentDifference {get;set;}
    
    public String rvNumber {get;set;}
    
    public Date waterElectricityDate {get;set;}
    
    public Date maintenanceCheckoutDate {get;set;}
    
    public List<AttachmentRow> attachments {get;set;}
    
    public List<PDCRow> pdcRows {get;set;}
    
    public RefundFormWrapper(){
        
        attachments = new List<AttachmentRow>();
        
        pdcRows = new List<PDCRow>();
        
        todayDate = System.today();
        
        additionalDays = 0;
        
        valueOfDays = 0;
        
        breakLeasePenalty = 0;
        
        balancePayment = 0;
        
        adminFees = 0;
        
        maintenanceCharges = 0;
        
        securityDeposit = 0;
        
        dueAmount = 0;
        
        totalPDCReturn = 0;
        
        paidInFull = '';
        
        rentDifference = '';
        
        rvNumber = '';
        
    }
    
    public class PDCRow{
        
        public Integer serialNo {get;set;}
        
        public String chequeNo {get;set;}
        
        public Date dueDate {get;set;}
        
        public Decimal amount {get;set;}
        
    }
    
    public class AttachmentRow {
        
        public String documentName {get;set;}
        
        public Boolean available {get;set;}
        
        public Date documentDate {get;set;}
        
        public String corNumber {get;set;}
        
        public Date corDate {get;set;}
        public Boolean getUnavailable() {
            return !available;
        }
        public Boolean getHasDocumentDate() {
            return documentDate != null;
        }
        public Boolean getHasCorDate() {
            return corDate != null;
        }
        
    }
    
    public Boolean getHasPDCRows() {
        return pdcRows != null && !pdcRows.isEmpty();
    }
    
}