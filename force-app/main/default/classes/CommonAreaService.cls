/*****************************************************************************************
Class       : CommonAreaService
Author      : Aman Bharti
Description : CommonArea Service Class
test Class  : CommonAreaServiceTest
Created Date: 16 JUN 2026
*****************************************************************************************/
public inherited sharing  class CommonAreaService {
    
    private static CommonAreaService instance;
    
    private CommonAreaService() {
    }
    
    public static CommonAreaService getInstance() { 
        if(instance == null) {
            instance = new CommonAreaService();
        }
        return instance;
    }

    public List<CommonArea__c> getCommonAreaByIds(Set<Id> commonAreaIds){
        return [SELECT Id, Name, Community__c FROM CommonArea__c WHERE Id IN :commonAreaIds];
    }
}