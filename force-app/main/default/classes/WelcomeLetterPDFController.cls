public with sharing class WelcomeLetterPDFController {
    
    public WelcomeLetterWrapper wrapper { get; set; }
    
    public WelcomeLetterPDFController() {
        
        Id leasingOrderId = ApexPages.currentPage().getParameters().get('id');
        
        if (leasingOrderId != null) {
            wrapper = WelcomeLetterService.getWelcomeLetter(leasingOrderId);
        } else {
            wrapper = new WelcomeLetterWrapper();
        }
    }
    
    public String getFormattedTodayDate() {
        
        if (wrapper == null || wrapper.todayDate == null) {
            return '';
        }
        
        List<String> months = new List<String>{
            'January','February','March','April','May','June',
                'July','August','September','October','November','December'
                };
                    
                    Date d = wrapper.todayDate;
        
        return d.day() + ' ' +
            months[d.month() - 1] + ' ' +
            d.year();
    }
    
    public String getAccountName() {
        return wrapper.accountName;
    }
    
    public String getAccountFirstName() {
        return wrapper.accountFirstName;
    }
    
    public String getCompanyName() {
        return wrapper.companyName;
    }
    
    public String getUnitNumber() {
        return wrapper.unitNumber;
    }
    
    public String getReferenceNumber() {
        return wrapper.referenceNumber;
    }
    
    public String getAddress() {
        return wrapper.address;
    }
}