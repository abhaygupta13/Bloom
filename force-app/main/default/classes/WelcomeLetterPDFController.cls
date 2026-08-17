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
    
    public String getTodayDate() {
        
        if (wrapper == null || wrapper.todayDate == null) {
            return '';
        }
        
        List<String> months = new List<String>{
            'January','February','March','April','May','June',
                'July','August','September','October','November','December'
                };
                    
                    Date d = wrapper.todayDate;
        
        Integer day = d.day();
        String suffix;
        
        if (day >= 11 && day <= 13) {
            suffix = 'th';
        } else {
            Integer lastDigit = Math.mod(day, 10);
            
            if (lastDigit == 1) {
                suffix = 'st';
            } else if (lastDigit == 2) {
                suffix = 'nd';
            } else if (lastDigit == 3) {
                suffix = 'rd';
            } else {
                suffix = 'th';
            }
        }
        
        return day + suffix + ' ' +
            months[d.month() - 1] + ' ' +
            d.year();
    }
    public String getTodayDay() {
        
        if (wrapper == null || wrapper.todayDate == null) {
            return '';
        }
        
        return String.valueOf(wrapper.todayDate.day());
    }
    public String getTodaySuffix() {
        
        if (wrapper == null || wrapper.todayDate == null) {
            return '';
        }
        
        Integer day = wrapper.todayDate.day();
        
        if (day >= 11 && day <= 13) {
            return 'th';
        }
        
        Integer lastDigit = Math.mod(day, 10);
        
        if (lastDigit == 1) {
            return 'st';
        } else if (lastDigit == 2) {
            return 'nd';
        } else if (lastDigit == 3) {
            return 'rd';
        } else {
            return 'th';
        }
    }
    public String getTodayMonthYear() {
        
        if (wrapper == null || wrapper.todayDate == null) {
            return '';
        }
        
        List<String> months = new List<String>{
            'January','February','March','April','May','June',
                'July','August','September','October','November','December'
                };
                    
                    Date d = wrapper.todayDate;
        
        return months[d.month() - 1] + ' ' + d.year();
    }
    
    public String getAccountName() {
        return wrapper.accountName;
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