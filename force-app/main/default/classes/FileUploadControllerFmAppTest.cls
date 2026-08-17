@isTest
public class FileUploadControllerFmAppTest {
    
    @testSetup
    public static void setupTestData() {
        Account accountRecord = new Account(Name = 'Test Account');
        insert accountRecord;

        Contact cntRecord = new Contact(FirstName = 'John', LastName = 'Doe', Email = 'johndoe@test.com', AccountId = accountRecord.Id);
        insert cntRecord;
    }

    @isTest
    public static void testUploadFileToSite() {
        Account accountRecord = [SELECT Id FROM Account LIMIT 1];
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test file content'));

        Test.startTest();
        Boolean result = FileUploadControllerFmApp.uploadFileToSite('testfile.txt', base64Data, accountRecord.Id);
        Test.stopTest();
    }

    @isTest
    public static void testUploadFileToSite_invalidBase64() {
        Account accountRecord = [SELECT Id FROM Account LIMIT 1];
        String invalidBase64Data = 'invalidbase64data';

        Test.startTest();
        Boolean result = FileUploadControllerFmApp.uploadFileToSite('invalidfile.txt', invalidBase64Data, accountRecord.Id);
        Test.stopTest();
    }

    @isTest
    public static void testUploadFileToSite_nullRecordId() {
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test file content'));

        Test.startTest();
        Boolean result = FileUploadControllerFmApp.uploadFileToSite('testfile.txt', base64Data, null);
        Test.stopTest();
    }

    @isTest
    public static void testUploadFileToSite_exception() {
        Test.startTest();
        Boolean result = FileUploadControllerFmApp.uploadFileToSite('testfile.txt', 'invalidBase64Data', null);
        Test.stopTest();
    }
}