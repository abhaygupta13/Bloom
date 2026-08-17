/***
Class       : DuplicateRecordSetService
Author      : Biswajeet
Description : Duplicate Record Set service class
****************************************************************************************************************/
public class DuplicateRecordSetService {
    
    private static DuplicateRecordSetService instance;
    
    private DuplicateRecordSetService() {
        
    }
    
    public static DuplicateRecordSetService getInstance() { 
        if(instance == null) {
            instance = new DuplicateRecordSetService();
        }
        return instance;
    }
    
    public List<DuplicateRecordItem> getDuplicatItemsByDuplicateRecordSetIds(Set<Id> duplicateRecordSetIds){
        return [SELECT Id, RecordId, DuplicateRecordSetId FROM DuplicateRecordItem 
                WHERE DuplicateRecordSetId IN :duplicateRecordSetIds
                ORDER BY CreatedDate DESC];
        
    }
}