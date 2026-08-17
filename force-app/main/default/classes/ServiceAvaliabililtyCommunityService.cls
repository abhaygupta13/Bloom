public class ServiceAvaliabililtyCommunityService {
    
    public static List<Service_Availability_Community__c> getAvailableCommunity(String projectId,String srId){
        
        return  [select Service_Catolog_Documents__c,Required_For__c, Is_Document_Required__c   from Service_Availability_Community__c  where project__c=:projectId and Service_Catalog__c=:srId ];
    }
    

}