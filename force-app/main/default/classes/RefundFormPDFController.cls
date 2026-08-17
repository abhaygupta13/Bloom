/*****************************************************************************************
Class       : RefundFormPDFController
Author      : Kalpana
Description : Controller Class for Generate Refund Form Requiremenet.
Created Date: 20/07/26
*****************************************************************************************/
public with sharing class RefundFormPDFController {
    
    public RefundFormWrapper wrapper { get; private set; }
    
    public RefundFormPDFController() {
        
        Id leasingOrderId = ApexPages.currentPage().getParameters().get('id');
        
        if (leasingOrderId == null) {
            throw new AuraHandledException('Leasing Order Id is required.');
        }
        
        String notes = ApexPages.currentPage().getParameters().get('notes');
        
        Date waterElectricityDate;
        Date maintenanceCheckoutDate;
        
        String waterDate = ApexPages.currentPage().getParameters().get('waterDate');
        if (String.isNotBlank(waterDate)) {
            waterElectricityDate = Date.valueOf(waterDate);
        }
        
        String maintenanceDate = ApexPages.currentPage().getParameters().get('maintenanceDate');
        if (String.isNotBlank(maintenanceDate)) {
            maintenanceCheckoutDate = Date.valueOf(maintenanceDate);
        }
        
        wrapper = RefundFormService.getRefundForm(
            leasingOrderId,
            notes,
            waterElectricityDate,
            maintenanceCheckoutDate
        );
    }
}