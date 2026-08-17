/*
* @Author:  Prashant Sahu
* @CreatedDate: 16 Mar 2026
* @Description: Utility
*/
/***************************************************************************************************** 
* Version       Author           Date          Comment                                          METHOD Name
* 1.0           Prashant Sahu    16 Mar 2026   Runtime SLA Calculation using Business Hours    calculateSlaPercentage
*****************************************************************************************************/
public class TaskController {
    @AuraEnabled(cacheable=true)
    public static Decimal calculateSlaPercentage(Id taskId){
        Task tsk = [ SELECT Id, AssignedDateTime__c, CompletedDateTime, BusinessHours__c, SLAHours__c FROM Task WHERE Id = :taskId LIMIT 1 ];
        if(tsk.AssignedDateTime__c == null || tsk.SLAHours__c == null){
            return 0;
        }
        Id defaultBHId = MetadataService.getInstance().getAppSettingTextValue('DefaultBusinessHoursId');
        Id businessHoursId = tsk.BusinessHours__c != null ? tsk.BusinessHours__c : defaultBHId;
        Datetime endTime = tsk.CompletedDateTime != null ? tsk.CompletedDateTime : System.now();
        Datetime slaEndTime = BusinessHours.add( businessHoursId, tsk.AssignedDateTime__c, (Long) (tsk.SLAHours__c * 60 * 60 * 1000) );
        Long usedMillis = BusinessHours.diff( businessHoursId, tsk.AssignedDateTime__c, endTime );
        Long totalMillis = BusinessHours.diff( businessHoursId, tsk.AssignedDateTime__c, slaEndTime );
        if(totalMillis <= 0){
            return 100;
        }
        Decimal percent = (totalMillis > 0) ? Math.min((Decimal.valueOf(usedMillis) / Decimal.valueOf(totalMillis)) * 100, 100): 0;
        return percent;
    }
}