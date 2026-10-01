@IsTest
public class SobjectBatchTest {

    public class TestSobjectBatch extends SobjectBatch {
        public TestSobjectBatch() {
            super();
        }

        public TestSobjectBatch(String query, Map<SObjectField, Object> fieldValueMap) {
            super(query, fieldValueMap);
        }
    }

    @TestSetup
    static void setupData() {
        insert new Account(Name = 'Test Account');
    }

    @IsTest
    static void testDefaultConstructor() {
        TestSobjectBatch batch = new TestSobjectBatch();
    }


    @IsTest
    public static void testStartExecuteAndFinish() {
        String query = 'SELECT Id, Name FROM Account';
        SObjectField nameField = Schema.Account.Name;
        Map<SObjectField, Object> fieldValueMap = new Map<SObjectField, Object>{
            nameField => 'Direct Update'
        };
		
        Test.startTest();
        SobjectBatch batch = new SobjectBatch(query, fieldValueMap);
        Database.executeBatch(batch, 200);
        Test.stopTest();
    }

    @IsTest
    static void testPerformAction() {
        Account account = [SELECT Id, Name FROM Account LIMIT 1];
		SObjectField nameField = Schema.Account.Name;
        Map<SObjectField, Object> fieldValueMap = new Map<SObjectField, Object>{
            nameField => 'Perform Action Update'
        };

        TestSobjectBatch batch = new TestSobjectBatch(
            'SELECT Id, Name FROM Account',
            fieldValueMap
        );

        Test.startTest();
        batch.performAction(new List<SObject>{account}, null);
        Test.stopTest();

        account = [SELECT Id, Name FROM Account LIMIT 1];

        System.assertEquals('Perform Action Update', account.Name);
    }

    @IsTest
    static void testPerformFinish() {
        TestSobjectBatch batch = new TestSobjectBatch(
            'SELECT Id FROM Account',
            new Map<SObjectField, Object>()
        );

        Test.startTest();
        batch.performFinish(null);
        Test.stopTest();

        System.assert(true);
    }
}