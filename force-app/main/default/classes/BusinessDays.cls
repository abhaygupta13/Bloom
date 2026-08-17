/***
Class       : BusinessDays
Author      : Smaartt
Description : 
TestClass   : BusinessDaysTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              27/04/23           Initial Version 
****************************************************************************************************************/
      public class BusinessDays {
        
        public static List<DateTime> updateSLA(integer slatimeHrs){
          //  BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = true];
            
            List<DateTime>dateTimeList = new List<DateTime>();
            datetime localTime = dateTime.now().DateGmt();
            localTime = localTime.addHours(system.now().hourGmt());
            localTime = localTime.addMinutes(system.now().minuteGmt());
            localTime = localTime.addSeconds(system.now().secondGmt());
            
            system.debug('localTime ?????? '+ localTime);
            
            Decimal slaHours = decimal.valueOf(slatimeHrs);
            Long sla = slaHours.longValue();
            sla = sla * 60 * 60 * 1000L;
            DateTime dueDateTime = BusinessHours.addGMT(CustomLabelUtility.BusinessHoursID, localTime, sla);
            system.debug('dueDateTime >>>>>> ?????? '+ dueDateTime);
            dateTimeList.add(dueDateTime);
            System.debug('dateTimeList'+dateTimeList);
            return dateTimeList;
        }
        
        
    }