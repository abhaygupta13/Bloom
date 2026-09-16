/**
 * AccessCardService
 * SOQL/selectors for AccessCard__c, singleton pattern.
 * No business logic here.
 */
public without sharing class AccessCardService {
    private static AccessCardService inst;
    public static AccessCardService getInstance() {
        if (inst == null) inst = new AccessCardService();
        return inst;
    }
    private AccessCardService() {}

    /** Count active cards for a given Account + Unit. */
    public Integer countActiveByAccountUnit(Id accountId, Id unitId) {
        return [SELECT COUNT()
                FROM AccessCard__c
                WHERE Account__c = :accountId
                  AND Unit__c    = :unitId
                  AND Status__c  = 'Activated'];
    }

    /** Return the list of ACTIVE cards by card numbers (filter by Status__c = Activated). */
    public List<AccessCard__c> getActivatedByNumbers(Set<String> numbers) {
        if (numbers == null || numbers.isEmpty()) return new List<AccessCard__c>();
        return [
            SELECT Id, CardNumber__c, Unit__c, Account__c, Status__c, CardType__c, UserType__c
            FROM AccessCard__c
            WHERE CardNumber__c IN :numbers
              AND Status__c = 'Activated'
        ];
    }

    /** Return any cards by numbers (no status filter) – useful to derive userType/card types when needed. */
    public List<AccessCard__c> getByNumbers(Set<String> numbers) {
        if (numbers == null || numbers.isEmpty()) return new List<AccessCard__c>();
        return [
            SELECT Id, CardNumber__c, Unit__c, Account__c, Status__c, CardType__c, UserType__c
            FROM AccessCard__c
            WHERE CardNumber__c IN :numbers
        ];
    }

    /** Return active cards for account+unit (used by handleGetAccessCards). */
    public List<AccessCard__c> getActiveByAccountUnit(Id accountId, Id unitId) {
        return [
            SELECT Id, CardNumber__c, CardType__c, UserType__c, ResidentName__c, Status__c
            FROM AccessCard__c
            WHERE Account__c = :accountId
              AND Unit__c    = :unitId
              AND Status__c  = 'Activated'
        ];
    }

    /** Get distinct card types for a set of numbers. */
    public Set<String> getCardTypesByNumbers(Set<String> numbers) {
        Set<String> types = new Set<String>();
        if (numbers == null || numbers.isEmpty()) return types;
        for (AccessCard__c c : [
            SELECT CardType__c
            FROM AccessCard__c
            WHERE CardNumber__c IN :numbers
        ]) {
            if (String.isNotBlank(c.CardType__c)) types.add(c.CardType__c);
        }
        return types;
    }
}