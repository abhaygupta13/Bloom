public class SlaProcessService {
     private SlaProcessService() {}
    
     public static SlaProcessService getInstance() {
        return new SlaProcessService();
    }
    
    
    //get SlaProcess by accountId
    public SlaProcess getSlaProcessByName(String slaName){
        if(String.isNotBlank(slaName)){
            return [SELECT Id, description, Name FROM SlaProcess WHERE Name = :slaName LIMIT 1];            
        } 
        return null;
    }

}