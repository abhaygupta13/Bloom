/*
* @Author: Shruti Kulkarni
* @CreatedDate: 11th Aug 2025
* @Description: Class created to build and utilize the generic INVOCABLE methods which needs to be called from Flow
*/
/*******************************************************************************************************************
* Version       Author      	   Date             Comment                                                                       
* 1.1           Shruti Kulkarni    11th AUG 2025    Initial Draft
********************************************************************************************************************/
public class FlowInvocableMethodController {

	/**
     * Calculate Escalation date based on current date - Broker Portal Implementation
     */
    @InvocableMethod(label='Calculate Escalation Date')
    public static List<EscalationDetailsWrapper> calculateEscalationDate(List<InputWrapper> inputs) {
       // Fetch the business hours ID (default)
        List<BusinessHours> bhList = BusinessHoursService.getInstance().getBusinessHoursByName('BloomBrokerBusinessHours'); 
        List<EscalationDetailsWrapper> results = new List<EscalationDetailsWrapper>();
        for (InputWrapper input : inputs) {
            EscalationDetailsWrapper result = new EscalationDetailsWrapper();
            if(!bhList.isEmpty()) {        
                // Convert hours to milliseconds
                Long millisecondsToAdd = (Long)(input.escalationTenure * 60 * 60 * 1000);
    
                // Add time considering business hours
                // Get current time in user's timezone
                Datetime nowUtc = System.now();
                Integer offsetMillis = UserInfo.getTimeZone().getOffset(nowUtc);
                Datetime userLocalTime = nowUtc.addSeconds(offsetMillis / 1000);
                
                result.escalationDate = BusinessHours.add(bhList[0].Id, userLocalTime, millisecondsToAdd);
                results.add(result);
            }
        }
        return results;
    }

    public class InputWrapper {
        @InvocableVariable(label='Escalation Tenure')
        public Integer escalationTenure;
    }

    public class EscalationDetailsWrapper {
        @InvocableVariable(label='Escalation Date')
        public DateTime escalationDate;
    }
}