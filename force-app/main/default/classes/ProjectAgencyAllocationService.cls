/*
* @Author        : Rushikesh Jadhav
* @CreatedDate   : 22th SEP 2025
* @Description   : Service class for fetching project allocations for a broker account. 
*                  Provides methods to retrieve active project allocations and assigned project IDs
*                  based on unit allocations.
*/
/*****************************************************************************************************
* Version       Author        Date             Comment                                                                       
* 1.0           Rushikesh     22-SEP-2025      Initial draft to handle project allocation retrieval for broker accounts
*****************************************************************************************************/

public class ProjectAgencyAllocationService {

    // Singleton instance
    private static ProjectAgencyAllocationService instance;

    // Private constructor
    private ProjectAgencyAllocationService() {}

    // Public method to get the singleton instance
    public static ProjectAgencyAllocationService getInstance() {
        if (instance == null) {
            instance = new ProjectAgencyAllocationService();
        }
        return instance;
    }

    // Get all allocations for the account (only active ones)
    public List<ProjectAgencyAllocation__c> getAllocationsByAccount(Id accountId) {
        if (String.isBlank(accountId)) return new List<ProjectAgencyAllocation__c>();
        return [
            SELECT Project__c,Project__r.Id, Project__r.Name
            FROM ProjectAgencyAllocation__c
            WHERE Account__c = :accountId AND IsActive__c = true AND Project__r.IsActive__c = true
            AND Project__r.IsAvailableForBroker__c = true
              
        ];
    }

}