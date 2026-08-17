//============================ BCAPP_AmenityBookingService =============================
/*
* @Author : Eagles  
* @CreatedDate : 15 Jul 2025
* @Name : BCAPP_AmenityBookingService
* @Description : This APEX class used to handle all amentiy related Class
*/
/*****************************************************************************************************
* Version       Author                  Date             Comment                                                                       
* 1.0           Eagles               15 Jul 2024        Initial draft 
*****************************************************************************************************/

public without sharing class BCAPP_AmenityBookingService {
    
    /**
     * description    get list of amenities based on projectid as configured Amenities__c object
     * param         projecid
     * return        List of Amenities
   */

    public static void getAmenitiesByProject(Map<String, Object> jsonData ) {
        Map<String, Object> returnValue = new Map<String, Object>();
        List<Map<String, Object>> response = new List<Map<String, Object>>();
        UnitAllocationService uaService = new UnitAllocationService();
        try{
            BCAPP_Utility utilit_ref = BCAPP_Utility.getInstance();            
            String unitId = (String)jsonData.get('projectId');
            String accountId = (String)jsonData.get('accountId');
            String userType='';
            List<User__c> customer = utilit_ref.getUserbyAccountId(accountId);
            AmenityService aService = AmenityService.getInstance();    
            UnitService uService = UnitService.getInstance();
            if (customer == null || customer.isEmpty()) {
                returnValue.put('errorMessage', 'Invalid User');
                BCAPP_WebServiceHelper.makeServerErrorResponse(returnValue);
                return;
            }
            if(customer[0].User_Type__c!=null){
                userType = customer[0].User_Type__c;
            }
            List<Unit__c> unitRec =  UnitService.fetchUnitDetailsById(unitId);
            if (unitRec.isEmpty()) {
                returnValue.put('errorMessage', 'Invalid Unit');
                BCAPP_WebServiceHelper.makeServerErrorResponse(returnValue);
                return;
            }
           /* for(Unit_Allocation__c so_records : uaService.fetchUnitAllocationByUnitId(unitId)){
                if(so_records.Account__c!=accountId){
                    returnValue.put('errorMessage', 'You Can\'t book amenity if active tenant exist.' );
                    BCAPP_WebServiceHelper.makeServerErrorResponse(returnValue);
                    return;
                }
            }*/
            List<Amenities__c> amenities = aService.fetchAmenityByProjectId(unitRec[0].project__c,userType);
            for(Amenities__c amenity : amenities){
                Map<String, Object> data = new Map<String, Object>();
                data.put('Id', amenity.Id);
                data.put('name', amenity.Name);
                data.put('tc', amenity.termsAndConditions__c);
                data.put('type', amenity.Type__c);
                data.put('bookingFee', amenity.bookingFee__c);
                 data.put('isPaid', amenity.isPaid__c );
                response.add(data);
            }
            BCAPP_WebServiceHelper.makeSuccessResponse(response);
        }
        catch (Exception e) {
            returnValue.put('errorMessage', e.getMessage()); BCAPP_WebServiceHelper.makeServerErrorResponse(returnValue);
        }
    }
    
     /**
     * description   get amentiy available dates coming 15 days
     * param         amenityId
     * return        List of dates and reated month
   */
    
    public static void getAvailableDatesByMonth(Map<String, Object> jsonData) {
    Map<String, List<String>> monthDatesMap = new Map<String, List<String>>();
    
    Date today = Date.today();
    Integer daysAhead = 15;
    Date endDate = today.addDays(daysAhead);
    String amenityId = (String) jsonData.get('amenityId');
    AmenityMaintenanceService amenityMaintenanceService = AmenityMaintenanceService.getInstance();

    List<AmenityMaintenance__c> maintenances = amenityMaintenanceService.fetchMaintenanceDateRange(amenityId, endDate);
    
    for (Integer i = 0; i < daysAhead; i++) {
        Date currentDate = today.addDays(i);
        
        List<AmenityMaintenance__c> dayMaintenances = new List<AmenityMaintenance__c>();
        for (AmenityMaintenance__c m : maintenances) {
            if (m.maintenanceDate__c == currentDate) {
                dayMaintenances.add(m);
            }
        }
        
        Boolean isFullDayBlocked = false;
        for (AmenityMaintenance__c m : dayMaintenances) {
            if (m.startTime__c == null) {
                isFullDayBlocked = true;
                break;
            }
        }
        if (isFullDayBlocked) continue;
        
        String monthKey = Utility.getMonthYearLabel(currentDate);
        if (!monthDatesMap.containsKey(monthKey)) {
            monthDatesMap.put(monthKey, new List<String>());
        }
        monthDatesMap.get(monthKey).add(Utility.formatDayMonth(currentDate));
    }

    // Sort and convert to list of maps (desired format)
    List<String> sortedKeys = new List<String>(monthDatesMap.keySet());
    sortedKeys.sort();

    List<Map<String, List<String>>> finalList = new List<Map<String, List<String>>>();
    for (String key : sortedKeys) {
        Map<String, List<String>> entry = new Map<String, List<String>>();
        entry.put(key, monthDatesMap.get(key));
        finalList.add(entry);
    }

    // Respond with the new list format
    BCAPP_WebServiceHelper.makeSuccessResponse(finalList);
}

   
    /**
     * description   api service menthod to return available slots based on the selected amenity and selected date
     * param         amenityId, selectedDate
     * return        the available slots timings
   */
    public static String getSlotsForDate(Map<String, Object> jsonData, Boolean isFromSF) {
    List<Map<String, String>> slotList = new List<Map<String, String>>();
    BCAPP_Utility utilit_ref = BCAPP_Utility.getInstance();
    String amenityId = (String) jsonData.get('amenityId');
    String selectedDateInput = (String) jsonData.get('selectedDate');
    Date selectedDate = utilit_ref.parseDate(selectedDateInput);
    Integer slotDurationHours = (Integer) jsonData.get('slotDurationHours');
    Integer slotDurationMins;
    AmenityMaintenanceService amenityMaintenanceService = AmenityMaintenanceService.getInstance();
    AmenityService amenityService = AmenityService.getInstance();
    List<Amenities__c> amenity = amenityService.fetchAmenityById(amenityId);
    CaseService caseService = CaseService.getInstance();
    List<Case> dayBookings = caseService.getAmenityBookingsByDate(selectedDate, amenityId);
    List<AmenityMaintenance__c> dayMaintenances = amenityMaintenanceService.fetchMaintenanceDateRange(amenityId, selectedDate);
    // Full day maintenance check
    for (AmenityMaintenance__c m : dayMaintenances) {
        if (m.startTime__c == null) {
            if (!isFromSF) { BCAPP_WebServiceHelper.makeSuccessResponse(slotList);}
            return JSON.serialize(slotList);
        }
    }
	
    Time slotStart = amenity[0].dailyStartTime__c;
    Time slotEnd = amenity[0].dailyEndTime__c;

    if (slotDurationHours != null) {
        slotDurationMins = slotDurationHours * 60;
    } else {
        slotDurationMins = amenity[0].slotDurationInMinutes__c != null ? (Integer) amenity[0].slotDurationInMinutes__c : 60;
    }

    // Get current date and time (considering org timezone)
    Date todayDate = Date.today();
    Time nowTime =  DateTime.now().time();

    Boolean isToday = selectedDate == todayDate;

    while (slotStart.addMinutes(slotDurationMins) <= slotEnd) {
        Time slotFinish = slotStart.addMinutes(slotDurationMins);
        Boolean isBlocked = false;
        // If selected date is today, skip slots that start before or equal current time
        if (isToday && slotStart <= nowTime) {slotStart = slotStart.addMinutes(slotDurationMins); continue;
        }

        // Check booking overlaps
        for (Case b : dayBookings) {
            if (!(slotFinish <= b.startTime__c || slotStart >= b.endTime__c)) {isBlocked = true; break;
            }
        }

        // Check maintenance overlaps
        if (!isBlocked) {
            for (AmenityMaintenance__c m : dayMaintenances) {
                
                if (m.startTime__c != null && m.durationHours__c != null) {
                    Time maintEnd = m.startTime__c.addMinutes(m.durationHours__c.intValue() * 60);
                    if (!(slotFinish <= m.startTime__c || slotStart >= maintEnd)) { isBlocked = true; break;
                    }
                }
            }
        }

        if (!isBlocked) {
            slotList.add(new Map<String, String>{
                'end' => Utility.formatTimeHHmm(slotFinish),
                'start' => Utility.formatTimeHHmm(slotStart)
            });
        }

        slotStart = slotStart.addMinutes(slotDurationMins);
    }

    if (!isFromSF) {
        BCAPP_WebServiceHelper.makeSuccessResponse(slotList);
    }

    return JSON.serialize(slotList);
}

    
    public static void validateAminities( Map<String, Object> jsonData) {
        Map<String, Object> result = new Map<String, Object>();
        // Extract fields
        String amenityId    = (String) jsonData.get('amenityId');
        String bookingDate  = (String) jsonData.get('bookingDate');
        String bookingTime  = (String) jsonData.get('bookingTime');
        String accountId    = (String) jsonData.get('accountId');
        String unitId    = (String) jsonData.get('unitId');
        String paymentId    = (String) jsonData.get('referenceId');
        
		CaseService caseService = CaseService.getInstance();
        Unit__c unit = UnitService.fetchUnitDetailsById(unitId)[0];
        if (unit.Legal_Status__c == 'With Legal') {
                result.put('isEligible', false);
                result.put('errorMessage', 'Unit is legally blocked. Cannot process request.');
                BCAPP_WebServiceHelper.makeSuccessResponse(result);
                return;
        }
        BCAPP_Utility utilit_ref = BCAPP_Utility.getInstance();
        Date selectedDate = utilit_ref.parseDate(bookingDate);
       
        List<Case> existingByUser = caseService.checkServicesByAccount(accountId,selectedDate);
        if (existingByUser.size() >= 2) {
            result.put('isEligible', false);result.put('errorMessage', 'You have already booked maximum number requests on this date.'); BCAPP_WebServiceHelper.makeServerErrorResponse(result);
            return;
        }
        result.put('isEligible', true);
        result.put('message', 'User is eligible this feature');
        BCAPP_WebServiceHelper.makeSuccessResponse(result);
        return;
        
    }
    
    /**
     * description   api service menthod to book the slot, create case record with amenity details
     * param         amenityId, bookingTime,bookingDate,accountId and unitId
     * return        case number
   */
    
    public static String bookAmenitySlot( Map<String, Object> jsonData,Boolean isUnpaidFromSF) {
        Map<String, Object> result = new Map<String, Object>();
        
        // Extract fields
        String amenityId    = (String) jsonData.get('amenityId');
        String bookingDate  = (String) jsonData.get('bookingDate');
        String bookingTime  = (String) jsonData.get('bookingTime');
        String accountId    = (String) jsonData.get('accountId');
        String unitId    = (String) jsonData.get('unitId');
        String paymentId    = (String) jsonData.get('referenceId');
        
        Integer duration = 0;
        Date selectedDate;
        Time selectedTime;
        CaseService caseService = CaseService.getInstance();
        AmenityService aService = AmenityService.getInstance();
        BCAPP_Utility utilit_ref = BCAPP_Utility.getInstance();
        List<Amenities__c> amenity = aService.fetchAmenityById(amenityId);
        ServiceCatalogService scService = ServiceCatalogService.getInstance();
        // Validation
        if (String.isBlank(amenityId) || String.isBlank(bookingDate) || String.isBlank(bookingTime)) {
            result.put('errorMessage', 'Amenity ID, Booking Date, and Booking Time are required.');if(!isUnpaidFromSF){BCAPP_WebServiceHelper.makeServerErrorResponse(result);}
            return JSON.serialize(result);
            
            
        }
        if(jsonData.containsKey('slotDurationHours') && jsonData.get('slotDurationHours')!=null){
            duration= (Integer) jsonData.get('slotDurationHours')==0?1:(Integer) jsonData.get('slotDurationHours');
        }
        else{
           
            if(!amenity.isEmpty()){
                duration =amenity[0].slotDurationInMinutes__c!=null?((Integer)amenity[0].slotDurationInMinutes__c)/60:1;
            }
        }
        
        try {
            selectedDate = utilit_ref.parseDate(bookingDate);
            selectedTime = utilit_ref.parseFormattedTime(bookingTime);
        } catch (Exception e) {
            result.put('errorMessage', 'Invalid date or time format.');if(!isUnpaidFromSF){BCAPP_WebServiceHelper.makeServerErrorResponse(result);} return JSON.serialize(result);
        }
        
        // Check for existing booking
        List<Case> existing = caseService.fetchAmenitySlotExist(amenityId,selectedDate,selectedTime);
        List<Case> existingByUser = caseService.checkServicesByAccount(accountId,selectedDate);
        if (existingByUser.size() >= 2) {
            result.put('errorMessage', 'You have already booked maximum number requests on this date.');
            if(!isUnpaidFromSF){
                BCAPP_WebServiceHelper.makeServerErrorResponse(result);
            }
            return JSON.serialize(result);
        }
        if (!existing.isEmpty()) {
            result.put('errorMessage', 'The selected slot is already booked.');
            if(!isUnpaidFromSF){
                BCAPP_WebServiceHelper.makeServerErrorResponse(result);
            }
            return JSON.serialize(result);
        }
        List<Service_Catalog__c> sc = ServiceCatalogService.fetchServiceCatalogByName(BCAPP_Constants.AMENITIES);
        List<User__c> customer = utilit_ref.getUserbyAccountId(accountId);
        List<Unit__c> units = UnitService.fetchUnitDetailsById(unitId);
        if(customer.isEmpty()){
             if (!existing.isEmpty()) {
           	 	result.put('errorMessage', 'Invalid Account.');
            	BCAPP_WebServiceHelper.makeServerErrorResponse(result);
        	}
        }
        // --- Payment validation (only if amenity is paid and not admin-unpaid flow) ---
        if (amenity[0].isPaid__c && !isUnpaidFromSF) {
            if (String.isBlank(paymentId)) {
                result.put('errorMessage', 'Missing payment reference.');
                if (!isUnpaidFromSF) { BCAPP_WebServiceHelper.makeServerErrorResponse(result); }
                return JSON.serialize(result);
            }else{
                    OnlinePaymentLineItemService opliService = OnlinePaymentLineItemService.getInstance();
                	paymentId = BCAPP_Utility.decryptId(paymentId);
                    List<OnlinePaymentLineItem__c> opl = opliService.getOnlinePaymentLineItemsByPaymentId(paymentId);
                    OnlinePaymentService opService = OnlinePaymentService.getInstance();
                    OnlinePayment__c op = opService.getPaymentById(paymentId);
                    if(opl.isEmpty()){
                        result.put('errorMessage', 'Missing payment reference.');
                        BCAPP_WebServiceHelper.makeServerErrorResponse(result);
                        return JSON.serialize(result);
                    }else{
                        if(!String.isBlank(opl[0].Case__c) || opl[0].Case__c != null || op.Status__c != 'Success'){
                            result.put('errorMessage', 'Missing payment reference.');
                            BCAPP_WebServiceHelper.makeServerErrorResponse(result);
                        	return JSON.serialize(result);
                        }
                    }
            }
            
            // Fetch OnlinePayment header via service (not inline SOQL)
            OnlinePaymentService paySvc = OnlinePaymentService.getInstance();
            OnlinePayment__c pay = paySvc.getPaymentById(paymentId);
            
            if (pay == null) {
                result.put('errorMessage', 'Invalid payment reference.');
                if (!isUnpaidFromSF) { BCAPP_WebServiceHelper.makeServerErrorResponse(result); }
                return JSON.serialize(result);
            }
            
            // 1) Status must be 'Success'
            if (String.valueOf(pay.Status__c) != 'Success') {
                result.put('errorMessage', 'Payment is not completed. Status: ' + String.valueOf(pay.Status__c));
                if (!isUnpaidFromSF) { BCAPP_WebServiceHelper.makeServerErrorResponse(result); }
                return JSON.serialize(result);
            }
            
            // 2) Amount must match the Amenity booking fee
            // NOTE: replace pay.Amount__c if your header field is named differently
            Decimal expected = (amenity[0].bookingFee__c == null ? 0 : amenity[0].bookingFee__c.setScale(2));
            //expected+= expected * 0.0125;
            Decimal paid     = (pay.PaidAmount__c == null ? 0 : pay.PaidAmount__c.setScale(2));
            
            if (expected.setScale(2,RoundingMode.HALF_UP) != paid) {
                result.put('errorMessage',
                           'Payment amount mismatch. Expected ' + String.valueOf(expected) +
                           ', received ' + String.valueOf(paid) + '.');
                if (!isUnpaidFromSF) { BCAPP_WebServiceHelper.makeServerErrorResponse(result); }
                return JSON.serialize(result);
            }
        }
        // --- end payment validation ---
        
        // Create booking record
        Case booking = new Case(
            Amenities__c   = amenityId,
            project__c = units[0].project__c,
            Permit_From_Date__c   = selectedDate,
            startTime__c    = selectedTime,
            endTime__c     = selectedTime.addSeconds(duration * 60 * 60),
            durationInMinutes__c = duration,
            AccountId        = accountId,
            recordTypeId = Utilities.getRecordTypeId('Case','Community General Service Request'),
            Unit__c  = unitId,
            Service_Catalog__c = sc[0].Id,
            Origin = (isUnpaidFromSF?'Admin':'Community APP'),
            User_Type__c = customer[0].User_Type__c,
            Status = (amenity[0].isPaid__c || isUnpaidFromSF) ? 'Confirmed' : 'Submitted'
        );
        if(jsonData.containsKey('description')){
            booking.Description  = (String) jsonData.get('description');    
        }
        if(jsonData.containsKey('music')){
             booking.MusicRequired__c = (Boolean) jsonData.get('music'); 
        }
        if(jsonData.containsKey('serveFandB')){
           booking.serveFandB__c = (Boolean) jsonData.get('serveFandB');       
        }
        if(jsonData.containsKey('noOfGuests')){
           booking.numberOfGuests__c =  (Decimal) jsonData.get('noOfGuests');     
        }
        try {
            booking = caseService.insertCase(booking);
            attachCaseIdtoPayment(booking.Id,paymentId);
            Case ar = caseService.getCaseById(booking.Id);
            result.put('success', true); 
            result.put('message', 'Slot booked successfully.');
            result.put('bookingNumber', ar.caseNumber); 
            result.put('bookingId', ar.Id); 
            if(!isUnpaidFromSF){
                BCAPP_WebServiceHelper.makeSuccessResponse(result);
            }
            return JSON.serialize(result);
        } catch (Exception e) {
            result.put('success', false); result.put('errorMessage', 'Failed to book slot: ' + e.getMessage());
            if(!isUnpaidFromSF){BCAPP_WebServiceHelper.makeSuccessResponse(result);}
            return JSON.serialize(result);
        }
    }
    
    public static void attachCaseIdtoPayment(String caseId, String paymentId){
        List<OnlinePaymentLineItem__c> oltColl = new List<OnlinePaymentLineItem__c> ();
        OnlinePaymentLineItemService opliService = OnlinePaymentLineItemService.getInstance();
        for(OnlinePaymentLineItem__c olt :opliService.getOnlinePaymentLineItemsByPaymentId(paymentId)){
            olt.Case__c = caseId;
            oltColl.add(olt);
        }
        if(!oltColl.IsEmpty()){opliService.updateonlinePaymentLineItems(oltColl);}
       
    }
    public static void cancelBlloking( Map<String, Object> jsonData) {
        Map<String, Object> result = new Map<String, Object>();
        CaseService caseService = CaseService.getInstance();
        // Extract fields
        String bookingId    = (String) jsonData.get('bookingId');
         String reason    = (String) jsonData.get('reason');
        // Validation
        if (String.isBlank(bookingId) ) {
            result.put('errorMessage', 'Amenity ID, Booking Date, and Booking Time are required.');BCAPP_WebServiceHelper.makeServerErrorResponse(result);return;
        }
       
        // cancel booking record
        Case booking = new Case(
            Id       = bookingId,
            Comments    = reason,
            Status = 'Cancelled'
        );
        
        try {
            caseService.updateCase(booking);
            result.put('success', true); 
            result.put('message', 'Slot Cancelled successfully.');
           
            BCAPP_WebServiceHelper.makeSuccessResponse(result);
        } catch (Exception e) {result.put('success', false); result.put('errorMessage', 'Failed to book slot: ' + e.getMessage());BCAPP_WebServiceHelper.makeServerErrorResponse(result);
        }
    }
    
    public static void getAmenityBookings(Map<String, Object> jsonData ) {
        Map<String, Object> returnValue = new Map<String, Object>();
        List<Map<String, Object>> response = new List<Map<String, Object>>();
        try{
            BCAPP_Utility utilit_ref = BCAPP_Utility.getInstance();            
            String accountId = (String) jsonData.get('accountId');
            Boolean upcomingOnly = ((String) jsonData.get('type')=='upcoming')?true:false;
            CaseService caseService = CaseService.getInstance();  
        	//Date TODAY = system.today();
        	
            List<Case> lstCases = caseService.fetchAmenityByAccount(accountId,upcomingOnly);
            for(Case ab : lstCases){
                if(ab.Permit_From_Date__c==null || ab.startTime__c==null){
                    continue;
                }
                DateTime permitDateTime = DateTime.newInstance(ab.Permit_From_Date__c, ab.startTime__c);
                if(!upcomingOnly || permitDateTime >= DateTime.now()){
                    Date bDate = ab.Permit_From_Date__c;
                    String formattedbDate ;
                    if (bDate != null) {
                        DateTime myDateTime = DateTime.newInstance(bDate, Time.newInstance(0, 0, 0, 0));
                        formattedbDate = myDateTime.format('dd MMM yyyy');
                    }
                    Map<String, Object> data = new Map<String, Object>();
                    data.put('amenityName', ab.Amenities__r.Name);
                    data.put('bookingName', ab.caseNumber);
                    data.put('bookingId', ab.Id);
                    data.put('bookingDate', formattedbDate);
                    data.put('startTime', Utility.formatTimeHHmm(ab.startTime__c));
                    data.put('endTime', Utility.formatTimeHHmm(ab.endTime__c));
                    data.put('isPaid', ab.Amenities__r.isPaid__c);
                    data.put('status', ab.Status);
                    response.add(data);
                }
            } 
            BCAPP_WebServiceHelper.makeSuccessResponse(response);
        }
        catch (Exception e) {returnValue.put('errorMessage', e.getMessage()+e.getLineNumber());BCAPP_WebServiceHelper.makeServerErrorResponse(returnValue);
        }
    }
}