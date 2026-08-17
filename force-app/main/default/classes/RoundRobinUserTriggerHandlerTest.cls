@isTest
public class RoundRobinUserTriggerHandlerTest {
    @isTest static void RoundRobinUserTriggerHandlerTestMethod(){
        
        Round_Robins__c rr=new Round_Robins__c(
        	Name='Sales Manager',
            Assigned_To__c = '1',
            Sobject__c='Lead'
        );
        insert rr;
        
        Round_Robin_User__c rrUser=new Round_Robin_User__c(
        	Name='Hani Zaki Al Bakri -  SM',
            Round_Robin__c=rr.Id
        );
        
        insert rrUser;
        List<Round_Robin_User__c> rruList= new List<Round_Robin_User__c>();
        rruList.add(rrUser);
        map<id,Round_Robin_User__c> rruMap=new map<id,Round_Robin_User__c>();
        rruMap.put(rrUser.id, rrUser);
        RoundRobinUserTriggerHelper.updateRoundRobinId(rruList);
        RoundRobinUserTriggerHelper.updateRoundRobinId_delete(rruMap);
        
        delete rrUser;
    }
}