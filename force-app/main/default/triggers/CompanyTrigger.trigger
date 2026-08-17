trigger CompanyTrigger on Company__c (before insert, before update) {
    for (Company__c company : Trigger.new) {
        if (company.LeasingPostingClosureDate__c != null) {
            Date selectedDate = company.LeasingPostingClosureDate__c;

            Date lastDayOfMonth = Date.newInstance(
                selectedDate.year(),
                selectedDate.month(),
                1
            ).addMonths(1).addDays(-1);

            company.LeasingPostingClosureDate__c = lastDayOfMonth;
        }
    }
}