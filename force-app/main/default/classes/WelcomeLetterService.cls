public with sharing class WelcomeLetterService {
    
    public static WelcomeLetterWrapper getWelcomeLetter(Id leasingOrderId){
        
        LeasingOrder__c order = [
            SELECT
            Id,
            LeasingOrderNumber__c,
            
            Account__r.Name,
            Account__r.IsPersonAccount,
            
            Account__r.PersonMailingStreet,
            Account__r.PersonMailingCity,
            Account__r.PersonMailingState,
            Account__r.PersonMailingPostalCode,
            Account__r.PersonMailingCountry,
            
            Account__r.BillingStreet,
            Account__r.BillingCity,
            Account__r.BillingState,
            Account__r.BillingPostalCode,
            Account__r.BillingCountry,
            
            Project__r.Leasing_Company__r.Name,
            
            Unit__r.LeasingUnitNumber__c
            
            FROM LeasingOrder__c
            WHERE Id = :leasingOrderId
        ];
        
        WelcomeLetterWrapper wrapper = new WelcomeLetterWrapper();
        
        wrapper.todayDate = System.today();
        
        wrapper.accountName = order.Account__r.Name;
        
        wrapper.companyName = order.Project__r.Leasing_Company__r.Name;
        
        wrapper.unitNumber = order.Unit__r.LeasingUnitNumber__c;
        
        wrapper.referenceNumber =
            'LET/BR/ROD/' + order.LeasingOrderNumber__c;
        
        wrapper.leasingOrder = order;
        
        
        // ================= ADDRESS =================
        
        if(order.Account__r.IsPersonAccount){
            
            wrapper.address = buildAddress(
                order.Account__r.PersonMailingStreet,
                order.Account__r.PersonMailingState,
                order.Account__r.PersonMailingPostalCode,
                order.Account__r.PersonMailingCountry
            );
            
        }else{
            
            wrapper.address = buildAddress(
                order.Account__r.BillingStreet,
                order.Account__r.BillingState,
                order.Account__r.BillingPostalCode,
                order.Account__r.BillingCountry
            );
            
        }
        
        return wrapper;
        
    }
    
    
    // ================= BUILD ADDRESS =================
    
    private static String buildAddress(
        String street,
        String state,
        String postalCode,
        String country
    ){
        
        List<String> addressParts = new List<String>();
        
        if(String.isNotBlank(street)){
            addressParts.add(street);
        }
        
        
        
        if(String.isNotBlank(state)){
            addressParts.add(state);
        }
        
        if(String.isNotBlank(postalCode)){
            addressParts.add(postalCode);
        }
        
        if(String.isNotBlank(country)){
            addressParts.add(country);
        }
        
        return String.join(addressParts, '<br/>');
    }
    
}